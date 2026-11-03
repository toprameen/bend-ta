import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat
import bend-mathlib@0.8.1.0/u32.bend as MU32

def bit(b: Bool) -> Nat:
  Bool.pick(Nat, b, 1n, 0n)

def shl_out_con_snd(+p: Nat, c: Bool, result: Bool & Word(p)) -> {WCon{c, Pair.snd(Bool, Word(p), result)} == Pair.snd(Bool, Word(1n+p), Word.shl.out.con(p, c, result)) : Word(1n+p)}:
  match result:
    case (carry, out):
      {==}

law shl_put_out:
  for +n: Nat
  for +c: Bool
  for +w: Word(n)
  {Word.shl.put(n, c, w) == Pair.snd(Bool, Word(n), Word.shl.out(n, c, w)) : Word(n)}

def shl_put_out(n, c, w):
  match n:
    case 0n:
      {==}
    case 1n++p:
      match w:
        case WCon{+b, +t}:
          %shl_out_con_snd(p, c, Word.shl.out(p, b, t)) : {WCon{c, Word.shl.put(p, b, t)} == _ : Word(1n+p)}
          %shl_put_out(p, b, t) : {WCon{c, Word.shl.put(p, b, t)} == WCon{c, _} : Word(1n+p)}
          {==}

law shl_out:
  for +n: Nat
  for +w: Word(n)
  {Word.shl(n, w) == Pair.snd(Bool, Word(n), Word.shl.out(n, False{}, w)) : Word(n)}

def shl_out(n, w):
  match n:
    case 0n:
      {==}
    case 1n++p:
      match w:
        case WCon{+b, +t}:
          %shl_out_con_snd(p, False{}, Word.shl.out(p, b, t)) : {WCon{False{}, Word.shl.put(p, b, t)} == _ : Word(1n+p)}
          %shl_put_out(p, b, t) : {WCon{False{}, Word.shl.put(p, b, t)} == WCon{False{}, _} : Word(1n+p)}
          {==}

def shl_exact_result(+n: Nat, +w: Word(n), result: Bool & Word(n),
  e: {MU32.internal_shl_val(n, Nat.pow(2n, n), result) == Nat.double(Word.to_nat(n, w)) : Nat},
  h: MNat.lt(Nat.double(Word.to_nat(n, w)), Nat.pow(2n, n))
) -> {Word.to_nat(n, Pair.snd(Bool, Word(n), result)) == Nat.double(Word.to_nat(n, w)) : Nat}:
  match result:
    case (carry, out):
      MU32.internal_fin_exact(Word.to_nat(n, out), Nat.double(Word.to_nat(n, w)), Nat.pow(2n, n), carry, e, h)

law shl_exact:
  for +n: Nat
  for +w: Word(n)
  for h: MNat.lt(Nat.double(Word.to_nat(n, w)), Nat.pow(2n, n))
  {Word.to_nat(n, Word.shl(n, w)) == Nat.double(Word.to_nat(n, w)) : Nat}

def shl_exact(n, w, h):
  %Equal.sym(Word(n), Word.shl(n, w), Pair.snd(Bool, Word(n), Word.shl.out(n, False{}, w)), shl_out(n, w)) : {Word.to_nat(n, _) == Nat.double(Word.to_nat(n, w)) : Nat}
  shl_exact_result(n, w, Word.shl.out(n, False{}, w), MU32.internal_shl_out(n, False{}, w), h)

def u32_shl_exact_inner(-m: Nat, n: U32, e: {Nat.pow(2n, 32n) == m : Nat},
  h: MNat.lt(Nat.double(U32.to_nat(n)), m)
) -> {U32.to_nat(U32.shl(n)) == Nat.double(U32.to_nat(n)) : Nat}:
  match n:
    case U32{+w}:
      shl_exact(32n, w, MU32.internal_bound(Nat.double(Word.to_nat(32n, w)), m, e, h))

law u32_shl_exact:
  for +n: U32
  for h: MNat.lt(Nat.double(U32.to_nat(n)), Nat.pow(2n, 32n))
  {U32.to_nat(U32.shl(n)) == Nat.double(U32.to_nat(n)) : Nat}

def u32_shl_exact(n, h):
  u32_shl_exact_inner(Nat.pow(2n, 32n), n, {==}, h)

law double_lt_cancel:
  for +a: Nat
  for +b: Nat
  for h: MNat.lt(Nat.double(a), Nat.double(b))
  MNat.lt(a, b)

def double_lt_cancel_inner(+a: Nat, +b: Nat, h: MNat.lt(Nat.double(a), Nat.double(b))) -> MNat.lt(Nat.mul(2n, a), Nat.mul(2n, b)):
  %MNat.double_eq_two_mul(a) : MNat.lt(_, Nat.mul(2n, b))
  %MNat.double_eq_two_mul(b) : MNat.lt(Nat.double(a), _)
  h

def double_lt_cancel(a, b, h):
  MNat.lt_of_mul_lt_mul_left(2n, a, b, double_lt_cancel_inner(a, b, h))

def lowmask(n: Nat, d: Nat) -> Word(n):
  match n d:
    case 0n _:
      WNil{}
    case 1n+p 0n:
      WCon{False{}, Word.zero(p)}
    case 1n+p 1n+q:
      WCon{True{}, lowmask(p, q)}

law and_zero:
  for +n: Nat
  for w: Word(n)
  {Word.and(n, w, Word.zero(n)) == Word.zero(n) : Word(n)}

def and_zero(n, w):
  match n:
    case 0n:
      {==}
    case 1n++p:
      match w:
        case WCon{b, t}:
          match b:
            case False{}:
              Equal.cong(Word(p), Word(1n+p), x => WCon{False{}, x}, Word.and(p, t, Word.zero(p)), Word.zero(p), and_zero(p, t))
            case True{}:
              Equal.cong(Word(p), Word(1n+p), x => WCon{False{}, x}, Word.and(p, t, Word.zero(p)), Word.zero(p), and_zero(p, t))

law lt_one_zero:
  for n: Nat
  for h: MNat.lt(n, 1n)
  {n == 0n : Nat}

def lt_one_zero(n, h):
  match n:
    case 0n:
      {==}
    case 1n+p:
      Empty.absurd({1n+p == 0n : Nat}, MNat.lt_zero(p)(h))

law bit_double_lt:
  for b: Bool
  for +x: Nat
  for +y: Nat
  for h: MNat.lt(Nat.add(bit(b), Nat.double(x)), Nat.double(y))
  MNat.lt(x, y)

def bit_double_lt(b, x, y, h):
  match b:
    case False{}:
      double_lt_cancel(x, y, h)
    case True{}:
      double_lt_cancel(x, y, MNat.lt_trans(Nat.double(x), 1n+Nat.double(x), Nat.double(y), MNat.lt_succ_self(Nat.double(x)), h))

law and_lowmask:
  for +n: Nat
  for d: Nat
  for +w: Word(n)
  for h: MNat.lt(Word.to_nat(n, w), Nat.pow(2n, d))
  {Word.and(n, w, lowmask(n, d)) == w : Word(n)}

def and_lowmask(n, d, w, h):
  match n d:
    case 0n _:
      match w:
        case WNil{}:
          {==}
    case 1n++p 0n:
      %Equal.sym(Word(1n+p), w, Word.zero(1n+p), MU32.word_to_nat_inj(1n+p, w, Word.zero(1n+p),
        Equal.trans(Nat, Word.to_nat(1n+p, w), 0n, Word.to_nat(1n+p, Word.zero(1n+p)), lt_one_zero(Word.to_nat(1n+p, w), h), MU32.word_to_nat_zero_sym(1n+p)))) : {Word.and(1n+p, w, Word.zero(1n+p)) == _ : Word(1n+p)}
      and_zero(1n+p, w)
    case 1n++p 1n++q:
      match w:
        case WCon{False{}, +t}:
          Equal.cong(Word(p), Word(1n+p), x => WCon{False{}, x}, Word.and(p, t, lowmask(p, q)), t,
            and_lowmask(p, q, t, bit_double_lt(False{}, Word.to_nat(p, t), Nat.pow(2n, q),
              Equal.trans(Bool, Nat.is_lt(Nat.double(Word.to_nat(p, t)), Nat.double(Nat.pow(2n, q))), Nat.is_lt(Nat.double(Word.to_nat(p, t)), Nat.pow(2n, 1n+q)), True{},
                Equal.cong(Nat, Bool, x => Nat.is_lt(Nat.double(Word.to_nat(p, t)), x), Nat.double(Nat.pow(2n, q)), Nat.pow(2n, 1n+q), MNat.two_pow_succ_sym(q)), h))))
        case WCon{True{}, +t}:
          Equal.cong(Word(p), Word(1n+p), x => WCon{True{}, x}, Word.and(p, t, lowmask(p, q)), t,
            and_lowmask(p, q, t, bit_double_lt(True{}, Word.to_nat(p, t), Nat.pow(2n, q),
              Equal.trans(Bool, Nat.is_lt(1n+Nat.double(Word.to_nat(p, t)), Nat.double(Nat.pow(2n, q))), Nat.is_lt(1n+Nat.double(Word.to_nat(p, t)), Nat.pow(2n, 1n+q)), True{},
                Equal.cong(Nat, Bool, x => Nat.is_lt(1n+Nat.double(Word.to_nat(p, t)), x), Nat.double(Nat.pow(2n, q)), Nat.pow(2n, 1n+q), MNat.two_pow_succ_sym(q)), h))))

law lowmask_value:
  for +n: Nat
  for +d: Nat
  for h: MNat.le(d, n)
  {1n+Word.to_nat(n, lowmask(n, d)) == Nat.pow(2n, d) : Nat}

def lowmask_value(n, d, h):
  match n d:
    case 0n 0n:
      {==}
    case 0n 1n+q:
      Empty.absurd({1n == Nat.pow(2n, 1n+q) : Nat}, MNat.internal_false_ne_true(h))
    case 1n++p 0n:
      Equal.cong(Nat, Nat, x => 1n+Nat.double(x), Word.to_nat(p, Word.zero(p)), 0n, MU32.word_to_nat_zero(p))
    case 1n++p 1n++q:
      Equal.trans(Nat, 2n+Nat.double(Word.to_nat(p, lowmask(p, q))), Nat.double(Nat.pow(2n, q)), Nat.pow(2n, 1n+q),
        Equal.cong(Nat, Nat, x => Nat.double(x), 1n+Word.to_nat(p, lowmask(p, q)), Nat.pow(2n, q), lowmask_value(p, q, h)), MNat.two_pow_succ_sym(q))

law succ_sub:
  for +a: Nat
  for -b: Nat
  for e: {1n+a == b : Nat}
  {a == Nat.sub(b, 1n) : Nat}

def succ_sub(a, b, e):
  %e : {a == Nat.sub(_, 1n) : Nat}
  MNat.sub_zero_sym(a)

law lowmask_sub:
  for +n: Nat
  for +d: Nat
  for h: MNat.le(d, n)
  {Word.to_nat(n, lowmask(n, d)) == Nat.sub(Nat.pow(2n, d), 1n) : Nat}

def lowmask_sub(n, d, h):
  succ_sub(Word.to_nat(n, lowmask(n, d)), Nat.pow(2n, d), lowmask_value(n, d, h))

def and_u32_lowmask(+i: U32, +d: Nat, h: MNat.lt(U32.to_nat(i), Nat.pow(2n, d))) -> {U32.and(i, U32{lowmask(32n, d)}) == i : U32}:
  match i:
    case U32{+w}:
      Equal.cong(Word(32n), U32, x => U32{x}, Word.and(32n, w, lowmask(32n, d)), w, and_lowmask(32n, d, w, h))

def mask_identity_inner(+m: Nat, +c: U32, +d: Nat, +i: U32,
  hd: MNat.le(d, 32n), +ec: {U32.to_nat(c) == m : Nat}, +em: {Nat.pow(2n, d) == m : Nat},
  hc: MNat.le(1n, m), hi: MNat.lt(U32.to_nat(i), m)
) -> {U32.and(i, U32.sub(c, 1)) == i : U32}:
  +hsub = MU32.u32_sub_exact(c, 1, Equal.trans(Bool, Nat.is_le(1n, U32.to_nat(c)), Nat.is_le(1n, m), True{}, Equal.cong(Nat, Bool, x => Nat.is_le(1n, x), U32.to_nat(c), m, ec), hc))
  +esub = Equal.trans(Nat, U32.to_nat(U32.sub(c, 1)), Nat.sub(U32.to_nat(c), 1n), Nat.sub(m, 1n), hsub, Equal.cong(Nat, Nat, x => Nat.sub(x, 1n), U32.to_nat(c), m, ec))
  +emask = Equal.trans(Nat, Word.to_nat(32n, lowmask(32n, d)), Nat.sub(Nat.pow(2n, d), 1n), Nat.sub(m, 1n), lowmask_sub(32n, d, hd), Equal.cong(Nat, Nat, x => Nat.sub(x, 1n), Nat.pow(2n, d), m, em))
  +e = MU32.u32_to_nat_inj(U32{lowmask(32n, d)}, U32.sub(c, 1), Equal.trans(Nat, Word.to_nat(32n, lowmask(32n, d)), Nat.sub(m, 1n), U32.to_nat(U32.sub(c, 1)), emask, Equal.sym(Nat, U32.to_nat(U32.sub(c, 1)), Nat.sub(m, 1n), esub)))
  %e : {U32.and(i, _) == i : U32}
  and_u32_lowmask(i, d,
    Equal.trans(Bool, Nat.is_lt(U32.to_nat(i), Nat.pow(2n, d)), Nat.is_lt(U32.to_nat(i), m), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(U32.to_nat(i), x), Nat.pow(2n, d), m, em), hi))

law mask_identity:
  for +c: U32
  for +d: Nat
  for +i: U32
  for hd: MNat.le(d, 32n)
  for ec: {U32.to_nat(c) == Nat.pow(2n, d) : Nat}
  for hi: MNat.lt(U32.to_nat(i), Nat.pow(2n, d))
  {U32.and(i, U32.sub(c, 1)) == i : U32}

def mask_identity(c, d, i, hd, ec, hi):
  mask_identity_inner(Nat.pow(2n, d), c, d, i, hd, ec, {==}, MNat.one_le_pow(d, 1n), hi)

law shr_pad_value:
  for +n: Nat
  for w: Word(n)
  {Word.to_nat(1n+n, Word.shr.pad(n, w)) == Word.to_nat(n, w) : Nat}

def shr_pad_value(n, w):
  match n:
    case 0n:
      {==}
    case 1n++p:
      match w:
        case WCon{False{}, t}:
          Equal.cong(Nat, Nat, x => Nat.double(x), Word.to_nat(1n+p, Word.shr.pad(p, t)), Word.to_nat(p, t), shr_pad_value(p, t))
        case WCon{True{}, t}:
          Equal.cong(Nat, Nat, x => 1n+Nat.double(x), Word.to_nat(1n+p, Word.shr.pad(p, t)), Word.to_nat(p, t), shr_pad_value(p, t))

law bit_double_div:
  for b: Bool
  for +n: Nat
  {Nat.div(Nat.add(bit(b), Nat.double(n)), 2n) == n : Nat}

def bit_double_div(b, n):
  match b:
    case False{}:
      %MNat.double_eq_two_mul_sym(n) : {Nat.div(_, 2n) == n : Nat}
      MNat.mul_div_cancel_left(n, 1n)
    case True{}:
      %MNat.double_eq_two_mul_sym(n) : {Nat.div(1n+_, 2n) == n : Nat}
      %MNat.add_mul_div_left_sym(1n, n, 1n) : {_ == n : Nat}
      {==}

law shr_value:
  for +n: Nat
  for +w: Word(n)
  {Word.to_nat(n, Word.shr(n, w)) == Nat.div(Word.to_nat(n, w), 2n) : Nat}

def shr_value(n, w):
  match n:
    case 0n:
      {==}
    case 1n++p:
      match w:
        case WCon{False{}, +t}:
          Equal.trans(Nat, Word.to_nat(1n+p, Word.shr.pad(p, t)), Word.to_nat(p, t), Nat.div(Nat.double(Word.to_nat(p, t)), 2n), shr_pad_value(p, t), Equal.sym(Nat, Nat.div(Nat.double(Word.to_nat(p, t)), 2n), Word.to_nat(p, t), bit_double_div(False{}, Word.to_nat(p, t))))
        case WCon{True{}, +t}:
          Equal.trans(Nat, Word.to_nat(1n+p, Word.shr.pad(p, t)), Word.to_nat(p, t), Nat.div(1n+Nat.double(Word.to_nat(p, t)), 2n), shr_pad_value(p, t), Equal.sym(Nat, Nat.div(1n+Nat.double(Word.to_nat(p, t)), 2n), Word.to_nat(p, t), bit_double_div(True{}, Word.to_nat(p, t))))

law u32_shr_value:
  for n: U32
  {U32.to_nat(U32.shr(n)) == Nat.div(U32.to_nat(n), 2n) : Nat}

def u32_shr_value(n):
  match n:
    case U32{w}:
      shr_value(32n, w)
