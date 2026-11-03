import Base
import ../src/core/ema.bend as Ema
import ../src/core/sma.bend as Sma
import ../src/core/config.bend as Config
import ./warmup.bend as Warmup

def ema_startup(
  -N: Data, -step: Ema.State<N> -> N -> Ema.State<N> & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, result: Result<&2, &2, Config.Error, Ema.State<N>>
) -> Type:
  match result:
    case Fail{error}: Empty
    case Done{state}: Warmup.warm_shape(N, Ema.State<N>, step, remaining, prices, 0n, state)

def sma_startup(
  -N: Data, -step: Sma.State<N> -> N -> Sma.State<N> & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, result: Result<&2, &1, Config.Error, Sma.State<N>>
) -> Type:
  match result:
    case Fail{error}: Empty
    case Done{state}: Warmup.warm_shape(N, Sma.State<N>, step, remaining, prices, 0n, state)
