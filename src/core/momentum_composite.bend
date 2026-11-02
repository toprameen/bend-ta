import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./ma.bend as Ma
import ./momentum.bend as Mom
import ./momentum_smooth.bend as Smooth
import ./momentum_window.bend as Box
import ./momentum_market.bend as Market
import ./statistics.bend as Stats
import ./rolling_average.bend as Average
import ./parameters.bend as Parameters

def mfi.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, state: Mom.Flow<N>, bar: Bar.HLCV<N>) -> Mom.Flow<N> & Maybe<&2, Mom.Flows<N>>:
  match state bar:
    case Mom.Flow{period, None{}, window} Bar.HLCV{high, low, close, volume}:
      +typical = div(add(add(high, low), close), from(3))
      (Mom.Flow{period, Some{typical}, window}, None{})
    case Mom.Flow{period, Some{+previous}, window} Bar.HLCV{high, low, close, volume}:
      +typical = div(add(add(high, low), close), from(3))
      +change = sub(typical, previous)
      +money = Bool.pick(N, Box.scaled_zero(~N, ~from, ~add, ~mul, ~div, ~abs, ~le, change, typical, previous), from(0), mul(typical, volume))
      +up = Bool.pick(N, gt(from(0), change), from(0), money)
      +down = Bool.pick(N, gt(from(0), change), money, from(0))
      Mom.flow.push(~N, ~from, ~add, period, Some{typical}, window, Mom.Flows{up, down})

def mfi.ratio(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, result: Mom.Flow<N> & Maybe<&2, Mom.Flows<N>>) -> Mom.Flow<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{Mom.Flows{+up, down}}):
      +sum = add(up, down)
      (state, Some{Bool.pick(N, gt(sum, from(0)), mul(from(100), div(max(from(0), min(sum, up)), sum)), from(0))})

type Ultimate<-N: Data> is Type:
  Ultimate{first: Market.Market<N>, second: Market.Market<N>, third: Market.Market<N>}

def ultimate.third(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, first: Market.Market<N>, second: Market.Market<N>, result: Market.Market<N> & Maybe<&2, Market.Terms<N>>, a: Maybe<&2, Market.Terms<N>>, b: Maybe<&2, Market.Terms<N>>) -> Ultimate<N> & Maybe<&2, N>:
  match result a b:
    case (third, Some{c}) Some{a} Some{b}:
      +value = div(mul(from(100), add(add(mul(from(4), Market.pressure(~N, ~from, ~div, ~gt, a)), mul(from(2), Market.pressure(~N, ~from, ~div, ~gt, b))), Market.pressure(~N, ~from, ~div, ~gt, c))), from(7))
      (Ultimate{first, second, third}, Some{value})
    case (third, _) _ _: (Ultimate{first, second, third}, None{})

def ultimate.second(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, first: Market.Market<N>, third: Market.Market<N>, a: Maybe<&2, Market.Terms<N>>, bar: Bar.HLC<N>, result: Market.Market<N> & Maybe<&2, Market.Terms<N>>) -> Ultimate<N> & Maybe<&2, N>:
  match result:
    case (second, b): ultimate.third(~N, ~from, ~add, ~mul, ~div, ~gt, first, second, Market.next(~N, ~add, ~sub, ~abs, ~min, ~max, third, bar, 2), a, b)

def ultimate.first(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, second: Market.Market<N>, third: Market.Market<N>, +bar: Bar.HLC<N>, result: Market.Market<N> & Maybe<&2, Market.Terms<N>>) -> Ultimate<N> & Maybe<&2, N>:
  match result:
    case (first, a): ultimate.second(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~gt, first, third, a, bar, Market.next(~N, ~add, ~sub, ~abs, ~min, ~max, second, bar, 2))

def ultimate.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, state: Ultimate<N>, +bar: Bar.HLC<N>) -> Ultimate<N> & Maybe<&2, N>:
  match state:
    case Ultimate{first, second, third}: ultimate.first(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, ~gt, second, third, bar, Market.next(~N, ~add, ~sub, ~abs, ~min, ~max, first, bar, 2))

type StochRSI<-N: Data> is Type:
  StochRSI{rsi: Mom.RSI<N>, stoch: Smooth.Stoch<N>}

def stochrsi.init(~N: Data, rsi: Mom.RSI<N>, result: Result<&2, &1, Parameters.Error, Smooth.Stoch<N>>) -> Result<&2, &1, Parameters.Error, StochRSI<N>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{stoch}: Done{StochRSI{rsi, stoch}}

def stochrsi.finish(~N: Data, rsi: Mom.RSI<N>, result: Smooth.Stoch<N> & Maybe<&2, Smooth.StochValue<N>>) -> StochRSI<N> & Maybe<&2, Smooth.StochValue<N>>:
  match result:
    case (stoch, value): (StochRSI{rsi, stoch}, value)

def stochrsi.rsi(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~ge: N -> N -> Bool, ~atan: N -> N, stoch: Smooth.Stoch<N>, result: Mom.RSI<N> & Maybe<&2, N>) -> StochRSI<N> & Maybe<&2, Smooth.StochValue<N>>:
  match result:
    case (rsi, None{}): (StochRSI{rsi, stoch}, None{})
    case (rsi, Some{+value}): stochrsi.finish(~N, rsi, Smooth.stoch.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~ge, ~atan, stoch, Bar.HLC{value, value, value}))

def stochrsi.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~ge: N -> N -> Bool, ~gt: N -> N -> Bool, ~max: N -> N -> N, ~atan: N -> N, state: StochRSI<N>, +price: N) -> StochRSI<N> & Maybe<&2, Smooth.StochValue<N>>:
  match state:
    case StochRSI{rsi, stoch}: stochrsi.rsi(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~ge, ~atan, stoch, Mom.rsi.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~max, ~gt, rsi, price, False{}))

type TSI<-N: Data> is Type:
  TSI{numerator: Smooth.Pipeline<N>, denominator: Smooth.Pipeline<N>, previous: Maybe<&2, N>}

def tsi.init(~N: Data, first: Result<&2, &1, Parameters.Error, Smooth.Pipeline<N>>, second: Result<&2, &1, Parameters.Error, Smooth.Pipeline<N>>) -> Result<&2, &1, Parameters.Error, TSI<N>>:
  match first second:
    case Fail{error} _: Fail{error}
    case Done{first} Fail{error}: Fail{error}
    case Done{first} Done{second}: Done{TSI{first, second, None{}}}

def tsi.finish(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, numerator: Smooth.Pipeline<N>, +price: N, result: Smooth.Pipeline<N> & Maybe<&2, N>, value: Maybe<&2, N>) -> TSI<N> & Maybe<&2, N>:
  match result value:
    case (denominator, Some{+den}) Some{num}: (TSI{numerator, denominator, Some{price}}, Some{Bool.pick(N, gt(den, from(0)), div(mul(from(100), num), den), from(0))})
    case (denominator, _) _: (TSI{numerator, denominator, Some{price}}, None{})

def tsi.numerator(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~atan: N -> N, denominator: Smooth.Pipeline<N>, +price: N, +change: N, result: Smooth.Pipeline<N> & Maybe<&2, N>) -> TSI<N> & Maybe<&2, N>:
  match result:
    case (numerator, value): tsi.finish(~N, ~from, ~mul, ~div, ~gt, numerator, price, Smooth.pipeline.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, denominator, abs(change)), value)

def tsi.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~gt: N -> N -> Bool, ~atan: N -> N, state: TSI<N>, +price: N) -> TSI<N> & Maybe<&2, N>:
  match state:
    case TSI{numerator, denominator, None{}}: (TSI{numerator, denominator, Some{price}}, None{})
    case TSI{numerator, denominator, Some{previous}}:
      +change = sub(price, previous)
      tsi.numerator(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~gt, ~atan, denominator, price, change, Smooth.pipeline.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, numerator, change))

type Forecast<-N: Data> is Type:
  Forecast{window: Average.State<N>, previous: Maybe<&2, N>, origin: Maybe<&2, N>}

def forecast.value(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, previous: Maybe<&2, N>, relative: N, +price: N) -> Maybe<&2, N>:
  match previous:
    case None{}: None{}
    case Some{prediction}: Some{Bool.pick(N, eq(price, from(0)), from(0), div(mul(from(100), sub(relative, prediction)), price))}

def forecast.finish(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, origin: N, previous: Maybe<&2, N>, relative: N, price: N, result: Average.State<N> & Maybe<&2, Stats.Regression<N>>) -> Forecast<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (Forecast{window, None{}, Some{origin}}, None{})
    case (window, Some{Stats.Regression{intercept, slope, endpoint, prediction}}): (Forecast{window, Some{prediction}, Some{origin}}, forecast.value(~N, ~from, ~sub, ~mul, ~div, ~eq, previous, relative, price))

def forecast.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~abs: N -> N, ~le: N -> N -> Bool, state: Forecast<N>, +price: N) -> Forecast<N> & Maybe<&2, N>:
  match state:
    case Forecast{window, previous, None{}}: forecast.finish(~N, ~from, ~sub, ~mul, ~div, ~eq, price, previous, from(0), price, Stats.regress.cached(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, window, from(0)))
    case Forecast{window, previous, Some{+origin}}:
      +relative = sub(price, origin)
      forecast.finish(~N, ~from, ~sub, ~mul, ~div, ~eq, origin, previous, relative, price, Stats.regress.cached(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, window, relative))

type RocLeg<-N: Data> is Type:
  RocLeg{history: Window.State<N>, average: Ma.State<N>, weight: N}

type Roc<-N: Data> is Type:
  Roc{count: Nat, legs: List<&1, RocLeg<N>>, signal: Ma.State<N>}

def roc.init(~N: Data, result: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, Roc<N>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{signal}: Done{Roc{0n, Nil{}, signal}}

def roc.leg(~N: Data, ~from: U32 -> N, +period: U32, depth: Nat, +weight: N, average: Result<&2, &1, Parameters.Error, Ma.State<N>>, result: Result<&2, &1, Parameters.Error, Roc<N>>) -> Result<&2, &1, Parameters.Error, Roc<N>>:
  match average result:
    case Fail{error} _: Fail{error}
    case Done{average} Fail{error}: Fail{error}
    case Done{average} Done{Roc{count, legs, signal}}: Done{Roc{1n+count, RocLeg{Window.init(~N, period, depth, from(0)), average, weight} <> legs, signal}}

def roc.averaged(~N: Data, ~mul: N -> N -> N, history: Window.State<N>, +weight: N, result: Ma.State<N> & Maybe<&2, N>) -> RocLeg<N> & Maybe<&2, N>:
  match result:
    case (average, None{}): (RocLeg{history, average, weight}, None{})
    case (average, Some{value}): (RocLeg{history, average, weight}, Some{mul(value, weight)})

def roc.history(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, average: Ma.State<N>, +weight: N, +price: N, result: Window.State<N> & Maybe<&2, N>) -> RocLeg<N> & Maybe<&2, N>:
  match result:
    case (history, None{}): (RocLeg{history, average, weight}, None{})
    case (history, Some{+old}):
      +value = Bool.pick(N, eq(old, from(0)), from(0), mul(sub(div(price, old), from(1)), from(100)))
      roc.averaged(~N, ~mul, history, weight, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, average, value))

def roc.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, state: RocLeg<N>, +price: N) -> RocLeg<N> & Maybe<&2, N>:
  match state:
    case RocLeg{history, average, weight}: roc.history(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, average, weight, price, Window.push(~N, history, price))

def roc.total(~N: Data, ~add: N -> N -> N, total: Maybe<&2, N>, value: Maybe<&2, N>) -> Maybe<&2, N>:
  match total value:
    case Some{acc} Some{value}: Some{add(acc, value)}
    case _ _: None{}

def roc.finish(~N: Data, state: RocLeg<N>, result: List<&1, RocLeg<N>> & Maybe<&2, N>) -> List<&1, RocLeg<N>> & Maybe<&2, N>:
  match result:
    case (rest, value): (state <> rest, value)

def roc.read(~N: Data, ~add: N -> N -> N, stages: List<&1, RocLeg<N>>, total: Maybe<&2, N>, result: RocLeg<N> & Maybe<&2, N>, rest: List<&1, RocLeg<N>> -> Maybe<&2, N> -> List<&1, RocLeg<N>> & Maybe<&2, N>) -> List<&1, RocLeg<N>> & Maybe<&2, N>:
  match result:
    case (state, value): roc.finish(~N, state, rest(stages, roc.total(~N, ~add, total, value)))

def roc.walk(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, fuel: Nat, legs: List<&1, RocLeg<N>>, +price: N, total: Maybe<&2, N>) -> List<&1, RocLeg<N>> & Maybe<&2, N>:
  match fuel legs:
    case 0n _: (legs, total)
    case 1n+fuel Nil{}: (Nil{}, total)
    case 1n+fuel first <> rest: roc.read(~N, ~add, rest, total, roc.step(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, first, price), stages => sum => roc.walk(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, fuel, stages, price, sum))

def roc.signaled(~N: Data, count: Nat, legs: List<&1, RocLeg<N>>, +line: N, result: Ma.State<N> & Maybe<&2, N>) -> Roc<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (signal, None{}): (Roc{count, legs, signal}, None{})
    case (signal, Some{value}): (Roc{count, legs, signal}, Some{Smooth.Lines{line, value}})

def roc.signal(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, count: Nat, signal: Ma.State<N>, result: List<&1, RocLeg<N>> & Maybe<&2, N>) -> Roc<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (legs, None{}): (Roc{count, legs, signal}, None{})
    case (legs, Some{+value}): roc.signaled(~N, count, legs, value, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, value))

def roc.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, state: Roc<N>, +price: N) -> Roc<N> & Maybe<&2, Smooth.Lines<N>>:
  match state:
    case Roc{+count, legs, signal}: roc.signal(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, count, signal, roc.walk(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, count, legs, price, Some{from(0)}))

def coppock.value(~N: Data, result: Roc<N> & Maybe<&2, Smooth.Lines<N>>) -> Roc<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{Smooth.Lines{line, signal}}): (state, Some{signal})
