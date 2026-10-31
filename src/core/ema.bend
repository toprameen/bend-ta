import Base
import ./smoothing.bend as Smooth

type State<-N: Data> is Data:
  Seed{period: U32, seen: U32, alpha: N, origin: N, delta_sum: N}
  Live{period: U32, alpha: N, value: N}

def init.alpha(~N: Data, ~from_u32: U32 -> N, period: U32, alpha: N) -> State<N>:
  +zero = from_u32(0)
  Seed{period, 0, alpha, zero, zero}

def init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, +period: U32) -> State<N>:
  init.alpha(~N, ~from_u32, period, div(from_u32(2), from_u32(U32.add(period, 1))))

def seed.finish(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N,
  +period: U32, seen: U32, alpha: N, +origin: N, sum: N, ready: Bool
) -> State<N> & Maybe<&2, N>:
  match ready:
    case False{}:
      (Seed{period, seen, alpha, origin, sum}, None{})
    case True{}:
      +mean = Bool.pick(N, U32.is_eq(period, 1), origin, add(origin, div(sum, from_u32(period))))
      (Live{period, alpha, mean}, Some{mean})

def seed.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  +period: U32, seen: U32, alpha: N, +origin: N, sum: N, price: N, first: Bool
) -> State<N> & Maybe<&2, N>:
  match first:
    case True{}:
      seed.finish(~N, ~from_u32, ~add, ~div, period, 1, alpha, price, from_u32(0), U32.is_eq(period, 1))
    case False{}:
      +count = U32.add(seen, 1)
      seed.finish(~N, ~from_u32, ~add, ~div, period, count, alpha, origin, add(sum, sub(price, origin)), U32.is_eq(count, period))

def live(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  +period: U32, +alpha: N, previous: N, +price: N, identity: Bool
) -> State<N> & Maybe<&2, N>:
  match identity:
    case True{}:
      (Live{period, alpha, price}, Some{price})
    case False{}:
      +value = Smooth.ema_step(~N, ~add, ~sub, ~mul, alpha, previous, price)
      (Live{period, alpha, value}, Some{value})

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N,
  ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  state: State<N>, price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Seed{period, +seen, alpha, origin, sum}:
      seed.next(~N, ~from_u32, ~add, ~sub, ~div, period, seen, alpha, origin, sum, price, U32.is_zero(seen))
    case Live{+period, alpha, value}:
      live(~N, ~add, ~sub, ~mul, period, alpha, value, price, U32.is_eq(period, 1))
