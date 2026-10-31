import Base
import ./ma.bend as Ma
import ./parameters.bend as Parameters
import ./bar.bend as Bar
import ./momentum_window.bend as Box
import ./momentum.bend as Mom

type Lines<-N: Data> is Data:
  Lines{first: N, second: N}

type SpreadValue<-N: Data> is Data:
  SpreadValue{first: N, second: N, origin: N}

type Dual<-N: Data> is Type:
  Dual{first: Ma.State<N>, second: Ma.State<N>, delay: U32, origin: Maybe<&2, N>}

def dual.init(~N: Data, +delay: U32, origin: Maybe<&2, N>, first: Result<&2, &1, Parameters.Error, Ma.State<N>>, second: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, Dual<N>>:
  match first second:
    case Fail{error} _: Fail{error}
    case Done{first} Fail{error}: Fail{error}
    case Done{first} Done{second}: Done{Dual{first, second, delay, origin}}

def dual.finish(~N: Data, +origin: N, first: Ma.State<N>, +delay: U32, result: Ma.State<N> & Maybe<&2, N>, value: Maybe<&2, N>) -> Dual<N> & Maybe<&2, SpreadValue<N>>:
  match result value:
    case (second, Some{b}) Some{a}: (Dual{first, second, delay, Some{origin}}, Some{SpreadValue{a, b, origin}})
    case (second, _) _: (Dual{first, second, delay, Some{origin}}, None{})

def dual.first(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, second: Ma.State<N>, +origin: N, +delay: U32, +price: N, result: Ma.State<N> & Maybe<&2, N>) -> Dual<N> & Maybe<&2, SpreadValue<N>>:
  match result:
    case (first, value): dual.finish(~N, origin, first, delay, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, second, price), value)

def dual.wait(~N: Data, +origin: N, first: Ma.State<N>, +delay: U32, result: Ma.State<N> & Maybe<&2, N>) -> Dual<N> & Maybe<&2, SpreadValue<N>>:
  match result:
    case (second, value): (Dual{first, second, delay, Some{origin}}, None{})

def dual.advance(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, first: Ma.State<N>, second: Ma.State<N>, +origin: N, +delay: U32, +price: N, +waiting: Bool) -> Dual<N> & Maybe<&2, SpreadValue<N>>:
  match waiting:
    case True{}: dual.wait(~N, origin, first, U32.sub(delay, 1), Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, second, price))
    case False{}: dual.first(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, second, origin, 0, price, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, first, price))

def dual.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Dual<N>, +price: N) -> Dual<N> & Maybe<&2, SpreadValue<N>>:
  match state:
    case Dual{first, second, +delay, None{}}: dual.advance(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, first, second, price, delay, from(0), U32.is_gt(delay, 0))
    case Dual{first, second, +delay, Some{+origin}}: dual.advance(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, first, second, origin, delay, sub(price, origin), U32.is_gt(delay, 0))

def difference(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~near_zero: N -> Bool, value: SpreadValue<N>, +percentage: Bool) -> N:
  match value:
    case SpreadValue{first, +second, origin}:
      +diff = sub(first, second)
      +den = add(origin, second)
      Bool.pick(N, percentage, Bool.pick(N, near_zero(den), from(0), mul(div(diff, den), from(100))), diff)

def dual.difference(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~near_zero: N -> Bool, result: Dual<N> & Maybe<&2, SpreadValue<N>>, +percentage: Bool) -> Dual<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{difference(~N, ~from, ~add, ~sub, ~mul, ~div, ~near_zero, value, percentage)})

type MACD<-N: Data> is Type:
  MACD{oscillator: Dual<N>, signal: Ma.State<N>}

type MACDValue<-N: Data> is Data:
  MACDValue{line: N, signal: N, histogram: N}

def macd.init(~N: Data, dual: Result<&2, &1, Parameters.Error, Dual<N>>, signal: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, MACD<N>>:
  match dual signal:
    case Fail{error} _: Fail{error}
    case Done{dual} Fail{error}: Fail{error}
    case Done{dual} Done{signal}: Done{MACD{dual, signal}}

def macd.finish(~N: Data, ~sub: N -> N -> N, oscillator: Dual<N>, +line: N, result: Ma.State<N> & Maybe<&2, N>) -> MACD<N> & Maybe<&2, MACDValue<N>>:
  match result:
    case (signal, None{}): (MACD{oscillator, signal}, None{})
    case (signal, Some{+value}): (MACD{oscillator, signal}, Some{MACDValue{line, value, sub(line, value)}})

def macd.signal(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, signal: Ma.State<N>, result: Dual<N> & Maybe<&2, SpreadValue<N>>) -> MACD<N> & Maybe<&2, MACDValue<N>>:
  match result:
    case (oscillator, None{}): (MACD{oscillator, signal}, None{})
    case (oscillator, Some{SpreadValue{first, second, origin}}):
      +line = sub(first, second)
      macd.finish(~N, ~sub, oscillator, line, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, line))

def macd.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: MACD<N>, +price: N) -> MACD<N> & Maybe<&2, MACDValue<N>>:
  match state:
    case MACD{oscillator, signal}: macd.signal(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, dual.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, oscillator, price))

type Stoch<-N: Data> is Type:
  Stoch{box: Box.Box<N>, k: Ma.State<N>, d: Ma.State<N>}

type StochValue<-N: Data> is Data:
  StochValue{k: N, d: N, j: N}

def stoch.init(~N: Data, box: Box.Box<N>, k: Result<&2, &1, Parameters.Error, Ma.State<N>>, d: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, Stoch<N>>:
  match k d:
    case Fail{error} _: Fail{error}
    case Done{k} Fail{error}: Fail{error}
    case Done{k} Done{d}: Done{Stoch{box, k, d}}

def stoch.finish(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, box: Box.Box<N>, k: Ma.State<N>, +value: N, result: Ma.State<N> & Maybe<&2, N>) -> Stoch<N> & Maybe<&2, StochValue<N>>:
  match result:
    case (d, None{}): (Stoch{box, k, d}, None{})
    case (d, Some{+signal}): (Stoch{box, k, d}, Some{StochValue{value, signal, sub(mul(from(3), value), mul(from(2), signal))}})

def stoch.d(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, box: Box.Box<N>, d: Ma.State<N>, result: Ma.State<N> & Maybe<&2, N>) -> Stoch<N> & Maybe<&2, StochValue<N>>:
  match result:
    case (k, None{}): (Stoch{box, k, d}, None{})
    case (k, Some{+value}): stoch.finish(~N, ~from, ~sub, ~mul, box, k, value, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, d, value))

def stoch.k(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, k: Ma.State<N>, d: Ma.State<N>, result: Box.Box<N> & Maybe<&2, Box.Bounds<N>>) -> Stoch<N> & Maybe<&2, StochValue<N>>:
  match result:
    case (box, None{}): (Stoch{box, k, d}, None{})
    case (box, Some{value}): stoch.d(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, box, d, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, k, Box.stochastic(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, value, from(0))))

def stoch.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~ge: N -> N -> Bool, ~atan: N -> N, state: Stoch<N>, bar: Bar.HLC<N>) -> Stoch<N> & Maybe<&2, StochValue<N>>:
  match state:
    case Stoch{box, k, d}: stoch.k(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, k, d, Box.box.next(~N, ~ge, ~le, box, bar))

type Pipeline<-N: Data> is Type:
  Pipeline{count: Nat, stages: List<&1, Ma.State<N>>}

def pipeline.finish(~N: Data, state: Ma.State<N>, result: List<&1, Ma.State<N>> & Maybe<&2, N>) -> List<&1, Ma.State<N>> & Maybe<&2, N>:
  match result:
    case (rest, value): (state <> rest, value)

def pipeline.read(~N: Data, stages: List<&1, Ma.State<N>>, result: Ma.State<N> & Maybe<&2, N>, rest: List<&1, Ma.State<N>> -> N -> List<&1, Ma.State<N>> & Maybe<&2, N>) -> List<&1, Ma.State<N>> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state <> stages, None{})
    case (state, Some{price}): pipeline.finish(~N, state, rest(stages, price))

def pipeline.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, fuel: Nat, stages: List<&1, Ma.State<N>>, +price: N) -> List<&1, Ma.State<N>> & Maybe<&2, N>:
  match fuel stages:
    case 0n _: (stages, Some{price})
    case 1n+fuel Nil{}: (Nil{}, Some{price})
    case 1n+fuel first <> rest: pipeline.read(~N, rest, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, first, price), stages => x => pipeline.step(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, fuel, stages, x))

def pipeline.init(~N: Data, first: Result<&2, &1, Parameters.Error, Ma.State<N>>, rest: Result<&2, &1, Parameters.Error, Pipeline<N>>) -> Result<&2, &1, Parameters.Error, Pipeline<N>>:
  match first rest:
    case Fail{error} _: Fail{error}
    case Done{first} Fail{error}: Fail{error}
    case Done{first} Done{Pipeline{count, stages}}: Done{Pipeline{1n+count, first <> stages}}

def pipeline.output(~N: Data, count: Nat, result: List<&1, Ma.State<N>> & Maybe<&2, N>) -> Pipeline<N> & Maybe<&2, N>:
  match result:
    case (stages, value): (Pipeline{count, stages}, value)

def pipeline.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Pipeline<N>, +price: N) -> Pipeline<N> & Maybe<&2, N>:
  match state:
    case Pipeline{+count, stages}: pipeline.output(~N, count, pipeline.step(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, count, stages, price))

def ao.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~near_zero: N -> Bool, state: Dual<N>, bar: Bar.HL<N>) -> Dual<N> & Maybe<&2, N>:
  match bar:
    case Bar.HL{high, low}: dual.difference(~N, ~from, ~add, ~sub, ~mul, ~div, ~near_zero, dual.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, state, div(add(high, low), from(2))), False{})

def ac.value(~N: Data, result: MACD<N> & Maybe<&2, MACDValue<N>>) -> MACD<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{MACDValue{line, signal, histogram}}): (state, Some{histogram})

def ac.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: MACD<N>, bar: Bar.HL<N>) -> MACD<N> & Maybe<&2, N>:
  match bar:
    case Bar.HL{high, low}: ac.value(~N, macd.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, state, div(add(high, low), from(2))))

def qstick.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Ma.State<N>, bar: Bar.OHLC<N>) -> Ma.State<N> & Maybe<&2, N>:
  match bar:
    case Bar.OHLC{open, high, low, close}: Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, state, sub(close, open))

type Eri<-N: Data> is Type:
  Eri{average: Ma.State<N>, origin: Maybe<&2, N>}

def eri.init(~N: Data, result: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, Eri<N>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{average}: Done{Eri{average, None{}}}

def eri.value(~N: Data, ~sub: N -> N -> N, origin: N, high: N, low: N, result: Ma.State<N> & Maybe<&2, N>) -> Eri<N> & Maybe<&2, Lines<N>>:
  match result:
    case (state, None{}): (Eri{state, Some{origin}}, None{})
    case (state, Some{+value}): (Eri{state, Some{origin}}, Some{Lines{sub(high, value), sub(low, value)}})

def eri.bar(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Ma.State<N>, +origin: N, high: N, low: N, close: N) -> Eri<N> & Maybe<&2, Lines<N>>:
  eri.value(~N, ~sub, origin, sub(high, origin), sub(low, origin), Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, state, sub(close, origin)))

def eri.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Eri<N>, bar: Bar.HLC<N>) -> Eri<N> & Maybe<&2, Lines<N>>:
  match state bar:
    case Eri{state, None{}} Bar.HLC{high, low, +close}: eri.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, state, close, high, low, close)
    case Eri{state, Some{origin}} Bar.HLC{high, low, close}: eri.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, state, origin, high, low, close)

type Trix<-N: Data> is Type:
  Trix{pipeline: Pipeline<N>, previous: Maybe<&2, N>}

def trix.init(~N: Data, result: Result<&2, &1, Parameters.Error, Pipeline<N>>) -> Result<&2, &1, Parameters.Error, Trix<N>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{pipeline}: Done{Trix{pipeline, None{}}}

def trix.value(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, previous: Maybe<&2, N>, +price: N) -> Maybe<&2, N>:
  match previous:
    case None{}: None{}
    case Some{+old}: Some{Bool.pick(N, eq(old, from(0)), from(0), mul(sub(div(price, old), from(1)), from(100)))}

def trix.finish(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, previous: Maybe<&2, N>, result: Pipeline<N> & Maybe<&2, N>) -> Trix<N> & Maybe<&2, N>:
  match result:
    case (pipeline, None{}): (Trix{pipeline, previous}, None{})
    case (pipeline, Some{+value}): (Trix{pipeline, Some{value}}, trix.value(~N, ~from, ~sub, ~mul, ~div, ~eq, previous, value))

def trix.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~eq: N -> N -> Bool, state: Trix<N>, +price: N) -> Trix<N> & Maybe<&2, N>:
  match state:
    case Trix{pipeline, previous}: trix.finish(~N, ~from, ~sub, ~mul, ~div, ~eq, previous, pipeline.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, pipeline, price))

type Dosc<-N: Data> is Type:
  Dosc{rsi: Mom.RSI<N>, pipeline: Pipeline<N>, signal: Ma.State<N>}

def dosc.init(~N: Data, rsi: Mom.RSI<N>, pipeline: Result<&2, &1, Parameters.Error, Pipeline<N>>, signal: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, Dosc<N>>:
  match pipeline signal:
    case Fail{error} _: Fail{error}
    case Done{pipeline} Fail{error}: Fail{error}
    case Done{pipeline} Done{signal}: Done{Dosc{rsi, pipeline, signal}}

def dosc.finish(~N: Data, ~sub: N -> N -> N, rsi: Mom.RSI<N>, pipeline: Pipeline<N>, +value: N, result: Ma.State<N> & Maybe<&2, N>) -> Dosc<N> & Maybe<&2, N>:
  match result:
    case (signal, None{}): (Dosc{rsi, pipeline, signal}, None{})
    case (signal, Some{average}): (Dosc{rsi, pipeline, signal}, Some{sub(value, average)})

def dosc.signal(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, rsi: Mom.RSI<N>, signal: Ma.State<N>, result: Pipeline<N> & Maybe<&2, N>) -> Dosc<N> & Maybe<&2, N>:
  match result:
    case (pipeline, None{}): (Dosc{rsi, pipeline, signal}, None{})
    case (pipeline, Some{+value}): dosc.finish(~N, ~sub, rsi, pipeline, value, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, value))

def dosc.rsi(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, pipeline: Pipeline<N>, signal: Ma.State<N>, result: Mom.RSI<N> & Maybe<&2, N>) -> Dosc<N> & Maybe<&2, N>:
  match result:
    case (rsi, None{}): (Dosc{rsi, pipeline, signal}, None{})
    case (rsi, Some{value}): dosc.signal(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, rsi, signal, pipeline.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, pipeline, value))

def dosc.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~max: N -> N -> N, ~atan: N -> N, state: Dosc<N>, +price: N) -> Dosc<N> & Maybe<&2, N>:
  match state:
    case Dosc{rsi, pipeline, signal}: dosc.rsi(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, pipeline, signal, Mom.rsi.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~max, ~gt, rsi, price, False{}))

type Pso<-N: Data> is Type:
  Pso{box: Box.Box<N>, pipeline: Pipeline<N>}

def pso.init(~N: Data, box: Box.Box<N>, result: Result<&2, &1, Parameters.Error, Pipeline<N>>) -> Result<&2, &1, Parameters.Error, Pso<N>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{pipeline}: Done{Pso{box, pipeline}}

def pso.finish(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~tanh: N -> N, box: Box.Box<N>, result: Pipeline<N> & Maybe<&2, N>) -> Pso<N> & Maybe<&2, N>:
  match result:
    case (pipeline, None{}): (Pso{box, pipeline}, None{})
    case (pipeline, Some{value}): (Pso{box, pipeline}, Some{tanh(div(value, from(2)))})

def pso.box(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~tanh: N -> N, pipeline: Pipeline<N>, result: Box.Box<N> & Maybe<&2, Box.Bounds<N>>) -> Pso<N> & Maybe<&2, N>:
  match result:
    case (box, None{}): (Pso{box, pipeline}, None{})
    case (box, Some{bounds}):
      +value = div(sub(Box.stochastic(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, bounds, from(50)), from(50)), from(10))
      pso.finish(~N, ~from, ~div, ~tanh, box, pipeline.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, pipeline, value))

def pso.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~ge: N -> N -> Bool, ~atan: N -> N, ~tanh: N -> N, state: Pso<N>, bar: Bar.HLC<N>) -> Pso<N> & Maybe<&2, N>:
  match state:
    case Pso{box, pipeline}: pso.box(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, ~tanh, pipeline, Box.box.next(~N, ~ge, ~le, box, bar))
