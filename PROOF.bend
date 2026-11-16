import Base
import ./LAWS.bend as Laws
import ./src/f32.bend as TA
import ./src/core/series.bend as Series
import ./proofs/ownership.bend as Ownership
import ./proofs/series.bend as SeriesProof
import ./proofs/configuration.bend as Configuration
import ./proofs/warmup.bend as Warmup
import ./proofs/contracts.bend as Contracts
import ./src/core/config.bend as Config
import ./src/core/ema.bend as Ema
import ./src/core/sma.bend as Sma
import ./src/core/parameters.bend as Parameters
import ./proofs/window_history.bend as History

def ema_configuration_if(period: U32, valid: Bool) -> {TA.EMA.init.result(Bool.pick(Result<&2, &2, Config.Error, Config.Config>, valid, Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}})) == Bool.pick(Result<&2, &2, TA.Error(), TA.EMA.State()>, valid, Done{Ema.init(~F32, ~U32.to_f32, ~F32.div, period)}, Fail{Config.InvalidPeriod{}}) : Result<&2, &2, TA.Error(), TA.EMA.State()>}:
  match valid:
    case False{}: {==}
    case True{}: {==}

def sma_configuration_if(period: U32, valid: Bool) -> {TA.SMA.init.result(Bool.pick(Result<&2, &2, Config.Error, Config.Config>, valid, Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}})) == Bool.pick(Result<&2, &1, TA.Error(), TA.SMA.State()>, valid, Done{Sma.init(~F32, ~U32.to_f32, period, Config.depth(period))}, Fail{Config.InvalidPeriod{}}) : Result<&2, &1, TA.Error(), TA.SMA.State()>}:
  match valid:
    case False{}: {==}
    case True{}: {==}

def Laws.bar_hl_fields(high, low):
  {==}

def Laws.bar_hlc_fields(high, low, close):
  {==}

def Laws.bar_hlv_fields(high, low, volume):
  {==}

def Laws.bar_cv_fields(close, volume):
  {==}

def Laws.bar_hlcv_fields(high, low, close, volume):
  {==}

def Laws.bar_ohlc_fields(open, high, low, close):
  {==}

def Laws.macd_line(line, signal, histogram):
  {==}

def Laws.macd_signal(line, signal, histogram):
  {==}

def Laws.macd_histogram(line, signal, histogram):
  {==}

def Laws.bbands_upper(upper, middle, lower):
  {==}

def Laws.bbands_middle(upper, middle, lower):
  {==}

def Laws.bbands_lower(upper, middle, lower):
  {==}

def Laws.window_clone(A, state):
  Ownership.window_clone(~A, state)

def Laws.sma_clone(state):
  Ownership.sma_clone(~F32, state)

def Laws.ema_clone(state):
  Ownership.data_clone(~TA.EMA.State(), state)

def Laws.sma_preview(state, price, next, output, transition):
  Ownership.preview_copy(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.clone, ~TA.SMA.next, ~(Ownership.sma_clone(~F32)), state, price, next, output, transition)

def Laws.ema_preview(state, price, next, output, transition):
  Ownership.preview_copy(~F32, ~F32, ~TA.EMA.State(), ~TA.EMA.clone, ~TA.EMA.next, ~(Ownership.data_clone(~TA.EMA.State())), state, price, next, output, transition)

def Laws.var_clone(state):
  Ownership.moments_clone(~F32, state)

def Laws.var_preview(state, value, next, output, transition):
  Ownership.preview_copy(~F32, ~F32, ~TA.VAR.State(), ~TA.VAR.clone, ~TA.VAR.next, ~(Ownership.moments_clone(~F32)), state, value, next, output, transition)

def Laws.correl_clone(state):
  Ownership.pair_clone(~F32, state)

def Laws.correl_preview(state, value, next, output, transition):
  Ownership.preview_copy(~TA.PairValue(), ~F32, ~TA.CORREL.State(), ~TA.CORREL.clone, ~TA.CORREL.next, ~(Ownership.pair_clone(~F32)), state, value, next, output, transition)

def Laws.beta_clone(state):
  Ownership.beta_clone(~F32, state)

def Laws.beta_preview(state, value, next, output, transition):
  Ownership.preview_copy(~TA.PairValue(), ~F32, ~TA.BETA.State(), ~TA.BETA.clone, ~TA.BETA.next, ~(Ownership.beta_clone(~F32)), state, value, next, output, transition)

def Laws.map_length(I, O, f, xs):
  SeriesProof.map_length(~I, ~O, ~f, xs)

def Laws.map_ordered(I, O, f, xs):
  SeriesProof.map_ordered(~I, ~O, ~f, xs)

def Laws.scan_length(I, O, S, step, xs, state):
  SeriesProof.scan_length(~I, ~O, ~S, ~step, xs, state)

def Laws.scan_ordered(I, O, S, step, xs, state):
  SeriesProof.scan_ordered(~I, ~O, ~S, ~step, xs, state)

def Laws.stream_scan_ordered(I, O, S, step, xs, state):
  SeriesProof.scan_ordered(~I, ~O, ~S, ~step, xs, state)

def Laws.batch_ordered(I, O, S, step, xs, state):
  SeriesProof.batch_ordered(~I, ~O, ~S, ~step, xs, state)

def Laws.scan_chunks(I, O, S, step, xs, ys, state):
  SeriesProof.scan_chunks(~I, ~O, ~S, ~step, xs, ys, state)

def Laws.ema_batch(xs, period, state, initialized, final, values, reference):
  %initialized : {TA.EMA.batch.result(xs, _) == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}
  %Equal.sym(List<&2, Maybe<&2, F32>>, Series.batch(~F32, ~F32, ~TA.EMA.State(), ~TA.EMA.next, xs, state), SeriesProof.spec_values(F32, TA.EMA.State(), SeriesProof.scan_spec(~F32, ~F32, ~TA.EMA.State(), ~TA.EMA.next, xs, state)), SeriesProof.batch_ordered(~F32, ~F32, ~TA.EMA.State(), ~TA.EMA.next, xs, state)) : {Done{_} == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}
  %reference : {Done{SeriesProof.spec_values(F32, TA.EMA.State(), _)} == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}
  {==}

def Laws.sma_batch(xs, period, state, initialized, final, values, reference):
  %initialized : {TA.SMA.batch.result(xs, _) == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}
  %Equal.sym(List<&2, Maybe<&2, F32>>, Series.batch(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, xs, state), SeriesProof.spec_values(F32, TA.SMA.State(), SeriesProof.scan_spec(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, xs, state)), SeriesProof.batch_ordered(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, xs, state)) : {Done{_} == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}
  %reference : {Done{SeriesProof.spec_values(F32, TA.SMA.State(), _)} == Done{values} : Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>}
  {==}

def Laws.configuration(period):
  Configuration.make_exact(period)

def Laws.ema_configuration(period):
  +period = period
  %Equal.sym(Result<&2, &2, Config.Error, Config.Config>, Config.make(period), Bool.pick(Result<&2, &2, Config.Error, Config.Config>, Configuration.domain(period), Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}}), Configuration.make_exact(period)) : {TA.EMA.init.result(_) == Bool.pick(Result<&2, &2, TA.Error(), TA.EMA.State()>, Configuration.domain(period), Done{Ema.init(~F32, ~U32.to_f32, ~F32.div, period)}, Fail{Config.InvalidPeriod{}}) : Result<&2, &2, TA.Error(), TA.EMA.State()>}
  ema_configuration_if(period, Configuration.domain(period))

def Laws.ema_lookback(period):
  Configuration.ema_lookback(period)

def Laws.ema_warmup(D, sample, period, data, valid):
  %Equal.sym(Result<&2, &2, TA.Error(), TA.EMA.State()>, TA.EMA.init(period), Done{Ema.init(~F32, ~U32.to_f32, ~F32.div, period)}, Configuration.ema_accepts(period, valid)) : Contracts.ema_startup(F32, TA.EMA.next, U32.to_nat(U32.sub(period, 1)), at => sample(data, at), _)
  Warmup.ema_initial_warmup_shape(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~D, ~sample, period, data, valid)

def Laws.sma_configuration(period):
  +period = period
  %Equal.sym(Result<&2, &2, Config.Error, Config.Config>, Config.make(period), Bool.pick(Result<&2, &2, Config.Error, Config.Config>, Configuration.domain(period), Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}}), Configuration.make_exact(period)) : {TA.SMA.init.result(_) == Bool.pick(Result<&2, &1, TA.Error(), TA.SMA.State()>, Configuration.domain(period), Done{Sma.init(~F32, ~U32.to_f32, period, Config.depth(period))}, Fail{Config.InvalidPeriod{}}) : Result<&2, &1, TA.Error(), TA.SMA.State()>}
  sma_configuration_if(period, Configuration.domain(period))

def Laws.sma_lookback(period):
  +period = period
  Equal.trans(TA.Lookback.Result(), TA.SMA.lookback(period), TA.EMA.lookback(period), Bool.pick(TA.Lookback.Result(), Configuration.domain(period), Done{U32.sub(period, 1)}, Fail{Parameters.InvalidParameter{}}), Configuration.sma_lookback(period), Configuration.ema_lookback(period))

def Laws.sma_warmup(D, sample, period, data, valid):
  %Equal.sym(Result<&2, &1, TA.Error(), TA.SMA.State()>, TA.SMA.init(period), Done{Sma.init(~F32, ~U32.to_f32, period, Config.depth(period))}, Configuration.sma_accepts(period, valid)) : Contracts.sma_startup(F32, TA.SMA.next, U32.to_nat(U32.sub(period, 1)), at => sample(data, at), _)
  Warmup.sma_initial_warmup(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.div, ~D, ~sample, period, data, Config.depth(period), valid)

def Laws.ema_first_one(price):
  Warmup.ema_first_one(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, price)

def Laws.ema_live_one(alpha, previous, price):
  Warmup.ema_live_one(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, alpha, previous, price)

def Laws.window_lag_history(A, period, depth, fill, history, age, config):
  History.lag_history(~A, period, depth, fill, history, age, config)

def Laws.window_push_history(A, period, depth, fill, history, value, config):
  History.push_history(~A, period, depth, fill, history, value, config)
