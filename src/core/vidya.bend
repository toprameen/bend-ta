import Base
import ./window.bend as Window

type Movement<-N: Data> is Data:
  Movement{up: N, down: N}

type State<-N: Data> is Type:
  Vidya{window: Window.State<Movement<N>>, previous: Maybe<&2, N>, value: N, alpha: N, identity: Bool}

def init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, cmo: U32, depth: Nat) -> State<N>:
  +zero = from(0)
  +identity = U32.is_eq(period, 1)
  Vidya{Window.init(~Movement<N>, Bool.pick(U32, identity, 1, cmo), Bool.pick(Nat, identity, 0n, depth), Movement{zero, zero}), None{}, zero,
    div(from(2), from(U32.add(period, 1))), identity}

def movement(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~le: N -> N -> Bool, +change: N) -> Movement<N>:
  +zero = from(0)
  Movement{Bool.pick(N, le(zero, change), change, zero), Bool.pick(N, le(change, zero), sub(zero, change), zero)}

def total(~N: Data, ~add: N -> N -> N, context: Unit, acc: Movement<N>, value: Movement<N>) -> Movement<N>:
  match acc value:
    case Movement{up, down} Movement{next_up, next_down}: Movement{add(up, next_up), add(down, next_down)}

def coefficient(
  ~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool,
  alpha: N, +up: N, +down: N, flat: Bool
) -> N:
  match flat:
    case True{}: from(0)
    case False{}: mul(alpha, div(abs(sub(up, down)), add(up, down)))

def emit(
  ~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool,
  +alpha: N, +identity: Bool, +previous_value: N, +price: N, ready: Bool,
  result: Window.State<Movement<N>> & Movement<N>
) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, Movement{+up, +down}):
      +k = coefficient(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, alpha, up, down, le(add(up, down), from(0)))
      +value = add(mul(sub(price, previous_value), k), previous_value)
      (Vidya{window, Some{price}, value, alpha, identity}, Bool.pick(Maybe<&2, N>, ready, Some{value}, None{}))

def ready(
  ~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool,
  alpha: N, identity: Bool, previous_value: N, price: N, result: Window.State<Movement<N>> & Bool
) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, ready):
      +zero = from(0)
      emit(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, alpha, identity, previous_value, price, ready,
        Window.fold(~Movement<N>, ~Unit, ~Movement<N>, ~(c => s => x => total(~N, ~add, c, s, x)), window, Unit{}, Movement{zero, zero}))

def pushed(
  ~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool,
  alpha: N, identity: Bool, previous_value: N, price: N,
  result: Window.State<Movement<N>> & Maybe<&2, Movement<N>>
) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, old): ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le,
      alpha, identity, previous_value, price, Window.full(~Movement<N>, window))

def next(
  ~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N,
  ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool,
  state: State<N>, +price: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case Vidya{window, previous, value, alpha, True{}}:
      (Vidya{window, Some{price}, price, alpha, True{}}, Some{price})
    case Vidya{window, None{}, value, alpha, False{}}:
      (Vidya{window, Some{price}, price, alpha, False{}}, None{})
    case Vidya{window, Some{before}, value, alpha, False{}}:
      pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, alpha, False{}, value, price,
        Window.push(~Movement<N>, window, movement(~N, ~from, ~sub, ~le, sub(price, before))))
