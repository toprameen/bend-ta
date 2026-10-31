import Base
import ./window.bend as Window

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
