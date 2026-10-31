import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./moments.bend as Moments
import ./extrema.bend as Extrema
import ./ema.bend as Ema
import ./ma.bend as Ma
import ./parameters.bend as Parameters
import ./volatility.bend as Vol

type Bands<-N: Data> is Data:
  Bands{upper: N, middle: N, lower: N}

def channel.step(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, u: Unit, acc: Maybe<&2, Bar.HL<N>>, bar: Bar.HL<N>) -> Maybe<&2, Bar.HL<N>>:
  match acc bar:
    case None{} Bar.HL{h, l}: Some{Bar.HL{h, l}}
    case Some{Bar.HL{h, l}} Bar.HL{high, low}: Some{Bar.HL{max(h, high), min(l, low)}}

def channel.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, result: Window.State<Bar.HL<N>> & Maybe<&2, Bar.HL<N>>) -> Window.State<Bar.HL<N>> & Maybe<&2, Bands<N>>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{Bar.HL{+high, +low}}): (window, Some{Bands{high, div(add(high, low), from(2)), low}})

def channel.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, result: Window.State<Bar.HL<N>> & Bool) -> Window.State<Bar.HL<N>> & Maybe<&2, Bands<N>>:
  match result:
    case (window, False{}): (window, None{})
    case (window, True{}): channel.finish(~N, ~from, ~add, ~div, Window.fold(~Bar.HL<N>, ~Unit, ~Maybe<&2, Bar.HL<N>>, ~(u => a => x => channel.step(~N, ~min, ~max, u, a, x)), window, Unit{}, None{}))

def channel.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, result: Window.State<Bar.HL<N>> & Maybe<&2, Bar.HL<N>>) -> Window.State<Bar.HL<N>> & Maybe<&2, Bands<N>>:
  match result:
    case (window, old): channel.ready(~N, ~from, ~add, ~div, ~min, ~max, Window.full(~Bar.HL<N>, window))

def channel.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, window: Window.State<Bar.HL<N>>, bar: Bar.HL<N>) -> Window.State<Bar.HL<N>> & Maybe<&2, Bands<N>>:
  channel.pushed(~N, ~from, ~add, ~div, ~min, ~max, Window.push(~Bar.HL<N>, window, bar))

type Bollinger<-N: Data> is Type:
  Bollinger{average: Ma.State<N>, moments: Window.State<N>, up: N, down: N, kind: U32}

def bollinger.initialized(~N: Data, ~from: U32 -> N, period: U32, depth: Nat, up: N, down: N, kind: U32, result: Result<&2, &1, Parameters.Error, Ma.State<N>>) -> Result<&2, &1, Parameters.Error, Bollinger<N>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{average}: Done{Bollinger{average, Window.init(~N, period, depth, from(0)), up, down, kind}}

def bollinger.init(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, depth: Nat, up: N, down: N, +kind: U32) -> Result<&2, &1, Parameters.Error, Bollinger<N>>:
  bollinger.initialized(~N, ~from, period, depth, up, down, kind, Ma.init(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, kind))

type BollingerValue<-N: Data> is Data:
  BollingerValue{bands: Bands<N>, width: N, percent: N}

def bollinger.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, +up: N, +down: N, +mean: N, +deviation: N, residual: N) -> BollingerValue<N>:
  +spread = mul(add(up, down), deviation)
  +zero = from(0)
  +flat = Bool.and(le(spread, zero), le(zero, spread))
  +no_center = Bool.and(le(mean, zero), le(zero, mean))
  BollingerValue{Bands{add(mean, mul(up, deviation)), mean, sub(mean, mul(down, deviation))}, Bool.pick(N, no_center, zero, mul(div(spread, mean), from(100))), Bool.pick(N, flat, div(from(1), from(2)), div(add(residual, mul(down, deviation)), spread))}

def bollinger.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, average: Ma.State<N>, +up: N, +down: N, +kind: U32, +price: N, +mean: N, deviation: N, count: U32, result: Window.State<N> & N) -> Bollinger<N> & Maybe<&2, BollingerValue<N>>:
  match result:
    case (moments, delta):
      (Bollinger{average, moments, up, down, kind}, Some{bollinger.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, up, down, mean, deviation, Bool.pick(N, U32.is_zero(kind), sub(from(0), div(delta, from(count))), sub(price, mean)))})

def bollinger.scan(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, average: Ma.State<N>, up: N, down: N, kind: U32, +price: N, mean: N, deviation: N, window: Window.State<N>) -> Bollinger<N> & Maybe<&2, BollingerValue<N>>:
  match window:
    case Window.Window{buffer, +period, size, pos}: bollinger.finish(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, average, up, down, kind, price, mean, deviation, period, Window.fold(~N, ~N, ~N, ~(c => a => x => Moments.delta(~N, ~add, ~sub, c, a, x)), Window.Window{buffer, period, size, pos}, price, from(0)))

def bollinger.values(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, ~sqrt: N -> N, average: Ma.State<N>, moments: Window.State<N>, up: N, down: N, +kind: U32, +price: N, av: Maybe<&2, N>, stats: Maybe<&2, Moments.Value<N>>) -> Bollinger<N> & Maybe<&2, BollingerValue<N>>:
  match av stats:
    case Some{m} Some{Moments.Moments{mean, variance}}:
      bollinger.scan(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, average, up, down, kind, price, Bool.pick(N, U32.is_zero(kind), mean, m), sqrt(variance), moments)
    case _ _: (Bollinger{average, moments, up, down, kind}, None{})

def bollinger.moments(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, ~sqrt: N -> N, average: Ma.State<N>, up: N, down: N, kind: U32, price: N, value: Maybe<&2, N>, result: Window.State<N> & Maybe<&2, Moments.Value<N>>) -> Bollinger<N> & Maybe<&2, BollingerValue<N>>:
  match result:
    case (moments, stats): bollinger.values(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, ~sqrt, average, moments, up, down, kind, price, value, stats)

def bollinger.average(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, ~sqrt: N -> N, moments: Window.State<N>, up: N, down: N, kind: U32, +price: N, result: Ma.State<N> & Maybe<&2, N>) -> Bollinger<N> & Maybe<&2, BollingerValue<N>>:
  match result:
    case (average, value): bollinger.moments(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, ~sqrt, average, up, down, kind, price, value, Moments.next(~N, ~from, ~add, ~sub, ~mul, ~div, moments, price))

def bollinger.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~sqrt: N -> N, state: Bollinger<N>, +price: N) -> Bollinger<N> & Maybe<&2, BollingerValue<N>>:
  match state:
    case Bollinger{average, moments, up, down, kind}: bollinger.average(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, ~sqrt, moments, up, down, kind, price, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, average, price))

type Acceleration<-N: Data> is Type:
  Acceleration{upper: Window.State<N>, middle: Window.State<N>, lower: Window.State<N>}

def accbands.init(~N: Data, ~from: U32 -> N, +period: U32, +depth: Nat) -> Acceleration<N>:
  +zero = from(0)
  Acceleration{Window.init(~N, period, depth, zero), Window.init(~N, period, depth, zero), Window.init(~N, period, depth, zero)}

def acceleration.value(~N: Data, upper: Maybe<&2, N>, middle: Maybe<&2, N>, lower: Maybe<&2, N>) -> Maybe<&2, Bands<N>>:
  match upper middle lower:
    case Some{u} Some{m} Some{l}: Some{Bands{u, m, l}}
    case _ _ _: None{}

def acceleration.lower(~N: Data, upper: Window.State<N>, middle: Window.State<N>, u: Maybe<&2, N>, m: Maybe<&2, N>, result: Window.State<N> & Maybe<&2, N>) -> Acceleration<N> & Maybe<&2, Bands<N>>:
  match result:
    case (lower, l): (Acceleration{upper, middle, lower}, acceleration.value(~N, u, m, l))

def acceleration.middle(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, upper: Window.State<N>, lower: Window.State<N>, u: Maybe<&2, N>, low: N, result: Window.State<N> & Maybe<&2, N>) -> Acceleration<N> & Maybe<&2, Bands<N>>:
  match result:
    case (middle, m): acceleration.lower(~N, upper, middle, u, m, Ma.mean.next(~N, ~from, ~add, ~sub, ~div, lower, low))

def acceleration.upper(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, middle: Window.State<N>, lower: Window.State<N>, mid: N, low: N, result: Window.State<N> & Maybe<&2, N>) -> Acceleration<N> & Maybe<&2, Bands<N>>:
  match result:
    case (upper, u): acceleration.middle(~N, ~from, ~add, ~sub, ~div, upper, lower, u, low, Ma.mean.next(~N, ~from, ~add, ~sub, ~div, middle, mid))

def acceleration.bar(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, upper: Window.State<N>, middle: Window.State<N>, lower: Window.State<N>, bar: Bar.HLC<N>) -> Acceleration<N> & Maybe<&2, Bands<N>>:
  match bar:
    case Bar.HLC{+high, +low, close}:
      +den = add(high, low)
      +factor = Bool.pick(N, eq(den, from(0)), from(0), div(mul(from(4), sub(high, low)), den))
      acceleration.upper(~N, ~from, ~add, ~sub, ~div, middle, lower, close, mul(low, sub(from(1), factor)), Ma.mean.next(~N, ~from, ~add, ~sub, ~div, upper, mul(high, add(from(1), factor))))

def acceleration.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, state: Acceleration<N>, bar: Bar.HLC<N>) -> Acceleration<N> & Maybe<&2, Bands<N>>:
  match state:
    case Acceleration{upper, middle, lower}: acceleration.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, upper, middle, lower, bar)

type VolumeWeight<-N: Data> is Data:
  VolumeWeight{value: N, volume: N}

def volume.step(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, origin: N, acc: VolumeWeight<N>, bar: Bar.CV<N>) -> VolumeWeight<N>:
  match acc bar:
    case VolumeWeight{value, volume} Bar.CV{close, +v}: VolumeWeight{add(value, mul(sub(close, origin), v)), add(volume, v)}

def volume.finish(~N: Data, ~add: N -> N -> N, ~div: N -> N -> N, origin: N, result: Window.State<Bar.CV<N>> & VolumeWeight<N>) -> Window.State<Bar.CV<N>> & Maybe<&2, N>:
  match result:
    case (window, VolumeWeight{value, volume}): (window, Some{add(origin, div(value, volume))})

def volume.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +price: N, result: Window.State<Bar.CV<N>> & Bool) -> Window.State<Bar.CV<N>> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, 1, size, pos}, True{}): (Window.Window{buffer, 1, size, pos}, Some{price})
    case (window, True{}): volume.finish(~N, ~add, ~div, price, Window.fold(~Bar.CV<N>, ~N, ~VolumeWeight<N>, ~(c => a => x => volume.step(~N, ~add, ~sub, ~mul, c, a, x)), window, price, VolumeWeight{from(0), from(0)}))

def volume.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, price: N, result: Window.State<Bar.CV<N>> & Maybe<&2, Bar.CV<N>>) -> Window.State<Bar.CV<N>> & Maybe<&2, N>:
  match result:
    case (window, old): volume.ready(~N, ~from, ~add, ~sub, ~mul, ~div, price, Window.full(~Bar.CV<N>, window))

def volume.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, window: Window.State<Bar.CV<N>>, bar: Bar.CV<N>) -> Window.State<Bar.CV<N>> & Maybe<&2, N>:
  match bar:
    case Bar.CV{+close, volume}: volume.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, close, Window.push(~Bar.CV<N>, window, Bar.CV{close, volume}))

type Heikin<-N: Data> is Data:
  First{}
  Heikin{open: N, close: N}

def heikin.prices(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, +open: N, bar: Bar.OHLC<N>) -> Heikin<N> & Maybe<&2, Bar.OHLC<N>>:
  match bar:
    case Bar.OHLC{o, +h, +l, c}:
      +close = div(add(add(add(o, h), l), c), from(4))
      (Heikin{open, close}, Some{Bar.OHLC{open, max(h, max(open, close)), min(l, min(open, close)), close}})

def heikin.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, state: Heikin<N>, bar: Bar.OHLC<N>) -> Heikin<N> & Maybe<&2, Bar.OHLC<N>>:
  match state bar:
    case First{} Bar.OHLC{+o, h, l, +c}: heikin.prices(~N, ~from, ~add, ~div, ~min, ~max, div(add(o, c), from(2)), Bar.OHLC{o, h, l, c})
    case Heikin{o, c} bar: heikin.prices(~N, ~from, ~add, ~div, ~min, ~max, div(add(o, c), from(2)), bar)

type Keltner<-N: Data> is Data:
  Keltner{average: Ema.State<N>, atr: Vol.Atr<N>, delay_average: U32, delay_atr: U32, deviation: N}

def keltner.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, +atr_period: U32, deviation: N) -> Keltner<N>:
  +average_lookback = U32.sub(period, 1)
  +lookback = U32.max(average_lookback, atr_period)
  Keltner{Ema.init(~N, ~from, ~div, period), Vol.atr.init(~N, ~from, ~div, atr_period), U32.sub(lookback, average_lookback), U32.sub(lookback, atr_period), deviation}

def keltner.value(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, factor: N, middle: Maybe<&2, N>, atr: Maybe<&2, N>) -> Maybe<&2, Bands<N>>:
  match middle atr:
    case Some{+m} Some{a}:
      +spread = mul(factor, a)
      Some{Bands{add(m, spread), m, sub(m, spread)}}
    case _ _: None{}

def keltner.atr.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, state: Vol.Atr<N>, delay: U32, bar: Bar.HLC<N>) -> Vol.Atr<N> & Maybe<&2, N>:
  match delay:
    case 0: Vol.atr.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, state, bar)
    case _: (state, None{})

def keltner.ema.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, state: Ema.State<N>, delay: U32, price: N) -> Ema.State<N> & Maybe<&2, N>:
  match delay:
    case 0: Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, state, price)
    case _: (state, None{})

def keltner.atr(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, average: Ema.State<N>, da: U32, dr: U32, +factor: N, m: Maybe<&2, N>, result: Vol.Atr<N> & Maybe<&2, N>) -> Keltner<N> & Maybe<&2, Bands<N>>:
  match result:
    case (atr, a): (Keltner{average, atr, da, dr, factor}, keltner.value(~N, ~add, ~sub, ~mul, factor, m, a))

def keltner.average(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, atr: Vol.Atr<N>, +da: U32, +dr: U32, factor: N, bar: Bar.HLC<N>, result: Ema.State<N> & Maybe<&2, N>) -> Keltner<N> & Maybe<&2, Bands<N>>:
  match result:
    case (average, m): keltner.atr(~N, ~add, ~sub, ~mul, average, Bool.pick(U32, U32.is_zero(da), 0, U32.sub(da, 1)), Bool.pick(U32, U32.is_zero(dr), 0, U32.sub(dr, 1)), factor, m, keltner.atr.step(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, atr, dr, bar))

def keltner.bar(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, average: Ema.State<N>, atr: Vol.Atr<N>, +da: U32, dr: U32, factor: N, bar: Bar.HLC<N>) -> Keltner<N> & Maybe<&2, Bands<N>>:
  match bar:
    case Bar.HLC{+h, +l, +c}: keltner.average(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, atr, da, dr, factor, Bar.HLC{h, l, c}, keltner.ema.step(~N, ~from, ~add, ~sub, ~mul, ~div, average, da, div(add(add(h, l), c), from(3))))

def keltner.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, state: Keltner<N>, bar: Bar.HLC<N>) -> Keltner<N> & Maybe<&2, Bands<N>>:
  match state:
    case Keltner{average, atr, da, dr, factor}: keltner.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, average, atr, da, dr, factor, bar)

type Stops<-N: Data> is Data:
  Stops{high_stop: N, low_stop: N}

type ChandeKroll<-N: Data> is Type:
  ChandeKroll{prices: Window.State<Bar.HL<N>>, stops: Window.State<Bar.HL<N>>, atr: Vol.Atr<N>, factor: N}

def chande.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, depth: Nat, factor: N, stop_period: U32, stop_depth: Nat) -> ChandeKroll<N>:
  +zero = from(0)
  ChandeKroll{Window.init(~Bar.HL<N>, period, depth, Bar.HL{zero, zero}), Window.init(~Bar.HL<N>, stop_period, stop_depth, Bar.HL{zero, zero}), Vol.atr.init(~N, ~from, ~div, period), factor}

def chande.output(~N: Data, prices: Window.State<Bar.HL<N>>, atr: Vol.Atr<N>, factor: N, result: Window.State<Bar.HL<N>> & Maybe<&2, Bands<N>>) -> ChandeKroll<N> & Maybe<&2, Stops<N>>:
  match result:
    case (stops, None{}): (ChandeKroll{prices, stops, atr, factor}, None{})
    case (stops, Some{Bands{high, middle, low}}): (ChandeKroll{prices, stops, atr, factor}, Some{Stops{high, low}})

def chande.values(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, prices: Window.State<Bar.HL<N>>, stops: Window.State<Bar.HL<N>>, atr: Vol.Atr<N>, +factor: N, range: Maybe<&2, Bands<N>>, atr_value: Maybe<&2, N>) -> ChandeKroll<N> & Maybe<&2, Stops<N>>:
  match range atr_value:
    case Some{Bands{high, mid, low}} Some{a}:
      +spread = mul(factor, a)
      chande.output(~N, prices, atr, factor, channel.next(~N, ~from, ~add, ~div, ~min, ~max, stops, Bar.HL{sub(high, spread), add(low, spread)}))
    case _ _: (ChandeKroll{prices, stops, atr, factor}, None{})

def chande.atr(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, prices: Window.State<Bar.HL<N>>, stops: Window.State<Bar.HL<N>>, factor: N, range: Maybe<&2, Bands<N>>, result: Vol.Atr<N> & Maybe<&2, N>) -> ChandeKroll<N> & Maybe<&2, Stops<N>>:
  match result:
    case (atr, a): chande.values(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, prices, stops, atr, factor, range, a)

def chande.range(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, stops: Window.State<Bar.HL<N>>, atr: Vol.Atr<N>, factor: N, bar: Bar.HLC<N>, result: Window.State<Bar.HL<N>> & Maybe<&2, Bands<N>>) -> ChandeKroll<N> & Maybe<&2, Stops<N>>:
  match result:
    case (prices, range): chande.atr(~N, ~from, ~add, ~sub, ~mul, ~div, ~min, ~max, prices, stops, factor, range, Vol.atr.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, atr, bar))

def chande.bar(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, prices: Window.State<Bar.HL<N>>, stops: Window.State<Bar.HL<N>>, atr: Vol.Atr<N>, factor: N, bar: Bar.HLC<N>) -> ChandeKroll<N> & Maybe<&2, Stops<N>>:
  match bar:
    case Bar.HLC{+h, +l, c}: chande.range(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, stops, atr, factor, Bar.HLC{h, l, c}, channel.next(~N, ~from, ~add, ~div, ~min, ~max, prices, Bar.HL{h, l}))

def chande.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, state: ChandeKroll<N>, bar: Bar.HLC<N>) -> ChandeKroll<N> & Maybe<&2, Stops<N>>:
  match state:
    case ChandeKroll{prices, stops, atr, factor}: chande.bar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, prices, stops, atr, factor, bar)


def midpoint(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, value: Extrema.Value<N>) -> N:
  match value:
    case Extrema.Range{low, high}: div(add(low, high), from(2))
