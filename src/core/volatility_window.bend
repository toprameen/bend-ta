import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./moments.bend as Moments
import ./rolling_average.bend as Average
import ./ema.bend as Ema

type RogersSatchell<-N: Data> is Type:
  RogersSatchell{window: Average.State<N>, scale: N}

type Rvi<-N: Data> is Type:
  Rvi{window: Window.State<N>, previous: Maybe<&2, N>, up: Ema.State<N>, down: Ema.State<N>}

type Rvir<-N: Data> is Type:
  Rvir{high: Rvi<N>, low: Rvi<N>}

def rogerssatchell.init(~N: Data, ~from: U32 -> N, ~sqrt: N -> N, period: U32, depth: Nat, annualization: N) -> RogersSatchell<N>:
  RogersSatchell{Average.init(~N, ~from, period, depth, 0), sqrt(annualization)}

def rogerssatchell.term.if(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~log: N -> N, +open: N, +high: N, +low: N, +close: N, valid: Bool) -> N:
  match valid:
    case False{}: from(0)
    case True{}: add(mul(log(div(high, close)), log(div(high, open))), mul(log(div(low, close)), log(div(low, open))))

def rogerssatchell.term(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~log: N -> N, ~gt: N -> N -> Bool, bar: Bar.OHLC<N>) -> N:
  match bar:
    case Bar.OHLC{+open, +high, +low, +close}:
      rogerssatchell.term.if(~N, ~from, ~add, ~mul, ~div, ~log, open, high, low, close, Bool.and(Bool.and(gt(open, from(0)), gt(high, from(0))), Bool.and(gt(low, from(0)), gt(close, from(0)))))

def rogerssatchell.positive(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~sqrt: N -> N, +scale: N, window: Average.State<N>, mean: N, positive: Bool) -> RogersSatchell<N> & Maybe<&2, N>:
  match positive:
    case False{}: (RogersSatchell{window, scale}, Some{from(0)})
    case True{}: (RogersSatchell{window, scale}, Some{mul(scale, sqrt(mean))})

def rogerssatchell.emit(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~sqrt: N -> N, ~gt: N -> N -> Bool, +scale: N, result: Average.State<N> & Maybe<&2, N>) -> RogersSatchell<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (RogersSatchell{window, scale}, None{})
    case (window, Some{+mean}):
      rogerssatchell.positive(~N, ~from, ~mul, ~sqrt, scale, window, mean, gt(mean, from(0)))

def rogerssatchell.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~log: N -> N, ~gt: N -> N -> Bool, ~abs: N -> N, ~le: N -> N -> Bool, state: RogersSatchell<N>, bar: Bar.OHLC<N>) -> RogersSatchell<N> & Maybe<&2, N>:
  match state:
    case RogersSatchell{window, scale}: rogerssatchell.emit(~N, ~from, ~mul, ~sqrt, ~gt, scale, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, window, rogerssatchell.term(~N, ~from, ~add, ~mul, ~div, ~log, ~gt, bar)))

def rvi.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, deviation_period: U32, depth: Nat) -> Rvi<N>:
  +alpha = div(from(1), from(period))
  Rvi{Window.init(~N, deviation_period, depth, from(0)), None{}, Ema.init.alpha(~N, ~from, period, alpha), Ema.init.alpha(~N, ~from, period, alpha)}

def rvi.ratio.if(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, up: N, total: N, zero: Bool) -> N:
  match zero:
    case True{}: from(50)
    case False{}: mul(from(100), div(up, total))

def rvi.ratio(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, +up: N, down: N) -> N:
  +total = add(up, down)
  rvi.ratio.if(~N, ~from, ~mul, ~div, up, total, eq(total, from(0)))

def rvi.emit(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, window: Window.State<N>, price: N, upr: Ema.State<N> & Maybe<&2, N>, dnr: Ema.State<N> & Maybe<&2, N>) -> Rvi<N> & Maybe<&2, N>:
  match upr dnr:
    case Tuple{up, Some{x}} Tuple{down, Some{y}}: (Rvi{window, Some{price}, up, down}, Some{rvi.ratio(~N, ~from, ~add, ~mul, ~div, ~eq, x, y)})
    case Tuple{up, x} Tuple{down, y}: (Rvi{window, Some{price}, up, down}, None{})

def rvi.deviation(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, previous: Maybe<&2, N>, +price: N, up: Ema.State<N>, down: Ema.State<N>, result: Window.State<N> & Maybe<&2, Moments.Value<N>>) -> Rvi<N> & Maybe<&2, N>:
  match previous result:
    case Some{+before} Tuple{window, Some{Moments.Moments{mean, variance}}}:
      +sigma = sqrt(variance)
      rvi.emit(~N, ~from, ~add, ~mul, ~div, ~eq, window, price, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, up, Bool.pick(N, gt(price, before), sigma, from(0))), Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, down, Bool.pick(N, gt(before, price), sigma, from(0))))
    case previous Tuple{window, value}: (Rvi{window, Some{price}, up, down}, None{})

def rvi.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, state: Rvi<N>, +price: N) -> Rvi<N> & Maybe<&2, N>:
  match state:
    case Rvi{window, previous, up, down}: rvi.deviation(~N, ~from, ~add, ~sub, ~mul, ~div, ~sqrt, ~eq, ~gt, previous, price, up, down, Moments.next(~N, ~from, ~add, ~sub, ~mul, ~div, window, price))

def rvir.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, +deviation_period: U32, +depth: Nat) -> Rvir<N>:
  Rvir{rvi.init(~N, ~from, ~div, period, deviation_period, depth), rvi.init(~N, ~from, ~div, period, deviation_period, depth)}

def rvir.emit(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, highr: Rvi<N> & Maybe<&2, N>, lowr: Rvi<N> & Maybe<&2, N>) -> Rvir<N> & Maybe<&2, N>:
  match highr lowr:
    case Tuple{high, Some{x}} Tuple{low, Some{y}}: (Rvir{high, low}, Some{div(add(x, y), from(2))})
    case Tuple{high, x} Tuple{low, y}: (Rvir{high, low}, None{})

def rvir.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, state: Rvir<N>, bar: Bar.HL<N>) -> Rvir<N> & Maybe<&2, N>:
  match state bar:
    case Rvir{high, low} Bar.HL{h, l}: rvir.emit(~N, ~from, ~add, ~div, rvi.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~sqrt, ~eq, ~gt, high, h), rvi.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~sqrt, ~eq, ~gt, low, l))
