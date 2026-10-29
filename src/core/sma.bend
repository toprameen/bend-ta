import Base
import ./rolling.bend as Rolling

type State<-N: Data> is Type:
  Sma{period: U32, seen: U32, ring: Rolling.State<N>}

def init(~N: Data, ~from_u32: U32 -> N, period: U32, depth: Nat) -> State<N>:
  Sma{period, 0, Rolling.init(~N, ~from_u32, depth)}

def emit(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N,
  +period: U32, seen: U32, ring: Rolling.State<N>, sum: N, ready: Bool
) -> State<N> & Maybe<&2, N>:
  match ready:
    case False{}:
      (Sma{period, seen, ring}, None{})
    case True{}:
      (Sma{period, seen, ring}, Some{div(sum, from_u32(period))})

def next.result(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N,
  +period: U32, +seen: U32, result: Rolling.State<N> & N
) -> State<N> & Maybe<&2, N>:
  match result:
    case (ring, sum):
      emit(~N, ~from_u32, ~div, period, seen, ring, sum, U32.is_eq(seen, period))

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N,
  ~sub: N -> N -> N, ~div: N -> N -> N, state: State<N>, price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Sma{+period, +seen, ring}:
      next.result(~N, ~from_u32, ~div, period, U32.min(U32.add(seen, 1), period), Rolling.push(~N, ~add, ~sub, period, ring, price))
