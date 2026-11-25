import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/parameters.bend as Params
import ../../src/core/series.bend as Series

def near(actual: F32, +expected: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(actual, expected)), F32.mul(0.00002, F32.max(1.0, F32.abs(expected))))

def same(xs: List<&2, Maybe<&2, F32>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs expected:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: same(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(near(x, y), same(xs, ys))
    case other remaining: False{}

def result(value: Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match value:
    case Fail{e}: False{}
    case Done{xs}: same(xs, expected)

def invalid(~S: Type, value: Result<&2, &1, Params.Error, S>) -> Bool:
  match value:
    case Fail{e}: True{}
    case Done{state}: False{}

def continued(value: TA.OBV.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match value:
    case (state, first):
      Bool.and(same(first, [Some{2.0}, Some{6.0}]),
        same(Series.batch(~Bar.CV<F32>, ~F32, ~TA.OBV.State(), ~TA.OBV.next,
          [Bar.CV{12.0, 3.0}, Bar.CV{6.0, 6.0}, Bar.CV{9.0, 3.0}], state), [Some{6.0}, Some{0.0}, Some{3.0}]))

def main() -> IO(Unit):
  +cv : List<&2, Bar.CV<F32>> = [Bar.CV{10.0, 2.0}, Bar.CV{12.0, 4.0}, Bar.CV{12.0, 3.0}, Bar.CV{6.0, 6.0}, Bar.CV{9.0, 3.0}]
  +hl : List<&2, Bar.HL<F32>> = [Bar.HL{12.0, 8.0}, Bar.HL{15.0, 9.0}, Bar.HL{14.0, 10.0}, Bar.HL{8.0, 4.0}, Bar.HL{11.0, 7.0}]
  +hlc : List<&2, Bar.HLC<F32>> = [Bar.HLC{12.0, 8.0, 11.0}, Bar.HLC{15.0, 9.0, 10.0}, Bar.HLC{14.0, 10.0, 13.0}, Bar.HLC{8.0, 4.0, 7.0}, Bar.HLC{11.0, 7.0, 9.0}]
  +hlv : List<&2, Bar.HLV<F32>> = [Bar.HLV{12.0, 8.0, 2.0}, Bar.HLV{15.0, 9.0, 4.0}, Bar.HLV{14.0, 10.0, 3.0}, Bar.HLV{8.0, 4.0, 6.0}, Bar.HLV{11.0, 7.0, 3.0}]
  +hlcv : List<&2, Bar.HLCV<F32>> = [Bar.HLCV{12.0, 8.0, 11.0, 2.0}, Bar.HLCV{15.0, 9.0, 10.0, 4.0}, Bar.HLCV{14.0, 10.0, 13.0, 3.0}, Bar.HLCV{8.0, 4.0, 7.0, 6.0}, Bar.HLCV{11.0, 7.0, 9.0, 3.0}]
  do IO<Unit>:
    Unit <- Assert.check("OBV.batch", same(TA.OBV.batch(cv), [Some{2.0}, Some{6.0}, Some{6.0}, Some{0.0}, Some{3.0}]))
    Unit <- Assert.check("NVI.batch case 1", same(TA.NVI.batch(cv), [Some{1000.0}, Some{1000.0}, Some{1000.0}, Some{1000.0}, Some{1500.0}]))
    Unit <- Assert.check("PVI.batch", same(TA.PVI.batch(cv), [Some{1000.0}, Some{1200.0}, Some{1200.0}, Some{600.0}, Some{600.0}]))
    Unit <- Assert.check("PVT.batch", same(TA.PVT.batch(cv), [Some{0.0}, Some{0.8}, Some{0.8}, Some{F32.neg(2.2)}, Some{F32.neg(0.7)}]))
    Unit <- Assert.check("AD.batch", same(TA.AD.batch(hlcv), [Some{1.0}, Some{F32.neg(1.6666667)}, Some{F32.neg(0.16666667)}, Some{2.8333333}, Some{2.8333333}]))
    Unit <- Assert.check("CMF.batch", result(TA.CMF.batch(hlcv, 2), [None{}, Some{F32.neg(0.27777778)}, Some{F32.neg(0.16666667)}, Some{0.5}, Some{0.33333333}]))
    Unit <- Assert.check("EFI.batch", result(TA.EFI.batch(cv, 2), [None{}, None{}, Some{4.0}, Some{F32.neg(22.6666667)}, Some{F32.neg(1.5555556)}]))
    Unit <- Assert.check("EMV.batch", result(TA.EMV.batch(hlv, 2, 1.0), [None{}, None{}, Some{1.5}, Some{F32.neg(2.0)}, Some{0.0}]))
    Unit <- Assert.check("ADR.batch", result(TA.ADR.batch(hl, 2), [None{}, Some{5.0}, Some{5.0}, Some{4.0}, Some{4.0}]))
    Unit <- Assert.check("TRANGE.batch", same(TA.TRANGE.batch(hlc), [None{}, Some{6.0}, Some{4.0}, Some{9.0}, Some{4.0}]))
    Unit <- Assert.check("ATR.batch case 1", result(TA.ATR.batch(hlc, 2), [None{}, None{}, Some{5.0}, Some{7.0}, Some{5.5}]))
    Unit <- Assert.check("NATR.batch case 1", result(TA.NATR.batch(hlc, 2), [None{}, None{}, Some{38.461538}, Some{100.0}, Some{61.111111}]))
    Unit <- Assert.check("NATR.batch case 2", result(TA.NATR.batch(hlc, 1), [None{}, Some{6.0}, Some{4.0}, Some{9.0}, Some{4.0}]))
    Unit <- Assert.check("CVI.batch", result(TA.CVI.batch(hl, 2, 2), [None{}, None{}, None{}, Some{F32.neg(17.7777778)}, Some{F32.neg(6.8376068)}]))
    Unit <- Assert.check("MASSI.batch", result(TA.MASSI.batch(hl, 2, 2), [None{}, None{}, None{}, Some{1.88546798}, Some{1.93593847}]))
    Unit <- Assert.check("OBV.next", continued(Series.scan(~Bar.CV<F32>, ~F32, ~TA.OBV.State(), ~TA.OBV.next, [Bar.CV{10.0, 2.0}, Bar.CV{12.0, 4.0}], TA.OBV.init())))
    Unit <- Assert.check("NVI.batch case 2", same(TA.NVI.batch([Bar.CV{1.0e-30, 3.0}, Bar.CV{1.0e30, 2.0}, Bar.CV{2.0e30, 1.0}]), [Some{1000.0}, Some{1000.0}, Some{2000.0}]))
    Unit <- Assert.check("CMF.init", Bool.and(invalid(~TA.CMF.State(), TA.CMF.init(1)), Bool.and(invalid(~TA.EMV.State(), TA.EMV.init(2, 0.0)), invalid(~TA.EMV.State(), TA.EMV.init(2, 1.0e38)))))
    Unit <- Assert.check("ATR.batch case 2", Bool.and(result(TA.ATR.batch([], 2), []), result(TA.CVI.batch([Bar.HL{2.0, 1.0}], 2, 1), [None{}])))
    Assert.check("PVO.batch", result(TA.PVO.batch([2.0, 4.0, 8.0, 16.0], 2, 3, 0), [None{}, None{}, Some{28.5714286}, Some{28.5714286}]))
