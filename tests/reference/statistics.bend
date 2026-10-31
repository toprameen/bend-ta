import Base
import ../../src/f32.bend as TA
import ../../src/core/parameters.bend as P
import ../../src/core/statistics.bend as S
import ../../src/core/series.bend as Series

def show(~A: Data, ~format: A -> String, value: Result<&2, &2, P.Error, List<&2, Maybe<&2, A>>>) -> String:
  match value:
    case Fail{e}: "invalid"
    case Done{xs}: List.show(~&2, ~Maybe<&2, A>, ~(x => Maybe.show(~&2, ~A, ~format, x)), xs)

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

def indexes(v: S.MinMaxIndex) -> String:
  match v:
    case S.MinMaxIndex{low, high}: U32.show(low) ++ "," ++ U32.show(high)

def bounds(v: S.MinMax<F32>) -> String:
  match v:
    case S.MinMax{low, high}: F32.show(low) ++ "," ++ F32.show(high)

def continued.scan(result: TA.LINEARREG.State() & List<&2, Maybe<&2, F32>>) -> String:
  match result:
    case (state, first): List.show(~&2, ~Maybe<&2, F32>, ~(x => Maybe.show(~&2, ~F32, ~F32.show, x)), Series.batch(~F32, ~F32, ~TA.LINEARREG.State(), ~TA.LINEARREG.next, [6.0, 8.0], state))

def continued(result: Result<&2, &1, P.Error, TA.LINEARREG.State()>) -> String:
  match result:
    case Fail{e}: "invalid"
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
    IO.print(show(~F32, ~F32.show, TA.LINEARREG.batch(ramp, 3)))
    IO.print(show(~F32, ~F32.show, TA.LINEARREG_SLOPE.batch(ramp, 3)))
    IO.print(show(~F32, ~F32.show, TA.LINEARREG_INTERCEPT.batch(ramp, 3)))
    IO.print(show(~F32, ~F32.show, TA.TSF.batch(ramp, 3)))
    IO.print(Bool.show(close(TA.LINEARREG_ANGLE.batch([0.0, 1.0, 2.0], 2), [None{}, Some{45.0}, Some{45.0}])))
    IO.print(show(~F32, ~F32.show, TA.LINEARREG_SLOPE.batch([1000000.0, 1000000.0625, 1000000.125], 3)))
    IO.print(Bool.show(close(TA.AVGDEV.batch([1000000.0, 1000000.0, 1000000.0625], 3), [None{}, None{}, Some{0.027777778}])))
    IO.print(show(~F32, ~F32.show, TA.STDDEV.batch([0.0, 2.0, 4.0], 2, 1.0)))
    IO.print(show(~F32, ~F32.show, TA.MEDIAN.batch([10.0, 0.0, 20.0, 40.0], 4)))
    IO.print(show(~F32, ~F32.show, TA.PERCENTILE.batch([10.0, 0.0, 20.0, 40.0], 4, 25.0)))
    IO.print(Bool.show(close(TA.PERCENTRANK.batch([2.0, 2.0, 1.0, 2.0, 1.0, 1.0, 3.0], 3), [None{}, None{}, None{}, Some{33.333333}, Some{0.0}, Some{0.0}, Some{100.0}])))
    IO.print(show(~U32, ~U32.show, TA.MAXINDEX.batch(ties, 3)))
    IO.print(show(~U32, ~U32.show, TA.MININDEX.batch(ties, 3)))
    IO.print(show(~S.MinMaxIndex, ~indexes, TA.MINMAXINDEX.batch(ties, 3)))
    IO.print(show(~F32, ~F32.show, TA.MAX.batch(ties, 3)))
    IO.print(show(~F32, ~F32.show, TA.MIN.batch(ties, 3)))
    IO.print(show(~F32, ~F32.show, TA.MIDPOINT.batch(ties, 3)))
    IO.print(show(~F32, ~F32.show, TA.MEDIAN.batch([], 3)))
    IO.print(show(~F32, ~F32.show, TA.STDDEV.batch([], 1, 1.0)))
    IO.print(show(~F32, ~F32.show, TA.PERCENTILE.batch([], 2, 101.0)))
    IO.print(continued(TA.LINEARREG.init(3)))
    IO.print(show(~S.MinMax<F32>, ~bounds, TA.MINMAX.batch(ties, 3)))
    IO.print(Bool.show(boundary()))

#|[None, None, Some(6), Some(8)]
#|[None, None, Some(2), Some(2)]
#|[None, None, Some(2), Some(4)]
#|[None, None, Some(8), Some(10)]
#|True
#|[None, None, Some(0.0625)]
#|True
#|[None, Some(1), Some(1)]
#|[None, None, None, Some(15)]
#|[None, None, None, Some(0)]
#|True
#|[None, None, Some(1), Some(3), Some(3)]
#|[None, None, Some(2), Some(2), Some(4)]
#|[None, None, Some(2,1), Some(2,3), Some(4,3)]
#|[None, None, Some(2), Some(2), Some(2)]
#|[None, None, Some(1), Some(1), Some(1)]
#|[None, None, Some(1.5), Some(1.5), Some(1.5)]
#|[]
#|invalid
#|invalid
#|[Some(6), Some(8)]

#|[None, None, Some(1,2), Some(1,2), Some(1,2)]

#|True
