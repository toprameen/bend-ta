import Base
import ../../src/f32.bend as TA

def value(v: Maybe<&2, F32>) -> String:
  Maybe.show(~&2, ~F32, ~(x => F32.show(x)), v)

def show(r: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> String:
  match r:
    case Fail{e}:
      "invalid"
    case Done{xs}:
      List.show(~&2, ~Maybe<&2, F32>, ~value, xs)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(TA.SMA.batch([], 3)))
    IO.print(show(TA.EMA.batch([], 3)))
    IO.print(show(TA.SMA.batch([5.0, 10.0], 3)))
    IO.print(show(TA.EMA.batch([5.0, 10.0], 3)))
    IO.print(show(TA.SMA.batch([3.0, 6.0, 9.0], 1)))
    IO.print(show(TA.EMA.batch([3.0, 6.0, 9.0], 1)))
    IO.print(show(TA.SMA.batch([1000000.0, 0.01, 10.0], 1)))
    IO.print(show(TA.EMA.batch([1000000.0, 0.01, 10.0], 1)))
    IO.print(show(TA.SMA.batch([3.0], 0)))
    IO.print(show(TA.EMA.batch([], 0)))
    IO.print(show(TA.SMA.batch([], 1073741825)))
    IO.print(show(TA.EMA.batch([], 4294967295)))

#|[]
#|[]
#|[None, None]
#|[None, None]
#|[Some(3), Some(6), Some(9)]
#|[Some(3), Some(6), Some(9)]
#|[Some(1000000), Some(0.01), Some(10)]
#|[Some(1000000), Some(0.01), Some(10)]
#|invalid
#|invalid
#|invalid
#|invalid
