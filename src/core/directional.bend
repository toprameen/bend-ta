import Base
import ./bar.bend as Bar
import ./window.bend as Window

type State<-N: Data> is Data:
  State{period: U32, seen: U32, previous: Maybe<&2, Bar.HLC<N>>, plus: N, minus: N, range: N, dx: N}

type Value<-N: Data> is Data:
  Value{seen: U32, plus_dm: N, minus_dm: N, plus_di: N, minus_di: N, dx: N, valid: Bool}

def init(~N: Data, ~from_u32: U32 -> N, +period: U32) -> State<N>:
  +zero = from_u32(0)
  State{period, 0, None{}, zero, zero, zero, zero}

def total(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, +previous: N, +value: N, +seed: Bool) -> N:
  match seed:
    case True{}: add(previous, value)
    case False{}: add(sub(previous, mul(previous, div(from_u32(1), from_u32(period)))), value)

def update(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool,
  +period: U32, +seen: U32, previous: Bar.HLC<N>, +plus: N, +minus: N, +range: N, +previous_dx: N, +bar: Bar.HLC<N>
) -> State<N> & Value<N>:
  match previous bar:
    case Bar.HLC{ph, pl, pc} Bar.HLC{+high, +low, close}:
      +zero = from_u32(0)
      +up = sub(high, ph)
      +down = sub(pl, low)
      +seed = U32.is_lt(seen, U32.sub(period, 1))
      +pd = Bool.pick(N, Bool.and(gt(up, zero), gt(up, down)), up, zero)
      +md = Bool.pick(N, Bool.and(gt(down, zero), gt(down, up)), down, zero)
      +p = total(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, plus, pd, seed)
      +m = total(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, minus, md, seed)
      +r = total(~N, ~from_u32, ~add, ~sub, ~mul, ~div, period, range, Bar.true_range(~N, ~sub, ~abs, ~max, pc, bar), seed)
      +scale = Bool.pick(N, U32.is_eq(period, 1), from_u32(1), from_u32(100))
      +pi = Bool.pick(N, gt(r, zero), mul(scale, div(p, r)), zero)
      +mi = Bool.pick(N, gt(r, zero), mul(scale, div(m, r)), zero)
      +den = add(pi, mi)
      +valid = Bool.and(gt(r, zero), gt(den, div(from_u32(1), mul(from_u32(10000000), from_u32(10000000)))))
      +dx = Bool.pick(N, valid, mul(from_u32(100), div(abs(sub(pi, mi)), den)), previous_dx)
      +count = U32.min(period, U32.add(U32.min(seen, period), 1))
      (State{period, count, Some{bar}, p, m, r, dx}, Value{count, p, m, pi, mi, dx, valid})

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool,
  state: State<N>, +bar: Bar.HLC<N>
) -> State<N> & Value<N>:
  match state:
    case State{+period, +seen, None{}, plus, minus, range, dx}:
      +zero = from_u32(0)
      (State{period, seen, Some{bar}, plus, minus, range, dx}, Value{0, zero, zero, zero, zero, zero, False{}})
    case State{period, seen, Some{previous}, plus, minus, range, dx}:
      update(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~max, ~gt, period, seen, previous, plus, minus, range, dx, bar)

def select.value(~N: Data, +kind: U32, +plus_dm: N, +minus_dm: N, +plus_di: N, +minus_di: N, +dx: N) -> N:
  match kind:
    case 0: plus_dm
    case 1: minus_dm
    case 2: plus_di
    case 3: minus_di
    case _: dx

def select(~N: Data, +period: U32, +kind: U32, result: State<N> & Value<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, Value{+seen, plus_dm, minus_dm, plus_di, minus_di, dx, valid}):
      +first = Bool.pick(U32, U32.is_lt(kind, 2), U32.max(1, U32.sub(period, 1)), period)
      +value = select.value(~N, kind, plus_dm, minus_dm, plus_di, minus_di, dx)
      (state, Bool.pick(Maybe<&2, N>, U32.is_ge(seen, first), Some{value}, None{}))

type ADX<-N: Data> is Data:
  ADX{directional: State<N>, count: U32, value: N}

def adx.init(~N: Data, ~from_u32: U32 -> N, +period: U32) -> ADX<N>:
  ADX{init(~N, ~from_u32, period), 0, from_u32(0)}

def adx.value(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, +period: U32, +count: U32, +value: N, +dx: N, +valid: Bool, +seed: Bool) -> N:
  match seed:
    case True{}:
      +sum = add(value, Bool.pick(N, valid, dx, from_u32(0)))
      Bool.pick(N, U32.is_eq(U32.add(count, 1), period), div(sum, from_u32(period)), sum)
    case False{}: Bool.pick(N, valid, sub(value, div(sub(value, dx), from_u32(period))), value)

def adx.ready(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, +period: U32, +count: U32, +value: N, state: State<N>, +dx: N, +valid: Bool, +warm: Bool) -> ADX<N> & Maybe<&2, N>:
  match warm:
    case True{}: (ADX{state, count, value}, None{})
    case False{}:
      +n = U32.min(period, U32.add(count, 1))
      +next = adx.value(~N, ~from_u32, ~add, ~sub, ~div, period, count, value, dx, valid, U32.is_lt(count, period))
      (ADX{state, n, next}, Bool.pick(Maybe<&2, N>, U32.is_eq(n, period), Some{next}, None{}))

def adx.emit(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, +period: U32, +count: U32, +value: N, result: State<N> & Value<N>) -> ADX<N> & Maybe<&2, N>:
  match result:
    case (state, Value{seen, p, m, pi, mi, dx, valid}):
      adx.ready(~N, ~from_u32, ~add, ~sub, ~div, period, count, value, state, dx, valid, U32.is_lt(seen, period))

def adx.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool,
  state: ADX<N>, bar: Bar.HLC<N>
) -> ADX<N> & Maybe<&2, N>:
  match state:
    case ADX{directional, count, value}:
      match directional:
        case State{+period, seen, previous, plus, minus, range, dx}:
          adx.emit(~N, ~from_u32, ~add, ~sub, ~div, period, count, value,
            next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~max, ~gt, State{period, seen, previous, plus, minus, range, dx}, bar))

type ADXR<-N: Data> is Type:
  ADXR{adx: ADX<N>, history: Window.State<N>}

def adxr.value(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, +value: N, previous: Maybe<&2, N>) -> Maybe<&2, N>:
  match previous:
    case None{}: None{}
    case Some{old}: Some{div(add(value, old), from_u32(2))}

def adxr.emit(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, adx: ADX<N>, +value: N, result: Window.State<N> & Maybe<&2, N>) -> ADXR<N> & Maybe<&2, N>:
  match result:
    case (history, previous):
      +output = adxr.value(~N, ~from_u32, ~add, ~div, value, previous)
      (ADXR{adx, history}, output)

def adxr.advance(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, history: Window.State<N>, result: ADX<N> & Maybe<&2, N>) -> ADXR<N> & Maybe<&2, N>:
  match result:
    case (adx, None{}): (ADXR{adx, history}, None{})
    case (adx, Some{+value}): adxr.emit(~N, ~from_u32, ~add, ~div, adx, value, Window.push(~N, history, value))

def adxr.next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool,
  state: ADXR<N>, bar: Bar.HLC<N>
) -> ADXR<N> & Maybe<&2, N>:
  match state:
    case ADXR{adx, history}: adxr.advance(~N, ~from_u32, ~add, ~div, history, adx.next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~max, ~gt, adx, bar))
