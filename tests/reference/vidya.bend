import Base
import ../../src/f32.bend as TA
import ../../src/core/parameters.bend as Params

def show(value: Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>) -> String:
  match value:
    case Fail{e}: "invalid"
    case Done{xs}: List.show(~&2, ~Maybe<&2, F32>, ~(x => Maybe.show(~&2, ~F32, ~F32.show, x)), xs)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(TA.VIDYA.batch([1.0, 2.0, 4.0, 4.0, 4.0, 6.0], 3, 2)))
    IO.print(show(TA.VIDYA.batch([4.0, 3.0, 1.0], 3, 2)))
    IO.print(show(TA.VIDYA.batch([1.0, 2.0, 4.0], 1, 100000)))
    IO.print(show(TA.VIDYA.batch([5.0, 5.0, 5.0, 5.0], 3, 2)))
    IO.print(show(TA.VIDYA.batch([], 3, 2)))
    IO.print(show(TA.VIDYA.batch([], 1, 1)))

#|[None, None, Some(2.75), Some(3.375), Some(3.375), Some(4.6875)]
#|[None, None, Some(2.25)]
#|[Some(1), Some(2), Some(4)]
#|[None, None, Some(5), Some(5)]
#|[]
#|invalid
