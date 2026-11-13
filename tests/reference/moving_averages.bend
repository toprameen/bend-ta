import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA

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

def sma_stream(initialized: Result<&2, &1, TA.Error(), TA.SMA.State()>) -> Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>:
  match initialized:
    case Fail{e}: Fail{e}
    case Done{state}: Done{stream.collect(~TA.SMA.State(), ~TA.SMA.next, [3.0, 6.0, 9.0, 12.0], state)}

def ema_stream(initialized: Result<&2, &2, TA.Error(), TA.EMA.State()>) -> Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>:
  match initialized:
    case Fail{e}: Fail{e}
    case Done{state}: Done{stream.collect(~TA.EMA.State(), ~TA.EMA.next, [3.0, 6.0, 9.0, 15.0], state)}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("SMA ramp", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([3.0, 6.0, 9.0, 12.0, 15.0, 18.0], 3), [None{}, None{}, Some{6.0}, Some{9.0}, Some{12.0}, Some{15.0}]))
    Unit <- Assert.check("EMA ramp", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.EMA.batch([3.0, 6.0, 9.0, 15.0, 12.0], 3), [None{}, None{}, Some{6.0}, Some{10.5}, Some{11.25}]))
    Unit <- Assert.check("SMA period four", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([2.0, 4.0, 6.0, 8.0, 10.0], 4), [None{}, None{}, None{}, Some{5.0}, Some{7.0}]))
    Unit <- Assert.check("EMA constant samples", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.EMA.batch([7.0, 7.0, 7.0, 7.0], 2), [None{}, Some{7.0}, Some{7.0}, Some{7.0}]))
    Unit <- Assert.check("SMA negative samples", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([F32.neg(3.0), 0.0, 3.0, 6.0], 3), [None{}, None{}, Some{0.0}, Some{3.0}]))
    Unit <- Assert.check("SMA.init", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, sma_stream(TA.SMA.init(3)), [None{}, None{}, Some{6.0}, Some{9.0}]))
    Unit <- Assert.check("EMA.init", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, ema_stream(TA.EMA.init(3)), [None{}, None{}, Some{6.0}, Some{10.5}]))
    Unit <- Assert.check("SMA empty", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([], 3), []))
    Unit <- Assert.check("EMA empty", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.EMA.batch([], 3), []))
    Unit <- Assert.check("SMA warm-up", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([5.0, 10.0], 3), [None{}, None{}]))
    Unit <- Assert.check("EMA warm-up", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.EMA.batch([5.0, 10.0], 3), [None{}, None{}]))
    Unit <- Assert.check("SMA period one", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([3.0, 6.0, 9.0], 1), [Some{3.0}, Some{6.0}, Some{9.0}]))
    Unit <- Assert.check("EMA period one", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.EMA.batch([3.0, 6.0, 9.0], 1), [Some{3.0}, Some{6.0}, Some{9.0}]))
    Unit <- Assert.check("SMA period-one precision", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.SMA.batch([1000000.0, 0.01, 10.0], 1), [Some{1000000.0}, Some{0.01}, Some{10.0}]))
    Unit <- Assert.check("EMA period-one precision", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.EMA.batch([1000000.0, 0.01, 10.0], 1), [Some{1000000.0}, Some{0.01}, Some{10.0}]))
    Unit <- Assert.check("SMA zero period", Result.is_fail(&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>, TA.SMA.batch([3.0], 0)))
    Unit <- Assert.check("EMA zero period", Result.is_fail(&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>, TA.EMA.batch([], 0)))
    Unit <- Assert.check("SMA oversized period", Result.is_fail(&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>, TA.SMA.batch([], 1073741825)))
    Assert.check("EMA oversized period", Result.is_fail(&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>, TA.EMA.batch([], 4294967295)))
