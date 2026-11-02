import Base
import ./extrema_queue.bend as Queue
import ./bar.bend as Bar
import ./window.bend as Window

type Box<-N: Data> is Type:
  Box{period: U32, range: Queue.State<N>}

type Bounds<-N: Data> is Data:
  Bounds{size: U32, high: N, low: N, up: U32, down: U32, close: N}

type Aroon<-N: Data> is Data:
  Aroon{down: N, up: N}

def box.init(~N: Data, ~from: U32 -> N, +period: U32, depth: Nat) -> Box<N>:
  Box{period, Queue.init(~N, ~from, period, depth)}

def box.output(~N: Data, period: U32, close: N, result: Queue.State<N> & Maybe<&2, Queue.Value<N>>) -> Box<N> & Maybe<&2, Bounds<N>>:
  match result:
    case (range, None{}): (Box{period, range}, None{})
    case (range, Some{Queue.Value{low, high, low_age, high_age, +size}}): (Box{period, range}, Some{Bounds{size, high, low, U32.sub(U32.sub(size, 1), high_age), U32.sub(U32.sub(size, 1), low_age), close}})

def box.next(~N: Data, ~ge: N -> N -> Bool, ~le: N -> N -> Bool, state: Box<N>, bar: Bar.HLC<N>) -> Box<N> & Maybe<&2, Bounds<N>>:
  match state bar:
    case Box{period, range} Bar.HLC{high, low, close}: box.output(~N, period, close, Queue.next(~N, ~le, ~ge, range, low, high))

def scaled_zero(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +value: N, +a: N, +b: N) -> Bool:
  le(abs(value), mul(div(from(1), mul(from(10000000), from(10000000))), add(abs(a), abs(b))))

def stochastic(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, value: Bounds<N>, +flat: N) -> N:
  match value:
    case Bounds{size, +high, +low, up, down, close}:
      +range = sub(high, low)
      Bool.pick(N, scaled_zero(~N, ~from, ~add, ~mul, ~div, ~abs, ~le, range, high, low), flat, mul(div(sub(close, low), range), from(100)))

def willr(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~min: N -> N -> N, ~max: N -> N -> N, value: Bounds<N>) -> N:
  match value:
    case Bounds{size, +high, +low, up, down, close}:
      +range = sub(high, low)
      +negative = sub(from(0), from(100))
      Bool.pick(N, scaled_zero(~N, ~from, ~add, ~mul, ~div, ~abs, ~le, range, high, low), from(0), max(negative, min(from(0), mul(div(sub(high, close), range), negative))))

def aroon(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, value: Bounds<N>) -> Aroon<N>:
  match value:
    case Bounds{size, high, low, up, down, close}:
      +factor = div(from(100), from(U32.sub(size, 1)))
      Aroon{mul(factor, from(down)), mul(factor, from(up))}

def aroonosc(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, value: Bounds<N>) -> N:
  match value:
    case Bounds{size, high, low, up, down, close}:
      mul(div(from(100), from(U32.sub(size, 1))), sub(from(up), from(down)))

type Prices<-N: Data> is Type:
  Prices{period: U32, window: Window.State<N>}

type Scan<-N: Data> is Data:
  Scan{count: U32, origin: N, last: N, low: N, high: N, changes: N}

def prices.init(~N: Data, ~from: U32 -> N, +period: U32, depth: Nat) -> Prices<N>:
  Prices{period, Window.init(~N, period, depth, from(0))}

def prices.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, u: Unit, acc: Maybe<&2, Scan<N>>, +price: N) -> Maybe<&2, Scan<N>>:
  match acc:
    case None{}:
      +zero = from(0)
      Some{Scan{1, price, price, price, price, zero}}
    case Some{Scan{+count, +origin, last, low, high, changes}}:
      Some{Scan{U32.add(count, 1), origin, price, Bool.pick(N, U32.is_eq(count, 1), price, min(low, price)), Bool.pick(N, U32.is_eq(count, 1), price, max(high, price)), add(changes, abs(sub(price, last)))}}

def prices.folded(~N: Data, +period: U32, result: Window.State<N> & Maybe<&2, Scan<N>>) -> Prices<N> & Maybe<&2, Scan<N>>:
  match result:
    case (window, value): (Prices{period, window}, value)

def prices.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, +period: U32, result: Window.State<N> & Bool) -> Prices<N> & Maybe<&2, Scan<N>>:
  match result:
    case (window, False{}): (Prices{period, window}, None{})
    case (window, True{}): prices.folded(~N, period, Window.fold(~N, ~Unit, ~Maybe<&2, Scan<N>>, ~(u => a => x => prices.step(~N, ~from, ~add, ~sub, ~abs, ~min, ~max, u, a, x)), window, Unit{}, None{}))

def prices.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, +period: U32, result: Window.State<N> & Maybe<&2, N>) -> Prices<N> & Maybe<&2, Scan<N>>:
  match result:
    case (window, old): prices.ready(~N, ~from, ~add, ~sub, ~abs, ~min, ~max, period, Window.full(~N, window))

def prices.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, state: Prices<N>, +price: N) -> Prices<N> & Maybe<&2, Scan<N>>:
  match state:
    case Prices{period, window}: prices.pushed(~N, ~from, ~add, ~sub, ~abs, ~min, ~max, period, Window.push(~N, window, price))

def er(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~gt: N -> N -> Bool, value: Scan<N>) -> N:
  match value:
    case Scan{count, origin, last, low, high, +changes}:
      Bool.pick(N, gt(changes, from(0)), min(from(1), abs(div(sub(last, origin), changes))), from(1))

def vhf(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, value: Scan<N>) -> N:
  match value:
    case Scan{count, origin, last, low, high, +changes}:
      Bool.pick(N, gt(changes, from(0)), div(sub(high, low), changes), from(0))

type Swing<-N: Data> is Data:
  Swing{limit: N, previous: Maybe<&2, Bar.OHLC<N>>, total: N}

def swing.init(~N: Data, ~from: U32 -> N, +limit: N) -> Swing<N>:
  Swing{limit, None{}, from(0)}

def swing.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, +limit: N, previous: Bar.OHLC<N>, bar: Bar.OHLC<N>) -> N:
  match previous bar:
    case Bar.OHLC{po, ph, pl, +pc} Bar.OHLC{open, +high, +low, +close}:
      +body = sub(close, open)
      +before = sub(pc, po)
      +half = div(from(1), from(2))
      +quarter = div(from(1), from(4))
      +n = add(add(sub(close, pc), mul(half, body)), mul(quarter, before))
      +up = abs(sub(high, pc))
      +down = abs(sub(low, pc))
      +k = max(up, down)
      +r = add(max(max(sub(up, mul(half, down)), sub(down, mul(half, up))), abs(sub(high, low))), mul(quarter, abs(before)))
      Bool.pick(N, eq(r, from(0)), from(0), mul(mul(from(50), div(n, r)), div(k, limit)))

def swing.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~eq: N -> N -> Bool, state: Swing<N>, +bar: Bar.OHLC<N>, +cumulative: Bool) -> Swing<N> & Maybe<&2, N>:
  match state:
    case Swing{limit, None{}, +total}: (Swing{limit, Some{bar}, total}, Bool.pick(Maybe<&2, N>, cumulative, Some{total}, None{}))
    case Swing{+limit, Some{previous}, total}:
      +swing = swing.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, ~eq, limit, previous, bar)
      +next = Bool.pick(N, cumulative, add(total, swing), swing)
      (Swing{limit, Some{bar}, next}, Some{next})

type WAD<-N: Data> is Data:
  WAD{previous: Maybe<&2, N>, total: N}

def wad.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, state: WAD<N>, bar: Bar.HLC<N>) -> WAD<N> & Maybe<&2, N>:
  match state bar:
    case WAD{None{}, +total} Bar.HLC{high, low, close}: (WAD{Some{close}, total}, Some{total})
    case WAD{Some{+previous}, total} Bar.HLC{high, low, +close}:
      +change = Bool.pick(N, gt(close, previous), sub(close, min(previous, low)), Bool.pick(N, gt(previous, close), sub(close, max(previous, high)), from(0)))
      +next = add(total, change)
      (WAD{Some{close}, next}, Some{next})
