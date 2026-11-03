import Base
import bend-mathlib@0.8.1.0/list.bend as MList
import bend-mathlib@0.8.1.0/nat.bend as MNat
import ../src/core/series.bend as Series

law map_collect_length:
  for ~I: Data
  for ~O: Data
  for ~f: I -> O
  for xs: List<&2, I>
  for +acc: List<&2, O>
  {List.length(&2, O, Series.map.collect(~I, ~O, ~f, xs, acc)) == Nat.add(List.length(&2, I, xs), List.length(&2, O, acc)) : Nat}

def map_collect_length(I, O, f, xs, acc):
  match xs:
    case Nil{}:
      MList.length_reverse(&2, O, acc)
    case +h <> +t:
      %MNat.add_succ(List.length(&2, I, t), List.length(&2, O, acc)) : {List.length(&2, O, Series.map.collect(~I, ~O, ~f, t, f(h) <> acc)) == _ : Nat}
      map_collect_length(~I, ~O, ~f, t, f(h) <> acc)

law map_length:
  for ~I: Data
  for ~O: Data
  for ~f: I -> O
  for +xs: List<&2, I>
  {List.length(&2, O, Series.map(~I, ~O, ~f, xs)) == List.length(&2, I, xs) : Nat}

def map_length(I, O, f, xs):
  %MNat.add_zero(List.length(&2, I, xs)) : {List.length(&2, O, Series.map(~I, ~O, ~f, xs)) == _ : Nat}
  map_collect_length(~I, ~O, ~f, xs, Nil{})

def result_length(~O: Data, ~S: Type, result: S & List<&2, Maybe<&2, O>>) -> Nat:
  (state, values) = result
  List.length(&2, Maybe<&2, O>, values)

def collect_length_step(
  ~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>,
  +xs: List<&2, I>, +acc: List<&2, Maybe<&2, O>>, result: S & Maybe<&2, O>,
  ih: @s: S -> @v: Maybe<&2, O> -> {result_length(~O, ~S, Series.collect(~I, ~O, ~S, ~step, xs, s, v <> acc)) == Nat.add(List.length(&2, I, xs), 1n+List.length(&2, Maybe<&2, O>, acc)) : Nat}
) -> {result_length(~O, ~S, Series.resume(O, S, result, s => v => Series.collect(~I, ~O, ~S, ~step, xs, s, v <> acc))) == 1n+Nat.add(List.length(&2, I, xs), List.length(&2, Maybe<&2, O>, acc)) : Nat}:
  match result:
    case (state, value):
      %MNat.add_succ(List.length(&2, I, xs), List.length(&2, Maybe<&2, O>, acc)) : {result_length(~O, ~S, Series.collect(~I, ~O, ~S, ~step, xs, state, value <> acc)) == _ : Nat}
      ih(state, value)

law collect_length:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for state: S
  for +acc: List<&2, Maybe<&2, O>>
  {result_length(~O, ~S, Series.collect(~I, ~O, ~S, ~step, xs, state, acc)) == Nat.add(List.length(&2, I, xs), List.length(&2, Maybe<&2, O>, acc)) : Nat}

def collect_length(I, O, S, step, xs, state, acc):
  match xs:
    case Nil{}:
      MList.length_reverse(&2, Maybe<&2, O>, acc)
    case h <> +t:
      collect_length_step(~I, ~O, ~S, ~step, t, acc, step(state, h), s => v => collect_length(~I, ~O, ~S, ~step, t, s, v <> acc))

law scan_length:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for +xs: List<&2, I>
  for state: S
  {result_length(~O, ~S, Series.scan(~I, ~O, ~S, ~step, xs, state)) == List.length(&2, I, xs) : Nat}

def scan_length(I, O, S, step, xs, state):
  %MNat.add_zero(List.length(&2, I, xs)) : {result_length(~O, ~S, Series.scan(~I, ~O, ~S, ~step, xs, state)) == _ : Nat}
  collect_length(~I, ~O, ~S, ~step, xs, state, Nil{})

def map_spec(~I: Data, ~O: Data, ~f: I -> O, xs: List<&2, I>) -> List<&2, O>:
  match xs:
    case Nil{}: Nil{}
    case h <> t: f(h) <> map_spec(~I, ~O, ~f, t)

def map_collect_spec(~I: Data, ~O: Data, ~f: I -> O, xs: List<&2, I>, +acc: List<&2, O>) -> {Series.map.collect(~I, ~O, ~f, xs, acc) == List.append(&2, O, List.reverse(&2, O, acc), map_spec(~I, ~O, ~f, xs)) : List<&2, O>}:
  match xs:
    case Nil{}:
      Equal.sym(List<&2, O>, List.append(&2, O, List.reverse(&2, O, acc), Nil{}), List.reverse(&2, O, acc), MList.append_nil(&2, O, List.reverse(&2, O, acc)))
    case +h <> t:
      %MList.append_assoc(&2, O, List.reverse(&2, O, acc), [f(h)], map_spec(~I, ~O, ~f, t)) : {Series.map.collect(~I, ~O, ~f, t, f(h) <> acc) == _ : List<&2, O>}
      %MList.reverse_cons(&2, O, f(h), acc) : {Series.map.collect(~I, ~O, ~f, t, f(h) <> acc) == List.append(&2, O, _, map_spec(~I, ~O, ~f, t)) : List<&2, O>}
      map_collect_spec(~I, ~O, ~f, t, f(h) <> acc)

law map_ordered:
  for ~I: Data
  for ~O: Data
  for ~f: I -> O
  for xs: List<&2, I>
  {Series.map(~I, ~O, ~f, xs) == map_spec(~I, ~O, ~f, xs) : List<&2, O>}

def map_ordered(I, O, f, xs):
  map_collect_spec(~I, ~O, ~f, xs, Nil{})

def prefix(-O: Data, -S: Type, before: List<&2, Maybe<&2, O>>, result: S & List<&2, Maybe<&2, O>>) -> S & List<&2, Maybe<&2, O>>:
  match result:
    case (state, values): (state, List.append(&2, Maybe<&2, O>, before, values))

def spec_resume(
  -O: Data, -S: Type, result: S & Maybe<&2, O>,
  rest: S -> Maybe<&2, O> -> S & List<&2, Maybe<&2, O>>
) -> S & List<&2, Maybe<&2, O>>:
  match result:
    case (state, value): rest(state, value)

def scan_spec(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, xs: List<&2, I>, state: S) -> S & List<&2, Maybe<&2, O>>:
  match xs:
    case Nil{}: (state, Nil{})
    case h <> t:
      spec_resume(O, S, step(state, h), s => v => prefix(O, S, [v], scan_spec(~I, ~O, ~S, ~step, t, s)))

def CollectEquality(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -state: S, -final: S, -values: List<&2, Maybe<&2, O>>, -acc: List<&2, Maybe<&2, O>>) -> Type:
  {Series.collect(~I, ~O, ~S, ~step, xs, state, acc) == prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), (final, values)) : S & List<&2, Maybe<&2, O>>}

def Verified(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -state: S) -> Type:
  &final: S -> &values: List<&2, Maybe<&2, O>> ->
    {scan_spec(~I, ~O, ~S, ~step, xs, state) == (final, values) : S & List<&2, Maybe<&2, O>>} &
    (@+acc: List<&2, Maybe<&2, O>> -> @+other: List<&2, Maybe<&2, O>> -> CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, acc) & CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, other))

def reverse_cons_append(-O: Data, +v: Maybe<&2, O>, +acc: List<&2, Maybe<&2, O>>, -values: List<&2, Maybe<&2, O>>) -> {List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, v <> acc), values) == List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), v <> values) : List<&2, Maybe<&2, O>>}:
  %Equal.sym(List<&2, Maybe<&2, O>>, List.reverse(&2, Maybe<&2, O>, v <> acc), List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), [v]), MList.reverse_cons(&2, Maybe<&2, O>, v, acc)) : {List.append(&2, Maybe<&2, O>, _, values) == List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), v <> values) : List<&2, Maybe<&2, O>>}
  MList.append_assoc(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), [v], values)

def AfterEquality(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -transition: S & Maybe<&2, O>, -final: S, -values: List<&2, Maybe<&2, O>>, -acc: List<&2, Maybe<&2, O>>) -> Type:
  {Series.resume(O, S, transition, s => v => Series.collect(~I, ~O, ~S, ~step, xs, s, v <> acc)) == prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), (final, values)) : S & List<&2, Maybe<&2, O>>}

def After(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -transition: S & Maybe<&2, O>) -> Type:
  &final: S -> &values: List<&2, Maybe<&2, O>> ->
    {spec_resume(O, S, transition, s => v => prefix(O, S, [v], scan_spec(~I, ~O, ~S, ~step, xs, s))) == (final, values) : S & List<&2, Maybe<&2, O>>} &
    (@+acc: List<&2, Maybe<&2, O>> -> @+other: List<&2, Maybe<&2, O>> -> AfterEquality(~I, ~O, ~S, ~step, xs, transition, final, values, acc) & AfterEquality(~I, ~O, ~S, ~step, xs, transition, final, values, other))

def collect_cons_equality(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -s: S, -final: S, +values: List<&2, Maybe<&2, O>>, +v: Maybe<&2, O>, +acc: List<&2, Maybe<&2, O>>, eq: CollectEquality(~I, ~O, ~S, ~step, xs, s, final, values, v <> acc)) -> AfterEquality(~I, ~O, ~S, ~step, xs, (s, v), final, v <> values, acc):
  Equal.trans(S & List<&2, Maybe<&2, O>>, Series.collect(~I, ~O, ~S, ~step, xs, s, v <> acc), (final, List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, v <> acc), values)), (final, List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), v <> values)), eq, Equal.cong(List<&2, Maybe<&2, O>>, S & List<&2, Maybe<&2, O>>, ys => (final, ys), List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, v <> acc), values), List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), v <> values), reverse_cons_append(O, v, acc, values)))

def collect_cons_pair(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -s: S, -final: S, +values: List<&2, Maybe<&2, O>>, +v: Maybe<&2, O>, +acc: List<&2, Maybe<&2, O>>, +other: List<&2, Maybe<&2, O>>, eqs: CollectEquality(~I, ~O, ~S, ~step, xs, s, final, values, v <> acc) & CollectEquality(~I, ~O, ~S, ~step, xs, s, final, values, v <> other)) -> AfterEquality(~I, ~O, ~S, ~step, xs, (s, v), final, v <> values, acc) & AfterEquality(~I, ~O, ~S, ~step, xs, (s, v), final, v <> values, other):
  match eqs:
    case (left, right):
      (collect_cons_equality(~I, ~O, ~S, ~step, xs, s, final, values, v, acc, left), collect_cons_equality(~I, ~O, ~S, ~step, xs, s, final, values, v, other, right))

def verified_tail(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -s: S, +v: Maybe<&2, O>, witness: Verified(~I, ~O, ~S, ~step, xs, s)) -> After(~I, ~O, ~S, ~step, xs, (s, v)):
  match witness:
    case (final, rest):
      match rest:
        case (+values, evidence):
          match evidence:
            case (spec_eq, acc_eq):
              ((final : S), (v <> values, (Equal.cong(S & List<&2, Maybe<&2, O>>, S & List<&2, Maybe<&2, O>>, result => prefix(O, S, [v], result), scan_spec(~I, ~O, ~S, ~step, xs, s), (final, values), spec_eq), acc => other => collect_cons_pair(~I, ~O, ~S, ~step, xs, s, final, values, v, acc, other, acc_eq(v <> acc, v <> other)))))

def verified_step(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, transition: S & Maybe<&2, O>, ih: @s: S -> Verified(~I, ~O, ~S, ~step, xs, s)) -> After(~I, ~O, ~S, ~step, xs, transition):
  match transition:
    case (s, v): verified_tail(~I, ~O, ~S, ~step, xs, s, v, ih(s))

def collect_empty_equality(-O: Data, -S: Type, -state: S, acc: List<&2, Maybe<&2, O>>) -> {(state, List.reverse(&2, Maybe<&2, O>, acc)) == prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), (state, Nil{})) : S & List<&2, Maybe<&2, O>>}:
  Equal.cong(List<&2, Maybe<&2, O>>, S & List<&2, Maybe<&2, O>>, values => (state, values), List.reverse(&2, Maybe<&2, O>, acc), List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), Nil{}), Equal.sym(List<&2, Maybe<&2, O>>, List.append(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc), Nil{}), List.reverse(&2, Maybe<&2, O>, acc), MList.append_nil(&2, Maybe<&2, O>, List.reverse(&2, Maybe<&2, O>, acc))))

def scan_verified(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, xs: List<&2, I>, state: S) -> Verified(~I, ~O, ~S, ~step, xs, state):
  match xs:
    case Nil{}:
      ((state : S), (Nil{}, ({==}, acc => other => (collect_empty_equality(O, S, state, acc), collect_empty_equality(O, S, state, other)))))
    case h <> +t:
      verified_step(~I, ~O, ~S, ~step, t, step(state, h), s => scan_verified(~I, ~O, ~S, ~step, t, s))

def first(-A: Type, -B: Type, pair: A & B) -> A:
  match pair:
    case (left, right): left

law scan_ordered:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for state: S
  {Series.scan(~I, ~O, ~S, ~step, xs, state) == scan_spec(~I, ~O, ~S, ~step, xs, state) : S & List<&2, Maybe<&2, O>>}

def scan_ordered_result(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -state: S, witness: Verified(~I, ~O, ~S, ~step, xs, state)) -> {Series.scan(~I, ~O, ~S, ~step, xs, state) == scan_spec(~I, ~O, ~S, ~step, xs, state) : S & List<&2, Maybe<&2, O>>}:
  match witness:
    case (final, rest):
      match rest:
        case (values, evidence):
          match evidence:
            case (spec_eq, acc_eq):
              Equal.trans(S & List<&2, Maybe<&2, O>>, Series.scan(~I, ~O, ~S, ~step, xs, state), (final, values), scan_spec(~I, ~O, ~S, ~step, xs, state), first(CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, Nil{}), CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, Nil{}), acc_eq(Nil{}, Nil{})), Equal.sym(S & List<&2, Maybe<&2, O>>, scan_spec(~I, ~O, ~S, ~step, xs, state), (final, values), spec_eq))

def scan_ordered(I, O, S, step, xs, state):
  scan_ordered_result(~I, ~O, ~S, ~step, xs, state, scan_verified(~I, ~O, ~S, ~step, xs, state))

def continue_scan(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, ys: List<&2, I>, result: S & List<&2, Maybe<&2, O>>) -> S & List<&2, Maybe<&2, O>>:
  match result:
    case (state, before): prefix(O, S, before, Series.scan(~I, ~O, ~S, ~step, ys, state))

def collect_prefix_pair(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -state: S, -final: S, -values: List<&2, Maybe<&2, O>>, -acc: List<&2, Maybe<&2, O>>, eqs: CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, acc) & CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, Nil{})) -> {Series.collect(~I, ~O, ~S, ~step, xs, state, acc) == prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), Series.scan(~I, ~O, ~S, ~step, xs, state)) : S & List<&2, Maybe<&2, O>>}:
  match eqs:
    case (left, right):
      Equal.trans(S & List<&2, Maybe<&2, O>>, Series.collect(~I, ~O, ~S, ~step, xs, state, acc), prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), (final, values)), prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), Series.scan(~I, ~O, ~S, ~step, xs, state)), left, Equal.cong(S & List<&2, Maybe<&2, O>>, S & List<&2, Maybe<&2, O>>, result => prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), result), (final, values), Series.scan(~I, ~O, ~S, ~step, xs, state), Equal.sym(S & List<&2, Maybe<&2, O>>, Series.scan(~I, ~O, ~S, ~step, xs, state), (final, values), right)))

def collect_prefix_result(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -state: S, +acc: List<&2, Maybe<&2, O>>, witness: Verified(~I, ~O, ~S, ~step, xs, state)) -> {Series.collect(~I, ~O, ~S, ~step, xs, state, acc) == prefix(O, S, List.reverse(&2, Maybe<&2, O>, acc), Series.scan(~I, ~O, ~S, ~step, xs, state)) : S & List<&2, Maybe<&2, O>>}:
  match witness:
    case (final, rest):
      match rest:
        case (values, evidence):
          match evidence:
            case (spec_eq, acc_eq):
              collect_prefix_pair(~I, ~O, ~S, ~step, xs, state, final, values, acc, acc_eq(acc, Nil{}))

def collect_append_step(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, -xs: List<&2, I>, -ys: List<&2, I>, -acc: List<&2, Maybe<&2, O>>, transition: S & Maybe<&2, O>, ih: @s: S -> @v: Maybe<&2, O> -> {Series.collect(~I, ~O, ~S, ~step, List.append(&2, I, xs, ys), s, v <> acc) == continue_scan(~I, ~O, ~S, ~step, ys, Series.collect(~I, ~O, ~S, ~step, xs, s, v <> acc)) : S & List<&2, Maybe<&2, O>>}) -> {Series.resume(O, S, transition, s => v => Series.collect(~I, ~O, ~S, ~step, List.append(&2, I, xs, ys), s, v <> acc)) == continue_scan(~I, ~O, ~S, ~step, ys, Series.resume(O, S, transition, s => v => Series.collect(~I, ~O, ~S, ~step, xs, s, v <> acc))) : S & List<&2, Maybe<&2, O>>}:
  match transition:
    case (state, value): ih(state, value)

law collect_append:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for +ys: List<&2, I>
  for state: S
  for +acc: List<&2, Maybe<&2, O>>
  {Series.collect(~I, ~O, ~S, ~step, List.append(&2, I, xs, ys), state, acc) == continue_scan(~I, ~O, ~S, ~step, ys, Series.collect(~I, ~O, ~S, ~step, xs, state, acc)) : S & List<&2, Maybe<&2, O>>}

def collect_append(I, O, S, step, xs, ys, state, acc):
  match xs:
    case Nil{}:
      collect_prefix_result(~I, ~O, ~S, ~step, ys, state, acc, scan_verified(~I, ~O, ~S, ~step, ys, state))
    case h <> +t:
      collect_append_step(~I, ~O, ~S, ~step, t, ys, acc, step(state, h), s => v => collect_append(~I, ~O, ~S, ~step, t, ys, s, v <> acc))

law scan_chunks:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for +ys: List<&2, I>
  for state: S
  {Series.scan(~I, ~O, ~S, ~step, List.append(&2, I, xs, ys), state) == continue_scan(~I, ~O, ~S, ~step, ys, Series.scan(~I, ~O, ~S, ~step, xs, state)) : S & List<&2, Maybe<&2, O>>}

def scan_chunks(I, O, S, step, xs, ys, state):
  collect_append(~I, ~O, ~S, ~step, xs, ys, state, Nil{})

def spec_values(-O: Data, -S: Type, result: S & List<&2, Maybe<&2, O>>) -> List<&2, Maybe<&2, O>>:
  match result:
    case (state, values): values

law batch_ordered:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~step: S -> I -> S & Maybe<&2, O>
  for xs: List<&2, I>
  for state: S
  {Series.batch(~I, ~O, ~S, ~step, xs, state) == spec_values(O, S, scan_spec(~I, ~O, ~S, ~step, xs, state)) : List<&2, Maybe<&2, O>>}

def batch_ordered_result(
  ~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>,
  -xs: List<&2, I>, -state: S, witness: Verified(~I, ~O, ~S, ~step, xs, state)
) -> {Series.batch(~I, ~O, ~S, ~step, xs, state) == spec_values(O, S, scan_spec(~I, ~O, ~S, ~step, xs, state)) : List<&2, Maybe<&2, O>>}:
  match witness:
    case (final, rest):
      match rest:
        case (values, evidence):
          match evidence:
            case (spec_eq, acc_eq):
              Equal.trans(
                List<&2, Maybe<&2, O>>,
                Series.batch(~I, ~O, ~S, ~step, xs, state), values,
                spec_values(O, S, scan_spec(~I, ~O, ~S, ~step, xs, state)),
                Equal.cong(
                  S & List<&2, Maybe<&2, O>>, List<&2, Maybe<&2, O>>,
                  result => Series.values(O, S, result),
                  Series.scan(~I, ~O, ~S, ~step, xs, state), (final, values),
                  first(
                    CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, Nil{}),
                    CollectEquality(~I, ~O, ~S, ~step, xs, state, final, values, Nil{}),
                    acc_eq(Nil{}, Nil{})
                  )
                ),
                Equal.cong(
                  S & List<&2, Maybe<&2, O>>, List<&2, Maybe<&2, O>>,
                  result => spec_values(O, S, result),
                  (final, values), scan_spec(~I, ~O, ~S, ~step, xs, state),
                  Equal.sym(
                    S & List<&2, Maybe<&2, O>>,
                    scan_spec(~I, ~O, ~S, ~step, xs, state), (final, values), spec_eq
                  )
                )
              )

def batch_ordered(I, O, S, step, xs, state):
  batch_ordered_result(~I, ~O, ~S, ~step, xs, state, scan_verified(~I, ~O, ~S, ~step, xs, state))
