import Base
import ./src/f32.bend as TA
import ./src/core/bar.bend as Bars
import ./src/core/candle.bend as Candle
import ./src/core/statistics_window.bend as StatWindow
import ./src/core/transform.bend as Transform
import ./src/core/variable.bend as Variable
import ./src/core/momentum_smooth.bend as Momentum
import ./src/core/overlap.bend as Overlap
import ./src/core/window.bend as Window
import ./src/core/clone.bend as Clone
import ./src/core/series.bend as Series
import ./proofs/series.bend as SeriesProof
import ./src/core/config.bend as Config
import ./src/core/ema.bend as Ema
import ./src/core/sma.bend as Sma
import ./src/core/parameters.bend as Parameters
import ./src/core/pattern_state.bend as PatternState
import ./proofs/contracts.bend as Contracts
import ./proofs/window_history.bend as History
import ./src/core/extrema.bend as Ext
import ./src/core/moments.bend as Stats
import ./src/core/patterns.bend as Patterns
import ./src/core/mama.bend as Mama
import ./src/core/statistics.bend as Statistics
import ./src/core/momentum_window.bend as MomentumWindow
import ./src/core/momentum_market.bend as MomentumMarket
import ./src/core/window_signals.bend as WindowSignals
import ./src/core/market_state.bend as MarketState
import ./src/core/trend_state.bend as TrendState
import ./src/core/squeeze.bend as Squeeze
import ./src/core/volume_filter.bend as VolumeFilter
import ./src/core/hilbert.bend as Hilbert

law bar_hl_fields:
  for high: F32
  for low: F32
  {TA.Bar.hl(high, low) == Bars.HL{high, low} : TA.Bar.HL()}

law bar_hlc_fields:
  for high: F32
  for low: F32
  for close: F32
  {TA.Bar.hlc(high, low, close) == Bars.HLC{high, low, close} : TA.Bar.HLC()}

law bar_hlv_fields:
  for high: F32
  for low: F32
  for volume: F32
  {TA.Bar.hlv(high, low, volume) == Bars.HLV{high, low, volume} : TA.Bar.HLV()}

law bar_cv_fields:
  for close: F32
  for volume: F32
  {TA.Bar.cv(close, volume) == Bars.CV{close, volume} : TA.Bar.CV()}

law bar_hlcv_fields:
  for high: F32
  for low: F32
  for close: F32
  for volume: F32
  {TA.Bar.hlcv(high, low, close, volume) == Bars.HLCV{high, low, close, volume} : TA.Bar.HLCV()}

law bar_ohlc_fields:
  for open: F32
  for high: F32
  for low: F32
  for close: F32
  {TA.Bar.ohlc(open, high, low, close) == Bars.OHLC{open, high, low, close} : TA.Bar.OHLC()}

law pair_fields:
  for x: F32
  for y: F32
  {TA.pair(x, y) == StatWindow.PairValue{x, y} : TA.PairValue()}

law mavp_sample_fields:
  for price: F32
  for period: F32
  {TA.MAVP.sample(price, period) == Variable.Sample{price, period} : TA.MAVP.Sample()}

law transform_operands_fields:
  for left: F32
  for right: F32
  {TA.Transform.operands(left, right) == Transform.Operands{left, right} : TA.Transform.Operands()}

law candle_setting_fields:
  for kind: TA.Candle.RangeKind()
  for period: U32
  for factor: F32
  {TA.Candle.setting(kind, period, factor) == Candle.Setting{kind, period, factor} : TA.Candle.Setting()}

law ma_selector_codes:
  {[TA.MA.Kind.SMA(), TA.MA.Kind.EMA(), TA.MA.Kind.WMA(), TA.MA.Kind.DEMA(), TA.MA.Kind.TEMA(),
    TA.MA.Kind.TRIMA(), TA.MA.Kind.KAMA(), TA.MA.Kind.MAMA(), TA.MA.Kind.T3(), TA.MA.Kind.HMA(),
    TA.MA.Kind.Identity(), TA.MA.Kind.ZLEMA(), TA.MA.Kind.RMA(), TA.MA.Kind.VIDYA(), TA.MA.Kind.ALMA()]
   == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15] : List<&2, U32>}

law macd_line:
  for line: F32
  for signal: F32
  for histogram: F32
  {TA.MACD.line(Momentum.MACDValue{line, signal, histogram}) == line : F32}

law macd_signal:
  for line: F32
  for signal: F32
  for histogram: F32
  {TA.MACD.signal(Momentum.MACDValue{line, signal, histogram}) == signal : F32}

law macd_histogram:
  for line: F32
  for signal: F32
  for histogram: F32
  {TA.MACD.histogram(Momentum.MACDValue{line, signal, histogram}) == histogram : F32}

law bbands_upper:
  for upper: F32
  for middle: F32
  for lower: F32
  {TA.BBANDS.upper(Overlap.Bands{upper, middle, lower}) == upper : F32}

law bbands_middle:
  for upper: F32
  for middle: F32
  for lower: F32
  {TA.BBANDS.middle(Overlap.Bands{upper, middle, lower}) == middle : F32}

law bbands_lower:
  for upper: F32
  for middle: F32
  for lower: F32
  {TA.BBANDS.lower(Overlap.Bands{upper, middle, lower}) == lower : F32}

law bbands_validation_rejects:
  for period: U32
  for up: F32
  for down: F32
  for kind: U32
  for rejected: {Result.is_done(&2, &2, String, Unit, TA.BBANDS.validate(period, up, down, kind)) == False{} : Bool}
  {(TA.BBANDS.init(period, up, down, kind), TA.BBANDS.lookback(period, up, down, kind)) ==
    (Fail{Parameters.InvalidParameter{}}, Fail{Parameters.InvalidParameter{}}) :
      Result<&2, &1, TA.Parameter.Error(), TA.BBANDS.State()> & TA.Lookback.Result()}

law extrema_fields:
  for low: F32
  for high: F32
  {(TA.Extrema.low(Ext.Range{low, high}),
    TA.Extrema.high(Ext.Range{low, high}))
    == (low, high) : F32 & F32}

law moments_fields:
  for mean: F32
  for variance: F32
  {(TA.Moments.mean(Stats.Moments{mean, variance}),
    TA.Moments.variance(Stats.Moments{mean, variance}))
    == (mean, variance) : F32 & F32}

law bar_fields:
  for open: F32
  for high: F32
  for low: F32
  for close: F32
  {(TA.Bar.open(Bars.OHLC{open, high, low, close}),
    (TA.Bar.high(Bars.OHLC{open, high, low, close}), (TA.Bar.low(Bars.OHLC{open, high, low, close}),
     TA.Bar.close(Bars.OHLC{open, high, low, close}))))
    == (open, (high, (low, close))) : F32 & (F32 & (F32 & F32))}

law pattern_fields:
  for negative: Bool
  for strength: U32
  {(TA.Pattern.negative(Patterns.Signal{negative, strength}),
    TA.Pattern.strength(Patterns.Signal{negative, strength}))
    == (negative, strength) : Bool & U32}

law mama_fields:
  for mama: F32
  for fama: F32
  {(TA.MAMA.mama(Mama.Value{mama, fama}),
    TA.MAMA.fama(Mama.Value{mama, fama}))
    == (mama, fama) : F32 & F32}

law minmax_fields:
  for min: F32
  for max: F32
  {(TA.MINMAX.min(Statistics.MinMax{min, max}),
    TA.MINMAX.max(Statistics.MinMax{min, max}))
    == (min, max) : F32 & F32}

law minmaxindex_fields:
  for min_index: U32
  for max_index: U32
  {(TA.MINMAXINDEX.min_index(Statistics.MinMaxIndex{min_index, max_index}),
    TA.MINMAXINDEX.max_index(Statistics.MinMaxIndex{min_index, max_index}))
    == (min_index, max_index) : U32 & U32}

law cksp_fields:
  for high_stop: F32
  for low_stop: F32
  {(TA.CKSP.high_stop(Overlap.Stops{high_stop, low_stop}),
    TA.CKSP.low_stop(Overlap.Stops{high_stop, low_stop}))
    == (high_stop, low_stop) : F32 & F32}

law aroon_fields:
  for down: F32
  for up: F32
  {(TA.AROON.down(MomentumWindow.Aroon{down, up}),
    TA.AROON.up(MomentumWindow.Aroon{down, up}))
    == (down, up) : F32 & F32}

law stoch_fields:
  for k: F32
  for d: F32
  for j: F32
  {(TA.STOCH.k(Momentum.StochValue{k, d, j}),
    (TA.STOCH.d(Momentum.StochValue{k, d, j}),
     TA.STOCH.j(Momentum.StochValue{k, d, j})))
    == (k, (d, j)) : F32 & (F32 & F32)}

law lines_fields:
  for first: F32
  for second: F32
  {(TA.Lines.first(Momentum.Lines{first, second}),
    TA.Lines.second(Momentum.Lines{first, second}))
    == (first, second) : F32 & F32}

law vortex_fields:
  for plus: F32
  for minus: F32
  {(TA.VORTEX.plus(MomentumMarket.Vortex{plus, minus}),
    TA.VORTEX.minus(MomentumMarket.Vortex{plus, minus}))
    == (plus, minus) : F32 & F32}

law displayshift_fields:
  for backward: Bool
  for bars: U32
  {(TA.DisplayShift.backward(WindowSignals.DisplayShift{backward, bars}),
    TA.DisplayShift.bars(WindowSignals.DisplayShift{backward, bars}))
    == (backward, bars) : Bool & U32}

law ichimoku_fields:
  for tenkan: F32
  for kijun: F32
  for span_a: F32
  for span_b: F32
  {(TA.ICHIMOKU.tenkan(WindowSignals.CloudValue{tenkan, kijun, span_a, span_b}),
    (TA.ICHIMOKU.kijun(WindowSignals.CloudValue{tenkan, kijun, span_a, span_b}), (TA.ICHIMOKU.span_a(WindowSignals.CloudValue{tenkan, kijun, span_a, span_b}),
     TA.ICHIMOKU.span_b(WindowSignals.CloudValue{tenkan, kijun, span_a, span_b}))))
    == (tenkan, (kijun, (span_a, span_b))) : F32 & (F32 & (F32 & F32))}

law fractal_fields:
  for high: U32
  for low: U32
  for index: U32
  {(TA.FRACTAL.high(WindowSignals.PivotFlags{high, low, index}),
    (TA.FRACTAL.low(WindowSignals.PivotFlags{high, low, index}),
     TA.FRACTAL.index(WindowSignals.PivotFlags{high, low, index})))
    == (high, (low, index)) : U32 & (U32 & U32)}

law zigzag_fields:
  for pivot: F32
  for up: Bool
  for index: U32
  {(TA.ZIGZAG.pivot(MarketState.ZigValue{pivot, Bool.pick(Bars.Direction, up, Bars.Up{}, Bars.Down{}), index}),
    (TA.ZIGZAG.is_up(MarketState.ZigValue{pivot, Bool.pick(Bars.Direction, up, Bars.Up{}, Bars.Down{}), index}),
     TA.ZIGZAG.index(MarketState.ZigValue{pivot, Bool.pick(Bars.Direction, up, Bars.Up{}, Bars.Down{}), index})))
    == (pivot, (up, index)) : F32 & (Bool & U32)}

law supertrend_fields:
  for line: F32
  for up: Bool
  {(TA.SUPERTREND.line(TrendState.TrendValue{line, Bool.pick(Bars.Direction, up, Bars.Up{}, Bars.Down{})}),
    TA.SUPERTREND.is_up(TrendState.TrendValue{line, Bool.pick(Bars.Direction, up, Bars.Up{}, Bars.Down{})}))
    == (line, up) : F32 & Bool}

law sqzmom_fields:
  for momentum: F32
  for negative: Bool
  for strength: U32
  {(TA.SQZMOM.momentum(Squeeze.SqueezeValue{momentum, negative, strength}),
    (TA.SQZMOM.negative(Squeeze.SqueezeValue{momentum, negative, strength}),
     TA.SQZMOM.strength(Squeeze.SqueezeValue{momentum, negative, strength})))
    == (momentum, (negative, strength)) : F32 & (Bool & U32)}

law kvo_fields:
  for kvo: F32
  for signal: F32
  {(TA.KVO.kvo(VolumeFilter.Lines{kvo, signal}),
    TA.KVO.signal(VolumeFilter.Lines{kvo, signal}))
    == (kvo, signal) : F32 & F32}

law ht_phasor_fields:
  for in_phase: F32
  for quadrature: F32
  {(TA.HT_PHASOR.in_phase(Hilbert.Phasor{in_phase, quadrature}),
    TA.HT_PHASOR.quadrature(Hilbert.Phasor{in_phase, quadrature}))
    == (in_phase, quadrature) : F32 & F32}

law ht_sine_fields:
  for sine: F32
  for lead_sine: F32
  {(TA.HT_SINE.sine(Hilbert.Sine{sine, lead_sine}),
    TA.HT_SINE.lead_sine(Hilbert.Sine{sine, lead_sine}))
    == (sine, lead_sine) : F32 & F32}

law window_clone:
  for ~A: Data
  for state: Window.State<A>
  {(state, state) == Clone.window(~A, state) : Window.State<A> & Window.State<A>}

law sma_clone:
  for state: TA.SMA.State()
  {(state, state) == TA.SMA.clone(state) : TA.SMA.State() & TA.SMA.State()}

law ema_clone:
  for state: TA.EMA.State()
  {(state, state) == TA.EMA.clone(state) : TA.EMA.State() & TA.EMA.State()}

law sma_preview:
  for state: TA.SMA.State()
  for price: F32
  for next: TA.SMA.State()
  for output: Maybe<&2, F32>
  for transition: {(next, output) == TA.SMA.next(state, price) : TA.SMA.State() & Maybe<&2, F32>}
  {TA.SMA.preview(state, price) == (state, output) : TA.SMA.State() & Maybe<&2, F32>}

law ema_preview:
  for state: TA.EMA.State()
  for price: F32
  for next: TA.EMA.State()
  for output: Maybe<&2, F32>
  for transition: {(next, output) == TA.EMA.next(state, price) : TA.EMA.State() & Maybe<&2, F32>}
  {TA.EMA.preview(state, price) == (state, output) : TA.EMA.State() & Maybe<&2, F32>}

law var_clone:
  for state: TA.VAR.State()
  {(state, state) == TA.VAR.clone(state) : TA.VAR.State() & TA.VAR.State()}

law var_preview:
  for state: TA.VAR.State()
  for value: F32
  for next: TA.VAR.State()
  for output: Maybe<&2, F32>
  for transition: {(next, output) == TA.VAR.next(state, value) : TA.VAR.State() & Maybe<&2, F32>}
  {TA.VAR.preview(state, value) == (state, output) : TA.VAR.State() & Maybe<&2, F32>}

law correl_clone:
  for state: TA.CORREL.State()
  {(state, state) == TA.CORREL.clone(state) : TA.CORREL.State() & TA.CORREL.State()}

law correl_preview:
  for state: TA.CORREL.State()
  for value: TA.PairValue()
  for next: TA.CORREL.State()
  for output: Maybe<&2, F32>
  for transition: {(next, output) == TA.CORREL.next(state, value) : TA.CORREL.State() & Maybe<&2, F32>}
  {TA.CORREL.preview(state, value) == (state, output) : TA.CORREL.State() & Maybe<&2, F32>}

law beta_clone:
  for state: TA.BETA.State()
  {(state, state) == TA.BETA.clone(state) : TA.BETA.State() & TA.BETA.State()}

law beta_preview:
  for state: TA.BETA.State()
  for value: TA.PairValue()
  for next: TA.BETA.State()
  for output: Maybe<&2, F32>
  for transition: {(next, output) == TA.BETA.next(state, value) : TA.BETA.State() & Maybe<&2, F32>}
  {TA.BETA.preview(state, value) == (state, output) : TA.BETA.State() & Maybe<&2, F32>}

law pattern_history_round_trip:
  for ~N: Data
  for frames: PatternState.Frames<N>
  {PatternState.history.frames(~N, PatternState.history.pack(~N, frames)) == frames : PatternState.Frames<N>}

law map_length:
  for ~I: Data
  for ~O: Data
  for ~f: I -> O
  for +xs: List<&2, I>
  {List.length(&2, O, Series.map(~I, ~O, ~f, xs)) == List.length(&2, I, xs) : Nat}

law map_ordered:
  for ~I: Data
  for ~O: Data
  for ~f: I -> O
  for xs: List<&2, I>
  {Series.map(~I, ~O, ~f, xs) == SeriesProof.map_spec(~I, ~O, ~f, xs) : List<&2, O>}

law scan_length:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for +xs: List<&2, I>
  for state: S
  {SeriesProof.result_length(~O, ~S, Series.scan(~I, ~O, ~S, ~step, xs, state)) == List.length(&2, I, xs) : Nat}

law scan_ordered:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for state: S
  {Series.scan(~I, ~O, ~S, ~step, xs, state) == SeriesProof.scan_spec(~I, ~O, ~S, ~step, xs, state) : S & List<&2, Maybe<&2, O>>}

law stream_scan_ordered:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for state: S
  {TA.Stream.scan(~I, ~O, ~S, ~step, xs, state) == SeriesProof.scan_spec(~I, ~O, ~S, ~step, xs, state) : S & List<&2, Maybe<&2, O>>}

law batch_ordered:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for state: S
  {Series.batch(~I, ~O, ~S, ~step, xs, state) == SeriesProof.spec_values(O, S, SeriesProof.scan_spec(~I, ~O, ~S, ~step, xs, state)) : List<&2, Maybe<&2, O>>}

law scan_chunks:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for +ys: List<&2, I>
  for state: S
  {Series.scan(~I, ~O, ~S, ~step, List.append(&2, I, xs, ys), state) == SeriesProof.continue_scan(~I, ~O, ~S, ~step, ys, Series.scan(~I, ~O, ~S, ~step, xs, state)) : S & List<&2, Maybe<&2, O>>}

law ema_batch:
  for xs: List<&2, F32>
  for period: U32
  for state: TA.EMA.State()
  for initialized: {Done{state} == TA.EMA.init(period) : Result<&2, &2, TA.Error(), TA.EMA.State()>}
  for final: TA.EMA.State()
  for values: List<&2, Maybe<&2, F32>>
  for reference: {(final, values) == SeriesProof.scan_spec(~F32, ~F32, ~TA.EMA.State(), ~TA.EMA.next, xs, state) : TA.EMA.State() & List<&2, Maybe<&2, F32>>}
  {TA.EMA.batch(xs, period) == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}

law sma_batch:
  for xs: List<&2, F32>
  for period: U32
  for state: TA.SMA.State()
  for initialized: {Done{state} == TA.SMA.init(period) : Result<&2, &1, TA.Error(), TA.SMA.State()>}
  for final: TA.SMA.State()
  for values: List<&2, Maybe<&2, F32>>
  for reference: {(final, values) == SeriesProof.scan_spec(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, xs, state) : TA.SMA.State() & List<&2, Maybe<&2, F32>>}
  {TA.SMA.batch(xs, period) == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}

law configuration:
  for period: U32
  {Config.make(period) == Bool.pick(Result<&2, &2, Config.Error, Config.Config>, Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)), Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}}) : Result<&2, &2, Config.Error, Config.Config>}

law ema_configuration:
  for period: U32
  {TA.EMA.init(period) == Bool.pick(Result<&2, &2, TA.Error(), TA.EMA.State()>, Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)), Done{Ema.init(~F32, ~U32.to_f32, ~F32.div, period)}, Fail{Config.InvalidPeriod{}}) : Result<&2, &2, TA.Error(), TA.EMA.State()>}

law ema_lookback:
  for period: U32
  {TA.EMA.lookback(period) == Bool.pick(TA.Lookback.Result(), Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)), Done{U32.sub(period, 1)}, Fail{Parameters.InvalidParameter{}}) : TA.Lookback.Result()}

law ema_warmup:
  for ~D: Data
  for ~sample: D -> Nat -> F32
  for +period: U32
  for data: D
  for +valid: {Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)) == True{} : Bool}
  Contracts.ema_startup(F32, TA.EMA.next, U32.to_nat(U32.sub(period, 1)), at => sample(data, at), TA.EMA.init(period))

law sma_configuration:
  for period: U32
  {TA.SMA.init(period) == Bool.pick(Result<&2, &1, TA.Error(), TA.SMA.State()>, Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)), Done{Sma.init(~F32, ~U32.to_f32, period, Config.depth(period))}, Fail{Config.InvalidPeriod{}}) : Result<&2, &1, TA.Error(), TA.SMA.State()>}

law sma_lookback:
  for period: U32
  {TA.SMA.lookback(period) == Bool.pick(TA.Lookback.Result(), Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)), Done{U32.sub(period, 1)}, Fail{Parameters.InvalidParameter{}}) : TA.Lookback.Result()}

law sma_warmup:
  for ~D: Data
  for ~sample: D -> Nat -> F32
  for +period: U32
  for data: D
  for +valid: {Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824)) == True{} : Bool}
  Contracts.sma_startup(F32, TA.SMA.next, U32.to_nat(U32.sub(period, 1)), at => sample(data, at), TA.SMA.init(period))

law ema_first_one:
  for price: F32
  {TA.EMA.next(Ema.init(~F32, ~U32.to_f32, ~F32.div, 1), price) == (Ema.Live{1, F32.div(U32.to_f32(2), U32.to_f32(2)), price}, Some{price}) : TA.EMA.State() & Maybe<&2, F32>}

law ema_live_one:
  for alpha: F32
  for previous: F32
  for price: F32
  {TA.EMA.next(Ema.Live{1, alpha, previous}, price) == (Ema.Live{1, alpha, price}, Some{price}) : TA.EMA.State() & Maybe<&2, F32>}

law window_lag_history:
  for ~A: Data
  for +period: U32
  for +depth: Nat
  for +fill: A
  for +history: List<&2, A>
  for +age: U32
  for config: History.Configuration<period, depth>
  {Window.lag(~A, History.replay(~A, period, depth, fill, history), age) == (History.replay(~A, period, depth, fill, history), History.visible(~A, period, history, age)) : Window.State<A> & Maybe<&2, A>}

law window_push_history:
  for ~A: Data
  for +period: U32
  for +depth: Nat
  for +fill: A
  for +history: List<&2, A>
  for +value: A
  for config: History.Configuration<period, depth>
  {Window.push(~A, History.replay(~A, period, depth, fill, history), value) == (History.replay(~A, period, depth, fill, value <> history), History.expelled(~A, period, history)) : Window.State<A> & Maybe<&2, A>}
