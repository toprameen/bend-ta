import Base
import ./bar.bend as Bar
import ./candle.bend as Candle
import ./config.bend as Config
import ./parameters.bend as Parameters

type Name is Data:
  CDL2CROWS{}
  CDL3BLACKCROWS{}
  CDL3INSIDE{}
  CDL3LINESTRIKE{}
  CDL3OUTSIDE{}
  CDL3STARSINSOUTH{}
  CDL3WHITESOLDIERS{}
  CDLABANDONEDBABY{}
  CDLADVANCEBLOCK{}
  CDLBELTHOLD{}
  CDLBREAKAWAY{}
  CDLCLOSINGMARUBOZU{}
  CDLCONCEALBABYSWALL{}
  CDLCOUNTERATTACK{}
  CDLDARKCLOUDCOVER{}
  CDLDOJI{}
  CDLDOJISTAR{}
  CDLDRAGONFLYDOJI{}
  CDLENGULFING{}
  CDLEVENINGDOJISTAR{}
  CDLEVENINGSTAR{}
  CDLGAPSIDESIDEWHITE{}
  CDLGRAVESTONEDOJI{}
  CDLHAMMER{}
  CDLHANGINGMAN{}
  CDLHARAMI{}
  CDLHARAMICROSS{}
  CDLHIGHWAVE{}
  CDLHOMINGPIGEON{}
  CDLIDENTICAL3CROWS{}
  CDLINNECK{}
  CDLINVERTEDHAMMER{}
  CDLKICKING{}
  CDLKICKINGBYLENGTH{}
  CDLLADDERBOTTOM{}
  CDLLONGLEGGEDDOJI{}
  CDLLONGLINE{}
  CDLMARUBOZU{}
  CDLMATCHINGLOW{}
  CDLMATHOLD{}
  CDLMORNINGDOJISTAR{}
  CDLMORNINGSTAR{}
  CDLONNECK{}
  CDLPIERCING{}
  CDLRICKSHAWMAN{}
  CDLRISEFALL3METHODS{}
  CDLSEPARATINGLINES{}
  CDLSHOOTINGSTAR{}
  CDLSHORTLINE{}
  CDLSPINNINGTOP{}
  CDLSTALLEDPATTERN{}
  CDLSTICKSANDWICH{}
  CDLTAKURI{}
  CDLTASUKIGAP{}
  CDLTHRUSTING{}
  CDLTRISTAR{}
  CDLUNIQUE3RIVER{}
  CDLUPSIDEGAP2CROWS{}
  CDLXSIDEGAP3METHODS{}

type Signal is Data:
  Signal{negative: Bool, strength: U32}

def Signal.show(value: Signal) -> String:
  match value:
    case Signal{negative, strength}:
      String.join([Bool.pick(String, negative, "-", ""), U32.show(strength)], "")

type Settings<-N: Data> is Data:
  Settings{body_long: Candle.Setting<N>, body_very_long: Candle.Setting<N>, body_short: Candle.Setting<N>, body_doji: Candle.Setting<N>, shadow_long: Candle.Setting<N>, shadow_very_long: Candle.Setting<N>, shadow_short: Candle.Setting<N>, shadow_very_short: Candle.Setting<N>, near: Candle.Setting<N>, far: Candle.Setting<N>, equal: Candle.Setting<N>}

def defaults(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N) -> Settings<N>:
  Settings{Candle.defaults(~N, ~from_u32, ~div, Candle.BodyLong{}), Candle.defaults(~N, ~from_u32, ~div, Candle.BodyVeryLong{}), Candle.defaults(~N, ~from_u32, ~div, Candle.BodyShort{}), Candle.defaults(~N, ~from_u32, ~div, Candle.BodyDoji{}), Candle.defaults(~N, ~from_u32, ~div, Candle.ShadowLong{}), Candle.defaults(~N, ~from_u32, ~div, Candle.ShadowVeryLong{}), Candle.defaults(~N, ~from_u32, ~div, Candle.ShadowShort{}), Candle.defaults(~N, ~from_u32, ~div, Candle.ShadowVeryShort{}), Candle.defaults(~N, ~from_u32, ~div, Candle.Near{}), Candle.defaults(~N, ~from_u32, ~div, Candle.Far{}), Candle.defaults(~N, ~from_u32, ~div, Candle.Equal{})}

def period(~N: Data, setting: Candle.Setting<N>) -> U32:
  match setting:
    case Candle.Setting{kind, period, factor}: period

def lookback(~N: Data, settings: Settings<N>, name: Name) -> U32:
  match settings:
    case Settings{+body_long, +body_very_long, +body_short, +body_doji, +shadow_long, +shadow_very_long, +shadow_short, +shadow_very_short, +near, +far, +equal}:
      match name:
        case CDL2CROWS{}: U32.add(period(~N, body_long), 2)
        case CDL3BLACKCROWS{}: U32.add(period(~N, shadow_very_short), 3)
        case CDL3INSIDE{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 2)
        case CDL3LINESTRIKE{}: U32.add(period(~N, near), 3)
        case CDL3OUTSIDE{}: 3
        case CDL3STARSINSOUTH{}: U32.add(U32.max(U32.max(period(~N, shadow_very_short), period(~N, shadow_long)), U32.max(period(~N, body_long), period(~N, body_short))), 2)
        case CDL3WHITESOLDIERS{}: U32.add(U32.max(U32.max(period(~N, shadow_very_short), period(~N, body_short)), U32.max(period(~N, far), period(~N, near))), 2)
        case CDLABANDONEDBABY{}: U32.add(U32.max(U32.max(period(~N, body_doji), period(~N, body_long)), period(~N, body_short)), 2)
        case CDLADVANCEBLOCK{}: U32.add(U32.max(U32.max(U32.max(period(~N, shadow_long), period(~N, shadow_short)), U32.max(period(~N, far), period(~N, near))), period(~N, body_long)), 2)
        case CDLBELTHOLD{}: U32.max(period(~N, body_long), period(~N, shadow_very_short))
        case CDLBREAKAWAY{}: U32.add(period(~N, body_long), 4)
        case CDLCLOSINGMARUBOZU{}: U32.max(period(~N, body_long), period(~N, shadow_very_short))
        case CDLCONCEALBABYSWALL{}: U32.add(period(~N, shadow_very_short), 3)
        case CDLCOUNTERATTACK{}: U32.add(U32.max(period(~N, equal), period(~N, body_long)), 1)
        case CDLDARKCLOUDCOVER{}: U32.add(period(~N, body_long), 1)
        case CDLDOJI{}: period(~N, body_doji)
        case CDLDOJISTAR{}: U32.add(U32.max(period(~N, body_doji), period(~N, body_long)), 1)
        case CDLDRAGONFLYDOJI{}: U32.max(period(~N, body_doji), period(~N, shadow_very_short))
        case CDLENGULFING{}: 2
        case CDLEVENINGDOJISTAR{}: U32.add(U32.max(U32.max(period(~N, body_doji), period(~N, body_long)), period(~N, body_short)), 2)
        case CDLEVENINGSTAR{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 2)
        case CDLGAPSIDESIDEWHITE{}: U32.add(U32.max(period(~N, near), period(~N, equal)), 2)
        case CDLGRAVESTONEDOJI{}: U32.max(period(~N, body_doji), period(~N, shadow_very_short))
        case CDLHAMMER{}: U32.add(U32.max(U32.max(U32.max(period(~N, body_short), period(~N, shadow_long)), period(~N, shadow_very_short)), period(~N, near)), 1)
        case CDLHANGINGMAN{}: U32.add(U32.max(U32.max(U32.max(period(~N, body_short), period(~N, shadow_long)), period(~N, shadow_very_short)), period(~N, near)), 1)
        case CDLHARAMI{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 1)
        case CDLHARAMICROSS{}: U32.add(U32.max(period(~N, body_doji), period(~N, body_long)), 1)
        case CDLHIGHWAVE{}: U32.max(period(~N, body_short), period(~N, shadow_very_long))
        case CDLHOMINGPIGEON{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 1)
        case CDLIDENTICAL3CROWS{}: U32.add(U32.max(period(~N, shadow_very_short), period(~N, equal)), 2)
        case CDLINNECK{}: U32.add(U32.max(period(~N, equal), period(~N, body_long)), 1)
        case CDLINVERTEDHAMMER{}: U32.add(U32.max(U32.max(period(~N, body_short), period(~N, shadow_long)), period(~N, shadow_very_short)), 1)
        case CDLKICKING{}: U32.add(U32.max(period(~N, shadow_very_short), period(~N, body_long)), 1)
        case CDLKICKINGBYLENGTH{}: U32.add(U32.max(period(~N, shadow_very_short), period(~N, body_long)), 1)
        case CDLLADDERBOTTOM{}: U32.add(period(~N, shadow_very_short), 4)
        case CDLLONGLEGGEDDOJI{}: U32.max(period(~N, body_doji), period(~N, shadow_long))
        case CDLLONGLINE{}: U32.max(period(~N, body_long), period(~N, shadow_short))
        case CDLMARUBOZU{}: U32.max(period(~N, body_long), period(~N, shadow_very_short))
        case CDLMATCHINGLOW{}: U32.add(period(~N, equal), 1)
        case CDLMATHOLD{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 4)
        case CDLMORNINGDOJISTAR{}: U32.add(U32.max(U32.max(period(~N, body_doji), period(~N, body_long)), period(~N, body_short)), 2)
        case CDLMORNINGSTAR{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 2)
        case CDLONNECK{}: U32.add(U32.max(period(~N, equal), period(~N, body_long)), 1)
        case CDLPIERCING{}: U32.add(period(~N, body_long), 1)
        case CDLRICKSHAWMAN{}: U32.max(U32.max(period(~N, body_doji), period(~N, shadow_long)), period(~N, near))
        case CDLRISEFALL3METHODS{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 4)
        case CDLSEPARATINGLINES{}: U32.add(U32.max(U32.max(period(~N, shadow_very_short), period(~N, body_long)), period(~N, equal)), 1)
        case CDLSHOOTINGSTAR{}: U32.add(U32.max(U32.max(period(~N, body_short), period(~N, shadow_long)), period(~N, shadow_very_short)), 1)
        case CDLSHORTLINE{}: U32.max(period(~N, body_short), period(~N, shadow_short))
        case CDLSPINNINGTOP{}: period(~N, body_short)
        case CDLSTALLEDPATTERN{}: U32.add(U32.max(U32.max(period(~N, body_long), period(~N, body_short)), U32.max(period(~N, shadow_very_short), period(~N, near))), 2)
        case CDLSTICKSANDWICH{}: U32.add(period(~N, equal), 2)
        case CDLTAKURI{}: U32.max(U32.max(period(~N, body_doji), period(~N, shadow_very_short)), period(~N, shadow_very_long))
        case CDLTASUKIGAP{}: U32.add(period(~N, near), 2)
        case CDLTHRUSTING{}: U32.add(U32.max(period(~N, equal), period(~N, body_long)), 1)
        case CDLTRISTAR{}: U32.add(period(~N, body_doji), 2)
        case CDLUNIQUE3RIVER{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 2)
        case CDLUPSIDEGAP2CROWS{}: U32.add(U32.max(period(~N, body_short), period(~N, body_long)), 2)
        case CDLXSIDEGAP3METHODS{}: 2

def setting.valid(~N: Data, ~finite: N -> Bool, ~ge: N -> N -> Bool, ~from_u32: U32 -> N, setting: Candle.Setting<N>) -> Bool:
  match setting:
    case Candle.Setting{kind, +period, +factor}:
      Bool.and(U32.is_le(period, Config.max_period()), Bool.and(finite(factor), ge(factor, from_u32(0))))

def settings.valid(~N: Data, ~finite: N -> Bool, ~ge: N -> N -> Bool, ~from_u32: U32 -> N, settings: Settings<N>) -> Bool:
  match settings:
    case Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}:
      Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, body_long), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, body_very_long), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, body_short), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, body_doji), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, shadow_long), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, shadow_very_long), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, shadow_short), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, shadow_very_short), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, near), Bool.and(setting.valid(~N, ~finite, ~ge, ~from_u32, far), setting.valid(~N, ~finite, ~ge, ~from_u32, equal)))))))))))

type Values<-N: Data> is Data:
  Values{body_long: N, body_very_long: N, body_short: N, body_doji: N, shadow_long: N, shadow_very_long: N, shadow_short: N, shadow_very_short: N, near: N, far: N, equal: N}

type Frame<-N: Data> is Data:
  Frame{bar: Bar.OHLC<N>, body: N, upper: N, lower: N, color: N, values: Values<N>}

def open(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{Bar.OHLC{open, high, low, close}, body, upper, lower, color, values}: open

def high(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{Bar.OHLC{open, high, low, close}, body, upper, lower, color, values}: high

def low(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{Bar.OHLC{open, high, low, close}, body, upper, lower, color, values}: low

def close(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{Bar.OHLC{open, high, low, close}, body, upper, lower, color, values}: close

def body(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, values}: body

def upper(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, values}: upper

def lower(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, values}: lower

def color(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, values}: color

def body_long(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: body_long

def body_very_long(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: body_very_long

def body_short(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: body_short

def body_doji(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: body_doji

def shadow_long(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: shadow_long

def shadow_very_long(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: shadow_very_long

def shadow_short(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: shadow_short

def shadow_very_short(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: shadow_very_short

def near(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: near

def far(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: far

def equal(~N: Data, frame: Frame<N>) -> N:
  match frame:
    case Frame{bar, body, upper, lower, color, Values{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}}: equal

def frame.zero(~N: Data, ~from_u32: U32 -> N) -> Frame<N>:
  +zero = from_u32(0)
  Frame{Bar.OHLC{zero, zero, zero, zero}, zero, zero, zero, from_u32(1), Values{zero, zero, zero, zero, zero, zero, zero, zero, zero, zero, zero}}

def CDL2CROWS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), from_u32(1)),
  gt(body(~N, f2), body_long(~N, f2))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))), gt(min(open(~N, f1), close(~N,
  f1)), max(open(~N, f2), close(~N, f2)))), eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), lt(open(~N, f0), open(~N,
  f1))), gt(open(~N, f0), close(~N, f1))), gt(close(~N, f0), open(~N, f2))), lt(close(~N, f0), close(~N, f2))),
  Signal{True{}, 100}, Signal{False{}, 0})

def CDL3BLACKCROWS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N,
  f3), from_u32(1)), eq(color(~N, f2), sub(from_u32(0), from_u32(1)))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))),
  eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), lt(open(~N, f1), open(~N, f2))), gt(open(~N, f1), close(~N, f2))),
  lt(open(~N, f0), open(~N, f1))), gt(open(~N, f0), close(~N, f1))), gt(high(~N, f3), close(~N, f2))), gt(close(~N, f2),
  close(~N, f1))), gt(close(~N, f1), close(~N, f0))), lt(lower(~N, f2), shadow_very_short(~N, f2))), lt(lower(~N, f1),
  shadow_very_short(~N, f1))), lt(lower(~N, f0), shadow_very_short(~N, f0))), Signal{True{}, 100}, Signal{False{}, 0})

def CDL3INSIDE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(lt(max(close(~N, f1), open(~N, f1)), max(close(~N, f2), open(~N,
  f2))), gt(min(close(~N, f1), open(~N, f1)), min(close(~N, f2), open(~N, f2)))), Bool.or(Bool.and(Bool.and(eq(color(~N, f2),
  from_u32(1)), eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), lt(close(~N, f0), open(~N, f2))),
  Bool.and(Bool.and(eq(color(~N, f2), sub(from_u32(0), from_u32(1))), eq(color(~N, f0), from_u32(1))), gt(close(~N, f0),
  open(~N, f2))))), gt(body(~N, f2), body_long(~N, f2))), le(body(~N, f1), body_short(~N, f1))), Signal{lt(sub(from_u32(0),
  color(~N, f2)), from_u32(0)), 100}, Signal{False{}, 0})

def CDL3LINESTRIKE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f3), color(~N, f2)),
  eq(color(~N, f2), color(~N, f1))), eq(color(~N, f0), sub(from_u32(0), color(~N, f1)))), ge(open(~N, f2), sub(min(open(~N,
  f3), close(~N, f3)), near(~N, f3)))), le(open(~N, f2), add(max(open(~N, f3), close(~N, f3)), near(~N, f3)))), ge(open(~N,
  f1), sub(min(open(~N, f2), close(~N, f2)), near(~N, f2)))), le(open(~N, f1), add(max(open(~N, f2), close(~N, f2)), near(~N,
  f2)))), Bool.or(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), from_u32(1)), gt(close(~N, f1), close(~N, f2))),
  gt(close(~N, f2), close(~N, f3))), gt(open(~N, f0), close(~N, f1))), lt(close(~N, f0), open(~N, f3))),
  Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))), lt(close(~N, f1), close(~N, f2))),
  lt(close(~N, f2), close(~N, f3))), lt(open(~N, f0), close(~N, f1))), gt(close(~N, f0), open(~N, f3))))),
  Signal{lt(color(~N, f1), from_u32(0)), 100}, Signal{False{}, 0})

def CDL3OUTSIDE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.or(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), from_u32(1)), eq(color(~N, f2),
  sub(from_u32(0), from_u32(1)))), gt(close(~N, f1), open(~N, f2))), lt(open(~N, f1), close(~N, f2))), gt(close(~N, f0),
  close(~N, f1))), Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))), eq(color(~N, f2),
  from_u32(1))), gt(open(~N, f1), close(~N, f2))), lt(close(~N, f1), open(~N, f2))), lt(close(~N, f0), close(~N, f1)))),
  Signal{lt(color(~N, f1), from_u32(0)), 100}, Signal{False{}, 0})

def CDL3STARSINSOUTH(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N,
  f2), sub(from_u32(0), from_u32(1))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))), eq(color(~N, f0), sub(from_u32(0),
  from_u32(1)))), gt(body(~N, f2), body_long(~N, f2))), gt(lower(~N, f2), shadow_long(~N, f2))), lt(body(~N, f1), body(~N,
  f2))), gt(open(~N, f1), close(~N, f2))), le(open(~N, f1), high(~N, f2))), lt(low(~N, f1), close(~N, f2))), ge(low(~N, f1),
  low(~N, f2))), gt(lower(~N, f1), shadow_very_short(~N, f1))), lt(body(~N, f0), body_short(~N, f0))), lt(lower(~N, f0),
  shadow_very_short(~N, f0))), lt(upper(~N, f0), shadow_very_short(~N, f0))), gt(low(~N, f0), low(~N, f1))), lt(high(~N, f0),
  high(~N, f1))), Signal{False{}, 100}, Signal{False{}, 0})

def CDL3WHITESOLDIERS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N,
  f2), from_u32(1)), lt(upper(~N, f2), shadow_very_short(~N, f2))), eq(color(~N, f1), from_u32(1))), lt(upper(~N, f1),
  shadow_very_short(~N, f1))), eq(color(~N, f0), from_u32(1))), lt(upper(~N, f0), shadow_very_short(~N, f0))), gt(close(~N,
  f0), close(~N, f1))), gt(close(~N, f1), close(~N, f2))), gt(open(~N, f1), open(~N, f2))), le(open(~N, f1), add(close(~N,
  f2), near(~N, f2)))), gt(open(~N, f0), open(~N, f1))), le(open(~N, f0), add(close(~N, f1), near(~N, f1)))), gt(body(~N,
  f1), sub(body(~N, f2), far(~N, f2)))), gt(body(~N, f0), sub(body(~N, f1), far(~N, f1)))), gt(body(~N, f0), body_short(~N,
  f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLABANDONEDBABY(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(gt(body(~N, f2), body_long(~N, f2)), le(body(~N, f1), body_doji(~N, f1))),
  gt(body(~N, f0), body_short(~N, f0))), Bool.or(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), from_u32(1)),
  eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), lt(close(~N, f0), sub(close(~N, f2), mul(body(~N, f2), penetration)))),
  gt(low(~N, f1), high(~N, f2))), lt(high(~N, f0), low(~N, f1))), Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2),
  sub(from_u32(0), from_u32(1))), eq(color(~N, f0), from_u32(1))), gt(close(~N, f0), add(close(~N, f2), mul(body(~N, f2),
  penetration)))), lt(high(~N, f1), low(~N, f2))), gt(low(~N, f0), high(~N, f1))))), Signal{lt(color(~N, f0), from_u32(0)),
  100}, Signal{False{}, 0})

def CDLADVANCEBLOCK(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2),
  from_u32(1)), eq(color(~N, f1), from_u32(1))), eq(color(~N, f0), from_u32(1))), gt(close(~N, f0), close(~N, f1))),
  gt(close(~N, f1), close(~N, f2))), gt(open(~N, f1), open(~N, f2))), le(open(~N, f1), add(close(~N, f2), near(~N, f2)))),
  gt(open(~N, f0), open(~N, f1))), le(open(~N, f0), add(close(~N, f1), near(~N, f1)))), gt(body(~N, f2), body_long(~N, f2))),
  lt(upper(~N, f2), shadow_short(~N, f2))), Bool.or(Bool.or(Bool.or(Bool.and(lt(body(~N, f1), sub(body(~N, f2), far(~N,
  f2))), lt(body(~N, f0), add(body(~N, f1), near(~N, f1)))), lt(body(~N, f0), sub(body(~N, f1), far(~N, f1)))),
  Bool.and(Bool.and(lt(body(~N, f0), body(~N, f1)), lt(body(~N, f1), body(~N, f2))), Bool.or(gt(upper(~N, f0),
  shadow_short(~N, f0)), gt(upper(~N, f1), shadow_short(~N, f1))))), Bool.and(lt(body(~N, f0), body(~N, f1)), gt(upper(~N,
  f0), shadow_long(~N, f0))))), Signal{True{}, 100}, Signal{False{}, 0})

def CDLBELTHOLD(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(gt(body(~N, f0), body_long(~N, f0)), Bool.or(Bool.and(eq(color(~N, f0), from_u32(1)),
  lt(lower(~N, f0), shadow_very_short(~N, f0))), Bool.and(eq(color(~N, f0), sub(from_u32(0), from_u32(1))), lt(upper(~N, f0),
  shadow_very_short(~N, f0))))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLBREAKAWAY(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f4), color(~N, f3)), eq(color(~N, f3), color(~N, f1))),
  eq(color(~N, f1), sub(from_u32(0), color(~N, f0)))), gt(body(~N, f4), body_long(~N, f4))),
  Bool.or(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f4), sub(from_u32(0), from_u32(1))),
  lt(max(open(~N, f3), close(~N, f3)), min(open(~N, f4), close(~N, f4)))), lt(high(~N, f2), high(~N, f3))), lt(low(~N, f2),
  low(~N, f3))), lt(high(~N, f1), high(~N, f2))), lt(low(~N, f1), low(~N, f2))), gt(close(~N, f0), open(~N, f3))),
  lt(close(~N, f0), close(~N, f4))), Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f4),
  from_u32(1)), gt(min(open(~N, f3), close(~N, f3)), max(open(~N, f4), close(~N, f4)))), gt(high(~N, f2), high(~N, f3))),
  gt(low(~N, f2), low(~N, f3))), gt(high(~N, f1), high(~N, f2))), gt(low(~N, f1), low(~N, f2))), lt(close(~N, f0), open(~N,
  f3))), gt(close(~N, f0), close(~N, f4))))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLCLOSINGMARUBOZU(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(gt(body(~N, f0), body_long(~N, f0)), Bool.or(Bool.and(eq(color(~N, f0), from_u32(1)),
  lt(upper(~N, f0), shadow_very_short(~N, f0))), Bool.and(eq(color(~N, f0), sub(from_u32(0), from_u32(1))), lt(lower(~N, f0),
  shadow_very_short(~N, f0))))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLCONCEALBABYSWALL(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N,
  f3), sub(from_u32(0), from_u32(1))), eq(color(~N, f2), sub(from_u32(0), from_u32(1)))), eq(color(~N, f1), sub(from_u32(0),
  from_u32(1)))), eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), lt(lower(~N, f3), shadow_very_short(~N, f3))),
  lt(upper(~N, f3), shadow_very_short(~N, f3))), lt(lower(~N, f2), shadow_very_short(~N, f2))), lt(upper(~N, f2),
  shadow_very_short(~N, f2))), lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2), close(~N, f2)))), gt(upper(~N, f1),
  shadow_very_short(~N, f1))), gt(high(~N, f1), close(~N, f2))), gt(high(~N, f0), high(~N, f1))), lt(low(~N, f0), low(~N,
  f1))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLCOUNTERATTACK(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), color(~N, f0))), gt(body(~N, f1),
  body_long(~N, f1))), gt(body(~N, f0), body_long(~N, f0))), le(close(~N, f0), add(close(~N, f1), equal(~N, f1)))),
  ge(close(~N, f0), sub(close(~N, f1), equal(~N, f1)))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLDARKCLOUDCOVER(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), from_u32(1)), gt(body(~N, f1),
  body_long(~N, f1))), eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), gt(open(~N, f0), high(~N, f1))), gt(close(~N, f0),
  open(~N, f1))), lt(close(~N, f0), sub(close(~N, f1), mul(body(~N, f1), penetration)))), Signal{True{}, 100},
  Signal{False{}, 0})

def CDLDOJI(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, le(body(~N, f0), body_doji(~N, f0)), Signal{False{}, 100}, Signal{False{}, 0})

def CDLDOJISTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(gt(body(~N, f1), body_long(~N, f1)), le(body(~N, f0), body_doji(~N, f0))),
  Bool.or(Bool.and(eq(color(~N, f1), from_u32(1)), gt(min(open(~N, f0), close(~N, f0)), max(open(~N, f1), close(~N, f1)))),
  Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))), lt(max(open(~N, f0), close(~N, f0)), min(open(~N, f1), close(~N,
  f1)))))), Signal{lt(sub(from_u32(0), color(~N, f1)), from_u32(0)), 100}, Signal{False{}, 0})

def CDLDRAGONFLYDOJI(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(le(body(~N, f0), body_doji(~N, f0)), lt(upper(~N, f0), shadow_very_short(~N, f0))),
  gt(lower(~N, f0), shadow_very_short(~N, f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLENGULFING(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.or(Bool.and(Bool.and(eq(color(~N, f0), from_u32(1)), eq(color(~N, f1), sub(from_u32(0),
  from_u32(1)))), Bool.or(Bool.and(ge(close(~N, f0), open(~N, f1)), lt(open(~N, f0), close(~N, f1))), Bool.and(gt(close(~N,
  f0), open(~N, f1)), le(open(~N, f0), close(~N, f1))))), Bool.and(Bool.and(eq(color(~N, f0), sub(from_u32(0), from_u32(1))),
  eq(color(~N, f1), from_u32(1))), Bool.or(Bool.and(ge(open(~N, f0), close(~N, f1)), lt(close(~N, f0), open(~N, f1))),
  Bool.and(gt(open(~N, f0), close(~N, f1)), le(close(~N, f0), open(~N, f1)))))), Bool.pick(Signal,
  Bool.and(Bool.not(eq(open(~N, f0), close(~N, f1))), Bool.not(eq(close(~N, f0), open(~N, f1)))), Signal{lt(color(~N, f0),
  from_u32(0)), 100}, Signal{lt(color(~N, f0), from_u32(0)), 80}), Signal{False{}, 0})

def CDLEVENINGDOJISTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), from_u32(1)), eq(color(~N, f0),
  sub(from_u32(0), from_u32(1)))), gt(min(open(~N, f1), close(~N, f1)), max(open(~N, f2), close(~N, f2)))), lt(close(~N, f0),
  sub(close(~N, f2), mul(body(~N, f2), penetration)))), gt(body(~N, f2), body_long(~N, f2))), le(body(~N, f1), body_doji(~N,
  f1))), gt(body(~N, f0), body_short(~N, f0))), Signal{True{}, 100}, Signal{False{}, 0})

def CDLEVENINGSTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), from_u32(1)), eq(color(~N, f0),
  sub(from_u32(0), from_u32(1)))), gt(min(open(~N, f1), close(~N, f1)), max(open(~N, f2), close(~N, f2)))), lt(close(~N, f0),
  sub(close(~N, f2), mul(body(~N, f2), penetration)))), gt(body(~N, f2), body_long(~N, f2))), le(body(~N, f1), body_short(~N,
  f1))), gt(body(~N, f0), body_short(~N, f0))), Signal{True{}, 100}, Signal{False{}, 0})

def CDLGAPSIDESIDEWHITE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.or(Bool.and(gt(min(open(~N, f1), close(~N,
  f1)), max(open(~N, f2), close(~N, f2))), gt(min(open(~N, f0), close(~N, f0)), max(open(~N, f2), close(~N, f2)))),
  Bool.and(lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2), close(~N, f2))), lt(max(open(~N, f0), close(~N, f0)),
  min(open(~N, f2), close(~N, f2))))), eq(color(~N, f1), from_u32(1))), eq(color(~N, f0), from_u32(1))), ge(body(~N, f0),
  sub(body(~N, f1), near(~N, f1)))), le(body(~N, f0), add(body(~N, f1), near(~N, f1)))), ge(open(~N, f0), sub(open(~N, f1),
  equal(~N, f1)))), le(open(~N, f0), add(open(~N, f1), equal(~N, f1)))), Bool.pick(Signal, gt(min(open(~N, f1), close(~N,
  f1)), max(open(~N, f2), close(~N, f2))), Signal{False{}, 100}, Signal{True{}, 100}), Signal{False{}, 0})

def CDLGRAVESTONEDOJI(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(le(body(~N, f0), body_doji(~N, f0)), lt(lower(~N, f0), shadow_very_short(~N, f0))),
  gt(upper(~N, f0), shadow_very_short(~N, f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLHAMMER(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(lt(body(~N, f0), body_short(~N, f0)), gt(lower(~N, f0), shadow_long(~N, f0))),
  lt(upper(~N, f0), shadow_very_short(~N, f0))), le(min(close(~N, f0), open(~N, f0)), add(low(~N, f1), near(~N, f1)))),
  Signal{False{}, 100}, Signal{False{}, 0})

def CDLHANGINGMAN(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(lt(body(~N, f0), body_short(~N, f0)), gt(lower(~N, f0), shadow_long(~N, f0))),
  lt(upper(~N, f0), shadow_very_short(~N, f0))), ge(min(close(~N, f0), open(~N, f0)), sub(high(~N, f1), near(~N, f1)))),
  Signal{True{}, 100}, Signal{False{}, 0})

def CDLHARAMI(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, gt(body(~N, f1), body_long(~N, f1)), Bool.pick(Signal, le(body(~N, f0), body_short(~N, f0)),
  Bool.pick(Signal, Bool.and(lt(max(close(~N, f0), open(~N, f0)), max(close(~N, f1), open(~N, f1))), gt(min(close(~N, f0),
  open(~N, f0)), min(close(~N, f1), open(~N, f1)))), Signal{lt(sub(from_u32(0), color(~N, f1)), from_u32(0)), 100},
  Bool.pick(Signal, Bool.and(le(max(close(~N, f0), open(~N, f0)), max(close(~N, f1), open(~N, f1))), ge(min(close(~N, f0),
  open(~N, f0)), min(close(~N, f1), open(~N, f1)))), Signal{lt(sub(from_u32(0), color(~N, f1)), from_u32(0)), 80},
  Signal{False{}, 0})), Signal{False{}, 0}), Signal{False{}, 0})

def CDLHARAMICROSS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, gt(body(~N, f1), body_long(~N, f1)), Bool.pick(Signal, le(body(~N, f0), body_doji(~N, f0)),
  Bool.pick(Signal, Bool.and(lt(max(close(~N, f0), open(~N, f0)), max(close(~N, f1), open(~N, f1))), gt(min(close(~N, f0),
  open(~N, f0)), min(close(~N, f1), open(~N, f1)))), Signal{lt(sub(from_u32(0), color(~N, f1)), from_u32(0)), 100},
  Bool.pick(Signal, Bool.and(le(max(close(~N, f0), open(~N, f0)), max(close(~N, f1), open(~N, f1))), ge(min(close(~N, f0),
  open(~N, f0)), min(close(~N, f1), open(~N, f1)))), Signal{lt(sub(from_u32(0), color(~N, f1)), from_u32(0)), 80},
  Signal{False{}, 0})), Signal{False{}, 0}), Signal{False{}, 0})

def CDLHIGHWAVE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(lt(body(~N, f0), body_short(~N, f0)), gt(upper(~N, f0), shadow_very_long(~N, f0))),
  gt(lower(~N, f0), shadow_very_long(~N, f0))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLHOMINGPIGEON(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), gt(body(~N, f1), body_long(~N, f1))), le(body(~N, f0), body_short(~N,
  f0))), lt(open(~N, f0), open(~N, f1))), gt(close(~N, f0), close(~N, f1))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLIDENTICAL3CROWS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2),
  sub(from_u32(0), from_u32(1))), lt(lower(~N, f2), shadow_very_short(~N, f2))), eq(color(~N, f1), sub(from_u32(0),
  from_u32(1)))), lt(lower(~N, f1), shadow_very_short(~N, f1))), eq(color(~N, f0), sub(from_u32(0), from_u32(1)))),
  lt(lower(~N, f0), shadow_very_short(~N, f0))), gt(close(~N, f2), close(~N, f1))), gt(close(~N, f1), close(~N, f0))),
  le(open(~N, f1), add(close(~N, f2), equal(~N, f2)))), ge(open(~N, f1), sub(close(~N, f2), equal(~N, f2)))), le(open(~N,
  f0), add(close(~N, f1), equal(~N, f1)))), ge(open(~N, f0), sub(close(~N, f1), equal(~N, f1)))), Signal{True{}, 100},
  Signal{False{}, 0})

def CDLINNECK(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  gt(body(~N, f1), body_long(~N, f1))), eq(color(~N, f0), from_u32(1))), lt(open(~N, f0), low(~N, f1))), le(close(~N, f0),
  add(close(~N, f1), equal(~N, f1)))), ge(close(~N, f0), close(~N, f1))), Signal{True{}, 100}, Signal{False{}, 0})

def CDLINVERTEDHAMMER(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(lt(max(open(~N, f0), close(~N, f0)), min(open(~N, f1), close(~N, f1))),
  lt(body(~N, f0), body_short(~N, f0))), gt(upper(~N, f0), shadow_long(~N, f0))), lt(lower(~N, f0), shadow_very_short(~N,
  f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLKICKING(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0),
  color(~N, f0))), gt(body(~N, f1), body_long(~N, f1))), lt(upper(~N, f1), shadow_very_short(~N, f1))), lt(lower(~N, f1),
  shadow_very_short(~N, f1))), gt(body(~N, f0), body_long(~N, f0))), lt(upper(~N, f0), shadow_very_short(~N, f0))),
  lt(lower(~N, f0), shadow_very_short(~N, f0))), Bool.or(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  gt(low(~N, f0), high(~N, f1))), Bool.and(eq(color(~N, f1), from_u32(1)), lt(high(~N, f0), low(~N, f1))))),
  Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLKICKINGBYLENGTH(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0),
  color(~N, f0))), gt(body(~N, f1), body_long(~N, f1))), lt(upper(~N, f1), shadow_very_short(~N, f1))), lt(lower(~N, f1),
  shadow_very_short(~N, f1))), gt(body(~N, f0), body_long(~N, f0))), lt(upper(~N, f0), shadow_very_short(~N, f0))),
  lt(lower(~N, f0), shadow_very_short(~N, f0))), Bool.or(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  gt(low(~N, f0), high(~N, f1))), Bool.and(eq(color(~N, f1), from_u32(1)), lt(high(~N, f0), low(~N, f1))))),
  Signal{lt(color(~N, Bool.pick(Frame<N>, gt(body(~N, f0), body(~N, f1)), f0, f1)), from_u32(0)), 100}, Signal{False{}, 0})

def CDLLADDERBOTTOM(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f4),
  sub(from_u32(0), from_u32(1))), eq(color(~N, f3), sub(from_u32(0), from_u32(1)))), eq(color(~N, f2), sub(from_u32(0),
  from_u32(1)))), gt(open(~N, f4), open(~N, f3))), gt(open(~N, f3), open(~N, f2))), gt(close(~N, f4), close(~N, f3))),
  gt(close(~N, f3), close(~N, f2))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))), gt(upper(~N, f1),
  shadow_very_short(~N, f1))), eq(color(~N, f0), from_u32(1))), gt(open(~N, f0), open(~N, f1))), gt(close(~N, f0), high(~N,
  f1))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLLONGLEGGEDDOJI(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(le(body(~N, f0), body_doji(~N, f0)), Bool.or(gt(lower(~N, f0), shadow_long(~N, f0)),
  gt(upper(~N, f0), shadow_long(~N, f0)))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLLONGLINE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(gt(body(~N, f0), body_long(~N, f0)), lt(upper(~N, f0), shadow_short(~N, f0))),
  lt(lower(~N, f0), shadow_short(~N, f0))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLMARUBOZU(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(gt(body(~N, f0), body_long(~N, f0)), lt(upper(~N, f0), shadow_very_short(~N, f0))),
  lt(lower(~N, f0), shadow_very_short(~N, f0))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLMATCHINGLOW(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))), eq(color(~N, f0),
  sub(from_u32(0), from_u32(1)))), le(close(~N, f0), add(close(~N, f1), equal(~N, f1)))), ge(close(~N, f0), sub(close(~N,
  f1), equal(~N, f1)))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLMATHOLD(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N,
  f4), from_u32(1)), eq(color(~N, f3), sub(from_u32(0), from_u32(1)))), eq(color(~N, f0), from_u32(1))), gt(min(open(~N, f3),
  close(~N, f3)), max(open(~N, f4), close(~N, f4)))), lt(min(open(~N, f2), close(~N, f2)), close(~N, f4))), lt(min(open(~N,
  f1), close(~N, f1)), close(~N, f4))), gt(min(open(~N, f2), close(~N, f2)), sub(close(~N, f4), mul(body(~N, f4),
  penetration)))), gt(min(open(~N, f1), close(~N, f1)), sub(close(~N, f4), mul(body(~N, f4), penetration)))),
  lt(max(close(~N, f2), open(~N, f2)), open(~N, f3))), lt(max(close(~N, f1), open(~N, f1)), max(close(~N, f2), open(~N,
  f2)))), gt(open(~N, f0), close(~N, f1))), gt(close(~N, f0), max(max(high(~N, f3), high(~N, f2)), high(~N, f1)))),
  gt(body(~N, f4), body_long(~N, f4))), lt(body(~N, f3), body_short(~N, f3))), lt(body(~N, f2), body_short(~N, f2))),
  lt(body(~N, f1), body_short(~N, f1))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLMORNINGDOJISTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), sub(from_u32(0), from_u32(1))),
  eq(color(~N, f0), from_u32(1))), lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2), close(~N, f2)))), gt(close(~N, f0),
  add(close(~N, f2), mul(body(~N, f2), penetration)))), gt(body(~N, f2), body_long(~N, f2))), le(body(~N, f1), body_doji(~N,
  f1))), gt(body(~N, f0), body_short(~N, f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLMORNINGSTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), sub(from_u32(0), from_u32(1))),
  eq(color(~N, f0), from_u32(1))), lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2), close(~N, f2)))), gt(close(~N, f0),
  add(close(~N, f2), mul(body(~N, f2), penetration)))), gt(body(~N, f2), body_long(~N, f2))), le(body(~N, f1), body_short(~N,
  f1))), gt(body(~N, f0), body_short(~N, f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLONNECK(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  gt(body(~N, f1), body_long(~N, f1))), eq(color(~N, f0), from_u32(1))), lt(open(~N, f0), low(~N, f1))), le(close(~N, f0),
  add(low(~N, f1), equal(~N, f1)))), ge(close(~N, f0), sub(low(~N, f1), equal(~N, f1)))), Signal{True{}, 100},
  Signal{False{}, 0})

def CDLPIERCING(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  gt(body(~N, f1), body_long(~N, f1))), eq(color(~N, f0), from_u32(1))), gt(body(~N, f0), body_long(~N, f0))), lt(open(~N,
  f0), low(~N, f1))), lt(close(~N, f0), open(~N, f1))), gt(close(~N, f0), add(close(~N, f1), mul(body(~N, f1),
  div(from_u32(5), from_u32(10)))))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLRICKSHAWMAN(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(le(body(~N, f0), body_doji(~N, f0)), gt(lower(~N, f0), shadow_long(~N, f0))),
  gt(upper(~N, f0), shadow_long(~N, f0))), Bool.and(le(min(open(~N, f0), close(~N, f0)), add(add(low(~N, f0),
  div(sub(high(~N, f0), low(~N, f0)), from_u32(2))), near(~N, f0))), ge(max(open(~N, f0), close(~N, f0)), sub(add(low(~N,
  f0), div(sub(high(~N, f0), low(~N, f0)), from_u32(2))), near(~N, f0))))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLRISEFALL3METHODS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N,
  f4), sub(from_u32(0), color(~N, f3))), eq(color(~N, f3), color(~N, f2))), eq(color(~N, f2), color(~N, f1))), eq(color(~N,
  f1), sub(from_u32(0), color(~N, f0)))), lt(min(open(~N, f3), close(~N, f3)), high(~N, f4))), gt(max(open(~N, f3), close(~N,
  f3)), low(~N, f4))), lt(min(open(~N, f2), close(~N, f2)), high(~N, f4))), gt(max(open(~N, f2), close(~N, f2)), low(~N,
  f4))), lt(min(open(~N, f1), close(~N, f1)), high(~N, f4))), gt(max(open(~N, f1), close(~N, f1)), low(~N, f4))),
  lt(mul(close(~N, f2), color(~N, f4)), mul(close(~N, f3), color(~N, f4)))), lt(mul(close(~N, f1), color(~N, f4)),
  mul(close(~N, f2), color(~N, f4)))), gt(mul(open(~N, f0), color(~N, f4)), mul(close(~N, f1), color(~N, f4)))),
  gt(mul(close(~N, f0), color(~N, f4)), mul(close(~N, f4), color(~N, f4)))), gt(body(~N, f4), body_long(~N, f4))),
  lt(body(~N, f3), body_short(~N, f3))), lt(body(~N, f2), body_short(~N, f2))), lt(body(~N, f1), body_short(~N, f1))),
  gt(body(~N, f0), body_long(~N, f0))), Signal{lt(color(~N, f4), from_u32(0)), 100}, Signal{False{}, 0})

def CDLSEPARATINGLINES(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), color(~N, f0))), le(open(~N, f0),
  add(open(~N, f1), equal(~N, f1)))), ge(open(~N, f0), sub(open(~N, f1), equal(~N, f1)))), gt(body(~N, f0), body_long(~N,
  f0))), Bool.or(Bool.and(eq(color(~N, f0), from_u32(1)), lt(lower(~N, f0), shadow_very_short(~N, f0))),
  Bool.and(eq(color(~N, f0), sub(from_u32(0), from_u32(1))), lt(upper(~N, f0), shadow_very_short(~N, f0))))),
  Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLSHOOTINGSTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(gt(min(open(~N, f0), close(~N, f0)), max(open(~N, f1), close(~N, f1))),
  lt(body(~N, f0), body_short(~N, f0))), gt(upper(~N, f0), shadow_long(~N, f0))), lt(lower(~N, f0), shadow_very_short(~N,
  f0))), Signal{True{}, 100}, Signal{False{}, 0})

def CDLSHORTLINE(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(lt(body(~N, f0), body_short(~N, f0)), lt(upper(~N, f0), shadow_short(~N, f0))),
  lt(lower(~N, f0), shadow_short(~N, f0))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLSPINNINGTOP(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(gt(upper(~N, f0), body(~N, f0)), gt(lower(~N, f0), body(~N, f0))), lt(body(~N, f0),
  body_short(~N, f0))), Signal{lt(color(~N, f0), from_u32(0)), 100}, Signal{False{}, 0})

def CDLSTALLEDPATTERN(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal,
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2),
  from_u32(1)), eq(color(~N, f1), from_u32(1))), eq(color(~N, f0), from_u32(1))), gt(close(~N, f0), close(~N, f1))),
  gt(close(~N, f1), close(~N, f2))), gt(body(~N, f2), body_long(~N, f2))), gt(body(~N, f1), body_long(~N, f1))), lt(upper(~N,
  f1), shadow_very_short(~N, f1))), gt(open(~N, f1), open(~N, f2))), le(open(~N, f1), add(close(~N, f2), near(~N, f2)))),
  lt(body(~N, f0), body_short(~N, f0))), ge(open(~N, f0), sub(sub(close(~N, f1), body(~N, f0)), near(~N, f1)))),
  Signal{True{}, 100}, Signal{False{}, 0})

def CDLSTICKSANDWICH(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), sub(from_u32(0), from_u32(1))),
  eq(color(~N, f1), from_u32(1))), eq(color(~N, f0), sub(from_u32(0), from_u32(1)))), gt(low(~N, f1), close(~N, f2))),
  le(close(~N, f0), add(close(~N, f2), equal(~N, f2)))), ge(close(~N, f0), sub(close(~N, f2), equal(~N, f2)))),
  Signal{False{}, 100}, Signal{False{}, 0})

def CDLTAKURI(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(le(body(~N, f0), body_doji(~N, f0)), lt(upper(~N, f0), shadow_very_short(~N, f0))),
  gt(lower(~N, f0), shadow_very_long(~N, f0))), Signal{False{}, 100}, Signal{False{}, 0})

def CDLTASUKIGAP(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.or(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(gt(min(open(~N, f1), close(~N,
  f1)), max(open(~N, f2), close(~N, f2))), eq(color(~N, f1), from_u32(1))), eq(color(~N, f0), sub(from_u32(0),
  from_u32(1)))), lt(open(~N, f0), close(~N, f1))), gt(open(~N, f0), open(~N, f1))), lt(close(~N, f0), open(~N, f1))),
  gt(close(~N, f0), max(close(~N, f2), open(~N, f2)))), lt(abs(sub(body(~N, f1), body(~N, f0))), near(~N, f1))),
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2),
  close(~N, f2))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))), eq(color(~N, f0), from_u32(1))), lt(open(~N, f0),
  open(~N, f1))), gt(open(~N, f0), close(~N, f1))), gt(close(~N, f0), open(~N, f1))), lt(close(~N, f0), min(close(~N, f2),
  open(~N, f2)))), lt(abs(sub(body(~N, f1), body(~N, f0))), near(~N, f1)))), Signal{lt(color(~N, f1), from_u32(0)), 100},
  Signal{False{}, 0})

def CDLTHRUSTING(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f1), sub(from_u32(0), from_u32(1))),
  gt(body(~N, f1), body_long(~N, f1))), eq(color(~N, f0), from_u32(1))), lt(open(~N, f0), low(~N, f1))), gt(close(~N, f0),
  add(close(~N, f1), equal(~N, f1)))), le(close(~N, f0), add(close(~N, f1), mul(body(~N, f1), div(from_u32(5),
  from_u32(10)))))), Signal{True{}, 100}, Signal{False{}, 0})

def CDLTRISTAR(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(le(body(~N, f2), body_doji(~N, f2)), le(body(~N, f1), body_doji(~N, f2))), le(body(~N,
  f0), body_doji(~N, f2))), Bool.pick(Signal, Bool.and(lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2), close(~N,
  f2))), gt(min(open(~N, f0), close(~N, f0)), min(open(~N, f1), close(~N, f1)))), Signal{False{}, 100}, Bool.pick(Signal,
  Bool.and(gt(min(open(~N, f1), close(~N, f1)), max(open(~N, f2), close(~N, f2))), lt(max(open(~N, f0), close(~N, f0)),
  max(open(~N, f1), close(~N, f1)))), Signal{True{}, 100}, Signal{False{}, 0})), Signal{False{}, 0})

def CDLUNIQUE3RIVER(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2),
  sub(from_u32(0), from_u32(1))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))), eq(color(~N, f0), from_u32(1))),
  gt(close(~N, f1), close(~N, f2))), le(open(~N, f1), open(~N, f2))), lt(low(~N, f1), low(~N, f2))), gt(open(~N, f0), low(~N,
  f1))), gt(body(~N, f2), body_long(~N, f2))), lt(body(~N, f0), body_short(~N, f0))), Signal{False{}, 100}, Signal{False{},
  0})

def CDLUPSIDEGAP2CROWS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), from_u32(1)),
  gt(body(~N, f2), body_long(~N, f2))), eq(color(~N, f1), sub(from_u32(0), from_u32(1)))), le(body(~N, f1), body_short(~N,
  f1))), gt(min(open(~N, f1), close(~N, f1)), max(open(~N, f2), close(~N, f2)))), eq(color(~N, f0), sub(from_u32(0),
  from_u32(1)))), gt(open(~N, f0), open(~N, f1))), lt(close(~N, f0), close(~N, f1))), gt(close(~N, f0), close(~N, f2))),
  Signal{True{}, 100}, Signal{False{}, 0})

def CDLXSIDEGAP3METHODS(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  Bool.pick(Signal, Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(eq(color(~N, f2), color(~N, f1)), eq(color(~N, f1),
  sub(from_u32(0), color(~N, f0)))), lt(open(~N, f0), max(close(~N, f1), open(~N, f1)))), gt(open(~N, f0), min(close(~N, f1),
  open(~N, f1)))), lt(close(~N, f0), max(close(~N, f2), open(~N, f2)))), gt(close(~N, f0), min(close(~N, f2), open(~N,
  f2)))), Bool.or(Bool.and(eq(color(~N, f2), from_u32(1)), gt(min(open(~N, f1), close(~N, f1)), max(open(~N, f2), close(~N,
  f2)))), Bool.and(eq(color(~N, f2), sub(from_u32(0), from_u32(1))), lt(max(open(~N, f1), close(~N, f1)), min(open(~N, f2),
  close(~N, f2)))))), Signal{lt(color(~N, f2), from_u32(0)), 100}, Signal{False{}, 0})

def detect(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~ge: N -> N -> Bool, name: Name, +f0: Frame<N>, +f1: Frame<N>, +f2: Frame<N>, +f3: Frame<N>, +f4: Frame<N>, +penetration: N) -> Signal:
  match name:
    case CDL2CROWS{}: CDL2CROWS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDL3BLACKCROWS{}: CDL3BLACKCROWS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDL3INSIDE{}: CDL3INSIDE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDL3LINESTRIKE{}: CDL3LINESTRIKE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDL3OUTSIDE{}: CDL3OUTSIDE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDL3STARSINSOUTH{}: CDL3STARSINSOUTH(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDL3WHITESOLDIERS{}: CDL3WHITESOLDIERS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLABANDONEDBABY{}: CDLABANDONEDBABY(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLADVANCEBLOCK{}: CDLADVANCEBLOCK(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLBELTHOLD{}: CDLBELTHOLD(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLBREAKAWAY{}: CDLBREAKAWAY(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLCLOSINGMARUBOZU{}: CDLCLOSINGMARUBOZU(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLCONCEALBABYSWALL{}: CDLCONCEALBABYSWALL(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLCOUNTERATTACK{}: CDLCOUNTERATTACK(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLDARKCLOUDCOVER{}: CDLDARKCLOUDCOVER(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLDOJI{}: CDLDOJI(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLDOJISTAR{}: CDLDOJISTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLDRAGONFLYDOJI{}: CDLDRAGONFLYDOJI(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLENGULFING{}: CDLENGULFING(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLEVENINGDOJISTAR{}: CDLEVENINGDOJISTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLEVENINGSTAR{}: CDLEVENINGSTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLGAPSIDESIDEWHITE{}: CDLGAPSIDESIDEWHITE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLGRAVESTONEDOJI{}: CDLGRAVESTONEDOJI(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLHAMMER{}: CDLHAMMER(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLHANGINGMAN{}: CDLHANGINGMAN(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLHARAMI{}: CDLHARAMI(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLHARAMICROSS{}: CDLHARAMICROSS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLHIGHWAVE{}: CDLHIGHWAVE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLHOMINGPIGEON{}: CDLHOMINGPIGEON(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLIDENTICAL3CROWS{}: CDLIDENTICAL3CROWS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLINNECK{}: CDLINNECK(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLINVERTEDHAMMER{}: CDLINVERTEDHAMMER(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLKICKING{}: CDLKICKING(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLKICKINGBYLENGTH{}: CDLKICKINGBYLENGTH(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLLADDERBOTTOM{}: CDLLADDERBOTTOM(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLLONGLEGGEDDOJI{}: CDLLONGLEGGEDDOJI(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLLONGLINE{}: CDLLONGLINE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLMARUBOZU{}: CDLMARUBOZU(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLMATCHINGLOW{}: CDLMATCHINGLOW(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLMATHOLD{}: CDLMATHOLD(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLMORNINGDOJISTAR{}: CDLMORNINGDOJISTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLMORNINGSTAR{}: CDLMORNINGSTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLONNECK{}: CDLONNECK(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLPIERCING{}: CDLPIERCING(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLRICKSHAWMAN{}: CDLRICKSHAWMAN(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLRISEFALL3METHODS{}: CDLRISEFALL3METHODS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLSEPARATINGLINES{}: CDLSEPARATINGLINES(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLSHOOTINGSTAR{}: CDLSHOOTINGSTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLSHORTLINE{}: CDLSHORTLINE(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLSPINNINGTOP{}: CDLSPINNINGTOP(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLSTALLEDPATTERN{}: CDLSTALLEDPATTERN(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLSTICKSANDWICH{}: CDLSTICKSANDWICH(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLTAKURI{}: CDLTAKURI(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLTASUKIGAP{}: CDLTASUKIGAP(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLTHRUSTING{}: CDLTHRUSTING(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLTRISTAR{}: CDLTRISTAR(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLUNIQUE3RIVER{}: CDLUNIQUE3RIVER(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLUPSIDEGAP2CROWS{}: CDLUPSIDEGAP2CROWS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)
    case CDLXSIDEGAP3METHODS{}: CDLXSIDEGAP3METHODS(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~eq, ~lt, ~le, ~gt, ~ge, f0, f1, f2, f3, f4, penetration)


def setting(~N: Data, settings: Settings<N>, name: Candle.Name, +replacement: Candle.Setting<N>) -> Settings<N>:
  match settings:
    case Settings{+body_long, +body_very_long, +body_short, +body_doji, +shadow_long, +shadow_very_long, +shadow_short, +shadow_very_short, +near, +far, +equal}:
      match name:
        case Candle.BodyLong{}: Settings{replacement, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}
        case Candle.BodyVeryLong{}: Settings{body_long, replacement, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}
        case Candle.BodyShort{}: Settings{body_long, body_very_long, replacement, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}
        case Candle.BodyDoji{}: Settings{body_long, body_very_long, body_short, replacement, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}
        case Candle.ShadowLong{}: Settings{body_long, body_very_long, body_short, body_doji, replacement, shadow_very_long, shadow_short, shadow_very_short, near, far, equal}
        case Candle.ShadowVeryLong{}: Settings{body_long, body_very_long, body_short, body_doji, shadow_long, replacement, shadow_short, shadow_very_short, near, far, equal}
        case Candle.ShadowShort{}: Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, replacement, shadow_very_short, near, far, equal}
        case Candle.ShadowVeryShort{}: Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, replacement, near, far, equal}
        case Candle.Near{}: Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, replacement, far, equal}
        case Candle.Far{}: Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, replacement, equal}
        case Candle.Equal{}: Settings{body_long, body_very_long, body_short, body_doji, shadow_long, shadow_very_long, shadow_short, shadow_very_short, near, far, replacement}
