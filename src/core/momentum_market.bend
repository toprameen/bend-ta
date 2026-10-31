import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./momentum_window.bend as Box

type Terms<-N: Data> is Data:
  Terms{range: N, pressure: N, plus: N, minus: N, high: N, low: N}

type Market<-N: Data> is Type:
  Market{period: U32, previous: Maybe<&2, Bar.HLC<N>>, window: Window.State<Terms<N>>}

def init(~N: Data, ~from: U32 -> N, +period: U32, depth: Nat) -> Market<N>:
  +zero = from(0)
  Market{period, None{}, Window.init(~Terms<N>, period, depth, Terms{zero, zero, zero, zero, zero, zero})}

def terms(~N: Data, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, previous: Bar.HLC<N>, bar: Bar.HLC<N>, +kind: U32) -> Terms<N>:
  match previous bar:
    case Bar.HLC{ph, pl, +pc} Bar.HLC{+high, +low, +close}:
      +th = max(high, pc)
      +tl = min(low, pc)
      Terms{Bool.pick(N, U32.is_ge(kind, 2), Bar.true_range(~N, ~sub, ~abs, ~max, pc, Bar.HLC{high, low, close}), sub(th, tl)), sub(close, tl), abs(sub(high, pl)), abs(sub(low, ph)), Bool.pick(N, U32.is_eq(kind, 1), th, high), Bool.pick(N, U32.is_eq(kind, 1), tl, low)}

def step(~N: Data, ~add: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, u: Unit, acc: Maybe<&2, Terms<N>>, value: Terms<N>) -> Maybe<&2, Terms<N>>:
  match acc value:
    case None{} value: Some{value}
    case Some{Terms{tr, bp, vp, vm, high, low}} Terms{r, b, p, m, h, l}:
      Some{Terms{add(tr, r), add(bp, b), add(vp, p), add(vm, m), max(high, h), min(low, l)}}

def folded(~N: Data, +period: U32, previous: Bar.HLC<N>, result: Window.State<Terms<N>> & Maybe<&2, Terms<N>>) -> Market<N> & Maybe<&2, Terms<N>>:
  match result:
    case (window, value): (Market{period, Some{previous}, window}, value)

def ready(~N: Data, ~add: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, +period: U32, previous: Bar.HLC<N>, result: Window.State<Terms<N>> & Bool) -> Market<N> & Maybe<&2, Terms<N>>:
  match result:
    case (window, False{}): (Market{period, Some{previous}, window}, None{})
    case (window, True{}): folded(~N, period, previous, Window.fold(~Terms<N>, ~Unit, ~Maybe<&2, Terms<N>>, ~(u => a => x => step(~N, ~add, ~min, ~max, u, a, x)), window, Unit{}, None{}))

def pushed(~N: Data, ~add: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, +period: U32, previous: Bar.HLC<N>, result: Window.State<Terms<N>> & Maybe<&2, Terms<N>>) -> Market<N> & Maybe<&2, Terms<N>>:
  match result:
    case (window, old): ready(~N, ~add, ~min, ~max, period, previous, Window.full(~Terms<N>, window))

def next(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, state: Market<N>, +bar: Bar.HLC<N>, +kind: U32) -> Market<N> & Maybe<&2, Terms<N>>:
  match state:
    case Market{period, None{}, window}: (Market{period, Some{bar}, window}, None{})
    case Market{period, Some{previous}, window}: pushed(~N, ~add, ~min, ~max, period, bar, Window.push(~Terms<N>, window, terms(~N, ~sub, ~abs, ~min, ~max, previous, bar, kind)))

def chop(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~log: N -> N, ~gt: N -> N -> Bool, +period: U32, value: Terms<N>) -> N:
  match value:
    case Terms{+range, pressure, plus, minus, high, low}:
      +box = sub(high, low)
      Bool.pick(N, Bool.and(gt(range, from(0)), gt(box, from(0))), mul(from(100), div(log(div(range, box)), log(from(period)))), from(100))

type Vortex<-N: Data> is Data:
  Vortex{plus: N, minus: N}

def vortex(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, value: Terms<N>) -> Vortex<N>:
  match value:
    case Terms{+range, pressure, plus, minus, high, low}:
      Vortex{Bool.pick(N, gt(range, from(0)), div(plus, range), from(0)), Bool.pick(N, gt(range, from(0)), div(minus, range), from(0))}

def pressure(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, value: Terms<N>) -> N:
  match value:
    case Terms{+range, pressure, plus, minus, high, low}: Bool.pick(N, gt(range, from(0)), div(pressure, range), from(0))

type CCI<-N: Data> is Type:
  CCI{period: U32, origin: Maybe<&2, N>, window: Window.State<N>}

def cci.init(~N: Data, ~from: U32 -> N, +period: U32, depth: Nat) -> CCI<N>:
  CCI{period, None{}, Window.init(~N, period, depth, from(0))}

type Center<-N: Data> is Data:
  Center{origin: N, total: N}

def center.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, u: Unit, acc: Maybe<&2, Center<N>>, +value: N) -> Maybe<&2, Center<N>>:
  match acc:
    case None{}: Some{Center{value, from(0)}}
    case Some{Center{+origin, total}}: Some{Center{origin, add(total, sub(value, origin))}}

def deviation.step(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, +mean: N, +total: N, +value: N) -> N:
  add(total, abs(sub(value, mean)))

def cci.deviation(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, +period: U32, +base: N, +mean: N, +price: N, result: Window.State<N> & N) -> CCI<N> & Maybe<&2, N>:
  match result:
    case (window, total):
      +deviation = div(total, from(period))
      +delta = sub(price, mean)
      +den = mul(div(from(15), from(1000)), deviation)
      +magnitude = add(base, mean)
      +flat = Bool.or(Box.scaled_zero(~N, ~from, ~add, ~mul, ~div, ~abs, ~le, delta, magnitude, from(0)), Bool.or(Box.scaled_zero(~N, ~from, ~add, ~mul, ~div, ~abs, ~le, deviation, magnitude, from(0)), eq(den, from(0))))
      (CCI{period, Some{base}, window}, Some{Bool.pick(N, flat, from(0), div(delta, den))})

def cci.centered(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, +period: U32, +base: N, +price: N, result: Window.State<N> & Maybe<&2, Center<N>>) -> CCI<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (CCI{period, Some{base}, window}, None{})
    case (window, Some{Center{origin, total}}):
      +mean = add(origin, div(total, from(period)))
      cci.deviation(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, period, base, mean, price, Window.fold(~N, ~N, ~N, ~(m => a => x => deviation.step(~N, ~add, ~sub, ~abs, m, a, x)), window, mean, from(0)))

def cci.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, +period: U32, +base: N, +price: N, result: Window.State<N> & Bool) -> CCI<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (CCI{period, Some{base}, window}, None{})
    case (window, True{}): cci.centered(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, period, base, price, Window.fold(~N, ~Unit, ~Maybe<&2, Center<N>>, ~(u => a => x => center.step(~N, ~from, ~add, ~sub, u, a, x)), window, Unit{}, None{}))

def cci.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, +period: U32, +base: N, +price: N, result: Window.State<N> & Maybe<&2, N>) -> CCI<N> & Maybe<&2, N>:
  match result:
    case (window, old): cci.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, period, base, price, Window.full(~N, window))

def cci.bar(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, +period: U32, +base: N, window: Window.State<N>, +high: N, +low: N, +close: N) -> CCI<N> & Maybe<&2, N>:
  +price = div(add(add(sub(high, base), sub(low, base)), sub(close, base)), from(3))
  cci.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, period, base, price, Window.push(~N, window, price))

def cci.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, state: CCI<N>, bar: Bar.HLC<N>) -> CCI<N> & Maybe<&2, N>:
  match state bar:
    case CCI{period, None{}, window} Bar.HLC{high, low, +close}: cci.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, period, close, window, high, low, close)
    case CCI{period, Some{base}, window} Bar.HLC{high, low, close}: cci.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, period, base, window, high, low, close)
