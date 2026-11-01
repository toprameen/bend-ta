import Base
import ./bar.bend as Bar
import ./volume.bend as Volume

type Filter<-N: Data> is Data:
  Filter{alpha: N, value: N}

type Adosc<-N: Data> is Data:
  Adosc{remaining: U32, seeded: Bool, total: N, fast: Filter<N>, slow: Filter<N>}

type Lines<-N: Data> is Data:
  Lines{kvo: N, signal: N}

type Kvo<-N: Data> is Data:
  Kvo{remaining: U32, phase: U32, previous: Bar.HLC<N>, previous_range: N, trend_up: Bool, cumulative_range: N, fast: Filter<N>, slow: Filter<N>, signal: Filter<N>}

def filter.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, period: U32) -> Filter<N>:
  Filter{div(from(2), from(U32.add(period, 1))), from(0)}

def filter.seed(~N: Data, filter: Filter<N>, value: N) -> Filter<N>:
  match filter:
    case Filter{alpha, previous}: Filter{alpha, value}

def filter.next(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, filter: Filter<N>, value: N) -> Filter<N>:
  match filter:
    case Filter{+alpha, +previous}: Filter{alpha, add(previous, mul(alpha, sub(value, previous)))}

def adosc.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +fast: U32, +slow: U32) -> Adosc<N>:
  Adosc{U32.sub(U32.max(fast, slow), 1), False{}, from(0), filter.init(~N, ~from, ~div, fast), filter.init(~N, ~from, ~div, slow)}

def remaining(+value: U32) -> U32:
  U32.sub(value, Bool.pick(U32, U32.is_zero(value), 0, 1))

def adosc.emit(~N: Data, ~sub: N -> N -> N, +count: U32, total: N, +fast: Filter<N>, +slow: Filter<N>) -> Adosc<N> & Maybe<&2, N>:
  match fast slow:
    case Filter{a, x} Filter{b, y}: (Adosc{remaining(count), True{}, total, fast, slow}, Bool.pick(Maybe<&2, N>, U32.is_zero(count), Some{sub(x, y)}, None{}))

def adosc.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, state: Adosc<N>, bar: Bar.HLCV<N>) -> Adosc<N> & Maybe<&2, N>:
  match state:
    case Adosc{count, +seeded, total, +fast, +slow}:
      +value = add(total, Volume.money(~N, ~from, ~sub, ~mul, ~div, ~gt, bar))
      adosc.emit(~N, ~sub, count, value, Bool.pick(Filter<N>, seeded, filter.next(~N, ~add, ~sub, ~mul, fast, value), filter.seed(~N, fast, value)), Bool.pick(Filter<N>, seeded, filter.next(~N, ~add, ~sub, ~mul, slow, value), filter.seed(~N, slow, value)))

def kvo.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +fast: U32, +slow: U32, +signal: U32) -> Kvo<N>:
  Kvo{U32.max(fast, U32.max(slow, signal)), 0, Bar.HLC{from(0), from(0), from(0)}, from(0), True{}, from(0), filter.init(~N, ~from, ~div, fast), filter.init(~N, ~from, ~div, slow), filter.init(~N, ~from, ~div, signal)}

def force.if(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, range: N, cumulative: N, volume: N, up: Bool, zero: Bool) -> N:
  match zero:
    case True{}: from(0)
    case False{}:
      +magnitude = mul(mul(volume, abs(sub(mul(from(2), div(range, cumulative)), from(1)))), from(100))
      Bool.pick(N, up, magnitude, sub(from(0), magnitude))

def force(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, range: N, +cumulative: N, volume: N, up: Bool) -> N:
  force.if(~N, ~from, ~sub, ~mul, ~div, ~abs, range, cumulative, volume, up, eq(cumulative, from(0)))

def kvo.trigger(~N: Data, +count: U32, hlc: Bar.HLC<N>, range: N, up: Bool, cumulative: N, fast: Filter<N>, slow: Filter<N>, value: N, +signal: Filter<N>) -> Kvo<N> & Maybe<&2, Lines<N>>:
  match signal:
    case Filter{k, trigger}: (Kvo{remaining(count), 2, hlc, range, up, cumulative, fast, slow, signal}, Bool.pick(Maybe<&2, Lines<N>>, U32.is_zero(count), Some{Lines{value, trigger}}, None{}))

def kvo.emit(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, +count: U32, hlc: Bar.HLC<N>, range: N, up: Bool, cumulative: N, +fast: Filter<N>, +slow: Filter<N>, signal: Filter<N>) -> Kvo<N> & Maybe<&2, Lines<N>>:
  match fast slow:
    case Filter{a, x} Filter{b, y}:
      +value = sub(x, y)
      kvo.trigger(~N, count, hlc, range, up, cumulative, fast, slow, value, filter.next(~N, ~add, ~sub, ~mul, signal, value))

def kvo.updated(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, count: U32, hlc: Bar.HLC<N>, range: N, up: Bool, cm: N, fast: Filter<N>, slow: Filter<N>, signal: Filter<N>, +vf: N, seed: Bool) -> Kvo<N> & Maybe<&2, Lines<N>>:
  match seed:
    case True{}: (Kvo{remaining(count), 2, hlc, range, up, cm, filter.seed(~N, fast, vf), filter.seed(~N, slow, vf), signal}, None{})
    case False{}: kvo.emit(~N, ~add, ~sub, ~mul, count, hlc, range, up, cm, filter.next(~N, ~add, ~sub, ~mul, fast, vf), filter.next(~N, ~add, ~sub, ~mul, slow, vf), signal)

def kvo.delta(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, previous: Bar.HLC<N>, current: Bar.HLC<N>) -> N:
  match previous current:
    case Bar.HLC{ph, pl, pc} Bar.HLC{high, low, close}: add(add(sub(high, ph), sub(low, pl)), sub(close, pc))

def kvo.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, count: U32, +phase: U32, +old_hlc: Bar.HLC<N>, old_range: N, +old_up: Bool, cumulative: N, fast: Filter<N>, slow: Filter<N>, signal: Filter<N>, +hlc: Bar.HLC<N>, +range: N, volume: N) -> Kvo<N> & Maybe<&2, Lines<N>>:
  +delta = kvo.delta(~N, ~add, ~sub, old_hlc, hlc)
  +up = Bool.pick(Bool, gt(delta, from(0)), True{}, Bool.pick(Bool, gt(from(0), delta), False{}, old_up))
  +cm = add(Bool.pick(N, Bool.or(U32.is_eq(phase, 1), Bool.xor(up, old_up)), old_range, cumulative), range)
  +vf = force(~N, ~from, ~sub, ~mul, ~div, ~abs, ~eq, range, cm, volume, up)
  kvo.updated(~N, ~add, ~sub, ~mul, count, hlc, range, up, cm, fast, slow, signal, vf, U32.is_eq(phase, 1))

def kvo.anchored(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, +count: U32, phase: U32, old_hlc: Bar.HLC<N>, old_range: N, old_up: Bool, cumulative: N, fast: Filter<N>, slow: Filter<N>, signal: Filter<N>, hlc: Bar.HLC<N>, range: N, volume: N, first: Bool) -> Kvo<N> & Maybe<&2, Lines<N>>:
  match first:
    case True{}: (Kvo{remaining(count), 1, hlc, range, True{}, from(0), fast, slow, signal}, None{})
    case False{}: kvo.step(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~eq, ~gt, count, phase, old_hlc, old_range, old_up, cumulative, fast, slow, signal, hlc, range, volume)

def kvo.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, state: Kvo<N>, bar: Bar.HLCV<N>) -> Kvo<N> & Maybe<&2, Lines<N>>:
  match state bar:
    case Kvo{+count, +phase, old_hlc, old_range, old_up, cumulative, fast, slow, signal} Bar.HLCV{+high, +low, close, volume}:
      +hlc : Bar.HLC<N> = Bar.HLC{high, low, close}
      +range = sub(high, low)
      kvo.anchored(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~eq, ~gt, count, phase, old_hlc, old_range, old_up, cumulative, fast, slow, signal, hlc, range, volume, U32.is_zero(phase))
