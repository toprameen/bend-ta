import Base
import bend-mathlib@0.8.1.0/nat.bend as MNat
import bend-mathlib@0.8.1.0/u32.bend as MU32
import ../src/core/ema.bend as Ema
import ../src/core/sma.bend as Sma
import ./configuration.bend as Configuration
import ../src/core/window.bend as Window
import ../src/core/rolling.bend as Rolling


def bounded(period: U32, -m: Nat, em: {Nat.pow(2n, 32n) == m : Nat}) -> MNat.lt(U32.to_nat(period), m):
  match period:
    case U32{word}:
      %em : MNat.lt(Word.to_nat(32n, word), _)
      MU32.word_to_nat_lt(32n, word)

def add_one(+n: Nat) -> {Nat.add(n, 1n) == 1n+n : Nat}:
  Equal.trans(Nat, Nat.add(n, 1n), 1n+Nat.add(n, 0n), 1n+n, MNat.add_succ(n, 0n), Equal.cong(Nat, Nat, x => 1n+x, Nat.add(n, 0n), n, MNat.add_zero(n)))

def increment_aux(+seen: U32, +period: U32, +m: Nat, em: {Nat.pow(2n, 32n) == m : Nat}, hp: MNat.lt(U32.to_nat(period), m), before: MNat.lt(U32.to_nat(seen), U32.to_nat(period))) -> {U32.to_nat(U32.add(seen, 1)) == 1n+U32.to_nat(seen) : Nat}:
  bound = MNat.lt_of_le_of_lt(1n+U32.to_nat(seen), U32.to_nat(period), m, MNat.succ_le_of_lt(U32.to_nat(seen), U32.to_nat(period), before), hp)
  sum_bound = Equal.trans(Bool, Nat.is_lt(Nat.add(U32.to_nat(seen), 1n), m), Nat.is_lt(1n+U32.to_nat(seen), m), True{}, Equal.cong(Nat, Bool, x => Nat.is_lt(x, m), Nat.add(U32.to_nat(seen), 1n), 1n+U32.to_nat(seen), add_one(U32.to_nat(seen))), bound)

  Equal.trans(Nat, U32.to_nat(U32.add(seen, 1)), Nat.add(U32.to_nat(seen), 1n), 1n+U32.to_nat(seen), MU32.internal_u32_add_exact(m, seen, 1, em, sum_bound), add_one(U32.to_nat(seen)))

def increment(+seen: U32, +period: U32, before: MNat.lt(U32.to_nat(seen), U32.to_nat(period))) -> {U32.to_nat(U32.add(seen, 1)) == 1n+U32.to_nat(seen) : Nat}:
  increment_aux(seen, period, Nat.pow(2n, 32n), {==}, bounded(period, Nat.pow(2n, 32n), {==}), before)


law ema_live_one:
  for ~N: Data
  for ~from_u32: U32 -> N
  for ~add: N -> N -> N
  for ~sub: N -> N -> N
  for ~mul: N -> N -> N
  for ~div: N -> N -> N
  for alpha: N
  for previous: N
  for price: N
  {Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Ema.Live{1, alpha, previous}, price) == (Ema.Live{1, alpha, price}, Some{price}) : Ema.State<N> & Maybe<&2, N>}

def ema_live_one(N, from_u32, add, sub, mul, div, alpha, previous, price):
  {==}

law ema_first_one:
  for ~N: Data
  for ~from_u32: U32 -> N
  for ~add: N -> N -> N
  for ~sub: N -> N -> N
  for ~mul: N -> N -> N
  for ~div: N -> N -> N
  for price: N
  {Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Ema.init(~N, ~from_u32, ~div, 1), price) == (Ema.Live{1, div(from_u32(2), from_u32(2)), price}, Some{price}) : Ema.State<N> & Maybe<&2, N>}

def ema_first_one(N, from_u32, add, sub, mul, div, price):
  {==}

def is_some(-N: Data, value: Maybe<&2, N>) -> Bool:
  match value:
    case None{}: False{}
    case Some{value}: True{}

def warm(
  -N: Data, -S: Type, -step: S -> N -> S & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, -offset: Nat, -state: S
) -> Type:
  match remaining:
    case 0n:
      &next:S -> &value:N -> {step(state, prices(offset)) == (next, Some{value}) : S & Maybe<&2, N>}
    case 1n+rest:
      &next:S -> {step(state, prices(offset)) == (next, None{}) : S & Maybe<&2, N>} & (warm(N, S, step, rest, prices, 1n+offset, next))

def lt_ne(+a: Nat, +b: Nat, h: MNat.lt(a, b)) -> {Nat.is_eq(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n: Empty.absurd({Nat.is_eq(0n, 0n) == False{} : Bool}, MNat.internal_false_ne_true(h))
    case 0n 1n+bp: {==}
    case 1n+ap 0n: Empty.absurd({Nat.is_eq(1n+ap, 0n) == False{} : Bool}, MNat.internal_false_ne_true(h))
    case 1n+ap 1n+bp: lt_ne(ap, bp, h)

def eq_check(+a: U32, +b: U32, e: {U32.to_nat(a) == U32.to_nat(b) : Nat}) -> {U32.is_eq(a, b) == True{} : Bool}:
  Equal.trans(Bool, U32.is_eq(a, b), Nat.is_eq(U32.to_nat(a), U32.to_nat(b)), True{}, MU32.u32_is_eq_to_nat(a, b), Equal.trans(Bool, Nat.is_eq(U32.to_nat(a), U32.to_nat(b)), Nat.is_eq(U32.to_nat(b), U32.to_nat(b)), True{}, Equal.cong(Nat, Bool, x => Nat.is_eq(x, U32.to_nat(b)), U32.to_nat(a), U32.to_nat(b), e), MNat.is_eq_refl(U32.to_nat(b))))

def lt_check(+a: U32, +b: U32, h: MNat.lt(U32.to_nat(a), U32.to_nat(b))) -> {U32.is_eq(a, b) == False{} : Bool}:
  Equal.trans(Bool, U32.is_eq(a, b), Nat.is_eq(U32.to_nat(a), U32.to_nat(b)), False{}, MU32.u32_is_eq_to_nat(a, b), lt_ne(U32.to_nat(a), U32.to_nat(b), h))

def seen_zero(+seen: U32, h: {U32.is_zero(seen) == True{} : Bool}) -> {U32.to_nat(seen) == 0n : Nat}:
  MNat.eq_of_is_eq(U32.to_nat(seen), 0n, Equal.trans(Bool, Nat.is_eq(U32.to_nat(seen), 0n), U32.is_zero(seen), True{}, MU32.u32_is_eq_to_nat_sym(seen, 0), h))

def scheduled_before(+seen: U32, +period: U32, +rest: Nat, e: {Nat.add(U32.to_nat(seen), 1n+rest) == U32.to_nat(period) : Nat}) -> MNat.lt(U32.to_nat(seen), U32.to_nat(period)):
  %e : MNat.lt(U32.to_nat(seen), _)
  MNat.lt_add_of_pos_right(U32.to_nat(seen), rest)

def scheduled_next(+seen: U32, +period: U32, +rest: Nat, +e: {Nat.add(U32.to_nat(seen), 1n+rest) == U32.to_nat(period) : Nat}) -> {Nat.add(U32.to_nat(U32.add(seen, 1)), rest) == U32.to_nat(period) : Nat}:
  count = increment(seen, period, scheduled_before(seen, period, rest, e))
  Equal.trans(Nat, Nat.add(U32.to_nat(U32.add(seen, 1)), rest), Nat.add(1n+U32.to_nat(seen), rest), U32.to_nat(period), Equal.cong(Nat, Nat, x => Nat.add(x, rest), U32.to_nat(U32.add(seen, 1)), 1n+U32.to_nat(seen), count), Equal.trans(Nat, Nat.add(1n+U32.to_nat(seen), rest), Nat.add(U32.to_nat(seen), 1n+rest), U32.to_nat(period), Equal.trans(Nat, Nat.add(1n+U32.to_nat(seen), rest), 1n+Nat.add(U32.to_nat(seen), rest), Nat.add(U32.to_nat(seen), 1n+rest), MNat.succ_add(U32.to_nat(seen), rest), MNat.add_succ_sym(U32.to_nat(seen), rest)), e))

def scheduled_first(+seen: U32, +period: U32, +rest: Nat, e: {Nat.add(U32.to_nat(seen), 1n+rest) == U32.to_nat(period) : Nat}, zero: {U32.to_nat(seen) == 0n : Nat}) -> {Nat.add(1n, rest) == U32.to_nat(period) : Nat}:
  Equal.trans(Nat, Nat.add(1n, rest), Nat.add(U32.to_nat(seen), 1n+rest), U32.to_nat(period), Equal.cong(Nat, Nat, x => Nat.add(x, 1n+rest), 0n, U32.to_nat(seen), Equal.sym(Nat, U32.to_nat(seen), 0n, zero)), e)

def equal_u32(+a: U32, +b: U32, e: {U32.to_nat(a) == U32.to_nat(b) : Nat}) -> {a == b : U32}:
  Equal.trans(U32, a, U32.from_nat(U32.to_nat(a)), b, MU32.u32_from_nat_to_nat_sym(a), Equal.trans(U32, U32.from_nat(U32.to_nat(a)), U32.from_nat(U32.to_nat(b)), b, Equal.cong(Nat, U32, U32.from_nat, U32.to_nat(a), U32.to_nat(b), e), MU32.u32_from_nat_to_nat(b)))

def ema_first_step(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +period: U32, +seen: U32, +alpha: N, +origin: N, +sum: N, +price: N, +ready: Bool,
  first: {U32.is_zero(seen) == True{} : Bool}, test: {U32.is_eq(period, 1) == ready : Bool}
) -> {Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Ema.Seed{period, seen, alpha, origin, sum}, price) == Ema.seed.finish(~N, ~from_u32, ~add, ~div, period, 1, alpha, price, from_u32(0), ready) : Ema.State<N> & Maybe<&2, N>}:
  Equal.trans(Ema.State<N> & Maybe<&2, N>, Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Ema.Seed{period, seen, alpha, origin, sum}, price), Ema.seed.next(~N, ~from_u32, ~add, ~sub, ~div, period, seen, alpha, origin, sum, price, True{}), Ema.seed.finish(~N, ~from_u32, ~add, ~div, period, 1, alpha, price, from_u32(0), ready), Equal.cong(Bool, Ema.State<N> & Maybe<&2, N>, flag => Ema.seed.next(~N, ~from_u32, ~add, ~sub, ~div, period, seen, alpha, origin, sum, price, flag), U32.is_zero(seen), True{}, first), Equal.cong(Bool, Ema.State<N> & Maybe<&2, N>, flag => Ema.seed.finish(~N, ~from_u32, ~add, ~div, period, 1, alpha, price, from_u32(0), flag), U32.is_eq(period, 1), ready, test))

def ema_later_step(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +period: U32, +seen: U32, +alpha: N, +origin: N, +sum: N, +price: N, +ready: Bool,
  first: {U32.is_zero(seen) == False{} : Bool}, test: {U32.is_eq(U32.add(seen, 1), period) == ready : Bool}
) -> {Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Ema.Seed{period, seen, alpha, origin, sum}, price) == Ema.seed.finish(~N, ~from_u32, ~add, ~div, period, U32.add(seen, 1), alpha, origin, add(sum, sub(price, origin)), ready) : Ema.State<N> & Maybe<&2, N>}:
  Equal.trans(Ema.State<N> & Maybe<&2, N>, Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, Ema.Seed{period, seen, alpha, origin, sum}, price), Ema.seed.next(~N, ~from_u32, ~add, ~sub, ~div, period, seen, alpha, origin, sum, price, False{}), Ema.seed.finish(~N, ~from_u32, ~add, ~div, period, U32.add(seen, 1), alpha, origin, add(sum, sub(price, origin)), ready), Equal.cong(Bool, Ema.State<N> & Maybe<&2, N>, flag => Ema.seed.next(~N, ~from_u32, ~add, ~sub, ~div, period, seen, alpha, origin, sum, price, flag), U32.is_zero(seen), False{}, first), Equal.cong(Bool, Ema.State<N> & Maybe<&2, N>, flag => Ema.seed.finish(~N, ~from_u32, ~add, ~div, period, U32.add(seen, 1), alpha, origin, add(sum, sub(price, origin)), flag), U32.is_eq(U32.add(seen, 1), period), ready, test))

def eq_comm_u32(+a: U32, +b: U32) -> {U32.is_eq(a, b) == U32.is_eq(b, a) : Bool}:
  Equal.trans(Bool, U32.is_eq(a, b), Nat.is_eq(U32.to_nat(a), U32.to_nat(b)), U32.is_eq(b, a), MU32.u32_is_eq_to_nat(a, b), Equal.trans(Bool, Nat.is_eq(U32.to_nat(a), U32.to_nat(b)), Nat.is_eq(U32.to_nat(b), U32.to_nat(a)), U32.is_eq(b, a), MNat.is_eq_comm(U32.to_nat(a), U32.to_nat(b)), MU32.u32_is_eq_to_nat_sym(b, a)))

def unadd_zero(+n: Nat, +p: Nat, e: {Nat.add(n, 0n) == p : Nat}) -> {n == p : Nat}:
  Equal.trans(Nat, n, Nat.add(n, 0n), p, MNat.add_zero_sym(n), e)

def seed_mean(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, +period: U32, +origin: N, sum: N) -> N:
  Bool.pick(N, U32.is_eq(period, 1), origin, add(origin, div(sum, from_u32(period))))

def ema_warming(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~D: Data, ~sample: D -> Nat -> N,
  remaining: Nat, first: Bool, +data: D, +offset: Nat, +period: U32, +seen: U32, +alpha: N, +origin: N, +sum: N,
  +schedule: {Nat.add(U32.to_nat(seen), 1n+remaining) == U32.to_nat(period) : Nat}, +first_test: {U32.is_zero(seen) == first : Bool}
) -> warm(N, Ema.State<N>, s => x => Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, s, x), remaining, at => sample(data, at), offset, Ema.Seed{period, seen, alpha, origin, sum}):
  match remaining first:
    case 0n True{}:
      one = scheduled_first(seen, period, 0n, schedule, seen_zero(seen, first_test))
      period_one = equal_u32(period, 1, Equal.sym(Nat, 1n, U32.to_nat(period), one))
      %Equal.sym(U32, period, 1, period_one) : warm(N, Ema.State<N>, s => x => Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, s, x), 0n, at => sample(data, at), offset, Ema.Seed{_, seen, alpha, origin, sum})
      +price = sample(data, offset)
      (Ema.Live{1, alpha, price}, price, ema_first_step(~N, ~from_u32, ~add, ~sub, ~mul, ~div, 1, seen, alpha, origin, sum, price, True{}, first_test, {==}))
    case 1n++rest True{}:
      +one = scheduled_first(seen, period, 1n+rest, schedule, seen_zero(seen, first_test))
      test = Equal.trans(Bool, U32.is_eq(period, 1), U32.is_eq(1, period), False{}, eq_comm_u32(period, 1), lt_check(1, period, scheduled_before(1, period, rest, one)))
      +price = sample(data, offset)
      (Ema.Seed{period, 1, alpha, price, from_u32(0)}, ema_first_step(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, seen, alpha, origin, sum, price, False{}, first_test, test), ema_warming(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~D, ~sample, rest, False{}, data, 1n+offset, period, 1, alpha, price, from_u32(0), one, {==}))
    case 0n False{}:
      count = unadd_zero(U32.to_nat(U32.add(seen, 1)), U32.to_nat(period), scheduled_next(seen, period, 0n, schedule))
      +price = sample(data, offset)
      +mean = seed_mean(~N, ~from_u32, ~add, ~div, period, origin, add(sum, sub(price, origin)))
      (Ema.Live{period, alpha, mean}, mean, ema_later_step(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, seen, alpha, origin, sum, price, True{}, first_test, eq_check(U32.add(seen, 1), period, count)))
    case 1n++rest False{}:
      +next_schedule = scheduled_next(seen, period, 1n+rest, schedule)
      test = lt_check(U32.add(seen, 1), period, scheduled_before(U32.add(seen, 1), period, rest, next_schedule))
      +price = sample(data, offset)
      +next_sum = add(sum, sub(price, origin))
      (Ema.Seed{period, U32.add(seen, 1), alpha, origin, next_sum}, ema_later_step(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, seen, alpha, origin, sum, price, False{}, first_test, test), ema_warming(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~D, ~sample, rest, U32.is_zero(U32.add(seen, 1)), data, 1n+offset, period, U32.add(seen, 1), alpha, origin, next_sum, next_schedule, {==}))

def and_left(a: Bool, b: Bool, h: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
  match a b:
    case False{} False{}: h
    case False{} True{}: h
    case True{} False{}: {==}
    case True{} True{}: {==}

def positive(+period: U32, valid: {Configuration.domain(period) == True{} : Bool}) -> MNat.lt(0n, U32.to_nat(period)):
  gt = and_left(U32.is_gt(period, 0), U32.is_le(period, 1073741824), valid)
  MNat.lt_of_gt(U32.to_nat(period), 0n, Equal.trans(Bool, Nat.is_gt(U32.to_nat(period), 0n), U32.is_gt(period, 0), True{}, MU32.u32_is_gt_to_nat_sym(period, 0), gt))

def lookback_schedule(+period: U32, valid: {Configuration.domain(period) == True{} : Bool}) -> {1n+U32.to_nat(U32.sub(period, 1)) == U32.to_nat(period) : Nat}:
  +at_least_one = MNat.succ_le_of_lt(0n, U32.to_nat(period), positive(period, valid))
  Equal.trans(Nat, 1n+U32.to_nat(U32.sub(period, 1)), 1n+Nat.sub(U32.to_nat(period), 1n), U32.to_nat(period), Equal.cong(Nat, Nat, x => 1n+x, U32.to_nat(U32.sub(period, 1)), Nat.sub(U32.to_nat(period), 1n), MU32.u32_sub_exact(period, 1, at_least_one)), Equal.trans(Nat, 1n+Nat.sub(U32.to_nat(period), 1n), Nat.add(Nat.sub(U32.to_nat(period), 1n), 1n), U32.to_nat(period), Equal.sym(Nat, Nat.add(Nat.sub(U32.to_nat(period), 1n), 1n), 1n+Nat.sub(U32.to_nat(period), 1n), add_one(Nat.sub(U32.to_nat(period), 1n))), MNat.sub_add_cancel(U32.to_nat(period), 1n, at_least_one)))

def ema_initial_warmup(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~D: Data, ~sample: D -> Nat -> N,
  +period: U32, data: D, valid: {Configuration.domain(period) == True{} : Bool}
) -> warm(N, Ema.State<N>, s => x => Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, s, x), U32.to_nat(U32.sub(period, 1)), at => sample(data, at), 0n, Ema.init(~N, ~from_u32, ~div, period)):
  ema_warming(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~D, ~sample, U32.to_nat(U32.sub(period, 1)), True{}, data, 0n, period, 0, div(from_u32(2), from_u32(U32.add(period, 1))), from_u32(0), from_u32(0), lookback_schedule(period, valid), {==})

def warm_shape(
  -N: Data, -S: Type, -step: S -> N -> S & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, -offset: Nat, -state: S
) -> Type:
  match remaining:
    case 0n:
      {is_some(N, Pair.snd(S, Maybe<&2, N>, step(state, prices(offset)))) == True{} : Bool}
    case 1n+rest:
      {is_some(N, Pair.snd(S, Maybe<&2, N>, step(state, prices(offset)))) == False{} : Bool} & (warm_shape(N, S, step, rest, prices, 1n+offset, Pair.fst(S, Maybe<&2, N>, step(state, prices(offset)))))

def warm_shape_after(
  -N: Data, -S: Type, -step: S -> N -> S & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, -offset: Nat, -result: S & Maybe<&2, N>
) -> Type:
  match remaining:
    case 0n:
      {is_some(N, Pair.snd(S, Maybe<&2, N>, result)) == True{} : Bool}
    case 1n+rest:
      {is_some(N, Pair.snd(S, Maybe<&2, N>, result)) == False{} : Bool} & (warm_shape(N, S, step, rest, prices, 1n+offset, Pair.fst(S, Maybe<&2, N>, result)))

def warm_exact_shape(
  ~N: Data, ~S: Type, ~step: S -> N -> S & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, -offset: Nat, -state: S,
  witness: warm(N, S, step, remaining, prices, offset, state)
) -> warm_shape(N, S, step, remaining, prices, offset, state):
  match remaining:
    case 0n:
      (next, value, equation) = witness
      Equal.cong(S & Maybe<&2, N>, Bool, result => is_some(N, Pair.snd(S, Maybe<&2, N>, result)), step(state, prices(offset)), (next, Some{value}), equation)
    case 1n+rest:
      (next, equation, tail) = witness
      %Equal.sym(S & Maybe<&2, N>, step(state, prices(offset)), (next, None{}), equation) : warm_shape_after(N, S, step, 1n+rest, prices, offset, _)
      ({==}, warm_exact_shape(~N, ~S, ~step, rest, prices, 1n+offset, next, tail))

def min_left(+a: U32, +b: U32, h: MNat.le(U32.to_nat(a), U32.to_nat(b))) -> {U32.min(a, b) == a : U32}:
  equal_u32(U32.min(a, b), a, Equal.trans(Nat, U32.to_nat(U32.min(a, b)), Nat.min(U32.to_nat(a), U32.to_nat(b)), U32.to_nat(a), MU32.u32_min_to_nat(a, b), MNat.min_eq_left(U32.to_nat(a), U32.to_nat(b), h)))

def sma_pending(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  +period: U32, +size: U32, +pos: U32, +total: Rolling.Total<N>, +price: N, -buffer: Array<N>, -old: N,
  +old_test: {U32.is_eq(size, period) == False{} : Bool}, +new_test: {U32.is_eq(U32.add(size, 1), period) == False{} : Bool}, +minimum: {U32.min(U32.add(size, 1), period) == U32.add(size, 1) : U32}
) -> {Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, Window.push.result(~N, period, size, pos, (buffer, old)))) == (Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, U32.add(size, 1), U32.mod(U32.add(pos, 1), period)}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, None{}) : Sma.State<N> & Maybe<&2, N>}:
  -next_size = U32.add(size, 1)
  -next_pos = U32.mod(U32.add(pos, 1), period)
  %Equal.sym(U32, U32.min(next_size, period), next_size, minimum) : {Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, (Window.Window{buffer, period, _, next_pos}, Bool.pick(Maybe<&2, N>, U32.is_eq(size, period), Some{old}, None{})))) == (Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, next_size, next_pos}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, None{}) : Sma.State<N> & Maybe<&2, N>}
  %Equal.sym(Bool, U32.is_eq(size, period), False{}, old_test) : {Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, (Window.Window{buffer, period, next_size, next_pos}, Bool.pick(Maybe<&2, N>, _, Some{old}, None{})))) == (Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, next_size, next_pos}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, None{}) : Sma.State<N> & Maybe<&2, N>}
  %Equal.sym(Bool, U32.is_eq(next_size, period), False{}, new_test) : {Sma.emit(~N, ~from_u32, ~div, period, Rolling.advance(~N, ~add, ~sub, sub(price, price), total, price, None{}, (Window.Window{buffer, period, next_size, next_pos}, Bool.and(_, U32.is_zero(next_pos))))) == (Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, next_size, next_pos}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, None{}) : Sma.State<N> & Maybe<&2, N>}
  %Equal.sym(Bool, U32.is_eq(next_size, period), False{}, new_test) : {Sma.emit(~N, ~from_u32, ~div, period, Rolling.emit(~N, Rolling.accumulate(~N, ~add, ~sub, total, price), (Window.Window{buffer, period, next_size, next_pos}, _))) == (Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, next_size, next_pos}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, None{}) : Sma.State<N> & Maybe<&2, N>}
  {==}

def sma_rebuilt_ready(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N,
  period: U32, result: Window.State<N> & Rolling.Total<N>
) -> {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.rebuild.emit(~N, result)))) == True{} : Bool}:
  match result:
    case (window, total): {==}

def sma_boundary_rebuild(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  cycled: Bool, +period: U32, +pos: U32, +zero: N, +total: Rolling.Total<N>, +price: N, buffer: Array<N>
) -> {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.advance(~N, ~add, ~sub, zero, total, price, None{}, (Window.Window{buffer, period, period, pos}, cycled))))) == True{} : Bool}:
  match cycled:
    case False{}:
      %Equal.sym(Bool, U32.is_eq(period, period), True{}, eq_check(period, period, {==})) : {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.emit(~N, Rolling.accumulate(~N, ~add, ~sub, total, price), (Window.Window{buffer, period, period, pos}, _))))) == True{} : Bool}
      {==}
    case True{}:
      sma_rebuilt_ready(~N, ~from_u32, ~div, period, Window.fold(~N, ~Unit, ~Rolling.Total<N>, ~(c => s => x => Rolling.accumulate(~N, ~add, ~sub, s, x)), Window.Window{buffer, period, period, pos}, Unit{}, Rolling.Total{zero, zero}))

def sma_ready(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  +period: U32, +size: U32, +pos: U32, +total: Rolling.Total<N>, +price: N, buffer: Array<N>, -old: N,
  old_test: {U32.is_eq(size, period) == False{} : Bool}, minimum: {U32.min(U32.add(size, 1), period) == period : U32}
) -> {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, Window.push.result(~N, period, size, pos, (buffer, old)))))) == True{} : Bool}:
  +next_pos = U32.mod(U32.add(pos, 1), period)
  %Equal.sym(U32, U32.min(U32.add(size, 1), period), period, minimum) : {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, (Window.Window{buffer, period, _, next_pos}, Bool.pick(Maybe<&2, N>, U32.is_eq(size, period), Some{old}, None{})))))) == True{} : Bool}
  %Equal.sym(Bool, U32.is_eq(size, period), False{}, old_test) : {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, (Window.Window{buffer, period, period, next_pos}, Bool.pick(Maybe<&2, N>, _, Some{old}, None{})))))) == True{} : Bool}
  %Equal.sym(Bool, U32.is_eq(period, period), True{}, eq_check(period, period, {==})) : {is_some(N, Pair.snd(Sma.State<N>, Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.advance(~N, ~add, ~sub, sub(price, price), total, price, None{}, (Window.Window{buffer, period, period, next_pos}, Bool.and(_, U32.is_zero(next_pos))))))) == True{} : Bool}
  sma_boundary_rebuild(~N, ~from_u32, ~add, ~sub, ~div, U32.is_zero(next_pos), period, next_pos, sub(price, price), total, price, buffer)

def shape_from_after(
  ~N: Data, ~S: Type, ~step: S -> N -> S & Maybe<&2, N>,
  remaining: Nat, -prices: Nat -> N, -offset: Nat, -state: S,
  proof: warm_shape_after(N, S, step, remaining, prices, offset, step(state, prices(offset)))
) -> warm_shape(N, S, step, remaining, prices, offset, state):
  match remaining:
    case 0n: proof
    case 1n+rest: proof

def sma_warming_step(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  ~D: Data, ~sample: D -> Nat -> N,
  remaining: Nat, +data: D, +offset: Nat, +period: U32, +size: U32, +pos: U32, +total: Rolling.Total<N>, +price: N, result: Array<N> & N,
  +schedule: {Nat.add(U32.to_nat(size), 1n+remaining) == U32.to_nat(period) : Nat}
) -> warm_shape_after(N, Sma.State<N>, s => x => Sma.next(~N, ~from_u32, ~add, ~sub, ~div, s, x), remaining, at => sample(data, at), offset, Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, Window.push.result(~N, period, size, pos, result)))):
  match remaining:
    case 0n:
      match result:
        case (buffer, old):
          +next_schedule = scheduled_next(size, period, 0n, schedule)
          +count = unadd_zero(U32.to_nat(U32.add(size, 1)), U32.to_nat(period), next_schedule)
          minimum = Equal.trans(U32, U32.min(U32.add(size, 1), period), U32.add(size, 1), period, min_left(U32.add(size, 1), period, MNat.le_of_add_eq(U32.to_nat(U32.add(size, 1)), 0n, U32.to_nat(period), next_schedule)), equal_u32(U32.add(size, 1), period, count))
          sma_ready(~N, ~from_u32, ~add, ~sub, ~div, period, size, pos, total, price, buffer, old, lt_check(size, period, scheduled_before(size, period, 0n, schedule)), minimum)
    case 1n++rest:
      match result:
        case (buffer, old):
          +next_schedule = scheduled_next(size, period, 1n+rest, schedule)
          +before_next = scheduled_before(U32.add(size, 1), period, rest, next_schedule)
          equation = sma_pending(~N, ~from_u32, ~add, ~sub, ~div, period, size, pos, total, price, buffer, old, lt_check(size, period, scheduled_before(size, period, 1n+rest, schedule)), lt_check(U32.add(size, 1), period, before_next), min_left(U32.add(size, 1), period, MNat.le_of_lt(U32.to_nat(U32.add(size, 1)), U32.to_nat(period), before_next)))
          %Equal.sym(Sma.State<N> & Maybe<&2, N>, Sma.emit(~N, ~from_u32, ~div, period, Rolling.pushed(~N, ~add, ~sub, total, price, Window.push.result(~N, period, size, pos, (buffer, old)))), (Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, U32.add(size, 1), U32.mod(U32.add(pos, 1), period)}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, None{}), equation) : warm_shape_after(N, Sma.State<N>, s => x => Sma.next(~N, ~from_u32, ~add, ~sub, ~div, s, x), 1n+rest, at => sample(data, at), offset, _)
          +next_pos = U32.mod(U32.add(pos, 1), period)
          +next_price = sample(data, 1n+offset)
          ({==}, shape_from_after(~N, ~Sma.State<N>, ~(s => x => Sma.next(~N, ~from_u32, ~add, ~sub, ~div, s, x)), rest, at => sample(data, at), 1n+offset, Sma.Sma{period, Rolling.Sum{Window.Window{buffer, period, U32.add(size, 1), next_pos}, Rolling.accumulate(~N, ~add, ~sub, total, price)}}, sma_warming_step(~N, ~from_u32, ~add, ~sub, ~div, ~D, ~sample, rest, data, 1n+offset, period, U32.add(size, 1), next_pos, Rolling.accumulate(~N, ~add, ~sub, total, price), next_price, Array.swap(N, buffer, next_pos, next_price), next_schedule)))

def sma_initial_warmup(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N,
  ~D: Data, ~sample: D -> Nat -> N,
  +period: U32, +data: D, depth: Nat, valid: {Configuration.domain(period) == True{} : Bool}
) -> warm_shape(N, Sma.State<N>, s => x => Sma.next(~N, ~from_u32, ~add, ~sub, ~div, s, x), U32.to_nat(U32.sub(period, 1)), at => sample(data, at), 0n, Sma.init(~N, ~from_u32, period, depth)):
  +price = sample(data, 0n)
  shape_from_after(~N, ~Sma.State<N>, ~(s => x => Sma.next(~N, ~from_u32, ~add, ~sub, ~div, s, x)), U32.to_nat(U32.sub(period, 1)), at => sample(data, at), 0n, Sma.init(~N, ~from_u32, period, depth), sma_warming_step(~N, ~from_u32, ~add, ~sub, ~div, ~D, ~sample, U32.to_nat(U32.sub(period, 1)), data, 0n, period, 0, 0, Rolling.Total{from_u32(0), from_u32(0)}, price, Array.swap(N, Array.new(N, depth, from_u32(0)), 0, price), lookback_schedule(period, valid)))

def ema_initial_warmup_shape(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~D: Data, ~sample: D -> Nat -> N,
  +period: U32, +data: D, valid: {Configuration.domain(period) == True{} : Bool}
) -> warm_shape(N, Ema.State<N>, s => x => Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, s, x), U32.to_nat(U32.sub(period, 1)), at => sample(data, at), 0n, Ema.init(~N, ~from_u32, ~div, period)):
  warm_exact_shape(~N, ~Ema.State<N>, ~(s => x => Ema.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, s, x)), U32.to_nat(U32.sub(period, 1)), at => sample(data, at), 0n, Ema.init(~N, ~from_u32, ~div, period), ema_initial_warmup(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~D, ~sample, period, data, valid))
