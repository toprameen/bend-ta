import Base
import ./window.bend as Window
import ./rolling_average.bend as Average

type Value<-N: Data> is Data:
  Moments{mean: N, variance: N}

type Center<-N: Data> is Data:
  Center{origin: N, mean_delta: N}

def delta(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, origin: N, sum: N, price: N) -> N:
  add(sum, sub(price, origin))

def square(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, center: Center<N>, sum: N, price: N) -> N:
  match center:
    case Center{origin, mean_delta}:
      +distance = sub(sub(price, origin), mean_delta)
      add(sum, mul(distance, distance))

def finish(~N: Data, ~div: N -> N -> N, mean: N, count: N, result: Window.State<N> & N) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, sum):
      (window, Some{Moments{mean, div(sum, count)}})

def centered(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +count: N, +origin: N, result: Window.State<N> & N
) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, sum):
      +mean_delta = div(sum, count)
      finish(~N, ~div, add(origin, mean_delta), count,
        Window.fold(~N, ~Center<N>, ~N, ~(c => acc => x => square(~N, ~add, ~sub, ~mul, c, acc, x)), window, Center{origin, mean_delta}, from_u32(0)))

def origin(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  count: U32, result: Window.State<N> & Maybe<&2, N>
) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, None{}):
      (window, None{})
    case (window, Some{+anchor}):
      centered(~N, ~from_u32, ~add, ~sub, ~mul, ~div, from_u32(count), anchor,
        Window.fold(~N, ~N, ~N, ~(a => acc => x => delta(~N, ~add, ~sub, a, acc, x)), window, anchor, from_u32(0)))

def counted(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  result: Window.State<N> & U32
) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, count):
      origin(~N, ~from_u32, ~add, ~sub, ~mul, ~div, count, Window.lag(~N, window, 0))

def ready(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  result: Window.State<N> & Bool
) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, False{}):
      (window, None{})
    case (window, True{}):
      counted(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Window.length(~N, window))

def read(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  window: Window.State<N>
) -> Window.State<N> & Maybe<&2, Value<N>>:
  ready(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Window.full(~N, window))

def pushed(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  result: Window.State<N> & Maybe<&2, N>
) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, old):
      read(~N, ~from_u32, ~add, ~sub, ~mul, ~div, window)

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  window: Window.State<N>, price: N
) -> Window.State<N> & Maybe<&2, Value<N>>:
  pushed(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Window.push(~N, window, price))

def energy.safe(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, energy: N, count: U32) -> Bool:
  +minimum = div(div(div(div(from(1), from(1073741824)), from(1073741824)), from(1073741824)), from(4194304))
  le(minimum, div(energy, from(count)))

type Values<-N: Data> is Data:
  Values{origin: N, total: Average.Sum<N>, squares: Average.Sum<N>, peak: N, flat: Bool}

type Cached<-N: Data> is Type:
  Cached{window: Window.State<N>, cache: Maybe<&2, Values<N>>}

def cached.init(~N: Data, ~from: U32 -> N, +period: U32, depth: Nat) -> Cached<N>:
  Cached{Window.init(~N, period, depth, from(0)), None{}}

def cached.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, values: Values<N>) -> Value<N>:
  match values:
    case Values{origin, +total, squares, peak, flat}:
      +mean = div(Average.sum.value(~N, total), from(period))
      Moments{add(origin, mean), div(sub(Average.sum.value(~N, squares), mul(Average.sum.value(~N, total), mean)), from(period))}

def cached.valid(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, values: Values<N>) -> Bool:
  match values:
    case Values{+origin, +total, squares, peak, flat}:
      +s = Average.sum.value(~N, total)
      +q = Average.sum.value(~N, squares)
      +m2 = sub(q, mul(s, div(s, from(period))))
      +bounded = mul(q, from(16))
      +mean = add(origin, div(s, from(period)))
      +stable_mean = Bool.and(le(abs(origin), mul(from(32), abs(mean))), le(div(q, from(period)), mul(from(1024), mul(mean, mean))))
      +stable_energy = Bool.or(flat, energy.safe(~N, ~from, ~div, ~le, m2, period))
      +stable_scale = Bool.and(le(sub(bounded, bounded), from(0)), Bool.and(le(q, mul(from(32), m2)), le(div(peak, from(65536)), q)))
      Bool.and(stable_mean, Bool.and(stable_energy, stable_scale))

def cached.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, +origin: N, values: Values<N>, price: N) -> Values<N>:
  match values:
    case Values{anchor, total, squares, peak, flat}:
      +d = sub(price, origin)
      Values{origin, Average.sum.add(~N, ~add, ~sub, total, d), Average.sum.add(~N, ~add, ~sub, squares, mul(d, d)), peak, Bool.and(flat, Bool.and(le(d, from(0)), le(from(0), d)))}

def cached.fresh(~N: Data, cache: Maybe<&2, Values<N>>, result: Window.State<N> & Maybe<&2, Value<N>>) -> Cached<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, value): (Cached{window, cache}, value)

def cached.accepted(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, window: Window.State<N>, +values: Values<N>, valid: Bool) -> Cached<N> & Maybe<&2, Value<N>>:
  match valid:
    case True{}: (Cached{window, Some{values}}, Some{cached.value(~N, ~from, ~add, ~sub, ~mul, ~div, period, values)})
    case False{}: cached.fresh(~N, None{}, read(~N, ~from, ~add, ~sub, ~mul, ~div, window))

def cached.rebuilt(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, result: Window.State<N> & Values<N>) -> Cached<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, Values{origin, total, +squares, peak, flat}):
      +values : Values<N> = Values{origin, total, squares, Average.sum.value(~N, squares), flat}
      cached.accepted(~N, ~from, ~add, ~sub, ~mul, ~div, period, window, values, cached.valid(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, values))

def cached.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, result: Window.State<N> & Maybe<&2, N>) -> Cached<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, None{}): (Cached{window, None{}}, None{})
    case (window, Some{+origin}):
      +zero = from(0)
      cached.rebuilt(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, Window.fold(~N, ~N, ~Values<N>, ~(o => a => x => cached.step(~N, ~from, ~add, ~sub, ~mul, ~le, o, a, x)), window, origin, Values{origin, Average.Sum{zero, zero}, Average.Sum{zero, zero}, zero, True{}}))

def cached.rebuild(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, window: Window.State<N>) -> Cached<N> & Maybe<&2, Value<N>>:
  cached.anchor(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, Window.lag(~N, window, 0))

def cached.changed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, window: Window.State<N>, +values: Values<N>, valid: Bool) -> Cached<N> & Maybe<&2, Value<N>>:
  match valid:
    case True{}: (Cached{window, Some{values}}, Some{cached.value(~N, ~from, ~add, ~sub, ~mul, ~div, period, values)})
    case False{}: cached.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, window)

def cached.update(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, window: Window.State<N>, values: Values<N>, old: N, price: N) -> Cached<N> & Maybe<&2, Value<N>>:
  match values:
    case Values{+origin, total, squares, +peak, flat}:
      +before = sub(old, origin)
      +after = sub(price, origin)
      +next = Average.sum.change(~N, ~from, ~add, ~sub, squares, mul(before, before), mul(after, after))
      +changed : Values<N> = Values{origin, Average.sum.change(~N, ~from, ~add, ~sub, total, before, after), next, Bool.pick(N, le(Average.sum.value(~N, next), peak), peak, Average.sum.value(~N, next)), Bool.and(flat, Bool.and(le(after, from(0)), le(from(0), after)))}
      cached.changed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, window, changed, cached.valid(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, changed))

def cached.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, window: Window.State<N>, cache: Maybe<&2, Values<N>>, old: Maybe<&2, N>, price: N, full: Bool, cycle: Bool) -> Cached<N> & Maybe<&2, Value<N>>:
  match cache old full cycle:
    case _ _ False{} _: (Cached{window, None{}}, None{})
    case _ _ True{} True{}: cached.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, window)
    case Some{values} Some{removed} True{} False{}: cached.update(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, window, values, removed, price)
    case _ _ True{} False{}: cached.fresh(~N, None{}, read(~N, ~from, ~add, ~sub, ~mul, ~div, window))

def cached.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, cache: Maybe<&2, Values<N>>, price: N, result: Window.State<N> & Maybe<&2, N>) -> Cached<N> & Maybe<&2, Value<N>>:
  match result:
    case (Window.Window{buffer, +period, +size, +pos}, old): cached.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, Window.Window{buffer, period, size, pos}, cache, old, price, U32.is_eq(size, period), U32.is_zero(pos))

def cached.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: Cached<N>, +price: N) -> Cached<N> & Maybe<&2, Value<N>>:
  match state:
    case Cached{window, cache}: cached.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, cache, price, Window.push(~N, window, price))
