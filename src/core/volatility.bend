import Base
import ./bar.bend as Bar
import ./ema.bend as Ema
import ./rolling.bend as Rolling
import ./window.bend as Window
import ./change.bend as Change
import ./sma.bend as Sma

def adr.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  state: Sma.State<N>, bar: Bar.HL<N>
) -> Sma.State<N> & Maybe<&2, N>:
  Sma.next(~N, ~from_u32, ~add, ~sub, ~div, state, Bar.range(~N, ~sub, bar))

def range.next(
  ~N: Data, ~sub: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N,
  previous: Maybe<&2, N>, bar: Bar.HLC<N>
) -> Maybe<&2, N> & Maybe<&2, N>:
  match previous bar:
    case None{} Bar.HLC{high, low, close}:
      (Some{close}, None{})
    case Some{before} Bar.HLC{high, low, +close}:
      (Some{close}, Some{Bar.true_range(~N, ~sub, ~abs, ~max, before, Bar.HLC{high, low, close})})

type Atr<-N: Data> is Data:
  Atr{previous: Maybe<&2, N>, smoother: Ema.State<N>}

def atr.init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, +period: U32) -> Atr<N>:
  Atr{None{}, Ema.init.alpha(~N, ~from_u32, period, div(from_u32(1), from_u32(period)))}

def atr.emit(~N: Data, previous: Maybe<&2, N>, result: Ema.State<N> & Maybe<&2, N>) -> Atr<N> & Maybe<&2, N>:
  match result:
    case (smoother, value): (Atr{previous, smoother}, value)

def atr.range(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, smoother: Ema.State<N>,
  result: Maybe<&2, N> & Maybe<&2, N>
) -> Atr<N> & Maybe<&2, N>:
  match result:
    case (previous, None{}): (Atr{previous, smoother}, None{})
    case (previous, Some{value}):
      atr.emit(~N, previous, Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, smoother, value))

def atr.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N,
  state: Atr<N>, bar: Bar.HLC<N>
) -> Atr<N> & Maybe<&2, N>:
  match state:
    case Atr{previous, smoother}:
      atr.range(~N, ~from_u32, ~add, ~sub, ~mul, ~div, smoother, range.next(~N, ~sub, ~abs, ~max, previous, bar))

def natr.ratio(
  ~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  value: N, close: N, zero: Bool
) -> N:
  match zero:
    case True{}: from_u32(0)
    case False{}: mul(div(value, close), from_u32(100))

def natr.value(
  ~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  period: U32, value: Maybe<&2, N>, +close: N
) -> Maybe<&2, N>:
  match value:
    case None{}: None{}
    case Some{+value}:
      Some{Bool.pick(N, U32.is_eq(period, 1), value, natr.ratio(~N, ~from_u32, ~mul, ~div, value, close, eq(close, from_u32(0))))}

type Natr<-N: Data> is Data:
  Natr{atr: Atr<N>, period: U32}

def natr.init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, +period: U32) -> Natr<N>:
  Natr{atr.init(~N, ~from_u32, ~div, period), period}

def natr.emit(
  ~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  +period: U32, close: N, result: Atr<N> & Maybe<&2, N>
) -> Natr<N> & Maybe<&2, N>:
  match result:
    case (atr, value): (Natr{atr, period}, natr.value(~N, ~from_u32, ~mul, ~div, ~eq, period, value, close))

def natr.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool,
  state: Natr<N>, bar: Bar.HLC<N>
) -> Natr<N> & Maybe<&2, N>:
  match state bar:
    case Natr{atr, period} Bar.HLC{high, low, +close}:
      natr.emit(~N, ~from_u32, ~mul, ~div, ~eq, period, close,
        atr.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~max, atr, Bar.HLC{high, low, close}))

type Cvi<-N: Data> is Type:
  Cvi{ema: Ema.State<N>, lag: Window.State<N>}

def cvi.init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, period: U32, lag: U32, depth: Nat) -> Cvi<N>:
  Cvi{Ema.init(~N, ~from_u32, ~div, period), Window.init(~N, lag, depth, from_u32(0))}

def cvi.emit(~N: Data, ema: Ema.State<N>, result: Window.State<N> & Maybe<&2, N>) -> Cvi<N> & Maybe<&2, N>:
  match result:
    case (lag, value): (Cvi{ema, lag}, value)

def cvi.average(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  ~div: N -> N -> N, ~eq: N -> N -> Bool, lag: Window.State<N>, result: Ema.State<N> & Maybe<&2, N>
) -> Cvi<N> & Maybe<&2, N>:
  match result:
    case (ema, None{}): (Cvi{ema, lag}, None{})
    case (ema, Some{value}):
      cvi.emit(~N, ema, Change.next(~N,
        ~(x => y => Change.guarded(~N, ~from_u32, ~eq,
          ~(a => b => Change.percent(~N, ~from_u32, ~sub, ~mul, ~div, a, b)), x, y)), lag, value))

def cvi.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, state: Cvi<N>, bar: Bar.HL<N>
) -> Cvi<N> & Maybe<&2, N>:
  match state:
    case Cvi{ema, lag}:
      cvi.average(~N, ~from_u32, ~sub, ~mul, ~div, ~eq, lag,
        Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ema, Bar.range(~N, ~sub, bar)))

type Mass<-N: Data> is Type:
  Mass{first: Ema.State<N>, second: Ema.State<N>, sum: Rolling.State<N>}

def mass.init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, +fast: U32, slow: U32, depth: Nat) -> Mass<N>:
  Mass{Ema.init(~N, ~from_u32, ~div, fast), Ema.init(~N, ~from_u32, ~div, fast), Rolling.init(~N, ~from_u32, slow, depth)}

def mass.ratio(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, first: N, second: N, zero: Bool) -> N:
  match zero:
    case True{}: from_u32(1)
    case False{}: div(first, second)

def mass.emit(~N: Data, first: Ema.State<N>, second: Ema.State<N>, result: Rolling.State<N> & Maybe<&2, N>) -> Mass<N> & Maybe<&2, N>:
  match result:
    case (sum, value): (Mass{first, second, sum}, value)

def mass.second(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~div: N -> N -> N, ~eq: N -> N -> Bool, first: Ema.State<N>, sum: Rolling.State<N>, current: N,
  result: Ema.State<N> & Maybe<&2, N>
) -> Mass<N> & Maybe<&2, N>:
  match result:
    case (second, None{}): (Mass{first, second, sum}, None{})
    case (second, Some{+value}):
      mass.emit(~N, first, second, Rolling.push(~N, ~add, ~sub, sum,
        mass.ratio(~N, ~from_u32, ~div, current, value, eq(value, from_u32(0)))))

def mass.first(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  second: Ema.State<N>, sum: Rolling.State<N>, result: Ema.State<N> & Maybe<&2, N>
) -> Mass<N> & Maybe<&2, N>:
  match result:
    case (first, None{}): (Mass{first, second, sum}, None{})
    case (first, Some{+value}):
      mass.second(~N, ~from_u32, ~add, ~sub, ~div, ~eq, first, sum, value,
        Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, second, value))

def mass.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, state: Mass<N>, bar: Bar.HL<N>
) -> Mass<N> & Maybe<&2, N>:
  match state:
    case Mass{first, second, sum}:
      mass.first(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~eq, second, sum,
        Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, first, Bar.range(~N, ~sub, bar)))
