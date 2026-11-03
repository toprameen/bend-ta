import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat
import bend-mathlib@0.8.1.0/u32.bend as MU32

def mod_unique(+q: Nat, +b: Nat, +r: Nat, -a: Nat,
  e: {Nat.add(Nat.mul(q, b), r) == a : Nat}, h: MNat.lt(r, b)
) -> {r == Nat.mod(a, b) : Nat}:
  %e : {r == Nat.mod(_, b) : Nat}
  %MNat.add_comm(r, Nat.mul(q, b)) : {r == Nat.mod(_, b) : Nat}
  %MNat.add_mul_mod_self_right_sym(r, b, q) : {r == _ : Nat}
  Equal.sym(Nat, Nat.mod(r, b), r, MNat.mod_eq_of_lt(r, b, h))

def mod_fin(+b: U32, -a: Nat, qr: Word(32n) & U32,
  inv: MU32.internal_dm_inv(32n, U32.to_nat(b), a, qr)
) -> {U32.to_nat(U32.mod.fin(qr)) == Nat.mod(a, U32.to_nat(b)) : Nat}:
  match qr:
    case (q, r):
      match inv:
        case (e, h):
          mod_unique(Word.to_nat(32n, q), U32.to_nat(b), U32.to_nat(r), a, e, h)

def mod_if(+aw: Word(32n), +bw: Word(32n), z: Bool,
  ez: {U32.is_zero(U32{bw}) == z : Bool}
) -> {U32.to_nat(U32.mod.if(aw, U32{bw}, z)) == Nat.mod(Word.to_nat(32n, aw), Word.to_nat(32n, bw)) : Nat}:
  match z:
    case True{}:
      +bn = Word.to_nat(32n, bw)
      +ee = Equal.trans(Bool, Nat.is_eq(bn, 0n), U32.is_zero(U32{bw}), True{},
        Equal.sym(Bool, U32.is_zero(U32{bw}), Nat.is_eq(bn, 0n), MU32.u32_is_eq_to_nat(U32{bw}, 0)), ez)
      %Equal.sym(Nat, bn, 0n, MNat.eq_of_is_eq(bn, 0n, ee)) : {Word.to_nat(32n, aw) == Nat.mod(Word.to_nat(32n, aw), _) : Nat}
      {==}
    case False{}:
      +bn = Word.to_nat(32n, bw)
      +ee = Equal.trans(Bool, Nat.is_eq(bn, 0n), U32.is_zero(U32{bw}), False{},
        Equal.sym(Bool, U32.is_zero(U32{bw}), Nat.is_eq(bn, 0n), MU32.u32_is_eq_to_nat(U32{bw}, 0)), ez)
      +hb = MNat.pos_of_ne_zero(bn, ee)
      mod_fin(U32{bw}, Word.to_nat(32n, aw), U32.divmod.go(32n, aw, U32{bw}),
        MU32.internal_dm_go(32n, aw, U32{bw}, hb, Nat.pow(2n, 32n), {==}))

law mod_to_nat:
  for a: U32
  for b: U32
  {U32.to_nat(U32.mod(a, b)) == Nat.mod(U32.to_nat(a), U32.to_nat(b)) : Nat}

def mod_to_nat(a, b):
  match a b:
    case U32{aw} U32{+bw}:
      mod_if(aw, bw, U32.is_zero(U32{bw}), {==})
