import Base

type Entry<-N: Data> is Data:
  Entry{value: N, slot: U32}

type Queue<-N: Data> is Type:
  Queue{buffer: Array<Entry<N>>, head: U32, size: U32}

type State<-N: Data> is Type:
  State{period: U32, size: U32, position: U32, low: Queue<N>, high: Queue<N>}

type Value<-N: Data> is Data:
  Value{low: N, high: N, low_age: U32, high_age: U32, size: U32}

def init(~N: Data, ~from: U32 -> N, +period: U32, +depth: Nat) -> State<N>:
  +fill : Entry<N> = Entry{from(0), 0}
  State{period, 0, 0, Queue{Array.new(Entry<N>, depth, fill), 0, 0}, Queue{Array.new(Entry<N>, depth, fill), 0, 0}}

def inserted(~N: Data, head: U32, size: U32, result: Array<Entry<N>> & Entry<N>) -> Queue<N>:
  match result:
    case (buffer, old): Queue{buffer, head, U32.add(size, 1)}

def insert(~N: Data, +period: U32, +head: U32, +size: U32, slot: U32, value: N, buffer: Array<Entry<N>>) -> Queue<N>:
  inserted(~N, head, size, Array.swap(Entry<N>, buffer, U32.mod(U32.add(head, size), period), Entry{value, slot}))

def prune.chosen(~N: Data, period: U32, head: U32, size: U32, slot: U32, value: N, buffer: Array<Entry<N>>, rest: Array<Entry<N>> -> Queue<N>, remove: Bool) -> Queue<N>:
  match remove:
    case True{}: rest(buffer)
    case False{}: insert(~N, period, head, size, slot, value, buffer)

def prune.read(~N: Data, ~wins: N -> N -> Bool, period: U32, head: U32, size: U32, slot: U32, +value: N, result: Array<Entry<N>> & Entry<N>, rest: Array<Entry<N>> -> Queue<N>) -> Queue<N>:
  match result:
    case (buffer, Entry{before, old_slot}): prune.chosen(~N, period, head, size, slot, value, buffer, rest, wins(value, before))

def prune(~N: Data, ~wins: N -> N -> Bool, fuel: Nat, +period: U32, +head: U32, +size: U32, +slot: U32, +value: N, buffer: Array<Entry<N>>) -> Queue<N>:
  match fuel:
    case 0n: insert(~N, period, head, size, slot, value, buffer)
    case 1n+rest: prune.read(~N, ~wins, period, head, size, slot, value, Array.get(Entry<N>, buffer, U32.mod(U32.sub(U32.add(head, size), 1), period)), b => prune(~N, ~wins, rest, period, head, U32.sub(size, 1), slot, value, b))

def expire.read(~N: Data, ~wins: N -> N -> Bool, +period: U32, +head: U32, +size: U32, +slot: U32, value: N, result: Array<Entry<N>> & Entry<N>) -> Queue<N>:
  match result:
    case (buffer, Entry{old, before}):
      +removed = Bool.pick(U32, Bool.and(U32.is_gt(size, 0), U32.is_eq(slot, before)), 1, 0)
      +remaining = U32.sub(size, removed)
      prune(~N, ~wins, U32.to_nat(remaining), period, U32.mod(U32.add(head, removed), period), remaining, slot, value, buffer)

def push(~N: Data, ~wins: N -> N -> Bool, period: U32, slot: U32, value: N, queue: Queue<N>) -> Queue<N>:
  match queue:
    case Queue{buffer, +head, size}: expire.read(~N, ~wins, period, head, size, slot, value, Array.get(Entry<N>, buffer, head))

def front.read(~N: Data, head: U32, size: U32, result: Array<Entry<N>> & Entry<N>) -> Queue<N> & Entry<N>:
  match result:
    case (buffer, entry): (Queue{buffer, head, size}, entry)

def front(~N: Data, queue: Queue<N>) -> Queue<N> & Entry<N>:
  match queue:
    case Queue{buffer, +head, size}: front.read(~N, head, size, Array.get(Entry<N>, buffer, head))

def age(+period: U32, position: U32, slot: U32) -> U32:
  U32.mod(U32.sub(U32.add(position, U32.sub(period, 1)), slot), period)

def output.high(~N: Data, +period: U32, +size: U32, +position: U32, low: Queue<N>, l: Entry<N>, result: Queue<N> & Entry<N>) -> State<N> & Maybe<&2, Value<N>>:
  match l result:
    case Entry{lo, low_slot} Tuple{high, Entry{hi, high_slot}}:
      (State{period, size, position, low, high}, Some{Value{lo, hi, age(period, position, low_slot), age(period, position, high_slot), size}})

def output.low(~N: Data, period: U32, size: U32, position: U32, high: Queue<N>, result: Queue<N> & Entry<N>) -> State<N> & Maybe<&2, Value<N>>:
  match result:
    case (low, entry): output.high(~N, period, size, position, low, entry, front(~N, high))

def ready(~N: Data, state: State<N>, full: Bool) -> State<N> & Maybe<&2, Value<N>>:
  match state full:
    case state False{}: (state, None{})
    case State{period, size, position, low, high} True{}: output.low(~N, period, size, position, high, front(~N, low))

def next(~N: Data, ~lower: N -> N -> Bool, ~higher: N -> N -> Bool, state: State<N>, low: N, high: N) -> State<N> & Maybe<&2, Value<N>>:
  match state:
    case State{+period, +size, +position, lows, highs}:
      +count = U32.min(U32.add(size, 1), period)
      ready(~N, State{period, count, U32.mod(U32.add(position, 1), period), push(~N, ~lower, period, position, low, lows), push(~N, ~higher, period, position, high, highs)}, U32.is_eq(count, period))
