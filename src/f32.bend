import Base
import ./core/config.bend as Config
import ./core/series.bend as Series
import ./core/ema.bend as Ema
import ./core/sma.bend as Sma

def Error() -> Data:
  Config.Error

def EMA.State() -> Data:
  Ema.State<F32>

def SMA.State() -> Type:
  Sma.State<F32>

def EMA.init.result(config: Result<&2, &2, Config.Error, Config.Config>) -> Result<&2, &2, Error(), EMA.State()>:
  match config:
    case Fail{e}:
      Fail{e}
    case Done{Config.Config{period, depth}}:
      Done{Ema.init(~F32, ~U32.to_f32, ~F32.div, period)}

def EMA.init(period: U32) -> Result<&2, &2, Error(), EMA.State()>:
  EMA.init.result(Config.make(period))

def EMA.next(state: EMA.State(), price: F32) -> EMA.State() & Maybe<&2, F32>:
  Ema.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price)

def EMA.batch.result(xs: List<&2, F32>, initialized: Result<&2, &2, Error(), EMA.State()>) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  match initialized:
    case Fail{e}:
      Fail{e}
    case Done{state}:
      Done{Series.batch(~F32, ~EMA.State(), ~EMA.next, xs, state)}

def EMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  EMA.batch.result(xs, EMA.init(period))

def SMA.init.result(config: Result<&2, &2, Config.Error, Config.Config>) -> Result<&2, &1, Error(), SMA.State()>:
  match config:
    case Fail{e}:
      Fail{e}
    case Done{Config.Config{period, depth}}:
      Done{Sma.init(~F32, ~U32.to_f32, period, depth)}

def SMA.init(period: U32) -> Result<&2, &1, Error(), SMA.State()>:
  SMA.init.result(Config.make(period))

def SMA.next(state: SMA.State(), price: F32) -> SMA.State() & Maybe<&2, F32>:
  Sma.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, state, price)

def SMA.batch.result(xs: List<&2, F32>, initialized: Result<&2, &1, Error(), SMA.State()>) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  match initialized:
    case Fail{e}:
      Fail{e}
    case Done{state}:
      Done{Series.batch(~F32, ~SMA.State(), ~SMA.next, xs, state)}

def SMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  SMA.batch.result(xs, SMA.init(period))
