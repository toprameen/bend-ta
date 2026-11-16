import Base
import ../../src/f32.bend as TA

def atr_matches(result: Result<&2, &2, TA.VolumeError(), List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Done{[None{}, Some{value}]}: F32.is_eq(value, 7.0)
    case _: False{}

def single_matches(values: List<&2, Maybe<&2, F32>>, expected: F32) -> Bool:
  match values:
    case [Some{value}]: F32.is_eq(value, expected)
    case _: False{}

def check(passed: Bool) -> IO(Unit):
  match passed:
    case True{}: IO.pure(Unit, Unit{})
    case False{}: IO.die(Unit, 1, "public bar inputs")

def main() -> IO(Unit):
  hl : TA.Bar.HL() = TA.Bar.hl(8.0, 2.0)
  hlc : List<&2, TA.Bar.HLC()> = [TA.Bar.hlc(10.0, 5.0, 8.0), TA.Bar.hlc(15.0, 11.0, 12.0)]
  hlv : TA.Bar.HLV() = TA.Bar.hlv(8.0, 2.0, 3.0)
  cv : TA.Bar.CV() = TA.Bar.cv(10.0, 2.0)
  hlcv : TA.Bar.HLCV() = TA.Bar.hlcv(12.0, 8.0, 11.0, 2.0)
  ohlc : TA.Bar.OHLC() = TA.Bar.ohlc(2.0, 8.0, 0.0, 6.0)
  check(List.all(~&2, ~Bool, ~(passed => passed), [
    F32.is_eq(TA.MEDPRICE(hl), 5.0),
    atr_matches(TA.ATR.batch(hlc, 1)),
    F32.is_eq(TA.MARKETFI(hlv), 2.0),
    single_matches(TA.OBV.batch([cv]), 2.0),
    single_matches(TA.AD.batch([hlcv]), 1.0),
    F32.is_eq(TA.BOP(ohlc), 0.5)
  ]))
