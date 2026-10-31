import Base
import ./bar.bend as Bar
import ./window.bend as Window

type RSI<-N: Data> is Data:
  RSI{period: U32, seen: U32, previous: Maybe<&2, N>, gain: N, loss: N, value: N}

def rsi.init(~N: Data, ~from_u32: U32 -> N, +period: U32) -> RSI<N>:
  +zero = from_u32(0)
  RSI{period, 0, None{}, zero, zero, zero}

def ratio(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, +gain: N, +loss: N, +cmo: Bool) -> N:
  +sum = add(gain, loss)
  +numerator = Bool.pick(N, cmo, sub(gain, loss), gain)
  Bool.pick(N, gt(sum, from_u32(0)), mul(from_u32(100), div(numerator, sum)), Bool.pick(N, cmo, from_u32(0), from_u32(50)))

def rsi.average(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, +seen: U32, +previous: N, +value: N, +seed: Bool) -> N:
  match seed:
    case True{}:
      +sum = add(previous, value)
      Bool.pick(N, U32.is_eq(U32.add(seen, 1), period), div(sum, from_u32(period)), sum)
    case False{}: div(add(mul(previous, from_u32(U32.sub(period, 1))), value), from_u32(period))

def rsi.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool,
  state: RSI<N>, +price: N, +cmo: Bool
) -> RSI<N> & Maybe<&2, N>:
  match state:
    case RSI{period, seen, None{}, gain, loss, value}: (RSI{period, seen, Some{price}, gain, loss, value}, None{})
    case RSI{+period, +seen, Some{previous}, gain, loss, value}:
      +zero = from_u32(0)
      +change = sub(price, previous)
      +up = max(change, zero)
      +down = sub(up, change)
      +n = U32.min(period, U32.add(seen, 1))
      +g = rsi.average(~N, ~from_u32, ~add, ~mul, ~div, period, seen, gain, up, U32.is_lt(seen, period))
      +l = rsi.average(~N, ~from_u32, ~add, ~mul, ~div, period, seen, loss, down, U32.is_lt(seen, period))
      +computed = ratio(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~gt, g, l, cmo)
      +stable = Bool.and(U32.is_ge(seen, period), Bool.and(Bool.and(Bool.not(gt(change, zero)), Bool.not(gt(zero, change))), gt(add(g, l), zero)))
      +output = Bool.pick(N, stable, value, computed)
      (RSI{period, n, Some{price}, g, l, output}, Bool.pick(Maybe<&2, N>, U32.is_eq(n, period), Some{output}, None{}))

type Flows<-N: Data> is Data:
  Flows{first: N, second: N}

def pair.add(~N: Data, ~add: N -> N -> N, u: Unit, acc: Flows<N>, value: Flows<N>) -> Flows<N>:
  match acc value:
    case Flows{a, b} Flows{c, d}: Flows{add(a, c), add(b, d)}

type Flow<-N: Data> is Type:
  Flow{period: U32, previous: Maybe<&2, N>, window: Window.State<Flows<N>>}

def flow.init(~N: Data, ~from_u32: U32 -> N, +period: U32, +depth: Nat) -> Flow<N>:
  +zero = from_u32(0)
  Flow{period, None{}, Window.init(~Flows<N>, period, depth, Flows{zero, zero})}

def flow.ready(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, +period: U32, previous: Maybe<&2, N>, result: Window.State<Flows<N>> & Flows<N>) -> Flow<N> & Maybe<&2, Flows<N>>:
  match result:
    case (window, total): (Flow{period, previous, window}, Some{total})

def flow.full(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, +period: U32, previous: Maybe<&2, N>, result: Window.State<Flows<N>> & Bool) -> Flow<N> & Maybe<&2, Flows<N>>:
  match result:
    case (window, False{}): (Flow{period, previous, window}, None{})
    case (window, True{}):
      +zero = from_u32(0)
      flow.ready(~N, ~from_u32, ~add, period, previous, Window.fold(~Flows<N>, ~Unit, ~Flows<N>, ~(u => a => x => pair.add(~N, ~add, u, a, x)), window, Unit{}, Flows{zero, zero}))

def flow.pushed(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, +period: U32, previous: Maybe<&2, N>, result: Window.State<Flows<N>> & Maybe<&2, Flows<N>>) -> Flow<N> & Maybe<&2, Flows<N>>:
  match result:
    case (window, old): flow.full(~N, ~from_u32, ~add, period, previous, Window.full(~Flows<N>, window))

def flow.push(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, +period: U32, previous: Maybe<&2, N>, window: Window.State<Flows<N>>, value: Flows<N>) -> Flow<N> & Maybe<&2, Flows<N>>:
  flow.pushed(~N, ~from_u32, ~add, period, previous, Window.push(~Flows<N>, window, value))

def cmou.next(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~max: N -> N -> N, state: Flow<N>, +price: N) -> Flow<N> & Maybe<&2, Flows<N>>:
  match state:
    case Flow{period, None{}, window}: (Flow{period, Some{price}, window}, None{})
    case Flow{period, Some{previous}, window}:
      +change = sub(price, previous)
      +up = max(from_u32(0), change)
      flow.push(~N, ~from_u32, ~add, period, Some{price}, window, Flows{up, sub(up, change)})

def imi.next(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~max: N -> N -> N, state: Flow<N>, bar: Bar.OHLC<N>) -> Flow<N> & Maybe<&2, Flows<N>>:
  match state bar:
    case Flow{period, previous, window} Bar.OHLC{open, high, low, close}:
      +change = sub(close, open)
      +up = max(from_u32(0), change)
      flow.push(~N, ~from_u32, ~add, period, previous, window, Flows{up, sub(up, change)})

def flow.ratio(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, result: Flow<N> & Maybe<&2, Flows<N>>, +cmo: Bool) -> Flow<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{Flows{gain, loss}}): (state, Some{ratio(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~gt, gain, loss, cmo)})
