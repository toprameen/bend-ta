import Base
import ./bar.bend as Bar
import ./rolling.bend as Rolling

type Error is Data:
  InvalidPeriod{}
  InvalidFactor{}

type RangeKind is Data:
  RealBody{}
  HighLow{}
  Shadows{}

type Name is Data:
  BodyLong{}
  BodyVeryLong{}
  BodyShort{}
  BodyDoji{}
  ShadowLong{}
  ShadowVeryLong{}
  ShadowShort{}
  ShadowVeryShort{}
  Near{}
  Far{}
  Equal{}

type Setting<-N: Data> is Data:
  Setting{kind: RangeKind, period: U32, factor: N}

def defaults(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, name: Name) -> Setting<N>:
  match name:
    case BodyLong{}: Setting{RealBody{}, 10, from_u32(1)}
    case BodyVeryLong{}: Setting{RealBody{}, 10, from_u32(3)}
    case BodyShort{}: Setting{RealBody{}, 10, from_u32(1)}
    case BodyDoji{}: Setting{HighLow{}, 10, div(from_u32(1), from_u32(10))}
    case ShadowLong{}: Setting{RealBody{}, 0, from_u32(1)}
    case ShadowVeryLong{}: Setting{RealBody{}, 0, from_u32(2)}
    case ShadowShort{}: Setting{Shadows{}, 10, from_u32(1)}
    case ShadowVeryShort{}: Setting{HighLow{}, 10, div(from_u32(1), from_u32(10))}
    case Near{}: Setting{HighLow{}, 5, div(from_u32(1), from_u32(5))}
    case Far{}: Setting{HighLow{}, 5, div(from_u32(3), from_u32(5))}
    case Equal{}: Setting{HighLow{}, 5, div(from_u32(1), from_u32(20))}

type State<-N: Data> is Type:
  Candle{setting: Setting<N>, ring: Rolling.State<N>, previous: Maybe<&2, N>}

def init(~N: Data, ~from_u32: U32 -> N, setting: Setting<N>, period: U32, depth: Nat) -> State<N>:
  Candle{setting, Rolling.init(~N, ~from_u32, period, depth), None{}}

def range(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N,
  kind: RangeKind, bar: Bar.OHLC<N>
) -> N:
  match kind bar:
    case RealBody{} bar:
      Bar.body(~N, ~sub, ~abs, bar)
    case HighLow{} Bar.OHLC{open, high, low, close}:
      sub(high, low)
    case Shadows{} bar:
      Bar.shadows(~N, ~add, ~sub, ~min, ~max, bar)

def scale(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, kind: RangeKind, value: N) -> N:
  match kind:
    case Shadows{}:
      div(value, from_u32(2))
    case other:
      value

def threshold(
  ~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  kind: RangeKind, factor: N, average: Maybe<&2, N>
) -> Maybe<&2, N>:
  match average:
    case None{}:
      None{}
    case Some{value}:
      Some{scale(~N, ~from_u32, ~div, kind, mul(factor, value))}

def pushed(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N,
  setting: Setting<N>, period: U32, output: Maybe<&2, N>, result: Rolling.State<N> & Maybe<&2, N>
) -> State<N> & Maybe<&2, N>:
  match result:
    case (ring, sum):
      (Candle{setting, ring, Rolling.average(~N, ~from_u32, ~div, period, sum)}, output)

def next.phase(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +kind: RangeKind, +period: U32, +factor: N, ring: Rolling.State<N>, previous: Maybe<&2, N>, value: N, current: Bool
) -> State<N> & Maybe<&2, N>:
  match current:
    case True{}:
      (Candle{Setting{kind, period, factor}, ring, previous}, threshold(~N, ~from_u32, ~mul, ~div, kind, factor, Some{value}))
    case False{}:
      pushed(~N, ~from_u32, ~div, Setting{kind, period, factor}, period, threshold(~N, ~from_u32, ~mul, ~div, kind, factor, previous), Rolling.push(~N, ~add, ~sub, ring, value))

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N,
  state: State<N>, bar: Bar.OHLC<N>
) -> State<N> & Maybe<&2, N>:
  match state:
    case Candle{Setting{+kind, +period, factor}, ring, previous}:
      next.phase(~N, ~from_u32, ~add, ~sub, ~mul, ~div, kind, period, factor, ring, previous,
        range(~N, ~add, ~sub, ~abs, ~min, ~max, kind, bar), U32.is_zero(period))
