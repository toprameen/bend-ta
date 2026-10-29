import Base

type State<-N: Data> is Type:
  Ring{buffer: Array<N>, pos: U32, total: N}

def init(~N: Data, ~from_u32: U32 -> N, depth: Nat) -> State<N>:
  +zero = from_u32(0)
  Ring{Array.new(N, depth, zero), 0, zero}

def update(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N,
  +period: U32, +price: N, +pos: U32, total: N, swapped: Array<N> & N
) -> State<N> & N:
  match swapped:
    case (buffer, old):
      +next = add(sub(total, old), price)
      (Ring{buffer, U32.mod(U32.add(pos, 1), period), next}, next)

# Internal precondition: period is validated and does not exceed capacity.
def push(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N,
  +period: U32, state: State<N>, +price: N
) -> State<N> & N:
  match state:
    case Ring{buffer, +pos, total}:
      update(~N, ~add, ~sub, period, price, pos, total, Array.swap(N, buffer, pos, price))
