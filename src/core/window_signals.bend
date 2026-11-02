import Base
import ./extrema_queue.bend as Queue
import ./bar.bend as Bar
import ./config.bend as Config
import ./window.bend as Window
import ./rolling_average.bend as Average
import ./overlap.bend as Overlap

type DisplayShift is Data:
  DisplayShift{backward: Bool, bars: U32}

type Detrended<-N: Data> is Type:
  Detrended{average: Average.State<N>, delayed: Window.State<N>, lag: U32}

def dpo.init(~N: Data, ~from: U32 -> N, +period: U32) -> Detrended<N>:
  +lag = U32.add(U32.div(period, 2), 1)
  +size = U32.add(lag, 1)
  Detrended{Average.init(~N, ~from, period, Config.depth(period), 0), Window.init(~N, size, Config.depth(size), from(0)), lag}

def dpo.output(~N: Data, ~sub: N -> N -> N, average: Average.State<N>, lag: U32, result: Window.State<N> & Maybe<&2, N>, mean: Maybe<&2, N>) -> Detrended<N> & Maybe<&2, N>:
  match result mean:
    case (delayed, Some{price}) Some{m}: (Detrended{average, delayed, lag}, Some{sub(price, m)})
    case (delayed, _) _: (Detrended{average, delayed, lag}, None{})

def dpo.pushed(~N: Data, ~sub: N -> N -> N, average: Average.State<N>, +lag: U32, mean: Maybe<&2, N>, result: Window.State<N> & Maybe<&2, N>) -> Detrended<N> & Maybe<&2, N>:
  match result:
    case (delayed, old): dpo.output(~N, ~sub, average, lag, Window.lag(~N, delayed, lag), mean)

def dpo.mean(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, delayed: Window.State<N>, lag: U32, price: N, result: Average.State<N> & Maybe<&2, N>) -> Detrended<N> & Maybe<&2, N>:
  match result:
    case (average, mean): dpo.pushed(~N, ~sub, average, lag, mean, Window.push(~N, delayed, price))

def dpo.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~mul: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: Detrended<N>, +price: N) -> Detrended<N> & Maybe<&2, N>:
  match state:
    case Detrended{average, delayed, lag}: dpo.mean(~N, ~from, ~add, ~sub, ~div, delayed, lag, price, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, average, price))

def rvol.output(~N: Data, ~div: N -> N -> N, volume: N, result: Average.State<N> & Maybe<&2, N>, mean: Maybe<&2, N>) -> Average.State<N> & Maybe<&2, N>:
  match result mean:
    case (window, old) Some{m}: (window, Some{div(volume, m)})
    case (window, old) None{}: (window, None{})

def rvol.mean(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +volume: N, result: Average.State<N> & Maybe<&2, N>) -> Average.State<N> & Maybe<&2, N>:
  match result:
    case (window, mean): rvol.output(~N, ~div, volume, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, window, volume), mean)

def rvol.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~mul: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, window: Average.State<N>, +volume: N) -> Average.State<N> & Maybe<&2, N>:
  rvol.mean(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, volume, Average.read(~N, ~add, ~div, window))

type Cloud<-N: Data> is Type:
  Cloud{tenkan: Queue.State<N>, kijun: Queue.State<N>, span: Queue.State<N>}

type CloudValue<-N: Data> is Data:
  CloudValue{tenkan: N, kijun: N, span_a: N, span_b: N}

def cloud.window(~N: Data, ~from: U32 -> N, +period: U32) -> Queue.State<N>:
  Queue.init(~N, ~from, period, Config.depth(period))

def cloud.init(~N: Data, ~from: U32 -> N, tenkan: U32, kijun: U32, span: U32) -> Cloud<N>:
  Cloud{cloud.window(~N, ~from, tenkan), cloud.window(~N, ~from, kijun), cloud.window(~N, ~from, span)}

def cloud.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, tenkan: Maybe<&2, Overlap.Bands<N>>, kijun: Maybe<&2, Overlap.Bands<N>>, span: Maybe<&2, Overlap.Bands<N>>) -> Maybe<&2, CloudValue<N>>:
  match tenkan kijun span:
    case Some{Overlap.Bands{u, +t, l}} Some{Overlap.Bands{u2, +k, l2}} Some{Overlap.Bands{u3, b, l3}}: Some{CloudValue{t, k, div(add(t, k), from(2)), b}}
    case _ _ _: None{}

def cloud.span(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, tenkan: Queue.State<N>, kijun: Queue.State<N>, t: Maybe<&2, Overlap.Bands<N>>, k: Maybe<&2, Overlap.Bands<N>>, result: Queue.State<N> & Maybe<&2, Overlap.Bands<N>>) -> Cloud<N> & Maybe<&2, CloudValue<N>>:
  match result:
    case (span, b): (Cloud{tenkan, kijun, span}, cloud.value(~N, ~from, ~add, ~div, t, k, b))

def cloud.kijun(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, tenkan: Queue.State<N>, span: Queue.State<N>, t: Maybe<&2, Overlap.Bands<N>>, bar: Bar.HL<N>, result: Queue.State<N> & Maybe<&2, Overlap.Bands<N>>) -> Cloud<N> & Maybe<&2, CloudValue<N>>:
  match result:
    case (kijun, k): cloud.span(~N, ~from, ~add, ~div, tenkan, kijun, t, k, Overlap.channel.next(~N, ~from, ~add, ~div, ~lt, span, bar))

def cloud.tenkan(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, kijun: Queue.State<N>, span: Queue.State<N>, +bar: Bar.HL<N>, result: Queue.State<N> & Maybe<&2, Overlap.Bands<N>>) -> Cloud<N> & Maybe<&2, CloudValue<N>>:
  match result:
    case (tenkan, t): cloud.kijun(~N, ~from, ~add, ~div, ~lt, tenkan, span, t, bar, Overlap.channel.next(~N, ~from, ~add, ~div, ~lt, kijun, bar))

def cloud.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, state: Cloud<N>, +bar: Bar.HL<N>) -> Cloud<N> & Maybe<&2, CloudValue<N>>:
  match state:
    case Cloud{tenkan, kijun, span}: cloud.tenkan(~N, ~from, ~add, ~div, ~lt, kijun, span, bar, Overlap.channel.next(~N, ~from, ~add, ~div, ~lt, tenkan, bar))

type Fractal<-N: Data> is Type:
  Fractal{window: Window.State<Bar.HL<N>>, left: U32, right: U32, count: U32}

type PivotFlags is Data:
  PivotFlags{high: U32, low: U32, index: U32}

type PivotScan is Data:
  PivotScan{at: U32, high: Bool, low: Bool}

type PivotContext<-N: Data> is Data:
  PivotContext{left: U32, bar: Bar.HL<N>}

def fractal.init(~N: Data, ~from: U32 -> N, +left: U32, +right: U32) -> Fractal<N>:
  +size = U32.add(U32.add(left, right), 1)
  Fractal{Window.init(~Bar.HL<N>, size, Config.depth(size), Bar.HL{from(0), from(0)}), left, right, 0}

def fractal.compare(~N: Data, ~gt: N -> N -> Bool, context: PivotContext<N>, scan: PivotScan, bar: Bar.HL<N>) -> PivotScan:
  match context scan bar:
    case PivotContext{+left, Bar.HL{h, l}} PivotScan{+at, high, low} Bar.HL{other_h, other_l}: PivotScan{U32.add(at, 1), Bool.and(high, Bool.or(U32.is_eq(at, left), gt(h, other_h))), Bool.and(low, Bool.or(U32.is_eq(at, left), gt(other_l, l)))}

def fractal.finish(~N: Data, left: U32, +right: U32, +count: U32, result: Window.State<Bar.HL<N>> & PivotScan) -> Fractal<N> & Maybe<&2, PivotFlags>:
  match result:
    case (window, PivotScan{at, high, low}): (Fractal{window, left, right, count}, Some{PivotFlags{Bool.pick(U32, high, 100, 0), Bool.pick(U32, low, 100, 0), U32.sub(U32.sub(count, 1), right)}})

def fractal.pivot(~N: Data, ~gt: N -> N -> Bool, +left: U32, +right: U32, +count: U32, result: Window.State<Bar.HL<N>> & Maybe<&2, Bar.HL<N>>) -> Fractal<N> & Maybe<&2, PivotFlags>:
  match result:
    case (window, None{}): (Fractal{window, left, right, count}, None{})
    case (window, Some{bar}): fractal.finish(~N, left, right, count, Window.fold(~Bar.HL<N>, ~PivotContext<N>, ~PivotScan, ~(c => a => x => fractal.compare(~N, ~gt, c, a, x)), window, PivotContext{left, bar}, PivotScan{0, True{}, True{}}))

def fractal.ready(~N: Data, ~gt: N -> N -> Bool, left: U32, +right: U32, count: U32, result: Window.State<Bar.HL<N>> & Bool) -> Fractal<N> & Maybe<&2, PivotFlags>:
  match result:
    case (window, False{}): (Fractal{window, left, right, count}, None{})
    case (window, True{}): fractal.pivot(~N, ~gt, left, right, count, Window.lag(~Bar.HL<N>, window, right))

def fractal.pushed(~N: Data, ~gt: N -> N -> Bool, left: U32, right: U32, count: U32, result: Window.State<Bar.HL<N>> & Maybe<&2, Bar.HL<N>>) -> Fractal<N> & Maybe<&2, PivotFlags>:
  match result:
    case (window, old): fractal.ready(~N, ~gt, left, right, count, Window.full(~Bar.HL<N>, window))

def fractal.next(~N: Data, ~gt: N -> N -> Bool, state: Fractal<N>, bar: Bar.HL<N>) -> Fractal<N> & Maybe<&2, PivotFlags>:
  match state:
    case Fractal{window, left, right, count}: fractal.pushed(~N, ~gt, left, right, U32.add(count, 1), Window.push(~Bar.HL<N>, window, bar))
