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

def stream.resume(
  -S: Type, result: S & Maybe<&2, F32>, rest: S -> List<&2, Maybe<&2, F32>>
) -> List<&2, Maybe<&2, F32>>:
  match result:
    case (state, output): output <> rest(state)

def stream.collect(
  ~S: Type, ~next: S -> F32 -> S & Maybe<&2, F32>, prices: List<&2, F32>, state: S
) -> List<&2, Maybe<&2, F32>>:
  match prices:
    case Nil{}: Nil{}
    case price <> rest:
      stream.resume(S, next(state, price), next_state => stream.collect(~S, ~next, rest, next_state))

def sma_stream(initialized: Result<&2, &1, TA.Error(), TA.SMA.State()>) -> String:
  match initialized:
    case Fail{e}: "invalid"
    case Done{state}:
      show(Done{stream.collect(~TA.SMA.State(), ~TA.SMA.next, [3.0, 6.0, 9.0, 12.0], state)})

def ema_stream(initialized: Result<&2, &2, TA.Error(), TA.EMA.State()>) -> String:
  match initialized:
    case Fail{e}: "invalid"
    case Done{state}:
      show(Done{stream.collect(~TA.EMA.State(), ~TA.EMA.next, [3.0, 6.0, 9.0, 15.0], state)})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(TA.SMA.batch([3.0, 6.0, 9.0, 12.0, 15.0, 18.0], 3)))
    IO.print(show(TA.EMA.batch([3.0, 6.0, 9.0, 15.0, 12.0], 3)))
    IO.print(show(TA.SMA.batch([2.0, 4.0, 6.0, 8.0, 10.0], 4)))
    IO.print(show(TA.EMA.batch([7.0, 7.0, 7.0, 7.0], 2)))
    IO.print(show(TA.SMA.batch([F32.neg(3.0), 0.0, 3.0, 6.0], 3)))
    IO.print(sma_stream(TA.SMA.init(3)))
    IO.print(ema_stream(TA.EMA.init(3)))

#|[None, None, Some(6), Some(9), Some(12), Some(15)]
#|[None, None, Some(6), Some(10.5), Some(11.25)]
#|[None, None, None, Some(5), Some(7)]
#|[None, Some(7), Some(7), Some(7)]
#|[None, None, Some(0), Some(3)]
#|[None, None, Some(6), Some(9)]
#|[None, None, Some(6), Some(10.5)]
