import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA

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

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("public MACD fields", macd(TA.MACD.batch([10.0, 11.0, 9.0, 12.0, 8.0, 13.0], 2, 4, 3)))
    Unit <- Assert.check("public Bollinger Bands fields", bands(TA.BBANDS.batch([0.0, 2.0], 2, 2.0, 1.0, 0)))
    Assert.check("public ATR parameter error", atr_error(TA.ATR.batch([TA.Bar.hlc(10.0, 5.0, 8.0)], 0)))
