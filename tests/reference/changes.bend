import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/series.bend as Series

def small.values(xs: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs:
    case None{} <> Some{x} <> Nil{}:
      F32.is_lt(F32.abs(F32.sub(x, 0.00000625)), 0.0000000001)
    case other: False{}

def small(value: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> Bool:
  match value:
    case Fail{e}: False{}
    case Done{xs}: small.values(xs)

def continued(value: TA.CUMSUM.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match value:
    case (state, first):
      Bool.and(Assert.series(~F32, ~F32.is_eq, first, [Some{1.0}, Some{3.0}]),
        Assert.series(~F32, ~F32.is_eq, Series.batch(~F32, ~F32, ~TA.CUMSUM.State(), ~TA.CUMSUM.next, [F32.neg(4.0), 3.0], state), [Some{F32.neg(1.0)}, Some{2.0}]))

def main() -> IO(Unit):
  +geometric : List<&2, F32> = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0]
  +zeros : List<&2, F32> = [0.0, 2.0, 0.0, 4.0]
  do IO<Unit>:
    Unit <- Assert.check("MOM.batch case 1", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.MOM.batch(geometric, 3), [None{}, None{}, None{}, Some{7.0}, Some{14.0}, Some{28.0}]))
    Unit <- Assert.check("ROC.batch case 1", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROC.batch(geometric, 3), [None{}, None{}, None{}, Some{700.0}, Some{700.0}, Some{700.0}]))
    Unit <- Assert.check("ROCP.batch case 1", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROCP.batch(geometric, 3), [None{}, None{}, None{}, Some{7.0}, Some{7.0}, Some{7.0}]))
    Unit <- Assert.check("ROCR.batch case 1", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROCR.batch(geometric, 3), [None{}, None{}, None{}, Some{8.0}, Some{8.0}, Some{8.0}]))
    Unit <- Assert.check("ROCR100.batch case 1", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROCR100.batch(geometric, 3), [None{}, None{}, None{}, Some{800.0}, Some{800.0}, Some{800.0}]))
    Unit <- Assert.check("MOM.batch case 2", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.MOM.batch(zeros, 1), [None{}, Some{2.0}, Some{F32.neg(2.0)}, Some{4.0}]))
    Unit <- Assert.check("ROC.batch case 2", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROC.batch(zeros, 1), [None{}, Some{0.0}, Some{F32.neg(100.0)}, Some{0.0}]))
    Unit <- Assert.check("ROCP.batch case 2", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROCP.batch(zeros, 1), [None{}, Some{0.0}, Some{F32.neg(1.0)}, Some{0.0}]))
    Unit <- Assert.check("ROCR.batch case 2", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROCR.batch(zeros, 1), [None{}, Some{0.0}, Some{0.0}, Some{0.0}]))
    Unit <- Assert.check("ROCR100.batch case 2", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.ROCR100.batch(zeros, 1), [None{}, Some{0.0}, Some{0.0}, Some{0.0}]))
    Unit <- Assert.check("MOM.batch case 3", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.MOM.batch([], 3), []))
    Unit <- Assert.check("MOM.batch case 4", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.MOM.batch([1.0, 2.0], 3), [None{}, None{}]))
    Unit <- Assert.check("ROC.batch case 3", Result.is_fail(&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>, TA.ROC.batch([], 0)))
    Unit <- Assert.check("ROC.batch case 4", small(TA.ROC.batch([1000000.0, 1000000.0625], 1)))
    Unit <- Assert.check("CUMSUM.batch case 1", Assert.series(~F32, ~F32.is_eq, TA.CUMSUM.batch([1.0, 2.0, F32.neg(4.0), 3.0]), [Some{1.0}, Some{3.0}, Some{F32.neg(1.0)}, Some{2.0}]))
    Unit <- Assert.check("CUMSUM.next", continued(Series.scan(~F32, ~F32, ~TA.CUMSUM.State(), ~TA.CUMSUM.next, [1.0, 2.0], TA.CUMSUM.init())))
    Unit <- Assert.check("CUMSUM.batch case 2", Assert.series(~F32, ~F32.is_eq, TA.CUMSUM.batch([F32.neg(4.0), 3.0]), [Some{F32.neg(4.0)}, Some{F32.neg(1.0)}]))
    Assert.check("CUMSUM.batch case 3", Assert.series(~F32, ~F32.is_eq, TA.CUMSUM.batch([]), []))
