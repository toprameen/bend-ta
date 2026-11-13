import Base
import ../src/core/config.bend as Config
import ../src/core/ema.bend as Ema
import ../src/core/sma.bend as Sma
import ../src/core/parameters.bend as Parameters
import ../src/core/lookback.bend as Lookback
import ../src/f32.bend as TA

def domain(+period: U32) -> Bool:
  Bool.and(U32.is_gt(period, 0), U32.is_le(period, 1073741824))

def make_if_exact(period: U32, valid: Bool) -> {Config.make.if(period, valid) == Bool.pick(Result<&2, &2, Config.Error, Config.Config>, valid, Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}}) : Result<&2, &2, Config.Error, Config.Config>}:
  match valid:
    case False{}: {==}
    case True{}: {==}

law make_exact:
  for period: U32
  {Config.make(period) == Bool.pick(Result<&2, &2, Config.Error, Config.Config>, domain(period), Done{Config.Config{period, Config.depth(period)}}, Fail{Config.InvalidPeriod{}}) : Result<&2, &2, Config.Error, Config.Config>}

def make_exact(period):
  +period = period
  make_if_exact(period, domain(period))

law make_accepts:
  for period: U32
  for valid: {domain(period) == True{} : Bool}
  {Config.make(period) == Done{Config.Config{period, Config.depth(period)}} : Result<&2, &2, Config.Error, Config.Config>}

def make_accepts(period, valid):
  Equal.cong(Bool, Result<&2, &2, Config.Error, Config.Config>, flag => Config.make.if(period, flag), domain(period), True{}, valid)

law ema_accepts:
  for period: U32
  for valid: {domain(period) == True{} : Bool}
  {TA.EMA.init(period) == Done{Ema.init(~F32, ~U32.to_f32, ~F32.div, period)} : Result<&2, &2, TA.Error(), TA.EMA.State()>}

def ema_accepts(period, valid):
  Equal.cong(Result<&2, &2, Config.Error, Config.Config>, Result<&2, &2, TA.Error(), TA.EMA.State()>, TA.EMA.init.result, Config.make(period), Done{Config.Config{period, Config.depth(period)}}, make_accepts(period, valid))

law sma_accepts:
  for period: U32
  for valid: {domain(period) == True{} : Bool}
  {TA.SMA.init(period) == Done{Sma.init(~F32, ~U32.to_f32, period, Config.depth(period))} : Result<&2, &1, TA.Error(), TA.SMA.State()>}

def sma_accepts(period, valid):
  Equal.cong(Result<&2, &2, Config.Error, Config.Config>, Result<&2, &1, TA.Error(), TA.SMA.State()>, TA.SMA.init.result, Config.make(period), Done{Config.Config{period, Config.depth(period)}}, make_accepts(period, valid))

def lookback_if_exact(valid: Bool, count: U32) -> {Lookback.checked(valid, count) == Bool.pick(TA.Lookback.Result(), valid, Done{count}, Fail{Parameters.InvalidParameter{}}) : TA.Lookback.Result()}:
  match valid:
    case False{}: {==}
    case True{}: {==}

law ema_lookback:
  for period: U32
  {TA.EMA.lookback(period) == Bool.pick(TA.Lookback.Result(), domain(period), Done{U32.sub(period, 1)}, Fail{Parameters.InvalidParameter{}}) : TA.Lookback.Result()}

def ema_lookback(period):
  +period = period
  lookback_if_exact(domain(period), U32.sub(period, 1))

law sma_lookback:
  for period: U32
  {TA.SMA.lookback(period) == TA.EMA.lookback(period) : TA.Lookback.Result()}

def sma_lookback(period):
  {==}
