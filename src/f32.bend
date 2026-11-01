import Base
import ./core/hilbert.bend as Hilbert
import ./core/filters.bend as Filters
import ./core/statistics_window.bend as StatWindow
import ./core/volume_filter.bend as VolumeFilter
import ./core/volatility_window.bend as VolWindow
import ./core/hikkake.bend as Hikkake
import ./core/trend_state.bend as TrendState
import ./core/adaptive_window.bend as AdaptiveWindow
import ./core/advanced_oscillator.bend as AdvancedOscillator
import ./core/trend_composite.bend as TrendComposite
import ./core/squeeze.bend as Squeeze
import ./core/window_signals.bend as WindowSignals
import ./core/market_state.bend as MarketState
import ./core/variable.bend as Variable
import ./core/config.bend as Config
import ./core/series.bend as Series
import ./core/ema.bend as Ema
import ./core/sma.bend as Sma

import ./core/window.bend as Win
import ./core/rolling.bend as Rolling
import ./core/extrema.bend as Ext
import ./core/moments.bend as Stats
import ./core/bar.bend as Bars
import ./core/candle.bend as Candles
import ./core/transform.bend as Transform
import ./core/change.bend as Change

import ./core/parameters.bend as Params
import ./core/volume.bend as Volume
import ./core/volatility.bend as Volatility

import ./core/patterns.bend as Patterns
import ./core/pattern_state.bend as PatternState

import ./core/vidya.bend as Vidya

import ./core/mama.bend as Mama

import ./core/ma.bend as Ma
import ./core/statistics.bend as Statistics
import ./core/overlap.bend as Overlap

import ./core/momentum.bend as MomCore
import ./core/directional.bend as Directional
import ./core/momentum_window.bend as MomentumWindow
import ./core/momentum_market.bend as MomentumMarket
import ./core/momentum_smooth.bend as MomentumSmooth
import ./core/momentum_composite.bend as MomentumComposite
import ./core/momentum_init.bend as MomentumInit

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
      Done{Series.batch(~F32, ~F32, ~EMA.State(), ~EMA.next, xs, state)}

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
      Done{Series.batch(~F32, ~F32, ~SMA.State(), ~SMA.next, xs, state)}

def SMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  SMA.batch.result(xs, SMA.init(period))

def RMA.State() -> Data:
  Ema.State<F32>

def RMA.init.result(config: Result<&2, &2, Config.Error, Config.Config>) -> Result<&2, &2, Error(), RMA.State()>:
  match config:
    case Fail{e}:
      Fail{e}
    case Done{Config.Config{+period, depth}}:
      Done{Ema.init.alpha(~F32, ~U32.to_f32, period, F32.div(1.0, U32.to_f32(period)))}

def RMA.init(period: U32) -> Result<&2, &2, Error(), RMA.State()>:
  RMA.init.result(Config.make(period))

def RMA.next(state: RMA.State(), price: F32) -> RMA.State() & Maybe<&2, F32>:
  EMA.next(state, price)

def RMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  EMA.batch.result(xs, RMA.init(period))

def Window.State() -> Type:
  Win.State<F32>

def Window.init.result(config: Result<&2, &2, Config.Error, Config.Config>) -> Result<&2, &1, Error(), Window.State()>:
  match config:
    case Fail{e}:
      Fail{e}
    case Done{Config.Config{period, depth}}:
      Done{Win.init(~F32, period, depth, 0.0)}

def Window.init(period: U32) -> Result<&2, &1, Error(), Window.State()>:
  Window.init.result(Config.make(period))

def Window.push(state: Window.State(), price: F32) -> Window.State() & Maybe<&2, F32>:
  Win.push(~F32, state, price)

def Window.lag(state: Window.State(), age: U32) -> Window.State() & Maybe<&2, F32>:
  Win.lag(~F32, state, age)

def Window.length(state: Window.State()) -> Window.State() & U32:
  Win.length(~F32, state)

def SUM.State() -> Type:
  Rolling.State<F32>

def SUM.init.result(result: Result<&2, &1, Error(), Window.State()>) -> Result<&2, &1, Error(), SUM.State()>:
  match result:
    case Fail{e}:
      Fail{e}
    case Done{window}:
      Done{Rolling.Sum{window, 0.0}}

def SUM.init(period: U32) -> Result<&2, &1, Error(), SUM.State()>:
  SUM.init.result(Window.init(period))

def SUM.next(state: SUM.State(), price: F32) -> SUM.State() & Maybe<&2, F32>:
  Rolling.push(~F32, ~F32.add, ~F32.sub, state, price)

def Extrema.Value() -> Data:
  Ext.Value<F32>

def Extrema.read(state: Window.State()) -> Window.State() & Maybe<&2, Extrema.Value()>:
  Ext.read(~F32, ~F32.min, ~F32.max, state)

def Extrema.next(state: Window.State(), price: F32) -> Window.State() & Maybe<&2, Extrema.Value()>:
  Ext.next(~F32, ~F32.min, ~F32.max, state, price)

def Moments.Value() -> Data:
  Stats.Value<F32>

def Moments.read(state: Window.State()) -> Window.State() & Maybe<&2, Moments.Value()>:
  Stats.read(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state)

def Moments.next(state: Window.State(), price: F32) -> Window.State() & Maybe<&2, Moments.Value()>:
  Stats.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price)

def Moments.stddev(value: Moments.Value()) -> F32:
  match value:
    case Stats.Moments{mean, variance}:
      F32.sqrt(variance)

def is_finite(value: F32) -> Bool:
  U32.is_ne(U32.and(F32.bits(value), 2139095040), 2139095040)

def Bar.valid(bar: Bars.OHLC<F32>) -> Bool:
  Bars.valid(~F32, ~is_finite, ~F32.is_le, bar)

def true_range(previous: F32, bar: Bars.HLC<F32>) -> F32:
  Bars.true_range(~F32, ~F32.sub, ~F32.abs, ~F32.max, previous, bar)

def Candle.Error() -> Data:
  Candles.Error

def Candle.State() -> Type:
  Candles.State<F32>

def Candle.defaults(name: Candles.Name) -> Candles.Setting<F32>:
  Candles.defaults(~F32, ~U32.to_f32, ~F32.div, name)

def Candle.init.result(setting: Candles.Setting<F32>, config: Result<&2, &2, Config.Error, Config.Config>) -> Result<&2, &1, Candle.Error(), Candle.State()>:
  match config:
    case Fail{e}:
      Fail{Candles.InvalidPeriod{}}
    case Done{Config.Config{period, depth}}:
      Done{Candles.init(~F32, ~U32.to_f32, setting, period, depth)}

def Candle.init.checked(setting: Candles.Setting<F32>, period: U32, valid: Bool) -> Result<&2, &1, Candle.Error(), Candle.State()>:
  match valid:
    case False{}:
      Fail{Candles.InvalidFactor{}}
    case True{}:
      Candle.init.result(setting, Config.make(U32.max(period, 1)))

def Candle.init(setting: Candles.Setting<F32>) -> Result<&2, &1, Candle.Error(), Candle.State()>:
  match setting:
    case Candles.Setting{kind, +period, +factor}:
      Candle.init.checked(Candles.Setting{kind, period, factor}, period, Bool.and(is_finite(factor), F32.is_ge(factor, 0.0)))

def Candle.next(state: Candle.State(), bar: Bars.OHLC<F32>) -> Candle.State() & Maybe<&2, F32>:
  Candles.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, state, bar)

def ACOS(value: F32) -> F32:
  F32.acos(value)

def ASIN(value: F32) -> F32:
  F32.asin(value)

def ATAN(value: F32) -> F32:
  F32.atan(value)

def CEIL(value: F32) -> F32:
  F32.ceil(value)

def COS(value: F32) -> F32:
  F32.cos(value)

def COSH(value: F32) -> F32:
  F32.cosh(value)

def EXP(value: F32) -> F32:
  F32.exp(value)

def FLOOR(value: F32) -> F32:
  F32.floor(value)

def LN(value: F32) -> F32:
  F32.log(value)

def LOG10(value: F32) -> F32:
  F32.log10(value)

def SIN(value: F32) -> F32:
  F32.sin(value)

def SINH(value: F32) -> F32:
  F32.sinh(value)

def SQRT(value: F32) -> F32:
  F32.sqrt(value)

def TAN(value: F32) -> F32:
  F32.tan(value)

def TANH(value: F32) -> F32:
  F32.tanh(value)

def ADD(inputs: Transform.Operands<F32>) -> F32:
  Transform.binary(~F32, ~F32.add, inputs)

def SUB(inputs: Transform.Operands<F32>) -> F32:
  Transform.binary(~F32, ~F32.sub, inputs)

def MULT(inputs: Transform.Operands<F32>) -> F32:
  Transform.binary(~F32, ~F32.mul, inputs)

def BOP(bar: Bars.OHLC<F32>) -> F32:
  Transform.bop(~F32, ~U32.to_f32, ~F32.sub, ~F32.div, ~F32.is_le, bar)

def IBS(bar: Bars.HLC<F32>) -> F32:
  Transform.ibs(~F32, ~U32.to_f32, ~F32.sub, ~F32.div, ~F32.is_le, bar)

def MARKETFI(bar: Bars.HLV<F32>) -> F32:
  Transform.marketfi(~F32, ~U32.to_f32, ~F32.sub, ~F32.div, ~F32.is_eq, bar)

def AVGPRICE(bar: Bars.OHLC<F32>) -> F32:
  Transform.avgprice(~F32, ~U32.to_f32, ~F32.add, ~F32.div, bar)

def MEDPRICE(bar: Bars.HL<F32>) -> F32:
  Transform.medprice(~F32, ~U32.to_f32, ~F32.add, ~F32.div, bar)

def TYPPRICE(bar: Bars.HLC<F32>) -> F32:
  Transform.typprice(~F32, ~U32.to_f32, ~F32.add, ~F32.div, bar)

def WCLPRICE(bar: Bars.HLC<F32>) -> F32:
  Transform.wclprice(~F32, ~U32.to_f32, ~F32.add, ~F32.mul, ~F32.div, bar)

def CUMSUM.State() -> Data:
  F32

def CUMSUM.init() -> CUMSUM.State():
  0.0

def CUMSUM.next(state: CUMSUM.State(), value: F32) -> CUMSUM.State() & Maybe<&2, F32>:
  Transform.cumulative(~F32, ~F32.add, state, value)

def CUMSUM.batch(xs: List<&2, F32>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~F32, ~F32, ~CUMSUM.State(), ~CUMSUM.next, xs, CUMSUM.init())

def change.roc(current: F32, previous: F32) -> F32:
  Change.guarded(~F32, ~U32.to_f32, ~F32.is_eq,
    ~(x => y => Change.percent(~F32, ~U32.to_f32, ~F32.sub, ~F32.mul, ~F32.div, x, y)), current, previous)

def change.rocp(current: F32, previous: F32) -> F32:
  Change.guarded(~F32, ~U32.to_f32, ~F32.is_eq,
    ~(x => y => Change.fraction(~F32, ~F32.sub, ~F32.div, x, y)), current, previous)

def change.rocr(current: F32, previous: F32) -> F32:
  Change.guarded(~F32, ~U32.to_f32, ~F32.is_eq, ~F32.div, current, previous)

def change.rocr100(current: F32, previous: F32) -> F32:
  Change.guarded(~F32, ~U32.to_f32, ~F32.is_eq,
    ~(x => y => Change.ratio100(~F32, ~U32.to_f32, ~F32.mul, ~F32.div, x, y)), current, previous)

def change.batch(~step: Window.State() -> F32 -> Window.State() & Maybe<&2, F32>, xs: List<&2, F32>, result: Result<&2, &1, Error(), Window.State()>) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}:
      Done{Series.batch(~F32, ~F32, ~Window.State(), ~step, xs, state)}

def MOM.State() -> Type:
  Window.State()

def MOM.init(period: U32) -> Result<&2, &1, Error(), MOM.State()>:
  Window.init(period)

def MOM.next(state: MOM.State(), value: F32) -> MOM.State() & Maybe<&2, F32>:
  Change.next(~F32, ~F32.sub, state, value)

def MOM.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  change.batch(~MOM.next, xs, MOM.init(period))

def ROC.State() -> Type:
  Window.State()

def ROC.init(period: U32) -> Result<&2, &1, Error(), ROC.State()>:
  Window.init(period)

def ROC.next(state: ROC.State(), value: F32) -> ROC.State() & Maybe<&2, F32>:
  Change.next(~F32, ~change.roc, state, value)

def ROC.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  change.batch(~ROC.next, xs, ROC.init(period))

def ROCP.State() -> Type:
  Window.State()

def ROCP.init(period: U32) -> Result<&2, &1, Error(), ROCP.State()>:
  Window.init(period)

def ROCP.next(state: ROCP.State(), value: F32) -> ROCP.State() & Maybe<&2, F32>:
  Change.next(~F32, ~change.rocp, state, value)

def ROCP.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  change.batch(~ROCP.next, xs, ROCP.init(period))

def ROCR.State() -> Type:
  Window.State()

def ROCR.init(period: U32) -> Result<&2, &1, Error(), ROCR.State()>:
  Window.init(period)

def ROCR.next(state: ROCR.State(), value: F32) -> ROCR.State() & Maybe<&2, F32>:
  Change.next(~F32, ~change.rocr, state, value)

def ROCR.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  change.batch(~ROCR.next, xs, ROCR.init(period))

def ROCR100.State() -> Type:
  Window.State()

def ROCR100.init(period: U32) -> Result<&2, &1, Error(), ROCR100.State()>:
  Window.init(period)

def ROCR100.next(state: ROCR100.State(), value: F32) -> ROCR100.State() & Maybe<&2, F32>:
  Change.next(~F32, ~change.rocr100, state, value)

def ROCR100.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  change.batch(~ROCR100.next, xs, ROCR100.init(period))

def VolumeError() -> Data:
  Params.Error

def volume.depth(+period: U32) -> Nat:
  Config.depth(period)

def OBV.State() -> Data:
  Volume.Index<F32>

def OBV.init() -> OBV.State():
  Volume.index.init(~F32, ~U32.to_f32, Volume.Obv{})

def OBV.next(state: OBV.State(), bar: Bars.CV<F32>) -> OBV.State() & Maybe<&2, F32>:
  Volume.index.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_lt, ~F32.is_gt, ~is_finite, state, bar)

def OBV.batch(xs: List<&2, Bars.CV<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.CV<F32>, ~F32, ~OBV.State(), ~OBV.next, xs, OBV.init())

def NVI.State() -> Data:
  Volume.Index<F32>

def NVI.init() -> NVI.State():
  Volume.index.init(~F32, ~U32.to_f32, Volume.Nvi{})

def NVI.next(state: NVI.State(), bar: Bars.CV<F32>) -> NVI.State() & Maybe<&2, F32>:
  Volume.index.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_lt, ~F32.is_gt, ~is_finite, state, bar)

def NVI.batch(xs: List<&2, Bars.CV<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.CV<F32>, ~F32, ~NVI.State(), ~NVI.next, xs, NVI.init())

def PVI.State() -> Data:
  Volume.Index<F32>

def PVI.init() -> PVI.State():
  Volume.index.init(~F32, ~U32.to_f32, Volume.Pvi{})

def PVI.next(state: PVI.State(), bar: Bars.CV<F32>) -> PVI.State() & Maybe<&2, F32>:
  Volume.index.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_lt, ~F32.is_gt, ~is_finite, state, bar)

def PVI.batch(xs: List<&2, Bars.CV<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.CV<F32>, ~F32, ~PVI.State(), ~PVI.next, xs, PVI.init())

def PVT.State() -> Data:
  Volume.Index<F32>

def PVT.init() -> PVT.State():
  Volume.index.init(~F32, ~U32.to_f32, Volume.Pvt{})

def PVT.next(state: PVT.State(), bar: Bars.CV<F32>) -> PVT.State() & Maybe<&2, F32>:
  Volume.index.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_lt, ~F32.is_gt, ~is_finite, state, bar)

def PVT.batch(xs: List<&2, Bars.CV<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.CV<F32>, ~F32, ~PVT.State(), ~PVT.next, xs, PVT.init())

def AD.State() -> Data:
  F32

def AD.init() -> AD.State():
  0.0

def AD.next(state: AD.State(), bar: Bars.HLCV<F32>) -> AD.State() & Maybe<&2, F32>:
  Volume.ad.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_gt, state, bar)

def AD.batch(xs: List<&2, Bars.HLCV<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.HLCV<F32>, ~F32, ~AD.State(), ~AD.next, xs, AD.init())

def TRANGE.State() -> Data:
  Maybe<&2, F32>

def TRANGE.init() -> TRANGE.State():
  None{}

def TRANGE.next(state: TRANGE.State(), bar: Bars.HLC<F32>) -> TRANGE.State() & Maybe<&2, F32>:
  Volatility.range.next(~F32, ~F32.sub, ~F32.abs, ~F32.max, state, bar)

def TRANGE.batch(xs: List<&2, Bars.HLC<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.HLC<F32>, ~F32, ~TRANGE.State(), ~TRANGE.next, xs, TRANGE.init())

def CMF.State() -> Type:
  Win.State<Volume.Flow<F32>>

def volume.CMF.valid(+period: U32, valid: Bool) -> Result<&2, &1, Params.Error, CMF.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volume.cmf.init(~F32, ~U32.to_f32, period, volume.depth(period))}

def CMF.init(+period: U32) -> Result<&2, &1, Params.Error, CMF.State()>:
  volume.CMF.valid(period, Bool.and(Params.period(period), U32.is_ge(period, 2)))

def CMF.next(state: CMF.State(), bar: Bars.HLCV<F32>) -> CMF.State() & Maybe<&2, F32>:
  Volume.cmf.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_gt, state, bar)

def CMF.batch(xs: List<&2, Bars.HLCV<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLCV<F32>, ~F32, ~CMF.State(), ~Params.Error, ~CMF.next, xs, CMF.init(period))

def EFI.State() -> Data:
  Volume.Force<F32>

def volume.EFI.valid(+period: U32, valid: Bool) -> Result<&2, &1, Params.Error, EFI.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volume.force.init(~F32, ~U32.to_f32, ~F32.div, period)}

def EFI.init(+period: U32) -> Result<&2, &1, Params.Error, EFI.State()>:
  volume.EFI.valid(period, Bool.and(Params.period(period), U32.is_ge(period, 1)))

def EFI.next(state: EFI.State(), bar: Bars.CV<F32>) -> EFI.State() & Maybe<&2, F32>:
  Volume.force.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, bar)

def EFI.batch(xs: List<&2, Bars.CV<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.CV<F32>, ~F32, ~EFI.State(), ~Params.Error, ~EFI.next, xs, EFI.init(period))

def ADR.State() -> Type:
  Sma.State<F32>

def volume.ADR.valid(+period: U32, valid: Bool) -> Result<&2, &1, Params.Error, ADR.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Sma.init(~F32, ~U32.to_f32, period, volume.depth(period))}

def ADR.init(+period: U32) -> Result<&2, &1, Params.Error, ADR.State()>:
  volume.ADR.valid(period, Bool.and(Params.period(period), U32.is_ge(period, 1)))

def ADR.next(state: ADR.State(), bar: Bars.HL<F32>) -> ADR.State() & Maybe<&2, F32>:
  Volatility.adr.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, state, bar)

def ADR.batch(xs: List<&2, Bars.HL<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~ADR.State(), ~Params.Error, ~ADR.next, xs, ADR.init(period))

def ATR.State() -> Data:
  Volatility.Atr<F32>

def volume.ATR.valid(+period: U32, valid: Bool) -> Result<&2, &1, Params.Error, ATR.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volatility.atr.init(~F32, ~U32.to_f32, ~F32.div, period)}

def ATR.init(+period: U32) -> Result<&2, &1, Params.Error, ATR.State()>:
  volume.ATR.valid(period, Bool.and(Params.period(period), U32.is_ge(period, 1)))

def ATR.next(state: ATR.State(), bar: Bars.HLC<F32>) -> ATR.State() & Maybe<&2, F32>:
  Volatility.atr.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, state, bar)

def ATR.batch(xs: List<&2, Bars.HLC<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~ATR.State(), ~Params.Error, ~ATR.next, xs, ATR.init(period))

def NATR.State() -> Data:
  Volatility.Natr<F32>

def volume.NATR.valid(+period: U32, valid: Bool) -> Result<&2, &1, Params.Error, NATR.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volatility.natr.init(~F32, ~U32.to_f32, ~F32.div, period)}

def NATR.init(+period: U32) -> Result<&2, &1, Params.Error, NATR.State()>:
  volume.NATR.valid(period, Bool.and(Params.period(period), U32.is_ge(period, 1)))

def NATR.next(state: NATR.State(), bar: Bars.HLC<F32>) -> NATR.State() & Maybe<&2, F32>:
  Volatility.natr.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_eq, state, bar)

def NATR.batch(xs: List<&2, Bars.HLC<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~NATR.State(), ~Params.Error, ~NATR.next, xs, NATR.init(period))

def EMV.State() -> Type:
  Volume.Ease<F32>

def volume.EMV.valid(+period: U32, divisor: F32, valid: Bool) -> Result<&2, &1, Params.Error, EMV.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volume.ease.init(~F32, ~U32.to_f32, period, volume.depth(period), divisor)}

def EMV.init(+period: U32, +divisor: F32) -> Result<&2, &1, Params.Error, EMV.State()>:
  volume.EMV.valid(period, divisor, Bool.and(Params.period(period), Bool.and(is_finite(divisor), Bool.and(F32.is_ge(divisor, 1.0), F32.is_le(divisor, 3.0e37)))))

def EMV.next(state: EMV.State(), bar: Bars.HLV<F32>) -> EMV.State() & Maybe<&2, F32>:
  Volume.ease.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, state, bar)

def EMV.batch(xs: List<&2, Bars.HLV<F32>>, period: U32, divisor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLV<F32>, ~F32, ~EMV.State(), ~Params.Error, ~EMV.next, xs, EMV.init(period, divisor))

def CVI.State() -> Type:
  Volatility.Cvi<F32>

def volume.CVI.valid(period: U32, +lag: U32, valid: Bool) -> Result<&2, &1, Params.Error, CVI.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volatility.cvi.init(~F32, ~U32.to_f32, ~F32.div, period, lag, volume.depth(lag))}

def CVI.init(+period: U32, +lag: U32) -> Result<&2, &1, Params.Error, CVI.State()>:
  volume.CVI.valid(period, lag, Bool.and(Params.periods([period, lag]), U32.is_ge(period, 2)))

def CVI.next(state: CVI.State(), bar: Bars.HL<F32>) -> CVI.State() & Maybe<&2, F32>:
  Volatility.cvi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, state, bar)

def CVI.batch(xs: List<&2, Bars.HL<F32>>, period: U32, lag: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~CVI.State(), ~Params.Error, ~CVI.next, xs, CVI.init(period, lag))

def MASSI.State() -> Type:
  Volatility.Mass<F32>

def volume.MASSI.valid(fast: U32, +slow: U32, valid: Bool) -> Result<&2, &1, Params.Error, MASSI.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volatility.mass.init(~F32, ~U32.to_f32, ~F32.div, fast, slow, volume.depth(slow))}

def MASSI.init(+fast: U32, +slow: U32) -> Result<&2, &1, Params.Error, MASSI.State()>:
  volume.MASSI.valid(fast, slow, Bool.and(Params.periods([fast, slow]), Bool.and(U32.is_ge(fast, 2), U32.is_ge(slow, 2))))

def MASSI.next(state: MASSI.State(), bar: Bars.HL<F32>) -> MASSI.State() & Maybe<&2, F32>:
  Volatility.mass.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, state, bar)

def MASSI.batch(xs: List<&2, Bars.HL<F32>>, fast: U32, slow: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~MASSI.State(), ~Params.Error, ~MASSI.next, xs, MASSI.init(fast, slow))

def Pattern.State() -> Type:
  PatternState.State<F32>

def Pattern.Error() -> Data:
  Params.Error

def Pattern.Settings() -> Data:
  Patterns.Settings<F32>

def Pattern.Signal() -> Data:
  Patterns.Signal

def Pattern.defaults() -> Pattern.Settings():
  Patterns.defaults(~F32, ~U32.to_f32, ~F32.div)

def Pattern.init(name: Patterns.Name, settings: Pattern.Settings(), penetration: F32) -> Result<&2, &1, Pattern.Error(), Pattern.State()>:
  PatternState.init(~F32, ~U32.to_f32, ~is_finite, ~F32.is_ge, name, settings, penetration)

def Pattern.next(state: Pattern.State(), bar: Bars.OHLC<F32>) -> Pattern.State() & Maybe<&2, Pattern.Signal()>:
  PatternState.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, ~F32.is_eq, ~F32.is_lt, ~F32.is_le, ~F32.is_gt, ~F32.is_ge, state, bar)

def Pattern.batch(xs: List<&2, Bars.OHLC<F32>>, name: Patterns.Name, settings: Pattern.Settings(), penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, Pattern.init(name, settings, penetration))

def CDL2CROWS.State() -> Type:
  Pattern.State()

def CDL2CROWS.init() -> Result<&2, &1, Pattern.Error(), CDL2CROWS.State()>:
  Pattern.init(Patterns.CDL2CROWS{}, Pattern.defaults(), 0.0)

def CDL2CROWS.next(state: CDL2CROWS.State(), bar: Bars.OHLC<F32>) -> CDL2CROWS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL2CROWS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL2CROWS.init())

def CDL3BLACKCROWS.State() -> Type:
  Pattern.State()

def CDL3BLACKCROWS.init() -> Result<&2, &1, Pattern.Error(), CDL3BLACKCROWS.State()>:
  Pattern.init(Patterns.CDL3BLACKCROWS{}, Pattern.defaults(), 0.0)

def CDL3BLACKCROWS.next(state: CDL3BLACKCROWS.State(), bar: Bars.OHLC<F32>) -> CDL3BLACKCROWS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL3BLACKCROWS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL3BLACKCROWS.init())

def CDL3INSIDE.State() -> Type:
  Pattern.State()

def CDL3INSIDE.init() -> Result<&2, &1, Pattern.Error(), CDL3INSIDE.State()>:
  Pattern.init(Patterns.CDL3INSIDE{}, Pattern.defaults(), 0.0)

def CDL3INSIDE.next(state: CDL3INSIDE.State(), bar: Bars.OHLC<F32>) -> CDL3INSIDE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL3INSIDE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL3INSIDE.init())

def CDL3LINESTRIKE.State() -> Type:
  Pattern.State()

def CDL3LINESTRIKE.init() -> Result<&2, &1, Pattern.Error(), CDL3LINESTRIKE.State()>:
  Pattern.init(Patterns.CDL3LINESTRIKE{}, Pattern.defaults(), 0.0)

def CDL3LINESTRIKE.next(state: CDL3LINESTRIKE.State(), bar: Bars.OHLC<F32>) -> CDL3LINESTRIKE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL3LINESTRIKE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL3LINESTRIKE.init())

def CDL3OUTSIDE.State() -> Type:
  Pattern.State()

def CDL3OUTSIDE.init() -> Result<&2, &1, Pattern.Error(), CDL3OUTSIDE.State()>:
  Pattern.init(Patterns.CDL3OUTSIDE{}, Pattern.defaults(), 0.0)

def CDL3OUTSIDE.next(state: CDL3OUTSIDE.State(), bar: Bars.OHLC<F32>) -> CDL3OUTSIDE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL3OUTSIDE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL3OUTSIDE.init())

def CDL3STARSINSOUTH.State() -> Type:
  Pattern.State()

def CDL3STARSINSOUTH.init() -> Result<&2, &1, Pattern.Error(), CDL3STARSINSOUTH.State()>:
  Pattern.init(Patterns.CDL3STARSINSOUTH{}, Pattern.defaults(), 0.0)

def CDL3STARSINSOUTH.next(state: CDL3STARSINSOUTH.State(), bar: Bars.OHLC<F32>) -> CDL3STARSINSOUTH.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL3STARSINSOUTH.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL3STARSINSOUTH.init())

def CDL3WHITESOLDIERS.State() -> Type:
  Pattern.State()

def CDL3WHITESOLDIERS.init() -> Result<&2, &1, Pattern.Error(), CDL3WHITESOLDIERS.State()>:
  Pattern.init(Patterns.CDL3WHITESOLDIERS{}, Pattern.defaults(), 0.0)

def CDL3WHITESOLDIERS.next(state: CDL3WHITESOLDIERS.State(), bar: Bars.OHLC<F32>) -> CDL3WHITESOLDIERS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDL3WHITESOLDIERS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDL3WHITESOLDIERS.init())

def CDLABANDONEDBABY.State() -> Type:
  Pattern.State()

def CDLABANDONEDBABY.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLABANDONEDBABY.State()>:
  Pattern.init(Patterns.CDLABANDONEDBABY{}, Pattern.defaults(), penetration)

def CDLABANDONEDBABY.next(state: CDLABANDONEDBABY.State(), bar: Bars.OHLC<F32>) -> CDLABANDONEDBABY.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLABANDONEDBABY.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLABANDONEDBABY.init(penetration))

def CDLADVANCEBLOCK.State() -> Type:
  Pattern.State()

def CDLADVANCEBLOCK.init() -> Result<&2, &1, Pattern.Error(), CDLADVANCEBLOCK.State()>:
  Pattern.init(Patterns.CDLADVANCEBLOCK{}, Pattern.defaults(), 0.0)

def CDLADVANCEBLOCK.next(state: CDLADVANCEBLOCK.State(), bar: Bars.OHLC<F32>) -> CDLADVANCEBLOCK.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLADVANCEBLOCK.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLADVANCEBLOCK.init())

def CDLBELTHOLD.State() -> Type:
  Pattern.State()

def CDLBELTHOLD.init() -> Result<&2, &1, Pattern.Error(), CDLBELTHOLD.State()>:
  Pattern.init(Patterns.CDLBELTHOLD{}, Pattern.defaults(), 0.0)

def CDLBELTHOLD.next(state: CDLBELTHOLD.State(), bar: Bars.OHLC<F32>) -> CDLBELTHOLD.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLBELTHOLD.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLBELTHOLD.init())

def CDLBREAKAWAY.State() -> Type:
  Pattern.State()

def CDLBREAKAWAY.init() -> Result<&2, &1, Pattern.Error(), CDLBREAKAWAY.State()>:
  Pattern.init(Patterns.CDLBREAKAWAY{}, Pattern.defaults(), 0.0)

def CDLBREAKAWAY.next(state: CDLBREAKAWAY.State(), bar: Bars.OHLC<F32>) -> CDLBREAKAWAY.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLBREAKAWAY.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLBREAKAWAY.init())

def CDLCLOSINGMARUBOZU.State() -> Type:
  Pattern.State()

def CDLCLOSINGMARUBOZU.init() -> Result<&2, &1, Pattern.Error(), CDLCLOSINGMARUBOZU.State()>:
  Pattern.init(Patterns.CDLCLOSINGMARUBOZU{}, Pattern.defaults(), 0.0)

def CDLCLOSINGMARUBOZU.next(state: CDLCLOSINGMARUBOZU.State(), bar: Bars.OHLC<F32>) -> CDLCLOSINGMARUBOZU.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLCLOSINGMARUBOZU.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLCLOSINGMARUBOZU.init())

def CDLCONCEALBABYSWALL.State() -> Type:
  Pattern.State()

def CDLCONCEALBABYSWALL.init() -> Result<&2, &1, Pattern.Error(), CDLCONCEALBABYSWALL.State()>:
  Pattern.init(Patterns.CDLCONCEALBABYSWALL{}, Pattern.defaults(), 0.0)

def CDLCONCEALBABYSWALL.next(state: CDLCONCEALBABYSWALL.State(), bar: Bars.OHLC<F32>) -> CDLCONCEALBABYSWALL.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLCONCEALBABYSWALL.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLCONCEALBABYSWALL.init())

def CDLCOUNTERATTACK.State() -> Type:
  Pattern.State()

def CDLCOUNTERATTACK.init() -> Result<&2, &1, Pattern.Error(), CDLCOUNTERATTACK.State()>:
  Pattern.init(Patterns.CDLCOUNTERATTACK{}, Pattern.defaults(), 0.0)

def CDLCOUNTERATTACK.next(state: CDLCOUNTERATTACK.State(), bar: Bars.OHLC<F32>) -> CDLCOUNTERATTACK.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLCOUNTERATTACK.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLCOUNTERATTACK.init())

def CDLDARKCLOUDCOVER.State() -> Type:
  Pattern.State()

def CDLDARKCLOUDCOVER.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLDARKCLOUDCOVER.State()>:
  Pattern.init(Patterns.CDLDARKCLOUDCOVER{}, Pattern.defaults(), penetration)

def CDLDARKCLOUDCOVER.next(state: CDLDARKCLOUDCOVER.State(), bar: Bars.OHLC<F32>) -> CDLDARKCLOUDCOVER.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLDARKCLOUDCOVER.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLDARKCLOUDCOVER.init(penetration))

def CDLDOJI.State() -> Type:
  Pattern.State()

def CDLDOJI.init() -> Result<&2, &1, Pattern.Error(), CDLDOJI.State()>:
  Pattern.init(Patterns.CDLDOJI{}, Pattern.defaults(), 0.0)

def CDLDOJI.next(state: CDLDOJI.State(), bar: Bars.OHLC<F32>) -> CDLDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLDOJI.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLDOJI.init())

def CDLDOJISTAR.State() -> Type:
  Pattern.State()

def CDLDOJISTAR.init() -> Result<&2, &1, Pattern.Error(), CDLDOJISTAR.State()>:
  Pattern.init(Patterns.CDLDOJISTAR{}, Pattern.defaults(), 0.0)

def CDLDOJISTAR.next(state: CDLDOJISTAR.State(), bar: Bars.OHLC<F32>) -> CDLDOJISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLDOJISTAR.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLDOJISTAR.init())

def CDLDRAGONFLYDOJI.State() -> Type:
  Pattern.State()

def CDLDRAGONFLYDOJI.init() -> Result<&2, &1, Pattern.Error(), CDLDRAGONFLYDOJI.State()>:
  Pattern.init(Patterns.CDLDRAGONFLYDOJI{}, Pattern.defaults(), 0.0)

def CDLDRAGONFLYDOJI.next(state: CDLDRAGONFLYDOJI.State(), bar: Bars.OHLC<F32>) -> CDLDRAGONFLYDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLDRAGONFLYDOJI.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLDRAGONFLYDOJI.init())

def CDLENGULFING.State() -> Type:
  Pattern.State()

def CDLENGULFING.init() -> Result<&2, &1, Pattern.Error(), CDLENGULFING.State()>:
  Pattern.init(Patterns.CDLENGULFING{}, Pattern.defaults(), 0.0)

def CDLENGULFING.next(state: CDLENGULFING.State(), bar: Bars.OHLC<F32>) -> CDLENGULFING.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLENGULFING.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLENGULFING.init())

def CDLEVENINGDOJISTAR.State() -> Type:
  Pattern.State()

def CDLEVENINGDOJISTAR.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLEVENINGDOJISTAR.State()>:
  Pattern.init(Patterns.CDLEVENINGDOJISTAR{}, Pattern.defaults(), penetration)

def CDLEVENINGDOJISTAR.next(state: CDLEVENINGDOJISTAR.State(), bar: Bars.OHLC<F32>) -> CDLEVENINGDOJISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLEVENINGDOJISTAR.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLEVENINGDOJISTAR.init(penetration))

def CDLEVENINGSTAR.State() -> Type:
  Pattern.State()

def CDLEVENINGSTAR.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLEVENINGSTAR.State()>:
  Pattern.init(Patterns.CDLEVENINGSTAR{}, Pattern.defaults(), penetration)

def CDLEVENINGSTAR.next(state: CDLEVENINGSTAR.State(), bar: Bars.OHLC<F32>) -> CDLEVENINGSTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLEVENINGSTAR.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLEVENINGSTAR.init(penetration))

def CDLGAPSIDESIDEWHITE.State() -> Type:
  Pattern.State()

def CDLGAPSIDESIDEWHITE.init() -> Result<&2, &1, Pattern.Error(), CDLGAPSIDESIDEWHITE.State()>:
  Pattern.init(Patterns.CDLGAPSIDESIDEWHITE{}, Pattern.defaults(), 0.0)

def CDLGAPSIDESIDEWHITE.next(state: CDLGAPSIDESIDEWHITE.State(), bar: Bars.OHLC<F32>) -> CDLGAPSIDESIDEWHITE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLGAPSIDESIDEWHITE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLGAPSIDESIDEWHITE.init())

def CDLGRAVESTONEDOJI.State() -> Type:
  Pattern.State()

def CDLGRAVESTONEDOJI.init() -> Result<&2, &1, Pattern.Error(), CDLGRAVESTONEDOJI.State()>:
  Pattern.init(Patterns.CDLGRAVESTONEDOJI{}, Pattern.defaults(), 0.0)

def CDLGRAVESTONEDOJI.next(state: CDLGRAVESTONEDOJI.State(), bar: Bars.OHLC<F32>) -> CDLGRAVESTONEDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLGRAVESTONEDOJI.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLGRAVESTONEDOJI.init())

def CDLHAMMER.State() -> Type:
  Pattern.State()

def CDLHAMMER.init() -> Result<&2, &1, Pattern.Error(), CDLHAMMER.State()>:
  Pattern.init(Patterns.CDLHAMMER{}, Pattern.defaults(), 0.0)

def CDLHAMMER.next(state: CDLHAMMER.State(), bar: Bars.OHLC<F32>) -> CDLHAMMER.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLHAMMER.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLHAMMER.init())

def CDLHANGINGMAN.State() -> Type:
  Pattern.State()

def CDLHANGINGMAN.init() -> Result<&2, &1, Pattern.Error(), CDLHANGINGMAN.State()>:
  Pattern.init(Patterns.CDLHANGINGMAN{}, Pattern.defaults(), 0.0)

def CDLHANGINGMAN.next(state: CDLHANGINGMAN.State(), bar: Bars.OHLC<F32>) -> CDLHANGINGMAN.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLHANGINGMAN.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLHANGINGMAN.init())

def CDLHARAMI.State() -> Type:
  Pattern.State()

def CDLHARAMI.init() -> Result<&2, &1, Pattern.Error(), CDLHARAMI.State()>:
  Pattern.init(Patterns.CDLHARAMI{}, Pattern.defaults(), 0.0)

def CDLHARAMI.next(state: CDLHARAMI.State(), bar: Bars.OHLC<F32>) -> CDLHARAMI.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLHARAMI.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLHARAMI.init())

def CDLHARAMICROSS.State() -> Type:
  Pattern.State()

def CDLHARAMICROSS.init() -> Result<&2, &1, Pattern.Error(), CDLHARAMICROSS.State()>:
  Pattern.init(Patterns.CDLHARAMICROSS{}, Pattern.defaults(), 0.0)

def CDLHARAMICROSS.next(state: CDLHARAMICROSS.State(), bar: Bars.OHLC<F32>) -> CDLHARAMICROSS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLHARAMICROSS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLHARAMICROSS.init())

def CDLHIGHWAVE.State() -> Type:
  Pattern.State()

def CDLHIGHWAVE.init() -> Result<&2, &1, Pattern.Error(), CDLHIGHWAVE.State()>:
  Pattern.init(Patterns.CDLHIGHWAVE{}, Pattern.defaults(), 0.0)

def CDLHIGHWAVE.next(state: CDLHIGHWAVE.State(), bar: Bars.OHLC<F32>) -> CDLHIGHWAVE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLHIGHWAVE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLHIGHWAVE.init())

def CDLHOMINGPIGEON.State() -> Type:
  Pattern.State()

def CDLHOMINGPIGEON.init() -> Result<&2, &1, Pattern.Error(), CDLHOMINGPIGEON.State()>:
  Pattern.init(Patterns.CDLHOMINGPIGEON{}, Pattern.defaults(), 0.0)

def CDLHOMINGPIGEON.next(state: CDLHOMINGPIGEON.State(), bar: Bars.OHLC<F32>) -> CDLHOMINGPIGEON.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLHOMINGPIGEON.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLHOMINGPIGEON.init())

def CDLIDENTICAL3CROWS.State() -> Type:
  Pattern.State()

def CDLIDENTICAL3CROWS.init() -> Result<&2, &1, Pattern.Error(), CDLIDENTICAL3CROWS.State()>:
  Pattern.init(Patterns.CDLIDENTICAL3CROWS{}, Pattern.defaults(), 0.0)

def CDLIDENTICAL3CROWS.next(state: CDLIDENTICAL3CROWS.State(), bar: Bars.OHLC<F32>) -> CDLIDENTICAL3CROWS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLIDENTICAL3CROWS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLIDENTICAL3CROWS.init())

def CDLINNECK.State() -> Type:
  Pattern.State()

def CDLINNECK.init() -> Result<&2, &1, Pattern.Error(), CDLINNECK.State()>:
  Pattern.init(Patterns.CDLINNECK{}, Pattern.defaults(), 0.0)

def CDLINNECK.next(state: CDLINNECK.State(), bar: Bars.OHLC<F32>) -> CDLINNECK.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLINNECK.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLINNECK.init())

def CDLINVERTEDHAMMER.State() -> Type:
  Pattern.State()

def CDLINVERTEDHAMMER.init() -> Result<&2, &1, Pattern.Error(), CDLINVERTEDHAMMER.State()>:
  Pattern.init(Patterns.CDLINVERTEDHAMMER{}, Pattern.defaults(), 0.0)

def CDLINVERTEDHAMMER.next(state: CDLINVERTEDHAMMER.State(), bar: Bars.OHLC<F32>) -> CDLINVERTEDHAMMER.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLINVERTEDHAMMER.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLINVERTEDHAMMER.init())

def CDLKICKING.State() -> Type:
  Pattern.State()

def CDLKICKING.init() -> Result<&2, &1, Pattern.Error(), CDLKICKING.State()>:
  Pattern.init(Patterns.CDLKICKING{}, Pattern.defaults(), 0.0)

def CDLKICKING.next(state: CDLKICKING.State(), bar: Bars.OHLC<F32>) -> CDLKICKING.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLKICKING.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLKICKING.init())

def CDLKICKINGBYLENGTH.State() -> Type:
  Pattern.State()

def CDLKICKINGBYLENGTH.init() -> Result<&2, &1, Pattern.Error(), CDLKICKINGBYLENGTH.State()>:
  Pattern.init(Patterns.CDLKICKINGBYLENGTH{}, Pattern.defaults(), 0.0)

def CDLKICKINGBYLENGTH.next(state: CDLKICKINGBYLENGTH.State(), bar: Bars.OHLC<F32>) -> CDLKICKINGBYLENGTH.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLKICKINGBYLENGTH.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLKICKINGBYLENGTH.init())

def CDLLADDERBOTTOM.State() -> Type:
  Pattern.State()

def CDLLADDERBOTTOM.init() -> Result<&2, &1, Pattern.Error(), CDLLADDERBOTTOM.State()>:
  Pattern.init(Patterns.CDLLADDERBOTTOM{}, Pattern.defaults(), 0.0)

def CDLLADDERBOTTOM.next(state: CDLLADDERBOTTOM.State(), bar: Bars.OHLC<F32>) -> CDLLADDERBOTTOM.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLLADDERBOTTOM.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLLADDERBOTTOM.init())

def CDLLONGLEGGEDDOJI.State() -> Type:
  Pattern.State()

def CDLLONGLEGGEDDOJI.init() -> Result<&2, &1, Pattern.Error(), CDLLONGLEGGEDDOJI.State()>:
  Pattern.init(Patterns.CDLLONGLEGGEDDOJI{}, Pattern.defaults(), 0.0)

def CDLLONGLEGGEDDOJI.next(state: CDLLONGLEGGEDDOJI.State(), bar: Bars.OHLC<F32>) -> CDLLONGLEGGEDDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLLONGLEGGEDDOJI.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLLONGLEGGEDDOJI.init())

def CDLLONGLINE.State() -> Type:
  Pattern.State()

def CDLLONGLINE.init() -> Result<&2, &1, Pattern.Error(), CDLLONGLINE.State()>:
  Pattern.init(Patterns.CDLLONGLINE{}, Pattern.defaults(), 0.0)

def CDLLONGLINE.next(state: CDLLONGLINE.State(), bar: Bars.OHLC<F32>) -> CDLLONGLINE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLLONGLINE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLLONGLINE.init())

def CDLMARUBOZU.State() -> Type:
  Pattern.State()

def CDLMARUBOZU.init() -> Result<&2, &1, Pattern.Error(), CDLMARUBOZU.State()>:
  Pattern.init(Patterns.CDLMARUBOZU{}, Pattern.defaults(), 0.0)

def CDLMARUBOZU.next(state: CDLMARUBOZU.State(), bar: Bars.OHLC<F32>) -> CDLMARUBOZU.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLMARUBOZU.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLMARUBOZU.init())

def CDLMATCHINGLOW.State() -> Type:
  Pattern.State()

def CDLMATCHINGLOW.init() -> Result<&2, &1, Pattern.Error(), CDLMATCHINGLOW.State()>:
  Pattern.init(Patterns.CDLMATCHINGLOW{}, Pattern.defaults(), 0.0)

def CDLMATCHINGLOW.next(state: CDLMATCHINGLOW.State(), bar: Bars.OHLC<F32>) -> CDLMATCHINGLOW.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLMATCHINGLOW.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLMATCHINGLOW.init())

def CDLMATHOLD.State() -> Type:
  Pattern.State()

def CDLMATHOLD.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLMATHOLD.State()>:
  Pattern.init(Patterns.CDLMATHOLD{}, Pattern.defaults(), penetration)

def CDLMATHOLD.next(state: CDLMATHOLD.State(), bar: Bars.OHLC<F32>) -> CDLMATHOLD.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLMATHOLD.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLMATHOLD.init(penetration))

def CDLMORNINGDOJISTAR.State() -> Type:
  Pattern.State()

def CDLMORNINGDOJISTAR.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLMORNINGDOJISTAR.State()>:
  Pattern.init(Patterns.CDLMORNINGDOJISTAR{}, Pattern.defaults(), penetration)

def CDLMORNINGDOJISTAR.next(state: CDLMORNINGDOJISTAR.State(), bar: Bars.OHLC<F32>) -> CDLMORNINGDOJISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLMORNINGDOJISTAR.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLMORNINGDOJISTAR.init(penetration))

def CDLMORNINGSTAR.State() -> Type:
  Pattern.State()

def CDLMORNINGSTAR.init(penetration: F32) -> Result<&2, &1, Pattern.Error(), CDLMORNINGSTAR.State()>:
  Pattern.init(Patterns.CDLMORNINGSTAR{}, Pattern.defaults(), penetration)

def CDLMORNINGSTAR.next(state: CDLMORNINGSTAR.State(), bar: Bars.OHLC<F32>) -> CDLMORNINGSTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLMORNINGSTAR.batch(xs: List<&2, Bars.OHLC<F32>>, penetration: F32) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLMORNINGSTAR.init(penetration))

def CDLONNECK.State() -> Type:
  Pattern.State()

def CDLONNECK.init() -> Result<&2, &1, Pattern.Error(), CDLONNECK.State()>:
  Pattern.init(Patterns.CDLONNECK{}, Pattern.defaults(), 0.0)

def CDLONNECK.next(state: CDLONNECK.State(), bar: Bars.OHLC<F32>) -> CDLONNECK.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLONNECK.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLONNECK.init())

def CDLPIERCING.State() -> Type:
  Pattern.State()

def CDLPIERCING.init() -> Result<&2, &1, Pattern.Error(), CDLPIERCING.State()>:
  Pattern.init(Patterns.CDLPIERCING{}, Pattern.defaults(), 0.0)

def CDLPIERCING.next(state: CDLPIERCING.State(), bar: Bars.OHLC<F32>) -> CDLPIERCING.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLPIERCING.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLPIERCING.init())

def CDLRICKSHAWMAN.State() -> Type:
  Pattern.State()

def CDLRICKSHAWMAN.init() -> Result<&2, &1, Pattern.Error(), CDLRICKSHAWMAN.State()>:
  Pattern.init(Patterns.CDLRICKSHAWMAN{}, Pattern.defaults(), 0.0)

def CDLRICKSHAWMAN.next(state: CDLRICKSHAWMAN.State(), bar: Bars.OHLC<F32>) -> CDLRICKSHAWMAN.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLRICKSHAWMAN.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLRICKSHAWMAN.init())

def CDLRISEFALL3METHODS.State() -> Type:
  Pattern.State()

def CDLRISEFALL3METHODS.init() -> Result<&2, &1, Pattern.Error(), CDLRISEFALL3METHODS.State()>:
  Pattern.init(Patterns.CDLRISEFALL3METHODS{}, Pattern.defaults(), 0.0)

def CDLRISEFALL3METHODS.next(state: CDLRISEFALL3METHODS.State(), bar: Bars.OHLC<F32>) -> CDLRISEFALL3METHODS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLRISEFALL3METHODS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLRISEFALL3METHODS.init())

def CDLSEPARATINGLINES.State() -> Type:
  Pattern.State()

def CDLSEPARATINGLINES.init() -> Result<&2, &1, Pattern.Error(), CDLSEPARATINGLINES.State()>:
  Pattern.init(Patterns.CDLSEPARATINGLINES{}, Pattern.defaults(), 0.0)

def CDLSEPARATINGLINES.next(state: CDLSEPARATINGLINES.State(), bar: Bars.OHLC<F32>) -> CDLSEPARATINGLINES.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLSEPARATINGLINES.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLSEPARATINGLINES.init())

def CDLSHOOTINGSTAR.State() -> Type:
  Pattern.State()

def CDLSHOOTINGSTAR.init() -> Result<&2, &1, Pattern.Error(), CDLSHOOTINGSTAR.State()>:
  Pattern.init(Patterns.CDLSHOOTINGSTAR{}, Pattern.defaults(), 0.0)

def CDLSHOOTINGSTAR.next(state: CDLSHOOTINGSTAR.State(), bar: Bars.OHLC<F32>) -> CDLSHOOTINGSTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLSHOOTINGSTAR.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLSHOOTINGSTAR.init())

def CDLSHORTLINE.State() -> Type:
  Pattern.State()

def CDLSHORTLINE.init() -> Result<&2, &1, Pattern.Error(), CDLSHORTLINE.State()>:
  Pattern.init(Patterns.CDLSHORTLINE{}, Pattern.defaults(), 0.0)

def CDLSHORTLINE.next(state: CDLSHORTLINE.State(), bar: Bars.OHLC<F32>) -> CDLSHORTLINE.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLSHORTLINE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLSHORTLINE.init())

def CDLSPINNINGTOP.State() -> Type:
  Pattern.State()

def CDLSPINNINGTOP.init() -> Result<&2, &1, Pattern.Error(), CDLSPINNINGTOP.State()>:
  Pattern.init(Patterns.CDLSPINNINGTOP{}, Pattern.defaults(), 0.0)

def CDLSPINNINGTOP.next(state: CDLSPINNINGTOP.State(), bar: Bars.OHLC<F32>) -> CDLSPINNINGTOP.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLSPINNINGTOP.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLSPINNINGTOP.init())

def CDLSTALLEDPATTERN.State() -> Type:
  Pattern.State()

def CDLSTALLEDPATTERN.init() -> Result<&2, &1, Pattern.Error(), CDLSTALLEDPATTERN.State()>:
  Pattern.init(Patterns.CDLSTALLEDPATTERN{}, Pattern.defaults(), 0.0)

def CDLSTALLEDPATTERN.next(state: CDLSTALLEDPATTERN.State(), bar: Bars.OHLC<F32>) -> CDLSTALLEDPATTERN.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLSTALLEDPATTERN.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLSTALLEDPATTERN.init())

def CDLSTICKSANDWICH.State() -> Type:
  Pattern.State()

def CDLSTICKSANDWICH.init() -> Result<&2, &1, Pattern.Error(), CDLSTICKSANDWICH.State()>:
  Pattern.init(Patterns.CDLSTICKSANDWICH{}, Pattern.defaults(), 0.0)

def CDLSTICKSANDWICH.next(state: CDLSTICKSANDWICH.State(), bar: Bars.OHLC<F32>) -> CDLSTICKSANDWICH.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLSTICKSANDWICH.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLSTICKSANDWICH.init())

def CDLTAKURI.State() -> Type:
  Pattern.State()

def CDLTAKURI.init() -> Result<&2, &1, Pattern.Error(), CDLTAKURI.State()>:
  Pattern.init(Patterns.CDLTAKURI{}, Pattern.defaults(), 0.0)

def CDLTAKURI.next(state: CDLTAKURI.State(), bar: Bars.OHLC<F32>) -> CDLTAKURI.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLTAKURI.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLTAKURI.init())

def CDLTASUKIGAP.State() -> Type:
  Pattern.State()

def CDLTASUKIGAP.init() -> Result<&2, &1, Pattern.Error(), CDLTASUKIGAP.State()>:
  Pattern.init(Patterns.CDLTASUKIGAP{}, Pattern.defaults(), 0.0)

def CDLTASUKIGAP.next(state: CDLTASUKIGAP.State(), bar: Bars.OHLC<F32>) -> CDLTASUKIGAP.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLTASUKIGAP.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLTASUKIGAP.init())

def CDLTHRUSTING.State() -> Type:
  Pattern.State()

def CDLTHRUSTING.init() -> Result<&2, &1, Pattern.Error(), CDLTHRUSTING.State()>:
  Pattern.init(Patterns.CDLTHRUSTING{}, Pattern.defaults(), 0.0)

def CDLTHRUSTING.next(state: CDLTHRUSTING.State(), bar: Bars.OHLC<F32>) -> CDLTHRUSTING.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLTHRUSTING.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLTHRUSTING.init())

def CDLTRISTAR.State() -> Type:
  Pattern.State()

def CDLTRISTAR.init() -> Result<&2, &1, Pattern.Error(), CDLTRISTAR.State()>:
  Pattern.init(Patterns.CDLTRISTAR{}, Pattern.defaults(), 0.0)

def CDLTRISTAR.next(state: CDLTRISTAR.State(), bar: Bars.OHLC<F32>) -> CDLTRISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLTRISTAR.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLTRISTAR.init())

def CDLUNIQUE3RIVER.State() -> Type:
  Pattern.State()

def CDLUNIQUE3RIVER.init() -> Result<&2, &1, Pattern.Error(), CDLUNIQUE3RIVER.State()>:
  Pattern.init(Patterns.CDLUNIQUE3RIVER{}, Pattern.defaults(), 0.0)

def CDLUNIQUE3RIVER.next(state: CDLUNIQUE3RIVER.State(), bar: Bars.OHLC<F32>) -> CDLUNIQUE3RIVER.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLUNIQUE3RIVER.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLUNIQUE3RIVER.init())

def CDLUPSIDEGAP2CROWS.State() -> Type:
  Pattern.State()

def CDLUPSIDEGAP2CROWS.init() -> Result<&2, &1, Pattern.Error(), CDLUPSIDEGAP2CROWS.State()>:
  Pattern.init(Patterns.CDLUPSIDEGAP2CROWS{}, Pattern.defaults(), 0.0)

def CDLUPSIDEGAP2CROWS.next(state: CDLUPSIDEGAP2CROWS.State(), bar: Bars.OHLC<F32>) -> CDLUPSIDEGAP2CROWS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLUPSIDEGAP2CROWS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLUPSIDEGAP2CROWS.init())

def CDLXSIDEGAP3METHODS.State() -> Type:
  Pattern.State()

def CDLXSIDEGAP3METHODS.init() -> Result<&2, &1, Pattern.Error(), CDLXSIDEGAP3METHODS.State()>:
  Pattern.init(Patterns.CDLXSIDEGAP3METHODS{}, Pattern.defaults(), 0.0)

def CDLXSIDEGAP3METHODS.next(state: CDLXSIDEGAP3METHODS.State(), bar: Bars.OHLC<F32>) -> CDLXSIDEGAP3METHODS.State() & Maybe<&2, Pattern.Signal()>:
  Pattern.next(state, bar)

def CDLXSIDEGAP3METHODS.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.Error(), ~Pattern.next, xs, CDLXSIDEGAP3METHODS.init())


def Pattern.Name() -> Data:
  Patterns.Name

def Pattern.show(signal: Pattern.Signal()) -> String:
  Patterns.Signal.show(signal)

def Pattern.setting(settings: Pattern.Settings(), name: Candles.Name, replacement: Candles.Setting<F32>) -> Pattern.Settings():
  Patterns.setting(~F32, settings, name, replacement)

def Pattern.lookback(name: Patterns.Name, settings: Pattern.Settings()) -> U32:
  Patterns.lookback(~F32, settings, name)

def VIDYA.State() -> Type:
  Vidya.State<F32>

def vidya.init.checked(+period: U32, +cmo: U32, valid: Bool) -> Result<&2, &1, Params.Error, VIDYA.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Vidya.init(~F32, ~U32.to_f32, ~F32.div, period, cmo, volume.depth(cmo))}

def VIDYA.init(+period: U32, +cmo: U32) -> Result<&2, &1, Params.Error, VIDYA.State()>:
  vidya.init.checked(period, cmo, Bool.and(Params.periods([period, cmo]), U32.is_ge(cmo, 2)))

def VIDYA.next(state: VIDYA.State(), price: F32) -> VIDYA.State() & Maybe<&2, F32>:
  Vidya.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price)

def VIDYA.batch(xs: List<&2, F32>, period: U32, cmo: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~VIDYA.State(), ~Params.Error, ~VIDYA.next, xs, VIDYA.init(period, cmo))

def MAMA.Error() -> Data:
  Params.Error

def MAMA.State() -> Data:
  Mama.State<F32>

def MAMA.Value() -> Data:
  Mama.Value<F32>

def MAMA.init.checked(fast: F32, slow: F32, valid: Bool) -> Result<&2, &1, MAMA.Error(), MAMA.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Mama.init(~F32, ~U32.to_f32, ~F32.div, fast, slow)}

def MAMA.init(+fast: F32, +slow: F32) -> Result<&2, &1, MAMA.Error(), MAMA.State()>:
  MAMA.init.checked(fast, slow, Bool.and(Bool.and(is_finite(fast), is_finite(slow)),
    Bool.and(Bool.and(F32.is_ge(fast, 0.01), F32.is_le(fast, 0.99)), Bool.and(F32.is_ge(slow, 0.01), F32.is_le(slow, 0.99)))))

def MAMA.next(state: MAMA.State(), price: F32) -> MAMA.State() & Maybe<&2, MAMA.Value()>:
  Mama.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_le, ~F32.atan, state, price)

def MAMA.batch(xs: List<&2, F32>, fast: F32, slow: F32) -> Result<&2, &2, MAMA.Error(), List<&2, Maybe<&2, MAMA.Value()>>>:
  Series.initialized(~F32, ~MAMA.Value(), ~MAMA.State(), ~MAMA.Error(), ~MAMA.next, xs, MAMA.init(fast, slow))

def overlap.valid(+period: U32, minimum: U32) -> Bool:
  Bool.and(U32.is_ge(period, minimum), U32.is_le(period, 100000))

def overlap.init(~S: Type, valid: Bool, make: Unit -> S) -> Result<&2, &1, Params.Error, S>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{make(Unit{})}

def overlap.window(+period: U32) -> Window.State():
  Win.init(~F32, period, Ma.buffer_depth(period), 0.0)

def overlap.project(~S: Type, ~I: Data, ~O: Data, ~project: I -> O, result: S & Maybe<&2, I>) -> S & Maybe<&2, O>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{project(value)})

def MA.State() -> Type:
  Ma.State<F32>

def MA.init(period: U32, kind: U32) -> Result<&2, &1, Params.Error, MA.State()>:
  Ma.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, kind)

def MA.next(state: MA.State(), price: F32) -> MA.State() & Maybe<&2, F32>:
  Ma.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, price)

def MA.batch(xs: List<&2, F32>, period: U32, kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~MA.State(), ~Params.Error, ~MA.next, xs, MA.init(period, kind))

def WMA.State() -> Type:
  MA.State()

def WMA.init(period: U32) -> Result<&2, &1, Params.Error, WMA.State()>:
  MA.init(period, 2)

def WMA.next(state: WMA.State(), price: F32) -> WMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def WMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 2)

def DEMA.State() -> Type:
  MA.State()

def DEMA.init(period: U32) -> Result<&2, &1, Params.Error, DEMA.State()>:
  MA.init(period, 3)

def DEMA.next(state: DEMA.State(), price: F32) -> DEMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def DEMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 3)

def TEMA.State() -> Type:
  MA.State()

def TEMA.init(period: U32) -> Result<&2, &1, Params.Error, TEMA.State()>:
  MA.init(period, 4)

def TEMA.next(state: TEMA.State(), price: F32) -> TEMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def TEMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 4)

def TRIMA.State() -> Type:
  MA.State()

def TRIMA.init(period: U32) -> Result<&2, &1, Params.Error, TRIMA.State()>:
  MA.init(period, 5)

def TRIMA.next(state: TRIMA.State(), price: F32) -> TRIMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def TRIMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 5)

def KAMA.State() -> Type:
  MA.State()

def KAMA.init(period: U32) -> Result<&2, &1, Params.Error, KAMA.State()>:
  MA.init(period, 6)

def KAMA.next(state: KAMA.State(), price: F32) -> KAMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def KAMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 6)

def HMA.State() -> Type:
  MA.State()

def HMA.init(period: U32) -> Result<&2, &1, Params.Error, HMA.State()>:
  MA.init(period, 9)

def HMA.next(state: HMA.State(), price: F32) -> HMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def HMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 9)

def ZLEMA.State() -> Type:
  MA.State()

def ZLEMA.init(period: U32) -> Result<&2, &1, Params.Error, ZLEMA.State()>:
  MA.init(period, 12)

def ZLEMA.next(state: ZLEMA.State(), price: F32) -> ZLEMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def ZLEMA.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  MA.batch(xs, period, 12)

def T3.State() -> Type:
  MA.State()

def T3.init(+period: U32, +factor: F32) -> Result<&2, &1, Params.Error, T3.State()>:
  overlap.init(~T3.State(), Bool.and(overlap.valid(period, 1), Bool.and(is_finite(factor), Bool.and(F32.is_ge(factor, 0.0), F32.is_le(factor, 1.0)))), u => Ma.make(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Ma.buffer_depth(period), 8, factor))

def T3.next(state: T3.State(), price: F32) -> T3.State() & Maybe<&2, F32>:
  MA.next(state, price)

def T3.batch(xs: List<&2, F32>, period: U32, factor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~T3.State(), ~Params.Error, ~T3.next, xs, T3.init(period, factor))

def ALMA.State() -> Type:
  MA.State()

def ALMA.init(+period: U32, +sigma: F32, +offset: F32) -> Result<&2, &1, Params.Error, ALMA.State()>:
  overlap.init(~ALMA.State(), Bool.and(overlap.valid(period, 1), Bool.and(Bool.and(is_finite(sigma), Bool.and(F32.is_ge(sigma, 0.01), F32.is_le(sigma, 3.0e37))), Bool.and(is_finite(offset), Bool.and(F32.is_ge(offset, 0.0), F32.is_le(offset, 1.0))))), u => Ma.gaussian.make(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Ma.buffer_depth(period), sigma, offset))

def ALMA.next(state: ALMA.State(), price: F32) -> ALMA.State() & Maybe<&2, F32>:
  MA.next(state, price)

def ALMA.batch(xs: List<&2, F32>, period: U32, sigma: F32, offset: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~ALMA.State(), ~Params.Error, ~ALMA.next, xs, ALMA.init(period, sigma, offset))

def SUM.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~SUM.State(), ~Error(), ~SUM.next, xs, SUM.init(period))

def stats.LINEARREG(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: endpoint

def LINEARREG.State() -> Type:
  Window.State()

def LINEARREG.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG.State()>:
  overlap.init(~LINEARREG.State(), overlap.valid(period, 2), u => overlap.window(period))

def LINEARREG.next(state: LINEARREG.State(), price: F32) -> LINEARREG.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG, Statistics.regress.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price))

def LINEARREG.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG.State(), ~Params.Error, ~LINEARREG.next, xs, LINEARREG.init(period))

def stats.LINEARREG_SLOPE(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: slope

def LINEARREG_SLOPE.State() -> Type:
  Window.State()

def LINEARREG_SLOPE.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG_SLOPE.State()>:
  overlap.init(~LINEARREG_SLOPE.State(), overlap.valid(period, 2), u => overlap.window(period))

def LINEARREG_SLOPE.next(state: LINEARREG_SLOPE.State(), price: F32) -> LINEARREG_SLOPE.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG_SLOPE.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG_SLOPE, Statistics.regress.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price))

def LINEARREG_SLOPE.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG_SLOPE.State(), ~Params.Error, ~LINEARREG_SLOPE.next, xs, LINEARREG_SLOPE.init(period))

def stats.LINEARREG_INTERCEPT(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: intercept

def LINEARREG_INTERCEPT.State() -> Type:
  Window.State()

def LINEARREG_INTERCEPT.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG_INTERCEPT.State()>:
  overlap.init(~LINEARREG_INTERCEPT.State(), overlap.valid(period, 2), u => overlap.window(period))

def LINEARREG_INTERCEPT.next(state: LINEARREG_INTERCEPT.State(), price: F32) -> LINEARREG_INTERCEPT.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG_INTERCEPT.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG_INTERCEPT, Statistics.regress.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price))

def LINEARREG_INTERCEPT.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG_INTERCEPT.State(), ~Params.Error, ~LINEARREG_INTERCEPT.next, xs, LINEARREG_INTERCEPT.init(period))

def stats.LINEARREG_ANGLE(value: Statistics.Regression<F32>) -> F32:
  Statistics.angle(~F32, ~U32.to_f32, ~F32.mul, ~F32.div, ~F32.atan, value)

def LINEARREG_ANGLE.State() -> Type:
  Window.State()

def LINEARREG_ANGLE.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG_ANGLE.State()>:
  overlap.init(~LINEARREG_ANGLE.State(), overlap.valid(period, 2), u => overlap.window(period))

def LINEARREG_ANGLE.next(state: LINEARREG_ANGLE.State(), price: F32) -> LINEARREG_ANGLE.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG_ANGLE.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG_ANGLE, Statistics.regress.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price))

def LINEARREG_ANGLE.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG_ANGLE.State(), ~Params.Error, ~LINEARREG_ANGLE.next, xs, LINEARREG_ANGLE.init(period))

def stats.TSF(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: forecast

def TSF.State() -> Type:
  Window.State()

def TSF.init(+period: U32) -> Result<&2, &1, Params.Error, TSF.State()>:
  overlap.init(~TSF.State(), overlap.valid(period, 2), u => overlap.window(period))

def TSF.next(state: TSF.State(), price: F32) -> TSF.State() & Maybe<&2, F32>:
  overlap.project(~TSF.State(), ~Statistics.Regression<F32>, ~F32, ~stats.TSF, Statistics.regress.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, price))

def TSF.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~TSF.State(), ~Params.Error, ~TSF.next, xs, TSF.init(period))

def stats.MAX(value: Statistics.Extrema<F32>) -> F32:
  match value:
    case Statistics.Extrema{low, high, low_index, high_index}: high

def MAX.Value() -> Data:
  F32

def MAX.State() -> Type:
  Statistics.Extremes<F32>

def MAX.init(+period: U32) -> Result<&2, &1, Params.Error, MAX.State()>:
  overlap.init(~MAX.State(), overlap.valid(period, 2), u => Statistics.Extremes{overlap.window(period), 0})

def MAX.next(state: MAX.State(), price: F32) -> MAX.State() & Maybe<&2, MAX.Value()>:
  overlap.project(~MAX.State(), ~Statistics.Extrema<F32>, ~MAX.Value(), ~stats.MAX, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MAX.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MAX.Value()>>>:
  Series.initialized(~F32, ~MAX.Value(), ~MAX.State(), ~Params.Error, ~MAX.next, xs, MAX.init(period))

def stats.MIN(value: Statistics.Extrema<F32>) -> F32:
  match value:
    case Statistics.Extrema{low, high, low_index, high_index}: low

def MIN.Value() -> Data:
  F32

def MIN.State() -> Type:
  Statistics.Extremes<F32>

def MIN.init(+period: U32) -> Result<&2, &1, Params.Error, MIN.State()>:
  overlap.init(~MIN.State(), overlap.valid(period, 2), u => Statistics.Extremes{overlap.window(period), 0})

def MIN.next(state: MIN.State(), price: F32) -> MIN.State() & Maybe<&2, MIN.Value()>:
  overlap.project(~MIN.State(), ~Statistics.Extrema<F32>, ~MIN.Value(), ~stats.MIN, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MIN.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MIN.Value()>>>:
  Series.initialized(~F32, ~MIN.Value(), ~MIN.State(), ~Params.Error, ~MIN.next, xs, MIN.init(period))

def stats.MAXINDEX(value: Statistics.Extrema<F32>) -> U32:
  match value:
    case Statistics.Extrema{low, high, low_index, high_index}: high_index

def MAXINDEX.Value() -> Data:
  U32

def MAXINDEX.State() -> Type:
  Statistics.Extremes<F32>

def MAXINDEX.init(+period: U32) -> Result<&2, &1, Params.Error, MAXINDEX.State()>:
  overlap.init(~MAXINDEX.State(), overlap.valid(period, 2), u => Statistics.Extremes{overlap.window(period), 0})

def MAXINDEX.next(state: MAXINDEX.State(), price: F32) -> MAXINDEX.State() & Maybe<&2, MAXINDEX.Value()>:
  overlap.project(~MAXINDEX.State(), ~Statistics.Extrema<F32>, ~MAXINDEX.Value(), ~stats.MAXINDEX, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MAXINDEX.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MAXINDEX.Value()>>>:
  Series.initialized(~F32, ~MAXINDEX.Value(), ~MAXINDEX.State(), ~Params.Error, ~MAXINDEX.next, xs, MAXINDEX.init(period))

def stats.MININDEX(value: Statistics.Extrema<F32>) -> U32:
  match value:
    case Statistics.Extrema{low, high, low_index, high_index}: low_index

def MININDEX.Value() -> Data:
  U32

def MININDEX.State() -> Type:
  Statistics.Extremes<F32>

def MININDEX.init(+period: U32) -> Result<&2, &1, Params.Error, MININDEX.State()>:
  overlap.init(~MININDEX.State(), overlap.valid(period, 2), u => Statistics.Extremes{overlap.window(period), 0})

def MININDEX.next(state: MININDEX.State(), price: F32) -> MININDEX.State() & Maybe<&2, MININDEX.Value()>:
  overlap.project(~MININDEX.State(), ~Statistics.Extrema<F32>, ~MININDEX.Value(), ~stats.MININDEX, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MININDEX.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MININDEX.Value()>>>:
  Series.initialized(~F32, ~MININDEX.Value(), ~MININDEX.State(), ~Params.Error, ~MININDEX.next, xs, MININDEX.init(period))

def stats.MINMAX(value: Statistics.Extrema<F32>) -> Statistics.MinMax<F32>:
  match value:
    case Statistics.Extrema{low, high, low_index, high_index}: Statistics.MinMax{low, high}

def MINMAX.Value() -> Data:
  Statistics.MinMax<F32>

def MINMAX.State() -> Type:
  Statistics.Extremes<F32>

def MINMAX.init(+period: U32) -> Result<&2, &1, Params.Error, MINMAX.State()>:
  overlap.init(~MINMAX.State(), overlap.valid(period, 2), u => Statistics.Extremes{overlap.window(period), 0})

def MINMAX.next(state: MINMAX.State(), price: F32) -> MINMAX.State() & Maybe<&2, MINMAX.Value()>:
  overlap.project(~MINMAX.State(), ~Statistics.Extrema<F32>, ~MINMAX.Value(), ~stats.MINMAX, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MINMAX.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MINMAX.Value()>>>:
  Series.initialized(~F32, ~MINMAX.Value(), ~MINMAX.State(), ~Params.Error, ~MINMAX.next, xs, MINMAX.init(period))

def stats.MINMAXINDEX(value: Statistics.Extrema<F32>) -> Statistics.MinMaxIndex:
  match value:
    case Statistics.Extrema{low, high, low_index, high_index}: Statistics.MinMaxIndex{low_index, high_index}

def MINMAXINDEX.Value() -> Data:
  Statistics.MinMaxIndex

def MINMAXINDEX.State() -> Type:
  Statistics.Extremes<F32>

def MINMAXINDEX.init(+period: U32) -> Result<&2, &1, Params.Error, MINMAXINDEX.State()>:
  overlap.init(~MINMAXINDEX.State(), overlap.valid(period, 2), u => Statistics.Extremes{overlap.window(period), 0})

def MINMAXINDEX.next(state: MINMAXINDEX.State(), price: F32) -> MINMAXINDEX.State() & Maybe<&2, MINMAXINDEX.Value()>:
  overlap.project(~MINMAXINDEX.State(), ~Statistics.Extrema<F32>, ~MINMAXINDEX.Value(), ~stats.MINMAXINDEX, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MINMAXINDEX.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MINMAXINDEX.Value()>>>:
  Series.initialized(~F32, ~MINMAXINDEX.Value(), ~MINMAXINDEX.State(), ~Params.Error, ~MINMAXINDEX.next, xs, MINMAXINDEX.init(period))

def MEDIAN.State() -> Type:
  Window.State()

def MEDIAN.init(+period: U32) -> Result<&2, &1, Params.Error, MEDIAN.State()>:
  overlap.init(~MEDIAN.State(), Bool.and(overlap.valid(period, 2), U32.is_le(period, 10000)), u => overlap.window(period))

def MEDIAN.next(state: MEDIAN.State(), price: F32) -> MEDIAN.State() & Maybe<&2, F32>:
  Statistics.quantile.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_le, state, price, 50.0)

def MEDIAN.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~MEDIAN.State(), ~Params.Error, ~MEDIAN.next, xs, MEDIAN.init(period))

def PERCENTRANK.State() -> Type:
  Window.State()

def PERCENTRANK.init(+period: U32) -> Result<&2, &1, Params.Error, PERCENTRANK.State()>:
  overlap.init(~PERCENTRANK.State(), Bool.and(overlap.valid(period, 2), U32.is_le(period, 10000)), u => overlap.window(period))

def PERCENTRANK.next(state: PERCENTRANK.State(), price: F32) -> PERCENTRANK.State() & Maybe<&2, F32>:
  Statistics.rank.next(~F32, ~U32.to_f32, ~F32.mul, ~F32.div, ~F32.is_lt, state, price)

def PERCENTRANK.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PERCENTRANK.State(), ~Params.Error, ~PERCENTRANK.next, xs, PERCENTRANK.init(period))

def AVGDEV.State() -> Type:
  Window.State()

def AVGDEV.init(+period: U32) -> Result<&2, &1, Params.Error, AVGDEV.State()>:
  overlap.init(~AVGDEV.State(), Bool.and(overlap.valid(period, 2), U32.is_le(period, 100000)), u => overlap.window(period))

def AVGDEV.next(state: AVGDEV.State(), price: F32) -> AVGDEV.State() & Maybe<&2, F32>:
  Statistics.deviation.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, ~F32.abs, state, price)

def AVGDEV.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~AVGDEV.State(), ~Params.Error, ~AVGDEV.next, xs, AVGDEV.init(period))

def STDDEV.State() -> Type:
  Statistics.ParameterWindow<F32>

def STDDEV.init(+period: U32, +factor: F32) -> Result<&2, &1, Params.Error, STDDEV.State()>:
  overlap.init(~STDDEV.State(), Bool.and(overlap.valid(period, 2), Bool.and(is_finite(factor), F32.is_le(F32.abs(factor), 3.0e37))), u => Statistics.ParameterWindow{overlap.window(period), factor})

def STDDEV.next(state: STDDEV.State(), price: F32) -> STDDEV.State() & Maybe<&2, F32>:
  Statistics.standard.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, state, price)

def STDDEV.batch(xs: List<&2, F32>, period: U32, factor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~STDDEV.State(), ~Params.Error, ~STDDEV.next, xs, STDDEV.init(period, factor))

def PERCENTILE.State() -> Type:
  Statistics.ParameterWindow<F32>

def PERCENTILE.init(+period: U32, +percent: F32) -> Result<&2, &1, Params.Error, PERCENTILE.State()>:
  overlap.init(~PERCENTILE.State(), Bool.and(overlap.valid(period, 2), Bool.and(U32.is_le(period, 10000), Bool.and(is_finite(percent), Bool.and(F32.is_ge(percent, 0.0), F32.is_le(percent, 100.0))))), u => Statistics.ParameterWindow{overlap.window(period), percent})

def PERCENTILE.next(state: PERCENTILE.State(), price: F32) -> PERCENTILE.State() & Maybe<&2, F32>:
  Statistics.percentile.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_le, state, price)

def PERCENTILE.batch(xs: List<&2, F32>, period: U32, percent: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PERCENTILE.State(), ~Params.Error, ~PERCENTILE.next, xs, PERCENTILE.init(period, percent))

def stats.midpoint(value: Extrema.Value()) -> F32:
  Overlap.midpoint(~F32, ~U32.to_f32, ~F32.add, ~F32.div, value)

def MIDPOINT.State() -> Type:
  Window.State()

def MIDPOINT.init(+period: U32) -> Result<&2, &1, Params.Error, MIDPOINT.State()>:
  overlap.init(~MIDPOINT.State(), overlap.valid(period, 2), u => overlap.window(period))

def MIDPOINT.next(state: MIDPOINT.State(), price: F32) -> MIDPOINT.State() & Maybe<&2, F32>:
  overlap.project(~MIDPOINT.State(), ~Extrema.Value(), ~F32, ~stats.midpoint, Extrema.next(state, price))

def MIDPOINT.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~MIDPOINT.State(), ~Params.Error, ~MIDPOINT.next, xs, MIDPOINT.init(period))

def overlap.hlwindow(+period: U32) -> Win.State<Bars.HL<F32>>:
  Win.init(~Bars.HL<F32>, period, Ma.buffer_depth(period), Bars.HL{0.0, 0.0})

def DONCHIAN.Value() -> Data:
  Overlap.Bands<F32>

def DONCHIAN.State() -> Type:
  Win.State<Bars.HL<F32>>

def DONCHIAN.init(+period: U32) -> Result<&2, &1, Params.Error, DONCHIAN.State()>:
  overlap.init(~DONCHIAN.State(), overlap.valid(period, 2), u => overlap.hlwindow(period))

def DONCHIAN.next(state: DONCHIAN.State(), bar: Bars.HL<F32>) -> DONCHIAN.State() & Maybe<&2, DONCHIAN.Value()>:
  Overlap.channel.next(~F32, ~U32.to_f32, ~F32.add, ~F32.div, ~F32.min, ~F32.max, state, bar)

def DONCHIAN.batch(xs: List<&2, Bars.HL<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, DONCHIAN.Value()>>>:
  Series.initialized(~Bars.HL<F32>, ~DONCHIAN.Value(), ~DONCHIAN.State(), ~Params.Error, ~DONCHIAN.next, xs, DONCHIAN.init(period))

def overlap.middle(value: Overlap.Bands<F32>) -> F32:
  match value:
    case Overlap.Bands{upper, middle, lower}: middle

def MIDPRICE.State() -> Type:
  DONCHIAN.State()

def MIDPRICE.init(period: U32) -> Result<&2, &1, Params.Error, MIDPRICE.State()>:
  DONCHIAN.init(period)

def MIDPRICE.next(state: MIDPRICE.State(), bar: Bars.HL<F32>) -> MIDPRICE.State() & Maybe<&2, F32>:
  overlap.project(~MIDPRICE.State(), ~DONCHIAN.Value(), ~F32, ~overlap.middle, DONCHIAN.next(state, bar))

def MIDPRICE.batch(xs: List<&2, Bars.HL<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~MIDPRICE.State(), ~Params.Error, ~MIDPRICE.next, xs, MIDPRICE.init(period))

def BBANDS.Value() -> Data:
  Overlap.Bands<F32>

def BBANDS.State() -> Type:
  Overlap.Bollinger<F32>

def BBANDS.init.checked(+period: U32, up: F32, down: F32, +kind: U32, valid: Bool) -> Result<&2, &1, Params.Error, BBANDS.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Overlap.bollinger.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Ma.buffer_depth(period), up, down, kind)

def BBANDS.init(+period: U32, +up: F32, +down: F32, kind: U32) -> Result<&2, &1, Params.Error, BBANDS.State()>:
  BBANDS.init.checked(period, up, down, kind, Bool.and(overlap.valid(period, 2), Bool.and(Bool.and(is_finite(up), F32.is_le(F32.abs(up), 3.0e37)), Bool.and(is_finite(down), F32.is_le(F32.abs(down), 3.0e37)))))

def overlap.bands(value: Overlap.BollingerValue<F32>) -> BBANDS.Value():
  match value:
    case Overlap.BollingerValue{bands, width, percent}: bands

def overlap.bandwidth(value: Overlap.BollingerValue<F32>) -> F32:
  match value:
    case Overlap.BollingerValue{bands, width, percent}: width

def overlap.percentb(value: Overlap.BollingerValue<F32>) -> F32:
  match value:
    case Overlap.BollingerValue{bands, width, percent}: percent

def overlap.bollinger.next(state: BBANDS.State(), price: F32) -> BBANDS.State() & Maybe<&2, Overlap.BollingerValue<F32>>:
  Overlap.bollinger.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sqrt, state, price)

def BBANDS.next(state: BBANDS.State(), price: F32) -> BBANDS.State() & Maybe<&2, BBANDS.Value()>:
  overlap.project(~BBANDS.State(), ~Overlap.BollingerValue<F32>, ~BBANDS.Value(), ~overlap.bands, overlap.bollinger.next(state, price))

def BBANDS.batch(xs: List<&2, F32>, period: U32, up: F32, down: F32, kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, BBANDS.Value()>>>:
  Series.initialized(~F32, ~BBANDS.Value(), ~BBANDS.State(), ~Params.Error, ~BBANDS.next, xs, BBANDS.init(period, up, down, kind))

def BBW.State() -> Type:
  BBANDS.State()

def BBW.init(period: U32, up: F32, down: F32, kind: U32) -> Result<&2, &1, Params.Error, BBW.State()>:
  BBANDS.init(period, up, down, kind)

def BBW.next(state: BBW.State(), price: F32) -> BBW.State() & Maybe<&2, F32>:
  overlap.project(~BBW.State(), ~Overlap.BollingerValue<F32>, ~F32, ~overlap.bandwidth, overlap.bollinger.next(state, price))

def BBW.batch(xs: List<&2, F32>, period: U32, up: F32, down: F32, kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~BBW.State(), ~Params.Error, ~BBW.next, xs, BBW.init(period, up, down, kind))

def PERCENTB.State() -> Type:
  BBANDS.State()

def PERCENTB.init(period: U32, up: F32, down: F32, kind: U32) -> Result<&2, &1, Params.Error, PERCENTB.State()>:
  BBANDS.init(period, up, down, kind)

def PERCENTB.next(state: PERCENTB.State(), price: F32) -> PERCENTB.State() & Maybe<&2, F32>:
  overlap.project(~PERCENTB.State(), ~Overlap.BollingerValue<F32>, ~F32, ~overlap.percentb, overlap.bollinger.next(state, price))

def PERCENTB.batch(xs: List<&2, F32>, period: U32, up: F32, down: F32, kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PERCENTB.State(), ~Params.Error, ~PERCENTB.next, xs, PERCENTB.init(period, up, down, kind))

def ACCBANDS.Value() -> Data:
  Overlap.Bands<F32>

def ACCBANDS.State() -> Type:
  Overlap.Acceleration<F32>

def ACCBANDS.init(+period: U32) -> Result<&2, &1, Params.Error, ACCBANDS.State()>:
  overlap.init(~ACCBANDS.State(), overlap.valid(period, 2), u => Overlap.accbands.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)))

def ACCBANDS.next(state: ACCBANDS.State(), bar: Bars.HLC<F32>) -> ACCBANDS.State() & Maybe<&2, ACCBANDS.Value()>:
  Overlap.acceleration.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, state, bar)

def ACCBANDS.batch(xs: List<&2, Bars.HLC<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, ACCBANDS.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~ACCBANDS.Value(), ~ACCBANDS.State(), ~Params.Error, ~ACCBANDS.next, xs, ACCBANDS.init(period))

def VWMA.State() -> Type:
  Win.State<Bars.CV<F32>>

def VWMA.init(+period: U32) -> Result<&2, &1, Params.Error, VWMA.State()>:
  overlap.init(~VWMA.State(), overlap.valid(period, 1), u => Win.init(~Bars.CV<F32>, period, Ma.buffer_depth(period), Bars.CV{0.0, 0.0}))

def VWMA.next(state: VWMA.State(), bar: Bars.CV<F32>) -> VWMA.State() & Maybe<&2, F32>:
  Overlap.volume.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, bar)

def VWMA.batch(xs: List<&2, Bars.CV<F32>>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.CV<F32>, ~F32, ~VWMA.State(), ~Params.Error, ~VWMA.next, xs, VWMA.init(period))

def HA.Value() -> Data:
  Bars.OHLC<F32>

def HA.State() -> Data:
  Overlap.Heikin<F32>

def HA.init() -> HA.State():
  Overlap.First{}

def HA.next(state: HA.State(), bar: HA.Value()) -> HA.State() & Maybe<&2, HA.Value()>:
  Overlap.heikin.next(~F32, ~U32.to_f32, ~F32.add, ~F32.div, ~F32.min, ~F32.max, state, bar)

def HA.batch(xs: List<&2, HA.Value()>) -> List<&2, Maybe<&2, HA.Value()>>:
  Series.batch(~HA.Value(), ~HA.Value(), ~HA.State(), ~HA.next, xs, HA.init())

def KC.Value() -> Data:
  Overlap.Bands<F32>

def KC.State() -> Data:
  Overlap.Keltner<F32>

def KC.init(+period: U32, +atr_period: U32, +deviation: F32) -> Result<&2, &1, Params.Error, KC.State()>:
  overlap.init(~KC.State(), Bool.and(Bool.and(overlap.valid(period, 2), overlap.valid(atr_period, 1)), Bool.and(is_finite(deviation), F32.is_le(F32.abs(deviation), 3.0e37))), u => Overlap.keltner.init(~F32, ~U32.to_f32, ~F32.div, period, atr_period, deviation))

def KC.next(state: KC.State(), bar: Bars.HLC<F32>) -> KC.State() & Maybe<&2, KC.Value()>:
  Overlap.keltner.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, state, bar)

def KC.batch(xs: List<&2, Bars.HLC<F32>>, period: U32, atr_period: U32, deviation: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, KC.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~KC.Value(), ~KC.State(), ~Params.Error, ~KC.next, xs, KC.init(period, atr_period, deviation))

def CKSP.Value() -> Data:
  Overlap.Stops<F32>

def CKSP.State() -> Type:
  Overlap.ChandeKroll<F32>

def CKSP.init(+period: U32, +multiplier: F32, +stop_period: U32) -> Result<&2, &1, Params.Error, CKSP.State()>:
  overlap.init(~CKSP.State(), Bool.and(Bool.and(overlap.valid(period, 2), overlap.valid(stop_period, 1)), Bool.and(is_finite(multiplier), Bool.and(F32.is_ge(multiplier, 0.0), F32.is_le(multiplier, 3.0e37)))), u => Overlap.chande.init(~F32, ~U32.to_f32, ~F32.div, period, Ma.buffer_depth(period), multiplier, stop_period, Ma.buffer_depth(stop_period)))

def CKSP.next(state: CKSP.State(), bar: Bars.HLC<F32>) -> CKSP.State() & Maybe<&2, CKSP.Value()>:
  Overlap.chande.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, state, bar)

def CKSP.batch(xs: List<&2, Bars.HLC<F32>>, period: U32, multiplier: F32, stop_period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, CKSP.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~CKSP.Value(), ~CKSP.State(), ~Params.Error, ~CKSP.next, xs, CKSP.init(period, multiplier, stop_period))

def Momentum.Error() -> Data:
  Params.Error

def Momentum.configure(~S: Type, valid: Bool, create: Unit -> Result<&2, &1, Momentum.Error(), S>) -> Result<&2, &1, Momentum.Error(), S>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: create(Unit{})

def Momentum.period(+period: U32, +minimum: U32) -> Bool:
  Bool.and(U32.is_ge(period, minimum), U32.is_le(period, 100000))

def RSI.State() -> Type:
  MomCore.RSI<F32>

def RSI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), RSI.State()>:
  Momentum.configure(~RSI.State(), Momentum.period(period, 2), u => Done{MomCore.rsi.init(~F32, ~U32.to_f32, period)})

def RSI.next(state: RSI.State(), value: F32) -> RSI.State() & Maybe<&2, F32>:
  MomCore.rsi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.max, ~F32.is_gt, state, value, False{})

def RSI.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~RSI.State(), ~Momentum.Error(), ~RSI.next, xs, RSI.init(period))

def CMO.State() -> Type:
  MomCore.RSI<F32>

def CMO.init(+period: U32) -> Result<&2, &1, Momentum.Error(), CMO.State()>:
  Momentum.configure(~CMO.State(), Momentum.period(period, 2), u => Done{MomCore.rsi.init(~F32, ~U32.to_f32, period)})

def CMO.next(state: CMO.State(), value: F32) -> CMO.State() & Maybe<&2, F32>:
  MomCore.rsi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.max, ~F32.is_gt, state, value, True{})

def CMO.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~CMO.State(), ~Momentum.Error(), ~CMO.next, xs, CMO.init(period))

def CMOU.State() -> Type:
  MomCore.Flow<F32>

def CMOU.init(+period: U32) -> Result<&2, &1, Momentum.Error(), CMOU.State()>:
  Momentum.configure(~CMOU.State(), Momentum.period(period, 2), u => Done{MomentumInit.flow(~F32, ~U32.to_f32, period)})

def CMOU.next(state: CMOU.State(), value: F32) -> CMOU.State() & Maybe<&2, F32>:
  MomCore.flow.ratio(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_gt, MomCore.cmou.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.max, state, value), True{})

def CMOU.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~CMOU.State(), ~Momentum.Error(), ~CMOU.next, xs, CMOU.init(period))

def IMI.State() -> Type:
  MomCore.Flow<F32>

def IMI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), IMI.State()>:
  Momentum.configure(~IMI.State(), Momentum.period(period, 2), u => Done{MomentumInit.flow(~F32, ~U32.to_f32, period)})

def IMI.next(state: IMI.State(), value: Bars.OHLC<F32>) -> IMI.State() & Maybe<&2, F32>:
  MomCore.flow.ratio(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_gt, MomCore.imi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.max, state, value), False{})

def IMI.batch(xs: List<&2, Bars.OHLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~IMI.State(), ~Momentum.Error(), ~IMI.next, xs, IMI.init(period))

def PLUS_DM.State() -> Type:
  Directional.State<F32>

def PLUS_DM.init(+period: U32) -> Result<&2, &1, Momentum.Error(), PLUS_DM.State()>:
  Momentum.configure(~PLUS_DM.State(), Momentum.period(period, 1), u => Done{Directional.init(~F32, ~U32.to_f32, period)})

def PLUS_DM.next(state: PLUS_DM.State(), value: Bars.HL<F32>) -> PLUS_DM.State() & Maybe<&2, F32>:
  match state value:
    case Directional.State{+period, seen, previous, plus, minus, range, dx} Bars.HL{high, low}:
      Directional.select(~F32, period, 0, Directional.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, Directional.State{period, seen, previous, plus, minus, range, dx}, Bars.HLC{high, low, 0.0}))

def PLUS_DM.batch(xs: List<&2, Bars.HL<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~PLUS_DM.State(), ~Momentum.Error(), ~PLUS_DM.next, xs, PLUS_DM.init(period))

def MINUS_DM.State() -> Type:
  Directional.State<F32>

def MINUS_DM.init(+period: U32) -> Result<&2, &1, Momentum.Error(), MINUS_DM.State()>:
  Momentum.configure(~MINUS_DM.State(), Momentum.period(period, 1), u => Done{Directional.init(~F32, ~U32.to_f32, period)})

def MINUS_DM.next(state: MINUS_DM.State(), value: Bars.HL<F32>) -> MINUS_DM.State() & Maybe<&2, F32>:
  match state value:
    case Directional.State{+period, seen, previous, plus, minus, range, dx} Bars.HL{high, low}:
      Directional.select(~F32, period, 1, Directional.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, Directional.State{period, seen, previous, plus, minus, range, dx}, Bars.HLC{high, low, 0.0}))

def MINUS_DM.batch(xs: List<&2, Bars.HL<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~MINUS_DM.State(), ~Momentum.Error(), ~MINUS_DM.next, xs, MINUS_DM.init(period))

def PLUS_DI.State() -> Type:
  Directional.State<F32>

def PLUS_DI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), PLUS_DI.State()>:
  Momentum.configure(~PLUS_DI.State(), Momentum.period(period, 1), u => Done{Directional.init(~F32, ~U32.to_f32, period)})

def PLUS_DI.next(state: PLUS_DI.State(), value: Bars.HLC<F32>) -> PLUS_DI.State() & Maybe<&2, F32>:
  match state:
    case Directional.State{+period, seen, previous, plus, minus, range, dx}:
      Directional.select(~F32, period, 2, Directional.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, Directional.State{period, seen, previous, plus, minus, range, dx}, value))

def PLUS_DI.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~PLUS_DI.State(), ~Momentum.Error(), ~PLUS_DI.next, xs, PLUS_DI.init(period))

def MINUS_DI.State() -> Type:
  Directional.State<F32>

def MINUS_DI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), MINUS_DI.State()>:
  Momentum.configure(~MINUS_DI.State(), Momentum.period(period, 1), u => Done{Directional.init(~F32, ~U32.to_f32, period)})

def MINUS_DI.next(state: MINUS_DI.State(), value: Bars.HLC<F32>) -> MINUS_DI.State() & Maybe<&2, F32>:
  match state:
    case Directional.State{+period, seen, previous, plus, minus, range, dx}:
      Directional.select(~F32, period, 3, Directional.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, Directional.State{period, seen, previous, plus, minus, range, dx}, value))

def MINUS_DI.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~MINUS_DI.State(), ~Momentum.Error(), ~MINUS_DI.next, xs, MINUS_DI.init(period))

def DX.State() -> Type:
  Directional.State<F32>

def DX.init(+period: U32) -> Result<&2, &1, Momentum.Error(), DX.State()>:
  Momentum.configure(~DX.State(), Momentum.period(period, 2), u => Done{Directional.init(~F32, ~U32.to_f32, period)})

def DX.next(state: DX.State(), value: Bars.HLC<F32>) -> DX.State() & Maybe<&2, F32>:
  match state:
    case Directional.State{+period, seen, previous, plus, minus, range, dx}:
      Directional.select(~F32, period, 4, Directional.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, Directional.State{period, seen, previous, plus, minus, range, dx}, value))

def DX.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~DX.State(), ~Momentum.Error(), ~DX.next, xs, DX.init(period))

def ADX.State() -> Type:
  Directional.ADX<F32>

def ADX.init(+period: U32) -> Result<&2, &1, Momentum.Error(), ADX.State()>:
  Momentum.configure(~ADX.State(), Momentum.period(period, 2), u => Done{Directional.adx.init(~F32, ~U32.to_f32, period)})

def ADX.next(state: ADX.State(), value: Bars.HLC<F32>) -> ADX.State() & Maybe<&2, F32>:
  Directional.adx.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, state, value)

def ADX.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~ADX.State(), ~Momentum.Error(), ~ADX.next, xs, ADX.init(period))

def ADXR.State() -> Type:
  Directional.ADXR<F32>

def ADXR.init(+period: U32) -> Result<&2, &1, Momentum.Error(), ADXR.State()>:
  Momentum.configure(~ADXR.State(), Momentum.period(period, 2), u => Done{MomentumInit.adxr(~F32, ~U32.to_f32, period)})

def ADXR.next(state: ADXR.State(), value: Bars.HLC<F32>) -> ADXR.State() & Maybe<&2, F32>:
  Directional.adxr.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_gt, state, value)

def ADXR.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~ADXR.State(), ~Momentum.Error(), ~ADXR.next, xs, ADXR.init(period))

def SI.State() -> Type:
  MomentumWindow.Swing<F32>

def SI.init(+limit: F32) -> Result<&2, &1, Momentum.Error(), SI.State()>:
  Momentum.configure(~SI.State(), Bool.and(is_finite(limit), Bool.and(F32.is_ge(limit, 0.00000001), F32.is_le(limit, 30000000000000000000000000000000000000.0))), u => Done{MomentumWindow.swing.init(~F32, ~U32.to_f32, limit)})

def SI.next(state: SI.State(), value: Bars.OHLC<F32>) -> SI.State() & Maybe<&2, F32>:
  MomentumWindow.swing.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_eq, state, value, False{})

def SI.batch(xs: List<&2, Bars.OHLC<F32>>, +limit: F32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~SI.State(), ~Momentum.Error(), ~SI.next, xs, SI.init(limit))

def ASI.State() -> Type:
  MomentumWindow.Swing<F32>

def ASI.init(+limit: F32) -> Result<&2, &1, Momentum.Error(), ASI.State()>:
  Momentum.configure(~ASI.State(), Bool.and(is_finite(limit), Bool.and(F32.is_ge(limit, 0.00000001), F32.is_le(limit, 30000000000000000000000000000000000000.0))), u => Done{MomentumWindow.swing.init(~F32, ~U32.to_f32, limit)})

def ASI.next(state: ASI.State(), value: Bars.OHLC<F32>) -> ASI.State() & Maybe<&2, F32>:
  MomentumWindow.swing.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_eq, state, value, True{})

def ASI.batch(xs: List<&2, Bars.OHLC<F32>>, +limit: F32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~ASI.State(), ~Momentum.Error(), ~ASI.next, xs, ASI.init(limit))

def WAD.State() -> Type:
  MomentumWindow.WAD<F32>

def WAD.init() -> Result<&2, &1, Momentum.Error(), WAD.State()>:
  Momentum.configure(~WAD.State(), True{}, u => Done{MomentumWindow.WAD{None{}, 0.0}})

def WAD.next(state: WAD.State(), value: Bars.HLC<F32>) -> WAD.State() & Maybe<&2, F32>:
  MomentumWindow.wad.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.min, ~F32.max, ~F32.is_gt, state, value)

def WAD.batch(xs: List<&2, Bars.HLC<F32>>) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~WAD.State(), ~Momentum.Error(), ~WAD.next, xs, WAD.init())

def Momentum.willr.result(result: MomentumWindow.Box<F32> & Maybe<&2, MomentumWindow.Bounds<F32>>) -> MomentumWindow.Box<F32> & Maybe<&2, F32>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{bounds}): (state, Some{MomentumWindow.willr(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.min, ~F32.max, bounds)})

def AROON.Value() -> Data:
  MomentumWindow.Aroon<F32>

def Momentum.aroon.result(result: MomentumWindow.Box<F32> & Maybe<&2, MomentumWindow.Bounds<F32>>) -> MomentumWindow.Box<F32> & Maybe<&2, AROON.Value()>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{MomentumWindow.aroon(~F32, ~U32.to_f32, ~F32.mul, ~F32.div, value)})

def Momentum.aroonosc.result(result: MomentumWindow.Box<F32> & Maybe<&2, MomentumWindow.Bounds<F32>>) -> MomentumWindow.Box<F32> & Maybe<&2, F32>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{bounds}): (state, Some{MomentumWindow.aroonosc(~F32, ~U32.to_f32, ~F32.sub, ~F32.mul, ~F32.div, bounds)})

def WILLR.State() -> Type:
  MomentumWindow.Box<F32>

def WILLR.init(+period: U32) -> Result<&2, &1, Momentum.Error(), WILLR.State()>:
  Momentum.configure(~WILLR.State(), Momentum.period(period, 2), u => Done{MomentumInit.box(~F32, ~U32.to_f32, period)})

def WILLR.next(state: WILLR.State(), value: Bars.HLC<F32>) -> WILLR.State() & Maybe<&2, F32>:
  Momentum.willr.result(MomentumWindow.box.next(~F32, ~F32.is_ge, ~F32.is_le, state, value))

def WILLR.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~WILLR.State(), ~Momentum.Error(), ~WILLR.next, xs, WILLR.init(period))

def AROON.State() -> Type:
  MomentumWindow.Box<F32>

def AROON.init(+period: U32) -> Result<&2, &1, Momentum.Error(), AROON.State()>:
  Momentum.configure(~AROON.State(), Momentum.period(period, 2), u => Done{MomentumInit.aroon(~F32, ~U32.to_f32, period)})

def AROON.next(state: AROON.State(), value: Bars.HL<F32>) -> AROON.State() & Maybe<&2, AROON.Value()>:
  match value:
    case Bars.HL{high, low}:
      Momentum.aroon.result(MomentumWindow.box.next(~F32, ~F32.is_ge, ~F32.is_le, state, Bars.HLC{high, low, 0.0}))

def AROON.batch(xs: List<&2, Bars.HL<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, AROON.Value()>>>:
  Series.initialized(~Bars.HL<F32>, ~AROON.Value(), ~AROON.State(), ~Momentum.Error(), ~AROON.next, xs, AROON.init(period))

def AROONOSC.State() -> Type:
  MomentumWindow.Box<F32>

def AROONOSC.init(+period: U32) -> Result<&2, &1, Momentum.Error(), AROONOSC.State()>:
  Momentum.configure(~AROONOSC.State(), Momentum.period(period, 2), u => Done{MomentumInit.aroon(~F32, ~U32.to_f32, period)})

def AROONOSC.next(state: AROONOSC.State(), value: Bars.HL<F32>) -> AROONOSC.State() & Maybe<&2, F32>:
  match value:
    case Bars.HL{high, low}:
      Momentum.aroonosc.result(MomentumWindow.box.next(~F32, ~F32.is_ge, ~F32.is_le, state, Bars.HLC{high, low, 0.0}))

def AROONOSC.batch(xs: List<&2, Bars.HL<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~AROONOSC.State(), ~Momentum.Error(), ~AROONOSC.next, xs, AROONOSC.init(period))

def Momentum.er.result(result: MomentumWindow.Prices<F32> & Maybe<&2, MomentumWindow.Scan<F32>>) -> MomentumWindow.Prices<F32> & Maybe<&2, F32>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{MomentumWindow.er(~F32, ~U32.to_f32, ~F32.sub, ~F32.div, ~F32.abs, ~F32.min, ~F32.is_gt, value)})

def ER.State() -> Type:
  MomentumWindow.Prices<F32>

def ER.init(+period: U32) -> Result<&2, &1, Momentum.Error(), ER.State()>:
  Momentum.configure(~ER.State(), Momentum.period(period, 2), u => Done{MomentumInit.changed(~F32, ~U32.to_f32, period)})

def ER.next(state: ER.State(), value: F32) -> ER.State() & Maybe<&2, F32>:
  Momentum.er.result(MomentumWindow.prices.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.abs, ~F32.min, ~F32.max, state, value))

def ER.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~ER.State(), ~Momentum.Error(), ~ER.next, xs, ER.init(period))

def Momentum.vhf.result(result: MomentumWindow.Prices<F32> & Maybe<&2, MomentumWindow.Scan<F32>>) -> MomentumWindow.Prices<F32> & Maybe<&2, F32>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{MomentumWindow.vhf(~F32, ~U32.to_f32, ~F32.sub, ~F32.div, ~F32.is_gt, value)})

def VHF.State() -> Type:
  MomentumWindow.Prices<F32>

def VHF.init(+period: U32) -> Result<&2, &1, Momentum.Error(), VHF.State()>:
  Momentum.configure(~VHF.State(), Momentum.period(period, 2), u => Done{MomentumInit.changed(~F32, ~U32.to_f32, period)})

def VHF.next(state: VHF.State(), value: F32) -> VHF.State() & Maybe<&2, F32>:
  Momentum.vhf.result(MomentumWindow.prices.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.abs, ~F32.min, ~F32.max, state, value))

def VHF.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~VHF.State(), ~Momentum.Error(), ~VHF.next, xs, VHF.init(period))

def Momentum.ppo_zero(value: F32) -> Bool:
  F32.is_le(F32.abs(value), 0.00000000000001)

def Momentum.ma(period: U32, kind: U32) -> Result<&2, &1, Momentum.Error(), Ma.State<F32>>:
  Ma.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, kind)

def Momentum.selector(+period: U32, +kind: U32) -> Bool:
  Bool.and(U32.is_le(kind, 15), Bool.or(U32.is_eq(period, 1), Ma.supported(kind)))

def MACD.Value() -> Data:
  MomentumSmooth.MACDValue<F32>

def STOCH.Value() -> Data:
  MomentumSmooth.StochValue<F32>

def ERI.Value() -> Data:
  MomentumSmooth.Lines<F32>

def KST.Value() -> Data:
  MomentumSmooth.Lines<F32>

def VORTEX.Value() -> Data:
  MomentumMarket.Vortex<F32>

def APO.State() -> Type:
  MomentumSmooth.Dual<F32>

def APO.init(+fast: U32, +slow: U32, +kind: U32) -> Result<&2, &1, Momentum.Error(), APO.State()>:
  Momentum.configure(~APO.State(), Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Ma.supported(kind)), u => MomentumInit.apo(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, kind))

def APO.next(state: APO.State(), value: F32) -> APO.State() & Maybe<&2, F32>:
  MomentumSmooth.dual.difference(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~Momentum.ppo_zero, MomentumSmooth.dual.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value), False{})

def APO.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +kind: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~APO.State(), ~Momentum.Error(), ~APO.next, xs, APO.init(fast, slow, kind))

def PPO.State() -> Type:
  MomentumSmooth.Dual<F32>

def PPO.init(+fast: U32, +slow: U32, +kind: U32) -> Result<&2, &1, Momentum.Error(), PPO.State()>:
  Momentum.configure(~PPO.State(), Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Ma.supported(kind)), u => MomentumInit.apo(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, kind))

def PPO.next(state: PPO.State(), value: F32) -> PPO.State() & Maybe<&2, F32>:
  MomentumSmooth.dual.difference(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~Momentum.ppo_zero, MomentumSmooth.dual.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value), True{})

def PPO.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +kind: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PPO.State(), ~Momentum.Error(), ~PPO.next, xs, PPO.init(fast, slow, kind))

def AO.State() -> Type:
  MomentumSmooth.Dual<F32>

def AO.init(+fast: U32, +slow: U32) -> Result<&2, &1, Momentum.Error(), AO.State()>:
  Momentum.configure(~AO.State(), Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), u => MomentumInit.ao(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow))

def AO.next(state: AO.State(), value: Bars.HL<F32>) -> AO.State() & Maybe<&2, F32>:
  MomentumSmooth.ao.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, ~Momentum.ppo_zero, state, value)

def AO.batch(xs: List<&2, Bars.HL<F32>>, +fast: U32, +slow: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~AO.State(), ~Momentum.Error(), ~AO.next, xs, AO.init(fast, slow))

def AC.State() -> Type:
  MomentumSmooth.MACD<F32>

def AC.init(+fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), AC.State()>:
  Momentum.configure(~AC.State(), Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(signal, 2)), u => MomentumInit.ac(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, signal))

def AC.next(state: AC.State(), value: Bars.HL<F32>) -> AC.State() & Maybe<&2, F32>:
  MomentumSmooth.ac.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def AC.batch(xs: List<&2, Bars.HL<F32>>, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~AC.State(), ~Momentum.Error(), ~AC.next, xs, AC.init(fast, slow, signal))

def MACD.State() -> Type:
  MomentumSmooth.MACD<F32>

def MACD.init(+fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), MACD.State()>:
  Momentum.configure(~MACD.State(), Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(signal, 1)), u => MomentumInit.macd(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, signal))

def MACD.next(state: MACD.State(), value: F32) -> MACD.State() & Maybe<&2, MACD.Value()>:
  MomentumSmooth.macd.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def MACD.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, MACD.Value()>>>:
  Series.initialized(~F32, ~MACD.Value(), ~MACD.State(), ~Momentum.Error(), ~MACD.next, xs, MACD.init(fast, slow, signal))

def MACDFIX.State() -> Type:
  MomentumSmooth.MACD<F32>

def MACDFIX.init(+signal: U32) -> Result<&2, &1, Momentum.Error(), MACDFIX.State()>:
  Momentum.configure(~MACDFIX.State(), Momentum.period(signal, 1), u => MomentumInit.macdfix(~F32, ~U32.to_f32, ~F32.div, ~Momentum.ma, signal))

def MACDFIX.next(state: MACDFIX.State(), value: F32) -> MACDFIX.State() & Maybe<&2, MACD.Value()>:
  MomentumSmooth.macd.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def MACDFIX.batch(xs: List<&2, F32>, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, MACD.Value()>>>:
  Series.initialized(~F32, ~MACD.Value(), ~MACDFIX.State(), ~Momentum.Error(), ~MACDFIX.next, xs, MACDFIX.init(signal))

def STOCH.State() -> Type:
  MomentumSmooth.Stoch<F32>

def STOCH.init(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), STOCH.State()>:
  Momentum.configure(~STOCH.State(), Bool.and(Bool.and(Bool.and(Momentum.period(kperiod, 1), Momentum.period(slowk, 1)), Momentum.period(dperiod, 1)), Bool.and(Momentum.selector(slowk, ktype), Momentum.selector(dperiod, dtype))), u => MomentumInit.stoch(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, slowk, ktype, dperiod, dtype))

def STOCH.next(state: STOCH.State(), value: Bars.HLC<F32>) -> STOCH.State() & Maybe<&2, STOCH.Value()>:
  MomentumSmooth.stoch.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, state, value)

def STOCH.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~STOCH.Value(), ~STOCH.State(), ~Momentum.Error(), ~STOCH.next, xs, STOCH.init(kperiod, slowk, ktype, dperiod, dtype))

def KDJ.State() -> Type:
  MomentumSmooth.Stoch<F32>

def KDJ.init(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), KDJ.State()>:
  Momentum.configure(~KDJ.State(), Bool.and(Bool.and(Bool.and(Momentum.period(kperiod, 1), Momentum.period(slowk, 1)), Momentum.period(dperiod, 1)), Bool.and(Momentum.selector(slowk, ktype), Momentum.selector(dperiod, dtype))), u => MomentumInit.stoch(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, slowk, ktype, dperiod, dtype))

def KDJ.next(state: KDJ.State(), value: Bars.HLC<F32>) -> KDJ.State() & Maybe<&2, STOCH.Value()>:
  MomentumSmooth.stoch.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, state, value)

def KDJ.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~STOCH.Value(), ~KDJ.State(), ~Momentum.Error(), ~KDJ.next, xs, KDJ.init(kperiod, slowk, ktype, dperiod, dtype))

def STOCHF.State() -> Type:
  MomentumSmooth.Stoch<F32>

def STOCHF.init(+kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), STOCHF.State()>:
  Momentum.configure(~STOCHF.State(), Bool.and(Bool.and(Momentum.period(kperiod, 1), Momentum.period(dperiod, 1)), Momentum.selector(dperiod, dtype)), u => MomentumInit.stochf(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, dperiod, dtype))

def STOCHF.next(state: STOCHF.State(), value: Bars.HLC<F32>) -> STOCHF.State() & Maybe<&2, STOCH.Value()>:
  MomentumSmooth.stoch.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, state, value)

def STOCHF.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~STOCH.Value(), ~STOCHF.State(), ~Momentum.Error(), ~STOCHF.next, xs, STOCHF.init(kperiod, dperiod, dtype))

def STOCHRSI.State() -> Type:
  MomentumComposite.StochRSI<F32>

def STOCHRSI.init(+period: U32, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), STOCHRSI.State()>:
  Momentum.configure(~STOCHRSI.State(), Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(kperiod, 1)), Momentum.period(dperiod, 1)), Momentum.selector(dperiod, dtype)), u => MomentumInit.stochrsi(~F32, ~U32.to_f32, ~Momentum.ma, period, kperiod, dperiod, dtype))

def STOCHRSI.next(state: STOCHRSI.State(), value: F32) -> STOCHRSI.State() & Maybe<&2, STOCH.Value()>:
  MomentumComposite.stochrsi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.is_gt, ~F32.max, ~F32.atan, state, value)

def STOCHRSI.batch(xs: List<&2, F32>, +period: U32, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~F32, ~STOCH.Value(), ~STOCHRSI.State(), ~Momentum.Error(), ~STOCHRSI.next, xs, STOCHRSI.init(period, kperiod, dperiod, dtype))

def TRIX.State() -> Type:
  MomentumSmooth.Trix<F32>

def TRIX.init(+period: U32) -> Result<&2, &1, Momentum.Error(), TRIX.State()>:
  Momentum.configure(~TRIX.State(), Momentum.period(period, 1), u => MomentumInit.trix(~F32, ~Momentum.ma, period))

def TRIX.next(state: TRIX.State(), value: F32) -> TRIX.State() & Maybe<&2, F32>:
  MomentumSmooth.trix.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.is_eq, state, value)

def TRIX.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~TRIX.State(), ~Momentum.Error(), ~TRIX.next, xs, TRIX.init(period))

def DOSC.State() -> Type:
  MomentumSmooth.Dosc<F32>

def DOSC.init(+period: U32, +first: U32, +second: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), DOSC.State()>:
  Momentum.configure(~DOSC.State(), Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(first, 2)), Momentum.period(second, 2)), Momentum.period(signal, 2)), u => MomentumInit.dosc(~F32, ~U32.to_f32, ~Momentum.ma, period, first, second, signal))

def DOSC.next(state: DOSC.State(), value: F32) -> DOSC.State() & Maybe<&2, F32>:
  MomentumSmooth.dosc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_gt, ~F32.max, ~F32.atan, state, value)

def DOSC.batch(xs: List<&2, F32>, +period: U32, +first: U32, +second: U32, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~DOSC.State(), ~Momentum.Error(), ~DOSC.next, xs, DOSC.init(period, first, second, signal))

def PSO.State() -> Type:
  MomentumSmooth.Pso<F32>

def PSO.init(+kperiod: U32, +period: U32) -> Result<&2, &1, Momentum.Error(), PSO.State()>:
  Momentum.configure(~PSO.State(), Bool.and(Momentum.period(kperiod, 1), Momentum.period(period, 1)), u => MomentumInit.pso(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, period))

def PSO.next(state: PSO.State(), value: Bars.HLC<F32>) -> PSO.State() & Maybe<&2, F32>:
  MomentumSmooth.pso.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, ~F32.tanh, state, value)

def PSO.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~PSO.State(), ~Momentum.Error(), ~PSO.next, xs, PSO.init(kperiod, period))

def TSI.State() -> Type:
  MomentumComposite.TSI<F32>

def TSI.init(+first: U32, +second: U32) -> Result<&2, &1, Momentum.Error(), TSI.State()>:
  Momentum.configure(~TSI.State(), Bool.and(Momentum.period(first, 2), Momentum.period(second, 2)), u => MomentumInit.tsi(~F32, ~Momentum.ma, first, second))

def TSI.next(state: TSI.State(), value: F32) -> TSI.State() & Maybe<&2, F32>:
  MomentumComposite.tsi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_gt, ~F32.atan, state, value)

def TSI.batch(xs: List<&2, F32>, +first: U32, +second: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~TSI.State(), ~Momentum.Error(), ~TSI.next, xs, TSI.init(first, second))

def QSTICK.State() -> Type:
  Ma.State<F32>

def QSTICK.init(+period: U32) -> Result<&2, &1, Momentum.Error(), QSTICK.State()>:
  Momentum.configure(~QSTICK.State(), Momentum.period(period, 1), u => MomentumInit.qstick(~F32, ~Momentum.ma, period))

def QSTICK.next(state: QSTICK.State(), value: Bars.OHLC<F32>) -> QSTICK.State() & Maybe<&2, F32>:
  MomentumSmooth.qstick.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def QSTICK.batch(xs: List<&2, Bars.OHLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~QSTICK.State(), ~Momentum.Error(), ~QSTICK.next, xs, QSTICK.init(period))

def ERI.State() -> Type:
  MomentumSmooth.Eri<F32>

def ERI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), ERI.State()>:
  Momentum.configure(~ERI.State(), Momentum.period(period, 1), u => MomentumInit.eri(~F32, ~Momentum.ma, period))

def ERI.next(state: ERI.State(), value: Bars.HLC<F32>) -> ERI.State() & Maybe<&2, ERI.Value()>:
  MomentumSmooth.eri.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def ERI.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, ERI.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~ERI.Value(), ~ERI.State(), ~Momentum.Error(), ~ERI.next, xs, ERI.init(period))

def FOSC.State() -> Type:
  MomentumComposite.Forecast<F32>

def FOSC.init(+period: U32) -> Result<&2, &1, Momentum.Error(), FOSC.State()>:
  Momentum.configure(~FOSC.State(), Momentum.period(period, 2), u => Done{MomentumInit.forecast(~F32, ~U32.to_f32, period)})

def FOSC.next(state: FOSC.State(), value: F32) -> FOSC.State() & Maybe<&2, F32>:
  MomentumComposite.forecast.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, state, value)

def FOSC.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~FOSC.State(), ~Momentum.Error(), ~FOSC.next, xs, FOSC.init(period))

def CCI.State() -> Type:
  MomentumMarket.CCI<F32>

def CCI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), CCI.State()>:
  Momentum.configure(~CCI.State(), Momentum.period(period, 2), u => Done{MomentumInit.cci(~F32, ~U32.to_f32, period)})

def CCI.next(state: CCI.State(), value: Bars.HLC<F32>) -> CCI.State() & Maybe<&2, F32>:
  MomentumMarket.cci.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_eq, state, value)

def CCI.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~CCI.State(), ~Momentum.Error(), ~CCI.next, xs, CCI.init(period))

def MFI.State() -> Type:
  MomCore.Flow<F32>

def MFI.init(+period: U32) -> Result<&2, &1, Momentum.Error(), MFI.State()>:
  Momentum.configure(~MFI.State(), Momentum.period(period, 2), u => Done{MomentumInit.flow(~F32, ~U32.to_f32, period)})

def MFI.next(state: MFI.State(), value: Bars.HLCV<F32>) -> MFI.State() & Maybe<&2, F32>:
  MomentumComposite.mfi.ratio(~F32, ~U32.to_f32, ~F32.add, ~F32.mul, ~F32.div, ~F32.min, ~F32.max, ~F32.is_gt, MomentumComposite.mfi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_gt, state, value))

def MFI.batch(xs: List<&2, Bars.HLCV<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLCV<F32>, ~F32, ~MFI.State(), ~Momentum.Error(), ~MFI.next, xs, MFI.init(period))

def Momentum.chop.result(+period: U32, result: MomentumMarket.Market<F32> & Maybe<&2, MomentumMarket.Terms<F32>>) -> MomentumMarket.Market<F32> & Maybe<&2, F32>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{MomentumMarket.chop(~F32, ~U32.to_f32, ~F32.sub, ~F32.mul, ~F32.div, ~F32.log10, ~F32.is_gt, period, value)})

def Momentum.vortex.result(result: MomentumMarket.Market<F32> & Maybe<&2, MomentumMarket.Terms<F32>>) -> MomentumMarket.Market<F32> & Maybe<&2, VORTEX.Value()>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{MomentumMarket.vortex(~F32, ~U32.to_f32, ~F32.div, ~F32.is_gt, value)})

def CHOP.State() -> Type:
  MomentumMarket.Market<F32>

def CHOP.init(+period: U32) -> Result<&2, &1, Momentum.Error(), CHOP.State()>:
  Momentum.configure(~CHOP.State(), Momentum.period(period, 2), u => Done{MomentumInit.market(~F32, ~U32.to_f32, period)})

def CHOP.next(state: CHOP.State(), value: Bars.HLC<F32>) -> CHOP.State() & Maybe<&2, F32>:
  match state:
    case MomentumMarket.Market{+period, previous, window}:
      Momentum.chop.result(period, MomentumMarket.next(~F32, ~F32.add, ~F32.sub, ~F32.abs, ~F32.min, ~F32.max, MomentumMarket.Market{period, previous, window}, value, 0))

def CHOP.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~CHOP.State(), ~Momentum.Error(), ~CHOP.next, xs, CHOP.init(period))

def CHOPTR.State() -> Type:
  MomentumMarket.Market<F32>

def CHOPTR.init(+period: U32) -> Result<&2, &1, Momentum.Error(), CHOPTR.State()>:
  Momentum.configure(~CHOPTR.State(), Momentum.period(period, 2), u => Done{MomentumInit.market(~F32, ~U32.to_f32, period)})

def CHOPTR.next(state: CHOPTR.State(), value: Bars.HLC<F32>) -> CHOPTR.State() & Maybe<&2, F32>:
  match state:
    case MomentumMarket.Market{+period, previous, window}:
      Momentum.chop.result(period, MomentumMarket.next(~F32, ~F32.add, ~F32.sub, ~F32.abs, ~F32.min, ~F32.max, MomentumMarket.Market{period, previous, window}, value, 1))

def CHOPTR.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~CHOPTR.State(), ~Momentum.Error(), ~CHOPTR.next, xs, CHOPTR.init(period))

def VORTEX.State() -> Type:
  MomentumMarket.Market<F32>

def VORTEX.init(+period: U32) -> Result<&2, &1, Momentum.Error(), VORTEX.State()>:
  Momentum.configure(~VORTEX.State(), Momentum.period(period, 1), u => Done{MomentumInit.market(~F32, ~U32.to_f32, period)})

def VORTEX.next(state: VORTEX.State(), value: Bars.HLC<F32>) -> VORTEX.State() & Maybe<&2, VORTEX.Value()>:
  match state:
    case MomentumMarket.Market{+period, previous, window}:
      Momentum.vortex.result(MomentumMarket.next(~F32, ~F32.add, ~F32.sub, ~F32.abs, ~F32.min, ~F32.max, MomentumMarket.Market{period, previous, window}, value, 2))

def VORTEX.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, VORTEX.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~VORTEX.Value(), ~VORTEX.State(), ~Momentum.Error(), ~VORTEX.next, xs, VORTEX.init(period))

def ULTOSC.State() -> Type:
  MomentumComposite.Ultimate<F32>

def ULTOSC.init(+first: U32, +second: U32, +third: U32) -> Result<&2, &1, Momentum.Error(), ULTOSC.State()>:
  Momentum.configure(~ULTOSC.State(), Bool.and(Bool.and(Momentum.period(first, 1), Momentum.period(second, 1)), Momentum.period(third, 1)), u => Done{MomentumInit.ultimate(~F32, ~U32.to_f32, first, second, third)})

def ULTOSC.next(state: ULTOSC.State(), value: Bars.HLC<F32>) -> ULTOSC.State() & Maybe<&2, F32>:
  MomentumComposite.ultimate.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, ~F32.is_gt, state, value)

def ULTOSC.batch(xs: List<&2, Bars.HLC<F32>>, +first: U32, +second: U32, +third: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~ULTOSC.State(), ~Momentum.Error(), ~ULTOSC.next, xs, ULTOSC.init(first, second, third))

def COPPOCK.State() -> Type:
  MomentumComposite.Roc<F32>

def COPPOCK.init(+wma: U32, +first: U32, +second: U32) -> Result<&2, &1, Momentum.Error(), COPPOCK.State()>:
  Momentum.configure(~COPPOCK.State(), Bool.and(Bool.and(Momentum.period(wma, 1), Momentum.period(first, 1)), Momentum.period(second, 1)), u => MomentumInit.coppock(~F32, ~U32.to_f32, ~Momentum.ma, wma, first, second))

def COPPOCK.next(state: COPPOCK.State(), value: F32) -> COPPOCK.State() & Maybe<&2, F32>:
  MomentumComposite.coppock.value(~F32, MomentumComposite.roc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_eq, ~F32.atan, state, value))

def COPPOCK.batch(xs: List<&2, F32>, +wma: U32, +first: U32, +second: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~COPPOCK.State(), ~Momentum.Error(), ~COPPOCK.next, xs, COPPOCK.init(wma, first, second))

def KST.State() -> Type:
  MomentumComposite.Roc<F32>

def KST.init(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +sma1: U32, +sma2: U32, +sma3: U32, +sma4: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), KST.State()>:
  Momentum.configure(~KST.State(), Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(roc1, 1), Momentum.period(roc2, 1)), Momentum.period(roc3, 1)), Momentum.period(roc4, 1)), Momentum.period(sma1, 1)), Momentum.period(sma2, 1)), Momentum.period(sma3, 1)), Momentum.period(sma4, 1)), Momentum.period(signal, 1)), u => MomentumInit.kst(~F32, ~U32.to_f32, ~Momentum.ma, roc1, roc2, roc3, roc4, sma1, sma2, sma3, sma4, signal))

def KST.next(state: KST.State(), value: F32) -> KST.State() & Maybe<&2, KST.Value()>:
  MomentumComposite.roc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_eq, ~F32.atan, state, value)

def KST.batch(xs: List<&2, F32>, +roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +sma1: U32, +sma2: U32, +sma3: U32, +sma4: U32, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, KST.Value()>>>:
  Series.initialized(~F32, ~KST.Value(), ~KST.State(), ~Momentum.Error(), ~KST.next, xs, KST.init(roc1, roc2, roc3, roc4, sma1, sma2, sma3, sma4, signal))

def PVO.State() -> Type:
  PPO.State()

def PVO.init(fast: U32, slow: U32, kind: U32) -> Result<&2, &1, Params.Error, PVO.State()>:
  PPO.init(fast, slow, kind)

def PVO.next(state: PVO.State(), volume: F32) -> PVO.State() & Maybe<&2, F32>:
  PPO.next(state, volume)

def PVO.batch(xs: List<&2, F32>, fast: U32, slow: U32, kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PVO.State(), ~Params.Error, ~PVO.next, xs, PVO.init(fast, slow, kind))


def DisplayShift() -> Data:
  WindowSignals.DisplayShift

def DIV(inputs: Transform.Operands<F32>) -> F32:
  Transform.binary(~F32, ~F32.div, inputs)

def DPO.State() -> Type:
  WindowSignals.Detrended<F32>

def DPO.init(+period: U32) -> Result<&2, &1, Params.Error, DPO.State()>:
  overlap.init(~DPO.State(), overlap.valid(period, 2), u => WindowSignals.dpo.init(~F32, ~U32.to_f32, period))

def DPO.next(state: DPO.State(), price: F32) -> DPO.State() & Maybe<&2, F32>:
  WindowSignals.dpo.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, state, price)

def DPO.display_shift(period: U32) -> DisplayShift():
  WindowSignals.DisplayShift{True{}, U32.add(U32.div(period, 2), 1)}

def RVOL.State() -> Type:
  Win.State<F32>

def RVOL.init(+period: U32) -> Result<&2, &1, Params.Error, RVOL.State()>:
  overlap.init(~RVOL.State(), Params.period(period), u => overlap.window(period))

def RVOL.next(state: RVOL.State(), volume: F32) -> RVOL.State() & Maybe<&2, F32>:
  WindowSignals.rvol.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, state, volume)

def ICHIMOKU.State() -> Type:
  WindowSignals.Cloud<F32>

def ICHIMOKU.Value() -> Data:
  WindowSignals.CloudValue<F32>

def ICHIMOKU.init(+tenkan: U32, +kijun: U32, +span_b: U32) -> Result<&2, &1, Params.Error, ICHIMOKU.State()>:
  overlap.init(~ICHIMOKU.State(), Bool.and(overlap.valid(tenkan, 2), Bool.and(overlap.valid(kijun, 2), overlap.valid(span_b, 2))), u => WindowSignals.cloud.init(~F32, ~U32.to_f32, tenkan, kijun, span_b))

def ICHIMOKU.next(state: ICHIMOKU.State(), bar: Bars.HL<F32>) -> ICHIMOKU.State() & Maybe<&2, ICHIMOKU.Value()>:
  WindowSignals.cloud.next(~F32, ~U32.to_f32, ~F32.add, ~F32.div, ~F32.min, ~F32.max, state, bar)

def ICHIMOKU.display_shift(kijun: U32) -> DisplayShift():
  WindowSignals.DisplayShift{False{}, kijun}

def FRACTAL.State() -> Type:
  WindowSignals.Fractal<F32>

def FRACTAL.Value() -> Data:
  WindowSignals.PivotFlags

def FRACTAL.init(+left: U32, +right: U32) -> Result<&2, &1, Params.Error, FRACTAL.State()>:
  overlap.init(~FRACTAL.State(), Params.periods([left, right]), u => WindowSignals.fractal.init(~F32, ~U32.to_f32, left, right))

def FRACTAL.next(state: FRACTAL.State(), bar: Bars.HL<F32>) -> FRACTAL.State() & Maybe<&2, FRACTAL.Value()>:
  WindowSignals.fractal.next(~F32, ~F32.is_gt, state, bar)

def FRACTAL.display_shift(right: U32) -> DisplayShift():
  WindowSignals.DisplayShift{True{}, right}

def VWAP.State() -> Data:
  MarketState.Anchored<F32>

def VWAP.init() -> VWAP.State():
  MarketState.vwap.init(~F32, ~U32.to_f32)

def VWAP.next(state: VWAP.State(), bar: Bars.HLCV<F32>) -> VWAP.State() & Maybe<&2, F32>:
  MarketState.vwap.next(~F32, ~U32.to_f32, ~F32.add, ~F32.mul, ~F32.div, ~F32.is_gt, ~is_finite, state, bar)

def VWAP.batch(xs: List<&2, Bars.HLCV<F32>>) -> List<&2, Maybe<&2, F32>>:
  Series.batch(~Bars.HLCV<F32>, ~F32, ~VWAP.State(), ~VWAP.next, xs, VWAP.init())

def ZIGZAG.State() -> Data:
  MarketState.ZigZag<F32>

def ZIGZAG.Value() -> Data:
  MarketState.ZigValue<F32>

def ZIGZAG.init(+sensitivity: F32, +minimum: U32) -> Result<&2, &1, Params.Error, ZIGZAG.State()>:
  overlap.init(~ZIGZAG.State(), Bool.and(Params.period(minimum), Bool.and(is_finite(sensitivity), Bool.and(F32.is_ge(sensitivity, 0.0), F32.is_le(sensitivity, 100.0)))), u => MarketState.zigzag.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, sensitivity, minimum))

def ZIGZAG.next(state: ZIGZAG.State(), bar: Bars.HL<F32>) -> ZIGZAG.State() & Maybe<&2, ZIGZAG.Value()>:
  MarketState.zigzag.next(~F32, ~F32.mul, ~F32.min, ~F32.max, ~F32.is_ge, state, bar)

def MAVP.State() -> Type:
  Variable.State<F32>

def MAVP.Sample() -> Data:
  Variable.Sample<F32>

def MAVP.init(+minimum: U32, +maximum: U32, +kind: U32) -> Result<&2, &1, Params.Error, MAVP.State()>:
  overlap.init(~MAVP.State(), Bool.and(Bool.and(U32.is_gt(minimum, 0), U32.is_le(maximum, 10000)), Bool.and(U32.is_le(minimum, maximum), Bool.or(Ma.supported(kind), Bool.and(U32.is_eq(maximum, 1), U32.is_le(kind, 15))))), u => Variable.init(~F32, minimum, maximum, kind))

def MAVP.average(+period: U32, kind: U32) -> Ma.State<F32>:
  Ma.make(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Config.depth(period), kind, 0.7)

def MAVP.next(state: MAVP.State(), sample: MAVP.Sample()) -> MAVP.State() & Maybe<&2, F32>:
  Variable.next(~F32, ~U32.to_f32, ~F32.to_u32, ~F32.is_ge, ~F32.is_gt, ~(p => k => MAVP.average(p, k)), ~MA.next, state, sample)

def DPO.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~DPO.State(), ~Params.Error, ~DPO.next, xs, DPO.init(period))

def RVOL.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~RVOL.State(), ~Params.Error, ~RVOL.next, xs, RVOL.init(period))

def ICHIMOKU.batch(xs: List<&2, Bars.HL<F32>>, tenkan: U32, kijun: U32, span_b: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, ICHIMOKU.Value()>>>:
  Series.initialized(~Bars.HL<F32>, ~ICHIMOKU.Value(), ~ICHIMOKU.State(), ~Params.Error, ~ICHIMOKU.next, xs, ICHIMOKU.init(tenkan, kijun, span_b))

def FRACTAL.batch(xs: List<&2, Bars.HL<F32>>, left: U32, right: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, FRACTAL.Value()>>>:
  Series.initialized(~Bars.HL<F32>, ~FRACTAL.Value(), ~FRACTAL.State(), ~Params.Error, ~FRACTAL.next, xs, FRACTAL.init(left, right))

def ZIGZAG.batch(xs: List<&2, Bars.HL<F32>>, sensitivity: F32, minimum: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, ZIGZAG.Value()>>>:
  Series.initialized(~Bars.HL<F32>, ~ZIGZAG.Value(), ~ZIGZAG.State(), ~Params.Error, ~ZIGZAG.next, xs, ZIGZAG.init(sensitivity, minimum))

def MAVP.batch(xs: List<&2, MAVP.Sample()>, minimum: U32, maximum: U32, kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~MAVP.Sample(), ~F32, ~MAVP.State(), ~Params.Error, ~MAVP.next, xs, MAVP.init(minimum, maximum, kind))

def Trend.nonnegative(+value: F32) -> Bool:
  Bool.and(is_finite(value), Bool.and(F32.is_ge(value, 0.0), F32.is_le(value, 3.0e37)))

def FRAMA.State() -> Type:
  AdaptiveWindow.Frama<F32>

def FRAMA.init(+period: U32) -> Result<&2, &1, Params.Error, FRAMA.State()>:
  Momentum.configure(~FRAMA.State(), Bool.and(Momentum.period(period, 2), U32.is_zero(U32.mod(period, 2))), u => Done{AdaptiveWindow.frama.init(~F32, ~U32.to_f32, period)})

def FRAMA.next(state: FRAMA.State(), value: Bars.HL<F32>) -> FRAMA.State() & Maybe<&2, F32>:
  AdaptiveWindow.frama.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.min, ~F32.max, ~F32.is_lt, ~F32.log, ~F32.exp, state, value)

def FRAMA.batch(xs: List<&2, Bars.HL<F32>>, +period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~FRAMA.State(), ~Params.Error, ~FRAMA.next, xs, FRAMA.init(period))

def MCGD.State() -> Type:
  TrendState.McGinley<F32>

def MCGD.init(+period: U32) -> Result<&2, &1, Params.Error, MCGD.State()>:
  Momentum.configure(~MCGD.State(), Momentum.period(period, 2), u => Done{TrendState.mcgd.init(~F32, period)})

def MCGD.next(state: MCGD.State(), value: F32) -> MCGD.State() & Maybe<&2, F32>:
  TrendState.mcgd.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~is_finite, state, value)

def MCGD.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~MCGD.State(), ~Params.Error, ~MCGD.next, xs, MCGD.init(period))

def SAR.State() -> Type:
  TrendState.Sar<F32>

def SAR.init(+acceleration: F32, +maximum: F32) -> Result<&2, &1, Params.Error, SAR.State()>:
  Momentum.configure(~SAR.State(), Bool.and(Trend.nonnegative(acceleration), Trend.nonnegative(maximum)), u => Done{TrendState.sar.init(~F32, ~F32.min, 0.0, 0.0, acceleration, acceleration, maximum, acceleration, acceleration, maximum, False{})})

def SAR.next(state: SAR.State(), value: Bars.HL<F32>) -> SAR.State() & Maybe<&2, F32>:
  TrendState.sar.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.min, ~F32.max, ~F32.is_le, ~F32.is_lt, ~F32.is_eq, ~F32.abs, state, value)

def SAR.batch(xs: List<&2, Bars.HL<F32>>, +acceleration: F32, +maximum: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~SAR.State(), ~Params.Error, ~SAR.next, xs, SAR.init(acceleration, maximum))

def SAREXT.State() -> Type:
  TrendState.Sar<F32>

def SAREXT.init(+start: F32, +offset: F32, +long_init: F32, +long_step: F32, +long_max: F32, +short_init: F32, +short_step: F32, +short_max: F32) -> Result<&2, &1, Params.Error, SAREXT.State()>:
  Momentum.configure(~SAREXT.State(), Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(is_finite(start), F32.is_le(F32.abs(start), 3.0e37)), Trend.nonnegative(offset)), Trend.nonnegative(long_init)), Trend.nonnegative(long_step)), Trend.nonnegative(long_max)), Trend.nonnegative(short_init)), Trend.nonnegative(short_step)), Trend.nonnegative(short_max)), u => Done{TrendState.sar.init(~F32, ~F32.min, start, offset, long_init, long_step, long_max, short_init, short_step, short_max, True{})})

def SAREXT.next(state: SAREXT.State(), value: Bars.HL<F32>) -> SAREXT.State() & Maybe<&2, F32>:
  TrendState.sar.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.min, ~F32.max, ~F32.is_le, ~F32.is_lt, ~F32.is_eq, ~F32.abs, state, value)

def SAREXT.batch(xs: List<&2, Bars.HL<F32>>, +start: F32, +offset: F32, +long_init: F32, +long_step: F32, +long_max: F32, +short_init: F32, +short_step: F32, +short_max: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~SAREXT.State(), ~Params.Error, ~SAREXT.next, xs, SAREXT.init(start, offset, long_init, long_step, long_max, short_init, short_step, short_max))

def SUPERTREND.State() -> Type:
  TrendState.Supertrend<F32>

def SUPERTREND.Value() -> Data:
  TrendState.TrendValue<F32>

def SUPERTREND.init(+period: U32, +multiplier: F32) -> Result<&2, &1, Params.Error, SUPERTREND.State()>:
  Momentum.configure(~SUPERTREND.State(), Bool.and(Momentum.period(period, 2), Trend.nonnegative(multiplier)), u => Done{TrendState.supertrend.init(~F32, ~U32.to_f32, ~F32.div, period, multiplier)})

def SUPERTREND.next(state: SUPERTREND.State(), value: Bars.HLC<F32>) -> SUPERTREND.State() & Maybe<&2, SUPERTREND.Value()>:
  TrendState.supertrend.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_lt, state, value)

def SUPERTREND.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32, +multiplier: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, SUPERTREND.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~SUPERTREND.Value(), ~SUPERTREND.State(), ~Params.Error, ~SUPERTREND.next, xs, SUPERTREND.init(period, multiplier))

def CG.State() -> Type:
  Win.State<F32>

def CG.init(+period: U32) -> Result<&2, &1, Params.Error, CG.State()>:
  Momentum.configure(~CG.State(), Momentum.period(period, 2), u => Done{AdaptiveWindow.prices.init(~F32, ~U32.to_f32, period)})

def CG.next(state: CG.State(), value: F32) -> CG.State() & Maybe<&2, F32>:
  AdaptiveWindow.cg.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, state, value)

def CG.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~CG.State(), ~Params.Error, ~CG.next, xs, CG.init(period))

def CTI.State() -> Type:
  Win.State<F32>

def CTI.init(+period: U32) -> Result<&2, &1, Params.Error, CTI.State()>:
  Momentum.configure(~CTI.State(), Momentum.period(period, 2), u => Done{AdaptiveWindow.prices.init(~F32, ~U32.to_f32, period)})

def CTI.next(state: CTI.State(), value: F32) -> CTI.State() & Maybe<&2, F32>:
  AdaptiveWindow.cti.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.min, ~F32.max, ~F32.is_lt, ~F32.sqrt, state, value)

def CTI.batch(xs: List<&2, F32>, +period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~CTI.State(), ~Params.Error, ~CTI.next, xs, CTI.init(period))

def FISHER.State() -> Type:
  AdaptiveWindow.Fisher<F32>

def FISHER.Value() -> Data:
  MomentumSmooth.Lines<F32>

def FISHER.init(+period: U32) -> Result<&2, &1, Params.Error, FISHER.State()>:
  Momentum.configure(~FISHER.State(), Momentum.period(period, 2), u => Done{AdaptiveWindow.fisher.init(~F32, ~U32.to_f32, period)})

def FISHER.next(state: FISHER.State(), value: Bars.HL<F32>) -> FISHER.State() & Maybe<&2, FISHER.Value()>:
  AdaptiveWindow.fisher.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_lt, ~F32.log, state, value)

def FISHER.batch(xs: List<&2, Bars.HL<F32>>, +period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, FISHER.Value()>>>:
  Series.initialized(~Bars.HL<F32>, ~FISHER.Value(), ~FISHER.State(), ~Params.Error, ~FISHER.next, xs, FISHER.init(period))

def CRSI.State() -> Type:
  AdvancedOscillator.Crsi<F32>

def CRSI.init(+period: U32, +streak: U32, +rank: U32) -> Result<&2, &1, Params.Error, CRSI.State()>:
  Momentum.configure(~CRSI.State(), Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(streak, 2)), Momentum.period(rank, 2)), U32.is_le(rank, 10000)), u => Done{AdvancedOscillator.crsi.init(~F32, ~U32.to_f32, period, streak, rank)})

def CRSI.next(state: CRSI.State(), value: F32) -> CRSI.State() & Maybe<&2, F32>:
  AdvancedOscillator.crsi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.max, ~F32.is_lt, ~F32.is_eq, state, value)

def CRSI.batch(xs: List<&2, F32>, +period: U32, +streak: U32, +rank: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~CRSI.State(), ~Params.Error, ~CRSI.next, xs, CRSI.init(period, streak, rank))

def SMI.State() -> Type:
  AdvancedOscillator.Smi<F32>

def SMI.Value() -> Data:
  MomentumSmooth.Lines<F32>

def SMI.init(+period: U32, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Params.Error, SMI.State()>:
  Momentum.configure(~SMI.State(), Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(fast, 2)), Momentum.period(slow, 2)), Momentum.period(signal, 2)), u => Done{AdvancedOscillator.smi.init(~F32, ~U32.to_f32, ~F32.div, period, fast, slow, signal)})

def SMI.next(state: SMI.State(), value: Bars.HLC<F32>) -> SMI.State() & Maybe<&2, SMI.Value()>:
  AdvancedOscillator.smi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_le, state, value)

def SMI.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, SMI.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~SMI.Value(), ~SMI.State(), ~Params.Error, ~SMI.next, xs, SMI.init(period, fast, slow, signal))

def STC.State() -> Type:
  AdvancedOscillator.Stc<F32>

def STC.init(+fast: U32, +slow: U32, +cycle: U32) -> Result<&2, &1, Params.Error, STC.State()>:
  Momentum.configure(~STC.State(), Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(cycle, 2)), u => AdvancedOscillator.stc.init(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, cycle))

def STC.next(state: STC.State(), value: F32) -> STC.State() & Maybe<&2, F32>:
  AdvancedOscillator.stc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_eq, ~F32.is_le, ~F32.atan, state, value)

def STC.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +cycle: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~STC.State(), ~Params.Error, ~STC.next, xs, STC.init(fast, slow, cycle))

def WAVETREND.State() -> Type:
  AdvancedOscillator.Wave<F32>

def WAVETREND.Value() -> Data:
  MomentumSmooth.Lines<F32>

def WAVETREND.init(+channel: U32, +average: U32, +signal: U32) -> Result<&2, &1, Params.Error, WAVETREND.State()>:
  Momentum.configure(~WAVETREND.State(), Bool.and(Bool.and(Momentum.period(channel, 2), Momentum.period(average, 1)), Momentum.period(signal, 1)), u => Done{AdvancedOscillator.wave.init(~F32, ~U32.to_f32, ~F32.div, channel, average, signal)})

def WAVETREND.next(state: WAVETREND.State(), value: Bars.HLC<F32>) -> WAVETREND.State() & Maybe<&2, WAVETREND.Value()>:
  AdvancedOscillator.wave.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_eq, state, value)

def WAVETREND.batch(xs: List<&2, Bars.HLC<F32>>, +channel: U32, +average: U32, +signal: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, WAVETREND.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~WAVETREND.Value(), ~WAVETREND.State(), ~Params.Error, ~WAVETREND.next, xs, WAVETREND.init(channel, average, signal))

def MACDEXT.State() -> Type:
  TrendComposite.Macd<F32>

def MACDEXT.Value() -> Data:
  MomentumSmooth.MACDValue<F32>

def MACDEXT.init(+fast: U32, +fast_kind: U32, +slow: U32, +slow_kind: U32, +signal: U32, +signal_kind: U32) -> Result<&2, &1, Params.Error, MACDEXT.State()>:
  Momentum.configure(~MACDEXT.State(), Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(signal, 1)), Momentum.selector(fast, fast_kind)), Momentum.selector(slow, slow_kind)), Momentum.selector(signal, signal_kind)), u => TrendComposite.macd.init(~F32, ~U32.to_f32, ~Momentum.ma, fast, fast_kind, slow, slow_kind, signal, signal_kind))

def MACDEXT.next(state: MACDEXT.State(), value: F32) -> MACDEXT.State() & Maybe<&2, MACDEXT.Value()>:
  TrendComposite.macd.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def MACDEXT.batch(xs: List<&2, F32>, +fast: U32, +fast_kind: U32, +slow: U32, +slow_kind: U32, +signal: U32, +signal_kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MACDEXT.Value()>>>:
  Series.initialized(~F32, ~MACDEXT.Value(), ~MACDEXT.State(), ~Params.Error, ~MACDEXT.next, xs, MACDEXT.init(fast, fast_kind, slow, slow_kind, signal, signal_kind))

def KSTEXT.State() -> Type:
  TrendComposite.Kst<F32>

def KSTEXT.Value() -> Data:
  MomentumSmooth.Lines<F32>

def KSTEXT.init(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +ma1: U32, +ma2: U32, +ma3: U32, +ma4: U32, +signal: U32, +kind: U32, +signal_kind: U32) -> Result<&2, &1, Params.Error, KSTEXT.State()>:
  Momentum.configure(~KSTEXT.State(), Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(roc1, 1), Momentum.period(roc2, 1)), Momentum.period(roc3, 1)), Momentum.period(roc4, 1)), Momentum.period(ma1, 1)), Momentum.period(ma2, 1)), Momentum.period(ma3, 1)), Momentum.period(ma4, 1)), Momentum.period(signal, 1)), Momentum.selector(ma1, kind)), Momentum.selector(ma2, kind)), Momentum.selector(ma3, kind)), Momentum.selector(ma4, kind)), Momentum.selector(signal, signal_kind)), u => TrendComposite.kst.init(~F32, ~U32.to_f32, ~Momentum.ma, roc1, roc2, roc3, roc4, ma1, ma2, ma3, ma4, signal, kind, signal_kind))

def KSTEXT.next(state: KSTEXT.State(), value: F32) -> KSTEXT.State() & Maybe<&2, KSTEXT.Value()>:
  TrendComposite.kst.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_eq, ~F32.atan, state, value)

def KSTEXT.batch(xs: List<&2, F32>, +roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +ma1: U32, +ma2: U32, +ma3: U32, +ma4: U32, +signal: U32, +kind: U32, +signal_kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, KSTEXT.Value()>>>:
  Series.initialized(~F32, ~KSTEXT.Value(), ~KSTEXT.State(), ~Params.Error, ~KSTEXT.next, xs, KSTEXT.init(roc1, roc2, roc3, roc4, ma1, ma2, ma3, ma4, signal, kind, signal_kind))

def SQZMOM.State() -> Type:
  Squeeze.State<F32>

def SQZMOM.Value() -> Data:
  Squeeze.Value<F32>

def SQZMOM.init(+bb: U32, +deviations: F32, +kc: U32, +wide: F32, +normal: F32, +narrow: F32) -> Result<&2, &1, Params.Error, SQZMOM.State()>:
  Momentum.configure(~SQZMOM.State(), Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(bb, 2), Momentum.period(kc, 2)), Trend.nonnegative(deviations)), Trend.nonnegative(wide)), Trend.nonnegative(normal)), Trend.nonnegative(narrow)), F32.is_le(narrow, normal)), F32.is_le(normal, wide)), u => Done{Squeeze.init(~F32, ~U32.to_f32, bb, kc, deviations, wide, normal, narrow)})

def SQZMOM.next(state: SQZMOM.State(), value: Bars.HLC<F32>) -> SQZMOM.State() & Maybe<&2, SQZMOM.Value()>:
  Squeeze.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_le, ~F32.is_lt, ~F32.sqrt, state, value)

def SQZMOM.batch(xs: List<&2, Bars.HLC<F32>>, +bb: U32, +deviations: F32, +kc: U32, +wide: F32, +normal: F32, +narrow: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, SQZMOM.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~SQZMOM.Value(), ~SQZMOM.State(), ~Params.Error, ~SQZMOM.next, xs, SQZMOM.init(bb, deviations, kc, wide, normal, narrow))

def PairValue() -> Data:
  StatWindow.PairValue<F32>

def KVO.Value() -> Data:
  VolumeFilter.Lines<F32>

def ADOSC.State() -> Type:
  VolumeFilter.Adosc<F32>

def ADOSC.init(+fast: U32, +slow: U32) -> Result<&2, &1, Params.Error, ADOSC.State()>:
  overlap.init(~ADOSC.State(), Bool.and(overlap.valid(fast, 2), overlap.valid(slow, 2)), u => VolumeFilter.adosc.init(~F32, ~U32.to_f32, ~F32.div, fast, slow))

def ADOSC.next(state: ADOSC.State(), value: Bars.HLCV<F32>) -> ADOSC.State() & Maybe<&2, F32>:
  VolumeFilter.adosc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_gt, state, value)

def ADOSC.batch(xs: List<&2, Bars.HLCV<F32>>, fast: U32, slow: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLCV<F32>, ~F32, ~ADOSC.State(), ~Params.Error, ~ADOSC.next, xs, ADOSC.init(fast, slow))

def KVO.State() -> Type:
  VolumeFilter.Kvo<F32>

def KVO.init(+fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Params.Error, KVO.State()>:
  overlap.init(~KVO.State(), Bool.and(overlap.valid(fast, 2), Bool.and(overlap.valid(slow, 2), overlap.valid(signal, 2))), u => VolumeFilter.kvo.init(~F32, ~U32.to_f32, ~F32.div, fast, slow, signal))

def KVO.next(state: KVO.State(), value: Bars.HLCV<F32>) -> KVO.State() & Maybe<&2, KVO.Value()>:
  VolumeFilter.kvo.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_eq, ~F32.is_gt, state, value)

def KVO.batch(xs: List<&2, Bars.HLCV<F32>>, fast: U32, slow: U32, signal: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, KVO.Value()>>>:
  Series.initialized(~Bars.HLCV<F32>, ~KVO.Value(), ~KVO.State(), ~Params.Error, ~KVO.next, xs, KVO.init(fast, slow, signal))

def VAR.State() -> Type:
  Win.State<F32>

def VAR.init(+period: U32, +factor: F32) -> Result<&2, &1, Params.Error, VAR.State()>:
  overlap.init(~VAR.State(), Bool.and(overlap.valid(period, 1), Bool.and(is_finite(factor), F32.is_le(F32.abs(factor), 3.0e37))), u => overlap.window(period))

def VAR.next(state: VAR.State(), value: F32) -> VAR.State() & Maybe<&2, F32>:
  overlap.project(~VAR.State(), ~Stats.Value<F32>, ~F32, ~(v => StatWindow.variance(~F32, v)), Stats.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, value))

def VAR.batch(xs: List<&2, F32>, period: U32, factor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~VAR.State(), ~Params.Error, ~VAR.next, xs, VAR.init(period, factor))

def CORREL.State() -> Type:
  Win.State<StatWindow.PairValue<F32>>

def CORREL.init(+period: U32) -> Result<&2, &1, Params.Error, CORREL.State()>:
  overlap.init(~CORREL.State(), overlap.valid(period, 1), u => StatWindow.pair.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)))

def CORREL.next(state: CORREL.State(), value: PairValue()) -> CORREL.State() & Maybe<&2, F32>:
  StatWindow.pair.project(~F32, ~(v => StatWindow.correl.ratio(~F32, ~U32.to_f32, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.min, ~F32.max, ~F32.is_gt, v)), StatWindow.pair.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, value))

def CORREL.batch(xs: List<&2, PairValue()>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~PairValue(), ~F32, ~CORREL.State(), ~Params.Error, ~CORREL.next, xs, CORREL.init(period))

def BETA.State() -> Type:
  StatWindow.Beta<F32>

def BETA.init(+period: U32) -> Result<&2, &1, Params.Error, BETA.State()>:
  overlap.init(~BETA.State(), overlap.valid(period, 1), u => StatWindow.beta.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)))

def BETA.next(state: BETA.State(), value: PairValue()) -> BETA.State() & Maybe<&2, F32>:
  StatWindow.beta.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_gt, state, value)

def BETA.batch(xs: List<&2, PairValue()>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~PairValue(), ~F32, ~BETA.State(), ~Params.Error, ~BETA.next, xs, BETA.init(period))

def KURTOSIS.State() -> Type:
  Win.State<F32>

def KURTOSIS.init(+period: U32) -> Result<&2, &1, Params.Error, KURTOSIS.State()>:
  overlap.init(~KURTOSIS.State(), Bool.and(U32.is_ge(period, 4), U32.is_le(period, 10000)), u => overlap.window(period))

def KURTOSIS.next(state: KURTOSIS.State(), value: F32) -> KURTOSIS.State() & Maybe<&2, F32>:
  StatWindow.kurtosis.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, value)

def KURTOSIS.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~KURTOSIS.State(), ~Params.Error, ~KURTOSIS.next, xs, KURTOSIS.init(period))

def ROGERSSATCHELL.State() -> Type:
  VolWindow.RogersSatchell<F32>

def ROGERSSATCHELL.init(+period: U32, +annualization: F32) -> Result<&2, &1, Params.Error, ROGERSSATCHELL.State()>:
  overlap.init(~ROGERSSATCHELL.State(), Bool.and(overlap.valid(period, 1), Bool.and(is_finite(annualization), Bool.and(F32.is_ge(annualization, 0.0), F32.is_le(annualization, 3.0e37)))), u => VolWindow.rogerssatchell.init(~F32, ~U32.to_f32, ~F32.sqrt, period, Ma.buffer_depth(period), annualization))

def ROGERSSATCHELL.next(state: ROGERSSATCHELL.State(), value: Bars.OHLC<F32>) -> ROGERSSATCHELL.State() & Maybe<&2, F32>:
  VolWindow.rogerssatchell.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.log, ~F32.is_gt, state, value)

def ROGERSSATCHELL.batch(xs: List<&2, Bars.OHLC<F32>>, period: U32, annualization: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~ROGERSSATCHELL.State(), ~Params.Error, ~ROGERSSATCHELL.next, xs, ROGERSSATCHELL.init(period, annualization))

def RVI.State() -> Type:
  VolWindow.Rvi<F32>

def RVI.init(+period: U32, +deviation_period: U32) -> Result<&2, &1, Params.Error, RVI.State()>:
  overlap.init(~RVI.State(), Bool.and(overlap.valid(period, 1), overlap.valid(deviation_period, 2)), u => VolWindow.rvi.init(~F32, ~U32.to_f32, ~F32.div, period, deviation_period, Ma.buffer_depth(deviation_period)))

def RVI.next(state: RVI.State(), value: F32) -> RVI.State() & Maybe<&2, F32>:
  VolWindow.rvi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.is_eq, ~F32.is_gt, state, value)

def RVI.batch(xs: List<&2, F32>, period: U32, deviation_period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~RVI.State(), ~Params.Error, ~RVI.next, xs, RVI.init(period, deviation_period))

def RVIR.State() -> Type:
  VolWindow.Rvir<F32>

def RVIR.init(+period: U32, +deviation_period: U32) -> Result<&2, &1, Params.Error, RVIR.State()>:
  overlap.init(~RVIR.State(), Bool.and(overlap.valid(period, 1), overlap.valid(deviation_period, 2)), u => VolWindow.rvir.init(~F32, ~U32.to_f32, ~F32.div, period, deviation_period, Ma.buffer_depth(deviation_period)))

def RVIR.next(state: RVIR.State(), value: Bars.HL<F32>) -> RVIR.State() & Maybe<&2, F32>:
  VolWindow.rvir.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.is_eq, ~F32.is_gt, state, value)

def RVIR.batch(xs: List<&2, Bars.HL<F32>>, period: U32, deviation_period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~RVIR.State(), ~Params.Error, ~RVIR.next, xs, RVIR.init(period, deviation_period))

def CDLHIKKAKE.State() -> Type:
  Hikkake.State<F32>

def CDLHIKKAKE.init() -> Result<&2, &1, Pattern.Error(), CDLHIKKAKE.State()>:
  Done{Hikkake.init(~F32, ~U32.to_f32, False{}, Candles.Setting{Candles.HighLow{}, 0, 0.0}, 0n)}

def CDLHIKKAKE.next(state: CDLHIKKAKE.State(), bar: Bars.OHLC<F32>) -> CDLHIKKAKE.State() & Maybe<&2, Pattern.Signal()>:
  Hikkake.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, ~F32.is_lt, ~F32.is_le, state, bar)

def CDLHIKKAKE.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHIKKAKE.State(), ~Pattern.Error(), ~CDLHIKKAKE.next, xs, CDLHIKKAKE.init())

def CDLHIKKAKEMOD.State() -> Type:
  Hikkake.State<F32>

def CDLHIKKAKEMOD.init.setting(+near: Candles.Setting<F32>) -> Result<&2, &1, Pattern.Error(), CDLHIKKAKEMOD.State()>:
  match near:
    case Candles.Setting{kind, +period, +factor}:
      overlap.init(~CDLHIKKAKEMOD.State(), Patterns.setting.valid(~F32, ~is_finite, ~F32.is_ge, ~U32.to_f32, near), u => Hikkake.init(~F32, ~U32.to_f32, True{}, near, Ma.buffer_depth(U32.max(period, 1))))

def CDLHIKKAKEMOD.init() -> Result<&2, &1, Pattern.Error(), CDLHIKKAKEMOD.State()>:
  CDLHIKKAKEMOD.init.setting(Candle.defaults(Candles.Near{}))

def CDLHIKKAKEMOD.next(state: CDLHIKKAKEMOD.State(), bar: Bars.OHLC<F32>) -> CDLHIKKAKEMOD.State() & Maybe<&2, Pattern.Signal()>:
  Hikkake.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, ~F32.is_lt, ~F32.is_le, state, bar)

def CDLHIKKAKEMOD.batch(xs: List<&2, Bars.OHLC<F32>>) -> Result<&2, &2, Pattern.Error(), List<&2, Maybe<&2, Pattern.Signal()>>>:
  Series.initialized(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHIKKAKEMOD.State(), ~Pattern.Error(), ~CDLHIKKAKEMOD.next, xs, CDLHIKKAKEMOD.init())

def HT_DCPERIOD.State() -> Type:
  Hilbert.State<F32>

def HT_DCPERIOD.init() -> Result<&2, &1, Params.Error, HT_DCPERIOD.State()>:
  Done{Hilbert.init(~F32, ~U32.to_f32, 0)}

def HT_DCPERIOD.next(state: HT_DCPERIOD.State(), value: F32) -> HT_DCPERIOD.State() & Maybe<&2, F32>:
  Hilbert.project(~F32, ~F32, ~(value => Hilbert.scalar(~F32, 0, value)), Hilbert.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.to_u32, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sin, ~F32.cos, state, value))

def HT_DCPERIOD.batch(xs: List<&2, F32>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~HT_DCPERIOD.State(), ~Params.Error, ~HT_DCPERIOD.next, xs, HT_DCPERIOD.init())

def HT_PHASOR.State() -> Type:
  Hilbert.State<F32>

def HT_PHASOR.Value() -> Data:
  Hilbert.Phasor<F32>

def HT_PHASOR.init() -> Result<&2, &1, Params.Error, HT_PHASOR.State()>:
  Done{Hilbert.init(~F32, ~U32.to_f32, 1)}

def HT_PHASOR.next(state: HT_PHASOR.State(), value: F32) -> HT_PHASOR.State() & Maybe<&2, HT_PHASOR.Value()>:
  Hilbert.project(~F32, ~HT_PHASOR.Value(), ~(value => Hilbert.phasor(~F32, value)), Hilbert.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.to_u32, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sin, ~F32.cos, state, value))

def HT_PHASOR.batch(xs: List<&2, F32>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, HT_PHASOR.Value()>>>:
  Series.initialized(~F32, ~HT_PHASOR.Value(), ~HT_PHASOR.State(), ~Params.Error, ~HT_PHASOR.next, xs, HT_PHASOR.init())

def HT_TRENDLINE.State() -> Type:
  Hilbert.State<F32>

def HT_TRENDLINE.init() -> Result<&2, &1, Params.Error, HT_TRENDLINE.State()>:
  Done{Hilbert.init(~F32, ~U32.to_f32, 2)}

def HT_TRENDLINE.next(state: HT_TRENDLINE.State(), value: F32) -> HT_TRENDLINE.State() & Maybe<&2, F32>:
  Hilbert.project(~F32, ~F32, ~(value => Hilbert.scalar(~F32, 2, value)), Hilbert.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.to_u32, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sin, ~F32.cos, state, value))

def HT_TRENDLINE.batch(xs: List<&2, F32>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~HT_TRENDLINE.State(), ~Params.Error, ~HT_TRENDLINE.next, xs, HT_TRENDLINE.init())

def HT_DCPHASE.State() -> Type:
  Hilbert.State<F32>

def HT_DCPHASE.init() -> Result<&2, &1, Params.Error, HT_DCPHASE.State()>:
  Done{Hilbert.init(~F32, ~U32.to_f32, 3)}

def HT_DCPHASE.next(state: HT_DCPHASE.State(), value: F32) -> HT_DCPHASE.State() & Maybe<&2, F32>:
  Hilbert.project(~F32, ~F32, ~(value => Hilbert.scalar(~F32, 3, value)), Hilbert.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.to_u32, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sin, ~F32.cos, state, value))

def HT_DCPHASE.batch(xs: List<&2, F32>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~HT_DCPHASE.State(), ~Params.Error, ~HT_DCPHASE.next, xs, HT_DCPHASE.init())

def HT_SINE.State() -> Type:
  Hilbert.State<F32>

def HT_SINE.Value() -> Data:
  Hilbert.Sine<F32>

def HT_SINE.init() -> Result<&2, &1, Params.Error, HT_SINE.State()>:
  Done{Hilbert.init(~F32, ~U32.to_f32, 4)}

def HT_SINE.next(state: HT_SINE.State(), value: F32) -> HT_SINE.State() & Maybe<&2, HT_SINE.Value()>:
  Hilbert.project(~F32, ~HT_SINE.Value(), ~(value => Hilbert.waves(~F32, value)), Hilbert.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.to_u32, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sin, ~F32.cos, state, value))

def HT_SINE.batch(xs: List<&2, F32>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, HT_SINE.Value()>>>:
  Series.initialized(~F32, ~HT_SINE.Value(), ~HT_SINE.State(), ~Params.Error, ~HT_SINE.next, xs, HT_SINE.init())

def HT_TRENDMODE.State() -> Type:
  Hilbert.State<F32>

def HT_TRENDMODE.init() -> Result<&2, &1, Params.Error, HT_TRENDMODE.State()>:
  Done{Hilbert.init(~F32, ~U32.to_f32, 5)}

def HT_TRENDMODE.next(state: HT_TRENDMODE.State(), value: F32) -> HT_TRENDMODE.State() & Maybe<&2, U32>:
  Hilbert.project(~F32, ~U32, ~(value => Hilbert.mode(~F32, value)), Hilbert.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.to_u32, ~F32.abs, ~F32.is_le, ~F32.atan, ~F32.sin, ~F32.cos, state, value))

def HT_TRENDMODE.batch(xs: List<&2, F32>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, U32>>>:
  Series.initialized(~F32, ~U32, ~HT_TRENDMODE.State(), ~Params.Error, ~HT_TRENDMODE.next, xs, HT_TRENDMODE.init())

def filter.valid(+period: U32, minimum: U32, maximum: U32) -> Bool:
  Bool.and(U32.is_ge(period, minimum), U32.is_le(period, maximum))

def SWAK_BUTTER.State() -> Data:
  Filters.State<F32>

def SWAK_BUTTER.init(+period: U32) -> Result<&2, &1, Params.Error, SWAK_BUTTER.State()>:
  overlap.init(~SWAK_BUTTER.State(), filter.valid(period, 2, 10000), u => Filters.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sin, ~F32.cos, ~F32.sqrt, ~F32.atan, 0, period, 0.0))

def SWAK_BUTTER.next(state: SWAK_BUTTER.State(), value: F32) -> SWAK_BUTTER.State() & Maybe<&2, F32>:
  Filters.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, state, value)

def SWAK_BUTTER.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~SWAK_BUTTER.State(), ~Params.Error, ~SWAK_BUTTER.next, xs, SWAK_BUTTER.init(period))

def SWAK_GAUSS.State() -> Data:
  Filters.State<F32>

def SWAK_GAUSS.init(+period: U32) -> Result<&2, &1, Params.Error, SWAK_GAUSS.State()>:
  overlap.init(~SWAK_GAUSS.State(), filter.valid(period, 2, 10000), u => Filters.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sin, ~F32.cos, ~F32.sqrt, ~F32.atan, 1, period, 0.0))

def SWAK_GAUSS.next(state: SWAK_GAUSS.State(), value: F32) -> SWAK_GAUSS.State() & Maybe<&2, F32>:
  Filters.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, state, value)

def SWAK_GAUSS.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~SWAK_GAUSS.State(), ~Params.Error, ~SWAK_GAUSS.next, xs, SWAK_GAUSS.init(period))

def SWAK_2PHP.State() -> Data:
  Filters.State<F32>

def SWAK_2PHP.init(+period: U32) -> Result<&2, &1, Params.Error, SWAK_2PHP.State()>:
  overlap.init(~SWAK_2PHP.State(), filter.valid(period, 2, 10000), u => Filters.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sin, ~F32.cos, ~F32.sqrt, ~F32.atan, 2, period, 0.0))

def SWAK_2PHP.next(state: SWAK_2PHP.State(), value: F32) -> SWAK_2PHP.State() & Maybe<&2, F32>:
  Filters.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, state, value)

def SWAK_2PHP.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~SWAK_2PHP.State(), ~Params.Error, ~SWAK_2PHP.next, xs, SWAK_2PHP.init(period))

def SWAK_BP.State() -> Data:
  Filters.State<F32>

def SWAK_BP.init(+period: U32, +delta: F32) -> Result<&2, &1, Params.Error, SWAK_BP.State()>:
  overlap.init(~SWAK_BP.State(), Bool.and(filter.valid(period, 5, 2000), Bool.and(is_finite(delta), Bool.and(F32.is_ge(delta, 0.05), F32.is_le(delta, 0.5)))), u => Filters.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sin, ~F32.cos, ~F32.sqrt, ~F32.atan, 3, period, delta))

def SWAK_BP.next(state: SWAK_BP.State(), value: F32) -> SWAK_BP.State() & Maybe<&2, F32>:
  Filters.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, state, value)

def SWAK_BP.batch(xs: List<&2, F32>, period: U32, +delta: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~SWAK_BP.State(), ~Params.Error, ~SWAK_BP.next, xs, SWAK_BP.init(period, delta))

def SWAK_HP.State() -> Data:
  Filters.State<F32>

def SWAK_HP.init(+period: U32) -> Result<&2, &1, Params.Error, SWAK_HP.State()>:
  overlap.init(~SWAK_HP.State(), filter.valid(period, 5, 100000), u => Filters.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sin, ~F32.cos, ~F32.sqrt, ~F32.atan, 4, period, 0.0))

def SWAK_HP.next(state: SWAK_HP.State(), value: F32) -> SWAK_HP.State() & Maybe<&2, F32>:
  Filters.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, state, value)

def SWAK_HP.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~SWAK_HP.State(), ~Params.Error, ~SWAK_HP.next, xs, SWAK_HP.init(period))
