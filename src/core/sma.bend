import Base
import ./rolling.bend as Rolling

type State<-N: Data> is Type:
  Sma{period: U32, ring: Rolling.State<N>}

def init(~N: Data, ~from_u32: U32 -> N, +period: U32, depth: Nat) -> State<N>:
  Sma{period, Rolling.init(~N, ~from_u32, period, depth)}

def emit(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N,
  +period: U32, result: Rolling.State<N> & Maybe<&2, N>
) -> State<N> & Maybe<&2, N>:
  match result:
    case (ring, sum):
      (Sma{period, ring}, Rolling.average(~N, ~from_u32, ~div, period, sum))

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N,
  ~sub: N -> N -> N, ~div: N -> N -> N, state: State<N>, price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Sma{+period, ring}:
      emit(~N, ~from_u32, ~div, period, Rolling.push(~N, ~add, ~sub, ring, price))
