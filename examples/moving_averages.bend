import Base
import ../src/f32.bend as TA

def show_value(value: Maybe<&2, F32>) -> String:
  Maybe.show(~&2, ~F32, ~(x => F32.show(x)), value)

def show_result(result: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> String:
  match result:
    case Fail{e}:
      "invalid period"
    case Done{values}:
      List.show(~&2, ~Maybe<&2, F32>, ~show_value, values)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("SMA: " ++ show_result(TA.SMA.batch([3.0, 6.0, 9.0, 12.0], 3)))
    IO.print("EMA: " ++ show_result(TA.EMA.batch([3.0, 6.0, 9.0, 15.0], 3)))

#|SMA: [None, None, Some(6), Some(9)]
#|EMA: [None, None, Some(6), Some(10.5)]
