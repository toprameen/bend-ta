import Base
import ./window.bend as Window

type Total<-N: Data> is Data:
  Total{sum: N, correction: N}

type State<-N: Data> is Type:
  Sum{window: Window.State<N>, total: Total<N>}

def init(~N: Data, ~from_u32: U32 -> N, period: U32, depth: Nat) -> State<N>:
  +zero = from_u32(0)
  Sum{Window.init(~N, period, depth, zero), Total{zero, zero}}

def average(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, period: U32, value: Maybe<&2, N>) -> Maybe<&2, N>:
  match value:
    case None{}:
      None{}
    case Some{sum}:
      Some{div(sum, from_u32(period))}

def sum_error(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, +a: N, b: N, +sum: N) -> N:
  +rounded = sub(sum, a)
  add(sub(a, sub(sum, rounded)), sub(b, rounded))

def accumulate(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, total: Total<N>, +value: N) -> Total<N>:
  match total:
    case Total{+sum, correction}:
      +next = add(sum, value)
      +low = add(correction, sum_error(~N, ~add, ~sub, sum, value, next))
      +high = add(next, low)
      Total{high, sum_error(~N, ~add, ~sub, next, low, high)}

def value(~N: Data, total: Total<N>) -> N:
  match total:
    case Total{sum, correction}: sum

def update(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, total: Total<N>, zero: N, price: N, removed: Maybe<&2, N>) -> Total<N>:
  match removed:
    case None{}:
      accumulate(~N, ~add, ~sub, total, price)
    case Some{old}:
      accumulate(~N, ~add, ~sub, accumulate(~N, ~add, ~sub, total, sub(zero, old)), price)

def emit(~N: Data, +total: Total<N>, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, full):
      (Sum{window, total}, Bool.pick(Maybe<&2, N>, full, Some{value(~N, total)}, None{}))

def rebuild.emit(~N: Data, result: Window.State<N> & Total<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, +total): (Sum{window, total}, Some{value(~N, total)})

def advance(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, +zero: N, total: Total<N>, price: N, removed: Maybe<&2, N>, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): emit(~N, update(~N, ~add, ~sub, total, zero, price, removed), Window.full(~N, window))
    case (window, True{}):
      rebuild.emit(~N, Window.fold(~N, ~Unit, ~Total<N>, ~(c => s => x => accumulate(~N, ~add, ~sub, s, x)), window, Unit{}, Total{zero, zero}))

def pushed(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N,
  total: Total<N>, +price: N, result: Window.State<N> & Maybe<&2, N>
) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, removed):
      advance(~N, ~add, ~sub, sub(price, price), total, price, removed, Window.cycled(~N, window))

def push(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N,
  state: State<N>, +price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Sum{window, total}:
      pushed(~N, ~add, ~sub, total, price, Window.push(~N, window, price))
