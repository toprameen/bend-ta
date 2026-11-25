import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/parameters.bend as P
import ../../src/core/statistics.bend as S
import ../../src/core/series.bend as Series

def close.values(xs: List<&2, Maybe<&2, F32>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs expected:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: close.values(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(F32.is_lt(F32.abs(F32.sub(x, y)), 0.00001), close.values(xs, ys))
    case _ _: False{}

def close(value: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match value:
    case Fail{e}: False{}
    case Done{xs}: close.values(xs, expected)

def indexes(actual: TA.MINMAXINDEX.Value(), expected: S.MinMaxIndex) -> Bool:
  match expected:
    case S.MinMaxIndex{low, high}:
      +actual = actual
      Bool.and(U32.is_eq(TA.MINMAXINDEX.min_index(actual), low), U32.is_eq(TA.MINMAXINDEX.max_index(actual), high))

def bounds(actual: TA.MINMAX.Value(), expected: S.MinMax<F32>) -> Bool:
  match expected:
    case S.MinMax{low, high}:
      +actual = actual
      Bool.and(F32.is_eq(TA.MINMAX.min(actual), low), F32.is_eq(TA.MINMAX.max(actual), high))

def continued.scan(result: TA.LINEARREG.State() & List<&2, Maybe<&2, F32>>) -> Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>:
  match result:
    case (state, first): Done{Series.batch(~F32, ~F32, ~TA.LINEARREG.State(), ~TA.LINEARREG.next, [6.0, 8.0], state)}

def continued(result: Result<&2, &1, P.Error, TA.LINEARREG.State()>) -> Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: continued.scan(Series.scan(~F32, ~F32, ~TA.LINEARREG.State(), ~TA.LINEARREG.next, [2.0, 4.0], state))

def copies(~A: Data, fuel: Nat, +value: A, acc: List<&2, A>) -> List<&2, A>:
  match fuel:
    case 0n: acc
    case 1n+rest: copies(~A, rest, value, value <> acc)

def boundary() -> Bool:
  +xs = copies(~F32, 10000n, 1.0, [])
  +expected = copies(~Maybe<&2, F32>, 9999n, None{}, [Some{1.0}])
  Bool.and(close(TA.MEDIAN.batch(xs, 10000), expected), close(TA.PERCENTILE.batch(xs, 10000, 100.0), expected))

def main() -> IO(Unit):
  +ramp : List<&2, F32> = [2.0, 4.0, 6.0, 8.0]
  +ties : List<&2, F32> = [2.0, 2.0, 1.0, 2.0, 1.0]
  do IO<Unit>:
    Unit <- Assert.check("LINEARREG.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.LINEARREG.batch(ramp, 3), [None{}, None{}, Some{6.0}, Some{8.0}]))
    Unit <- Assert.check("LINEARREG_SLOPE.batch case 1", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.LINEARREG_SLOPE.batch(ramp, 3), [None{}, None{}, Some{2.0}, Some{2.0}]))
    Unit <- Assert.check("LINEARREG_INTERCEPT.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.LINEARREG_INTERCEPT.batch(ramp, 3), [None{}, None{}, Some{2.0}, Some{4.0}]))
    Unit <- Assert.check("TSF.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.TSF.batch(ramp, 3), [None{}, None{}, Some{8.0}, Some{10.0}]))
    Unit <- Assert.check("LINEARREG_ANGLE.batch", close(TA.LINEARREG_ANGLE.batch([0.0, 1.0, 2.0], 2), [None{}, Some{45.0}, Some{45.0}]))
    Unit <- Assert.check("LINEARREG_SLOPE.batch case 2", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.LINEARREG_SLOPE.batch([1000000.0, 1000000.0625, 1000000.125], 3), [None{}, None{}, Some{0.0625}]))
    Unit <- Assert.check("AVGDEV.batch", close(TA.AVGDEV.batch([1000000.0, 1000000.0, 1000000.0625], 3), [None{}, None{}, Some{0.027777778}]))
    Unit <- Assert.check("STDDEV.batch case 1", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.STDDEV.batch([0.0, 2.0, 4.0], 2, 1.0), [None{}, Some{1.0}, Some{1.0}]))
    Unit <- Assert.check("MEDIAN.batch case 1", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.MEDIAN.batch([10.0, 0.0, 20.0, 40.0], 4), [None{}, None{}, None{}, Some{15.0}]))
    Unit <- Assert.check("PERCENTILE.batch case 1", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.PERCENTILE.batch([10.0, 0.0, 20.0, 40.0], 4, 25.0), [None{}, None{}, None{}, Some{0.0}]))
    Unit <- Assert.check("PERCENTRANK.batch", close(TA.PERCENTRANK.batch([2.0, 2.0, 1.0, 2.0, 1.0, 1.0, 3.0], 3), [None{}, None{}, None{}, Some{33.333333}, Some{0.0}, Some{0.0}, Some{100.0}]))
    Unit <- Assert.check("MAXINDEX.batch", Assert.batch(~P.Error, ~U32, ~U32.is_eq, TA.MAXINDEX.batch(ties, 3), [None{}, None{}, Some{1}, Some{3}, Some{3}]))
    Unit <- Assert.check("MININDEX.batch", Assert.batch(~P.Error, ~U32, ~U32.is_eq, TA.MININDEX.batch(ties, 3), [None{}, None{}, Some{2}, Some{2}, Some{4}]))
    Unit <- Assert.check("MINMAXINDEX.batch", Assert.batch(~P.Error, ~S.MinMaxIndex, ~indexes, TA.MINMAXINDEX.batch(ties, 3), [None{}, None{}, Some{S.MinMaxIndex{2, 1}}, Some{S.MinMaxIndex{2, 3}}, Some{S.MinMaxIndex{4, 3}}]))
    Unit <- Assert.check("MAX.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.MAX.batch(ties, 3), [None{}, None{}, Some{2.0}, Some{2.0}, Some{2.0}]))
    Unit <- Assert.check("MIN.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.MIN.batch(ties, 3), [None{}, None{}, Some{1.0}, Some{1.0}, Some{1.0}]))
    Unit <- Assert.check("MIDPOINT.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.MIDPOINT.batch(ties, 3), [None{}, None{}, Some{1.5}, Some{1.5}, Some{1.5}]))
    Unit <- Assert.check("MEDIAN.batch case 2", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.MEDIAN.batch([], 3), []))
    Unit <- Assert.check("STDDEV.batch case 2", Result.is_fail(&2, &2, P.Error, List<&2, Maybe<&2, F32>>, TA.STDDEV.batch([], 1, 1.0)))
    Unit <- Assert.check("PERCENTILE.batch case 2", Result.is_fail(&2, &2, P.Error, List<&2, Maybe<&2, F32>>, TA.PERCENTILE.batch([], 2, 101.0)))
    Unit <- Assert.check("LINEARREG.init", Assert.batch(~P.Error, ~F32, ~F32.is_eq, continued(TA.LINEARREG.init(3)), [Some{6.0}, Some{8.0}]))
    Unit <- Assert.check("MINMAX.batch", Assert.batch(~P.Error, ~S.MinMax<F32>, ~bounds, TA.MINMAX.batch(ties, 3), [None{}, None{}, Some{S.MinMax{1.0, 2.0}}, Some{S.MinMax{1.0, 2.0}}, Some{S.MinMax{1.0, 2.0}}]))
    Assert.check("boundary", boundary())
