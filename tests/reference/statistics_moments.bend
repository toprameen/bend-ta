import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/statistics_window.bend as S
import ../../src/core/parameters.bend as P
import ../../src/core/series.bend as Series

def near(+x: F32, +y: F32) -> Bool:
  Bool.or(Bool.and(Bool.not(F32.is_eq(x, x)), Bool.not(F32.is_eq(y, y))), F32.is_le(F32.abs(F32.sub(x, y)), F32.mul(0.00002, F32.max(1.0, F32.abs(y)))))

def same(xs: List<&2, Maybe<&2, F32>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: same(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(near(x, y), same(xs, ys))
    case _ _: False{}

def result(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{xs}: same(xs, ys)

def invalid(~S: Type, r: Result<&2, &1, P.Error, S>) -> Bool:
  match r:
    case Fail{e}: True{}
    case Done{state}: False{}

def continued.scan(r: TA.BETA.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match r:
    case (state, first): Bool.and(same(first, [None{}, None{}]), same(Series.batch(~TA.PairValue(), ~F32, ~TA.BETA.State(), ~TA.BETA.next, [S.PairValue{8.0, 21.0}, S.PairValue{16.0, 63.0}], state), [Some{2.0}, Some{2.0}]))

def continued(r: Result<&2, &1, P.Error, TA.BETA.State()>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{state}: continued.scan(Series.scan(~TA.PairValue(), ~F32, ~TA.BETA.State(), ~TA.BETA.next, [S.PairValue{1.0, 1.0}, S.PairValue{2.0, 3.0}], state))

def main() -> IO(Unit):
  +prices : List<&2, F32> = [1000000.0, 1000000.0, 1000000.0625]
  +pairs : List<&2, TA.PairValue()> = [S.PairValue{1000000.0, 5.0}, S.PairValue{1000000.0625, 3.0}, S.PairValue{1000000.125, 1.0}]
  do IO<Unit>:
    Unit <- Assert.check("VAR.batch case 1", result(TA.VAR.batch(prices, 3, 9.0), [None{}, None{}, Some{0.00086805556}]))
    Unit <- Assert.check("VAR.batch case 2", result(TA.VAR.batch([2.0, 4.0, 6.0], 2, F32.neg(3.0)), [None{}, Some{1.0}, Some{1.0}]))
    Unit <- Assert.check("VAR.batch case 3", result(TA.VAR.batch(prices, 1, 0.0), [Some{0.0}, Some{0.0}, Some{0.0}]))
    Unit <- Assert.check("CORREL.batch case 1", result(TA.CORREL.batch(pairs, 3), [None{}, None{}, Some{F32.neg(1.0)}]))
    Unit <- Assert.check("CORREL.batch case 2", result(TA.CORREL.batch([S.PairValue{1000000.0, 0.0}, S.PairValue{1000000.0, 0.0}, S.PairValue{1000000.0625, 1.0}], 3), [None{}, None{}, Some{1.0}]))
    Unit <- Assert.check("CORREL.batch case 3", result(TA.CORREL.batch([S.PairValue{2.0, 1.0}, S.PairValue{2.0, 3.0}], 2), [None{}, Some{0.0}]))
    Unit <- Assert.check("BETA.batch", result(TA.BETA.batch([S.PairValue{0.0, 0.0}, S.PairValue{1.0, 2.0}, S.PairValue{2.0, 4.0}, S.PairValue{4.0, 12.0}], 2), [None{}, None{}, Some{1.0}, Some{0.0}]))
    Unit <- Assert.check("BETA.init", continued(TA.BETA.init(2)))
    Unit <- Assert.check("KURTOSIS.batch case 1", result(TA.KURTOSIS.batch([1.0, 2.0, 3.0, 4.0, 4.0], 4), [None{}, None{}, None{}, Some{F32.neg(1.2)}, Some{F32.neg(1.2892562)}]))
    Unit <- Assert.check("KURTOSIS.batch case 2", result(TA.KURTOSIS.batch([1000000.0, 1000000.0, 1000000.0, 1000000.0625], 4), [None{}, None{}, None{}, Some{4.0}]))
    Unit <- Assert.check("KURTOSIS.batch case 3", result(TA.KURTOSIS.batch([2.0, 2.0, 2.0, 2.0], 4), [None{}, None{}, None{}, Some{F32.div(0.0, 0.0)}]))
    Unit <- Assert.check("KURTOSIS.init", Bool.and(invalid(~TA.KURTOSIS.State(), TA.KURTOSIS.init(3)), Bool.and(invalid(~TA.KURTOSIS.State(), TA.KURTOSIS.init(10001)), invalid(~TA.BETA.State(), TA.BETA.init(100001)))))
    Assert.check("CORREL.batch case 4", Bool.and(result(TA.CORREL.batch([], 1), []), result(TA.BETA.batch(pairs, 1), [None{}, Some{0.0}, Some{0.0}])))
