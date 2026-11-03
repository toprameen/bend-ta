import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat
import bend-mathlib@0.8.1.0/u32.bend as MU32
import ./window_arithmetic.bend as Arithmetic
import ./window_ring.bend as Ring

def period_safe_core(+p: Nat, +n: Nat, +b: Nat, +m: Nat,
  eb: {Nat.pow(2n, n) == b : Nat}, em: {Nat.pow(2n, 2n+n) == m : Nat},
  h: MNat.le(p, b)) -> MNat.lt(Nat.double(p), m):
  +ed = Equal.trans(Nat, Nat.double(b), Nat.double(Nat.pow(2n, n)), Nat.pow(2n, 1n+n), Equal.cong(Nat, Nat, Nat.double, b, Nat.pow(2n, n), Equal.sym(Nat, Nat.pow(2n, n), b, eb)), MNat.two_pow_succ_sym(n))
  +eg = Equal.trans(Bool, Nat.is_lt(Nat.double(b), m), Nat.is_lt(Nat.pow(2n, 1n+n), m), Nat.is_lt(Nat.pow(2n, 1n+n), Nat.pow(2n, 2n+n)), Equal.cong(Nat, Bool, x => Nat.is_lt(x, m), Nat.double(b), Nat.pow(2n, 1n+n), ed), Equal.cong(Nat, Bool, x => Nat.is_lt(Nat.pow(2n, 1n+n), x), m, Nat.pow(2n, 2n+n), Equal.sym(Nat, Nat.pow(2n, 2n+n), m, em)))
  MNat.lt_of_le_of_lt(Nat.double(p), Nat.double(b), m,
    MNat.double_le_double(p, b, h),
    Equal.trans(Bool, Nat.is_lt(Nat.double(b), m), Nat.is_lt(Nat.pow(2n, 1n+n), Nat.pow(2n, 2n+n)), True{}, eg, MNat.pow_lt_pow_right(0n, 1n+n, 2n+n, MNat.lt_succ_self(1n+n))))

law period_safe:
  for +p: Nat
  for h: MNat.le(p, Nat.pow(2n, 30n))
  MNat.lt(Nat.double(p), Nat.pow(2n, 32n))

def period_safe(p, h):
  period_safe_core(p, 30n, Nat.pow(2n, 30n), Nat.pow(2n, 32n), {==}, {==}, h)

def bounded_add_core(+a: Nat, +b: Nat, +p: Nat, +m: Nat,
  ha: MNat.le(a, p), hb: MNat.le(b, p), safe: MNat.lt(Nat.double(p), m)
) -> MNat.lt(Nat.add(a, b), m):
  MNat.lt_of_le_of_lt(Nat.add(a, b), Nat.add(p, p), m,
    MNat.add_le_add(a, b, p, p, ha, hb),
    Equal.trans(Bool, Nat.is_lt(Nat.add(p, p), m), Nat.is_lt(Nat.double(p), m), True{},
      Equal.cong(Nat, Bool, x => Nat.is_lt(x, m), Nat.add(p, p), Nat.double(p), MNat.double_eq_add_sym(p)), safe))

def bounded_add(+a: U32, +b: U32, +p: Nat,
  ha: MNat.le(U32.to_nat(a), p), hb: MNat.le(U32.to_nat(b), p), h: MNat.le(p, Nat.pow(2n, 30n))
) -> {U32.to_nat(U32.add(a, b)) == Nat.add(U32.to_nat(a), U32.to_nat(b)) : Nat}:
  MU32.internal_u32_add_exact(Nat.pow(2n, 32n), a, b, {==},
    bounded_add_core(U32.to_nat(a), U32.to_nat(b), p, Nat.pow(2n, 32n), ha, hb, period_safe(p, h)))

def index(+period: U32, +pos: U32, age: U32) -> U32:
  U32.mod(U32.sub(U32.add(pos, period), U32.add(age, 1)), period)

def next(+period: U32, pos: U32) -> U32:
  U32.mod(U32.add(pos, 1), period)

def one_le(+p: Nat, +q: Nat, ep: {p == 1n+q : Nat}) -> MNat.le(1n, p):
  %Equal.sym(Nat, p, 1n+q, ep) : MNat.le(1n, _)
  MNat.succ_le_succ(0n, q, MNat.zero_le(q))

law next_to_nat:
  for +period: U32
  for +pos: U32
  for +q: Nat
  for ep: {U32.to_nat(period) == 1n+q : Nat}
  for hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  {U32.to_nat(next(period, pos)) == Nat.mod(1n+U32.to_nat(pos), U32.to_nat(period)) : Nat}

def next_to_nat(period, pos, q, ep, hp, h):
  +eadd = bounded_add(pos, 1, U32.to_nat(period), MNat.le_of_lt(U32.to_nat(pos), U32.to_nat(period), hp), one_le(U32.to_nat(period), q, ep), h)
  Equal.trans(Nat, U32.to_nat(next(period, pos)), Nat.mod(U32.to_nat(U32.add(pos, 1)), U32.to_nat(period)), Nat.mod(1n+U32.to_nat(pos), U32.to_nat(period)),
    Arithmetic.mod_to_nat(U32.add(pos, 1), period),
    Equal.cong(Nat, Nat, x => Nat.mod(x, U32.to_nat(period)), U32.to_nat(U32.add(pos, 1)), 1n+U32.to_nat(pos), Equal.trans(Nat, U32.to_nat(U32.add(pos, 1)), Nat.add(U32.to_nat(pos), 1n), 1n+U32.to_nat(pos), eadd, MNat.add_comm(U32.to_nat(pos), 1n))))

def sub_to_nat(+a: U32, +b: U32, +x: Nat, +y: Nat,
  +ea: {U32.to_nat(a) == x : Nat}, +eb: {U32.to_nat(b) == y : Nat}, h: MNat.le(y, x)
) -> {U32.to_nat(U32.sub(a, b)) == Nat.sub(x, y) : Nat}:
  %ea : {U32.to_nat(U32.sub(a, b)) == Nat.sub(_, y) : Nat}
  %eb : {U32.to_nat(U32.sub(a, b)) == Nat.sub(U32.to_nat(a), _) : Nat}
  MU32.u32_sub_exact(a, b,
    Equal.trans(Bool, Nat.is_le(U32.to_nat(b), U32.to_nat(a)), Nat.is_le(y, U32.to_nat(a)), True{},
      Equal.cong(Nat, Bool, z => Nat.is_le(z, U32.to_nat(a)), U32.to_nat(b), y, eb),
      Equal.trans(Bool, Nat.is_le(y, U32.to_nat(a)), Nat.is_le(y, x), True{}, Equal.cong(Nat, Bool, z => Nat.is_le(y, z), U32.to_nat(a), x, ea), h)))

def difference_back(+pos: Nat, +age: Nat, +q: Nat) -> {Nat.sub(Nat.add(pos, 1n+q), Nat.add(age, 1n)) == Nat.sub(Nat.add(pos, q), age) : Nat}:
  %Equal.sym(Nat, Nat.add(pos, 1n+q), 1n+Nat.add(pos, q), MNat.add_succ(pos, q)) : {Nat.sub(_, Nat.add(age, 1n)) == Nat.sub(Nat.add(pos, q), age) : Nat}
  %MNat.add_comm(1n, age) : {Nat.sub(1n+Nat.add(pos, q), _) == Nat.sub(Nat.add(pos, q), age) : Nat}
  {==}

def index_nat_finish(+p: Nat, +pos: Nat, +age: Nat, +q: Nat, ep: {p == 1n+q : Nat}) -> {Nat.mod(Nat.sub(Nat.add(pos, p), Nat.add(age, 1n)), p) == Ring.back(q, pos, age) : Nat}:
  Equal.trans(Nat, Nat.mod(Nat.sub(Nat.add(pos, p), Nat.add(age, 1n)), p), Nat.mod(Nat.sub(Nat.add(pos, 1n+q), Nat.add(age, 1n)), 1n+q), Ring.back(q, pos, age),
    Equal.cong(Nat, Nat, z => Nat.mod(Nat.sub(Nat.add(pos, z), Nat.add(age, 1n)), z), p, 1n+q, ep),
    Equal.cong(Nat, Nat, z => Nat.mod(z, 1n+q), Nat.sub(Nat.add(pos, 1n+q), Nat.add(age, 1n)), Nat.sub(Nat.add(pos, q), age), difference_back(pos, age, q)))

law index_to_nat:
  for +period: U32
  for +pos: U32
  for +age: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for +ha: MNat.lt(U32.to_nat(age), U32.to_nat(period))
  for +h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  {U32.to_nat(index(period, pos, age)) == Ring.back(q, U32.to_nat(pos), U32.to_nat(age)) : Nat}

def index_to_nat(period, pos, age, q, ep, hp, ha, h):
  +p = U32.to_nat(period)
  +x = U32.to_nat(pos)
  +a = U32.to_nat(age)
  +ea = bounded_add(pos, period, p, MNat.le_of_lt(x, p, hp), MNat.le_refl(p), h)
  +eb = bounded_add(age, 1, p, MNat.le_of_lt(a, p, ha), one_le(p, q, ep), h)
  +hs = Equal.trans(Bool, Nat.is_le(Nat.add(a, 1n), Nat.add(x, p)), Nat.is_le(1n+a, Nat.add(x, p)), True{}, Equal.cong(Nat, Bool, z => Nat.is_le(z, Nat.add(x, p)), Nat.add(a, 1n), 1n+a, MNat.add_comm(a, 1n)), MNat.le_trans(1n+a, p, Nat.add(x, p), MNat.succ_le_of_lt(a, p, ha), MNat.le_add_left(p, x)))
  +es = sub_to_nat(U32.add(pos, period), U32.add(age, 1), Nat.add(x, p), Nat.add(a, 1n), ea, eb, hs)
  Equal.trans(Nat, U32.to_nat(index(period, pos, age)), Nat.mod(U32.to_nat(U32.sub(U32.add(pos, period), U32.add(age, 1))), p), Ring.back(q, x, a), Arithmetic.mod_to_nat(U32.sub(U32.add(pos, period), U32.add(age, 1)), period),
    Equal.trans(Nat, Nat.mod(U32.to_nat(U32.sub(U32.add(pos, period), U32.add(age, 1))), p), Nat.mod(Nat.sub(Nat.add(x, p), Nat.add(a, 1n)), p), Ring.back(q, x, a), Equal.cong(Nat, Nat, z => Nat.mod(z, p), U32.to_nat(U32.sub(U32.add(pos, period), U32.add(age, 1))), Nat.sub(Nat.add(x, p), Nat.add(a, 1n)), es), index_nat_finish(p, x, a, q, ep)))

law nextsize_to_nat:
  for +period: U32
  for +size: U32
  for +q: Nat
  for ep: {U32.to_nat(period) == 1n+q : Nat}
  for hs: MNat.le(U32.to_nat(size), U32.to_nat(period))
  for h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  {U32.to_nat(U32.min(U32.add(size, 1), period)) == Nat.min(1n+U32.to_nat(size), U32.to_nat(period)) : Nat}

def nextsize_to_nat(period, size, q, ep, hs, h):
  Equal.trans(Nat, U32.to_nat(U32.min(U32.add(size, 1), period)), Nat.min(U32.to_nat(U32.add(size, 1)), U32.to_nat(period)), Nat.min(1n+U32.to_nat(size), U32.to_nat(period)), MU32.u32_min_to_nat(U32.add(size, 1), period), Equal.cong(Nat, Nat, x => Nat.min(x, U32.to_nat(period)), U32.to_nat(U32.add(size, 1)), 1n+U32.to_nat(size), Equal.trans(Nat, U32.to_nat(U32.add(size, 1)), Nat.add(U32.to_nat(size), 1n), 1n+U32.to_nat(size), bounded_add(size, 1, U32.to_nat(period), hs, one_le(U32.to_nat(period), q, ep), h), MNat.add_comm(U32.to_nat(size), 1n))))

def mod_lt(+period: U32, +a: U32, +q: Nat, +ep: {U32.to_nat(period) == 1n+q : Nat}) -> MNat.lt(U32.to_nat(U32.mod(a, period)), U32.to_nat(period)):
  %Equal.sym(Nat, U32.to_nat(period), 1n+q, ep) : MNat.lt(U32.to_nat(U32.mod(a, period)), _)
  %Equal.sym(Nat, U32.to_nat(U32.mod(a, period)), Nat.mod(U32.to_nat(a), U32.to_nat(period)), Arithmetic.mod_to_nat(a, period)) : MNat.lt(_, 1n+q)
  %Equal.sym(Nat, U32.to_nat(period), 1n+q, ep) : MNat.lt(Nat.mod(U32.to_nat(a), _), 1n+q)
  MNat.mod_lt(U32.to_nat(a), q)

def index_lt(+period: U32, +pos: U32, +age: U32, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}) -> MNat.lt(U32.to_nat(index(period, pos, age)), U32.to_nat(period)):
  mod_lt(period, U32.sub(U32.add(pos, period), U32.add(age, 1)), q, ep)

def next_lt(+period: U32, +pos: U32, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}) -> MNat.lt(U32.to_nat(next(period, pos)), U32.to_nat(period)):
  mod_lt(period, U32.add(pos, 1), q, ep)

def period_lt(+a: Nat, +p: Nat, +q: Nat, ep: {p == 1n+q : Nat}, h: MNat.lt(a, p)) -> MNat.lt(a, 1n+q):
  Equal.trans(Bool, Nat.is_lt(a, 1n+q), Nat.is_lt(a, p), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(a, x), 1n+q, p, Equal.sym(Nat, p, 1n+q, ep)), h)

def next_ring(+period: U32, +pos: U32, +q: Nat, +ep: {U32.to_nat(period) == 1n+q : Nat}, hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period)), h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))) -> {U32.to_nat(next(period, pos)) == Nat.mod(1n+U32.to_nat(pos), 1n+q) : Nat}:
  Equal.trans(Nat, U32.to_nat(next(period, pos)), Nat.mod(1n+U32.to_nat(pos), U32.to_nat(period)), Nat.mod(1n+U32.to_nat(pos), 1n+q), next_to_nat(period, pos, q, ep, hp, h), Equal.cong(Nat, Nat, x => Nat.mod(1n+U32.to_nat(pos), x), U32.to_nat(period), 1n+q, ep))

law index_newest:
  for +period: U32
  for +pos: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for +hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for +h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  {index(period, next(period, pos), 0) == pos : U32}

def index_newest(period, pos, q, ep, hp, h):
  +en = next_ring(period, pos, q, ep, hp, h)
  +hz = MNat.lt_of_succ_le(0n, U32.to_nat(period), one_le(U32.to_nat(period), q, ep))
  +ei = index_to_nat(period, next(period, pos), 0, q, ep, next_lt(period, pos, q, ep), hz, h)
  MU32.u32_to_nat_inj(index(period, next(period, pos), 0), pos,
    Equal.trans(Nat, U32.to_nat(index(period, next(period, pos), 0)), Ring.back(q, U32.to_nat(next(period, pos)), 0n), U32.to_nat(pos), ei,
      Equal.trans(Nat, Ring.back(q, U32.to_nat(next(period, pos)), 0n), Ring.back(q, Nat.mod(1n+U32.to_nat(pos), 1n+q), 0n), U32.to_nat(pos), Equal.cong(Nat, Nat, x => Ring.back(q, x, 0n), U32.to_nat(next(period, pos)), Nat.mod(1n+U32.to_nat(pos), 1n+q), en), Ring.back_newest(q, U32.to_nat(pos), period_lt(U32.to_nat(pos), U32.to_nat(period), q, ep, hp)))))

def under_period(+a: Nat, +p: Nat, +q: Nat, ep: {p == 1n+q : Nat}, h: MNat.lt(a, 1n+q)) -> MNat.lt(a, p):
  Equal.trans(Bool, Nat.is_lt(a, p), Nat.is_lt(a, 1n+q), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(a, x), p, 1n+q, ep), h)

def increment_nat(+period: U32, +age: U32, +q: Nat, ep: {U32.to_nat(period) == 1n+q : Nat}, ha: MNat.le(U32.to_nat(age), U32.to_nat(period)), h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))) -> {U32.to_nat(U32.add(age, 1)) == 1n+U32.to_nat(age) : Nat}:
  Equal.trans(Nat, U32.to_nat(U32.add(age, 1)), Nat.add(U32.to_nat(age), 1n), 1n+U32.to_nat(age), bounded_add(age, 1, U32.to_nat(period), ha, one_le(U32.to_nat(period), q, ep), h), MNat.add_comm(U32.to_nat(age), 1n))

law index_shift:
  for +period: U32
  for +pos: U32
  for +age: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for +hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for +ha: MNat.lt(U32.to_nat(age), q)
  for +h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  {index(period, next(period, pos), U32.add(age, 1)) == index(period, pos, age) : U32}

def index_shift(period, pos, age, q, ep, hp, ha, h):
  +ap = under_period(U32.to_nat(age), U32.to_nat(period), q, ep, MNat.lt_of_lt_of_le(U32.to_nat(age), q, 1n+q, ha, MNat.le_succ(q)))
  +ea = increment_nat(period, age, q, ep, MNat.le_of_lt(U32.to_nat(age), U32.to_nat(period), ap), h)
  +anp = Equal.trans(Bool, Nat.is_lt(U32.to_nat(U32.add(age, 1)), U32.to_nat(period)), Nat.is_lt(1n+U32.to_nat(age), U32.to_nat(period)), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(x, U32.to_nat(period)), U32.to_nat(U32.add(age, 1)), 1n+U32.to_nat(age), ea), under_period(1n+U32.to_nat(age), U32.to_nat(period), q, ep, ha))
  +ei = index_to_nat(period, next(period, pos), U32.add(age, 1), q, ep, next_lt(period, pos, q, ep), anp, h)
  +en = next_ring(period, pos, q, ep, hp, h)
  +er = index_to_nat(period, pos, age, q, ep, hp, ap, h)
  MU32.u32_to_nat_inj(index(period, next(period, pos), U32.add(age, 1)), index(period, pos, age),
    Equal.trans(Nat, U32.to_nat(index(period, next(period, pos), U32.add(age, 1))), Ring.back(q, U32.to_nat(next(period, pos)), U32.to_nat(U32.add(age, 1))), U32.to_nat(index(period, pos, age)), ei,
      Equal.trans(Nat, Ring.back(q, U32.to_nat(next(period, pos)), U32.to_nat(U32.add(age, 1))), Ring.back(q, Nat.mod(1n+U32.to_nat(pos), 1n+q), 1n+U32.to_nat(age)), U32.to_nat(index(period, pos, age)),
        Equal.trans(Nat, Ring.back(q, U32.to_nat(next(period, pos)), U32.to_nat(U32.add(age, 1))), Ring.back(q, Nat.mod(1n+U32.to_nat(pos), 1n+q), U32.to_nat(U32.add(age, 1))), Ring.back(q, Nat.mod(1n+U32.to_nat(pos), 1n+q), 1n+U32.to_nat(age)), Equal.cong(Nat, Nat, x => Ring.back(q, x, U32.to_nat(U32.add(age, 1))), U32.to_nat(next(period, pos)), Nat.mod(1n+U32.to_nat(pos), 1n+q), en), Equal.cong(Nat, Nat, x => Ring.back(q, Nat.mod(1n+U32.to_nat(pos), 1n+q), x), U32.to_nat(U32.add(age, 1)), 1n+U32.to_nat(age), ea)),
        Equal.trans(Nat, Ring.back(q, Nat.mod(1n+U32.to_nat(pos), 1n+q), 1n+U32.to_nat(age)), Ring.back(q, U32.to_nat(pos), U32.to_nat(age)), U32.to_nat(index(period, pos, age)), Ring.back_shift(q, U32.to_nat(pos), U32.to_nat(age), period_lt(U32.to_nat(pos), U32.to_nat(period), q, ep, hp), ha), Equal.sym(Nat, U32.to_nat(index(period, pos, age)), Ring.back(q, U32.to_nat(pos), U32.to_nat(age)), er)))))

law index_ne_write:
  for +period: U32
  for +pos: U32
  for +age: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for +ha: MNat.lt(U32.to_nat(age), q)
  for h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  for e: {index(period, pos, age) == pos : U32}
  Empty

def index_ne_write(period, pos, age, q, ep, hp, ha, h, e):
  +ei = index_to_nat(period, pos, age, q, ep, hp, under_period(U32.to_nat(age), U32.to_nat(period), q, ep, MNat.lt_of_lt_of_le(U32.to_nat(age), q, 1n+q, ha, MNat.le_succ(q))), h)
  Ring.back_ne_write(q, U32.to_nat(pos), U32.to_nat(age), ha, Equal.trans(Nat, Ring.back(q, U32.to_nat(pos), U32.to_nat(age)), U32.to_nat(index(period, pos, age)), U32.to_nat(pos), Equal.sym(Nat, U32.to_nat(index(period, pos, age)), Ring.back(q, U32.to_nat(pos), U32.to_nat(age)), ei), Equal.cong(U32, Nat, U32.to_nat, index(period, pos, age), pos, e)))

def predecessor_exact(+age: U32, +q: Nat, e: {U32.to_nat(age) == 1n+q : Nat}) -> {U32.to_nat(U32.sub(age, 1)) == q : Nat}:
  Equal.trans(Nat, U32.to_nat(U32.sub(age, 1)), Nat.sub(q, 0n), q, sub_to_nat(age, 1, 1n+q, 1n, e, {==}, MNat.succ_le_succ(0n, q, MNat.zero_le(q))), MNat.sub_zero(q))

law index_oldest:
  for +period: U32
  for +pos: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for +hp: MNat.lt(U32.to_nat(pos), U32.to_nat(period))
  for h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  {index(period, pos, U32.sub(period, 1)) == pos : U32}

def index_oldest(period, pos, q, ep, hp, h):
  +ea = predecessor_exact(period, q, ep)
  +ha = Equal.trans(Bool, Nat.is_lt(U32.to_nat(U32.sub(period, 1)), U32.to_nat(period)), Nat.is_lt(q, U32.to_nat(period)), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(x, U32.to_nat(period)), U32.to_nat(U32.sub(period, 1)), q, ea), under_period(q, U32.to_nat(period), q, ep, MNat.lt_succ_self(q)))
  +ei = index_to_nat(period, pos, U32.sub(period, 1), q, ep, hp, ha, h)
  MU32.u32_to_nat_inj(index(period, pos, U32.sub(period, 1)), pos,
    Equal.trans(Nat, U32.to_nat(index(period, pos, U32.sub(period, 1))), Ring.back(q, U32.to_nat(pos), U32.to_nat(U32.sub(period, 1))), U32.to_nat(pos), ei,
      Equal.trans(Nat, Ring.back(q, U32.to_nat(pos), U32.to_nat(U32.sub(period, 1))), Ring.back(q, U32.to_nat(pos), q), U32.to_nat(pos), Equal.cong(Nat, Nat, x => Ring.back(q, U32.to_nat(pos), x), U32.to_nat(U32.sub(period, 1)), q, ea), Ring.back_oldest(q, U32.to_nat(pos), period_lt(U32.to_nat(pos), U32.to_nat(period), q, ep, hp)))))

def predecessor_nat_core(+age: U32, +a: Nat, +e: {U32.to_nat(age) == a : Nat}, h: {Nat.is_eq(a, 0n) == False{} : Bool}) -> {U32.to_nat(age) == 1n+U32.to_nat(U32.sub(age, 1)) : Nat}:
  match a:
    case 0n:
      Empty.absurd({U32.to_nat(age) == 1n+U32.to_nat(U32.sub(age, 1)) : Nat}, MNat.internal_false_ne_true(Equal.sym(Bool, True{}, False{}, h)))
    case 1n+q:
      Equal.trans(Nat, U32.to_nat(age), 1n+q, 1n+U32.to_nat(U32.sub(age, 1)), e, Equal.cong(Nat, Nat, x => 1n+x, q, U32.to_nat(U32.sub(age, 1)), Equal.sym(Nat, U32.to_nat(U32.sub(age, 1)), q, predecessor_exact(age, q, e))))

law predecessor_nat:
  for +age: U32
  for h: {U32.is_eq(age, 0) == False{} : Bool}
  {U32.to_nat(age) == 1n+U32.to_nat(U32.sub(age, 1)) : Nat}

def predecessor_nat(age, h):
  predecessor_nat_core(age, U32.to_nat(age), {==}, Equal.trans(Bool, Nat.is_eq(U32.to_nat(age), 0n), U32.is_eq(age, 0), False{}, Equal.sym(Bool, U32.is_eq(age, 0), Nat.is_eq(U32.to_nat(age), 0n), MU32.u32_is_eq_to_nat(age, 0)), h))

law predecessor_successor:
  for +period: U32
  for +age: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for ha: MNat.le(U32.to_nat(age), U32.to_nat(period))
  for h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  for +hz: {U32.is_eq(age, 0) == False{} : Bool}
  {U32.add(U32.sub(age, 1), 1) == age : U32}

def predecessor_successor(period, age, q, ep, ha, h, hz):
  +ea = predecessor_nat(age, hz)
  +hs = MNat.le_trans(U32.to_nat(U32.sub(age, 1)), U32.to_nat(age), U32.to_nat(period), Equal.trans(Bool, Nat.is_le(U32.to_nat(U32.sub(age, 1)), U32.to_nat(age)), Nat.is_le(U32.to_nat(U32.sub(age, 1)), 1n+U32.to_nat(U32.sub(age, 1))), True{}, Equal.cong(Nat, Bool, x => Nat.is_le(U32.to_nat(U32.sub(age, 1)), x), U32.to_nat(age), 1n+U32.to_nat(U32.sub(age, 1)), ea), MNat.le_succ(U32.to_nat(U32.sub(age, 1)))), ha)
  MU32.u32_to_nat_inj(U32.add(U32.sub(age, 1), 1), age, Equal.trans(Nat, U32.to_nat(U32.add(U32.sub(age, 1), 1)), 1n+U32.to_nat(U32.sub(age, 1)), U32.to_nat(age), increment_nat(period, U32.sub(age, 1), q, ep, hs, h), Equal.sym(Nat, U32.to_nat(age), 1n+U32.to_nat(U32.sub(age, 1)), ea)))

law predecessor_available:
  for +period: U32
  for +size: U32
  for +age: U32
  for +q: Nat
  for +ep: {U32.to_nat(period) == 1n+q : Nat}
  for hs: MNat.le(U32.to_nat(size), U32.to_nat(period))
  for h: MNat.le(U32.to_nat(period), Nat.pow(2n, 30n))
  for hz: {U32.is_eq(age, 0) == False{} : Bool}
  for available: {U32.is_lt(age, U32.min(U32.add(size, 1), period)) == True{} : Bool}
  {U32.is_lt(U32.sub(age, 1), size) == True{} : Bool}

def predecessor_available(period, size, age, q, ep, hs, h, hz, available):
  +a = U32.to_nat(age)
  +s = U32.to_nat(size)
  +p = U32.to_nat(period)
  +ea = predecessor_nat(age, hz)
  +es = nextsize_to_nat(period, size, q, ep, hs, h)
  +hn = Equal.trans(Bool, Nat.is_lt(a, U32.to_nat(U32.min(U32.add(size, 1), period))), U32.is_lt(age, U32.min(U32.add(size, 1), period)), True{}, Equal.sym(Bool, U32.is_lt(age, U32.min(U32.add(size, 1), period)), Nat.is_lt(a, U32.to_nat(U32.min(U32.add(size, 1), period))), MU32.u32_is_lt_to_nat(age, U32.min(U32.add(size, 1), period))), available)
  +hm = Equal.trans(Bool, Nat.is_lt(a, Nat.min(1n+s, p)), Nat.is_lt(a, U32.to_nat(U32.min(U32.add(size, 1), period))), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(a, x), Nat.min(1n+s, p), U32.to_nat(U32.min(U32.add(size, 1), period)), Equal.sym(Nat, U32.to_nat(U32.min(U32.add(size, 1), period)), Nat.min(1n+s, p), es)), hn)
  +hl = MNat.lt_of_lt_of_le(a, Nat.min(1n+s, p), 1n+s, hm, MNat.min_le_left(1n+s, p))
  +hp = Equal.trans(Bool, Nat.is_lt(1n+U32.to_nat(U32.sub(age, 1)), 1n+s), Nat.is_lt(a, 1n+s), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(x, 1n+s), 1n+U32.to_nat(U32.sub(age, 1)), a, Equal.sym(Nat, a, 1n+U32.to_nat(U32.sub(age, 1)), ea)), hl)
  Equal.trans(Bool, U32.is_lt(U32.sub(age, 1), size), Nat.is_lt(U32.to_nat(U32.sub(age, 1)), s), True{}, MU32.u32_is_lt_to_nat(U32.sub(age, 1), size), hp)
