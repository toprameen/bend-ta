import Base
import ./src/f32.bend as TA
import ./src/core/bar.bend as Bars
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
import ./proofs/contracts.bend as Contracts
import ./proofs/window_history.bend as History

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
