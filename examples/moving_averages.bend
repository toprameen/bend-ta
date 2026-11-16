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

def print_sma_value(update: TA.SMA.State() & Maybe<&2, F32>) -> IO(Unit):
  match update:
    case (_, value): IO.print(show_value(value))

def continue_sma(update: TA.SMA.State() & Maybe<&2, F32>) -> IO(Unit):
  match update:
    case (state, value):
      do IO<Unit>:
        IO.print(show_value(value))
        print_sma_value(TA.SMA.next(state, 6.0))

def stream_sma(initialized: Result<&2, &1, TA.Error(), TA.SMA.State()>) -> IO(Unit):
  match initialized:
    case Fail{error}: IO.die(Unit, 1, "invalid SMA period")
    case Done{state}: continue_sma(TA.SMA.next(state, 3.0))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("SMA: " ++ show_result(TA.SMA.batch([3.0, 6.0, 9.0, 12.0], 3)))
    IO.print("EMA: " ++ show_result(TA.EMA.batch([3.0, 6.0, 9.0, 15.0], 3)))
    IO.print("SMA updates:")
    stream_sma(TA.SMA.init(2))
