import Base
import ../../src/f32.bend as TA

def value(v: Maybe<&2, F32>) -> String:
  Maybe.show(~&2, ~F32, ~(x => F32.show(x)), v)

def sma.fourth(r: TA.SMA.State() & Maybe<&2, F32>, third: Maybe<&2, F32>) -> String:
  match r:
    case (state, fourth):
      value(third) ++ ", " ++ value(fourth)

def sma.third(r: TA.SMA.State() & Maybe<&2, F32>) -> String:
  match r:
    case (state, third):
      sma.fourth(TA.SMA.next(state, 12.0), third)

def sma.second(r: TA.SMA.State() & Maybe<&2, F32>) -> String:
  match r:
    case (state, second):
      value(second) ++ ", " ++ sma.third(TA.SMA.next(state, 9.0))

def sma.first(r: TA.SMA.State() & Maybe<&2, F32>) -> String:
  match r:
    case (state, first):
      value(first) ++ ", " ++ sma.second(TA.SMA.next(state, 6.0))

def sma.start(r: Result<&2, &1, TA.Error(), TA.SMA.State()>) -> String:
  match r:
    case Fail{e}:
      "invalid"
    case Done{state}:
      sma.first(TA.SMA.next(state, 3.0))

def ema.fourth(r: TA.EMA.State() & Maybe<&2, F32>, third: Maybe<&2, F32>) -> String:
  match r:
    case (state, fourth):
      value(third) ++ ", " ++ value(fourth)

def ema.third(r: TA.EMA.State() & Maybe<&2, F32>) -> String:
  match r:
    case (state, third):
      ema.fourth(TA.EMA.next(state, 15.0), third)

def ema.second(r: TA.EMA.State() & Maybe<&2, F32>) -> String:
  match r:
    case (state, second):
      value(second) ++ ", " ++ ema.third(TA.EMA.next(state, 9.0))

def ema.first(r: TA.EMA.State() & Maybe<&2, F32>) -> String:
  match r:
    case (state, first):
      value(first) ++ ", " ++ ema.second(TA.EMA.next(state, 6.0))

def ema.start(r: Result<&2, &2, TA.Error(), TA.EMA.State()>) -> String:
  match r:
    case Fail{e}:
      "invalid"
    case Done{state}:
      ema.first(TA.EMA.next(state, 3.0))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(sma.start(TA.SMA.init(3)))
    IO.print(ema.start(TA.EMA.init(3)))

#|None, None, Some(6), Some(9)
#|None, None, Some(6), Some(10.5)
