import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA

def message(result: Result<&2, &2, String, Unit>, expected: String) -> Bool:
  match result:
    case Fail{actual}: String.eq(actual, expected)
    case Done{unit}: False{}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("Bollinger Bands period diagnostic",
      message(TA.BBANDS.validate(1, 2.0, 2.0, TA.MA.Kind.SMA()), "period is out of range"))
    Unit <- Assert.check("Bollinger Bands upper multiplier diagnostic",
      message(TA.BBANDS.validate(20, F32.div(0.0, 0.0), 2.0, TA.MA.Kind.SMA()), "upper multiplier must be finite and within range"))
    Unit <- Assert.check("Bollinger Bands lower multiplier diagnostic",
      message(TA.BBANDS.validate(20, 2.0, 4.0e37, TA.MA.Kind.SMA()), "lower multiplier must be finite and within range"))
    Unit <- Assert.check("Bollinger Bands averaging diagnostic",
      message(TA.BBANDS.validate(20, 2.0, 2.0, 11), "moving-average kind is unsupported"))
    Assert.check("Bollinger Bands valid settings",
      Result.is_done(&2, &2, String, Unit, TA.BBANDS.validate(20, F32.neg(2.0), 2.0, TA.MA.Kind.SMA())))
