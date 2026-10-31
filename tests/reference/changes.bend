import Base
import ../../src/f32.bend as TA
import ../../src/core/series.bend as Series

def show(xs: List<&2, Maybe<&2, F32>>) -> String:
  List.show(~&2, ~Maybe<&2, F32>, ~(v => Maybe.show(~&2, ~F32, ~F32.show, v)), xs)

def result(value: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> String:
  match value:
    case Fail{e}: "invalid"
    case Done{xs}: show(xs)

def small.values(xs: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs:
    case None{} <> Some{x} <> Nil{}:
      F32.is_lt(F32.abs(F32.sub(x, 0.00000625)), 0.0000000001)
    case other: False{}

def small(value: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> Bool:
  match value:
    case Fail{e}: False{}
    case Done{xs}: small.values(xs)

def continued(value: TA.CUMSUM.State() & List<&2, Maybe<&2, F32>>) -> String:
  match value:
    case (state, first):
      show(first) ++ " | " ++ show(Series.batch(~F32, ~F32, ~TA.CUMSUM.State(), ~TA.CUMSUM.next, [F32.neg(4.0), 3.0], state))

def main() -> IO(Unit):
  +geometric : List<&2, F32> = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0]
  +zeros : List<&2, F32> = [0.0, 2.0, 0.0, 4.0]
  do IO<Unit>:
    IO.print(result(TA.MOM.batch(geometric, 3)))
    IO.print(result(TA.ROC.batch(geometric, 3)))
    IO.print(result(TA.ROCP.batch(geometric, 3)))
    IO.print(result(TA.ROCR.batch(geometric, 3)))
    IO.print(result(TA.ROCR100.batch(geometric, 3)))
    IO.print(result(TA.MOM.batch(zeros, 1)))
    IO.print(result(TA.ROC.batch(zeros, 1)))
    IO.print(result(TA.ROCP.batch(zeros, 1)))
    IO.print(result(TA.ROCR.batch(zeros, 1)))
    IO.print(result(TA.ROCR100.batch(zeros, 1)))
    IO.print(result(TA.MOM.batch([], 3)))
    IO.print(result(TA.MOM.batch([1.0, 2.0], 3)))
    IO.print(result(TA.ROC.batch([], 0)))
    IO.print(Bool.show(small(TA.ROC.batch([1000000.0, 1000000.0625], 1))))
    IO.print(show(TA.CUMSUM.batch([1.0, 2.0, F32.neg(4.0), 3.0])))
    IO.print(continued(Series.scan(~F32, ~F32, ~TA.CUMSUM.State(), ~TA.CUMSUM.next, [1.0, 2.0], TA.CUMSUM.init())))
    IO.print(show(TA.CUMSUM.batch([F32.neg(4.0), 3.0])))
    IO.print(show(TA.CUMSUM.batch([])))

#|[None, None, None, Some(7), Some(14), Some(28)]
#|[None, None, None, Some(700), Some(700), Some(700)]
#|[None, None, None, Some(7), Some(7), Some(7)]
#|[None, None, None, Some(8), Some(8), Some(8)]
#|[None, None, None, Some(800), Some(800), Some(800)]
#|[None, Some(2), Some(-2), Some(4)]
#|[None, Some(0), Some(-100), Some(0)]
#|[None, Some(0), Some(-1), Some(0)]
#|[None, Some(0), Some(0), Some(0)]
#|[None, Some(0), Some(0), Some(0)]
#|[]
#|[None, None]
#|invalid
#|True
#|[Some(1), Some(3), Some(-1), Some(2)]
#|[Some(1), Some(3)] | [Some(-1), Some(2)]
#|[Some(-4), Some(-1)]
#|[]
