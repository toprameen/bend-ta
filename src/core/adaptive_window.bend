import Base
import ./window.bend as Window
import ./bar.bend as Bar
import ./ma.bend as Ma
import ./momentum_window.bend as Box
import ./momentum_smooth.bend as Smooth

type Frama<-N: Data> is Type:
  Frama{period: U32, window: Window.State<Bar.HL<N>>, previous: Maybe<&2, N>, started: Bool}


type Split<-N: Data> is Data:
  Split{at: U32, first: Maybe<&2, Bar.HL<N>>, second: Maybe<&2, Bar.HL<N>>}


type GravitySum<-N: Data> is Data:
  GravitySum{weight: U32, denominator: N, numerator: N}


type CorrelationSum<-N: Data> is Data:
  CorrelationSum{at: U32, sum: N, square: N, xy: N, xx: N}


type CorrelationCenter<-N: Data> is Data:
  CorrelationCenter{origin: N, ramp: N}


type Fisher<-N: Data> is Type:
  Fisher{box: Box.Box<N>, smoothed: N, fish: N}


def prices.init(~N: Data, ~from: U32 -> N, +period: U32) -> Window.State<N>:
  Window.init(~N, period, Ma.buffer_depth(period), from(0))


def extrema(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, value: Maybe<&2, Bar.HL<N>>, bar: Bar.HL<N>) -> Maybe<&2, Bar.HL<N>>:
  match value bar:
    case None{} _: Some{bar}
    case Some{Bar.HL{high, low}} Bar.HL{h, l}: Some{Bar.HL{max(high, h), min(low, l)}}


def frama.split(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, +at: U32, first: Maybe<&2, Bar.HL<N>>, second: Maybe<&2, Bar.HL<N>>, bar: Bar.HL<N>, early: Bool) -> Split<N>:
  match early:
    case True{}: Split{U32.add(at, 1), extrema(~N, ~min, ~max, first, bar), second}
    case False{}: Split{U32.add(at, 1), first, extrema(~N, ~min, ~max, second, bar)}


def frama.fold(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, half: U32, acc: Split<N>, +bar: Bar.HL<N>) -> Split<N>:
  match acc:
    case Split{+at, first, second}:
      frama.split(~N, ~min, ~max, at, first, second, bar, U32.is_lt(at, half))


def frama.init(~N: Data, ~from: U32 -> N, +period: U32) -> Frama<N>:
  +zero = from(0)
  Frama{period, Window.init(~Bar.HL<N>, period, Ma.buffer_depth(period), Bar.HL{zero, zero}), None{}, False{}}


def frama.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~log: N -> N, ~exp: N -> N, +price: N, +previous: N, value: Split<N>) -> N:
  match value:
    case Split{at, Some{Bar.HL{+h1, +l1}}, Some{Bar.HL{+h2, +l2}}}:
      +r1 = sub(h1, l1)
      +r2 = sub(h2, l2)
      +r = sub(max(h1, h2), min(l1, l2))
      +alpha = exp(mul(div(sub(from(0), div(from(46), from(10))), log(from(2))), log(div(add(r1, r2), r))))
      Bool.pick(N, Bool.and(Bool.and(lt(from(0), r1), lt(from(0), r2)), lt(r, add(r1, r2))), add(mul(alpha, price), mul(sub(from(1), alpha), previous)), price)
    case _: price


def frama.finished(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~log: N -> N, ~exp: N -> N, period: U32, +price: N, previous: N, result: Window.State<Bar.HL<N>> & Split<N>) -> Frama<N> & Maybe<&2, N>:
  match result:
    case (window, value):
      +next = frama.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~log, ~exp, price, previous, value)
      (Frama{period, window, Some{next}, True{}}, Some{next})


def frama.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~log: N -> N, ~exp: N -> N, +period: U32, +price: N, previous: N, result: Window.State<Bar.HL<N>> & Bool) -> Frama<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (Frama{period, window, Some{price}, True{}}, None{})
    case (window, True{}): frama.finished(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~log, ~exp, period, price, previous, Window.fold(~Bar.HL<N>, ~U32, ~Split<N>, ~(c => a => x => frama.fold(~N, ~min, ~max, c, a, x)), window, U32.div(period, 2), Split{0, None{}, None{}}))


def frama.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~log: N -> N, ~exp: N -> N, period: U32, price: N, previous: N, result: Window.State<Bar.HL<N>> & Maybe<&2, Bar.HL<N>>) -> Frama<N> & Maybe<&2, N>:
  match result:
    case (window, old): frama.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~log, ~exp, period, price, previous, Window.full(~Bar.HL<N>, window))


def frama.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~log: N -> N, ~exp: N -> N, state: Frama<N>, +bar: Bar.HL<N>) -> Frama<N> & Maybe<&2, N>:
  match state bar:
    case Frama{period, window, previous, False{}} Bar.HL{high, low}: (Frama{period, window, Some{div(add(high, low), from(2))}, True{}}, None{})
    case Frama{period, window, Some{previous}, True{}} Bar.HL{high, low}: frama.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~log, ~exp, period, div(add(high, low), from(2)), previous, Window.push(~Bar.HL<N>, window, bar))
    case Frama{period, window, None{}, True{}} _: (Frama{period, window, None{}, True{}}, None{})


def cg.fold(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, u: Unit, acc: GravitySum<N>, +x: N) -> GravitySum<N>:
  match acc:
    case GravitySum{+weight, denominator, numerator}: GravitySum{U32.sub(weight, 1), add(denominator, x), add(numerator, mul(from(weight), x))}


def cg.finished(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, period: U32, result: Window.State<N> & GravitySum<N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, GravitySum{weight, +den, num}): (window, Some{Bool.pick(N, eq(den, from(0)), sub(from(0), div(from(U32.add(period, 1)), from(2))), sub(from(0), div(num, den)))})


def cg.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): cg.finished(~N, ~from, ~sub, ~div, ~eq, period, Window.fold(~N, ~Unit, ~GravitySum<N>, ~(u => a => x => cg.fold(~N, ~from, ~add, ~mul, u, a, x)), Window.Window{buffer, period, size, pos}, Unit{}, GravitySum{period, from(0), from(0)}))


def cg.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): cg.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, Window.full(~N, window))


def cg.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, window: Window.State<N>, price: N) -> Window.State<N> & Maybe<&2, N>:
  cg.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, Window.push(~N, window, price))


def cti.fold(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, context: CorrelationCenter<N>, acc: CorrelationSum<N>, x: N) -> CorrelationSum<N>:
  match context acc:
    case CorrelationCenter{origin, center} CorrelationSum{+at, sum, square, xy, xx}:
      +dx = sub(from(at), center)
      +dy = sub(x, origin)
      CorrelationSum{U32.add(at, 1), add(sum, dy), add(square, mul(dy, dy)), add(xy, mul(dx, dy)), add(xx, mul(dx, dx))}


def cti.finished(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, result: Window.State<N> & CorrelationSum<N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, CorrelationSum{count, +sum, +square, xy, +xx}):
      +variance = sub(square, div(mul(sum, sum), from(count)))
      +product = mul(variance, xx)
      +threshold = div(square, mul(from(10000000), from(10000000)))
      +value = Bool.pick(N, Bool.and(lt(threshold, variance), lt(from(0), product)), max(sub(from(0), from(1)), min(from(1), div(xy, sqrt(product)))), from(0))
      (window, Some{value})


def cti.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, period: U32, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{origin}): cti.finished(~N, ~from, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~sqrt, Window.fold(~N, ~CorrelationCenter<N>, ~CorrelationSum<N>, ~(c => a => x => cti.fold(~N, ~from, ~add, ~sub, ~mul, c, a, x)), window, CorrelationCenter{origin, div(from(U32.sub(period, 1)), from(2))}, CorrelationSum{0, from(0), from(0), from(0), from(0)}))


def cti.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): cti.anchor(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~sqrt, period, Window.lag(~N, Window.Window{buffer, period, size, pos}, 0))


def cti.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): cti.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~sqrt, Window.full(~N, window))


def cti.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, window: Window.State<N>, price: N) -> Window.State<N> & Maybe<&2, N>:
  cti.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, ~lt, ~sqrt, Window.push(~N, window, price))


def fisher.init(~N: Data, ~from: U32 -> N, +period: U32) -> Fisher<N>:
  Fisher{Box.box.init(~N, ~from, period, Ma.buffer_depth(period)), from(0), from(0)}


def fisher.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, ~log: N -> N, +smoothed: N, +fish: N, result: Box.Box<N> & Maybe<&2, Box.Bounds<N>>) -> Fisher<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (box, None{}): (Fisher{box, smoothed, fish}, None{})
    case (box, Some{bounds}):
      +ratio = div(Box.stochastic(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, bounds, from(50)), from(100))
      +s = add(mul(div(from(66), from(100)), sub(ratio, div(from(1), from(2)))), mul(div(from(67), from(100)), smoothed))
      +limit = div(from(99), from(100))
      +clamp = div(from(999), from(1000))
      +value = Bool.pick(N, lt(limit, s), clamp, Bool.pick(N, lt(s, sub(from(0), limit)), sub(from(0), clamp), s))
      +next = div(add(log(div(add(from(1), value), sub(from(1), value))), fish), from(2))
      (Fisher{box, value, next}, Some{Smooth.Lines{next, fish}})


def fisher.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, ~log: N -> N, state: Fisher<N>, bar: Bar.HL<N>) -> Fisher<N> & Maybe<&2, Smooth.Lines<N>>:
  match state bar:
    case Fisher{box, smoothed, fish} Bar.HL{high, low}:
      +mid = div(add(high, low), from(2))
      fisher.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~lt, ~log, smoothed, fish, Box.box.next(~N, ~(x => y => le(y, x)), ~le, box, Bar.HLC{mid, mid, mid}))
