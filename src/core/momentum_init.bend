import Base
import ./config.bend as Config
import ./parameters.bend as Parameters
import ./window.bend as Window
import ./ema.bend as Ema
import ./ma.bend as Ma
import ./momentum.bend as Mom
import ./directional.bend as Directional
import ./momentum_window.bend as Box
import ./momentum_market.bend as Market
import ./momentum_smooth.bend as Smooth
import ./momentum_composite.bend as Composite

def depth(+period: U32) -> Nat:
  Config.depth.go(30n, period, 1, 0n, U32.is_le(period, 1))

def adxr(~N: Data, ~from: U32 -> N, +period: U32) -> Directional.ADXR<N>:
  Directional.ADXR{Directional.adx.init(~N, ~from, period), Window.init(~N, U32.sub(period, 1), depth(U32.sub(period, 1)), from(0))}

def aroon(~N: Data, ~from: U32 -> N, +period: U32) -> Box.Box<N>:
  Box.box.init(~N, ~from, U32.add(period, 1), depth(U32.add(period, 1)))

def changed(~N: Data, ~from: U32 -> N, +period: U32) -> Box.Prices<N>:
  Box.prices.init(~N, ~from, U32.add(period, 1), depth(U32.add(period, 1)))

def forecast(~N: Data, ~from: U32 -> N, +period: U32) -> Composite.Forecast<N>:
  Composite.Forecast{Window.init(~N, period, depth(period), from(0)), None{}, None{}}

def flow(~N: Data, ~from: U32 -> N, +period: U32) -> Mom.Flow<N>:
  Mom.flow.init(~N, ~from, period, depth(period))

def cci(~N: Data, ~from: U32 -> N, +period: U32) -> Market.CCI<N>:
  Market.cci.init(~N, ~from, period, depth(period))

def box(~N: Data, ~from: U32 -> N, +period: U32) -> Box.Box<N>:
  Box.box.init(~N, ~from, period, depth(period))

def market(~N: Data, ~from: U32 -> N, +period: U32) -> Market.Market<N>:
  Market.init(~N, ~from, period, depth(period))

def ultimate(~N: Data, ~from: U32 -> N, +first: U32, +second: U32, +third: U32) -> Composite.Ultimate<N>:
  +small = U32.min(first, U32.min(second, third))
  +middle = U32.max(U32.min(first, second), U32.min(U32.max(first, second), third))
  +large = U32.max(first, U32.max(second, third))
  Composite.Ultimate{market(~N, ~from, small), market(~N, ~from, middle), market(~N, ~from, large)}

def dual(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, fast: U32, slow: U32, +kind: U32, delay: U32) -> Result<&2, &1, Parameters.Error, Smooth.Dual<N>>:
  Smooth.dual.init(~N, delay, Bool.pick(Maybe<&2, N>, U32.is_eq(kind, 7), Some{from(0)}, None{}), make(fast, kind), make(slow, kind))

def apo(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, +fast: U32, +slow: U32, kind: U32) -> Result<&2, &1, Parameters.Error, Smooth.Dual<N>>:
  dual(~N, ~from, ~make, U32.min(fast, slow), U32.max(fast, slow), kind, 0)

def ao(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, fast: U32, slow: U32) -> Result<&2, &1, Parameters.Error, Smooth.Dual<N>>:
  dual(~N, ~from, ~make, fast, slow, 0, 0)

def ac(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, fast: U32, slow: U32, signal: U32) -> Result<&2, &1, Parameters.Error, Smooth.MACD<N>>:
  Smooth.macd.init(~N, ao(~N, ~from, ~make, fast, slow), make(signal, 0))

def macd(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, +fast: U32, +slow: U32, signal: U32) -> Result<&2, &1, Parameters.Error, Smooth.MACD<N>>:
  +short = U32.min(fast, slow)
  +long = U32.max(fast, slow)
  Smooth.macd.init(~N, dual(~N, ~from, ~make, short, long, 1, U32.sub(long, short)), make(signal, 1))

def macdfix(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, signal: U32) -> Result<&2, &1, Parameters.Error, Smooth.MACD<N>>:
  Smooth.macd.init(~N, Smooth.dual.init(~N, 14, None{}, Done{Ma.Exponential{Ema.init.alpha(~N, ~from, 12, div(from(3), from(20)))}}, Done{Ma.Exponential{Ema.init.alpha(~N, ~from, 26, div(from(3), from(40)))}}), make(signal, 1))

def pipeline2(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, first: U32, second: U32) -> Result<&2, &1, Parameters.Error, Smooth.Pipeline<N>>:
  Smooth.pipeline.init(~N, make(first, 1), Smooth.pipeline.init(~N, make(second, 1), Done{Smooth.Pipeline{0n, Nil{}}}))

def trix(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, +period: U32) -> Result<&2, &1, Parameters.Error, Smooth.Trix<N>>:
  Smooth.trix.init(~N, Smooth.pipeline.init(~N, make(period, 1), pipeline2(~N, ~make, period, period)))

def stoch(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, kperiod: U32, slowk: U32, ktype: U32, dperiod: U32, dtype: U32) -> Result<&2, &1, Parameters.Error, Smooth.Stoch<N>>:
  Smooth.stoch.init(~N, box(~N, ~from, kperiod), make(slowk, ktype), make(dperiod, dtype))

def stochf(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, kperiod: U32, dperiod: U32, dtype: U32) -> Result<&2, &1, Parameters.Error, Smooth.Stoch<N>>:
  stoch(~N, ~from, ~make, kperiod, 1, 0, dperiod, dtype)

def stochrsi(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, period: U32, kperiod: U32, dperiod: U32, dtype: U32) -> Result<&2, &1, Parameters.Error, Composite.StochRSI<N>>:
  Composite.stochrsi.init(~N, Mom.rsi.init(~N, ~from, period), stochf(~N, ~from, ~make, kperiod, dperiod, dtype))

def dosc(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, period: U32, first: U32, second: U32, signal: U32) -> Result<&2, &1, Parameters.Error, Smooth.Dosc<N>>:
  Smooth.dosc.init(~N, Mom.rsi.init(~N, ~from, period), pipeline2(~N, ~make, first, second), make(signal, 0))

def pso(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, kperiod: U32, +period: U32) -> Result<&2, &1, Parameters.Error, Smooth.Pso<N>>:
  Smooth.pso.init(~N, box(~N, ~from, kperiod), pipeline2(~N, ~make, period, period))

def tsi(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, +first: U32, +second: U32) -> Result<&2, &1, Parameters.Error, Composite.TSI<N>>:
  Composite.tsi.init(~N, pipeline2(~N, ~make, first, second), pipeline2(~N, ~make, first, second))

def qstick(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, period: U32) -> Result<&2, &1, Parameters.Error, Ma.State<N>>:
  make(period, 0)

def eri(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, period: U32) -> Result<&2, &1, Parameters.Error, Smooth.Eri<N>>:
  Smooth.eri.init(~N, make(period, 1))

def leg(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, +roc: U32, average: U32, weight: U32, rest: Result<&2, &1, Parameters.Error, Composite.Roc<N>>) -> Result<&2, &1, Parameters.Error, Composite.Roc<N>>:
  Composite.roc.leg(~N, ~from, roc, depth(roc), from(weight), make(average, 0), rest)

def coppock(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, wma: U32, first: U32, second: U32) -> Result<&2, &1, Parameters.Error, Composite.Roc<N>>:
  leg(~N, ~from, ~make, second, 1, 1, leg(~N, ~from, ~make, first, 1, 1, Composite.roc.init(~N, make(wma, 2))))

def kst(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Parameters.Error, Ma.State<N>>, roc1: U32, roc2: U32, roc3: U32, roc4: U32, sma1: U32, sma2: U32, sma3: U32, sma4: U32, signal: U32) -> Result<&2, &1, Parameters.Error, Composite.Roc<N>>:
  leg(~N, ~from, ~make, roc1, sma1, 1, leg(~N, ~from, ~make, roc2, sma2, 2, leg(~N, ~from, ~make, roc3, sma3, 3, leg(~N, ~from, ~make, roc4, sma4, 4, Composite.roc.init(~N, make(signal, 0))))))
