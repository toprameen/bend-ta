import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat

def back(+q: Nat, pos: Nat, age: Nat) -> Nat:
  Nat.mod(Nat.sub(Nat.add(pos, q), age), 1n+q)

law back_oldest:
  for +q: Nat
  for +pos: Nat
  for h: MNat.lt(pos, 1n+q)
  {back(q, pos, q) == pos : Nat}

def back_oldest(q, pos, h):
  %MNat.add_sub_cancel_sym(pos, q) : {Nat.mod(_, 1n+q) == pos : Nat}
  MNat.mod_eq_of_lt(pos, 1n+q, h)

law sub_step:
  for +q: Nat
  for +age: Nat
  for h: MNat.lt(age, q)
  {Nat.sub(q, age) == 1n+Nat.sub(q, 1n+age) : Nat}

def sub_step(q, age, h):
  match q age:
    case 0n _:
      Empty.absurd({Nat.sub(0n, age) == 1n+Nat.sub(0n, 1n+age) : Nat}, MNat.lt_zero(age)(h))
    case 1n+p 0n:
      %MNat.sub_zero_sym(p) : {1n+p == 1n+_ : Nat}
      {==}
    case 1n++p 1n++r:
      sub_step(p, r, h)

law back_wrap_shift:
  for +q: Nat
  for +age: Nat
  for +h: MNat.lt(age, q)
  {back(q, 0n, 1n+age) == back(q, q, age) : Nat}

def back_wrap_shift(q, age, h):
  %Equal.sym(Nat, Nat.sub(Nat.add(q, q), age), Nat.add(q, Nat.sub(q, age)), MNat.add_sub_assoc(age, q, MNat.le_of_lt(age, q, h), q)) : {back(q, 0n, 1n+age) == Nat.mod(_, 1n+q) : Nat}
  %Equal.sym(Nat, Nat.sub(q, age), 1n+Nat.sub(q, 1n+age), sub_step(q, age, h)) : {back(q, 0n, 1n+age) == Nat.mod(Nat.add(q, _), 1n+q) : Nat}
  %MNat.add_succ_sym(q, Nat.sub(q, 1n+age)) : {back(q, 0n, 1n+age) == Nat.mod(_, 1n+q) : Nat}
  Equal.sym(Nat, Nat.mod(Nat.add(1n+q, Nat.sub(q, 1n+age)), 1n+q), Nat.mod(Nat.sub(q, 1n+age), 1n+q), MNat.add_mod_left(Nat.sub(q, 1n+age), 1n+q))

law back_newest:
  for +q: Nat
  for +pos: Nat
  for hp: MNat.lt(pos, 1n+q)
  {back(q, Nat.mod(1n+pos, 1n+q), 0n) == pos : Nat}

law back_shift:
  for +q: Nat
  for +pos: Nat
  for +age: Nat
  for +hp: MNat.lt(pos, 1n+q)
  for +ha: MNat.lt(age, q)
  {back(q, Nat.mod(1n+pos, 1n+q), 1n+age) == back(q, pos, age) : Nat}

def next_newest_check(+q: Nat, +pos: Nat, before: Bool, e: {Nat.is_lt(pos, q) == before : Bool}, hp: MNat.le(pos, q)) -> {back(q, Nat.mod(1n+pos, 1n+q), 0n) == pos : Nat}:
  match before:
    case True{}:
      %Equal.sym(Nat, Nat.mod(1n+pos, 1n+q), 1n+pos, MNat.mod_eq_of_lt(1n+pos, 1n+q, e)) : {back(q, _, 0n) == pos : Nat}
      %MNat.sub_zero_sym(Nat.add(1n+pos, q)) : {Nat.mod(_, 1n+q) == pos : Nat}
      %MNat.add_comm(q, pos) : {Nat.mod(1n+_, 1n+q) == pos : Nat}
      %MNat.add_mod_left_sym(pos, 1n+q) : {_ == pos : Nat}
      MNat.mod_eq_of_lt(pos, 1n+q, MNat.lt_succ_of_le(pos, q, hp))
    case False{}:
      %Equal.sym(Nat, pos, q, MNat.le_antisymm(pos, q, hp, MNat.le_of_not_lt(pos, q, e))) : {back(q, Nat.mod(1n+_, 1n+q), 0n) == _ : Nat}
      %MNat.mod_self_sym(1n+q) : {back(q, _, 0n) == q : Nat}
      %MNat.sub_zero_sym(q) : {Nat.mod(_, 1n+q) == q : Nat}
      MNat.mod_eq_of_lt(q, 1n+q, MNat.lt_succ_self(q))

def back_newest(q, pos, hp):
  next_newest_check(q, pos, Nat.is_lt(pos, q), {==}, MNat.le_of_lt_succ(pos, q, hp))

def next_shift_check(+q: Nat, +pos: Nat, +age: Nat, before: Bool, e: {Nat.is_lt(pos, q) == before : Bool}, hp: MNat.le(pos, q), ha: MNat.lt(age, q)) -> {back(q, Nat.mod(1n+pos, 1n+q), 1n+age) == back(q, pos, age) : Nat}:
  match before:
    case True{}:
      %Equal.sym(Nat, Nat.mod(1n+pos, 1n+q), 1n+pos, MNat.mod_eq_of_lt(1n+pos, 1n+q, e)) : {back(q, _, 1n+age) == back(q, pos, age) : Nat}
      {==}
    case False{}:
      %Equal.sym(Nat, pos, q, MNat.le_antisymm(pos, q, hp, MNat.le_of_not_lt(pos, q, e))) : {back(q, Nat.mod(1n+_, 1n+q), 1n+age) == back(q, _, age) : Nat}
      %MNat.mod_self_sym(1n+q) : {back(q, _, 1n+age) == back(q, q, age) : Nat}
      back_wrap_shift(q, age, ha)

def back_shift(q, pos, age, hp, ha):
  next_shift_check(q, pos, age, Nat.is_lt(pos, q), {==}, MNat.le_of_lt_succ(pos, q, hp), ha)

def proper_multiple(q: Nat, +p: Nat, +r: Nat, hp: MNat.lt(0n, r), hr: MNat.lt(r, p), e: {Nat.mul(p, q) == r : Nat}) -> Empty:
  match q:
    case 0n:
      MNat.lt_irrefl(0n)(Equal.trans(Bool, Nat.is_lt(0n, 0n), Nat.is_lt(0n, r), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(0n, x), 0n, r, Equal.trans(Nat, 0n, Nat.mul(p, 0n), r, MNat.mul_zero_sym(p), e)), hp))
    case 1n+t:
      MNat.lt_irrefl(p)(MNat.lt_of_le_of_lt(p, r, p, Equal.trans(Bool, Nat.is_le(p, r), Nat.is_le(p, Nat.mul(p, 1n+t)), True{}, Equal.cong(Nat, Bool, x => Nat.is_le(p, x), r, Nat.mul(p, 1n+t), Equal.sym(Nat, Nat.mul(p, 1n+t), r, e)), MNat.le_mul_of_pos_right(p, t)), hr))

law add_mod_ne:
  for +pos: Nat
  for +r: Nat
  for +p: Nat
  for hp: MNat.lt(0n, r)
  for hr: MNat.lt(r, p)
  for em: {Nat.mod(Nat.add(pos, r), p) == pos : Nat}
  Empty

def add_mod_ne(pos, r, p, hp, hr, em):
  proper_multiple(Nat.div(Nat.add(pos, r), p), p, r, hp, hr,
    MNat.add_left_cancel(pos, Nat.mul(p, Nat.div(Nat.add(pos, r), p)), r,
      Equal.trans(Nat, Nat.add(pos, Nat.mul(p, Nat.div(Nat.add(pos, r), p))), Nat.add(Nat.mod(Nat.add(pos, r), p), Nat.mul(p, Nat.div(Nat.add(pos, r), p))), Nat.add(pos, r),
        Equal.cong(Nat, Nat, x => Nat.add(x, Nat.mul(p, Nat.div(Nat.add(pos, r), p))), pos, Nat.mod(Nat.add(pos, r), p), Equal.sym(Nat, Nat.mod(Nat.add(pos, r), p), pos, em)), MNat.mod_add_div(Nat.add(pos, r), p))))

law back_ne_write:
  for +q: Nat
  for +pos: Nat
  for +age: Nat
  for +ha: MNat.lt(age, q)
  for e: {back(q, pos, age) == pos : Nat}
  Empty

def back_ne_write(q, pos, age, ha, e):
  add_mod_ne(pos, Nat.sub(q, age), 1n+q, MNat.sub_pos_of_lt(age, q, ha), MNat.lt_succ_of_le(Nat.sub(q, age), q, MNat.sub_le(q, age)),
    Equal.trans(Nat, Nat.mod(Nat.add(pos, Nat.sub(q, age)), 1n+q), back(q, pos, age), pos,
      Equal.cong(Nat, Nat, x => Nat.mod(x, 1n+q), Nat.add(pos, Nat.sub(q, age)), Nat.sub(Nat.add(pos, q), age), Equal.sym(Nat, Nat.sub(Nat.add(pos, q), age), Nat.add(pos, Nat.sub(q, age)), MNat.add_sub_assoc(age, q, MNat.le_of_lt(age, q, ha), pos))), e))
