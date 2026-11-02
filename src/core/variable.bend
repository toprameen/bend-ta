import Base
import ./ma.bend as Ma
import ./variable_shared.bend as Shared

type Sample<-N: Data> is Data:
  Sample{price: N, period: N}

type Entry<-N: Data> is Type:
  Waiting{period: U32, delay: U32}
  Active{period: U32, average: Ma.State<N>}

type State<-N: Data> is Type:
  State{entries: List<&1, Entry<N>>, minimum: U32, maximum: U32, kind: U32}
  Buffered{state: Shared.State<N>, minimum: U32, maximum: U32}
  Direct{}

type Update<-N: Data> is Type:
  Update{entries: List<&1, Entry<N>>, price: N, selected: U32, kind: U32, output: Maybe<&2, N>}

def entries(~N: Data, fuel: Nat, +period: U32, +kind: U32, +lookback: U32, acc: List<&1, Entry<N>>) -> List<&1, Entry<N>>:
  match fuel:
    case 0n: List.reverse(&1, Entry<N>, acc)
    case 1n+rest: entries(~N, rest, U32.add(period, 1), kind, lookback, Waiting{period, U32.sub(lookback, Ma.lookback(period, kind))} <> acc)

def init.mode(~N: Data, +minimum: U32, +maximum: U32, +kind: U32, direct: Bool, shared: Bool) -> State<N>:
  match direct shared:
    case True{} _: Direct{}
    case False{} True{}: Buffered{Shared.init(~N, minimum, maximum, kind), minimum, maximum}
    case False{} False{}: State{entries(~N, U32.to_nat(U32.add(U32.sub(maximum, minimum), 1)), minimum, kind, Ma.lookback(maximum, kind), Nil{}), minimum, maximum, kind}

def init(~N: Data, +minimum: U32, +maximum: U32, +kind: U32) -> State<N>:
  init.mode(~N, minimum, maximum, kind, Bool.or(U32.is_eq(maximum, 1), U32.is_eq(kind, 10)), Shared.supported(minimum, maximum, kind))

def normalize.upper(~N: Data, ~to: N -> U32, minimum: U32, maximum: U32, value: N, above: Bool) -> U32:
  match above:
    case True{}: maximum
    case False{}: to(value)

def normalize.lower(~N: Data, ~from: U32 -> N, ~to: N -> U32, ~gt: N -> N -> Bool, +minimum: U32, +maximum: U32, +value: N, bounded: Bool) -> U32:
  match bounded:
    case False{}: minimum
    case True{}: normalize.upper(~N, ~to, minimum, maximum, value, gt(value, from(maximum)))

def normalize(~N: Data, ~from: U32 -> N, ~to: N -> U32, ~ge: N -> N -> Bool, ~gt: N -> N -> Bool, +minimum: U32, maximum: U32, +value: N) -> U32:
  normalize.lower(~N, ~from, ~to, ~gt, minimum, maximum, value, ge(value, from(minimum)))

def updated(~N: Data, entries: List<&1, Entry<N>>, price: N, +selected: U32, kind: U32, output: Maybe<&2, N>, +period: U32, result: Ma.State<N> & Maybe<&2, N>) -> Update<N>:
  match result:
    case (average, value): Update{Active{period, average} <> entries, price, selected, kind, Bool.pick(Maybe<&2, N>, U32.is_eq(selected, period), value, output)}

def waiting(~N: Data, ~make: U32 -> U32 -> Ma.State<N>, ~step: Ma.State<N> -> N -> Ma.State<N> & Maybe<&2, N>, entries: List<&1, Entry<N>>, +price: N, selected: U32, +kind: U32, output: Maybe<&2, N>, +period: U32, delay: Nat) -> Update<N>:
  match delay:
    case 0n: updated(~N, entries, price, selected, kind, output, period, step(make(period, kind), price))
    case 1n+rest: Update{Waiting{period, U32.from_nat(rest)} <> entries, price, selected, kind, output}

def update(~N: Data, ~make: U32 -> U32 -> Ma.State<N>, ~step: Ma.State<N> -> N -> Ma.State<N> & Maybe<&2, N>, state: Update<N>, entry: Entry<N>) -> Update<N>:
  match state entry:
    case Update{entries, price, selected, kind, output} Waiting{period, delay}: waiting(~N, ~make, ~step, entries, price, selected, kind, output, period, U32.to_nat(delay))
    case Update{entries, +price, selected, kind, output} Active{period, average}: updated(~N, entries, price, selected, kind, output, period, step(average, price))

def finish(~N: Data, minimum: U32, maximum: U32, result: Update<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case Update{entries, price, selected, kind, output}: (State{List.reverse(&1, Entry<N>, entries), minimum, maximum, kind}, output)

def next.shared(~N: Data, minimum: U32, maximum: U32, result: Shared.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, value): (Buffered{state, minimum, maximum}, value)

def next(~N: Data, ~from: U32 -> N, ~to: N -> U32, ~ge: N -> N -> Bool, ~gt: N -> N -> Bool, ~make: U32 -> U32 -> Ma.State<N>, ~step: Ma.State<N> -> N -> Ma.State<N> & Maybe<&2, N>, ~shared: Shared.State<N> -> N -> U32 -> Shared.State<N> & Maybe<&2, N>, state: State<N>, sample: Sample<N>) -> State<N> & Maybe<&2, N>:
  match state sample:
    case State{entries, +minimum, +maximum, kind} Sample{price, period}: finish(~N, minimum, maximum, List.foldl(~&1, ~Entry<N>, ~Update<N>, ~(s => e => update(~N, ~make, ~step, s, e)), entries, Update{Nil{}, price, normalize(~N, ~from, ~to, ~ge, ~gt, minimum, maximum, period), kind, None{}}))
    case Buffered{state, +minimum, +maximum} Sample{price, period}: next.shared(~N, minimum, maximum, shared(state, price, normalize(~N, ~from, ~to, ~ge, ~gt, minimum, maximum, period)))
    case Direct{} Sample{price, period}: (Direct{}, Some{price})
