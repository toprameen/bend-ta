import Base
import ./window.bend as Window

type State<-N: Data> is Type:
  Sum{window: Window.State<N>, total: N}

def init(~N: Data, ~from_u32: U32 -> N, period: U32, depth: Nat) -> State<N>:
  +zero = from_u32(0)
  Sum{Window.init(~N, period, depth, zero), zero}

def average(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, period: U32, value: Maybe<&2, N>) -> Maybe<&2, N>:
  match value:
    case None{}:
      None{}
    case Some{sum}:
      Some{div(sum, from_u32(period))}

def update(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, total: N, price: N, removed: Maybe<&2, N>) -> N:
  match removed:
    case None{}:
      add(total, price)
    case Some{old}:
      add(sub(total, old), price)

def emit(~N: Data, +total: N, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, full):
      (Sum{window, total}, Bool.pick(Maybe<&2, N>, full, Some{total}, None{}))

def rebuild.step(~N: Data, ~add: N -> N -> N, context: Unit, total: N, value: N) -> N:
  add(total, value)

def rebuild.emit(~N: Data, result: Window.State<N> & N) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, +total): (Sum{window, total}, Some{total})

def rebuild(~N: Data, ~add: N -> N -> N, zero: N, total: N, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): emit(~N, total, Window.full(~N, window))
    case (window, True{}):
      rebuild.emit(~N, Window.fold(~N, ~Unit, ~N, ~(c => s => x => rebuild.step(~N, ~add, c, s, x)), window, Unit{}, zero))

def pushed(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N,
  total: N, +price: N, result: Window.State<N> & Maybe<&2, N>
) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, removed):
      rebuild(~N, ~add, sub(price, price), update(~N, ~add, ~sub, total, price, removed), Window.cycled(~N, window))

def push(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N,
  state: State<N>, +price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Sum{window, total}:
      pushed(~N, ~add, ~sub, total, price, Window.push(~N, window, price))
