import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/transform.bend as Transform
import ../../src/core/series.bend as Series

def near(actual: F32, expected: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(actual, expected)), 0.000001)

def nan(+value: F32) -> Bool:
  F32.is_ne(value, value)

def same_bits(a: F32, b: F32) -> Bool:
  U32.is_eq(F32.bits(a), F32.bits(b))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("scalar transforms", List.all(~&2, ~Bool, ~(passed => passed), [
      near(TA.ACOS(0.5), 1.0471975511965976),
      near(TA.ASIN(0.5), 0.5235987755982988),
      near(TA.ATAN(0.5), 0.46364760900080615),
      near(TA.CEIL(0.5), 1.0),
      near(TA.COS(0.5), 0.8775825618903728),
      near(TA.COSH(0.5), 1.1276259652063807),
      near(TA.EXP(0.5), 1.6487212707001282),
      near(TA.FLOOR(0.5), 0.0),
      near(TA.LN(0.5), F32.neg(0.6931471805599453)),
      near(TA.LOG10(0.5), F32.neg(0.3010299956639812)),
      near(TA.SIN(0.5), 0.479425538604203),
      near(TA.SINH(0.5), 0.5210953054937474),
      near(TA.SQRT(0.5), 0.7071067811865476),
      near(TA.TAN(0.5), 0.5463024898437905),
      near(TA.TANH(0.5), 0.46211715726000974)
    ]))
    Unit <- Assert.check("domain and overflow", List.all(~&2, ~Bool, ~(passed => passed), [
      nan(TA.ACOS(2.0)),
      nan(TA.ASIN(2.0)),
      nan(TA.SQRT(F32.neg(1.0))),
      nan(TA.LN(F32.neg(1.0))),
      F32.is_eq(TA.LN(0.0), F32.neg(F32.div(1.0, 0.0))),
      F32.is_eq(TA.EXP(100.0), F32.div(1.0, 0.0)),
      F32.is_eq(TA.EXP(F32.neg(200.0)), 0.0)
    ]))
    Unit <- Assert.check("signed rounding", Assert.list(~F32, ~same_bits, [TA.CEIL(F32.neg(0.25)), TA.FLOOR(F32.neg(0.25))], [F32.neg(0.0), F32.neg(1.0)]))
    Unit <- Assert.check("signed zero", List.all(~&2, ~Bool, ~(passed => passed), [U32.is_eq(F32.bits(TA.SIN(F32.neg(0.0))), 2147483648), U32.is_eq(F32.bits(TA.SQRT(F32.neg(0.0))), 2147483648)]))
    Unit <- Assert.check("SQRT series", Assert.list(~F32, ~same_bits, Series.map(~F32, ~F32, ~TA.SQRT, [0.0, 1.0, 4.0, 9.0]), [0.0, 1.0, 2.0, 3.0]))
    Unit <- Assert.check("empty series", Assert.list(~F32, ~same_bits, Series.map(~F32, ~F32, ~TA.COS, []), []))
    Unit <- Assert.check("pair operations", Assert.list(~F32, ~same_bits, [TA.ADD(Transform.Operands{3.0, F32.neg(2.0)}), TA.SUB(Transform.Operands{3.0, F32.neg(2.0)}), TA.MULT(Transform.Operands{3.0, F32.neg(2.0)})], [1.0, 5.0, F32.neg(6.0)]))
    Unit <- Assert.check("ADD series", Assert.list(~F32, ~same_bits, Series.map(~Transform.Operands<F32>, ~F32, ~TA.ADD, [Transform.Operands{1.0, 2.0}, Transform.Operands{3.0, 4.0}]), [3.0, 7.0]))
    Unit <- Assert.check("price transforms", Assert.list(~F32, ~same_bits, [TA.AVGPRICE(Bar.OHLC{2.0, 8.0, 0.0, 6.0}), TA.MEDPRICE(Bar.HL{8.0, 0.0}), TA.TYPPRICE(Bar.HLC{8.0, 0.0, 6.0}), TA.WCLPRICE(Bar.HLC{8.0, 0.0, 6.0})], [4.0, 4.0, 4.6666665, 5.0]))
    Unit <- Assert.check("balance of power", Assert.list(~F32, ~same_bits, [TA.BOP(Bar.OHLC{2.0, 8.0, 0.0, 6.0}), TA.BOP(Bar.OHLC{6.0, 8.0, 0.0, 2.0}), TA.BOP(Bar.OHLC{1.0, 1.0, 1.0, 1.0}), TA.BOP(Bar.OHLC{1.0, 0.0, 2.0, 1.0})], [0.5, F32.neg(0.5), 0.0, 0.0]))
    Unit <- Assert.check("internal bar strength", Assert.list(~F32, ~same_bits, [TA.IBS(Bar.HLC{8.0, 0.0, 6.0}), TA.IBS(Bar.HLC{1.0, 1.0, 1.0}), TA.IBS(Bar.HLC{0.0, 2.0, 1.0}), TA.IBS(Bar.HLC{2.0, 0.0, 3.0})], [0.75, 0.5, 0.5, 1.5]))
    Unit <- Assert.check("market facilitation", Assert.list(~F32, ~same_bits, [TA.MARKETFI(Bar.HLV{8.0, 0.0, 4.0}), TA.MARKETFI(Bar.HLV{8.0, 0.0, 0.0}), TA.MARKETFI(Bar.HLV{2.0e-15, 1.0e-15, 1.0e-15})], [2.0, 0.0, 1.0]))
    Assert.check("guarded division", List.all(~&2, ~Bool, ~(passed => passed), [near(TA.BOP(Bar.OHLC{1.0e-15, 2.0e-15, 1.0e-15, 1.5e-15}), 0.5), near(TA.IBS(Bar.HLC{2.0e-15, 1.0e-15, 1.5e-15}), 0.5)]))
