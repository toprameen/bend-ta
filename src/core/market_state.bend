import Base
import ./bar.bend as Bar

type Anchored<-N: Data> is Data:
  Anchored{weighted: N, volume: N, value: N}

def vwap.init(~N: Data, ~from: U32 -> N) -> Anchored<N>:
  Anchored{from(0), from(0), from(0)}

def vwap.weight(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, state: Anchored<N>, price: N, +volume: N, valid: Bool) -> Anchored<N>:
  match state valid:
    case Anchored{pv, v, last} False{}: Anchored{pv, v, last}
    case Anchored{pv, v, last} True{}: Anchored{add(pv, mul(price, volume)), add(v, volume), last}

def vwap.output(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, state: Anchored<N>) -> Anchored<N> & Maybe<&2, N>:
  match state:
    case Anchored{+pv, +volume, last}:
      +value = Bool.pick(N, gt(volume, from(0)), div(pv, volume), last)
      (Anchored{pv, volume, value}, Some{value})

def vwap.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, ~finite: N -> Bool, state: Anchored<N>, bar: Bar.HLCV<N>) -> Anchored<N> & Maybe<&2, N>:
  match bar:
    case Bar.HLCV{high, low, close, +volume}:
      +price = div(add(add(high, low), close), from(3))
      vwap.output(~N, ~from, ~div, ~gt, vwap.weight(~N, ~from, ~add, ~mul, state, price, volume, Bool.and(finite(price), finite(volume))))

type ZigValue<-N: Data> is Data:
  ZigValue{pivot: N, direction: Bar.Direction, index: U32}

type ZigZag<-N: Data> is Data:
  ZigZag{up: N, down: N, minimum: U32, remaining: U32, count: U32, age: U32, direction: Bar.Direction, pivot: Maybe<&2, N>}

def zigzag.init(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, sensitivity: N, +minimum: U32) -> ZigZag<N>:
  +fraction = div(sensitivity, from(100))
  ZigZag{add(from(1), fraction), sub(from(1), fraction), minimum, minimum, 0, 0, Bar.Down{}, None{}}

def zigzag.finish(~N: Data, up: N, down: N, minimum: U32, +remaining: U32, +count: U32, +age: U32, +direction: Bar.Direction, +pivot: N) -> ZigZag<N> & Maybe<&2, ZigValue<N>>:
  (ZigZag{up, down, minimum, remaining, count, age, direction, Some{pivot}}, Bool.pick(Maybe<&2, ZigValue<N>>, U32.is_zero(remaining), Some{ZigValue{pivot, direction, U32.sub(U32.sub(count, 1), age)}}, None{}))

def zigzag.extension(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, ~ge: N -> N -> Bool, up: N, down: N, minimum: U32, remaining: U32, count: U32, +age: U32, direction: Bar.Direction, +pivot: N, bar: Bar.HL<N>) -> ZigZag<N> & Maybe<&2, ZigValue<N>>:
  match direction bar:
    case Bar.Down{} Bar.HL{high, +low}: zigzag.finish(~N, up, down, minimum, remaining, count, Bool.pick(U32, ge(pivot, low), 0, age), Bar.Down{}, min(pivot, low))
    case Bar.Up{} Bar.HL{+high, low}: zigzag.finish(~N, up, down, minimum, remaining, count, Bool.pick(U32, ge(high, pivot), 0, age), Bar.Up{}, max(pivot, high))

def zigzag.reversal(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, ~ge: N -> N -> Bool, up: N, down: N, minimum: U32, remaining: U32, count: U32, age: U32, direction: Bar.Direction, pivot: N, bar: Bar.HL<N>, reverse: Bool) -> ZigZag<N> & Maybe<&2, ZigValue<N>>:
  match direction bar reverse:
    case Bar.Down{} Bar.HL{high, low} True{}: zigzag.finish(~N, up, down, minimum, remaining, count, 0, Bar.Up{}, high)
    case Bar.Up{} Bar.HL{high, low} True{}: zigzag.finish(~N, up, down, minimum, remaining, count, 0, Bar.Down{}, low)
    case d b False{}: zigzag.extension(~N, ~min, ~max, ~ge, up, down, minimum, remaining, count, age, d, pivot, b)

def zigzag.update(~N: Data, ~mul: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~ge: N -> N -> Bool, +up: N, +down: N, +minimum: U32, remaining: U32, count: U32, +age: U32, +direction: Bar.Direction, +pivot: N, +bar: Bar.HL<N>) -> ZigZag<N> & Maybe<&2, ZigValue<N>>:
  match direction bar:
    case Bar.Down{} Bar.HL{high, low}: zigzag.reversal(~N, ~min, ~max, ~ge, up, down, minimum, remaining, count, age, direction, pivot, bar, Bool.and(U32.is_ge(age, minimum), ge(high, mul(pivot, up))))
    case Bar.Up{} Bar.HL{high, low}: zigzag.reversal(~N, ~min, ~max, ~ge, up, down, minimum, remaining, count, age, direction, pivot, bar, Bool.and(U32.is_ge(age, minimum), ge(mul(pivot, down), low)))

def zigzag.next(~N: Data, ~mul: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~ge: N -> N -> Bool, state: ZigZag<N>, bar: Bar.HL<N>) -> ZigZag<N> & Maybe<&2, ZigValue<N>>:
  match state bar:
    case ZigZag{up, down, minimum, remaining, count, age, direction, None{}} Bar.HL{high, low}: (ZigZag{up, down, minimum, remaining, 1, 0, Bar.Down{}, Some{low}}, None{})
    case ZigZag{up, down, minimum, +remaining, count, age, direction, Some{pivot}} b: zigzag.update(~N, ~mul, ~min, ~max, ~ge, up, down, minimum, U32.sub(remaining, Bool.pick(U32, U32.is_zero(remaining), 0, 1)), U32.add(count, 1), U32.add(age, 1), direction, pivot, b)
