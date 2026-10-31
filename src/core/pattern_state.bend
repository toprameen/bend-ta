import Base
import ./bar.bend as Bar
import ./candle.bend as Candle
import ./config.bend as Config
import ./parameters.bend as Parameters

import ./patterns.bend as Pattern

type Thresholds<-N: Data> is Type:
  Thresholds{body_long: Candle.State<N>, body_very_long: Candle.State<N>, body_short: Candle.State<N>, body_doji: Candle.State<N>, shadow_long: Candle.State<N>, shadow_very_long: Candle.State<N>, shadow_short: Candle.State<N>, shadow_very_short: Candle.State<N>, near: Candle.State<N>, far: Candle.State<N>, equal: Candle.State<N>}

type History<-N: Data> is Data:
  History{one: Pattern.Frame<N>, two: Pattern.Frame<N>, three: Pattern.Frame<N>, four: Pattern.Frame<N>}

type State<-N: Data> is Type:
  State{name: Pattern.Name, remaining: U32, penetration: N, thresholds: Thresholds<N>, history: History<N>}

def threshold.init(~N: Data, ~from_u32: U32 -> N, +setting: Candle.Setting<N>) -> Candle.State<N>:
  +size = U32.max(Pattern.period(~N, setting), 1)
  Candle.init(~N, ~from_u32, setting, size, Config.depth.go(30n, size, 1, 0n, U32.is_le(size, 1)))

def init.validated(~N: Data, ~from_u32: U32 -> N, +name: Pattern.Name, +settings: Pattern.Settings<N>, penetration: N) -> State<N>:
  match settings:
    case Pattern.Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}:
      +remaining = Pattern.lookback(~N, settings, name)
      +zero = Pattern.frame.zero(~N, ~from_u32)
      State{name, remaining, penetration, Thresholds{threshold.init(~N, ~from_u32, body_long), threshold.init(~N, ~from_u32, body_very_long), threshold.init(~N, ~from_u32, body_short), threshold.init(~N, ~from_u32, body_doji), threshold.init(~N, ~from_u32, shadow_long), threshold.init(~N, ~from_u32, shadow_very_long), threshold.init(~N, ~from_u32, shadow_short), threshold.init(~N, ~from_u32, shadow_very_short), threshold.init(~N, ~from_u32, near), threshold.init(~N, ~from_u32, far), threshold.init(~N, ~from_u32, equal)}, History{zero, zero, zero, zero}}

def init.checked(~N: Data, ~from_u32: U32 -> N, name: Pattern.Name, settings: Pattern.Settings<N>, penetration: N, valid: Bool) -> Result<&2, &1, Parameters.Error, State<N>>:
  match valid:
    case False{}: Fail{Parameters.InvalidParameter{}}
    case True{}: Done{init.validated(~N, ~from_u32, name, settings, penetration)}

def init(~N: Data, ~from_u32: U32 -> N, ~finite: N -> Bool, ~ge: N -> N -> Bool, name: Pattern.Name, +settings: Pattern.Settings<N>, +penetration: N) -> Result<&2, &1, Parameters.Error, State<N>>:
  init.checked(~N, ~from_u32, name, settings, penetration, Bool.and(Pattern.settings.valid(~N, ~finite, ~ge, ~from_u32, settings), Bool.and(finite(penetration), ge(penetration, from_u32(0)))))

def value(~N: Data, ~from_u32: U32 -> N, value: Maybe<&2, N>) -> N:
  match value:
    case None{}: from_u32(0)
    case Some{x}: x

def emit(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +name: Pattern.Name, +remaining: U32, +penetration: N, thresholds: Thresholds<N>, history: History<N>, +frame: Pattern.Frame<N>) -> State<N> & Maybe<&2, Pattern.Signal>:
  match history:
    case History{+one, +two, +three, four}:
      (State{name, U32.sub(remaining, Bool.pick(U32, U32.is_zero(remaining), 0, 1)), penetration, thresholds, History{frame, one, two, three}},
        Bool.pick(Maybe<&2, Pattern.Signal>, U32.is_zero(remaining), Some{Pattern.detect(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, name, frame, one, two, three, four, penetration)}, None{}))

def bar.color(~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~ge: N -> N -> Bool, bar: Bar.OHLC<N>) -> N:
  match bar:
    case Bar.OHLC{open, high, low, close}:
      Bool.pick(N, ge(close, open), from_u32(1), sub(from_u32(0), from_u32(1)))

def advanced(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, name: Pattern.Name, remaining: U32, penetration: N, history: History<N>, +bar: Bar.OHLC<N>, body_longr: Candle.State<N> & Maybe<&2, N>, body_very_longr: Candle.State<N> & Maybe<&2, N>, body_shortr: Candle.State<N> & Maybe<&2, N>, body_dojir: Candle.State<N> & Maybe<&2, N>, shadow_longr: Candle.State<N> & Maybe<&2, N>, shadow_very_longr: Candle.State<N> & Maybe<&2, N>, shadow_shortr: Candle.State<N> & Maybe<&2, N>, shadow_very_shortr: Candle.State<N> & Maybe<&2, N>, nearr: Candle.State<N> & Maybe<&2, N>, farr: Candle.State<N> & Maybe<&2, N>, equalr: Candle.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, Pattern.Signal>:
  match body_longr body_very_longr body_shortr body_dojir shadow_longr shadow_very_longr shadow_shortr shadow_very_shortr nearr farr equalr:
    case Tuple{body_long, body_longv} Tuple{body_very_long, body_very_longv} Tuple{body_short, body_shortv} Tuple{body_doji, body_dojiv} Tuple{shadow_long, shadow_longv} Tuple{shadow_very_long, shadow_very_longv} Tuple{shadow_short, shadow_shortv} Tuple{shadow_very_short, shadow_very_shortv} Tuple{near, nearv} Tuple{far, farv} Tuple{equal, equalv}:
      emit(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, name, remaining, penetration, Thresholds{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}, history,
        Pattern.Frame{bar, Bar.body(~N, ~sub, ~abs, bar), Bar.upper_shadow(~N, ~sub, ~max, bar), Bar.lower_shadow(~N, ~sub, ~min, bar),
          bar.color(~N, ~from_u32, ~sub, ~ge, bar),
          Pattern.Values{value(~N, ~from_u32, body_longv), value(~N, ~from_u32, body_very_longv), value(~N, ~from_u32, body_shortv), value(~N, ~from_u32, body_dojiv), value(~N, ~from_u32, shadow_longv), value(~N, ~from_u32, shadow_very_longv), value(~N, ~from_u32, shadow_shortv), value(~N, ~from_u32, shadow_very_shortv), value(~N, ~from_u32, nearv), value(~N, ~from_u32, farv), value(~N, ~from_u32, equalv)}})

def next(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, state: State<N>, +bar: Bar.OHLC<N>) -> State<N> & Maybe<&2, Pattern.Signal>:
  match state:
    case State{name, remaining, penetration, Thresholds{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}, history}:
      advanced(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, name, remaining, penetration, history, bar,
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, body_long, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, body_very_long, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, body_short, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, body_doji, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, shadow_long, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, shadow_very_long, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, shadow_short, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, shadow_very_short, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, near, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, far, bar),
        Candle.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, equal, bar))
