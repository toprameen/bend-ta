import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat
import bend-mathlib@0.8.1.0/u32.bend as MU32
import bend-mathlib@0.8.1.0/bool.bend as MBool
import ./window_storage.bend as Storage
import ./window_words.bend as Words

def balanced(~A: Data, +d: Nat, a: Storage.Tree<A>) -> Bool:
  match d a:
    case 0n Storage.Leaf{x}:
      True{}
    case 1n++p Storage.Node{xs, ys}:
      Bool.and(balanced(~A, p, xs), balanced(~A, p, ys))
    case _ _:
      False{}

def double_power_bound(+d: Nat, +x: Nat, e: {x == Nat.pow(2n, d) : Nat}, h: MNat.lt(1n+d, 32n)) -> MNat.lt(Nat.double(x), Nat.pow(2n, 32n)):
  %Equal.sym(Nat, x, Nat.pow(2n, d), e) : MNat.lt(Nat.double(_), Nat.pow(2n, 32n))
  %MNat.two_pow_succ(d) : MNat.lt(_, Nat.pow(2n, 32n))
  MNat.pow_lt_pow_right(0n, 1n+d, 32n, h)

law capacity_value:
  for ~A: Data
  for +d: Nat
  for +a: Storage.Tree<A>
  for +hd: MNat.lt(d, 32n)
  for shape: {balanced(~A, d, a) == True{} : Bool}
  {U32.to_nat(Storage.capacity(~A, a)) == Nat.pow(2n, d) : Nat}

def capacity_value(A, d, a, hd, shape):
  match d a:
    case 0n Storage.Leaf{x}:
      {==}
    case 0n Storage.Node{xs, ys}:
      Empty.absurd({U32.to_nat(Storage.capacity(~A, Storage.Node{xs, ys})) == 1n : Nat}, MBool.internal_false_ne_true(shape))
    case 1n+p Storage.Leaf{x}:
      Empty.absurd({1n == Nat.pow(2n, 1n+p) : Nat}, MBool.internal_false_ne_true(shape))
    case 1n++p Storage.Node{+xs, +ys}:
      +e = capacity_value(~A, p, xs, MNat.lt_trans(p, 1n+p, 32n, MNat.lt_succ_self(p), hd), MBool.eq_true_of_and_left(balanced(~A, p, xs), balanced(~A, p, ys), shape))
      Equal.trans(Nat, U32.to_nat(U32.shl(Storage.capacity(~A, xs))), Nat.double(U32.to_nat(Storage.capacity(~A, xs))), Nat.pow(2n, 1n+p),
        Words.u32_shl_exact(Storage.capacity(~A, xs), double_power_bound(p, U32.to_nat(Storage.capacity(~A, xs)), e, hd)),
        Equal.trans(Nat, Nat.double(U32.to_nat(Storage.capacity(~A, xs))), Nat.double(Nat.pow(2n, p)), Nat.pow(2n, 1n+p), Equal.cong(Nat, Nat, x => Nat.double(x), U32.to_nat(Storage.capacity(~A, xs)), Nat.pow(2n, p), e), MNat.two_pow_succ_sym(p)))

law half_power:
  for +n: U32
  for +d: Nat
  for e: {U32.to_nat(n) == Nat.pow(2n, 1n+d) : Nat}
  {U32.to_nat(U32.shr(n)) == Nat.pow(2n, d) : Nat}

def half_power(n, d, e):
  %Equal.sym(Nat, U32.to_nat(U32.shr(n)), Nat.div(U32.to_nat(n), 2n), Words.u32_shr_value(n)) : {_ == Nat.pow(2n, d) : Nat}
  %Equal.sym(Nat, U32.to_nat(n), Nat.pow(2n, 1n+d), e) : {Nat.div(_, 2n) == Nat.pow(2n, d) : Nat}
  %MNat.two_pow_succ_sym(d) : {Nat.div(_, 2n) == Nat.pow(2n, d) : Nat}
  Words.bit_double_div(False{}, Nat.pow(2n, d))

law u32_lt_nat:
  for +i: U32
  for +n: U32
  for h: {U32.is_lt(i, n) == True{} : Bool}
  MNat.lt(U32.to_nat(i), U32.to_nat(n))

def u32_lt_nat(i, n, h):
  %MU32.u32_is_lt_to_nat(i, n) : {_ == True{} : Bool}
  h

law u32_nlt_nat:
  for +i: U32
  for +n: U32
  for h: {U32.is_lt(i, n) == False{} : Bool}
  MNat.le(U32.to_nat(n), U32.to_nat(i))

def u32_nlt_nat(i, n, h):
  MNat.le_of_not_lt(U32.to_nat(i), U32.to_nat(n), Equal.trans(Bool, Nat.is_lt(U32.to_nat(i), U32.to_nat(n)), U32.is_lt(i, n), False{}, MU32.u32_is_lt_to_nat_sym(i, n), h))

law half_double:
  for +n: U32
  for +d: Nat
  for +e: {U32.to_nat(n) == Nat.pow(2n, 1n+d) : Nat}
  {Nat.double(U32.to_nat(U32.shr(n))) == U32.to_nat(n) : Nat}

def half_double(n, d, e):
  %Equal.sym(Nat, U32.to_nat(n), Nat.pow(2n, 1n+d), e) : {Nat.double(U32.to_nat(U32.shr(n))) == _ : Nat}
  %Equal.sym(Nat, U32.to_nat(U32.shr(n)), Nat.pow(2n, d), half_power(n, d, e)) : {Nat.double(_) == Nat.pow(2n, 1n+d) : Nat}
  MNat.two_pow_succ_sym(d)

def subtract_bound_expand(+x: Nat, +h: Nat, +n: Nat, e: {Nat.double(h) == n : Nat}, hi: MNat.lt(x, n), hl: MNat.le(h, x)) -> MNat.lt(Nat.add(h, Nat.sub(x, h)), Nat.add(h, h)):
  %Equal.sym(Nat, Nat.add(h, Nat.sub(x, h)), x, MNat.add_sub_of_le(h, x, hl)) : MNat.lt(_, Nat.add(h, h))
  %MNat.double_eq_add(h) : MNat.lt(x, _)
  %Equal.sym(Nat, Nat.double(h), n, e) : MNat.lt(x, _)
  hi

law subtract_half_bound:
  for +i: U32
  for +n: U32
  for +d: Nat
  for +e: {U32.to_nat(n) == Nat.pow(2n, 1n+d) : Nat}
  for hi: MNat.lt(U32.to_nat(i), U32.to_nat(n))
  for +hl: MNat.le(U32.to_nat(U32.shr(n)), U32.to_nat(i))
  MNat.lt(U32.to_nat(U32.sub(i, U32.shr(n))), U32.to_nat(U32.shr(n)))

def subtract_half_bound(i, n, d, e, hi, hl):
  %Equal.sym(Nat, U32.to_nat(U32.sub(i, U32.shr(n))), Nat.sub(U32.to_nat(i), U32.to_nat(U32.shr(n))), MU32.u32_sub_exact(i, U32.shr(n), hl)) : MNat.lt(_, U32.to_nat(U32.shr(n)))
  MNat.lt_of_add_lt_add_left(U32.to_nat(U32.shr(n)), Nat.sub(U32.to_nat(i), U32.to_nat(U32.shr(n))), U32.to_nat(U32.shr(n)),
    subtract_bound_expand(U32.to_nat(i), U32.to_nat(U32.shr(n)), U32.to_nat(n), half_double(n, d, e), hi, hl))

def subtract_cancel_nat(+x: Nat, +y: Nat, +h: Nat, hx: MNat.le(h, x), hy: MNat.le(h, y), e: {Nat.sub(x, h) == Nat.sub(y, h) : Nat}) -> {x == y : Nat}:
  %MNat.add_sub_of_le(h, x, hx) : {_ == y : Nat}
  %MNat.add_sub_of_le(h, y, hy) : {Nat.add(h, Nat.sub(x, h)) == _ : Nat}
  Equal.cong(Nat, Nat, z => Nat.add(h, z), Nat.sub(x, h), Nat.sub(y, h), e)

def subtract_equal_nat(+i: U32, +j: U32, +h: U32, hi: MNat.le(U32.to_nat(h), U32.to_nat(i)), hj: MNat.le(U32.to_nat(h), U32.to_nat(j)), e: {U32.sub(i, h) == U32.sub(j, h) : U32}) -> {Nat.sub(U32.to_nat(i), U32.to_nat(h)) == Nat.sub(U32.to_nat(j), U32.to_nat(h)) : Nat}:
  %MU32.u32_sub_exact(i, h, hi) : {_ == Nat.sub(U32.to_nat(j), U32.to_nat(h)) : Nat}
  %MU32.u32_sub_exact(j, h, hj) : {U32.to_nat(U32.sub(i, h)) == _ : Nat}
  Equal.cong(U32, Nat, x => U32.to_nat(x), U32.sub(i, h), U32.sub(j, h), e)

law subtract_cancel:
  for +i: U32
  for +j: U32
  for +h: U32
  for +hi: MNat.le(U32.to_nat(h), U32.to_nat(i))
  for +hj: MNat.le(U32.to_nat(h), U32.to_nat(j))
  for e: {U32.sub(i, h) == U32.sub(j, h) : U32}
  {i == j : U32}

def subtract_cancel(i, j, h, hi, hj, e):
  MU32.u32_to_nat_inj(i, j, subtract_cancel_nat(U32.to_nat(i), U32.to_nat(j), U32.to_nat(h), hi, hj, subtract_equal_nat(i, j, h, hi, hj, e)))

def bound_power(+i: U32, +n: U32, +d: Nat, en: {U32.to_nat(n) == Nat.pow(2n, d) : Nat}, hi: MNat.lt(U32.to_nat(i), U32.to_nat(n))) -> MNat.lt(U32.to_nat(i), Nat.pow(2n, d)):
  %en : MNat.lt(U32.to_nat(i), _)
  hi

law same_injective_check:
  for ~A: Data
  for +d: Nat
  for +a: Storage.Tree<A>
  for +n: U32
  for +i: U32
  for +j: U32
  for +z: Bool
  for +w: Bool
  for +en: {U32.to_nat(n) == Nat.pow(2n, d) : Nat}
  for +shape: {balanced(~A, d, a) == True{} : Bool}
  for hi: MNat.lt(U32.to_nat(i), U32.to_nat(n))
  for hj: MNat.lt(U32.to_nat(j), U32.to_nat(n))
  for +ez: {U32.is_lt(i, U32.shr(n)) == z : Bool}
  for +ew: {U32.is_lt(j, U32.shr(n)) == w : Bool}
  for same: {Storage.same_go(~A, a, n, i, z, j, w) == True{} : Bool}
  {i == j : U32}

def same_injective_check(A, d, a, n, i, j, z, w, en, shape, hi, hj, ez, ew, same):
  match d a z w:
    case 0n Storage.Leaf{x} _ _:
      MU32.u32_to_nat_inj(i, j, Equal.trans(Nat, U32.to_nat(i), 0n, U32.to_nat(j), Words.lt_one_zero(U32.to_nat(i), bound_power(i, n, 0n, en, hi)), Equal.sym(Nat, U32.to_nat(j), 0n, Words.lt_one_zero(U32.to_nat(j), bound_power(j, n, 0n, en, hj)))))
    case 0n Storage.Node{xs, ys} _ _:
      Empty.absurd({i == j : U32}, MBool.internal_false_ne_true(shape))
    case 1n+p Storage.Leaf{x} _ _:
      Empty.absurd({i == j : U32}, MBool.internal_false_ne_true(shape))
    case 1n++p Storage.Node{+xs, +ys} True{} True{}:
      same_injective_check(~A, p, xs, U32.shr(n), i, j, U32.is_lt(i, U32.shr(U32.shr(n))), U32.is_lt(j, U32.shr(U32.shr(n))), half_power(n, p, en), MBool.eq_true_of_and_left(balanced(~A, p, xs), balanced(~A, p, ys), shape), u32_lt_nat(i, U32.shr(n), ez), u32_lt_nat(j, U32.shr(n), ew), {==}, {==}, same)
    case 1n++p Storage.Node{+xs, +ys} False{} False{}:
      subtract_cancel(i, j, U32.shr(n), u32_nlt_nat(i, U32.shr(n), ez), u32_nlt_nat(j, U32.shr(n), ew),
        same_injective_check(~A, p, ys, U32.shr(n), U32.sub(i, U32.shr(n)), U32.sub(j, U32.shr(n)), U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))), U32.is_lt(U32.sub(j, U32.shr(n)), U32.shr(U32.shr(n))), half_power(n, p, en), MBool.eq_true_of_and_right(balanced(~A, p, xs), balanced(~A, p, ys), shape), subtract_half_bound(i, n, p, en, hi, u32_nlt_nat(i, U32.shr(n), ez)), subtract_half_bound(j, n, p, en, hj, u32_nlt_nat(j, U32.shr(n), ew)), {==}, {==}, same))
    case 1n+p Storage.Node{xs, ys} True{} False{}:
      Empty.absurd({i == j : U32}, MBool.internal_false_ne_true(same))
    case 1n+p Storage.Node{xs, ys} False{} True{}:
      Empty.absurd({i == j : U32}, MBool.internal_false_ne_true(same))

law put_go_balanced:
  for ~A: Data
  for +d: Nat
  for +a: Storage.Tree<A>
  for +n: U32
  for +i: U32
  for value: A
  for +z: Bool
  {balanced(~A, d, Storage.put_go(~A, a, n, i, value, z)) == balanced(~A, d, a) : Bool}

def put_go_balanced(A, d, a, n, i, value, z):
  match d a z:
    case _ Storage.Leaf{x} _:
      {==}
    case 0n Storage.Node{xs, ys} True{}:
      {==}
    case 0n Storage.Node{xs, ys} False{}:
      {==}
    case 1n++p Storage.Node{+xs, +ys} True{}:
      %put_go_balanced(~A, p, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n)))) : {Bool.and(balanced(~A, p, Storage.put_go(~A, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n))))), balanced(~A, p, ys)) == Bool.and(_, balanced(~A, p, ys)) : Bool}
      {==}
    case 1n++p Storage.Node{+xs, +ys} False{}:
      %put_go_balanced(~A, p, ys, U32.shr(n), U32.sub(i, U32.shr(n)), value, U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n)))) : {Bool.and(balanced(~A, p, xs), balanced(~A, p, Storage.put_go(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), value, U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n)))))) == Bool.and(balanced(~A, p, xs), _) : Bool}
      {==}

law put_balanced:
  for ~A: Data
  for +d: Nat
  for +a: Storage.Tree<A>
  for +i: U32
  for value: A
  {balanced(~A, d, Storage.put(~A, a, i, value)) == balanced(~A, d, a) : Bool}

def put_balanced(A, d, a, i, value):
  put_go_balanced(~A, d, a, Storage.capacity(~A, a), Storage.wrapped_index(Storage.capacity(~A, a), i), value, U32.is_lt(Storage.wrapped_index(Storage.capacity(~A, a), i), U32.shr(Storage.capacity(~A, a))))

def false_of_no_true(b: Bool, f: {b == True{} : Bool} -> Empty) -> {b == False{} : Bool}:
  match b:
    case False{}:
      {==}
    case True{}:
      Empty.absurd({True{} == False{} : Bool}, f({==}))

law read_write_frame:
  for ~A: Data
  for +d: Nat
  for +a: Storage.Tree<A>
  for +n: U32
  for +i: U32
  for +j: U32
  for +value: A
  for en: {U32.to_nat(n) == Nat.pow(2n, d) : Nat}
  for shape: {balanced(~A, d, a) == True{} : Bool}
  for hi: MNat.lt(U32.to_nat(i), U32.to_nat(n))
  for hj: MNat.lt(U32.to_nat(j), U32.to_nat(n))
  for ne: {i == j : U32} -> Empty
  {Storage.read(~A, Storage.write(~A, a, n, i, value), n, j) == Storage.read(~A, a, n, j) : A}

def read_write_frame(A, d, a, n, i, j, value, en, shape, hi, hj, ne):
  +same = Storage.same_go(~A, a, n, i, U32.is_lt(i, U32.shr(n)), j, U32.is_lt(j, U32.shr(n)))
  +e = false_of_no_true(same, h => ne(same_injective_check(~A, d, a, n, i, j, U32.is_lt(i, U32.shr(n)), U32.is_lt(j, U32.shr(n)), en, shape, hi, hj, {==}, {==}, h)))
  %e : {Storage.read(~A, Storage.write(~A, a, n, i, value), n, j) == Bool.pick(A, _, value, Storage.read(~A, a, n, j)) : A}
  Storage.cell_put_frame_go(~A, a, n, i, U32.is_lt(i, U32.shr(n)), j, U32.is_lt(j, U32.shr(n)), value)

law cell_put_frame:
  for ~A: Data
  for +d: Nat
  for +a: Storage.Tree<A>
  for +i: U32
  for +j: U32
  for +value: A
  for +hd: MNat.lt(d, 32n)
  for +shape: {balanced(~A, d, a) == True{} : Bool}
  for +hi: MNat.lt(U32.to_nat(i), U32.to_nat(Storage.capacity(~A, a)))
  for +hj: MNat.lt(U32.to_nat(j), U32.to_nat(Storage.capacity(~A, a)))
  for ne: {i == j : U32} -> Empty
  {Storage.cell(~A, Storage.put(~A, a, i, value), j) == Storage.cell(~A, a, j) : A}

def cell_put_frame(A, d, a, i, j, value, hd, shape, hi, hj, ne):
  +n = Storage.capacity(~A, a)
  +en = capacity_value(~A, d, a, hd, shape)
  +ei = Words.mask_identity(n, d, i, MNat.le_of_lt(d, 32n, hd), en, bound_power(i, n, d, en, hi))
  +ej = Words.mask_identity(n, d, j, MNat.le_of_lt(d, 32n, hd), en, bound_power(j, n, d, en, hj))
  %Equal.sym(U32, Storage.capacity(~A, Storage.put(~A, a, i, value)), n, Storage.put_capacity(~A, a, i, value)) : {Storage.cell_at(~A, Storage.put(~A, a, i, value), _, j) == Storage.cell(~A, a, j) : A}
  %Equal.sym(U32, Storage.wrapped_index(n, i), i, ei) : {Storage.read(~A, Storage.write(~A, a, n, _, value), n, Storage.wrapped_index(n, j)) == Storage.read(~A, a, n, Storage.wrapped_index(n, j)) : A}
  %Equal.sym(U32, Storage.wrapped_index(n, j), j, ej) : {Storage.read(~A, Storage.write(~A, a, n, i, value), n, _) == Storage.read(~A, a, n, _) : A}
  read_write_frame(~A, d, a, n, i, j, value, en, shape, hi, hj, ne)
