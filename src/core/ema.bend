import Base
import ./smoothing.bend as Smooth

type State<-N: Data> is Data:
  Ema{period: U32, seen: U32, alpha: N, seed_sum: N, value: N}

def init(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, +period: U32
) -> State<N>:
  +zero = from_u32(0)
  Ema{period, 0, div(from_u32(2), from_u32(U32.add(period, 1))), zero, zero}

def seed.finish(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N,
  +period: U32, seen: U32, alpha: N, +sum: N, ready: Bool
) -> State<N> & Maybe<&2, N>:
  match ready:
    case False{}:
      (Ema{period, seen, alpha, sum, from_u32(0)}, None{})
    case True{}:
      +mean = div(sum, from_u32(period))
      (Ema{period, seen, alpha, sum, mean}, Some{mean})

def live(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  alpha: N, previous: N, price: N, identity: Bool
) -> N:
  match identity:
    case True{}:
      price
    case False{}:
      Smooth.ema_step(~N, ~add, ~sub, ~mul, alpha, previous, price)

def next.phase(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N,
  ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +period: U32, +seen: U32, +alpha: N, sum: N, value: N, price: N, seeding: Bool
) -> State<N> & Maybe<&2, N>:
  match seeding:
    case True{}:
      +count = U32.add(seen, 1)
      seed.finish(~N, ~from_u32, ~div, period, count, alpha, add(sum, price), U32.is_eq(count, period))
    case False{}:
      +next = live(~N, ~add, ~sub, ~mul, alpha, value, price, U32.is_eq(period, 1))
      (Ema{period, seen, alpha, sum, next}, Some{next})

# Seed with the first period samples' SMA; the period-th sample is valid.
def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N,
  ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  state: State<N>, price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Ema{+period, +seen, alpha, sum, value}:
      next.phase(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, seen, alpha, sum, value, price, U32.is_lt(seen, period))
