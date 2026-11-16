import Base
import ./core/rolling_average.bend as Average
import ./core/variable_shared.bend as VariableShared
import ./core/clone.bend as Clone
import ./core/lookback.bend as Lookbacks
import ./core/extrema_queue.bend as RangeQueue
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

def Bar.HL() -> Data:
  Bars.HL<F32>

def Bar.hl(high: F32, low: F32) -> Bar.HL():
  Bars.HL{high, low}

def Bar.HLC() -> Data:
  Bars.HLC<F32>

def Bar.hlc(high: F32, low: F32, close: F32) -> Bar.HLC():
  Bars.HLC{high, low, close}

def Bar.HLV() -> Data:
  Bars.HLV<F32>

def Bar.hlv(high: F32, low: F32, volume: F32) -> Bar.HLV():
  Bars.HLV{high, low, volume}

def Bar.CV() -> Data:
  Bars.CV<F32>

def Bar.cv(close: F32, volume: F32) -> Bar.CV():
  Bars.CV{close, volume}

def Bar.HLCV() -> Data:
  Bars.HLCV<F32>

def Bar.hlcv(high: F32, low: F32, close: F32, volume: F32) -> Bar.HLCV():
  Bars.HLCV{high, low, close, volume}

def Bar.OHLC() -> Data:
  Bars.OHLC<F32>

def Bar.ohlc(open: F32, high: F32, low: F32, close: F32) -> Bar.OHLC():
  Bars.OHLC{open, high, low, close}

def Bar.valid(bar: Bar.OHLC()) -> Bool:
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

def parameters.CMF(+period: U32) -> Bool:
  Bool.and(Params.period(period), U32.is_ge(period, 2))

def CMF.init(+period: U32) -> Result<&2, &1, Params.Error, CMF.State()>:
  volume.CMF.valid(period, parameters.CMF(period))

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

def parameters.EFI(+period: U32) -> Bool:
  Bool.and(Params.period(period), U32.is_ge(period, 1))

def EFI.init(+period: U32) -> Result<&2, &1, Params.Error, EFI.State()>:
  volume.EFI.valid(period, parameters.EFI(period))

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

def parameters.ADR(+period: U32) -> Bool:
  Bool.and(Params.period(period), U32.is_ge(period, 1))

def ADR.init(+period: U32) -> Result<&2, &1, Params.Error, ADR.State()>:
  volume.ADR.valid(period, parameters.ADR(period))

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

def parameters.ATR(+period: U32) -> Bool:
  Bool.and(Params.period(period), U32.is_ge(period, 1))

def ATR.init(+period: U32) -> Result<&2, &1, Params.Error, ATR.State()>:
  volume.ATR.valid(period, parameters.ATR(period))

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

def parameters.NATR(+period: U32) -> Bool:
  Bool.and(Params.period(period), U32.is_ge(period, 1))

def NATR.init(+period: U32) -> Result<&2, &1, Params.Error, NATR.State()>:
  volume.NATR.valid(period, parameters.NATR(period))

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

def parameters.EMV(+period: U32, +divisor: F32) -> Bool:
  Bool.and(Params.period(period), Bool.and(is_finite(divisor), Bool.and(F32.is_ge(divisor, 1.0), F32.is_le(divisor, 3.0e37))))

def EMV.init(+period: U32, +divisor: F32) -> Result<&2, &1, Params.Error, EMV.State()>:
  volume.EMV.valid(period, divisor, parameters.EMV(period, divisor))

def EMV.next(state: EMV.State(), bar: Bars.HLV<F32>) -> EMV.State() & Maybe<&2, F32>:
  Volume.ease.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.abs, ~F32.is_le, state, bar)

def EMV.batch(xs: List<&2, Bars.HLV<F32>>, period: U32, divisor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLV<F32>, ~F32, ~EMV.State(), ~Params.Error, ~EMV.next, xs, EMV.init(period, divisor))

def CVI.State() -> Type:
  Volatility.Cvi<F32>

def volume.CVI.valid(period: U32, +lag: U32, valid: Bool) -> Result<&2, &1, Params.Error, CVI.State()>:
  match valid:
    case False{}: Fail{Params.InvalidParameter{}}
    case True{}: Done{Volatility.cvi.init(~F32, ~U32.to_f32, ~F32.div, period, lag, volume.depth(lag))}

def parameters.CVI(+period: U32, +lag: U32) -> Bool:
  Bool.and(Params.periods([period, lag]), U32.is_ge(period, 2))

def CVI.init(+period: U32, +lag: U32) -> Result<&2, &1, Params.Error, CVI.State()>:
  volume.CVI.valid(period, lag, parameters.CVI(period, lag))

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

def parameters.MASSI(+fast: U32, +slow: U32) -> Bool:
  Bool.and(Params.periods([fast, slow]), Bool.and(U32.is_ge(fast, 2), U32.is_ge(slow, 2)))

def MASSI.init(+fast: U32, +slow: U32) -> Result<&2, &1, Params.Error, MASSI.State()>:
  volume.MASSI.valid(fast, slow, parameters.MASSI(fast, slow))

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

def parameters.VIDYA(+period: U32, +cmo: U32) -> Bool:
  Bool.and(Params.periods([period, cmo]), U32.is_ge(cmo, 2))

def VIDYA.init(+period: U32, +cmo: U32) -> Result<&2, &1, Params.Error, VIDYA.State()>:
  vidya.init.checked(period, cmo, parameters.VIDYA(period, cmo))

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

def parameters.MAMA(+fast: F32, +slow: F32) -> Bool:
  Bool.and(Bool.and(is_finite(fast), is_finite(slow)),
    Bool.and(Bool.and(F32.is_ge(fast, 0.01), F32.is_le(fast, 0.99)), Bool.and(F32.is_ge(slow, 0.01), F32.is_le(slow, 0.99))))

def MAMA.init(+fast: F32, +slow: F32) -> Result<&2, &1, MAMA.Error(), MAMA.State()>:
  MAMA.init.checked(fast, slow, parameters.MAMA(fast, slow))

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

def parameters.T3(+period: U32, +factor: F32) -> Bool:
  Bool.and(overlap.valid(period, 1), Bool.and(is_finite(factor), Bool.and(F32.is_ge(factor, 0.0), F32.is_le(factor, 1.0))))

def T3.init(+period: U32, +factor: F32) -> Result<&2, &1, Params.Error, T3.State()>:
  overlap.init(~T3.State(), parameters.T3(period, factor), u => Ma.make(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Ma.buffer_depth(period), 8, factor))

def T3.next(state: T3.State(), price: F32) -> T3.State() & Maybe<&2, F32>:
  MA.next(state, price)

def T3.batch(xs: List<&2, F32>, period: U32, factor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~T3.State(), ~Params.Error, ~T3.next, xs, T3.init(period, factor))

def ALMA.State() -> Type:
  MA.State()

def parameters.ALMA(+period: U32, +sigma: F32, +offset: F32) -> Bool:
  Bool.and(overlap.valid(period, 1), Bool.and(Bool.and(is_finite(sigma), Bool.and(F32.is_ge(sigma, 0.01), F32.is_le(sigma, 3.0e37))), Bool.and(is_finite(offset), Bool.and(F32.is_ge(offset, 0.0), F32.is_le(offset, 1.0)))))

def ALMA.init(+period: U32, +sigma: F32, +offset: F32) -> Result<&2, &1, Params.Error, ALMA.State()>:
  overlap.init(~ALMA.State(), parameters.ALMA(period, sigma, offset), u => Ma.gaussian.make(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Ma.buffer_depth(period), sigma, offset))

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
  Average.State<F32>

def LINEARREG.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG.State()>:
  overlap.init(~LINEARREG.State(), overlap.valid(period, 2), u => Statistics.regress.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def LINEARREG.next(state: LINEARREG.State(), price: F32) -> LINEARREG.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG, Statistics.regress.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price))

def LINEARREG.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG.State(), ~Params.Error, ~LINEARREG.next, xs, LINEARREG.init(period))

def stats.LINEARREG_SLOPE(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: slope

def LINEARREG_SLOPE.State() -> Type:
  Average.State<F32>

def LINEARREG_SLOPE.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG_SLOPE.State()>:
  overlap.init(~LINEARREG_SLOPE.State(), overlap.valid(period, 2), u => Statistics.regress.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def LINEARREG_SLOPE.next(state: LINEARREG_SLOPE.State(), price: F32) -> LINEARREG_SLOPE.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG_SLOPE.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG_SLOPE, Statistics.regress.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price))

def LINEARREG_SLOPE.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG_SLOPE.State(), ~Params.Error, ~LINEARREG_SLOPE.next, xs, LINEARREG_SLOPE.init(period))

def stats.LINEARREG_INTERCEPT(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: intercept

def LINEARREG_INTERCEPT.State() -> Type:
  Average.State<F32>

def LINEARREG_INTERCEPT.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG_INTERCEPT.State()>:
  overlap.init(~LINEARREG_INTERCEPT.State(), overlap.valid(period, 2), u => Statistics.regress.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def LINEARREG_INTERCEPT.next(state: LINEARREG_INTERCEPT.State(), price: F32) -> LINEARREG_INTERCEPT.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG_INTERCEPT.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG_INTERCEPT, Statistics.regress.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price))

def LINEARREG_INTERCEPT.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG_INTERCEPT.State(), ~Params.Error, ~LINEARREG_INTERCEPT.next, xs, LINEARREG_INTERCEPT.init(period))

def stats.LINEARREG_ANGLE(value: Statistics.Regression<F32>) -> F32:
  Statistics.angle(~F32, ~U32.to_f32, ~F32.mul, ~F32.div, ~F32.atan, value)

def LINEARREG_ANGLE.State() -> Type:
  Average.State<F32>

def LINEARREG_ANGLE.init(+period: U32) -> Result<&2, &1, Params.Error, LINEARREG_ANGLE.State()>:
  overlap.init(~LINEARREG_ANGLE.State(), overlap.valid(period, 2), u => Statistics.regress.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def LINEARREG_ANGLE.next(state: LINEARREG_ANGLE.State(), price: F32) -> LINEARREG_ANGLE.State() & Maybe<&2, F32>:
  overlap.project(~LINEARREG_ANGLE.State(), ~Statistics.Regression<F32>, ~F32, ~stats.LINEARREG_ANGLE, Statistics.regress.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price))

def LINEARREG_ANGLE.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~LINEARREG_ANGLE.State(), ~Params.Error, ~LINEARREG_ANGLE.next, xs, LINEARREG_ANGLE.init(period))

def stats.TSF(value: Statistics.Regression<F32>) -> F32:
  match value:
    case Statistics.Regression{intercept, slope, endpoint, forecast}: forecast

def TSF.State() -> Type:
  Average.State<F32>

def TSF.init(+period: U32) -> Result<&2, &1, Params.Error, TSF.State()>:
  overlap.init(~TSF.State(), overlap.valid(period, 2), u => Statistics.regress.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def TSF.next(state: TSF.State(), price: F32) -> TSF.State() & Maybe<&2, F32>:
  overlap.project(~TSF.State(), ~Statistics.Regression<F32>, ~F32, ~stats.TSF, Statistics.regress.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price))

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
  overlap.init(~MAX.State(), overlap.valid(period, 2), u => Statistics.extreme.init(~F32, ~U32.to_f32, period, Config.depth(period)))

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
  overlap.init(~MIN.State(), overlap.valid(period, 2), u => Statistics.extreme.init(~F32, ~U32.to_f32, period, Config.depth(period)))

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
  overlap.init(~MAXINDEX.State(), overlap.valid(period, 2), u => Statistics.extreme.init(~F32, ~U32.to_f32, period, Config.depth(period)))

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
  overlap.init(~MININDEX.State(), overlap.valid(period, 2), u => Statistics.extreme.init(~F32, ~U32.to_f32, period, Config.depth(period)))

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
  overlap.init(~MINMAX.State(), overlap.valid(period, 2), u => Statistics.extreme.init(~F32, ~U32.to_f32, period, Config.depth(period)))

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
  overlap.init(~MINMAXINDEX.State(), overlap.valid(period, 2), u => Statistics.extreme.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def MINMAXINDEX.next(state: MINMAXINDEX.State(), price: F32) -> MINMAXINDEX.State() & Maybe<&2, MINMAXINDEX.Value()>:
  overlap.project(~MINMAXINDEX.State(), ~Statistics.Extrema<F32>, ~MINMAXINDEX.Value(), ~stats.MINMAXINDEX, Statistics.extreme.next(~F32, ~F32.is_le, state, price))

def MINMAXINDEX.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MINMAXINDEX.Value()>>>:
  Series.initialized(~F32, ~MINMAXINDEX.Value(), ~MINMAXINDEX.State(), ~Params.Error, ~MINMAXINDEX.next, xs, MINMAXINDEX.init(period))

def MEDIAN.State() -> Type:
  Window.State()

def parameters.MEDIAN(+period: U32) -> Bool:
  Bool.and(overlap.valid(period, 2), U32.is_le(period, 10000))

def MEDIAN.init(+period: U32) -> Result<&2, &1, Params.Error, MEDIAN.State()>:
  overlap.init(~MEDIAN.State(), parameters.MEDIAN(period), u => overlap.window(period))

def MEDIAN.next(state: MEDIAN.State(), price: F32) -> MEDIAN.State() & Maybe<&2, F32>:
  Statistics.quantile.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_le, state, price, 50.0)

def MEDIAN.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~MEDIAN.State(), ~Params.Error, ~MEDIAN.next, xs, MEDIAN.init(period))

def PERCENTRANK.State() -> Type:
  Window.State()

def parameters.PERCENTRANK(+period: U32) -> Bool:
  Bool.and(overlap.valid(period, 2), U32.is_le(period, 10000))

def PERCENTRANK.init(+period: U32) -> Result<&2, &1, Params.Error, PERCENTRANK.State()>:
  overlap.init(~PERCENTRANK.State(), parameters.PERCENTRANK(period), u => overlap.window(period))

def PERCENTRANK.next(state: PERCENTRANK.State(), price: F32) -> PERCENTRANK.State() & Maybe<&2, F32>:
  Statistics.rank.next(~F32, ~U32.to_f32, ~F32.mul, ~F32.div, ~F32.is_lt, state, price)

def PERCENTRANK.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PERCENTRANK.State(), ~Params.Error, ~PERCENTRANK.next, xs, PERCENTRANK.init(period))

def AVGDEV.State() -> Type:
  Window.State()

def parameters.AVGDEV(+period: U32) -> Bool:
  Bool.and(overlap.valid(period, 2), U32.is_le(period, 100000))

def AVGDEV.init(+period: U32) -> Result<&2, &1, Params.Error, AVGDEV.State()>:
  overlap.init(~AVGDEV.State(), parameters.AVGDEV(period), u => overlap.window(period))

def AVGDEV.next(state: AVGDEV.State(), price: F32) -> AVGDEV.State() & Maybe<&2, F32>:
  Statistics.deviation.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, ~F32.abs, state, price)

def AVGDEV.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~AVGDEV.State(), ~Params.Error, ~AVGDEV.next, xs, AVGDEV.init(period))

def STDDEV.State() -> Type:
  Statistics.Standard<F32>

def parameters.STDDEV(+period: U32, +factor: F32) -> Bool:
  Bool.and(overlap.valid(period, 2), Bool.and(is_finite(factor), F32.is_le(F32.abs(factor), 3.0e37)))

def STDDEV.init(+period: U32, +factor: F32) -> Result<&2, &1, Params.Error, STDDEV.State()>:
  overlap.init(~STDDEV.State(), parameters.STDDEV(period, factor), u => Statistics.Standard{Stats.cached.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)), factor})

def STDDEV.next(state: STDDEV.State(), price: F32) -> STDDEV.State() & Maybe<&2, F32>:
  Statistics.standard.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.abs, ~F32.is_le, state, price)

def STDDEV.batch(xs: List<&2, F32>, period: U32, factor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~STDDEV.State(), ~Params.Error, ~STDDEV.next, xs, STDDEV.init(period, factor))

def PERCENTILE.State() -> Type:
  Statistics.ParameterWindow<F32>

def parameters.PERCENTILE(+period: U32, +percent: F32) -> Bool:
  Bool.and(overlap.valid(period, 2), Bool.and(U32.is_le(period, 10000), Bool.and(is_finite(percent), Bool.and(F32.is_ge(percent, 0.0), F32.is_le(percent, 100.0)))))

def PERCENTILE.init(+period: U32, +percent: F32) -> Result<&2, &1, Params.Error, PERCENTILE.State()>:
  overlap.init(~PERCENTILE.State(), parameters.PERCENTILE(period, percent), u => Statistics.ParameterWindow{overlap.window(period), percent})

def PERCENTILE.next(state: PERCENTILE.State(), price: F32) -> PERCENTILE.State() & Maybe<&2, F32>:
  Statistics.percentile.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_le, state, price)

def PERCENTILE.batch(xs: List<&2, F32>, period: U32, percent: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PERCENTILE.State(), ~Params.Error, ~PERCENTILE.next, xs, PERCENTILE.init(period, percent))

def stats.midpoint(value: RangeQueue.Value<F32>) -> F32:
  Overlap.midpoint.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.div, value)

def MIDPOINT.State() -> Type:
  RangeQueue.State<F32>

def MIDPOINT.init(+period: U32) -> Result<&2, &1, Params.Error, MIDPOINT.State()>:
  overlap.init(~MIDPOINT.State(), overlap.valid(period, 2), u => RangeQueue.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def MIDPOINT.next(state: MIDPOINT.State(), price: F32) -> MIDPOINT.State() & Maybe<&2, F32>:
  +value = price
  overlap.project(~MIDPOINT.State(), ~RangeQueue.Value<F32>, ~F32, ~stats.midpoint, RangeQueue.next(~F32, ~F32.is_le, ~F32.is_gt, state, value, value))

def MIDPOINT.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~MIDPOINT.State(), ~Params.Error, ~MIDPOINT.next, xs, MIDPOINT.init(period))

def overlap.hlwindow(+period: U32) -> RangeQueue.State<F32>:
  RangeQueue.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period))

def DONCHIAN.Value() -> Data:
  Overlap.Bands<F32>

def DONCHIAN.State() -> Type:
  RangeQueue.State<F32>

def DONCHIAN.init(+period: U32) -> Result<&2, &1, Params.Error, DONCHIAN.State()>:
  overlap.init(~DONCHIAN.State(), overlap.valid(period, 2), u => overlap.hlwindow(period))

def DONCHIAN.next(state: DONCHIAN.State(), bar: Bars.HL<F32>) -> DONCHIAN.State() & Maybe<&2, DONCHIAN.Value()>:
  Overlap.channel.next(~F32, ~U32.to_f32, ~F32.add, ~F32.div, ~F32.is_lt, state, bar)

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

def parameters.BBANDS(+period: U32, +up: F32, +down: F32) -> Bool:
  Bool.and(overlap.valid(period, 2), Bool.and(Bool.and(is_finite(up), F32.is_le(F32.abs(up), 3.0e37)), Bool.and(is_finite(down), F32.is_le(F32.abs(down), 3.0e37))))

def BBANDS.init(+period: U32, +up: F32, +down: F32, kind: U32) -> Result<&2, &1, Params.Error, BBANDS.State()>:
  BBANDS.init.checked(period, up, down, kind, parameters.BBANDS(period, up, down))

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
  Overlap.acceleration.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.abs, ~F32.is_le, state, bar)

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

def parameters.KC(+period: U32, +atr_period: U32, +deviation: F32) -> Bool:
  Bool.and(Bool.and(overlap.valid(period, 2), overlap.valid(atr_period, 1)), Bool.and(is_finite(deviation), F32.is_le(F32.abs(deviation), 3.0e37)))

def KC.init(+period: U32, +atr_period: U32, +deviation: F32) -> Result<&2, &1, Params.Error, KC.State()>:
  overlap.init(~KC.State(), parameters.KC(period, atr_period, deviation), u => Overlap.keltner.init(~F32, ~U32.to_f32, ~F32.div, period, atr_period, deviation))

def KC.next(state: KC.State(), bar: Bars.HLC<F32>) -> KC.State() & Maybe<&2, KC.Value()>:
  Overlap.keltner.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, state, bar)

def KC.batch(xs: List<&2, Bars.HLC<F32>>, period: U32, atr_period: U32, deviation: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, KC.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~KC.Value(), ~KC.State(), ~Params.Error, ~KC.next, xs, KC.init(period, atr_period, deviation))

def CKSP.Value() -> Data:
  Overlap.Stops<F32>

def CKSP.State() -> Type:
  Overlap.ChandeKroll<F32>

def parameters.CKSP(+period: U32, +multiplier: F32, +stop_period: U32) -> Bool:
  Bool.and(Bool.and(overlap.valid(period, 2), overlap.valid(stop_period, 1)), Bool.and(is_finite(multiplier), Bool.and(F32.is_ge(multiplier, 0.0), F32.is_le(multiplier, 3.0e37))))

def CKSP.init(+period: U32, +multiplier: F32, +stop_period: U32) -> Result<&2, &1, Params.Error, CKSP.State()>:
  overlap.init(~CKSP.State(), parameters.CKSP(period, multiplier, stop_period), u => Overlap.chande.init(~F32, ~U32.to_f32, ~F32.div, period, Ma.buffer_depth(period), multiplier, stop_period, Ma.buffer_depth(stop_period)))

def CKSP.next(state: CKSP.State(), bar: Bars.HLC<F32>) -> CKSP.State() & Maybe<&2, CKSP.Value()>:
  Overlap.chande.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_lt, ~F32.max, state, bar)

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

def parameters.SI(+limit: F32) -> Bool:
  Bool.and(is_finite(limit), Bool.and(F32.is_ge(limit, 0.00000001), F32.is_le(limit, 30000000000000000000000000000000000000.0)))

def SI.init(+limit: F32) -> Result<&2, &1, Momentum.Error(), SI.State()>:
  Momentum.configure(~SI.State(), parameters.SI(limit), u => Done{MomentumWindow.swing.init(~F32, ~U32.to_f32, limit)})

def SI.next(state: SI.State(), value: Bars.OHLC<F32>) -> SI.State() & Maybe<&2, F32>:
  MomentumWindow.swing.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.max, ~F32.is_eq, state, value, False{})

def SI.batch(xs: List<&2, Bars.OHLC<F32>>, +limit: F32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~SI.State(), ~Momentum.Error(), ~SI.next, xs, SI.init(limit))

def ASI.State() -> Type:
  MomentumWindow.Swing<F32>

def parameters.ASI(+limit: F32) -> Bool:
  Bool.and(is_finite(limit), Bool.and(F32.is_ge(limit, 0.00000001), F32.is_le(limit, 30000000000000000000000000000000000000.0)))

def ASI.init(+limit: F32) -> Result<&2, &1, Momentum.Error(), ASI.State()>:
  Momentum.configure(~ASI.State(), parameters.ASI(limit), u => Done{MomentumWindow.swing.init(~F32, ~U32.to_f32, limit)})

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

def parameters.APO(+fast: U32, +slow: U32, +kind: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Ma.supported(kind))

def APO.init(+fast: U32, +slow: U32, +kind: U32) -> Result<&2, &1, Momentum.Error(), APO.State()>:
  Momentum.configure(~APO.State(), parameters.APO(fast, slow, kind), u => MomentumInit.apo(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, kind))

def APO.next(state: APO.State(), value: F32) -> APO.State() & Maybe<&2, F32>:
  MomentumSmooth.dual.difference(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~Momentum.ppo_zero, MomentumSmooth.dual.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value), False{})

def APO.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +kind: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~APO.State(), ~Momentum.Error(), ~APO.next, xs, APO.init(fast, slow, kind))

def PPO.State() -> Type:
  MomentumSmooth.Dual<F32>

def parameters.PPO(+fast: U32, +slow: U32, +kind: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Ma.supported(kind))

def PPO.init(+fast: U32, +slow: U32, +kind: U32) -> Result<&2, &1, Momentum.Error(), PPO.State()>:
  Momentum.configure(~PPO.State(), parameters.PPO(fast, slow, kind), u => MomentumInit.apo(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, kind))

def PPO.next(state: PPO.State(), value: F32) -> PPO.State() & Maybe<&2, F32>:
  MomentumSmooth.dual.difference(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~Momentum.ppo_zero, MomentumSmooth.dual.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value), True{})

def PPO.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +kind: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~PPO.State(), ~Momentum.Error(), ~PPO.next, xs, PPO.init(fast, slow, kind))

def AO.State() -> Type:
  MomentumSmooth.Dual<F32>

def parameters.AO(+fast: U32, +slow: U32) -> Bool:
  Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2))

def AO.init(+fast: U32, +slow: U32) -> Result<&2, &1, Momentum.Error(), AO.State()>:
  Momentum.configure(~AO.State(), parameters.AO(fast, slow), u => MomentumInit.ao(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow))

def AO.next(state: AO.State(), value: Bars.HL<F32>) -> AO.State() & Maybe<&2, F32>:
  MomentumSmooth.ao.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, ~Momentum.ppo_zero, state, value)

def AO.batch(xs: List<&2, Bars.HL<F32>>, +fast: U32, +slow: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~AO.State(), ~Momentum.Error(), ~AO.next, xs, AO.init(fast, slow))

def AC.State() -> Type:
  MomentumSmooth.MACD<F32>

def parameters.AC(+fast: U32, +slow: U32, +signal: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(signal, 2))

def AC.init(+fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), AC.State()>:
  Momentum.configure(~AC.State(), parameters.AC(fast, slow, signal), u => MomentumInit.ac(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, signal))

def AC.next(state: AC.State(), value: Bars.HL<F32>) -> AC.State() & Maybe<&2, F32>:
  MomentumSmooth.ac.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def AC.batch(xs: List<&2, Bars.HL<F32>>, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~AC.State(), ~Momentum.Error(), ~AC.next, xs, AC.init(fast, slow, signal))

def MACD.State() -> Type:
  MomentumSmooth.MACD<F32>

def parameters.MACD(+fast: U32, +slow: U32, +signal: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(signal, 1))

def MACD.init(+fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), MACD.State()>:
  Momentum.configure(~MACD.State(), parameters.MACD(fast, slow, signal), u => MomentumInit.macd(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, signal))

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

def parameters.STOCH(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Momentum.period(kperiod, 1), Momentum.period(slowk, 1)), Momentum.period(dperiod, 1)), Bool.and(Momentum.selector(slowk, ktype), Momentum.selector(dperiod, dtype)))

def STOCH.init(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), STOCH.State()>:
  Momentum.configure(~STOCH.State(), parameters.STOCH(kperiod, slowk, ktype, dperiod, dtype), u => MomentumInit.stoch(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, slowk, ktype, dperiod, dtype))

def STOCH.next(state: STOCH.State(), value: Bars.HLC<F32>) -> STOCH.State() & Maybe<&2, STOCH.Value()>:
  MomentumSmooth.stoch.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, state, value)

def STOCH.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~STOCH.Value(), ~STOCH.State(), ~Momentum.Error(), ~STOCH.next, xs, STOCH.init(kperiod, slowk, ktype, dperiod, dtype))

def KDJ.State() -> Type:
  MomentumSmooth.Stoch<F32>

def parameters.KDJ(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Momentum.period(kperiod, 1), Momentum.period(slowk, 1)), Momentum.period(dperiod, 1)), Bool.and(Momentum.selector(slowk, ktype), Momentum.selector(dperiod, dtype)))

def KDJ.init(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), KDJ.State()>:
  Momentum.configure(~KDJ.State(), parameters.KDJ(kperiod, slowk, ktype, dperiod, dtype), u => MomentumInit.stoch(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, slowk, ktype, dperiod, dtype))

def KDJ.next(state: KDJ.State(), value: Bars.HLC<F32>) -> KDJ.State() & Maybe<&2, STOCH.Value()>:
  MomentumSmooth.stoch.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, state, value)

def KDJ.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~STOCH.Value(), ~KDJ.State(), ~Momentum.Error(), ~KDJ.next, xs, KDJ.init(kperiod, slowk, ktype, dperiod, dtype))

def STOCHF.State() -> Type:
  MomentumSmooth.Stoch<F32>

def parameters.STOCHF(+kperiod: U32, +dperiod: U32, +dtype: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(kperiod, 1), Momentum.period(dperiod, 1)), Momentum.selector(dperiod, dtype))

def STOCHF.init(+kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), STOCHF.State()>:
  Momentum.configure(~STOCHF.State(), parameters.STOCHF(kperiod, dperiod, dtype), u => MomentumInit.stochf(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, dperiod, dtype))

def STOCHF.next(state: STOCHF.State(), value: Bars.HLC<F32>) -> STOCHF.State() & Maybe<&2, STOCH.Value()>:
  MomentumSmooth.stoch.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, state, value)

def STOCHF.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, STOCH.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~STOCH.Value(), ~STOCHF.State(), ~Momentum.Error(), ~STOCHF.next, xs, STOCHF.init(kperiod, dperiod, dtype))

def STOCHRSI.State() -> Type:
  MomentumComposite.StochRSI<F32>

def parameters.STOCHRSI(+period: U32, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(kperiod, 1)), Momentum.period(dperiod, 1)), Momentum.selector(dperiod, dtype))

def STOCHRSI.init(+period: U32, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Result<&2, &1, Momentum.Error(), STOCHRSI.State()>:
  Momentum.configure(~STOCHRSI.State(), parameters.STOCHRSI(period, kperiod, dperiod, dtype), u => MomentumInit.stochrsi(~F32, ~U32.to_f32, ~Momentum.ma, period, kperiod, dperiod, dtype))

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

def parameters.DOSC(+period: U32, +first: U32, +second: U32, +signal: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(first, 2)), Momentum.period(second, 2)), Momentum.period(signal, 2))

def DOSC.init(+period: U32, +first: U32, +second: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), DOSC.State()>:
  Momentum.configure(~DOSC.State(), parameters.DOSC(period, first, second, signal), u => MomentumInit.dosc(~F32, ~U32.to_f32, ~Momentum.ma, period, first, second, signal))

def DOSC.next(state: DOSC.State(), value: F32) -> DOSC.State() & Maybe<&2, F32>:
  MomentumSmooth.dosc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_gt, ~F32.max, ~F32.atan, state, value)

def DOSC.batch(xs: List<&2, F32>, +period: U32, +first: U32, +second: U32, +signal: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~DOSC.State(), ~Momentum.Error(), ~DOSC.next, xs, DOSC.init(period, first, second, signal))

def PSO.State() -> Type:
  MomentumSmooth.Pso<F32>

def parameters.PSO(+kperiod: U32, +period: U32) -> Bool:
  Bool.and(Momentum.period(kperiod, 1), Momentum.period(period, 1))

def PSO.init(+kperiod: U32, +period: U32) -> Result<&2, &1, Momentum.Error(), PSO.State()>:
  Momentum.configure(~PSO.State(), parameters.PSO(kperiod, period), u => MomentumInit.pso(~F32, ~U32.to_f32, ~Momentum.ma, kperiod, period))

def PSO.next(state: PSO.State(), value: Bars.HLC<F32>) -> PSO.State() & Maybe<&2, F32>:
  MomentumSmooth.pso.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_ge, ~F32.atan, ~F32.tanh, state, value)

def PSO.batch(xs: List<&2, Bars.HLC<F32>>, +kperiod: U32, +period: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~PSO.State(), ~Momentum.Error(), ~PSO.next, xs, PSO.init(kperiod, period))

def TSI.State() -> Type:
  MomentumComposite.TSI<F32>

def parameters.TSI(+first: U32, +second: U32) -> Bool:
  Bool.and(Momentum.period(first, 2), Momentum.period(second, 2))

def TSI.init(+first: U32, +second: U32) -> Result<&2, &1, Momentum.Error(), TSI.State()>:
  Momentum.configure(~TSI.State(), parameters.TSI(first, second), u => MomentumInit.tsi(~F32, ~Momentum.ma, first, second))

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
  MomentumComposite.forecast.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.abs, ~F32.is_le, state, value)

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

def parameters.ULTOSC(+first: U32, +second: U32, +third: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(first, 1), Momentum.period(second, 1)), Momentum.period(third, 1))

def ULTOSC.init(+first: U32, +second: U32, +third: U32) -> Result<&2, &1, Momentum.Error(), ULTOSC.State()>:
  Momentum.configure(~ULTOSC.State(), parameters.ULTOSC(first, second, third), u => Done{MomentumInit.ultimate(~F32, ~U32.to_f32, first, second, third)})

def ULTOSC.next(state: ULTOSC.State(), value: Bars.HLC<F32>) -> ULTOSC.State() & Maybe<&2, F32>:
  MomentumComposite.ultimate.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.min, ~F32.max, ~F32.is_gt, state, value)

def ULTOSC.batch(xs: List<&2, Bars.HLC<F32>>, +first: U32, +second: U32, +third: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLC<F32>, ~F32, ~ULTOSC.State(), ~Momentum.Error(), ~ULTOSC.next, xs, ULTOSC.init(first, second, third))

def COPPOCK.State() -> Type:
  MomentumComposite.Roc<F32>

def parameters.COPPOCK(+wma: U32, +first: U32, +second: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(wma, 1), Momentum.period(first, 1)), Momentum.period(second, 1))

def COPPOCK.init(+wma: U32, +first: U32, +second: U32) -> Result<&2, &1, Momentum.Error(), COPPOCK.State()>:
  Momentum.configure(~COPPOCK.State(), parameters.COPPOCK(wma, first, second), u => MomentumInit.coppock(~F32, ~U32.to_f32, ~Momentum.ma, wma, first, second))

def COPPOCK.next(state: COPPOCK.State(), value: F32) -> COPPOCK.State() & Maybe<&2, F32>:
  MomentumComposite.coppock.value(~F32, MomentumComposite.roc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_eq, ~F32.atan, state, value))

def COPPOCK.batch(xs: List<&2, F32>, +wma: U32, +first: U32, +second: U32) -> Result<&2, &2, Momentum.Error(), List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~COPPOCK.State(), ~Momentum.Error(), ~COPPOCK.next, xs, COPPOCK.init(wma, first, second))

def KST.State() -> Type:
  MomentumComposite.Roc<F32>

def parameters.KST(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +sma1: U32, +sma2: U32, +sma3: U32, +sma4: U32, +signal: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(roc1, 1), Momentum.period(roc2, 1)), Momentum.period(roc3, 1)), Momentum.period(roc4, 1)), Momentum.period(sma1, 1)), Momentum.period(sma2, 1)), Momentum.period(sma3, 1)), Momentum.period(sma4, 1)), Momentum.period(signal, 1))

def KST.init(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +sma1: U32, +sma2: U32, +sma3: U32, +sma4: U32, +signal: U32) -> Result<&2, &1, Momentum.Error(), KST.State()>:
  Momentum.configure(~KST.State(), parameters.KST(roc1, roc2, roc3, roc4, sma1, sma2, sma3, sma4, signal), u => MomentumInit.kst(~F32, ~U32.to_f32, ~Momentum.ma, roc1, roc2, roc3, roc4, sma1, sma2, sma3, sma4, signal))

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
  WindowSignals.dpo.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, ~F32.mul, ~F32.abs, ~F32.is_le, state, price)

def DPO.display_shift(period: U32) -> DisplayShift():
  WindowSignals.DisplayShift{True{}, U32.add(U32.div(period, 2), 1)}

def RVOL.State() -> Type:
  Average.State<F32>

def RVOL.init(+period: U32) -> Result<&2, &1, Params.Error, RVOL.State()>:
  overlap.init(~RVOL.State(), Params.period(period), u => Average.init(~F32, ~U32.to_f32, period, Config.depth(period), 0))

def RVOL.next(state: RVOL.State(), volume: F32) -> RVOL.State() & Maybe<&2, F32>:
  WindowSignals.rvol.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, ~F32.mul, ~F32.abs, ~F32.is_le, state, volume)

def ICHIMOKU.State() -> Type:
  WindowSignals.Cloud<F32>

def ICHIMOKU.Value() -> Data:
  WindowSignals.CloudValue<F32>

def parameters.ICHIMOKU(+tenkan: U32, +kijun: U32, +span_b: U32) -> Bool:
  Bool.and(overlap.valid(tenkan, 2), Bool.and(overlap.valid(kijun, 2), overlap.valid(span_b, 2)))

def ICHIMOKU.init(+tenkan: U32, +kijun: U32, +span_b: U32) -> Result<&2, &1, Params.Error, ICHIMOKU.State()>:
  overlap.init(~ICHIMOKU.State(), parameters.ICHIMOKU(tenkan, kijun, span_b), u => WindowSignals.cloud.init(~F32, ~U32.to_f32, tenkan, kijun, span_b))

def ICHIMOKU.next(state: ICHIMOKU.State(), bar: Bars.HL<F32>) -> ICHIMOKU.State() & Maybe<&2, ICHIMOKU.Value()>:
  WindowSignals.cloud.next(~F32, ~U32.to_f32, ~F32.add, ~F32.div, ~F32.is_lt, state, bar)

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

def parameters.ZIGZAG(+sensitivity: F32, +minimum: U32) -> Bool:
  Bool.and(Params.period(minimum), Bool.and(is_finite(sensitivity), Bool.and(F32.is_ge(sensitivity, 0.0), F32.is_le(sensitivity, 100.0))))

def ZIGZAG.init(+sensitivity: F32, +minimum: U32) -> Result<&2, &1, Params.Error, ZIGZAG.State()>:
  overlap.init(~ZIGZAG.State(), parameters.ZIGZAG(sensitivity, minimum), u => MarketState.zigzag.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, sensitivity, minimum))

def ZIGZAG.next(state: ZIGZAG.State(), bar: Bars.HL<F32>) -> ZIGZAG.State() & Maybe<&2, ZIGZAG.Value()>:
  MarketState.zigzag.next(~F32, ~F32.mul, ~F32.min, ~F32.max, ~F32.is_ge, state, bar)

def MAVP.State() -> Type:
  Variable.State<F32>

def MAVP.Sample() -> Data:
  Variable.Sample<F32>

def parameters.MAVP(+minimum: U32, +maximum: U32, +kind: U32) -> Bool:
  Bool.and(Bool.and(U32.is_gt(minimum, 0), U32.is_le(maximum, 10000)), Bool.and(U32.is_le(minimum, maximum), Bool.or(Ma.supported(kind), Bool.and(U32.is_eq(maximum, 1), U32.is_le(kind, 15)))))

def MAVP.init(+minimum: U32, +maximum: U32, +kind: U32) -> Result<&2, &1, Params.Error, MAVP.State()>:
  overlap.init(~MAVP.State(), parameters.MAVP(minimum, maximum, kind), u => Variable.init(~F32, minimum, maximum, kind))

def MAVP.average(+period: U32, kind: U32) -> Ma.State<F32>:
  Ma.make(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, Config.depth(period), kind, 0.7)

def MAVP.weights(period: U32) -> List<&2, F32>:
  Ma.gaussian.coefficients(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.exp, ~F32.floor, period, 6.0, 0.85)

def MAVP.shared(state: VariableShared.State<F32>, price: F32, period: U32) -> VariableShared.State<F32> & Maybe<&2, F32>:
  VariableShared.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~MAVP.weights, state, price, period)

def MAVP.next(state: MAVP.State(), sample: MAVP.Sample()) -> MAVP.State() & Maybe<&2, F32>:
  Variable.next(~F32, ~U32.to_f32, ~F32.to_u32, ~F32.is_ge, ~F32.is_gt, ~(p => k => MAVP.average(p, k)), ~MA.next, ~MAVP.shared, state, sample)

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

def parameters.FRAMA(+period: U32) -> Bool:
  Bool.and(Momentum.period(period, 2), U32.is_zero(U32.mod(period, 2)))

def FRAMA.init(+period: U32) -> Result<&2, &1, Params.Error, FRAMA.State()>:
  Momentum.configure(~FRAMA.State(), parameters.FRAMA(period), u => Done{AdaptiveWindow.frama.init(~F32, ~U32.to_f32, period)})

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

def parameters.SAR(+acceleration: F32, +maximum: F32) -> Bool:
  Bool.and(Trend.nonnegative(acceleration), Trend.nonnegative(maximum))

def SAR.init(+acceleration: F32, +maximum: F32) -> Result<&2, &1, Params.Error, SAR.State()>:
  Momentum.configure(~SAR.State(), parameters.SAR(acceleration, maximum), u => Done{TrendState.sar.init(~F32, ~F32.min, 0.0, 0.0, acceleration, acceleration, maximum, acceleration, acceleration, maximum, False{})})

def SAR.next(state: SAR.State(), value: Bars.HL<F32>) -> SAR.State() & Maybe<&2, F32>:
  TrendState.sar.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.min, ~F32.max, ~F32.is_le, ~F32.is_lt, ~F32.is_eq, ~F32.abs, state, value)

def SAR.batch(xs: List<&2, Bars.HL<F32>>, +acceleration: F32, +maximum: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~SAR.State(), ~Params.Error, ~SAR.next, xs, SAR.init(acceleration, maximum))

def SAREXT.State() -> Type:
  TrendState.Sar<F32>

def parameters.SAREXT(+start: F32, +offset: F32, +long_init: F32, +long_step: F32, +long_max: F32, +short_init: F32, +short_step: F32, +short_max: F32) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(is_finite(start), F32.is_le(F32.abs(start), 3.0e37)), Trend.nonnegative(offset)), Trend.nonnegative(long_init)), Trend.nonnegative(long_step)), Trend.nonnegative(long_max)), Trend.nonnegative(short_init)), Trend.nonnegative(short_step)), Trend.nonnegative(short_max))

def SAREXT.init(+start: F32, +offset: F32, +long_init: F32, +long_step: F32, +long_max: F32, +short_init: F32, +short_step: F32, +short_max: F32) -> Result<&2, &1, Params.Error, SAREXT.State()>:
  Momentum.configure(~SAREXT.State(), parameters.SAREXT(start, offset, long_init, long_step, long_max, short_init, short_step, short_max), u => Done{TrendState.sar.init(~F32, ~F32.min, start, offset, long_init, long_step, long_max, short_init, short_step, short_max, True{})})

def SAREXT.next(state: SAREXT.State(), value: Bars.HL<F32>) -> SAREXT.State() & Maybe<&2, F32>:
  TrendState.sar.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.min, ~F32.max, ~F32.is_le, ~F32.is_lt, ~F32.is_eq, ~F32.abs, state, value)

def SAREXT.batch(xs: List<&2, Bars.HL<F32>>, +start: F32, +offset: F32, +long_init: F32, +long_step: F32, +long_max: F32, +short_init: F32, +short_step: F32, +short_max: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HL<F32>, ~F32, ~SAREXT.State(), ~Params.Error, ~SAREXT.next, xs, SAREXT.init(start, offset, long_init, long_step, long_max, short_init, short_step, short_max))

def SUPERTREND.State() -> Type:
  TrendState.Supertrend<F32>

def SUPERTREND.Value() -> Data:
  TrendState.TrendValue<F32>

def parameters.SUPERTREND(+period: U32, +multiplier: F32) -> Bool:
  Bool.and(Momentum.period(period, 2), Trend.nonnegative(multiplier))

def SUPERTREND.init(+period: U32, +multiplier: F32) -> Result<&2, &1, Params.Error, SUPERTREND.State()>:
  Momentum.configure(~SUPERTREND.State(), parameters.SUPERTREND(period, multiplier), u => Done{TrendState.supertrend.init(~F32, ~U32.to_f32, ~F32.div, period, multiplier)})

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

def parameters.CRSI(+period: U32, +streak: U32, +rank: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(streak, 2)), Momentum.period(rank, 2)), U32.is_le(rank, 10000))

def CRSI.init(+period: U32, +streak: U32, +rank: U32) -> Result<&2, &1, Params.Error, CRSI.State()>:
  Momentum.configure(~CRSI.State(), parameters.CRSI(period, streak, rank), u => Done{AdvancedOscillator.crsi.init(~F32, ~U32.to_f32, period, streak, rank)})

def CRSI.next(state: CRSI.State(), value: F32) -> CRSI.State() & Maybe<&2, F32>:
  AdvancedOscillator.crsi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.max, ~F32.is_lt, ~F32.is_eq, state, value)

def CRSI.batch(xs: List<&2, F32>, +period: U32, +streak: U32, +rank: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~CRSI.State(), ~Params.Error, ~CRSI.next, xs, CRSI.init(period, streak, rank))

def SMI.State() -> Type:
  AdvancedOscillator.Smi<F32>

def SMI.Value() -> Data:
  MomentumSmooth.Lines<F32>

def parameters.SMI(+period: U32, +fast: U32, +slow: U32, +signal: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Momentum.period(period, 2), Momentum.period(fast, 2)), Momentum.period(slow, 2)), Momentum.period(signal, 2))

def SMI.init(+period: U32, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Params.Error, SMI.State()>:
  Momentum.configure(~SMI.State(), parameters.SMI(period, fast, slow, signal), u => Done{AdvancedOscillator.smi.init(~F32, ~U32.to_f32, ~F32.div, period, fast, slow, signal)})

def SMI.next(state: SMI.State(), value: Bars.HLC<F32>) -> SMI.State() & Maybe<&2, SMI.Value()>:
  AdvancedOscillator.smi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_le, state, value)

def SMI.batch(xs: List<&2, Bars.HLC<F32>>, +period: U32, +fast: U32, +slow: U32, +signal: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, SMI.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~SMI.Value(), ~SMI.State(), ~Params.Error, ~SMI.next, xs, SMI.init(period, fast, slow, signal))

def STC.State() -> Type:
  AdvancedOscillator.Stc<F32>

def parameters.STC(+fast: U32, +slow: U32, +cycle: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(cycle, 2))

def STC.init(+fast: U32, +slow: U32, +cycle: U32) -> Result<&2, &1, Params.Error, STC.State()>:
  Momentum.configure(~STC.State(), parameters.STC(fast, slow, cycle), u => AdvancedOscillator.stc.init(~F32, ~U32.to_f32, ~Momentum.ma, fast, slow, cycle))

def STC.next(state: STC.State(), value: F32) -> STC.State() & Maybe<&2, F32>:
  AdvancedOscillator.stc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_eq, ~F32.is_le, ~F32.atan, state, value)

def STC.batch(xs: List<&2, F32>, +fast: U32, +slow: U32, +cycle: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~STC.State(), ~Params.Error, ~STC.next, xs, STC.init(fast, slow, cycle))

def WAVETREND.State() -> Type:
  AdvancedOscillator.Wave<F32>

def WAVETREND.Value() -> Data:
  MomentumSmooth.Lines<F32>

def parameters.WAVETREND(+channel: U32, +average: U32, +signal: U32) -> Bool:
  Bool.and(Bool.and(Momentum.period(channel, 2), Momentum.period(average, 1)), Momentum.period(signal, 1))

def WAVETREND.init(+channel: U32, +average: U32, +signal: U32) -> Result<&2, &1, Params.Error, WAVETREND.State()>:
  Momentum.configure(~WAVETREND.State(), parameters.WAVETREND(channel, average, signal), u => Done{AdvancedOscillator.wave.init(~F32, ~U32.to_f32, ~F32.div, channel, average, signal)})

def WAVETREND.next(state: WAVETREND.State(), value: Bars.HLC<F32>) -> WAVETREND.State() & Maybe<&2, WAVETREND.Value()>:
  AdvancedOscillator.wave.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_eq, ~F32.is_le, state, value)

def WAVETREND.batch(xs: List<&2, Bars.HLC<F32>>, +channel: U32, +average: U32, +signal: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, WAVETREND.Value()>>>:
  Series.initialized(~Bars.HLC<F32>, ~WAVETREND.Value(), ~WAVETREND.State(), ~Params.Error, ~WAVETREND.next, xs, WAVETREND.init(channel, average, signal))

def MACDEXT.State() -> Type:
  TrendComposite.Macd<F32>

def MACDEXT.Value() -> Data:
  MomentumSmooth.MACDValue<F32>

def parameters.MACDEXT(+fast: U32, +fast_kind: U32, +slow: U32, +slow_kind: U32, +signal: U32, +signal_kind: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(fast, 2), Momentum.period(slow, 2)), Momentum.period(signal, 1)), Momentum.selector(fast, fast_kind)), Momentum.selector(slow, slow_kind)), Momentum.selector(signal, signal_kind))

def MACDEXT.init(+fast: U32, +fast_kind: U32, +slow: U32, +slow_kind: U32, +signal: U32, +signal_kind: U32) -> Result<&2, &1, Params.Error, MACDEXT.State()>:
  Momentum.configure(~MACDEXT.State(), parameters.MACDEXT(fast, fast_kind, slow, slow_kind, signal, signal_kind), u => TrendComposite.macd.init(~F32, ~U32.to_f32, ~Momentum.ma, fast, fast_kind, slow, slow_kind, signal, signal_kind))

def MACDEXT.next(state: MACDEXT.State(), value: F32) -> MACDEXT.State() & Maybe<&2, MACDEXT.Value()>:
  TrendComposite.macd.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.atan, state, value)

def MACDEXT.batch(xs: List<&2, F32>, +fast: U32, +fast_kind: U32, +slow: U32, +slow_kind: U32, +signal: U32, +signal_kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, MACDEXT.Value()>>>:
  Series.initialized(~F32, ~MACDEXT.Value(), ~MACDEXT.State(), ~Params.Error, ~MACDEXT.next, xs, MACDEXT.init(fast, fast_kind, slow, slow_kind, signal, signal_kind))

def KSTEXT.State() -> Type:
  TrendComposite.Kst<F32>

def KSTEXT.Value() -> Data:
  MomentumSmooth.Lines<F32>

def parameters.KSTEXT(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +ma1: U32, +ma2: U32, +ma3: U32, +ma4: U32, +signal: U32, +kind: U32, +signal_kind: U32) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(roc1, 1), Momentum.period(roc2, 1)), Momentum.period(roc3, 1)), Momentum.period(roc4, 1)), Momentum.period(ma1, 1)), Momentum.period(ma2, 1)), Momentum.period(ma3, 1)), Momentum.period(ma4, 1)), Momentum.period(signal, 1)), Momentum.selector(ma1, kind)), Momentum.selector(ma2, kind)), Momentum.selector(ma3, kind)), Momentum.selector(ma4, kind)), Momentum.selector(signal, signal_kind))

def KSTEXT.init(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +ma1: U32, +ma2: U32, +ma3: U32, +ma4: U32, +signal: U32, +kind: U32, +signal_kind: U32) -> Result<&2, &1, Params.Error, KSTEXT.State()>:
  Momentum.configure(~KSTEXT.State(), parameters.KSTEXT(roc1, roc2, roc3, roc4, ma1, ma2, ma3, ma4, signal, kind, signal_kind), u => TrendComposite.kst.init(~F32, ~U32.to_f32, ~Momentum.ma, roc1, roc2, roc3, roc4, ma1, ma2, ma3, ma4, signal, kind, signal_kind))

def KSTEXT.next(state: KSTEXT.State(), value: F32) -> KSTEXT.State() & Maybe<&2, KSTEXT.Value()>:
  TrendComposite.kst.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, ~F32.is_eq, ~F32.atan, state, value)

def KSTEXT.batch(xs: List<&2, F32>, +roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +ma1: U32, +ma2: U32, +ma3: U32, +ma4: U32, +signal: U32, +kind: U32, +signal_kind: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, KSTEXT.Value()>>>:
  Series.initialized(~F32, ~KSTEXT.Value(), ~KSTEXT.State(), ~Params.Error, ~KSTEXT.next, xs, KSTEXT.init(roc1, roc2, roc3, roc4, ma1, ma2, ma3, ma4, signal, kind, signal_kind))

def SQZMOM.State() -> Type:
  Squeeze.State<F32>

def SQZMOM.Value() -> Data:
  Squeeze.Value<F32>

def parameters.SQZMOM(+bb: U32, +deviations: F32, +kc: U32, +wide: F32, +normal: F32, +narrow: F32) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Bool.and(Momentum.period(bb, 2), Momentum.period(kc, 2)), Trend.nonnegative(deviations)), Trend.nonnegative(wide)), Trend.nonnegative(normal)), Trend.nonnegative(narrow)), F32.is_le(narrow, normal)), F32.is_le(normal, wide))

def SQZMOM.init(+bb: U32, +deviations: F32, +kc: U32, +wide: F32, +normal: F32, +narrow: F32) -> Result<&2, &1, Params.Error, SQZMOM.State()>:
  Momentum.configure(~SQZMOM.State(), parameters.SQZMOM(bb, deviations, kc, wide, normal, narrow), u => Done{Squeeze.init(~F32, ~U32.to_f32, bb, kc, deviations, wide, normal, narrow)})

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

def parameters.ADOSC(+fast: U32, +slow: U32) -> Bool:
  Bool.and(overlap.valid(fast, 2), overlap.valid(slow, 2))

def ADOSC.init(+fast: U32, +slow: U32) -> Result<&2, &1, Params.Error, ADOSC.State()>:
  overlap.init(~ADOSC.State(), parameters.ADOSC(fast, slow), u => VolumeFilter.adosc.init(~F32, ~U32.to_f32, ~F32.div, fast, slow))

def ADOSC.next(state: ADOSC.State(), value: Bars.HLCV<F32>) -> ADOSC.State() & Maybe<&2, F32>:
  VolumeFilter.adosc.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_gt, state, value)

def ADOSC.batch(xs: List<&2, Bars.HLCV<F32>>, fast: U32, slow: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.HLCV<F32>, ~F32, ~ADOSC.State(), ~Params.Error, ~ADOSC.next, xs, ADOSC.init(fast, slow))

def KVO.State() -> Type:
  VolumeFilter.Kvo<F32>

def parameters.KVO(+fast: U32, +slow: U32, +signal: U32) -> Bool:
  Bool.and(overlap.valid(fast, 2), Bool.and(overlap.valid(slow, 2), overlap.valid(signal, 2)))

def KVO.init(+fast: U32, +slow: U32, +signal: U32) -> Result<&2, &1, Params.Error, KVO.State()>:
  overlap.init(~KVO.State(), parameters.KVO(fast, slow, signal), u => VolumeFilter.kvo.init(~F32, ~U32.to_f32, ~F32.div, fast, slow, signal))

def KVO.next(state: KVO.State(), value: Bars.HLCV<F32>) -> KVO.State() & Maybe<&2, KVO.Value()>:
  VolumeFilter.kvo.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_eq, ~F32.is_gt, state, value)

def KVO.batch(xs: List<&2, Bars.HLCV<F32>>, fast: U32, slow: U32, signal: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, KVO.Value()>>>:
  Series.initialized(~Bars.HLCV<F32>, ~KVO.Value(), ~KVO.State(), ~Params.Error, ~KVO.next, xs, KVO.init(fast, slow, signal))

def VAR.State() -> Type:
  Stats.Cached<F32>

def parameters.VAR(+period: U32, +factor: F32) -> Bool:
  Bool.and(overlap.valid(period, 1), Bool.and(is_finite(factor), F32.is_le(F32.abs(factor), 3.0e37)))

def VAR.init(+period: U32, +factor: F32) -> Result<&2, &1, Params.Error, VAR.State()>:
  overlap.init(~VAR.State(), parameters.VAR(period, factor), u => Stats.cached.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)))

def VAR.next(state: VAR.State(), value: F32) -> VAR.State() & Maybe<&2, F32>:
  overlap.project(~VAR.State(), ~Stats.Value<F32>, ~F32, ~(v => StatWindow.variance(~F32, v)), Stats.cached.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, value))

def VAR.batch(xs: List<&2, F32>, period: U32, factor: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~VAR.State(), ~Params.Error, ~VAR.next, xs, VAR.init(period, factor))

def CORREL.State() -> Type:
  StatWindow.PairCached<F32>

def CORREL.init(+period: U32) -> Result<&2, &1, Params.Error, CORREL.State()>:
  overlap.init(~CORREL.State(), overlap.valid(period, 1), u => StatWindow.pair.cached.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)))

def CORREL.next(state: CORREL.State(), value: PairValue()) -> CORREL.State() & Maybe<&2, F32>:
  StatWindow.pair.cached.project(~F32, ~(v => StatWindow.correl.ratio(~F32, ~U32.to_f32, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.min, ~F32.max, ~F32.is_gt, v)), StatWindow.pair.cached.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_le, state, value))

def CORREL.batch(xs: List<&2, PairValue()>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~PairValue(), ~F32, ~CORREL.State(), ~Params.Error, ~CORREL.next, xs, CORREL.init(period))

def BETA.State() -> Type:
  StatWindow.Beta<F32>

def BETA.init(+period: U32) -> Result<&2, &1, Params.Error, BETA.State()>:
  overlap.init(~BETA.State(), overlap.valid(period, 1), u => StatWindow.beta.init(~F32, ~U32.to_f32, period, Ma.buffer_depth(period)))

def BETA.next(state: BETA.State(), value: PairValue()) -> BETA.State() & Maybe<&2, F32>:
  StatWindow.beta.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.is_eq, ~F32.is_gt, ~F32.is_le, state, value)

def BETA.batch(xs: List<&2, PairValue()>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~PairValue(), ~F32, ~BETA.State(), ~Params.Error, ~BETA.next, xs, BETA.init(period))

def KURTOSIS.State() -> Type:
  Win.State<F32>

def parameters.KURTOSIS(+period: U32) -> Bool:
  Bool.and(U32.is_ge(period, 4), U32.is_le(period, 10000))

def KURTOSIS.init(+period: U32) -> Result<&2, &1, Params.Error, KURTOSIS.State()>:
  overlap.init(~KURTOSIS.State(), parameters.KURTOSIS(period), u => overlap.window(period))

def KURTOSIS.next(state: KURTOSIS.State(), value: F32) -> KURTOSIS.State() & Maybe<&2, F32>:
  StatWindow.kurtosis.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, value)

def KURTOSIS.batch(xs: List<&2, F32>, period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~KURTOSIS.State(), ~Params.Error, ~KURTOSIS.next, xs, KURTOSIS.init(period))

def ROGERSSATCHELL.State() -> Type:
  VolWindow.RogersSatchell<F32>

def parameters.ROGERSSATCHELL(+period: U32, +annualization: F32) -> Bool:
  Bool.and(overlap.valid(period, 1), Bool.and(is_finite(annualization), Bool.and(F32.is_ge(annualization, 0.0), F32.is_le(annualization, 3.0e37))))

def ROGERSSATCHELL.init(+period: U32, +annualization: F32) -> Result<&2, &1, Params.Error, ROGERSSATCHELL.State()>:
  overlap.init(~ROGERSSATCHELL.State(), parameters.ROGERSSATCHELL(period, annualization), u => VolWindow.rogerssatchell.init(~F32, ~U32.to_f32, ~F32.sqrt, period, Ma.buffer_depth(period), annualization))

def ROGERSSATCHELL.next(state: ROGERSSATCHELL.State(), value: Bars.OHLC<F32>) -> ROGERSSATCHELL.State() & Maybe<&2, F32>:
  VolWindow.rogerssatchell.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.log, ~F32.is_gt, ~F32.abs, ~F32.is_le, state, value)

def ROGERSSATCHELL.batch(xs: List<&2, Bars.OHLC<F32>>, period: U32, annualization: F32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~Bars.OHLC<F32>, ~F32, ~ROGERSSATCHELL.State(), ~Params.Error, ~ROGERSSATCHELL.next, xs, ROGERSSATCHELL.init(period, annualization))

def RVI.State() -> Type:
  VolWindow.Rvi<F32>

def parameters.RVI(+period: U32, +deviation_period: U32) -> Bool:
  Bool.and(overlap.valid(period, 1), overlap.valid(deviation_period, 2))

def RVI.init(+period: U32, +deviation_period: U32) -> Result<&2, &1, Params.Error, RVI.State()>:
  overlap.init(~RVI.State(), parameters.RVI(period, deviation_period), u => VolWindow.rvi.init(~F32, ~U32.to_f32, ~F32.div, period, deviation_period, Ma.buffer_depth(deviation_period)))

def RVI.next(state: RVI.State(), value: F32) -> RVI.State() & Maybe<&2, F32>:
  VolWindow.rvi.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.is_eq, ~F32.is_gt, ~F32.abs, ~F32.is_le, state, value)

def RVI.batch(xs: List<&2, F32>, period: U32, deviation_period: U32) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>:
  Series.initialized(~F32, ~F32, ~RVI.State(), ~Params.Error, ~RVI.next, xs, RVI.init(period, deviation_period))

def RVIR.State() -> Type:
  VolWindow.Rvir<F32>

def parameters.RVIR(+period: U32, +deviation_period: U32) -> Bool:
  Bool.and(overlap.valid(period, 1), overlap.valid(deviation_period, 2))

def RVIR.init(+period: U32, +deviation_period: U32) -> Result<&2, &1, Params.Error, RVIR.State()>:
  overlap.init(~RVIR.State(), parameters.RVIR(period, deviation_period), u => VolWindow.rvir.init(~F32, ~U32.to_f32, ~F32.div, period, deviation_period, Ma.buffer_depth(deviation_period)))

def RVIR.next(state: RVIR.State(), value: Bars.HL<F32>) -> RVIR.State() & Maybe<&2, F32>:
  VolWindow.rvir.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.is_eq, ~F32.is_gt, ~F32.abs, ~F32.is_le, state, value)

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

def parameters.SWAK_BP(+period: U32, +delta: F32) -> Bool:
  Bool.and(filter.valid(period, 5, 2000), Bool.and(is_finite(delta), Bool.and(F32.is_ge(delta, 0.05), F32.is_le(delta, 0.5))))

def SWAK_BP.init(+period: U32, +delta: F32) -> Result<&2, &1, Params.Error, SWAK_BP.State()>:
  overlap.init(~SWAK_BP.State(), parameters.SWAK_BP(period, delta), u => Filters.init(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sin, ~F32.cos, ~F32.sqrt, ~F32.atan, 3, period, delta))

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

def Lookback.Result() -> Data:
  Result<&2, &2, Params.Error, U32>

def Pattern.lookback.checked(+name: Pattern.Name(), +settings: Pattern.Settings(), penetration: F32) -> Lookback.Result():
  Lookbacks.checked(PatternState.valid(~F32, ~U32.to_f32, ~is_finite, ~F32.is_ge, settings, penetration), Pattern.lookback(name, settings))

def CDLHIKKAKEMOD.lookback.setting(+near: Candles.Setting<F32>) -> Lookback.Result():
  match near:
    case Candles.Setting{range, period, factor}:
      Lookbacks.checked(Patterns.setting.valid(~F32, ~is_finite, ~F32.is_ge, ~U32.to_f32, near), U32.add(U32.max(period, 1), 5))

def AC.lookback(+fast: U32, +slow: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.AC(fast, slow, signal), U32.sub(U32.add(U32.max(fast, slow), signal), 2))

def ACCBANDS.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def ACOS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def AD.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def ADD.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def ADOSC.lookback(+fast: U32, +slow: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.ADOSC(fast, slow), U32.sub(U32.max(fast, slow), 1))

def ADR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.ADR(period), U32.sub(period, 1))

def ADX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(U32.mul(2, period), 1))

def ADXR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(U32.mul(3, period), 2))

def ALMA.lookback(+period: U32, +sigma: F32, +offset: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.ALMA(period, sigma, offset), U32.sub(period, 1))

def AO.lookback(+fast: U32, +slow: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.AO(fast, slow), U32.sub(U32.max(fast, slow), 1))

def APO.lookback(+fast: U32, +slow: U32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.APO(fast, slow, kind), U32.max(Ma.lookback(fast, kind), Ma.lookback(slow, kind)))

def AROON.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def AROONOSC.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def ASI.lookback(+limit: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.ASI(limit), 0)

def ASIN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def ATAN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def ATR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.ATR(period), period)

def AVGDEV.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.AVGDEV(period), U32.sub(period, 1))

def AVGPRICE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def BBANDS.lookback(+period: U32, +up: F32, +down: F32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(parameters.BBANDS(period, up, down), Momentum.selector(period, kind)), U32.max(U32.sub(period, 1), Ma.lookback(period, kind)))

def BBW.lookback(+period: U32, +up: F32, +down: F32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(parameters.BBANDS(period, up, down), Momentum.selector(period, kind)), U32.max(U32.sub(period, 1), Ma.lookback(period, kind)))

def BETA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 1), period)

def BOP.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def CCI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def CDL2CROWS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL2CROWS{}, Pattern.defaults()))

def CDL3BLACKCROWS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL3BLACKCROWS{}, Pattern.defaults()))

def CDL3INSIDE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL3INSIDE{}, Pattern.defaults()))

def CDL3LINESTRIKE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL3LINESTRIKE{}, Pattern.defaults()))

def CDL3OUTSIDE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL3OUTSIDE{}, Pattern.defaults()))

def CDL3STARSINSOUTH.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL3STARSINSOUTH{}, Pattern.defaults()))

def CDL3WHITESOLDIERS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDL3WHITESOLDIERS{}, Pattern.defaults()))

def CDLABANDONEDBABY.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLABANDONEDBABY{}, Pattern.defaults()))

def CDLADVANCEBLOCK.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLADVANCEBLOCK{}, Pattern.defaults()))

def CDLBELTHOLD.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLBELTHOLD{}, Pattern.defaults()))

def CDLBREAKAWAY.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLBREAKAWAY{}, Pattern.defaults()))

def CDLCLOSINGMARUBOZU.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLCLOSINGMARUBOZU{}, Pattern.defaults()))

def CDLCONCEALBABYSWALL.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLCONCEALBABYSWALL{}, Pattern.defaults()))

def CDLCOUNTERATTACK.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLCOUNTERATTACK{}, Pattern.defaults()))

def CDLDARKCLOUDCOVER.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLDARKCLOUDCOVER{}, Pattern.defaults()))

def CDLDOJI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLDOJI{}, Pattern.defaults()))

def CDLDOJISTAR.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLDOJISTAR{}, Pattern.defaults()))

def CDLDRAGONFLYDOJI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLDRAGONFLYDOJI{}, Pattern.defaults()))

def CDLENGULFING.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLENGULFING{}, Pattern.defaults()))

def CDLEVENINGDOJISTAR.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLEVENINGDOJISTAR{}, Pattern.defaults()))

def CDLEVENINGSTAR.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLEVENINGSTAR{}, Pattern.defaults()))

def CDLGAPSIDESIDEWHITE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLGAPSIDESIDEWHITE{}, Pattern.defaults()))

def CDLGRAVESTONEDOJI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLGRAVESTONEDOJI{}, Pattern.defaults()))

def CDLHAMMER.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLHAMMER{}, Pattern.defaults()))

def CDLHANGINGMAN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLHANGINGMAN{}, Pattern.defaults()))

def CDLHARAMI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLHARAMI{}, Pattern.defaults()))

def CDLHARAMICROSS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLHARAMICROSS{}, Pattern.defaults()))

def CDLHIGHWAVE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLHIGHWAVE{}, Pattern.defaults()))

def CDLHIKKAKE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 5)

def CDLHIKKAKEMOD.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 10)

def CDLHOMINGPIGEON.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLHOMINGPIGEON{}, Pattern.defaults()))

def CDLIDENTICAL3CROWS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLIDENTICAL3CROWS{}, Pattern.defaults()))

def CDLINNECK.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLINNECK{}, Pattern.defaults()))

def CDLINVERTEDHAMMER.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLINVERTEDHAMMER{}, Pattern.defaults()))

def CDLKICKING.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLKICKING{}, Pattern.defaults()))

def CDLKICKINGBYLENGTH.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLKICKINGBYLENGTH{}, Pattern.defaults()))

def CDLLADDERBOTTOM.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLLADDERBOTTOM{}, Pattern.defaults()))

def CDLLONGLEGGEDDOJI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLLONGLEGGEDDOJI{}, Pattern.defaults()))

def CDLLONGLINE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLLONGLINE{}, Pattern.defaults()))

def CDLMARUBOZU.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLMARUBOZU{}, Pattern.defaults()))

def CDLMATCHINGLOW.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLMATCHINGLOW{}, Pattern.defaults()))

def CDLMATHOLD.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLMATHOLD{}, Pattern.defaults()))

def CDLMORNINGDOJISTAR.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLMORNINGDOJISTAR{}, Pattern.defaults()))

def CDLMORNINGSTAR.lookback(+penetration: F32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(is_finite(penetration), F32.is_ge(penetration, 0.0)), Pattern.lookback(Patterns.CDLMORNINGSTAR{}, Pattern.defaults()))

def CDLONNECK.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLONNECK{}, Pattern.defaults()))

def CDLPIERCING.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLPIERCING{}, Pattern.defaults()))

def CDLRICKSHAWMAN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLRICKSHAWMAN{}, Pattern.defaults()))

def CDLRISEFALL3METHODS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLRISEFALL3METHODS{}, Pattern.defaults()))

def CDLSEPARATINGLINES.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLSEPARATINGLINES{}, Pattern.defaults()))

def CDLSHOOTINGSTAR.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLSHOOTINGSTAR{}, Pattern.defaults()))

def CDLSHORTLINE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLSHORTLINE{}, Pattern.defaults()))

def CDLSPINNINGTOP.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLSPINNINGTOP{}, Pattern.defaults()))

def CDLSTALLEDPATTERN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLSTALLEDPATTERN{}, Pattern.defaults()))

def CDLSTICKSANDWICH.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLSTICKSANDWICH{}, Pattern.defaults()))

def CDLTAKURI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLTAKURI{}, Pattern.defaults()))

def CDLTASUKIGAP.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLTASUKIGAP{}, Pattern.defaults()))

def CDLTHRUSTING.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLTHRUSTING{}, Pattern.defaults()))

def CDLTRISTAR.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLTRISTAR{}, Pattern.defaults()))

def CDLUNIQUE3RIVER.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLUNIQUE3RIVER{}, Pattern.defaults()))

def CDLUPSIDEGAP2CROWS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLUPSIDEGAP2CROWS{}, Pattern.defaults()))

def CDLXSIDEGAP3METHODS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, Pattern.lookback(Patterns.CDLXSIDEGAP3METHODS{}, Pattern.defaults()))

def CEIL.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def CG.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def CHOP.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def CHOPTR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def CKSP.lookback(+period: U32, +multiplier: F32, +stop_period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.CKSP(period, multiplier, stop_period), U32.sub(U32.add(period, stop_period), 1))

def CMF.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.CMF(period), U32.sub(period, 1))

def CMO.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def CMOU.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def COPPOCK.lookback(+wma: U32, +first: U32, +second: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.COPPOCK(wma, first, second), U32.sub(U32.add(U32.max(first, second), wma), 1))

def CORREL.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 1), U32.sub(period, 1))

def COS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def COSH.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def CRSI.lookback(+period: U32, +streak: U32, +rank: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.CRSI(period, streak, rank), U32.max(U32.max(period, U32.add(streak, 1)), U32.add(rank, 1)))

def CTI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def CUMSUM.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def CVI.lookback(+period: U32, +lag: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.CVI(period, lag), U32.add(U32.sub(period, 1), lag))

def DEMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 3))

def DIV.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def DONCHIAN.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def DOSC.lookback(+period: U32, +first: U32, +second: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.DOSC(period, first, second, signal), U32.sub(U32.add(U32.add(U32.add(period, first), second), signal), 3))

def DPO.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.max(U32.sub(period, 1), U32.add(U32.div(period, 2), 1)))

def DX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def EFI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.EFI(period), period)

def EMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), U32.sub(period, 1))

def EMV.lookback(+period: U32, +divisor: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.EMV(period, divisor), period)

def ER.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def ERI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), U32.sub(period, 1))

def EXP.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def FISHER.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def FLOOR.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def FOSC.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def FRACTAL.lookback(+left: U32, +right: U32) -> Lookback.Result():
  Lookbacks.checked(Params.periods([left, right]), U32.add(left, right))

def FRAMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.FRAMA(period), period)

def HA.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def HMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 9))

def HT_DCPERIOD.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 32)

def HT_DCPHASE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 63)

def HT_PHASOR.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 32)

def HT_SINE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 63)

def HT_TRENDLINE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 63)

def HT_TRENDMODE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 63)

def IBS.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def ICHIMOKU.lookback(+tenkan: U32, +kijun: U32, +span_b: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.ICHIMOKU(tenkan, kijun, span_b), U32.sub(U32.max(U32.max(tenkan, kijun), span_b), 1))

def IMI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def KAMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 6))

def KC.lookback(+period: U32, +atr_period: U32, +deviation: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.KC(period, atr_period, deviation), U32.max(U32.sub(period, 1), atr_period))

def KDJ.lookback(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.KDJ(kperiod, slowk, ktype, dperiod, dtype), U32.add(U32.add(U32.sub(kperiod, 1), Ma.lookback(slowk, ktype)), Ma.lookback(dperiod, dtype)))

def KST.lookback(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +sma1: U32, +sma2: U32, +sma3: U32, +sma4: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.KST(roc1, roc2, roc3, roc4, sma1, sma2, sma3, sma4, signal), U32.sub(U32.add(U32.max(U32.max(U32.max(U32.sub(U32.add(roc1, sma1), 1), U32.sub(U32.add(roc2, sma2), 1)), U32.sub(U32.add(roc3, sma3), 1)), U32.sub(U32.add(roc4, sma4), 1)), signal), 1))

def KSTEXT.lookback(+roc1: U32, +roc2: U32, +roc3: U32, +roc4: U32, +ma1: U32, +ma2: U32, +ma3: U32, +ma4: U32, +signal: U32, +kind: U32, +signal_kind: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.KSTEXT(roc1, roc2, roc3, roc4, ma1, ma2, ma3, ma4, signal, kind, signal_kind), U32.add(U32.max(U32.max(U32.max(U32.add(roc1, Ma.lookback(ma1, kind)), U32.add(roc2, Ma.lookback(ma2, kind))), U32.add(roc3, Ma.lookback(ma3, kind))), U32.add(roc4, Ma.lookback(ma4, kind))), Ma.lookback(signal, signal_kind)))

def KURTOSIS.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.KURTOSIS(period), U32.sub(period, 1))

def KVO.lookback(+fast: U32, +slow: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.KVO(fast, slow, signal), U32.max(U32.max(fast, slow), signal))

def LINEARREG.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def LINEARREG_ANGLE.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def LINEARREG_INTERCEPT.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def LINEARREG_SLOPE.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def LN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def LOG10.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def MA.lookback(+period: U32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(Ma.valid(period, kind), Ma.lookback(period, kind))

def MACD.lookback(+fast: U32, +slow: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.MACD(fast, slow, signal), U32.sub(U32.add(U32.max(fast, slow), signal), 2))

def MACDEXT.lookback(+fast: U32, +fast_kind: U32, +slow: U32, +slow_kind: U32, +signal: U32, +signal_kind: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.MACDEXT(fast, fast_kind, slow, slow_kind, signal, signal_kind), U32.add(U32.max(Ma.lookback(fast, fast_kind), Ma.lookback(slow, slow_kind)), Ma.lookback(signal, signal_kind)))

def MACDFIX.lookback(+signal: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(signal, 1), U32.add(signal, 24))

def MAMA.lookback(+fast: F32, +slow: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.MAMA(fast, slow), 32)

def MARKETFI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def MASSI.lookback(+fast: U32, +slow: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.MASSI(fast, slow), U32.sub(U32.add(U32.mul(2, U32.sub(fast, 1)), slow), 1))

def MAVP.lookback(+minimum: U32, +maximum: U32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.MAVP(minimum, maximum, kind), Ma.lookback(maximum, kind))

def MAX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MAXINDEX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MCGD.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def MEDIAN.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.MEDIAN(period), U32.sub(period, 1))

def MEDPRICE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def MFI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def MIDPOINT.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MIDPRICE.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MIN.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MININDEX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MINMAX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MINMAXINDEX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def MINUS_DI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), period)

def MINUS_DM.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), U32.max(1, U32.sub(period, 1)))

def MOM.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), period)

def MULT.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def NATR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.NATR(period), period)

def NVI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def OBV.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def PERCENTB.lookback(+period: U32, +up: F32, +down: F32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(Bool.and(parameters.BBANDS(period, up, down), Momentum.selector(period, kind)), U32.max(U32.sub(period, 1), Ma.lookback(period, kind)))

def PERCENTILE.lookback(+period: U32, +percent: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.PERCENTILE(period, percent), U32.sub(period, 1))

def PERCENTRANK.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.PERCENTRANK(period), period)

def PLUS_DI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), period)

def PLUS_DM.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), U32.max(1, U32.sub(period, 1)))

def PPO.lookback(+fast: U32, +slow: U32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.PPO(fast, slow, kind), U32.max(Ma.lookback(fast, kind), Ma.lookback(slow, kind)))

def PSO.lookback(+kperiod: U32, +period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.PSO(kperiod, period), U32.add(U32.sub(kperiod, 1), U32.mul(2, U32.sub(period, 1))))

def PVI.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def PVO.lookback(+fast: U32, +slow: U32, +kind: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.PPO(fast, slow, kind), U32.max(Ma.lookback(fast, kind), Ma.lookback(slow, kind)))

def PVT.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def QSTICK.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), U32.sub(period, 1))

def RMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), U32.sub(period, 1))

def ROC.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), period)

def ROCP.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), period)

def ROCR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), period)

def ROCR100.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), period)

def ROGERSSATCHELL.lookback(+period: U32, +annualization: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.ROGERSSATCHELL(period, annualization), U32.sub(period, 1))

def RSI.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def RVI.lookback(+period: U32, +deviation_period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.RVI(period, deviation_period), U32.sub(U32.add(deviation_period, period), 2))

def RVIR.lookback(+period: U32, +deviation_period: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.RVIR(period, deviation_period), U32.sub(U32.add(deviation_period, period), 2))

def RVOL.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), period)

def SAR.lookback(+acceleration: F32, +maximum: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.SAR(acceleration, maximum), 1)

def SAREXT.lookback(+start: F32, +offset: F32, +long_init: F32, +long_step: F32, +long_max: F32, +short_init: F32, +short_step: F32, +short_max: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.SAREXT(start, offset, long_init, long_step, long_max, short_init, short_step, short_max), 1)

def SI.lookback(+limit: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.SI(limit), 1)

def SIN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def SINH.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def SMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), U32.sub(period, 1))

def SMI.lookback(+period: U32, +fast: U32, +slow: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.SMI(period, fast, slow, signal), U32.sub(U32.add(U32.add(U32.add(period, fast), slow), signal), 4))

def SQRT.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def SQZMOM.lookback(+bb: U32, +deviations: F32, +kc: U32, +wide: F32, +normal: F32, +narrow: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.SQZMOM(bb, deviations, kc, wide, normal, narrow), U32.max(U32.sub(bb, 1), U32.sub(U32.mul(2, kc), 2)))

def STC.lookback(+fast: U32, +slow: U32, +cycle: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.STC(fast, slow, cycle), U32.add(U32.sub(U32.max(fast, slow), 1), U32.mul(2, U32.sub(cycle, 1))))

def STDDEV.lookback(+period: U32, +factor: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.STDDEV(period, factor), U32.sub(period, 1))

def STOCH.lookback(+kperiod: U32, +slowk: U32, +ktype: U32, +dperiod: U32, +dtype: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.STOCH(kperiod, slowk, ktype, dperiod, dtype), U32.add(U32.add(U32.sub(kperiod, 1), Ma.lookback(slowk, ktype)), Ma.lookback(dperiod, dtype)))

def STOCHF.lookback(+kperiod: U32, +dperiod: U32, +dtype: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.STOCHF(kperiod, dperiod, dtype), U32.add(U32.sub(kperiod, 1), Ma.lookback(dperiod, dtype)))

def STOCHRSI.lookback(+period: U32, +kperiod: U32, +dperiod: U32, +dtype: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.STOCHRSI(period, kperiod, dperiod, dtype), U32.add(U32.sub(U32.add(period, kperiod), 1), Ma.lookback(dperiod, dtype)))

def SUB.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def SUM.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Config.valid(period), U32.sub(period, 1))

def SUPERTREND.lookback(+period: U32, +multiplier: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.SUPERTREND(period, multiplier), period)

def SWAK_2PHP.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(filter.valid(period, 2, 10000), 0)

def SWAK_BP.lookback(+period: U32, +delta: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.SWAK_BP(period, delta), 0)

def SWAK_BUTTER.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(filter.valid(period, 2, 10000), 0)

def SWAK_GAUSS.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(filter.valid(period, 2, 10000), 0)

def SWAK_HP.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(filter.valid(period, 5, 100000), 0)

def T3.lookback(+period: U32, +factor: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.T3(period, factor), Ma.lookback(period, 8))

def TAN.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def TANH.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def TEMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 4))

def TRANGE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 1)

def TRIMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 5))

def TRIX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), U32.add(U32.mul(3, U32.sub(period, 1)), 1))

def TSF.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 2), U32.sub(period, 1))

def TSI.lookback(+first: U32, +second: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.TSI(first, second), U32.sub(U32.add(first, second), 1))

def TYPPRICE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def ULTOSC.lookback(+first: U32, +second: U32, +third: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.ULTOSC(first, second, third), U32.max(U32.max(first, second), third))

def VAR.lookback(+period: U32, +factor: F32) -> Lookback.Result():
  Lookbacks.checked(parameters.VAR(period, factor), U32.sub(period, 1))

def VHF.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), period)

def VIDYA.lookback(+period: U32, +cmo: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.VIDYA(period, cmo), Bool.pick(U32, U32.is_eq(period, 1), 0, cmo))

def VORTEX.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 1), period)

def VWAP.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def VWMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(overlap.valid(period, 1), U32.sub(period, 1))

def WAD.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def WAVETREND.lookback(+channel: U32, +average: U32, +signal: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.WAVETREND(channel, average, signal), U32.sub(U32.add(U32.sub(U32.add(U32.mul(2, U32.sub(channel, 1)), average), 1), signal), 1))

def WCLPRICE.lookback() -> Lookback.Result():
  Lookbacks.checked(True{}, 0)

def WILLR.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Momentum.period(period, 2), U32.sub(period, 1))

def WMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 2))

def ZIGZAG.lookback(+sensitivity: F32, +minimum: U32) -> Lookback.Result():
  Lookbacks.checked(parameters.ZIGZAG(sensitivity, minimum), minimum)

def ZLEMA.lookback(+period: U32) -> Lookback.Result():
  Lookbacks.checked(Params.period(period), Ma.lookback(period, 12))

def EMA.clone(state: EMA.State()) -> EMA.State() & EMA.State():
  Clone.data(~Ema.State<F32>, state)

def SMA.clone(state: SMA.State()) -> SMA.State() & SMA.State():
  Clone.sma(~F32, state)

def RMA.clone(state: RMA.State()) -> RMA.State() & RMA.State():
  Clone.data(~Ema.State<F32>, state)

def Window.clone(state: Window.State()) -> Window.State() & Window.State():
  Clone.window(~F32, state)

def SUM.clone(state: SUM.State()) -> SUM.State() & SUM.State():
  Clone.rolling(~F32, state)

def Candle.clone(state: Candle.State()) -> Candle.State() & Candle.State():
  Clone.candle(~F32, state)

def CUMSUM.clone(state: CUMSUM.State()) -> CUMSUM.State() & CUMSUM.State():
  Clone.data(~F32, state)

def MOM.clone(state: MOM.State()) -> MOM.State() & MOM.State():
  Clone.window(~F32, state)

def ROC.clone(state: ROC.State()) -> ROC.State() & ROC.State():
  Clone.window(~F32, state)

def ROCP.clone(state: ROCP.State()) -> ROCP.State() & ROCP.State():
  Clone.window(~F32, state)

def ROCR.clone(state: ROCR.State()) -> ROCR.State() & ROCR.State():
  Clone.window(~F32, state)

def ROCR100.clone(state: ROCR100.State()) -> ROCR100.State() & ROCR100.State():
  Clone.window(~F32, state)

def OBV.clone(state: OBV.State()) -> OBV.State() & OBV.State():
  Clone.data(~Volume.Index<F32>, state)

def NVI.clone(state: NVI.State()) -> NVI.State() & NVI.State():
  Clone.data(~Volume.Index<F32>, state)

def PVI.clone(state: PVI.State()) -> PVI.State() & PVI.State():
  Clone.data(~Volume.Index<F32>, state)

def PVT.clone(state: PVT.State()) -> PVT.State() & PVT.State():
  Clone.data(~Volume.Index<F32>, state)

def AD.clone(state: AD.State()) -> AD.State() & AD.State():
  Clone.data(~F32, state)

def TRANGE.clone(state: TRANGE.State()) -> TRANGE.State() & TRANGE.State():
  Clone.data(~Maybe<&2, F32>, state)

def CMF.clone(state: CMF.State()) -> CMF.State() & CMF.State():
  Clone.window(~Volume.Flow<F32>, state)

def EFI.clone(state: EFI.State()) -> EFI.State() & EFI.State():
  Clone.data(~Volume.Force<F32>, state)

def ADR.clone(state: ADR.State()) -> ADR.State() & ADR.State():
  Clone.sma(~F32, state)

def ATR.clone(state: ATR.State()) -> ATR.State() & ATR.State():
  Clone.data(~Volatility.Atr<F32>, state)

def NATR.clone(state: NATR.State()) -> NATR.State() & NATR.State():
  Clone.data(~Volatility.Natr<F32>, state)

def EMV.clone(state: EMV.State()) -> EMV.State() & EMV.State():
  Clone.volume.ease(~F32, state)

def CVI.clone(state: CVI.State()) -> CVI.State() & CVI.State():
  Clone.volatility.cvi(~F32, state)

def MASSI.clone(state: MASSI.State()) -> MASSI.State() & MASSI.State():
  Clone.volatility.mass(~F32, state)

def Pattern.clone(state: Pattern.State()) -> Pattern.State() & Pattern.State():
  Clone.pattern_state(~F32, state)

def CDL2CROWS.clone(state: CDL2CROWS.State()) -> CDL2CROWS.State() & CDL2CROWS.State():
  Clone.pattern_state(~F32, state)

def CDL3BLACKCROWS.clone(state: CDL3BLACKCROWS.State()) -> CDL3BLACKCROWS.State() & CDL3BLACKCROWS.State():
  Clone.pattern_state(~F32, state)

def CDL3INSIDE.clone(state: CDL3INSIDE.State()) -> CDL3INSIDE.State() & CDL3INSIDE.State():
  Clone.pattern_state(~F32, state)

def CDL3LINESTRIKE.clone(state: CDL3LINESTRIKE.State()) -> CDL3LINESTRIKE.State() & CDL3LINESTRIKE.State():
  Clone.pattern_state(~F32, state)

def CDL3OUTSIDE.clone(state: CDL3OUTSIDE.State()) -> CDL3OUTSIDE.State() & CDL3OUTSIDE.State():
  Clone.pattern_state(~F32, state)

def CDL3STARSINSOUTH.clone(state: CDL3STARSINSOUTH.State()) -> CDL3STARSINSOUTH.State() & CDL3STARSINSOUTH.State():
  Clone.pattern_state(~F32, state)

def CDL3WHITESOLDIERS.clone(state: CDL3WHITESOLDIERS.State()) -> CDL3WHITESOLDIERS.State() & CDL3WHITESOLDIERS.State():
  Clone.pattern_state(~F32, state)

def CDLABANDONEDBABY.clone(state: CDLABANDONEDBABY.State()) -> CDLABANDONEDBABY.State() & CDLABANDONEDBABY.State():
  Clone.pattern_state(~F32, state)

def CDLADVANCEBLOCK.clone(state: CDLADVANCEBLOCK.State()) -> CDLADVANCEBLOCK.State() & CDLADVANCEBLOCK.State():
  Clone.pattern_state(~F32, state)

def CDLBELTHOLD.clone(state: CDLBELTHOLD.State()) -> CDLBELTHOLD.State() & CDLBELTHOLD.State():
  Clone.pattern_state(~F32, state)

def CDLBREAKAWAY.clone(state: CDLBREAKAWAY.State()) -> CDLBREAKAWAY.State() & CDLBREAKAWAY.State():
  Clone.pattern_state(~F32, state)

def CDLCLOSINGMARUBOZU.clone(state: CDLCLOSINGMARUBOZU.State()) -> CDLCLOSINGMARUBOZU.State() & CDLCLOSINGMARUBOZU.State():
  Clone.pattern_state(~F32, state)

def CDLCONCEALBABYSWALL.clone(state: CDLCONCEALBABYSWALL.State()) -> CDLCONCEALBABYSWALL.State() & CDLCONCEALBABYSWALL.State():
  Clone.pattern_state(~F32, state)

def CDLCOUNTERATTACK.clone(state: CDLCOUNTERATTACK.State()) -> CDLCOUNTERATTACK.State() & CDLCOUNTERATTACK.State():
  Clone.pattern_state(~F32, state)

def CDLDARKCLOUDCOVER.clone(state: CDLDARKCLOUDCOVER.State()) -> CDLDARKCLOUDCOVER.State() & CDLDARKCLOUDCOVER.State():
  Clone.pattern_state(~F32, state)

def CDLDOJI.clone(state: CDLDOJI.State()) -> CDLDOJI.State() & CDLDOJI.State():
  Clone.pattern_state(~F32, state)

def CDLDOJISTAR.clone(state: CDLDOJISTAR.State()) -> CDLDOJISTAR.State() & CDLDOJISTAR.State():
  Clone.pattern_state(~F32, state)

def CDLDRAGONFLYDOJI.clone(state: CDLDRAGONFLYDOJI.State()) -> CDLDRAGONFLYDOJI.State() & CDLDRAGONFLYDOJI.State():
  Clone.pattern_state(~F32, state)

def CDLENGULFING.clone(state: CDLENGULFING.State()) -> CDLENGULFING.State() & CDLENGULFING.State():
  Clone.pattern_state(~F32, state)

def CDLEVENINGDOJISTAR.clone(state: CDLEVENINGDOJISTAR.State()) -> CDLEVENINGDOJISTAR.State() & CDLEVENINGDOJISTAR.State():
  Clone.pattern_state(~F32, state)

def CDLEVENINGSTAR.clone(state: CDLEVENINGSTAR.State()) -> CDLEVENINGSTAR.State() & CDLEVENINGSTAR.State():
  Clone.pattern_state(~F32, state)

def CDLGAPSIDESIDEWHITE.clone(state: CDLGAPSIDESIDEWHITE.State()) -> CDLGAPSIDESIDEWHITE.State() & CDLGAPSIDESIDEWHITE.State():
  Clone.pattern_state(~F32, state)

def CDLGRAVESTONEDOJI.clone(state: CDLGRAVESTONEDOJI.State()) -> CDLGRAVESTONEDOJI.State() & CDLGRAVESTONEDOJI.State():
  Clone.pattern_state(~F32, state)

def CDLHAMMER.clone(state: CDLHAMMER.State()) -> CDLHAMMER.State() & CDLHAMMER.State():
  Clone.pattern_state(~F32, state)

def CDLHANGINGMAN.clone(state: CDLHANGINGMAN.State()) -> CDLHANGINGMAN.State() & CDLHANGINGMAN.State():
  Clone.pattern_state(~F32, state)

def CDLHARAMI.clone(state: CDLHARAMI.State()) -> CDLHARAMI.State() & CDLHARAMI.State():
  Clone.pattern_state(~F32, state)

def CDLHARAMICROSS.clone(state: CDLHARAMICROSS.State()) -> CDLHARAMICROSS.State() & CDLHARAMICROSS.State():
  Clone.pattern_state(~F32, state)

def CDLHIGHWAVE.clone(state: CDLHIGHWAVE.State()) -> CDLHIGHWAVE.State() & CDLHIGHWAVE.State():
  Clone.pattern_state(~F32, state)

def CDLHOMINGPIGEON.clone(state: CDLHOMINGPIGEON.State()) -> CDLHOMINGPIGEON.State() & CDLHOMINGPIGEON.State():
  Clone.pattern_state(~F32, state)

def CDLIDENTICAL3CROWS.clone(state: CDLIDENTICAL3CROWS.State()) -> CDLIDENTICAL3CROWS.State() & CDLIDENTICAL3CROWS.State():
  Clone.pattern_state(~F32, state)

def CDLINNECK.clone(state: CDLINNECK.State()) -> CDLINNECK.State() & CDLINNECK.State():
  Clone.pattern_state(~F32, state)

def CDLINVERTEDHAMMER.clone(state: CDLINVERTEDHAMMER.State()) -> CDLINVERTEDHAMMER.State() & CDLINVERTEDHAMMER.State():
  Clone.pattern_state(~F32, state)

def CDLKICKING.clone(state: CDLKICKING.State()) -> CDLKICKING.State() & CDLKICKING.State():
  Clone.pattern_state(~F32, state)

def CDLKICKINGBYLENGTH.clone(state: CDLKICKINGBYLENGTH.State()) -> CDLKICKINGBYLENGTH.State() & CDLKICKINGBYLENGTH.State():
  Clone.pattern_state(~F32, state)

def CDLLADDERBOTTOM.clone(state: CDLLADDERBOTTOM.State()) -> CDLLADDERBOTTOM.State() & CDLLADDERBOTTOM.State():
  Clone.pattern_state(~F32, state)

def CDLLONGLEGGEDDOJI.clone(state: CDLLONGLEGGEDDOJI.State()) -> CDLLONGLEGGEDDOJI.State() & CDLLONGLEGGEDDOJI.State():
  Clone.pattern_state(~F32, state)

def CDLLONGLINE.clone(state: CDLLONGLINE.State()) -> CDLLONGLINE.State() & CDLLONGLINE.State():
  Clone.pattern_state(~F32, state)

def CDLMARUBOZU.clone(state: CDLMARUBOZU.State()) -> CDLMARUBOZU.State() & CDLMARUBOZU.State():
  Clone.pattern_state(~F32, state)

def CDLMATCHINGLOW.clone(state: CDLMATCHINGLOW.State()) -> CDLMATCHINGLOW.State() & CDLMATCHINGLOW.State():
  Clone.pattern_state(~F32, state)

def CDLMATHOLD.clone(state: CDLMATHOLD.State()) -> CDLMATHOLD.State() & CDLMATHOLD.State():
  Clone.pattern_state(~F32, state)

def CDLMORNINGDOJISTAR.clone(state: CDLMORNINGDOJISTAR.State()) -> CDLMORNINGDOJISTAR.State() & CDLMORNINGDOJISTAR.State():
  Clone.pattern_state(~F32, state)

def CDLMORNINGSTAR.clone(state: CDLMORNINGSTAR.State()) -> CDLMORNINGSTAR.State() & CDLMORNINGSTAR.State():
  Clone.pattern_state(~F32, state)

def CDLONNECK.clone(state: CDLONNECK.State()) -> CDLONNECK.State() & CDLONNECK.State():
  Clone.pattern_state(~F32, state)

def CDLPIERCING.clone(state: CDLPIERCING.State()) -> CDLPIERCING.State() & CDLPIERCING.State():
  Clone.pattern_state(~F32, state)

def CDLRICKSHAWMAN.clone(state: CDLRICKSHAWMAN.State()) -> CDLRICKSHAWMAN.State() & CDLRICKSHAWMAN.State():
  Clone.pattern_state(~F32, state)

def CDLRISEFALL3METHODS.clone(state: CDLRISEFALL3METHODS.State()) -> CDLRISEFALL3METHODS.State() & CDLRISEFALL3METHODS.State():
  Clone.pattern_state(~F32, state)

def CDLSEPARATINGLINES.clone(state: CDLSEPARATINGLINES.State()) -> CDLSEPARATINGLINES.State() & CDLSEPARATINGLINES.State():
  Clone.pattern_state(~F32, state)

def CDLSHOOTINGSTAR.clone(state: CDLSHOOTINGSTAR.State()) -> CDLSHOOTINGSTAR.State() & CDLSHOOTINGSTAR.State():
  Clone.pattern_state(~F32, state)

def CDLSHORTLINE.clone(state: CDLSHORTLINE.State()) -> CDLSHORTLINE.State() & CDLSHORTLINE.State():
  Clone.pattern_state(~F32, state)

def CDLSPINNINGTOP.clone(state: CDLSPINNINGTOP.State()) -> CDLSPINNINGTOP.State() & CDLSPINNINGTOP.State():
  Clone.pattern_state(~F32, state)

def CDLSTALLEDPATTERN.clone(state: CDLSTALLEDPATTERN.State()) -> CDLSTALLEDPATTERN.State() & CDLSTALLEDPATTERN.State():
  Clone.pattern_state(~F32, state)

def CDLSTICKSANDWICH.clone(state: CDLSTICKSANDWICH.State()) -> CDLSTICKSANDWICH.State() & CDLSTICKSANDWICH.State():
  Clone.pattern_state(~F32, state)

def CDLTAKURI.clone(state: CDLTAKURI.State()) -> CDLTAKURI.State() & CDLTAKURI.State():
  Clone.pattern_state(~F32, state)

def CDLTASUKIGAP.clone(state: CDLTASUKIGAP.State()) -> CDLTASUKIGAP.State() & CDLTASUKIGAP.State():
  Clone.pattern_state(~F32, state)

def CDLTHRUSTING.clone(state: CDLTHRUSTING.State()) -> CDLTHRUSTING.State() & CDLTHRUSTING.State():
  Clone.pattern_state(~F32, state)

def CDLTRISTAR.clone(state: CDLTRISTAR.State()) -> CDLTRISTAR.State() & CDLTRISTAR.State():
  Clone.pattern_state(~F32, state)

def CDLUNIQUE3RIVER.clone(state: CDLUNIQUE3RIVER.State()) -> CDLUNIQUE3RIVER.State() & CDLUNIQUE3RIVER.State():
  Clone.pattern_state(~F32, state)

def CDLUPSIDEGAP2CROWS.clone(state: CDLUPSIDEGAP2CROWS.State()) -> CDLUPSIDEGAP2CROWS.State() & CDLUPSIDEGAP2CROWS.State():
  Clone.pattern_state(~F32, state)

def CDLXSIDEGAP3METHODS.clone(state: CDLXSIDEGAP3METHODS.State()) -> CDLXSIDEGAP3METHODS.State() & CDLXSIDEGAP3METHODS.State():
  Clone.pattern_state(~F32, state)

def VIDYA.clone(state: VIDYA.State()) -> VIDYA.State() & VIDYA.State():
  Clone.vidya(~F32, state)

def MAMA.clone(state: MAMA.State()) -> MAMA.State() & MAMA.State():
  Clone.data(~Mama.State<F32>, state)

def MA.clone(state: MA.State()) -> MA.State() & MA.State():
  Clone.ma(~F32, state)

def WMA.clone(state: WMA.State()) -> WMA.State() & WMA.State():
  Clone.ma(~F32, state)

def DEMA.clone(state: DEMA.State()) -> DEMA.State() & DEMA.State():
  Clone.ma(~F32, state)

def TEMA.clone(state: TEMA.State()) -> TEMA.State() & TEMA.State():
  Clone.ma(~F32, state)

def TRIMA.clone(state: TRIMA.State()) -> TRIMA.State() & TRIMA.State():
  Clone.ma(~F32, state)

def KAMA.clone(state: KAMA.State()) -> KAMA.State() & KAMA.State():
  Clone.ma(~F32, state)

def HMA.clone(state: HMA.State()) -> HMA.State() & HMA.State():
  Clone.ma(~F32, state)

def ZLEMA.clone(state: ZLEMA.State()) -> ZLEMA.State() & ZLEMA.State():
  Clone.ma(~F32, state)

def T3.clone(state: T3.State()) -> T3.State() & T3.State():
  Clone.ma(~F32, state)

def ALMA.clone(state: ALMA.State()) -> ALMA.State() & ALMA.State():
  Clone.ma(~F32, state)

def LINEARREG.clone(state: LINEARREG.State()) -> LINEARREG.State() & LINEARREG.State():
  Clone.rolling_average(~F32, state)

def LINEARREG_SLOPE.clone(state: LINEARREG_SLOPE.State()) -> LINEARREG_SLOPE.State() & LINEARREG_SLOPE.State():
  Clone.rolling_average(~F32, state)

def LINEARREG_INTERCEPT.clone(state: LINEARREG_INTERCEPT.State()) -> LINEARREG_INTERCEPT.State() & LINEARREG_INTERCEPT.State():
  Clone.rolling_average(~F32, state)

def LINEARREG_ANGLE.clone(state: LINEARREG_ANGLE.State()) -> LINEARREG_ANGLE.State() & LINEARREG_ANGLE.State():
  Clone.rolling_average(~F32, state)

def TSF.clone(state: TSF.State()) -> TSF.State() & TSF.State():
  Clone.rolling_average(~F32, state)

def MAX.clone(state: MAX.State()) -> MAX.State() & MAX.State():
  Clone.statistics.extremes(~F32, state)

def MIN.clone(state: MIN.State()) -> MIN.State() & MIN.State():
  Clone.statistics.extremes(~F32, state)

def MAXINDEX.clone(state: MAXINDEX.State()) -> MAXINDEX.State() & MAXINDEX.State():
  Clone.statistics.extremes(~F32, state)

def MININDEX.clone(state: MININDEX.State()) -> MININDEX.State() & MININDEX.State():
  Clone.statistics.extremes(~F32, state)

def MINMAX.clone(state: MINMAX.State()) -> MINMAX.State() & MINMAX.State():
  Clone.statistics.extremes(~F32, state)

def MINMAXINDEX.clone(state: MINMAXINDEX.State()) -> MINMAXINDEX.State() & MINMAXINDEX.State():
  Clone.statistics.extremes(~F32, state)

def MEDIAN.clone(state: MEDIAN.State()) -> MEDIAN.State() & MEDIAN.State():
  Clone.window(~F32, state)

def PERCENTRANK.clone(state: PERCENTRANK.State()) -> PERCENTRANK.State() & PERCENTRANK.State():
  Clone.window(~F32, state)

def AVGDEV.clone(state: AVGDEV.State()) -> AVGDEV.State() & AVGDEV.State():
  Clone.window(~F32, state)

def STDDEV.clone(state: STDDEV.State()) -> STDDEV.State() & STDDEV.State():
  Clone.statistics.standard(~F32, state)

def PERCENTILE.clone(state: PERCENTILE.State()) -> PERCENTILE.State() & PERCENTILE.State():
  Clone.statistics.parameterwindow(~F32, state)

def MIDPOINT.clone(state: MIDPOINT.State()) -> MIDPOINT.State() & MIDPOINT.State():
  Clone.extrema_queue(~F32, state)

def DONCHIAN.clone(state: DONCHIAN.State()) -> DONCHIAN.State() & DONCHIAN.State():
  Clone.extrema_queue(~F32, state)

def MIDPRICE.clone(state: MIDPRICE.State()) -> MIDPRICE.State() & MIDPRICE.State():
  Clone.extrema_queue(~F32, state)

def BBANDS.clone(state: BBANDS.State()) -> BBANDS.State() & BBANDS.State():
  Clone.overlap.bollinger(~F32, state)

def BBW.clone(state: BBW.State()) -> BBW.State() & BBW.State():
  Clone.overlap.bollinger(~F32, state)

def PERCENTB.clone(state: PERCENTB.State()) -> PERCENTB.State() & PERCENTB.State():
  Clone.overlap.bollinger(~F32, state)

def ACCBANDS.clone(state: ACCBANDS.State()) -> ACCBANDS.State() & ACCBANDS.State():
  Clone.overlap.acceleration(~F32, state)

def VWMA.clone(state: VWMA.State()) -> VWMA.State() & VWMA.State():
  Clone.window(~Bars.CV<F32>, state)

def HA.clone(state: HA.State()) -> HA.State() & HA.State():
  Clone.data(~Overlap.Heikin<F32>, state)

def KC.clone(state: KC.State()) -> KC.State() & KC.State():
  Clone.data(~Overlap.Keltner<F32>, state)

def CKSP.clone(state: CKSP.State()) -> CKSP.State() & CKSP.State():
  Clone.overlap.chandekroll(~F32, state)

def RSI.clone(state: RSI.State()) -> RSI.State() & RSI.State():
  Clone.data(~MomCore.RSI<F32>, state)

def CMO.clone(state: CMO.State()) -> CMO.State() & CMO.State():
  Clone.data(~MomCore.RSI<F32>, state)

def CMOU.clone(state: CMOU.State()) -> CMOU.State() & CMOU.State():
  Clone.momentum.flow(~F32, state)

def IMI.clone(state: IMI.State()) -> IMI.State() & IMI.State():
  Clone.momentum.flow(~F32, state)

def PLUS_DM.clone(state: PLUS_DM.State()) -> PLUS_DM.State() & PLUS_DM.State():
  Clone.data(~Directional.State<F32>, state)

def MINUS_DM.clone(state: MINUS_DM.State()) -> MINUS_DM.State() & MINUS_DM.State():
  Clone.data(~Directional.State<F32>, state)

def PLUS_DI.clone(state: PLUS_DI.State()) -> PLUS_DI.State() & PLUS_DI.State():
  Clone.data(~Directional.State<F32>, state)

def MINUS_DI.clone(state: MINUS_DI.State()) -> MINUS_DI.State() & MINUS_DI.State():
  Clone.data(~Directional.State<F32>, state)

def DX.clone(state: DX.State()) -> DX.State() & DX.State():
  Clone.data(~Directional.State<F32>, state)

def ADX.clone(state: ADX.State()) -> ADX.State() & ADX.State():
  Clone.data(~Directional.ADX<F32>, state)

def ADXR.clone(state: ADXR.State()) -> ADXR.State() & ADXR.State():
  Clone.directional.adxr(~F32, state)

def SI.clone(state: SI.State()) -> SI.State() & SI.State():
  Clone.data(~MomentumWindow.Swing<F32>, state)

def ASI.clone(state: ASI.State()) -> ASI.State() & ASI.State():
  Clone.data(~MomentumWindow.Swing<F32>, state)

def WAD.clone(state: WAD.State()) -> WAD.State() & WAD.State():
  Clone.data(~MomentumWindow.WAD<F32>, state)

def WILLR.clone(state: WILLR.State()) -> WILLR.State() & WILLR.State():
  Clone.momentum_window.box(~F32, state)

def AROON.clone(state: AROON.State()) -> AROON.State() & AROON.State():
  Clone.momentum_window.box(~F32, state)

def AROONOSC.clone(state: AROONOSC.State()) -> AROONOSC.State() & AROONOSC.State():
  Clone.momentum_window.box(~F32, state)

def ER.clone(state: ER.State()) -> ER.State() & ER.State():
  Clone.momentum_window.prices(~F32, state)

def VHF.clone(state: VHF.State()) -> VHF.State() & VHF.State():
  Clone.momentum_window.prices(~F32, state)

def APO.clone(state: APO.State()) -> APO.State() & APO.State():
  Clone.momentum_smooth.dual(~F32, state)

def PPO.clone(state: PPO.State()) -> PPO.State() & PPO.State():
  Clone.momentum_smooth.dual(~F32, state)

def AO.clone(state: AO.State()) -> AO.State() & AO.State():
  Clone.momentum_smooth.dual(~F32, state)

def AC.clone(state: AC.State()) -> AC.State() & AC.State():
  Clone.momentum_smooth.macd(~F32, state)

def MACD.clone(state: MACD.State()) -> MACD.State() & MACD.State():
  Clone.momentum_smooth.macd(~F32, state)

def MACDFIX.clone(state: MACDFIX.State()) -> MACDFIX.State() & MACDFIX.State():
  Clone.momentum_smooth.macd(~F32, state)

def STOCH.clone(state: STOCH.State()) -> STOCH.State() & STOCH.State():
  Clone.momentum_smooth.stoch(~F32, state)

def KDJ.clone(state: KDJ.State()) -> KDJ.State() & KDJ.State():
  Clone.momentum_smooth.stoch(~F32, state)

def STOCHF.clone(state: STOCHF.State()) -> STOCHF.State() & STOCHF.State():
  Clone.momentum_smooth.stoch(~F32, state)

def STOCHRSI.clone(state: STOCHRSI.State()) -> STOCHRSI.State() & STOCHRSI.State():
  Clone.momentum_composite.stochrsi(~F32, state)

def TRIX.clone(state: TRIX.State()) -> TRIX.State() & TRIX.State():
  Clone.momentum_smooth.trix(~F32, state)

def DOSC.clone(state: DOSC.State()) -> DOSC.State() & DOSC.State():
  Clone.momentum_smooth.dosc(~F32, state)

def PSO.clone(state: PSO.State()) -> PSO.State() & PSO.State():
  Clone.momentum_smooth.pso(~F32, state)

def TSI.clone(state: TSI.State()) -> TSI.State() & TSI.State():
  Clone.momentum_composite.tsi(~F32, state)

def QSTICK.clone(state: QSTICK.State()) -> QSTICK.State() & QSTICK.State():
  Clone.ma(~F32, state)

def ERI.clone(state: ERI.State()) -> ERI.State() & ERI.State():
  Clone.momentum_smooth.eri(~F32, state)

def FOSC.clone(state: FOSC.State()) -> FOSC.State() & FOSC.State():
  Clone.momentum_composite.forecast(~F32, state)

def CCI.clone(state: CCI.State()) -> CCI.State() & CCI.State():
  Clone.momentum_market.cci(~F32, state)

def MFI.clone(state: MFI.State()) -> MFI.State() & MFI.State():
  Clone.momentum.flow(~F32, state)

def CHOP.clone(state: CHOP.State()) -> CHOP.State() & CHOP.State():
  Clone.momentum_market.market(~F32, state)

def CHOPTR.clone(state: CHOPTR.State()) -> CHOPTR.State() & CHOPTR.State():
  Clone.momentum_market.market(~F32, state)

def VORTEX.clone(state: VORTEX.State()) -> VORTEX.State() & VORTEX.State():
  Clone.momentum_market.market(~F32, state)

def ULTOSC.clone(state: ULTOSC.State()) -> ULTOSC.State() & ULTOSC.State():
  Clone.momentum_composite.ultimate(~F32, state)

def COPPOCK.clone(state: COPPOCK.State()) -> COPPOCK.State() & COPPOCK.State():
  Clone.momentum_composite.roc(~F32, state)

def KST.clone(state: KST.State()) -> KST.State() & KST.State():
  Clone.momentum_composite.roc(~F32, state)

def PVO.clone(state: PVO.State()) -> PVO.State() & PVO.State():
  Clone.momentum_smooth.dual(~F32, state)

def DPO.clone(state: DPO.State()) -> DPO.State() & DPO.State():
  Clone.window_signals.detrended(~F32, state)

def RVOL.clone(state: RVOL.State()) -> RVOL.State() & RVOL.State():
  Clone.rolling_average(~F32, state)

def ICHIMOKU.clone(state: ICHIMOKU.State()) -> ICHIMOKU.State() & ICHIMOKU.State():
  Clone.window_signals.cloud(~F32, state)

def FRACTAL.clone(state: FRACTAL.State()) -> FRACTAL.State() & FRACTAL.State():
  Clone.window_signals.fractal(~F32, state)

def VWAP.clone(state: VWAP.State()) -> VWAP.State() & VWAP.State():
  Clone.data(~MarketState.Anchored<F32>, state)

def ZIGZAG.clone(state: ZIGZAG.State()) -> ZIGZAG.State() & ZIGZAG.State():
  Clone.data(~MarketState.ZigZag<F32>, state)

def MAVP.clone(state: MAVP.State()) -> MAVP.State() & MAVP.State():
  Clone.variable(~F32, state)

def FRAMA.clone(state: FRAMA.State()) -> FRAMA.State() & FRAMA.State():
  Clone.adaptive_window.frama(~F32, state)

def MCGD.clone(state: MCGD.State()) -> MCGD.State() & MCGD.State():
  Clone.data(~TrendState.McGinley<F32>, state)

def SAR.clone(state: SAR.State()) -> SAR.State() & SAR.State():
  Clone.data(~TrendState.Sar<F32>, state)

def SAREXT.clone(state: SAREXT.State()) -> SAREXT.State() & SAREXT.State():
  Clone.data(~TrendState.Sar<F32>, state)

def SUPERTREND.clone(state: SUPERTREND.State()) -> SUPERTREND.State() & SUPERTREND.State():
  Clone.data(~TrendState.Supertrend<F32>, state)

def CG.clone(state: CG.State()) -> CG.State() & CG.State():
  Clone.window(~F32, state)

def CTI.clone(state: CTI.State()) -> CTI.State() & CTI.State():
  Clone.window(~F32, state)

def FISHER.clone(state: FISHER.State()) -> FISHER.State() & FISHER.State():
  Clone.adaptive_window.fisher(~F32, state)

def CRSI.clone(state: CRSI.State()) -> CRSI.State() & CRSI.State():
  Clone.advanced_oscillator.crsi(~F32, state)

def SMI.clone(state: SMI.State()) -> SMI.State() & SMI.State():
  Clone.advanced_oscillator.smi(~F32, state)

def STC.clone(state: STC.State()) -> STC.State() & STC.State():
  Clone.advanced_oscillator.stc(~F32, state)

def WAVETREND.clone(state: WAVETREND.State()) -> WAVETREND.State() & WAVETREND.State():
  Clone.advanced_oscillator.wave(~F32, state)

def MACDEXT.clone(state: MACDEXT.State()) -> MACDEXT.State() & MACDEXT.State():
  Clone.trend_composite.macd(~F32, state)

def KSTEXT.clone(state: KSTEXT.State()) -> KSTEXT.State() & KSTEXT.State():
  Clone.trend_composite.kst(~F32, state)

def SQZMOM.clone(state: SQZMOM.State()) -> SQZMOM.State() & SQZMOM.State():
  Clone.squeeze(~F32, state)

def ADOSC.clone(state: ADOSC.State()) -> ADOSC.State() & ADOSC.State():
  Clone.data(~VolumeFilter.Adosc<F32>, state)

def KVO.clone(state: KVO.State()) -> KVO.State() & KVO.State():
  Clone.data(~VolumeFilter.Kvo<F32>, state)

def VAR.clone(state: VAR.State()) -> VAR.State() & VAR.State():
  Clone.moments(~F32, state)

def CORREL.clone(state: CORREL.State()) -> CORREL.State() & CORREL.State():
  Clone.statistics_window.pair(~F32, state)

def BETA.clone(state: BETA.State()) -> BETA.State() & BETA.State():
  Clone.statistics_window.beta(~F32, state)

def KURTOSIS.clone(state: KURTOSIS.State()) -> KURTOSIS.State() & KURTOSIS.State():
  Clone.window(~F32, state)

def ROGERSSATCHELL.clone(state: ROGERSSATCHELL.State()) -> ROGERSSATCHELL.State() & ROGERSSATCHELL.State():
  Clone.volatility_window.rogerssatchell(~F32, state)

def RVI.clone(state: RVI.State()) -> RVI.State() & RVI.State():
  Clone.volatility_window.rvi(~F32, state)

def RVIR.clone(state: RVIR.State()) -> RVIR.State() & RVIR.State():
  Clone.volatility_window.rvir(~F32, state)

def CDLHIKKAKE.clone(state: CDLHIKKAKE.State()) -> CDLHIKKAKE.State() & CDLHIKKAKE.State():
  Clone.hikkake(~F32, state)

def CDLHIKKAKEMOD.clone(state: CDLHIKKAKEMOD.State()) -> CDLHIKKAKEMOD.State() & CDLHIKKAKEMOD.State():
  Clone.hikkake(~F32, state)

def HT_DCPERIOD.clone(state: HT_DCPERIOD.State()) -> HT_DCPERIOD.State() & HT_DCPERIOD.State():
  Clone.hilbert(~F32, state)

def HT_PHASOR.clone(state: HT_PHASOR.State()) -> HT_PHASOR.State() & HT_PHASOR.State():
  Clone.hilbert(~F32, state)

def HT_TRENDLINE.clone(state: HT_TRENDLINE.State()) -> HT_TRENDLINE.State() & HT_TRENDLINE.State():
  Clone.hilbert(~F32, state)

def HT_DCPHASE.clone(state: HT_DCPHASE.State()) -> HT_DCPHASE.State() & HT_DCPHASE.State():
  Clone.hilbert(~F32, state)

def HT_SINE.clone(state: HT_SINE.State()) -> HT_SINE.State() & HT_SINE.State():
  Clone.hilbert(~F32, state)

def HT_TRENDMODE.clone(state: HT_TRENDMODE.State()) -> HT_TRENDMODE.State() & HT_TRENDMODE.State():
  Clone.hilbert(~F32, state)

def SWAK_BUTTER.clone(state: SWAK_BUTTER.State()) -> SWAK_BUTTER.State() & SWAK_BUTTER.State():
  Clone.data(~Filters.State<F32>, state)

def SWAK_GAUSS.clone(state: SWAK_GAUSS.State()) -> SWAK_GAUSS.State() & SWAK_GAUSS.State():
  Clone.data(~Filters.State<F32>, state)

def SWAK_2PHP.clone(state: SWAK_2PHP.State()) -> SWAK_2PHP.State() & SWAK_2PHP.State():
  Clone.data(~Filters.State<F32>, state)

def SWAK_BP.clone(state: SWAK_BP.State()) -> SWAK_BP.State() & SWAK_BP.State():
  Clone.data(~Filters.State<F32>, state)

def SWAK_HP.clone(state: SWAK_HP.State()) -> SWAK_HP.State() & SWAK_HP.State():
  Clone.data(~Filters.State<F32>, state)

def EMA.preview(state: EMA.State(), price: F32) -> EMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~EMA.State(), ~EMA.clone, ~EMA.next, state, price)

def SMA.preview(state: SMA.State(), price: F32) -> SMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SMA.State(), ~SMA.clone, ~SMA.next, state, price)

def RMA.preview(state: RMA.State(), price: F32) -> RMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~RMA.State(), ~RMA.clone, ~RMA.next, state, price)

def SUM.preview(state: SUM.State(), price: F32) -> SUM.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SUM.State(), ~SUM.clone, ~SUM.next, state, price)

def Candle.preview(state: Candle.State(), bar: Bars.OHLC<F32>) -> Candle.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.OHLC<F32>, ~F32, ~Candle.State(), ~Candle.clone, ~Candle.next, state, bar)

def CUMSUM.preview(state: CUMSUM.State(), value: F32) -> CUMSUM.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~CUMSUM.State(), ~CUMSUM.clone, ~CUMSUM.next, state, value)

def MOM.preview(state: MOM.State(), value: F32) -> MOM.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~MOM.State(), ~MOM.clone, ~MOM.next, state, value)

def ROC.preview(state: ROC.State(), value: F32) -> ROC.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ROC.State(), ~ROC.clone, ~ROC.next, state, value)

def ROCP.preview(state: ROCP.State(), value: F32) -> ROCP.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ROCP.State(), ~ROCP.clone, ~ROCP.next, state, value)

def ROCR.preview(state: ROCR.State(), value: F32) -> ROCR.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ROCR.State(), ~ROCR.clone, ~ROCR.next, state, value)

def ROCR100.preview(state: ROCR100.State(), value: F32) -> ROCR100.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ROCR100.State(), ~ROCR100.clone, ~ROCR100.next, state, value)

def OBV.preview(state: OBV.State(), bar: Bars.CV<F32>) -> OBV.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.CV<F32>, ~F32, ~OBV.State(), ~OBV.clone, ~OBV.next, state, bar)

def NVI.preview(state: NVI.State(), bar: Bars.CV<F32>) -> NVI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.CV<F32>, ~F32, ~NVI.State(), ~NVI.clone, ~NVI.next, state, bar)

def PVI.preview(state: PVI.State(), bar: Bars.CV<F32>) -> PVI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.CV<F32>, ~F32, ~PVI.State(), ~PVI.clone, ~PVI.next, state, bar)

def PVT.preview(state: PVT.State(), bar: Bars.CV<F32>) -> PVT.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.CV<F32>, ~F32, ~PVT.State(), ~PVT.clone, ~PVT.next, state, bar)

def AD.preview(state: AD.State(), bar: Bars.HLCV<F32>) -> AD.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLCV<F32>, ~F32, ~AD.State(), ~AD.clone, ~AD.next, state, bar)

def TRANGE.preview(state: TRANGE.State(), bar: Bars.HLC<F32>) -> TRANGE.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~TRANGE.State(), ~TRANGE.clone, ~TRANGE.next, state, bar)

def CMF.preview(state: CMF.State(), bar: Bars.HLCV<F32>) -> CMF.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLCV<F32>, ~F32, ~CMF.State(), ~CMF.clone, ~CMF.next, state, bar)

def EFI.preview(state: EFI.State(), bar: Bars.CV<F32>) -> EFI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.CV<F32>, ~F32, ~EFI.State(), ~EFI.clone, ~EFI.next, state, bar)

def ADR.preview(state: ADR.State(), bar: Bars.HL<F32>) -> ADR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~ADR.State(), ~ADR.clone, ~ADR.next, state, bar)

def ATR.preview(state: ATR.State(), bar: Bars.HLC<F32>) -> ATR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~ATR.State(), ~ATR.clone, ~ATR.next, state, bar)

def NATR.preview(state: NATR.State(), bar: Bars.HLC<F32>) -> NATR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~NATR.State(), ~NATR.clone, ~NATR.next, state, bar)

def EMV.preview(state: EMV.State(), bar: Bars.HLV<F32>) -> EMV.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLV<F32>, ~F32, ~EMV.State(), ~EMV.clone, ~EMV.next, state, bar)

def CVI.preview(state: CVI.State(), bar: Bars.HL<F32>) -> CVI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~CVI.State(), ~CVI.clone, ~CVI.next, state, bar)

def MASSI.preview(state: MASSI.State(), bar: Bars.HL<F32>) -> MASSI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~MASSI.State(), ~MASSI.clone, ~MASSI.next, state, bar)

def Pattern.preview(state: Pattern.State(), bar: Bars.OHLC<F32>) -> Pattern.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~Pattern.State(), ~Pattern.clone, ~Pattern.next, state, bar)

def CDL2CROWS.preview(state: CDL2CROWS.State(), bar: Bars.OHLC<F32>) -> CDL2CROWS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL2CROWS.State(), ~CDL2CROWS.clone, ~CDL2CROWS.next, state, bar)

def CDL3BLACKCROWS.preview(state: CDL3BLACKCROWS.State(), bar: Bars.OHLC<F32>) -> CDL3BLACKCROWS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL3BLACKCROWS.State(), ~CDL3BLACKCROWS.clone, ~CDL3BLACKCROWS.next, state, bar)

def CDL3INSIDE.preview(state: CDL3INSIDE.State(), bar: Bars.OHLC<F32>) -> CDL3INSIDE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL3INSIDE.State(), ~CDL3INSIDE.clone, ~CDL3INSIDE.next, state, bar)

def CDL3LINESTRIKE.preview(state: CDL3LINESTRIKE.State(), bar: Bars.OHLC<F32>) -> CDL3LINESTRIKE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL3LINESTRIKE.State(), ~CDL3LINESTRIKE.clone, ~CDL3LINESTRIKE.next, state, bar)

def CDL3OUTSIDE.preview(state: CDL3OUTSIDE.State(), bar: Bars.OHLC<F32>) -> CDL3OUTSIDE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL3OUTSIDE.State(), ~CDL3OUTSIDE.clone, ~CDL3OUTSIDE.next, state, bar)

def CDL3STARSINSOUTH.preview(state: CDL3STARSINSOUTH.State(), bar: Bars.OHLC<F32>) -> CDL3STARSINSOUTH.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL3STARSINSOUTH.State(), ~CDL3STARSINSOUTH.clone, ~CDL3STARSINSOUTH.next, state, bar)

def CDL3WHITESOLDIERS.preview(state: CDL3WHITESOLDIERS.State(), bar: Bars.OHLC<F32>) -> CDL3WHITESOLDIERS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDL3WHITESOLDIERS.State(), ~CDL3WHITESOLDIERS.clone, ~CDL3WHITESOLDIERS.next, state, bar)

def CDLABANDONEDBABY.preview(state: CDLABANDONEDBABY.State(), bar: Bars.OHLC<F32>) -> CDLABANDONEDBABY.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLABANDONEDBABY.State(), ~CDLABANDONEDBABY.clone, ~CDLABANDONEDBABY.next, state, bar)

def CDLADVANCEBLOCK.preview(state: CDLADVANCEBLOCK.State(), bar: Bars.OHLC<F32>) -> CDLADVANCEBLOCK.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLADVANCEBLOCK.State(), ~CDLADVANCEBLOCK.clone, ~CDLADVANCEBLOCK.next, state, bar)

def CDLBELTHOLD.preview(state: CDLBELTHOLD.State(), bar: Bars.OHLC<F32>) -> CDLBELTHOLD.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLBELTHOLD.State(), ~CDLBELTHOLD.clone, ~CDLBELTHOLD.next, state, bar)

def CDLBREAKAWAY.preview(state: CDLBREAKAWAY.State(), bar: Bars.OHLC<F32>) -> CDLBREAKAWAY.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLBREAKAWAY.State(), ~CDLBREAKAWAY.clone, ~CDLBREAKAWAY.next, state, bar)

def CDLCLOSINGMARUBOZU.preview(state: CDLCLOSINGMARUBOZU.State(), bar: Bars.OHLC<F32>) -> CDLCLOSINGMARUBOZU.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLCLOSINGMARUBOZU.State(), ~CDLCLOSINGMARUBOZU.clone, ~CDLCLOSINGMARUBOZU.next, state, bar)

def CDLCONCEALBABYSWALL.preview(state: CDLCONCEALBABYSWALL.State(), bar: Bars.OHLC<F32>) -> CDLCONCEALBABYSWALL.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLCONCEALBABYSWALL.State(), ~CDLCONCEALBABYSWALL.clone, ~CDLCONCEALBABYSWALL.next, state, bar)

def CDLCOUNTERATTACK.preview(state: CDLCOUNTERATTACK.State(), bar: Bars.OHLC<F32>) -> CDLCOUNTERATTACK.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLCOUNTERATTACK.State(), ~CDLCOUNTERATTACK.clone, ~CDLCOUNTERATTACK.next, state, bar)

def CDLDARKCLOUDCOVER.preview(state: CDLDARKCLOUDCOVER.State(), bar: Bars.OHLC<F32>) -> CDLDARKCLOUDCOVER.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLDARKCLOUDCOVER.State(), ~CDLDARKCLOUDCOVER.clone, ~CDLDARKCLOUDCOVER.next, state, bar)

def CDLDOJI.preview(state: CDLDOJI.State(), bar: Bars.OHLC<F32>) -> CDLDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLDOJI.State(), ~CDLDOJI.clone, ~CDLDOJI.next, state, bar)

def CDLDOJISTAR.preview(state: CDLDOJISTAR.State(), bar: Bars.OHLC<F32>) -> CDLDOJISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLDOJISTAR.State(), ~CDLDOJISTAR.clone, ~CDLDOJISTAR.next, state, bar)

def CDLDRAGONFLYDOJI.preview(state: CDLDRAGONFLYDOJI.State(), bar: Bars.OHLC<F32>) -> CDLDRAGONFLYDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLDRAGONFLYDOJI.State(), ~CDLDRAGONFLYDOJI.clone, ~CDLDRAGONFLYDOJI.next, state, bar)

def CDLENGULFING.preview(state: CDLENGULFING.State(), bar: Bars.OHLC<F32>) -> CDLENGULFING.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLENGULFING.State(), ~CDLENGULFING.clone, ~CDLENGULFING.next, state, bar)

def CDLEVENINGDOJISTAR.preview(state: CDLEVENINGDOJISTAR.State(), bar: Bars.OHLC<F32>) -> CDLEVENINGDOJISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLEVENINGDOJISTAR.State(), ~CDLEVENINGDOJISTAR.clone, ~CDLEVENINGDOJISTAR.next, state, bar)

def CDLEVENINGSTAR.preview(state: CDLEVENINGSTAR.State(), bar: Bars.OHLC<F32>) -> CDLEVENINGSTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLEVENINGSTAR.State(), ~CDLEVENINGSTAR.clone, ~CDLEVENINGSTAR.next, state, bar)

def CDLGAPSIDESIDEWHITE.preview(state: CDLGAPSIDESIDEWHITE.State(), bar: Bars.OHLC<F32>) -> CDLGAPSIDESIDEWHITE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLGAPSIDESIDEWHITE.State(), ~CDLGAPSIDESIDEWHITE.clone, ~CDLGAPSIDESIDEWHITE.next, state, bar)

def CDLGRAVESTONEDOJI.preview(state: CDLGRAVESTONEDOJI.State(), bar: Bars.OHLC<F32>) -> CDLGRAVESTONEDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLGRAVESTONEDOJI.State(), ~CDLGRAVESTONEDOJI.clone, ~CDLGRAVESTONEDOJI.next, state, bar)

def CDLHAMMER.preview(state: CDLHAMMER.State(), bar: Bars.OHLC<F32>) -> CDLHAMMER.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHAMMER.State(), ~CDLHAMMER.clone, ~CDLHAMMER.next, state, bar)

def CDLHANGINGMAN.preview(state: CDLHANGINGMAN.State(), bar: Bars.OHLC<F32>) -> CDLHANGINGMAN.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHANGINGMAN.State(), ~CDLHANGINGMAN.clone, ~CDLHANGINGMAN.next, state, bar)

def CDLHARAMI.preview(state: CDLHARAMI.State(), bar: Bars.OHLC<F32>) -> CDLHARAMI.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHARAMI.State(), ~CDLHARAMI.clone, ~CDLHARAMI.next, state, bar)

def CDLHARAMICROSS.preview(state: CDLHARAMICROSS.State(), bar: Bars.OHLC<F32>) -> CDLHARAMICROSS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHARAMICROSS.State(), ~CDLHARAMICROSS.clone, ~CDLHARAMICROSS.next, state, bar)

def CDLHIGHWAVE.preview(state: CDLHIGHWAVE.State(), bar: Bars.OHLC<F32>) -> CDLHIGHWAVE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHIGHWAVE.State(), ~CDLHIGHWAVE.clone, ~CDLHIGHWAVE.next, state, bar)

def CDLHOMINGPIGEON.preview(state: CDLHOMINGPIGEON.State(), bar: Bars.OHLC<F32>) -> CDLHOMINGPIGEON.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHOMINGPIGEON.State(), ~CDLHOMINGPIGEON.clone, ~CDLHOMINGPIGEON.next, state, bar)

def CDLIDENTICAL3CROWS.preview(state: CDLIDENTICAL3CROWS.State(), bar: Bars.OHLC<F32>) -> CDLIDENTICAL3CROWS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLIDENTICAL3CROWS.State(), ~CDLIDENTICAL3CROWS.clone, ~CDLIDENTICAL3CROWS.next, state, bar)

def CDLINNECK.preview(state: CDLINNECK.State(), bar: Bars.OHLC<F32>) -> CDLINNECK.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLINNECK.State(), ~CDLINNECK.clone, ~CDLINNECK.next, state, bar)

def CDLINVERTEDHAMMER.preview(state: CDLINVERTEDHAMMER.State(), bar: Bars.OHLC<F32>) -> CDLINVERTEDHAMMER.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLINVERTEDHAMMER.State(), ~CDLINVERTEDHAMMER.clone, ~CDLINVERTEDHAMMER.next, state, bar)

def CDLKICKING.preview(state: CDLKICKING.State(), bar: Bars.OHLC<F32>) -> CDLKICKING.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLKICKING.State(), ~CDLKICKING.clone, ~CDLKICKING.next, state, bar)

def CDLKICKINGBYLENGTH.preview(state: CDLKICKINGBYLENGTH.State(), bar: Bars.OHLC<F32>) -> CDLKICKINGBYLENGTH.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLKICKINGBYLENGTH.State(), ~CDLKICKINGBYLENGTH.clone, ~CDLKICKINGBYLENGTH.next, state, bar)

def CDLLADDERBOTTOM.preview(state: CDLLADDERBOTTOM.State(), bar: Bars.OHLC<F32>) -> CDLLADDERBOTTOM.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLLADDERBOTTOM.State(), ~CDLLADDERBOTTOM.clone, ~CDLLADDERBOTTOM.next, state, bar)

def CDLLONGLEGGEDDOJI.preview(state: CDLLONGLEGGEDDOJI.State(), bar: Bars.OHLC<F32>) -> CDLLONGLEGGEDDOJI.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLLONGLEGGEDDOJI.State(), ~CDLLONGLEGGEDDOJI.clone, ~CDLLONGLEGGEDDOJI.next, state, bar)

def CDLLONGLINE.preview(state: CDLLONGLINE.State(), bar: Bars.OHLC<F32>) -> CDLLONGLINE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLLONGLINE.State(), ~CDLLONGLINE.clone, ~CDLLONGLINE.next, state, bar)

def CDLMARUBOZU.preview(state: CDLMARUBOZU.State(), bar: Bars.OHLC<F32>) -> CDLMARUBOZU.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLMARUBOZU.State(), ~CDLMARUBOZU.clone, ~CDLMARUBOZU.next, state, bar)

def CDLMATCHINGLOW.preview(state: CDLMATCHINGLOW.State(), bar: Bars.OHLC<F32>) -> CDLMATCHINGLOW.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLMATCHINGLOW.State(), ~CDLMATCHINGLOW.clone, ~CDLMATCHINGLOW.next, state, bar)

def CDLMATHOLD.preview(state: CDLMATHOLD.State(), bar: Bars.OHLC<F32>) -> CDLMATHOLD.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLMATHOLD.State(), ~CDLMATHOLD.clone, ~CDLMATHOLD.next, state, bar)

def CDLMORNINGDOJISTAR.preview(state: CDLMORNINGDOJISTAR.State(), bar: Bars.OHLC<F32>) -> CDLMORNINGDOJISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLMORNINGDOJISTAR.State(), ~CDLMORNINGDOJISTAR.clone, ~CDLMORNINGDOJISTAR.next, state, bar)

def CDLMORNINGSTAR.preview(state: CDLMORNINGSTAR.State(), bar: Bars.OHLC<F32>) -> CDLMORNINGSTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLMORNINGSTAR.State(), ~CDLMORNINGSTAR.clone, ~CDLMORNINGSTAR.next, state, bar)

def CDLONNECK.preview(state: CDLONNECK.State(), bar: Bars.OHLC<F32>) -> CDLONNECK.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLONNECK.State(), ~CDLONNECK.clone, ~CDLONNECK.next, state, bar)

def CDLPIERCING.preview(state: CDLPIERCING.State(), bar: Bars.OHLC<F32>) -> CDLPIERCING.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLPIERCING.State(), ~CDLPIERCING.clone, ~CDLPIERCING.next, state, bar)

def CDLRICKSHAWMAN.preview(state: CDLRICKSHAWMAN.State(), bar: Bars.OHLC<F32>) -> CDLRICKSHAWMAN.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLRICKSHAWMAN.State(), ~CDLRICKSHAWMAN.clone, ~CDLRICKSHAWMAN.next, state, bar)

def CDLRISEFALL3METHODS.preview(state: CDLRISEFALL3METHODS.State(), bar: Bars.OHLC<F32>) -> CDLRISEFALL3METHODS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLRISEFALL3METHODS.State(), ~CDLRISEFALL3METHODS.clone, ~CDLRISEFALL3METHODS.next, state, bar)

def CDLSEPARATINGLINES.preview(state: CDLSEPARATINGLINES.State(), bar: Bars.OHLC<F32>) -> CDLSEPARATINGLINES.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLSEPARATINGLINES.State(), ~CDLSEPARATINGLINES.clone, ~CDLSEPARATINGLINES.next, state, bar)

def CDLSHOOTINGSTAR.preview(state: CDLSHOOTINGSTAR.State(), bar: Bars.OHLC<F32>) -> CDLSHOOTINGSTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLSHOOTINGSTAR.State(), ~CDLSHOOTINGSTAR.clone, ~CDLSHOOTINGSTAR.next, state, bar)

def CDLSHORTLINE.preview(state: CDLSHORTLINE.State(), bar: Bars.OHLC<F32>) -> CDLSHORTLINE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLSHORTLINE.State(), ~CDLSHORTLINE.clone, ~CDLSHORTLINE.next, state, bar)

def CDLSPINNINGTOP.preview(state: CDLSPINNINGTOP.State(), bar: Bars.OHLC<F32>) -> CDLSPINNINGTOP.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLSPINNINGTOP.State(), ~CDLSPINNINGTOP.clone, ~CDLSPINNINGTOP.next, state, bar)

def CDLSTALLEDPATTERN.preview(state: CDLSTALLEDPATTERN.State(), bar: Bars.OHLC<F32>) -> CDLSTALLEDPATTERN.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLSTALLEDPATTERN.State(), ~CDLSTALLEDPATTERN.clone, ~CDLSTALLEDPATTERN.next, state, bar)

def CDLSTICKSANDWICH.preview(state: CDLSTICKSANDWICH.State(), bar: Bars.OHLC<F32>) -> CDLSTICKSANDWICH.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLSTICKSANDWICH.State(), ~CDLSTICKSANDWICH.clone, ~CDLSTICKSANDWICH.next, state, bar)

def CDLTAKURI.preview(state: CDLTAKURI.State(), bar: Bars.OHLC<F32>) -> CDLTAKURI.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLTAKURI.State(), ~CDLTAKURI.clone, ~CDLTAKURI.next, state, bar)

def CDLTASUKIGAP.preview(state: CDLTASUKIGAP.State(), bar: Bars.OHLC<F32>) -> CDLTASUKIGAP.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLTASUKIGAP.State(), ~CDLTASUKIGAP.clone, ~CDLTASUKIGAP.next, state, bar)

def CDLTHRUSTING.preview(state: CDLTHRUSTING.State(), bar: Bars.OHLC<F32>) -> CDLTHRUSTING.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLTHRUSTING.State(), ~CDLTHRUSTING.clone, ~CDLTHRUSTING.next, state, bar)

def CDLTRISTAR.preview(state: CDLTRISTAR.State(), bar: Bars.OHLC<F32>) -> CDLTRISTAR.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLTRISTAR.State(), ~CDLTRISTAR.clone, ~CDLTRISTAR.next, state, bar)

def CDLUNIQUE3RIVER.preview(state: CDLUNIQUE3RIVER.State(), bar: Bars.OHLC<F32>) -> CDLUNIQUE3RIVER.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLUNIQUE3RIVER.State(), ~CDLUNIQUE3RIVER.clone, ~CDLUNIQUE3RIVER.next, state, bar)

def CDLUPSIDEGAP2CROWS.preview(state: CDLUPSIDEGAP2CROWS.State(), bar: Bars.OHLC<F32>) -> CDLUPSIDEGAP2CROWS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLUPSIDEGAP2CROWS.State(), ~CDLUPSIDEGAP2CROWS.clone, ~CDLUPSIDEGAP2CROWS.next, state, bar)

def CDLXSIDEGAP3METHODS.preview(state: CDLXSIDEGAP3METHODS.State(), bar: Bars.OHLC<F32>) -> CDLXSIDEGAP3METHODS.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLXSIDEGAP3METHODS.State(), ~CDLXSIDEGAP3METHODS.clone, ~CDLXSIDEGAP3METHODS.next, state, bar)

def VIDYA.preview(state: VIDYA.State(), price: F32) -> VIDYA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~VIDYA.State(), ~VIDYA.clone, ~VIDYA.next, state, price)

def MAMA.preview(state: MAMA.State(), price: F32) -> MAMA.State() & Maybe<&2, MAMA.Value()>:
  Clone.preview(~F32, ~MAMA.Value(), ~MAMA.State(), ~MAMA.clone, ~MAMA.next, state, price)

def MA.preview(state: MA.State(), price: F32) -> MA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~MA.State(), ~MA.clone, ~MA.next, state, price)

def WMA.preview(state: WMA.State(), price: F32) -> WMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~WMA.State(), ~WMA.clone, ~WMA.next, state, price)

def DEMA.preview(state: DEMA.State(), price: F32) -> DEMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~DEMA.State(), ~DEMA.clone, ~DEMA.next, state, price)

def TEMA.preview(state: TEMA.State(), price: F32) -> TEMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~TEMA.State(), ~TEMA.clone, ~TEMA.next, state, price)

def TRIMA.preview(state: TRIMA.State(), price: F32) -> TRIMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~TRIMA.State(), ~TRIMA.clone, ~TRIMA.next, state, price)

def KAMA.preview(state: KAMA.State(), price: F32) -> KAMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~KAMA.State(), ~KAMA.clone, ~KAMA.next, state, price)

def HMA.preview(state: HMA.State(), price: F32) -> HMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~HMA.State(), ~HMA.clone, ~HMA.next, state, price)

def ZLEMA.preview(state: ZLEMA.State(), price: F32) -> ZLEMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ZLEMA.State(), ~ZLEMA.clone, ~ZLEMA.next, state, price)

def T3.preview(state: T3.State(), price: F32) -> T3.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~T3.State(), ~T3.clone, ~T3.next, state, price)

def ALMA.preview(state: ALMA.State(), price: F32) -> ALMA.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ALMA.State(), ~ALMA.clone, ~ALMA.next, state, price)

def LINEARREG.preview(state: LINEARREG.State(), price: F32) -> LINEARREG.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~LINEARREG.State(), ~LINEARREG.clone, ~LINEARREG.next, state, price)

def LINEARREG_SLOPE.preview(state: LINEARREG_SLOPE.State(), price: F32) -> LINEARREG_SLOPE.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~LINEARREG_SLOPE.State(), ~LINEARREG_SLOPE.clone, ~LINEARREG_SLOPE.next, state, price)

def LINEARREG_INTERCEPT.preview(state: LINEARREG_INTERCEPT.State(), price: F32) -> LINEARREG_INTERCEPT.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~LINEARREG_INTERCEPT.State(), ~LINEARREG_INTERCEPT.clone, ~LINEARREG_INTERCEPT.next, state, price)

def LINEARREG_ANGLE.preview(state: LINEARREG_ANGLE.State(), price: F32) -> LINEARREG_ANGLE.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~LINEARREG_ANGLE.State(), ~LINEARREG_ANGLE.clone, ~LINEARREG_ANGLE.next, state, price)

def TSF.preview(state: TSF.State(), price: F32) -> TSF.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~TSF.State(), ~TSF.clone, ~TSF.next, state, price)

def MAX.preview(state: MAX.State(), price: F32) -> MAX.State() & Maybe<&2, MAX.Value()>:
  Clone.preview(~F32, ~MAX.Value(), ~MAX.State(), ~MAX.clone, ~MAX.next, state, price)

def MIN.preview(state: MIN.State(), price: F32) -> MIN.State() & Maybe<&2, MIN.Value()>:
  Clone.preview(~F32, ~MIN.Value(), ~MIN.State(), ~MIN.clone, ~MIN.next, state, price)

def MAXINDEX.preview(state: MAXINDEX.State(), price: F32) -> MAXINDEX.State() & Maybe<&2, MAXINDEX.Value()>:
  Clone.preview(~F32, ~MAXINDEX.Value(), ~MAXINDEX.State(), ~MAXINDEX.clone, ~MAXINDEX.next, state, price)

def MININDEX.preview(state: MININDEX.State(), price: F32) -> MININDEX.State() & Maybe<&2, MININDEX.Value()>:
  Clone.preview(~F32, ~MININDEX.Value(), ~MININDEX.State(), ~MININDEX.clone, ~MININDEX.next, state, price)

def MINMAX.preview(state: MINMAX.State(), price: F32) -> MINMAX.State() & Maybe<&2, MINMAX.Value()>:
  Clone.preview(~F32, ~MINMAX.Value(), ~MINMAX.State(), ~MINMAX.clone, ~MINMAX.next, state, price)

def MINMAXINDEX.preview(state: MINMAXINDEX.State(), price: F32) -> MINMAXINDEX.State() & Maybe<&2, MINMAXINDEX.Value()>:
  Clone.preview(~F32, ~MINMAXINDEX.Value(), ~MINMAXINDEX.State(), ~MINMAXINDEX.clone, ~MINMAXINDEX.next, state, price)

def MEDIAN.preview(state: MEDIAN.State(), price: F32) -> MEDIAN.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~MEDIAN.State(), ~MEDIAN.clone, ~MEDIAN.next, state, price)

def PERCENTRANK.preview(state: PERCENTRANK.State(), price: F32) -> PERCENTRANK.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~PERCENTRANK.State(), ~PERCENTRANK.clone, ~PERCENTRANK.next, state, price)

def AVGDEV.preview(state: AVGDEV.State(), price: F32) -> AVGDEV.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~AVGDEV.State(), ~AVGDEV.clone, ~AVGDEV.next, state, price)

def STDDEV.preview(state: STDDEV.State(), price: F32) -> STDDEV.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~STDDEV.State(), ~STDDEV.clone, ~STDDEV.next, state, price)

def PERCENTILE.preview(state: PERCENTILE.State(), price: F32) -> PERCENTILE.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~PERCENTILE.State(), ~PERCENTILE.clone, ~PERCENTILE.next, state, price)

def MIDPOINT.preview(state: MIDPOINT.State(), price: F32) -> MIDPOINT.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~MIDPOINT.State(), ~MIDPOINT.clone, ~MIDPOINT.next, state, price)

def DONCHIAN.preview(state: DONCHIAN.State(), bar: Bars.HL<F32>) -> DONCHIAN.State() & Maybe<&2, DONCHIAN.Value()>:
  Clone.preview(~Bars.HL<F32>, ~DONCHIAN.Value(), ~DONCHIAN.State(), ~DONCHIAN.clone, ~DONCHIAN.next, state, bar)

def MIDPRICE.preview(state: MIDPRICE.State(), bar: Bars.HL<F32>) -> MIDPRICE.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~MIDPRICE.State(), ~MIDPRICE.clone, ~MIDPRICE.next, state, bar)

def BBANDS.preview(state: BBANDS.State(), price: F32) -> BBANDS.State() & Maybe<&2, BBANDS.Value()>:
  Clone.preview(~F32, ~BBANDS.Value(), ~BBANDS.State(), ~BBANDS.clone, ~BBANDS.next, state, price)

def BBW.preview(state: BBW.State(), price: F32) -> BBW.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~BBW.State(), ~BBW.clone, ~BBW.next, state, price)

def PERCENTB.preview(state: PERCENTB.State(), price: F32) -> PERCENTB.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~PERCENTB.State(), ~PERCENTB.clone, ~PERCENTB.next, state, price)

def ACCBANDS.preview(state: ACCBANDS.State(), bar: Bars.HLC<F32>) -> ACCBANDS.State() & Maybe<&2, ACCBANDS.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~ACCBANDS.Value(), ~ACCBANDS.State(), ~ACCBANDS.clone, ~ACCBANDS.next, state, bar)

def VWMA.preview(state: VWMA.State(), bar: Bars.CV<F32>) -> VWMA.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.CV<F32>, ~F32, ~VWMA.State(), ~VWMA.clone, ~VWMA.next, state, bar)

def HA.preview(state: HA.State(), bar: HA.Value()) -> HA.State() & Maybe<&2, HA.Value()>:
  Clone.preview(~HA.Value(), ~HA.Value(), ~HA.State(), ~HA.clone, ~HA.next, state, bar)

def KC.preview(state: KC.State(), bar: Bars.HLC<F32>) -> KC.State() & Maybe<&2, KC.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~KC.Value(), ~KC.State(), ~KC.clone, ~KC.next, state, bar)

def CKSP.preview(state: CKSP.State(), bar: Bars.HLC<F32>) -> CKSP.State() & Maybe<&2, CKSP.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~CKSP.Value(), ~CKSP.State(), ~CKSP.clone, ~CKSP.next, state, bar)

def RSI.preview(state: RSI.State(), value: F32) -> RSI.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~RSI.State(), ~RSI.clone, ~RSI.next, state, value)

def CMO.preview(state: CMO.State(), value: F32) -> CMO.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~CMO.State(), ~CMO.clone, ~CMO.next, state, value)

def CMOU.preview(state: CMOU.State(), value: F32) -> CMOU.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~CMOU.State(), ~CMOU.clone, ~CMOU.next, state, value)

def IMI.preview(state: IMI.State(), value: Bars.OHLC<F32>) -> IMI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.OHLC<F32>, ~F32, ~IMI.State(), ~IMI.clone, ~IMI.next, state, value)

def PLUS_DM.preview(state: PLUS_DM.State(), value: Bars.HL<F32>) -> PLUS_DM.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~PLUS_DM.State(), ~PLUS_DM.clone, ~PLUS_DM.next, state, value)

def MINUS_DM.preview(state: MINUS_DM.State(), value: Bars.HL<F32>) -> MINUS_DM.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~MINUS_DM.State(), ~MINUS_DM.clone, ~MINUS_DM.next, state, value)

def PLUS_DI.preview(state: PLUS_DI.State(), value: Bars.HLC<F32>) -> PLUS_DI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~PLUS_DI.State(), ~PLUS_DI.clone, ~PLUS_DI.next, state, value)

def MINUS_DI.preview(state: MINUS_DI.State(), value: Bars.HLC<F32>) -> MINUS_DI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~MINUS_DI.State(), ~MINUS_DI.clone, ~MINUS_DI.next, state, value)

def DX.preview(state: DX.State(), value: Bars.HLC<F32>) -> DX.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~DX.State(), ~DX.clone, ~DX.next, state, value)

def ADX.preview(state: ADX.State(), value: Bars.HLC<F32>) -> ADX.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~ADX.State(), ~ADX.clone, ~ADX.next, state, value)

def ADXR.preview(state: ADXR.State(), value: Bars.HLC<F32>) -> ADXR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~ADXR.State(), ~ADXR.clone, ~ADXR.next, state, value)

def SI.preview(state: SI.State(), value: Bars.OHLC<F32>) -> SI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.OHLC<F32>, ~F32, ~SI.State(), ~SI.clone, ~SI.next, state, value)

def ASI.preview(state: ASI.State(), value: Bars.OHLC<F32>) -> ASI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.OHLC<F32>, ~F32, ~ASI.State(), ~ASI.clone, ~ASI.next, state, value)

def WAD.preview(state: WAD.State(), value: Bars.HLC<F32>) -> WAD.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~WAD.State(), ~WAD.clone, ~WAD.next, state, value)

def WILLR.preview(state: WILLR.State(), value: Bars.HLC<F32>) -> WILLR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~WILLR.State(), ~WILLR.clone, ~WILLR.next, state, value)

def AROON.preview(state: AROON.State(), value: Bars.HL<F32>) -> AROON.State() & Maybe<&2, AROON.Value()>:
  Clone.preview(~Bars.HL<F32>, ~AROON.Value(), ~AROON.State(), ~AROON.clone, ~AROON.next, state, value)

def AROONOSC.preview(state: AROONOSC.State(), value: Bars.HL<F32>) -> AROONOSC.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~AROONOSC.State(), ~AROONOSC.clone, ~AROONOSC.next, state, value)

def ER.preview(state: ER.State(), value: F32) -> ER.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~ER.State(), ~ER.clone, ~ER.next, state, value)

def VHF.preview(state: VHF.State(), value: F32) -> VHF.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~VHF.State(), ~VHF.clone, ~VHF.next, state, value)

def APO.preview(state: APO.State(), value: F32) -> APO.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~APO.State(), ~APO.clone, ~APO.next, state, value)

def PPO.preview(state: PPO.State(), value: F32) -> PPO.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~PPO.State(), ~PPO.clone, ~PPO.next, state, value)

def AO.preview(state: AO.State(), value: Bars.HL<F32>) -> AO.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~AO.State(), ~AO.clone, ~AO.next, state, value)

def AC.preview(state: AC.State(), value: Bars.HL<F32>) -> AC.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~AC.State(), ~AC.clone, ~AC.next, state, value)

def MACD.preview(state: MACD.State(), value: F32) -> MACD.State() & Maybe<&2, MACD.Value()>:
  Clone.preview(~F32, ~MACD.Value(), ~MACD.State(), ~MACD.clone, ~MACD.next, state, value)

def MACDFIX.preview(state: MACDFIX.State(), value: F32) -> MACDFIX.State() & Maybe<&2, MACD.Value()>:
  Clone.preview(~F32, ~MACD.Value(), ~MACDFIX.State(), ~MACDFIX.clone, ~MACDFIX.next, state, value)

def STOCH.preview(state: STOCH.State(), value: Bars.HLC<F32>) -> STOCH.State() & Maybe<&2, STOCH.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~STOCH.Value(), ~STOCH.State(), ~STOCH.clone, ~STOCH.next, state, value)

def KDJ.preview(state: KDJ.State(), value: Bars.HLC<F32>) -> KDJ.State() & Maybe<&2, STOCH.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~STOCH.Value(), ~KDJ.State(), ~KDJ.clone, ~KDJ.next, state, value)

def STOCHF.preview(state: STOCHF.State(), value: Bars.HLC<F32>) -> STOCHF.State() & Maybe<&2, STOCH.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~STOCH.Value(), ~STOCHF.State(), ~STOCHF.clone, ~STOCHF.next, state, value)

def STOCHRSI.preview(state: STOCHRSI.State(), value: F32) -> STOCHRSI.State() & Maybe<&2, STOCH.Value()>:
  Clone.preview(~F32, ~STOCH.Value(), ~STOCHRSI.State(), ~STOCHRSI.clone, ~STOCHRSI.next, state, value)

def TRIX.preview(state: TRIX.State(), value: F32) -> TRIX.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~TRIX.State(), ~TRIX.clone, ~TRIX.next, state, value)

def DOSC.preview(state: DOSC.State(), value: F32) -> DOSC.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~DOSC.State(), ~DOSC.clone, ~DOSC.next, state, value)

def PSO.preview(state: PSO.State(), value: Bars.HLC<F32>) -> PSO.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~PSO.State(), ~PSO.clone, ~PSO.next, state, value)

def TSI.preview(state: TSI.State(), value: F32) -> TSI.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~TSI.State(), ~TSI.clone, ~TSI.next, state, value)

def QSTICK.preview(state: QSTICK.State(), value: Bars.OHLC<F32>) -> QSTICK.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.OHLC<F32>, ~F32, ~QSTICK.State(), ~QSTICK.clone, ~QSTICK.next, state, value)

def ERI.preview(state: ERI.State(), value: Bars.HLC<F32>) -> ERI.State() & Maybe<&2, ERI.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~ERI.Value(), ~ERI.State(), ~ERI.clone, ~ERI.next, state, value)

def FOSC.preview(state: FOSC.State(), value: F32) -> FOSC.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~FOSC.State(), ~FOSC.clone, ~FOSC.next, state, value)

def CCI.preview(state: CCI.State(), value: Bars.HLC<F32>) -> CCI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~CCI.State(), ~CCI.clone, ~CCI.next, state, value)

def MFI.preview(state: MFI.State(), value: Bars.HLCV<F32>) -> MFI.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLCV<F32>, ~F32, ~MFI.State(), ~MFI.clone, ~MFI.next, state, value)

def CHOP.preview(state: CHOP.State(), value: Bars.HLC<F32>) -> CHOP.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~CHOP.State(), ~CHOP.clone, ~CHOP.next, state, value)

def CHOPTR.preview(state: CHOPTR.State(), value: Bars.HLC<F32>) -> CHOPTR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~CHOPTR.State(), ~CHOPTR.clone, ~CHOPTR.next, state, value)

def VORTEX.preview(state: VORTEX.State(), value: Bars.HLC<F32>) -> VORTEX.State() & Maybe<&2, VORTEX.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~VORTEX.Value(), ~VORTEX.State(), ~VORTEX.clone, ~VORTEX.next, state, value)

def ULTOSC.preview(state: ULTOSC.State(), value: Bars.HLC<F32>) -> ULTOSC.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLC<F32>, ~F32, ~ULTOSC.State(), ~ULTOSC.clone, ~ULTOSC.next, state, value)

def COPPOCK.preview(state: COPPOCK.State(), value: F32) -> COPPOCK.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~COPPOCK.State(), ~COPPOCK.clone, ~COPPOCK.next, state, value)

def KST.preview(state: KST.State(), value: F32) -> KST.State() & Maybe<&2, KST.Value()>:
  Clone.preview(~F32, ~KST.Value(), ~KST.State(), ~KST.clone, ~KST.next, state, value)

def PVO.preview(state: PVO.State(), volume: F32) -> PVO.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~PVO.State(), ~PVO.clone, ~PVO.next, state, volume)

def DPO.preview(state: DPO.State(), price: F32) -> DPO.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~DPO.State(), ~DPO.clone, ~DPO.next, state, price)

def RVOL.preview(state: RVOL.State(), volume: F32) -> RVOL.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~RVOL.State(), ~RVOL.clone, ~RVOL.next, state, volume)

def ICHIMOKU.preview(state: ICHIMOKU.State(), bar: Bars.HL<F32>) -> ICHIMOKU.State() & Maybe<&2, ICHIMOKU.Value()>:
  Clone.preview(~Bars.HL<F32>, ~ICHIMOKU.Value(), ~ICHIMOKU.State(), ~ICHIMOKU.clone, ~ICHIMOKU.next, state, bar)

def FRACTAL.preview(state: FRACTAL.State(), bar: Bars.HL<F32>) -> FRACTAL.State() & Maybe<&2, FRACTAL.Value()>:
  Clone.preview(~Bars.HL<F32>, ~FRACTAL.Value(), ~FRACTAL.State(), ~FRACTAL.clone, ~FRACTAL.next, state, bar)

def VWAP.preview(state: VWAP.State(), bar: Bars.HLCV<F32>) -> VWAP.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLCV<F32>, ~F32, ~VWAP.State(), ~VWAP.clone, ~VWAP.next, state, bar)

def ZIGZAG.preview(state: ZIGZAG.State(), bar: Bars.HL<F32>) -> ZIGZAG.State() & Maybe<&2, ZIGZAG.Value()>:
  Clone.preview(~Bars.HL<F32>, ~ZIGZAG.Value(), ~ZIGZAG.State(), ~ZIGZAG.clone, ~ZIGZAG.next, state, bar)

def MAVP.preview(state: MAVP.State(), sample: MAVP.Sample()) -> MAVP.State() & Maybe<&2, F32>:
  Clone.preview(~MAVP.Sample(), ~F32, ~MAVP.State(), ~MAVP.clone, ~MAVP.next, state, sample)

def FRAMA.preview(state: FRAMA.State(), value: Bars.HL<F32>) -> FRAMA.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~FRAMA.State(), ~FRAMA.clone, ~FRAMA.next, state, value)

def MCGD.preview(state: MCGD.State(), value: F32) -> MCGD.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~MCGD.State(), ~MCGD.clone, ~MCGD.next, state, value)

def SAR.preview(state: SAR.State(), value: Bars.HL<F32>) -> SAR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~SAR.State(), ~SAR.clone, ~SAR.next, state, value)

def SAREXT.preview(state: SAREXT.State(), value: Bars.HL<F32>) -> SAREXT.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~SAREXT.State(), ~SAREXT.clone, ~SAREXT.next, state, value)

def SUPERTREND.preview(state: SUPERTREND.State(), value: Bars.HLC<F32>) -> SUPERTREND.State() & Maybe<&2, SUPERTREND.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~SUPERTREND.Value(), ~SUPERTREND.State(), ~SUPERTREND.clone, ~SUPERTREND.next, state, value)

def CG.preview(state: CG.State(), value: F32) -> CG.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~CG.State(), ~CG.clone, ~CG.next, state, value)

def CTI.preview(state: CTI.State(), value: F32) -> CTI.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~CTI.State(), ~CTI.clone, ~CTI.next, state, value)

def FISHER.preview(state: FISHER.State(), value: Bars.HL<F32>) -> FISHER.State() & Maybe<&2, FISHER.Value()>:
  Clone.preview(~Bars.HL<F32>, ~FISHER.Value(), ~FISHER.State(), ~FISHER.clone, ~FISHER.next, state, value)

def CRSI.preview(state: CRSI.State(), value: F32) -> CRSI.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~CRSI.State(), ~CRSI.clone, ~CRSI.next, state, value)

def SMI.preview(state: SMI.State(), value: Bars.HLC<F32>) -> SMI.State() & Maybe<&2, SMI.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~SMI.Value(), ~SMI.State(), ~SMI.clone, ~SMI.next, state, value)

def STC.preview(state: STC.State(), value: F32) -> STC.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~STC.State(), ~STC.clone, ~STC.next, state, value)

def WAVETREND.preview(state: WAVETREND.State(), value: Bars.HLC<F32>) -> WAVETREND.State() & Maybe<&2, WAVETREND.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~WAVETREND.Value(), ~WAVETREND.State(), ~WAVETREND.clone, ~WAVETREND.next, state, value)

def MACDEXT.preview(state: MACDEXT.State(), value: F32) -> MACDEXT.State() & Maybe<&2, MACDEXT.Value()>:
  Clone.preview(~F32, ~MACDEXT.Value(), ~MACDEXT.State(), ~MACDEXT.clone, ~MACDEXT.next, state, value)

def KSTEXT.preview(state: KSTEXT.State(), value: F32) -> KSTEXT.State() & Maybe<&2, KSTEXT.Value()>:
  Clone.preview(~F32, ~KSTEXT.Value(), ~KSTEXT.State(), ~KSTEXT.clone, ~KSTEXT.next, state, value)

def SQZMOM.preview(state: SQZMOM.State(), value: Bars.HLC<F32>) -> SQZMOM.State() & Maybe<&2, SQZMOM.Value()>:
  Clone.preview(~Bars.HLC<F32>, ~SQZMOM.Value(), ~SQZMOM.State(), ~SQZMOM.clone, ~SQZMOM.next, state, value)

def ADOSC.preview(state: ADOSC.State(), value: Bars.HLCV<F32>) -> ADOSC.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HLCV<F32>, ~F32, ~ADOSC.State(), ~ADOSC.clone, ~ADOSC.next, state, value)

def KVO.preview(state: KVO.State(), value: Bars.HLCV<F32>) -> KVO.State() & Maybe<&2, KVO.Value()>:
  Clone.preview(~Bars.HLCV<F32>, ~KVO.Value(), ~KVO.State(), ~KVO.clone, ~KVO.next, state, value)

def VAR.preview(state: VAR.State(), value: F32) -> VAR.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~VAR.State(), ~VAR.clone, ~VAR.next, state, value)

def CORREL.preview(state: CORREL.State(), value: PairValue()) -> CORREL.State() & Maybe<&2, F32>:
  Clone.preview(~PairValue(), ~F32, ~CORREL.State(), ~CORREL.clone, ~CORREL.next, state, value)

def BETA.preview(state: BETA.State(), value: PairValue()) -> BETA.State() & Maybe<&2, F32>:
  Clone.preview(~PairValue(), ~F32, ~BETA.State(), ~BETA.clone, ~BETA.next, state, value)

def KURTOSIS.preview(state: KURTOSIS.State(), value: F32) -> KURTOSIS.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~KURTOSIS.State(), ~KURTOSIS.clone, ~KURTOSIS.next, state, value)

def ROGERSSATCHELL.preview(state: ROGERSSATCHELL.State(), value: Bars.OHLC<F32>) -> ROGERSSATCHELL.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.OHLC<F32>, ~F32, ~ROGERSSATCHELL.State(), ~ROGERSSATCHELL.clone, ~ROGERSSATCHELL.next, state, value)

def RVI.preview(state: RVI.State(), value: F32) -> RVI.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~RVI.State(), ~RVI.clone, ~RVI.next, state, value)

def RVIR.preview(state: RVIR.State(), value: Bars.HL<F32>) -> RVIR.State() & Maybe<&2, F32>:
  Clone.preview(~Bars.HL<F32>, ~F32, ~RVIR.State(), ~RVIR.clone, ~RVIR.next, state, value)

def CDLHIKKAKE.preview(state: CDLHIKKAKE.State(), bar: Bars.OHLC<F32>) -> CDLHIKKAKE.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHIKKAKE.State(), ~CDLHIKKAKE.clone, ~CDLHIKKAKE.next, state, bar)

def CDLHIKKAKEMOD.preview(state: CDLHIKKAKEMOD.State(), bar: Bars.OHLC<F32>) -> CDLHIKKAKEMOD.State() & Maybe<&2, Pattern.Signal()>:
  Clone.preview(~Bars.OHLC<F32>, ~Pattern.Signal(), ~CDLHIKKAKEMOD.State(), ~CDLHIKKAKEMOD.clone, ~CDLHIKKAKEMOD.next, state, bar)

def HT_DCPERIOD.preview(state: HT_DCPERIOD.State(), value: F32) -> HT_DCPERIOD.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~HT_DCPERIOD.State(), ~HT_DCPERIOD.clone, ~HT_DCPERIOD.next, state, value)

def HT_PHASOR.preview(state: HT_PHASOR.State(), value: F32) -> HT_PHASOR.State() & Maybe<&2, HT_PHASOR.Value()>:
  Clone.preview(~F32, ~HT_PHASOR.Value(), ~HT_PHASOR.State(), ~HT_PHASOR.clone, ~HT_PHASOR.next, state, value)

def HT_TRENDLINE.preview(state: HT_TRENDLINE.State(), value: F32) -> HT_TRENDLINE.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~HT_TRENDLINE.State(), ~HT_TRENDLINE.clone, ~HT_TRENDLINE.next, state, value)

def HT_DCPHASE.preview(state: HT_DCPHASE.State(), value: F32) -> HT_DCPHASE.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~HT_DCPHASE.State(), ~HT_DCPHASE.clone, ~HT_DCPHASE.next, state, value)

def HT_SINE.preview(state: HT_SINE.State(), value: F32) -> HT_SINE.State() & Maybe<&2, HT_SINE.Value()>:
  Clone.preview(~F32, ~HT_SINE.Value(), ~HT_SINE.State(), ~HT_SINE.clone, ~HT_SINE.next, state, value)

def HT_TRENDMODE.preview(state: HT_TRENDMODE.State(), value: F32) -> HT_TRENDMODE.State() & Maybe<&2, U32>:
  Clone.preview(~F32, ~U32, ~HT_TRENDMODE.State(), ~HT_TRENDMODE.clone, ~HT_TRENDMODE.next, state, value)

def SWAK_BUTTER.preview(state: SWAK_BUTTER.State(), value: F32) -> SWAK_BUTTER.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SWAK_BUTTER.State(), ~SWAK_BUTTER.clone, ~SWAK_BUTTER.next, state, value)

def SWAK_GAUSS.preview(state: SWAK_GAUSS.State(), value: F32) -> SWAK_GAUSS.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SWAK_GAUSS.State(), ~SWAK_GAUSS.clone, ~SWAK_GAUSS.next, state, value)

def SWAK_2PHP.preview(state: SWAK_2PHP.State(), value: F32) -> SWAK_2PHP.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SWAK_2PHP.State(), ~SWAK_2PHP.clone, ~SWAK_2PHP.next, state, value)

def SWAK_BP.preview(state: SWAK_BP.State(), value: F32) -> SWAK_BP.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SWAK_BP.State(), ~SWAK_BP.clone, ~SWAK_BP.next, state, value)

def SWAK_HP.preview(state: SWAK_HP.State(), value: F32) -> SWAK_HP.State() & Maybe<&2, F32>:
  Clone.preview(~F32, ~F32, ~SWAK_HP.State(), ~SWAK_HP.clone, ~SWAK_HP.next, state, value)
