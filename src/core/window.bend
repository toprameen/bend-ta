import Base

type State<-A: Data> is Type:
  Window{buffer: Array<A>, period: U32, size: U32, pos: U32}

def init(~A: Data, period: U32, depth: Nat, fill: A) -> State<A>:
  Window{Array.new(A, depth, fill), period, 0, 0}

def full(~A: Data, state: State<A>) -> State<A> & Bool:
  match state:
    case Window{buffer, +period, +size, pos}:
      (Window{buffer, period, size, pos}, U32.is_eq(size, period))

def cycled(~A: Data, state: State<A>) -> State<A> & Bool:
  match state:
    case Window{buffer, +period, +size, +pos}:
      (Window{buffer, period, size, pos}, Bool.and(U32.is_eq(size, period), U32.is_zero(pos)))

def length(~A: Data, state: State<A>) -> State<A> & U32:
  match state:
    case Window{buffer, period, +size, pos}:
      (Window{buffer, period, size, pos}, size)

def push.result(~A: Data, +period: U32, +size: U32, pos: U32, result: Array<A> & A) -> State<A> & Maybe<&2, A>:
  match result:
    case (buffer, old):
      (Window{buffer, period, U32.min(U32.add(size, 1), period), U32.mod(U32.add(pos, 1), period)},
        Bool.pick(Maybe<&2, A>, U32.is_eq(size, period), Some{old}, None{}))

def push(~A: Data, state: State<A>, value: A) -> State<A> & Maybe<&2, A>:
  match state:
    case Window{buffer, +period, size, +pos}:
      push.result(~A, period, size, pos, Array.swap(A, buffer, pos, value))

def lag.result(~A: Data, period: U32, size: U32, pos: U32, result: Array<A> & A) -> State<A> & Maybe<&2, A>:
  match result:
    case (buffer, value):
      (Window{buffer, period, size, pos}, Some{value})

def lag.check(~A: Data, +period: U32, size: U32, +pos: U32, buffer: Array<A>, age: U32, valid: Bool) -> State<A> & Maybe<&2, A>:
  match valid:
    case False{}:
      (Window{buffer, period, size, pos}, None{})
    case True{}:
      +index = U32.mod(U32.sub(U32.add(pos, period), U32.add(age, 1)), period)
      lag.result(~A, period, size, pos, Array.get(A, buffer, index))

def lag(~A: Data, state: State<A>, +age: U32) -> State<A> & Maybe<&2, A>:
  match state:
    case Window{buffer, period, +size, pos}:
      lag.check(~A, period, size, pos, buffer, age, U32.is_lt(age, size))

def fold.read(
  ~E: Data, ~A: Type, result: Array<E> & E, rest: Array<E> -> E -> State<E> & A
) -> State<E> & A:
  match result:
    case (buffer, value):
      rest(buffer, value)

def fold.check(
  ~E: Data, ~C: Data, ~A: Type, ~step: C -> A -> E -> A,
  fuel: Nat, +period: U32, +size: U32, +pos: U32, +at: U32, +context: C, buffer: Array<E>, acc: A
) -> State<E> & A:
  match fuel:
    case 0n:
      (Window{buffer, period, size, pos}, acc)
    case 1n+rest:
      +index = U32.mod(U32.add(U32.sub(U32.add(pos, period), size), at), period)
      +next = U32.add(at, 1)
      fold.read(~E, ~A, Array.get(E, buffer, index), buffer => value =>
        fold.check(~E, ~C, ~A, ~step, rest, period, size, pos, next, context, buffer, step(context, acc, value)))

def fold(
  ~E: Data, ~C: Data, ~A: Type, ~step: C -> A -> E -> A,
  state: State<E>, context: C, acc: A
) -> State<E> & A:
  match state:
    case Window{buffer, period, +size, pos}:
      fold.check(~E, ~C, ~A, ~step, U32.to_nat(size), period, size, pos, 0, context, buffer, acc)
