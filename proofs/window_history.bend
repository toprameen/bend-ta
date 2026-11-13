import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat
import bend-mathlib@0.8.1.0/u32.bend as MU32
import ../src/core/window.bend as Window
import ./window_storage.bend as Storage
import ./window_geometry.bend as Geometry
import ./window_indices.bend as Indices

type Model<-A: Data> is Data:
  Model{buffer: Storage.Tree<A>, period: U32, size: U32, pos: U32}

def model_period(~A: Data, m: Model<A>) -> U32:
  match m:
    case Model{buffer, period, size, pos}:
      period

def state(~A: Data, m: Model<A>) -> Window.State<A>:
  match m:
    case Model{buffer, period, size, pos}:
      Window.Window{Storage.array(~A, buffer), period, size, pos}

def filled(~A: Data, d: Nat, +fill: A) -> Storage.Tree<A>:
  match d:
    case 0n:
      Storage.Leaf{fill}
    case 1n+p:
      +rest = filled(~A, p, fill)
      Storage.Node{rest, rest}

def initialized(~A: Data, period: U32, d: Nat, fill: A) -> Model<A>:
  Model{filled(~A, d, fill), period, 0, 0}

def push(~A: Data, m: Model<A>, +value: A) -> Model<A>:
  match m:
    case Model{buffer, +period, size, +pos}:
      Model{Storage.put(~A, buffer, pos, value), period, U32.min(U32.add(size, 1), period), U32.mod(U32.add(pos, 1), period)}

def eviction(~A: Data, m: Model<A>) -> Maybe<&2, A>:
  match m:
    case Model{+buffer, period, size, pos}:
      Bool.pick(Maybe<&2, A>, U32.is_eq(size, period), Some{Storage.cell(~A, buffer, pos)}, None{})

def index(+period: U32, pos: U32, age: U32) -> U32:
  U32.mod(U32.sub(U32.add(pos, period), U32.add(age, 1)), period)

def observed(~A: Data, m: Model<A>, +age: U32) -> Maybe<&2, A>:
  match m:
    case Model{+buffer, +period, +size, +pos}:
      Bool.pick(Maybe<&2, A>, U32.is_lt(age, size), Some{Storage.cell(~A, buffer, index(period, pos, age))}, None{})

def lookup(~A: Data, history: List<&2, A>, +age: U32) -> Maybe<&2, A>:
  match history:
    case Nil{}:
      None{}
    case value <> older:
      Bool.pick(Maybe<&2, A>, U32.is_zero(age), Some{value}, lookup(~A, older, U32.sub(age, 1)))

law filled_array:
  for ~A: Data
  for +d: Nat
  for +fill: A
  {Storage.array(~A, filled(~A, d, fill)) == Array.new(A, d, fill) : Array<A>}

def filled_array(A, d, fill):
  match d:
    case 0n:
      {==}
    case 1n+p:
      %filled_array(~A, p, fill) : {ANode{Storage.array(~A, filled(~A, p, fill)), Storage.array(~A, filled(~A, p, fill))} == ANode{_, _} : Array<A>}
      {==}

law init_state:
  for ~A: Data
  for +period: U32
  for d: Nat
  for fill: A
  {state(~A, initialized(~A, period, d, fill)) == Window.init(~A, period, d, fill) : Window.State<A>}

def init_state(A, period, d, fill):
  %filled_array(~A, d, fill) : {Window.Window{Storage.array(~A, filled(~A, d, fill)), period, 0, 0} == Window.Window{_, period, 0, 0} : Window.State<A>}
  {==}

law push_state:
  for ~A: Data
  for +m: Model<A>
  for +value: A
  {(state(~A, push(~A, m, value)), eviction(~A, m)) == Window.push(~A, state(~A, m), value) : Window.State<A> & Maybe<&2, A>}

def push_state(A, m, value):
  match m:
    case Model{+buffer, +period, +size, +pos}:
      %Storage.swap_contents(~A, buffer, pos, value) : {(state(~A, push(~A, Model{buffer, period, size, pos}, value)), eviction(~A, Model{buffer, period, size, pos})) == Window.push.result(~A, period, size, pos, _) : Window.State<A> & Maybe<&2, A>}
      {==}

law lag_state_check:
  for ~A: Data
  for +buffer: Storage.Tree<A>
  for +period: U32
  for +size: U32
  for +pos: U32
  for +age: U32
  for valid: Bool
  {(state(~A, Model{buffer, period, size, pos}), Bool.pick(Maybe<&2, A>, valid, Some{Storage.cell(~A, buffer, index(period, pos, age))}, None{})) == Window.lag.check(~A, period, size, pos, Storage.array(~A, buffer), age, valid) : Window.State<A> & Maybe<&2, A>}

def lag_state_check(A, buffer, period, size, pos, age, valid):
  match valid:
    case False{}:
      {==}
    case True{}:
      %Storage.get_contents(~A, buffer, index(period, pos, age)) : {(state(~A, Model{buffer, period, size, pos}), Some{Storage.cell(~A, buffer, index(period, pos, age))}) == Window.lag.result(~A, period, size, pos, _) : Window.State<A> & Maybe<&2, A>}
      {==}

law lag_state:
  for ~A: Data
  for +m: Model<A>
  for +age: U32
  {(state(~A, m), observed(~A, m, age)) == Window.lag(~A, state(~A, m), age) : Window.State<A> & Maybe<&2, A>}

def lag_state(A, m, age):
  match m:
    case Model{buffer, period, size, pos}:
      lag_state_check(~A, buffer, period, size, pos, age, U32.is_lt(age, size))

law filled_balanced:
  for ~A: Data
  for +d: Nat
  for +fill: A
  {Geometry.balanced(~A, d, filled(~A, d, fill)) == True{} : Bool}

def filled_balanced(A, d, fill):
  match d:
    case 0n:
      {==}
    case 1n+p:
      %Equal.sym(Bool, Geometry.balanced(~A, p, filled(~A, p, fill)), True{}, filled_balanced(~A, p, fill)) : {Bool.and(_, _) == True{} : Bool}
      {==}

def initialized_history(~A: Data, +period: U32, +d: Nat, +fill: A, history: List<&2, A>) -> Model<A>:
  match history:
    case Nil{}:
      initialized(~A, period, d, fill)
    case value <> older:
      push(~A, initialized_history(~A, period, d, fill, older), value)

def first(~A: Type, ~B: Type, result: A & B) -> A:
  (a, b) = result
  a

def replay(~A: Data, +period: U32, +d: Nat, +fill: A, history: List<&2, A>) -> Window.State<A>:
  match history:
    case Nil{}:
      Window.init(~A, period, d, fill)
    case value <> older:
      first(~Window.State<A>, ~Maybe<&2, A>, Window.push(~A, replay(~A, period, d, fill, older), value))

law replay_state:
  for ~A: Data
  for +period: U32
  for +d: Nat
  for +fill: A
  for +history: List<&2, A>
  {state(~A, initialized_history(~A, period, d, fill, history)) == replay(~A, period, d, fill, history) : Window.State<A>}

def replay_state(A, period, d, fill, history):
  match history:
    case Nil{}:
      init_state(~A, period, d, fill)
    case +value <> +older:
      %replay_state(~A, period, d, fill, older) : {state(~A, push(~A, initialized_history(~A, period, d, fill, older), value)) == first(~Window.State<A>, ~Maybe<&2, A>, Window.push(~A, _, value)) : Window.State<A>}
      %push_state(~A, initialized_history(~A, period, d, fill, older), value) : {state(~A, push(~A, initialized_history(~A, period, d, fill, older), value)) == first(~Window.State<A>, ~Maybe<&2, A>, _) : Window.State<A>}
      {==}

type Configuration<-period: U32, -d: Nat> is Type:
  Valid{
    positive: MNat.lt(0n, U32.to_nat(period)),
    bounded: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n)),
    depth: MNat.lt(d, 32n),
    capacity: MNat.le(U32.to_nat(period), Nat.pow(2n, d))}

def Invariant(~A: Data, +d: Nat, m: Model<A>, +history: List<&2, A>) -> Type:
  match m:
    case Model{buffer, +period, +size, pos}:
      Configuration<period, d> &
      {Geometry.balanced(~A, d, buffer) == True{} : Bool} &
      MNat.le(U32.to_nat(size), U32.to_nat(period)) &
      MNat.lt(U32.to_nat(pos), U32.to_nat(period)) &
      {U32.to_nat(size) == Nat.min(List.length(&2, A, history), U32.to_nat(period)) : Nat} &
      (@+age: U32 -> @ha: {U32.is_lt(age, size) == True{} : Bool} ->
        {Some{Storage.cell(~A, buffer, index(period, pos, age))} == lookup(~A, history, age) : Maybe<&2, A>})

law initialized_invariant:
  for ~A: Data
  for +period: U32
  for +d: Nat
  for +fill: A
  for config: Configuration<period, d>
  Invariant(~A, d, initialized(~A, period, d, fill), Nil{})

def initialized_invariant(A, period, d, fill, config):
  match config:
    case Valid{+hp, hmax, hd, hc}:
      (Valid{hp, hmax, hd, hc}, filled_balanced(~A, d, fill), MNat.zero_le(U32.to_nat(period)), hp, {==},
        age => ha => Empty.absurd({Some{Storage.cell(~A, filled(~A, d, fill), index(period, 0, age))} == None{} : Maybe<&2, A>}, MNat.lt_zero(U32.to_nat(age))(Geometry.u32_lt_nat(age, 0, ha))))

law min_increment:
  for +n: Nat
  for +p: Nat
  {Nat.min(1n+Nat.min(n, p), p) == Nat.min(1n+n, p) : Nat}

def min_increment(n, p):
  match n p:
    case _ 0n:
      {==}
    case 0n 1n+q:
      {==}
    case 1n++r 1n++q:
      %min_increment(r, q) : {1n+Nat.min(1n+Nat.min(r, q), q) == 1n+_ : Nat}
      {==}

law positive_predecessor:
  for +n: Nat
  for h: MNat.lt(0n, n)
  {n == 1n+Nat.sub(n, 1n) : Nat}

def positive_predecessor(n, h):
  match n:
    case 0n:
      Empty.absurd({0n == 1n+Nat.sub(0n, 1n) : Nat}, MNat.lt_zero(0n)(h))
    case 1n+p:
      %MNat.sub_zero_sym(p) : {1n+p == 1n+_ : Nat}
      {==}

def zero_equal(+age: U32, h: {U32.is_zero(age) == True{} : Bool}) -> {age == 0 : U32}:
  MU32.u32_to_nat_inj(age, 0, MNat.eq_of_is_eq(U32.to_nat(age), 0n,
    Equal.trans(Bool, Nat.is_eq(U32.to_nat(age), 0n), U32.is_zero(age), True{}, MU32.u32_is_eq_to_nat_sym(age, 0), h)))

def next_size_bound(+period: U32, +size: U32, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}, hs: MNat.le(U32.to_nat(size), U32.to_nat(period)), hmax: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))) -> MNat.le(U32.to_nat(U32.min(U32.add(size, 1), period)), U32.to_nat(period)):
  %Equal.sym(Nat, U32.to_nat(U32.min(U32.add(size, 1), period)), Nat.min(1n+U32.to_nat(size), U32.to_nat(period)), Indices.nextsize_to_nat(period, size, q, ep, hs, hmax)) : MNat.le(_, U32.to_nat(period))
  MNat.min_le_right(1n+U32.to_nat(size), U32.to_nat(period))

def next_available_period(+period: U32, +size: U32, +age: U32, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}, hs: MNat.le(U32.to_nat(size), U32.to_nat(period)), hmax: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n)), ha: {U32.is_lt(age, U32.min(U32.add(size, 1), period)) == True{} : Bool}) -> MNat.lt(U32.to_nat(age), U32.to_nat(period)):
  MNat.lt_of_lt_of_le(U32.to_nat(age), U32.to_nat(U32.min(U32.add(size, 1), period)), U32.to_nat(period), Geometry.u32_lt_nat(age, U32.min(U32.add(size, 1), period), ha), next_size_bound(period, size, q, ep, hs, hmax))

def previous_lt_q(+period: U32, +age: U32, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}, hz: {U32.is_zero(age) == False{} : Bool}, ha: MNat.lt(U32.to_nat(age), U32.to_nat(period))) -> MNat.lt(U32.to_nat(U32.sub(age, 1)), q):
  %Indices.predecessor_nat(age, hz) : MNat.lt(_, 1n+q)
  %ep : MNat.lt(U32.to_nat(age), _)
  ha

def physical_bound(~A: Data, +d: Nat, +buffer: Storage.Tree<A>, +period: U32, +i: U32, hd: MNat.lt(d, 32n), shape: {Geometry.balanced(~A, d, buffer) == True{} : Bool}, hc: MNat.le(U32.to_nat(period), Nat.pow(2n, d)), hi: MNat.lt(U32.to_nat(i), U32.to_nat(period))) -> MNat.lt(U32.to_nat(i), U32.to_nat(Storage.capacity(~A, buffer))):
  %Equal.sym(Nat, U32.to_nat(Storage.capacity(~A, buffer)), Nat.pow(2n, d), Geometry.capacity_value(~A, d, buffer, hd, shape)) : MNat.lt(U32.to_nat(i), _)
  MNat.lt_of_lt_of_le(U32.to_nat(i), U32.to_nat(period), Nat.pow(2n, d), hi, hc)

law push_cells_check:
  for ~A: Data
  for +d: Nat
  for +buffer: Storage.Tree<A>
  for +period: U32
  for +size: U32
  for +pos: U32
  for +value: A
  for +history: List<&2, A>
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for +hmax: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  for +hd: MNat.lt(d, 32n)
  for +hc: MNat.le(U32.to_nat(period), Nat.pow(2n, d))
  for +shape: {Geometry.balanced(~A, d, buffer) == True{} : Bool}
  for +hs: MNat.le(U32.to_nat(size), U32.to_nat(period))
  for +hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for cells: @+a: U32 -> @available: {U32.is_lt(a, size) == True{} : Bool} -> {Some{Storage.cell(~A, buffer, index(period, pos, a))} == lookup(~A, history, a) : Maybe<&2, A>}
  for +age: U32
  for zero: Bool
  for +ez: {U32.is_zero(age) == zero : Bool}
  for +ha: {U32.is_lt(age, U32.min(U32.add(size, 1), period)) == True{} : Bool}
  {Some{Storage.cell(~A, Storage.put(~A, buffer, pos, value), index(period, Indices.next(period, pos), age))} == lookup(~A, value <> history, age) : Maybe<&2, A>}

def push_cells_check(A, d, buffer, period, size, pos, value, history, q, ep, hmax, hd, hc, shape, hs, hp, cells, age, zero, ez, ha):
  match zero:
    case True{}:
      %Equal.sym(U32, age, 0, zero_equal(age, ez)) : {Some{Storage.cell(~A, Storage.put(~A, buffer, pos, value), index(period, Indices.next(period, pos), _))} == lookup(~A, value <> history, _) : Maybe<&2, A>}
      %Equal.sym(U32, index(period, Indices.next(period, pos), 0), pos, Indices.index_newest(period, pos, q, ep, hp, hmax)) : {Some{Storage.cell(~A, Storage.put(~A, buffer, pos, value), _)} == Some{value} : Maybe<&2, A>}
      Equal.cong(A, Maybe<&2, A>, x => Some{x}, Storage.cell(~A, Storage.put(~A, buffer, pos, value), pos), value, Storage.cell_put(~A, buffer, pos, value))
    case False{}:
      +prior = U32.sub(age, 1)
      +hage = next_available_period(period, size, age, q, ep, hs, hmax, ha)
      +hprior = previous_lt_q(period, age, q, ep, ez, hage)
      +esucc = Indices.predecessor_successor(period, age, q, ep, MNat.le_of_lt(U32.to_nat(age), U32.to_nat(period), hage), hmax, ez)
      +eshift = Equal.trans(U32, index(period, Indices.next(period, pos), age), index(period, Indices.next(period, pos), U32.add(prior, 1)), index(period, pos, prior),
        Equal.cong(U32, U32, x => index(period, Indices.next(period, pos), x), age, U32.add(prior, 1), Equal.sym(U32, U32.add(prior, 1), age, esucc)), Indices.index_shift(period, pos, prior, q, ep, hp, hprior, hmax))
      %Equal.sym(Bool, U32.is_zero(age), False{}, ez) : {Some{Storage.cell(~A, Storage.put(~A, buffer, pos, value), index(period, Indices.next(period, pos), age))} == Bool.pick(Maybe<&2, A>, _, Some{value}, lookup(~A, history, prior)) : Maybe<&2, A>}
      %Equal.sym(U32, index(period, Indices.next(period, pos), age), index(period, pos, prior), eshift) : {Some{Storage.cell(~A, Storage.put(~A, buffer, pos, value), _)} == lookup(~A, history, prior) : Maybe<&2, A>}
      %Equal.sym(A, Storage.cell(~A, Storage.put(~A, buffer, pos, value), index(period, pos, prior)), Storage.cell(~A, buffer, index(period, pos, prior)),
        Geometry.cell_put_frame(~A, d, buffer, pos, index(period, pos, prior), value, hd, shape,
          physical_bound(~A, d, buffer, period, pos, hd, shape, hc, hp), physical_bound(~A, d, buffer, period, index(period, pos, prior), hd, shape, hc, Indices.index_lt(period, pos, prior, q, ep)),
          e => Indices.index_ne_write(period, pos, prior, q, ep, hp, hprior, hmax, Equal.sym(U32, pos, index(period, pos, prior), e)))) : {Some{_} == lookup(~A, history, prior) : Maybe<&2, A>}
      cells(prior, Indices.predecessor_available(period, size, age, q, ep, hs, hmax, ez, ha))

def next_size_length(+period: U32, +size: U32, +length: Nat, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}, hs: MNat.le(U32.to_nat(size), U32.to_nat(period)), hmax: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n)), e: {U32.to_nat(size) == Nat.min(length, U32.to_nat(period)) : Nat}) -> {U32.to_nat(U32.min(U32.add(size, 1), period)) == Nat.min(1n+length, U32.to_nat(period)) : Nat}:
  %Equal.sym(Nat, U32.to_nat(U32.min(U32.add(size, 1), period)), Nat.min(1n+U32.to_nat(size), U32.to_nat(period)), Indices.nextsize_to_nat(period, size, q, ep, hs, hmax)) : {_ == Nat.min(1n+length, U32.to_nat(period)) : Nat}
  %Equal.sym(Nat, U32.to_nat(size), Nat.min(length, U32.to_nat(period)), e) : {Nat.min(1n+_, U32.to_nat(period)) == Nat.min(1n+length, U32.to_nat(period)) : Nat}
  min_increment(length, U32.to_nat(period))

law push_invariant_fields:
  for ~A: Data
  for +d: Nat
  for +buffer: Storage.Tree<A>
  for +period: U32
  for +size: U32
  for +pos: U32
  for +value: A
  for +history: List<&2, A>
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for +positive: MNat.lt(0n, U32.to_nat(period))
  for +hmax: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  for +hd: MNat.lt(d, 32n)
  for +hc: MNat.le(U32.to_nat(period), Nat.pow(2n, d))
  for +shape: {Geometry.balanced(~A, d, buffer) == True{} : Bool}
  for +hs: MNat.le(U32.to_nat(size), U32.to_nat(period))
  for +hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for length: {U32.to_nat(size) == Nat.min(List.length(&2, A, history), U32.to_nat(period)) : Nat}
  for cells: @+a: U32 -> @available: {U32.is_lt(a, size) == True{} : Bool} -> {Some{Storage.cell(~A, buffer, index(period, pos, a))} == lookup(~A, history, a) : Maybe<&2, A>}
  Invariant(~A, d, push(~A, Model{buffer, period, size, pos}, value), value <> history)

def push_invariant_fields(A, d, buffer, period, size, pos, value, history, q, ep, positive, hmax, hd, hc, shape, hs, hp, length, cells):
  (Valid{positive, hmax, hd, hc},
    Equal.trans(Bool, Geometry.balanced(~A, d, Storage.put(~A, buffer, pos, value)), Geometry.balanced(~A, d, buffer), True{}, Geometry.put_balanced(~A, d, buffer, pos, value), shape),
    next_size_bound(period, size, q, ep, hs, hmax), Indices.next_lt(period, pos, q, ep),
    next_size_length(period, size, List.length(&2, A, history), q, ep, hs, hmax, length),
    age => ha => push_cells_check(~A, d, buffer, period, size, pos, value, history, q, ep, hmax, hd, hc, shape, hs, hp, cells, age, U32.is_zero(age), {==}, ha))

law push_invariant_config:
  for ~A: Data
  for +d: Nat
  for +buffer: Storage.Tree<A>
  for +period: U32
  for +size: U32
  for +pos: U32
  for +value: A
  for +history: List<&2, A>
  for config: Configuration<period, d>
  for shape: {Geometry.balanced(~A, d, buffer) == True{} : Bool}
  for hs: MNat.le(U32.to_nat(size), U32.to_nat(period))
  for hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for length: {U32.to_nat(size) == Nat.min(List.length(&2, A, history), U32.to_nat(period)) : Nat}
  for cells: @+a: U32 -> @available: {U32.is_lt(a, size) == True{} : Bool} -> {Some{Storage.cell(~A, buffer, index(period, pos, a))} == lookup(~A, history, a) : Maybe<&2, A>}
  Invariant(~A, d, push(~A, Model{buffer, period, size, pos}, value), value <> history)

def push_invariant_config(A, d, buffer, period, size, pos, value, history, config, shape, hs, hp, length, cells):
  match config:
    case Valid{+positive, hmax, hd, hc}:
      push_invariant_fields(~A, d, buffer, period, size, pos, value, history, Nat.sub(U32.to_nat(period), 1n), positive_predecessor(U32.to_nat(period), positive), positive, hmax, hd, hc, shape, hs, hp, length, cells)

law push_invariant:
  for ~A: Data
  for +d: Nat
  for +m: Model<A>
  for +value: A
  for +history: List<&2, A>
  for invariant: Invariant(~A, d, m, history)
  Invariant(~A, d, push(~A, m, value), value <> history)

def push_invariant(A, d, m, value, history, invariant):
  match m:
    case Model{+buffer, +period, +size, +pos}:
      match invariant:
        case (config, shape, hs, hp, length, cells):
          push_invariant_config(~A, d, buffer, period, size, pos, value, history, config, shape, hs, hp, length, cells)

law history_invariant:
  for ~A: Data
  for +period: U32
  for +d: Nat
  for +fill: A
  for +history: List<&2, A>
  for config: Configuration<period, d>
  Invariant(~A, d, initialized_history(~A, period, d, fill, history), history)

def history_invariant(A, period, d, fill, history, config):
  match history:
    case Nil{}:
      initialized_invariant(~A, period, d, fill, config)
    case +value <> +older:
      push_invariant(~A, d, initialized_history(~A, period, d, fill, older), value, older, history_invariant(~A, period, d, fill, older, config))

def visible(~A: Data, period: U32, +history: List<&2, A>, +age: U32) -> Maybe<&2, A>:
  Bool.pick(Maybe<&2, A>, Nat.is_lt(U32.to_nat(age), Nat.min(List.length(&2, A, history), U32.to_nat(period))), lookup(~A, history, age), None{})

def observation_check(~A: Data, flag: Bool, +value: Maybe<&2, A>, +wanted: Maybe<&2, A>, proof: {flag == True{} : Bool} -> {value == wanted : Maybe<&2, A>}) -> {Bool.pick(Maybe<&2, A>, flag, value, None{}) == Bool.pick(Maybe<&2, A>, flag, wanted, None{}) : Maybe<&2, A>}:
  match flag:
    case False{}:
      {==}
    case True{}:
      proof({==})

law observed_visible:
  for ~A: Data
  for +d: Nat
  for +m: Model<A>
  for +history: List<&2, A>
  for +age: U32
  for invariant: Invariant(~A, d, m, history)
  {observed(~A, m, age) == visible(~A, model_period(~A, m), history, age) : Maybe<&2, A>}

def observed_visible(A, d, m, history, age, invariant):
  match m:
    case Model{+buffer, +period, +size, +pos}:
      match invariant:
        case (config, shape, hs, hp, length, cells):
          %length : {observed(~A, Model{buffer, period, size, pos}, age) == Bool.pick(Maybe<&2, A>, Nat.is_lt(U32.to_nat(age), _), lookup(~A, history, age), None{}) : Maybe<&2, A>}
          %MU32.u32_is_lt_to_nat(age, size) : {observed(~A, Model{buffer, period, size, pos}, age) == Bool.pick(Maybe<&2, A>, _, lookup(~A, history, age), None{}) : Maybe<&2, A>}
          observation_check(~A, U32.is_lt(age, size), Some{Storage.cell(~A, buffer, index(period, pos, age))}, lookup(~A, history, age), cells(age))

law push_period:
  for ~A: Data
  for +m: Model<A>
  for value: A
  {model_period(~A, push(~A, m, value)) == model_period(~A, m) : U32}

def push_period(A, m, value):
  match m:
    case Model{buffer, period, size, pos}:
      {==}

law history_period:
  for ~A: Data
  for +period: U32
  for +d: Nat
  for +fill: A
  for +history: List<&2, A>
  {model_period(~A, initialized_history(~A, period, d, fill, history)) == period : U32}

def history_period(A, period, d, fill, history):
  match history:
    case Nil{}:
      {==}
    case +value <> +older:
      %Equal.sym(U32, model_period(~A, push(~A, initialized_history(~A, period, d, fill, older), value)), model_period(~A, initialized_history(~A, period, d, fill, older)), push_period(~A, initialized_history(~A, period, d, fill, older), value)) : {_ == period : U32}
      history_period(~A, period, d, fill, older)

law lag_history:
  for ~A: Data
  for +period: U32
  for +d: Nat
  for +fill: A
  for +history: List<&2, A>
  for +age: U32
  for config: Configuration<period, d>
  {Window.lag(~A, replay(~A, period, d, fill, history), age) == (replay(~A, period, d, fill, history), visible(~A, period, history, age)) : Window.State<A> & Maybe<&2, A>}

def lag_history(A, period, d, fill, history, age, config):
  +m = initialized_history(~A, period, d, fill, history)
  %history_period(~A, period, d, fill, history) : {Window.lag(~A, replay(~A, period, d, fill, history), age) == (replay(~A, period, d, fill, history), visible(~A, _, history, age)) : Window.State<A> & Maybe<&2, A>}
  %replay_state(~A, period, d, fill, history) : {Window.lag(~A, _, age) == (_, visible(~A, model_period(~A, m), history, age)) : Window.State<A> & Maybe<&2, A>}
  %lag_state(~A, m, age) : {_ == (state(~A, m), visible(~A, model_period(~A, m), history, age)) : Window.State<A> & Maybe<&2, A>}
  Equal.cong(Maybe<&2, A>, Window.State<A> & Maybe<&2, A>, x => (state(~A, m), x), observed(~A, m, age), visible(~A, model_period(~A, m), history, age), observed_visible(~A, d, m, history, age, history_invariant(~A, period, d, fill, history, config)))

law min_full:
  for n: Nat
  for p: Nat
  {Nat.is_eq(Nat.min(n, p), p) == Nat.is_le(p, n) : Bool}

def min_full(n, p):
  match n p:
    case 0n 0n:
      {==}
    case 0n 1n+q:
      {==}
    case 1n+r 0n:
      {==}
    case 1n+r 1n+q:
      min_full(r, q)

def expelled(~A: Data, +period: U32, +history: List<&2, A>) -> Maybe<&2, A>:
  Bool.pick(Maybe<&2, A>, Nat.is_le(U32.to_nat(period), List.length(&2, A, history)), lookup(~A, history, U32.sub(period, 1)), None{})

def equal_u32(+a: U32, +b: U32, h: {U32.is_eq(a, b) == True{} : Bool}) -> {a == b : U32}:
  MU32.u32_to_nat_inj(a, b, MNat.eq_of_is_eq(U32.to_nat(a), U32.to_nat(b), Equal.trans(Bool, Nat.is_eq(U32.to_nat(a), U32.to_nat(b)), U32.is_eq(a, b), True{}, MU32.u32_is_eq_to_nat_sym(a, b), h)))

def oldest_available(+period: U32, +size: U32, +q: Nat, +ep: {U32.to_nat(period) == 1n+q : Nat}, full: {U32.is_eq(size, period) == True{} : Bool}) -> {U32.is_lt(U32.sub(period, 1), size) == True{} : Bool}:
  %Equal.sym(U32, size, period, equal_u32(size, period, full)) : {U32.is_lt(U32.sub(period, 1), _) == True{} : Bool}
  %MU32.u32_is_lt_to_nat_sym(U32.sub(period, 1), period) : {_ == True{} : Bool}
  %Equal.sym(Nat, U32.to_nat(U32.sub(period, 1)), q, Indices.predecessor_exact(period, q, ep)) : MNat.lt(_, U32.to_nat(period))
  %Equal.sym(Nat, U32.to_nat(period), 1n+q, ep) : MNat.lt(q, _)
  MNat.lt_succ_self(q)

law eviction_check:
  for ~A: Data
  for +buffer: Storage.Tree<A>
  for +period: U32
  for +size: U32
  for +pos: U32
  for +history: List<&2, A>
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for hmax: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  for cells: @+a: U32 -> @available: {U32.is_lt(a, size) == True{} : Bool} -> {Some{Storage.cell(~A, buffer, index(period, pos, a))} == lookup(~A, history, a) : Maybe<&2, A>}
  for full: Bool
  for efull: {U32.is_eq(size, period) == full : Bool}
  {Bool.pick(Maybe<&2, A>, full, Some{Storage.cell(~A, buffer, pos)}, None{}) == Bool.pick(Maybe<&2, A>, full, lookup(~A, history, U32.sub(period, 1)), None{}) : Maybe<&2, A>}

def eviction_check(A, buffer, period, size, pos, history, q, ep, hp, hmax, cells, full, efull):
  match full:
    case False{}:
      {==}
    case True{}:
      %Indices.index_oldest(period, pos, q, ep, hp, hmax) : {Some{Storage.cell(~A, buffer, _)} == lookup(~A, history, U32.sub(period, 1)) : Maybe<&2, A>}
      cells(U32.sub(period, 1), oldest_available(period, size, q, ep, efull))

law eviction_fields:
  for ~A: Data
  for +d: Nat
  for +buffer: Storage.Tree<A>
  for +period: U32
  for +size: U32
  for +pos: U32
  for +history: List<&2, A>
  for config: Configuration<period, d>
  for hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for cells: @+a: U32 -> @available: {U32.is_lt(a, size) == True{} : Bool} -> {Some{Storage.cell(~A, buffer, index(period, pos, a))} == lookup(~A, history, a) : Maybe<&2, A>}
  {eviction(~A, Model{buffer, period, size, pos}) == Bool.pick(Maybe<&2, A>, U32.is_eq(size, period), lookup(~A, history, U32.sub(period, 1)), None{}) : Maybe<&2, A>}

def eviction_fields(A, d, buffer, period, size, pos, history, config, hp, cells):
  match config:
    case Valid{positive, hmax, hd, hc}:
      eviction_check(~A, buffer, period, size, pos, history, Nat.sub(U32.to_nat(period), 1n), positive_predecessor(U32.to_nat(period), positive), hp, hmax, cells, U32.is_eq(size, period), {==})

law eviction_visible:
  for ~A: Data
  for +d: Nat
  for +m: Model<A>
  for +history: List<&2, A>
  for invariant: Invariant(~A, d, m, history)
  {eviction(~A, m) == expelled(~A, model_period(~A, m), history) : Maybe<&2, A>}

def eviction_visible(A, d, m, history, invariant):
  match m:
    case Model{+buffer, +period, +size, +pos}:
      match invariant:
        case (config, shape, hs, hp, length, cells):
          %min_full(List.length(&2, A, history), U32.to_nat(period)) : {eviction(~A, Model{buffer, period, size, pos}) == Bool.pick(Maybe<&2, A>, _, lookup(~A, history, U32.sub(period, 1)), None{}) : Maybe<&2, A>}
          %length : {eviction(~A, Model{buffer, period, size, pos}) == Bool.pick(Maybe<&2, A>, Nat.is_eq(_, U32.to_nat(period)), lookup(~A, history, U32.sub(period, 1)), None{}) : Maybe<&2, A>}
          %MU32.u32_is_eq_to_nat(size, period) : {eviction(~A, Model{buffer, period, size, pos}) == Bool.pick(Maybe<&2, A>, _, lookup(~A, history, U32.sub(period, 1)), None{}) : Maybe<&2, A>}
          eviction_fields(~A, d, buffer, period, size, pos, history, config, hp, cells)

law push_history:
  for ~A: Data
  for +period: U32
  for +d: Nat
  for +fill: A
  for +history: List<&2, A>
  for +value: A
  for config: Configuration<period, d>
  {Window.push(~A, replay(~A, period, d, fill, history), value) == (replay(~A, period, d, fill, value <> history), expelled(~A, period, history)) : Window.State<A> & Maybe<&2, A>}

def push_history(A, period, d, fill, history, value, config):
  +m = initialized_history(~A, period, d, fill, history)
  %history_period(~A, period, d, fill, history) : {Window.push(~A, replay(~A, period, d, fill, history), value) == (replay(~A, period, d, fill, value <> history), expelled(~A, _, history)) : Window.State<A> & Maybe<&2, A>}
  %replay_state(~A, period, d, fill, history) : {Window.push(~A, _, value) == (replay(~A, period, d, fill, value <> history), expelled(~A, model_period(~A, m), history)) : Window.State<A> & Maybe<&2, A>}
  %replay_state(~A, period, d, fill, value <> history) : {Window.push(~A, state(~A, m), value) == (_, expelled(~A, model_period(~A, m), history)) : Window.State<A> & Maybe<&2, A>}
  %push_state(~A, m, value) : {_ == (state(~A, push(~A, m, value)), expelled(~A, model_period(~A, m), history)) : Window.State<A> & Maybe<&2, A>}
  Equal.cong(Maybe<&2, A>, Window.State<A> & Maybe<&2, A>, x => (state(~A, push(~A, m, value)), x), eviction(~A, m), expelled(~A, model_period(~A, m), history), eviction_visible(~A, d, m, history, history_invariant(~A, period, d, fill, history, config)))
