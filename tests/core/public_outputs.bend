import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA

def near(actual: F32, expected: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(actual, expected)), 0.0001)

def macd(result: Result<&2, &2, TA.Parameter.Error(), List<&2, Maybe<&2, TA.MACD.Value()>>>) -> Bool:
  match result:
    case Done{[None{}, None{}, None{}, None{}, None{}, Some{+value}]}:
      Bool.and(near(TA.MACD.line(value), 0.71111111),
        Bool.and(near(TA.MACD.signal(value), 0.01481481),
          near(TA.MACD.histogram(value), 0.69629630)))
    case _: False{}

def bands(result: Result<&2, &2, TA.Parameter.Error(), List<&2, Maybe<&2, TA.BBANDS.Value()>>>) -> Bool:
  match result:
    case Done{[None{}, Some{+value}]}:
      Bool.and(F32.is_eq(TA.BBANDS.upper(value), 3.0),
        Bool.and(F32.is_eq(TA.BBANDS.middle(value), 1.0), F32.is_eq(TA.BBANDS.lower(value), 0.0)))
    case _: False{}

def atr_error(result: Result<&2, &2, TA.Parameter.Error(), List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Fail{error}: True{}
    case Done{values}: False{}

def stochastic(result: Result<&2, &2, TA.Parameter.Error(), List<&2, Maybe<&2, TA.STOCH.Value()>>>) -> Bool:
  match result:
    case Done{[None{}, None{}, Some{+value}]}:
      Bool.and(near(TA.STOCH.k(value), 80.0),
        Bool.and(near(TA.STOCH.d(value), 60.0), near(TA.STOCH.j(value), 120.0)))
    case _: False{}

def trend(result: Result<&2, &2, TA.Parameter.Error(), List<&2, Maybe<&2, TA.SUPERTREND.Value()>>>) -> Bool:
  match result:
    case Done{[None{}, None{}, Some{+up}, Some{+down}]}:
      Bool.and(Bool.and(TA.SUPERTREND.is_up(up), near(TA.SUPERTREND.line(up), 2.0)),
        Bool.and(Bool.not(TA.SUPERTREND.is_up(down)), near(TA.SUPERTREND.line(down), 5.75)))
    case _: False{}

def pattern(result: Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>) -> Bool:
  match result:
    case Done{[None{}, None{}, Some{+value}]}:
      Bool.and(TA.Pattern.negative(value), U32.is_eq(TA.Pattern.strength(value), 100))
    case _: False{}

def shift(+value: TA.DisplayShift(), backward: Bool, bars: U32) -> Bool:
  Bool.and(Bool.not(Bool.xor(TA.DisplayShift.backward(value), backward)), U32.is_eq(TA.DisplayShift.bars(value), bars))

def heikin_ashi(values: List<&2, Maybe<&2, TA.HA.Value()>>) -> Bool:
  match values:
    case [Some{+value}]:
      Bool.and(Bool.and(near(TA.Bar.open(value), 3.0), near(TA.Bar.high(value), 8.0)),
        Bool.and(near(TA.Bar.low(value), 1.0), near(TA.Bar.close(value), 3.75)))
    case _: False{}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("public MACD fields", macd(TA.MACD.batch([10.0, 11.0, 9.0, 12.0, 8.0, 13.0], 2, 4, 3)))
    Unit <- Assert.check("public Bollinger Bands fields", bands(TA.BBANDS.batch([0.0, 2.0], 2, 2.0, 1.0, 0)))
    Unit <- Assert.check("public stochastic fields", stochastic(TA.STOCH.batch([TA.Bar.hlc(10.0, 0.0, 2.0), TA.Bar.hlc(10.0, 0.0, 4.0), TA.Bar.hlc(10.0, 0.0, 8.0)], 2, 1, TA.MA.Kind.SMA(), 2, TA.MA.Kind.SMA())))
    Unit <- Assert.check("public Supertrend fields", trend(TA.SUPERTREND.batch([TA.Bar.hlc(8.0, 4.0, 6.0), TA.Bar.hlc(8.0, 4.0, 6.0), TA.Bar.hlc(8.0, 4.0, 6.0), TA.Bar.hlc(1.5, 0.5, 1.0)], 2, 1.0)))
    Unit <- Assert.check("public pattern signal fields", pattern(TA.CDLENGULFING.batch([TA.Bar.ohlc(2.0, 2.0, 2.0, 2.0), TA.Bar.ohlc(1.0, 4.0, 1.0, 3.0), TA.Bar.ohlc(4.0, 4.0, 0.0, 0.0)])))
    Unit <- Assert.check("public display shift fields", Bool.and(shift(TA.DPO.display_shift(4), True{}, 3), shift(TA.ICHIMOKU.display_shift(26), False{}, 26)))
    Unit <- Assert.check("public Heikin Ashi fields", heikin_ashi(TA.HA.batch([TA.Bar.ohlc(2.0, 8.0, 1.0, 4.0)])))
    Assert.check("public ATR parameter error", atr_error(TA.ATR.batch([TA.Bar.hlc(10.0, 5.0, 8.0)], 0)))
