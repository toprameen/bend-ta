import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./ema.bend as Ema
import ./rolling_average.bend as Average

type IndexKind is Data:
  Obv{}
  Nvi{}
  Pvi{}
  Pvt{}

type Index<-N: Data> is Data:
  Index{kind: IndexKind, previous: Maybe<&2, Bar.CV<N>>, total: N}

def index.origin(kind: IndexKind) -> U32:
  match kind:
    case Nvi{}: 1000
    case Pvi{}: 1000
    case other: 0

def index.init(~N: Data, ~from_u32: U32 -> N, +kind: IndexKind) -> Index<N>:
  Index{kind, None{}, from_u32(index.origin(kind))}

def index.scaled(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~finite: N -> Bool, +total: N, current: N, +previous: N, scale: N, retain_finite: Bool, active: Bool
) -> N:
  match active:
    case False{}: total
    case True{}:
      +candidate = add(total, mul(div(sub(current, previous), previous), scale))
      Bool.pick(N, Bool.or(Bool.not(retain_finite), finite(candidate)), candidate, total)

def index.value(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  ~lt: N -> N -> Bool, ~gt: N -> N -> Bool, ~finite: N -> Bool,
  kind: IndexKind, +total: N, before: Bar.CV<N>, current: Bar.CV<N>
) -> N:
  match kind before current:
    case Obv{} Bar.CV{+previous, v} Bar.CV{+close, +volume}:
      Bool.pick(N, gt(close, previous), add(total, volume), Bool.pick(N, lt(close, previous), sub(total, volume), total))
    case Nvi{} Bar.CV{+previous, before_volume} Bar.CV{close, volume}:
      index.scaled(~N, ~add, ~sub, ~mul, ~div, ~finite, total, close, previous, total, True{}, Bool.and(lt(volume, before_volume), Bool.not(eq(previous, from_u32(0)))))
    case Pvi{} Bar.CV{+previous, before_volume} Bar.CV{close, volume}:
      index.scaled(~N, ~add, ~sub, ~mul, ~div, ~finite, total, close, previous, total, True{}, Bool.and(gt(volume, before_volume), Bool.not(eq(previous, from_u32(0)))))
    case Pvt{} Bar.CV{+previous, before_volume} Bar.CV{close, volume}:
      index.scaled(~N, ~add, ~sub, ~mul, ~div, ~finite, total, close, previous, volume, False{}, Bool.not(eq(previous, from_u32(0))))

def index.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  ~lt: N -> N -> Bool, ~gt: N -> N -> Bool, ~finite: N -> Bool,
  state: Index<N>, +current: Bar.CV<N>
) -> Index<N> & Maybe<&2, N>:
  match state current:
    case Index{Obv{}, None{}, +total} Bar.CV{close, +volume}:
      (Index{Obv{}, Some{Bar.CV{close, volume}}, volume}, Some{volume})
    case Index{+kind, None{}, +total} bar:
      (Index{kind, Some{bar}, total}, Some{total})
    case Index{+kind, Some{before}, total} +bar:
      +value = index.value(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~eq, ~lt, ~gt, ~finite, kind, total, before, bar)
      (Index{kind, Some{bar}, value}, Some{value})

type Flow<-N: Data> is Data:
  Flow{money: N, volume: N}

def money.value(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +high: N, +low: N, +close: N, volume: N, range: N, positive: Bool
) -> N:
  match positive:
    case False{}: from_u32(0)
    case True{}: mul(div(sub(sub(close, low), sub(high, close)), range), volume)

def money(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~gt: N -> N -> Bool, bar: Bar.HLCV<N>
) -> N:
  match bar:
    case Bar.HLCV{+high, +low, close, volume}:
      +range = sub(high, low)
      money.value(~N, ~from_u32, ~sub, ~mul, ~div, high, low, close, volume, range, gt(range, from_u32(0)))

def ad.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, total: N, bar: Bar.HLCV<N>
) -> N & Maybe<&2, N>:
  +value = add(total, money(~N, ~from_u32, ~sub, ~mul, ~div, ~gt, bar))
  (value, Some{value})

def cmf.init(~N: Data, ~from_u32: U32 -> N, period: U32, depth: Nat) -> Window.State<Flow<N>>:
  +zero = from_u32(0)
  Window.init(~Flow<N>, period, depth, Flow{zero, zero})

def flow.add(~N: Data, ~add: N -> N -> N, context: Unit, sum: Flow<N>, value: Flow<N>) -> Flow<N>:
  match sum value:
    case Flow{money, volume} Flow{next_money, next_volume}:
      Flow{add(money, next_money), add(volume, next_volume)}

def cmf.ratio(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, money: N, volume: N, positive: Bool) -> N:
  match positive:
    case False{}: from_u32(0)
    case True{}: div(money, volume)

def cmf.emit(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool,
  result: Window.State<Flow<N>> & Flow<N>
) -> Window.State<Flow<N>> & Maybe<&2, N>:
  match result:
    case (window, Flow{money, +volume}):
      (window, Some{cmf.ratio(~N, ~from_u32, ~div, money, volume, gt(volume, from_u32(0)))})

def cmf.read(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool,
  result: Window.State<Flow<N>> & Bool
) -> Window.State<Flow<N>> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (window, True{}):
      +zero = from_u32(0)
      cmf.emit(~N, ~from_u32, ~div, ~gt, Window.fold(~Flow<N>, ~Unit, ~Flow<N>, ~(c => s => x => flow.add(~N, ~add, c, s, x)), window, Unit{}, Flow{zero, zero}))

def cmf.pushed(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool,
  result: Window.State<Flow<N>> & Maybe<&2, Flow<N>>
) -> Window.State<Flow<N>> & Maybe<&2, N>:
  match result:
    case (window, old): cmf.read(~N, ~from_u32, ~add, ~div, ~gt, Window.full(~Flow<N>, window))

def cmf.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool,
  state: Window.State<Flow<N>>, +bar: Bar.HLCV<N>
) -> Window.State<Flow<N>> & Maybe<&2, N>:
  match bar:
    case Bar.HLCV{high, low, close, volume}:
      cmf.pushed(~N, ~from_u32, ~add, ~div, ~gt, Window.push(~Flow<N>, state, Flow{money(~N, ~from_u32, ~sub, ~mul, ~div, ~gt, bar), volume}))

type Force<-N: Data> is Data:
  Force{previous: Maybe<&2, N>, ema: Ema.State<N>}

def force.init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, period: U32) -> Force<N>:
  Force{None{}, Ema.init(~N, ~from_u32, ~div, period)}

def force.emit(~N: Data, close: N, result: Ema.State<N> & Maybe<&2, N>) -> Force<N> & Maybe<&2, N>:
  match result:
    case (ema, value): (Force{Some{close}, ema}, value)

def force.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, state: Force<N>, bar: Bar.CV<N>
) -> Force<N> & Maybe<&2, N>:
  match state bar:
    case Force{None{}, ema} Bar.CV{close, volume}:
      (Force{Some{close}, ema}, None{})
    case Force{Some{previous}, ema} Bar.CV{+close, volume}:
      force.emit(~N, close, Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ema, mul(sub(close, previous), volume)))

type Ease<-N: Data> is Type:
  Ease{previous: Maybe<&2, N>, average: Average.State<N>, divisor: N}

def ease.init(~N: Data, ~from_u32: U32 -> N, period: U32, depth: Nat, divisor: N) -> Ease<N>:
  Ease{None{}, Average.init(~N, ~from_u32, period, depth, 0), divisor}

def ease.divide(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, delta: N, box: N, zero: Bool) -> N:
  match zero:
    case True{}: from_u32(0)
    case False{}: div(delta, box)

def ease.value(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  delta: N, range: N, volume: N, divisor: N, flat: Bool
) -> N:
  match flat:
    case True{}: from_u32(0)
    case False{}:
      +box = div(div(volume, divisor), range)
      ease.divide(~N, ~from_u32, ~div, delta, box, eq(box, from_u32(0)))

def ease.emit(~N: Data, close: N, divisor: N, result: Average.State<N> & Maybe<&2, N>) -> Ease<N> & Maybe<&2, N>:
  match result:
    case (average, None{}): (Ease{Some{close}, average, divisor}, None{})
    case (average, Some{mean}): (Ease{Some{close}, average, divisor}, Some{mean})

def ease.sample(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~abs: N -> N, ~le: N -> N -> Bool, previous: Maybe<&2, N>, average: Average.State<N>,
  +divisor: N, +mid: N, +range: N, volume: N
) -> Ease<N> & Maybe<&2, N>:
  match previous:
    case None{}: (Ease{Some{mid}, average, divisor}, None{})
    case Some{before}:
      ease.emit(~N, mid, divisor, Average.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~le, average,
        ease.value(~N, ~from_u32, ~div, ~eq, sub(mid, before), range, volume, divisor, eq(range, from_u32(0)))))

def ease.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~abs: N -> N, ~le: N -> N -> Bool, state: Ease<N>, bar: Bar.HLV<N>
) -> Ease<N> & Maybe<&2, N>:
  match state bar:
    case Ease{previous, average, divisor} Bar.HLV{+high, +low, volume}:
      ease.sample(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~eq, ~abs, ~le, previous, average, divisor,
        div(add(high, low), from_u32(2)), sub(high, low), volume)
