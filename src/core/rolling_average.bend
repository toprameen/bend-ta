import Base
import ./window.bend as Window

type Sum<-N: Data> is Data:
  Sum{value: N, error: N}

type Values<-N: Data> is Data:
  Values{origin: N, total: Sum<N>, weighted: Sum<N>, left: Sum<N>, divisor: N}

type Rebuild<-N: Data> is Data:
  Rebuild{at: U32, total: Sum<N>, weighted: Sum<N>, left: Sum<N>, divisor: N}

type Context<-N: Data> is Data:
  Context{period: U32, kind: U32, origin: N}

type State<-N: Data> is Type:
  Average{window: Window.State<N>, kind: U32, cache: Maybe<&2, Values<N>>}

def init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat, kind: U32) -> State<N>:
  Average{Window.init(~N, period, depth, from(0)), kind, None{}}

def sum.value(~N: Data, sum: Sum<N>) -> N:
  match sum:
    case Sum{value, error}: value

def sum.add(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, sum: Sum<N>, value: N) -> Sum<N>:
  match sum:
    case Sum{+before, error}:
      +delta = sub(value, error)
      +after = add(before, delta)
      Sum{after, sub(sub(after, before), delta)}

def sum.change(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, sum: Sum<N>, old: N, value: N) -> Sum<N>:
  sum.add(~N, ~add, ~sub, sum.add(~N, ~add, ~sub, sum, sub(from(0), old)), value)

def sum.remove(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, sum: Sum<N>, value: Sum<N>) -> Sum<N>:
  match value:
    case Sum{value, error}: sum.add(~N, ~add, ~sub, sum.add(~N, ~add, ~sub, sum, sub(from(0), value)), error)

def sum.merge(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, sum: Sum<N>, value: Sum<N>) -> Sum<N>:
  match value:
    case Sum{value, error}: sum.add(~N, ~add, ~sub, sum.add(~N, ~add, ~sub, sum, value), sub(from(0), error))

def weight(+period: U32, +at: U32, kind: U32) -> U32:
  match kind:
    case 0: 1
    case 1: U32.add(at, 1)
    case _: U32.min(U32.add(at, 1), U32.sub(period, at))

def sum.plain(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, sum: Sum<N>, value: N) -> Sum<N>:
  Sum{add(sum.value(~N, sum), value), from(0)}

def rebuild.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~accumulate: Sum<N> -> N -> Sum<N>, context: Context<N>, acc: Rebuild<N>, value: N) -> Rebuild<N>:
  match context acc:
    case Context{+period, kind, origin} Rebuild{+at, total, weighted, left, divisor}:
      +delta = sub(value, origin)
      +w = from(weight(period, at, kind))
      Rebuild{U32.add(at, 1), accumulate(total, delta), accumulate(weighted, mul(w, delta)), accumulate(left, Bool.pick(N, U32.is_lt(at, U32.div(U32.add(period, 1), 2)), delta, from(0))), add(divisor, w)}

def value(~N: Data, ~add: N -> N -> N, ~div: N -> N -> N, values: Values<N>) -> N:
  match values:
    case Values{origin, total, weighted, left, divisor}: add(origin, div(sum.value(~N, weighted), divisor))

def read(~N: Data, ~add: N -> N -> N, ~div: N -> N -> N, state: State<N>) -> State<N> & Maybe<&2, N>:
  match state:
    case Average{window, kind, None{}}: (Average{window, kind, None{}}, None{})
    case Average{window, kind, Some{+cache}}: (Average{window, kind, Some{cache}}, Some{value(~N, ~add, ~div, cache)})

def rebuilt(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, kind: U32, +origin: N, result: Window.State<N> & Rebuild<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, Rebuild{at, total, weighted, left, divisor}):
      +cache : Values<N> = Values{origin, total, weighted, left, divisor}
      (Average{window, kind, Some{cache}}, Some{value(~N, ~add, ~div, cache)})

def rebuild.with(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~accumulate: Sum<N> -> N -> Sum<N>, +kind: U32, +period: U32, +origin: N, window: Window.State<N>) -> Window.State<N> & Rebuild<N>:
  +zero = from(0)
  Window.fold(~N, ~Context<N>, ~Rebuild<N>, ~(c => a => x => rebuild.step(~N, ~from, ~add, ~sub, ~mul, ~accumulate, c, a, x)), window, Context{period, kind, origin}, Rebuild{0, Sum{zero, zero}, Sum{zero, zero}, Sum{zero, zero}, zero})

def rebuild.accepted(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +kind: U32, period: U32, +origin: N, window: Window.State<N>, values: Rebuild<N>, good: Bool) -> State<N> & Maybe<&2, N>:
  match good:
    case True{}: rebuilt(~N, ~from, ~add, ~div, kind, origin, (window, values))
    case False{}: rebuilt(~N, ~from, ~add, ~div, kind, origin, rebuild.with(~N, ~from, ~add, ~sub, ~mul, ~(s => x => sum.plain(~N, ~from, ~add, s, x)), kind, period, origin, window))

def rebuild.checked(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, kind: U32, period: U32, origin: N, result: Window.State<N> & Rebuild<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, +values):
      match values:
        case Rebuild{at, total, weighted, left, divisor}:
          +t = sum.value(~N, total)
          +w = sum.value(~N, weighted)
          +l = sum.value(~N, left)
          rebuild.accepted(~N, ~from, ~add, ~sub, ~mul, ~div, kind, period, origin, window, values, Bool.and(le(sub(t, t), from(0)), Bool.and(le(sub(w, w), from(0)), le(sub(l, l), from(0)))))

def rebuild(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, +kind: U32, +period: U32, +origin: N, window: Window.State<N>) -> State<N> & Maybe<&2, N>:
  rebuild.checked(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, kind, period, origin, rebuild.with(~N, ~from, ~add, ~sub, ~mul, ~(s => x => sum.add(~N, ~add, ~sub, s, x)), kind, period, origin, window))

def update.mean(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, cache: Values<N>, old: N, input: N) -> Values<N>:
  match cache:
    case Values{+origin, total, weighted, left, divisor}:
      +sum = sum.change(~N, ~from, ~add, ~sub, total, sub(old, origin), sub(input, origin))
      Values{origin, sum, sum, left, divisor}

def update.linear(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, period: U32, cache: Values<N>, old: N, input: N) -> Values<N>:
  match cache:
    case Values{+origin, +total, weighted, left, divisor}:
      +delta = sub(input, origin)
      Values{origin, sum.change(~N, ~from, ~add, ~sub, total, sub(old, origin), delta), sum.add(~N, ~add, ~sub, sum.remove(~N, ~from, ~add, ~sub, weighted, total), mul(from(period), delta)), left, divisor}

def update.triangle(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, +period: U32, cache: Values<N>, +old: N, input: N, middle: N) -> Values<N>:
  match cache:
    case Values{+origin, +total, weighted, +left, divisor}:
      +delta = sub(input, origin)
      +mid = sub(middle, origin)
      +w = sum.add(~N, ~add, ~sub, sum.add(~N, ~add, ~sub, sum.merge(~N, ~from, ~add, ~sub, sum.remove(~N, ~from, ~add, ~sub, sum.remove(~N, ~from, ~add, ~sub, weighted, left), left), total), Bool.pick(N, U32.is_zero(U32.mod(period, 2)), sub(from(0), mid), from(0))), delta)
      Values{origin, sum.change(~N, ~from, ~add, ~sub, total, sub(old, origin), delta), w, sum.change(~N, ~from, ~add, ~sub, left, sub(old, origin), mid), divisor}

def update(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, period: U32, kind: U32, cache: Values<N>, old: N, input: N, middle: N) -> Values<N>:
  match kind:
    case 0: update.mean(~N, ~from, ~add, ~sub, cache, old, input)
    case 1: update.linear(~N, ~from, ~add, ~sub, ~mul, period, cache, old, input)
    case _: update.triangle(~N, ~from, ~add, ~sub, period, cache, old, input, middle)

def stable(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +before: N, +after: N) -> Bool:
  Bool.and(le(sub(after, after), from(0)), Bool.or(le(abs(before), from(0)), le(abs(before), mul(from(65536), abs(after)))))

def accepted(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, kind: U32, period: U32, input: N, window: Window.State<N>, +cache: Values<N>, good: Bool) -> State<N> & Maybe<&2, N>:
  match good:
    case True{}: (Average{window, kind, Some{cache}}, Some{value(~N, ~add, ~div, cache)})
    case False{}: rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, kind, period, input, window)

def conditioned(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +input: N, before: Values<N>, +after: Values<N>) -> Bool:
  match before after:
    case Values{+origin, total, weighted, left, divisor} Values{ao, at, aw, al, ad}:
      +estimate = value(~N, ~add, ~div, after)
      Bool.and(Bool.and(Bool.and(stable(~N, ~from, ~sub, ~mul, ~abs, ~le, origin, estimate), stable(~N, ~from, ~sub, ~mul, ~abs, ~le, estimate, origin)), Bool.and(stable(~N, ~from, ~sub, ~mul, ~abs, ~le, origin, input), stable(~N, ~from, ~sub, ~mul, ~abs, ~le, input, origin))), Bool.and(stable(~N, ~from, ~sub, ~mul, ~abs, ~le, sum.value(~N, total), sum.value(~N, at)), Bool.and(stable(~N, ~from, ~sub, ~mul, ~abs, ~le, sum.value(~N, weighted), sum.value(~N, aw)), stable(~N, ~from, ~sub, ~mul, ~abs, ~le, sum.value(~N, left), sum.value(~N, al)))))

def checked(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, kind: U32, period: U32, +input: N, window: Window.State<N>, before: Values<N>, +after: Values<N>) -> State<N> & Maybe<&2, N>:
  accepted(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, kind, period, input, window, after, conditioned(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, input, before, after))

def updated(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, +kind: U32, +cache: Values<N>, +old: N, +input: N, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, Some{middle}): checked(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, kind, period, input, window, cache, update(~N, ~from, ~add, ~sub, ~mul, period, kind, cache, old, input, middle))
    case (window, None{}): rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, kind, period, input, window)

def middle(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, kind: U32, cache: Values<N>, old: N, input: N, window: Window.State<N>) -> State<N> & Maybe<&2, N>:
  match kind:
    case 2: updated(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, 2, cache, old, input, Window.lag(~N, window, U32.sub(period, U32.div(U32.add(period, 1), 2))))
    case kind: updated(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, cache, old, input, (window, Some{from(0)}))

def ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, kind: U32, period: U32, cache: Maybe<&2, Values<N>>, old: Maybe<&2, N>, input: N, window: Window.State<N>, full: Bool, cycle: Bool) -> State<N> & Maybe<&2, N>:
  match cache old full cycle:
    case _ _ False{} _: (Average{window, kind, None{}}, None{})
    case Some{values} Some{removed} True{} False{}: middle(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, values, removed, input, window)
    case _ _ _ _: rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, kind, period, input, window)

def pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, kind: U32, cache: Maybe<&2, Values<N>>, input: N, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (Window.Window{buffer, +period, +size, +pos}, removed): ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, kind, period, cache, removed, input, Window.Window{buffer, period, size, pos}, U32.is_eq(size, period), U32.is_zero(pos))

def next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: State<N>, +input: N) -> State<N> & Maybe<&2, N>:
  match state:
    case Average{window, kind, cache}: pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, kind, cache, input, Window.push(~N, window, input))
