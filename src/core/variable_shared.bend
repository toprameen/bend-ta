import Base
import ./config.bend as Config
import ./window.bend as Window
import ./ma.bend as Ma
import ./rolling_average.bend as Average
import ./ema.bend as Ema
import ./vidya.bend as Vidya

type Frame<-N: Data> is Data:
  Frame{period: U32, kind: U32, phase: U32, count: U32, cache: Maybe<&2, Average.Values<N>>}

type Cell<-N: Data> is Type:
  Cached{frame: Frame<N>}
  Kama{period: U32, phase: U32, value: Maybe<&2, N>, cache: Maybe<&2, Ma.AdaptiveCache<N>>}
  Scalar{period: U32, delay: U32, count: U32, value: Maybe<&2, N>}
  Smooth{period: U32, delay: U32, state: Ema.State<N>}
  Outer{delay: U32, fast: Frame<N>, slow: Frame<N>, root: U32, window: Maybe<&1, Average.State<N>>}

type State<-N: Data> is Type:
  Pending{minimum: U32, maximum: U32, kind: U32}
  Shared{window: Window.State<N>, cells: List<&1, Cell<N>>, minimum: U32, maximum: U32, kind: U32}

type Update<-N: Data> is Type:
  Update{window: Window.State<N>, cells: List<&1, Cell<N>>, price: N, selected: U32, kind: U32, output: Maybe<&2, N>}

type Trail<-N: Data> is Data:
  Trail{previous: Maybe<&2, N>, up: N, down: N}

def supported(+minimum: U32, +maximum: U32, +kind: U32) -> Bool:
  Bool.and(U32.is_ge(U32.sub(maximum, minimum), 3), Bool.or(List.contains(~U32, ~U32.is_eq, [0, 2, 5, 6, 9, 12, 14], kind), Bool.and(U32.is_eq(kind, 15), U32.is_ge(U32.sub(maximum, minimum), 11))))

def init(~N: Data, minimum: U32, maximum: U32, kind: U32) -> State<N>:
  Pending{minimum, maximum, kind}

def reach(+maximum: U32, kind: U32) -> U32:
  match kind:
    case 6: U32.add(maximum, 2)
    case 12: U32.add(U32.div(U32.sub(maximum, 1), 2), 1)
    case 14: U32.add(Ma.lookback(maximum, 14), 1)
    case 15: maximum
    case _: U32.add(maximum, 1)

def frame.period(~N: Data, frame: Frame<N>) -> U32:
  match frame:
    case Frame{period, kind, phase, count, cache}: period

def cell(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, maximum: U32, kind: U32) -> Cell<N>:
  match kind:
    case 0: Cached{Frame{period, 0, U32.sub(period, 1), U32.sub(period, 1), None{}}}
    case 2: Cached{Frame{period, 1, U32.sub(period, 1), U32.sub(period, 1), None{}}}
    case 5: Cached{Frame{period, 2, U32.sub(period, 1), U32.sub(period, 1), None{}}}
    case 6: Kama{period, period, None{}, None{}}
    case 9:
      +root = Ma.root.go(32n, 1, period, period)
      Outer{U32.sub(Ma.lookback(maximum, 9), Ma.lookback(period, 9)), Frame{U32.max(1, U32.div(period, 2)), 1, 0, 0, None{}}, Frame{period, 1, 0, 0, None{}}, root, None{}}
    case 12: Smooth{period, U32.sub(Ma.lookback(maximum, 12), U32.sub(period, 1)), Ema.init(~N, ~from, ~div, period)}
    case _: Scalar{period, U32.sub(Ma.lookback(maximum, 14), Ma.lookback(period, 14)), 0, None{}}

def cells.collect(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, fuel: Nat, +period: U32, +maximum: U32, +kind: U32, acc: List<&1, Cell<N>>) -> List<&1, Cell<N>>:
  match fuel:
    case 0n: List.reverse(&1, Cell<N>, acc)
    case 1n+rest: cells.collect(~N, ~from, ~div, rest, U32.add(period, 1), maximum, kind, cell(~N, ~from, ~div, period, maximum, kind) <> acc)

def cells(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +minimum: U32, +maximum: U32, +kind: U32) -> List<&1, Cell<N>>:
  match kind:
    case 9: cells.collect(~N, ~from, ~div, U32.to_nat(U32.add(U32.sub(maximum, minimum), 1)), minimum, maximum, kind, Nil{})
    case 12: cells.collect(~N, ~from, ~div, U32.to_nat(U32.add(U32.sub(maximum, minimum), 1)), minimum, maximum, kind, Nil{})
    case 14: cells.collect(~N, ~from, ~div, U32.to_nat(U32.add(U32.sub(maximum, minimum), 1)), minimum, maximum, kind, Nil{})
    case _: Nil{}

def frame.result(~N: Data, period: U32, phase: U32, count: U32, span: U32, size: U32, pos: U32, result: Average.State<N> & Maybe<&2, N>) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match result:
    case (Average.Average{Window.Window{buffer, view_span, view_size, view_pos}, kind, cache}, value): (Window.Window{buffer, span, size, pos}, Frame{period, kind, phase, count, cache}, value)

def frame.lag(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, kind: U32, +phase: U32, +count: U32, cache: Maybe<&2, Average.Values<N>>, input: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match result:
    case (Window.Window{buffer, +span, +size, +pos}, old): frame.result(~N, period, phase, count, span, size, pos, Average.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, kind, period, cache, old, input, Window.Window{buffer, span, count, pos}, U32.is_eq(count, period), U32.is_zero(phase)))

def frame.checked(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, kind: U32, phase: U32, count: U32, +input: N, window: Window.State<N>, +cache: Average.Values<N>, good: Bool) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match good:
    case True{}: (window, Frame{period, kind, phase, count, Some{cache}}, Some{Average.value(~N, ~add, ~div, cache)})
    case False{}: frame.lag(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, None{}, input, (window, None{}))

def frame.changed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, +kind: U32, phase: U32, count: U32, +before: Average.Values<N>, old: N, +input: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match result:
    case (window, Some{middle}):
      +after = Average.update(~N, ~from, ~add, ~sub, ~mul, period, kind, before, old, input, middle)
      frame.checked(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, input, window, after, Average.conditioned(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, input, before, after))
    case (window, None{}): frame.lag(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, None{}, input, (window, None{}))

def frame.middle(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, kind: U32, phase: U32, count: U32, cache: Average.Values<N>, old: N, input: N, window: Window.State<N>, triangular: Bool) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match triangular:
    case True{}: frame.changed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, cache, old, input, Window.lag(~N, window, U32.sub(period, U32.div(U32.add(period, 1), 2))))
    case False{}: frame.changed(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, cache, old, input, (window, Some{from(0)}))

def frame.chosen(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, +kind: U32, +phase: U32, +count: U32, cache: Maybe<&2, Average.Values<N>>, input: N, result: Window.State<N> & Maybe<&2, N>, full: Bool, cycle: Bool) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match cache result full cycle:
    case Some{before} Tuple{window, Some{old}} True{} False{}: frame.middle(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, before, old, input, window, U32.is_eq(kind, 2))
    case cache result _ _: frame.lag(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, phase, count, cache, input, result)

def frame.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, frame: Frame<N>, input: N, window: Window.State<N>) -> Window.State<N> & Frame<N> & Maybe<&2, N>:
  match frame:
    case Frame{+period, kind, phase, count, cache}:
      +next = U32.mod(U32.add(phase, 1), period)
      +size = U32.min(U32.add(count, 1), period)
      frame.chosen(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, next, size, cache, input, Window.lag(~N, window, period), U32.is_eq(size, period), U32.is_zero(next))

def cached.result(~N: Data, result: Window.State<N> & Frame<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (window, frame, value): (window, Cached{frame}, value)

def cached(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, frame: Frame<N>, input: N, window: Window.State<N>, identity: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match identity:
    case True{}: (window, Cached{frame}, Some{input})
    case False{}: cached.result(~N, frame.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, frame, input, window))

def kama.rebuilt(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, phase: U32, value: Maybe<&2, N>, +input: N, previous: N, span: U32, size: U32, pos: U32, result: Window.State<N> & Ma.Changes<N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (Window.Window{buffer, vs, vn, vp}, Ma.Changes{last, +total, Some{first}}):
      +next = Ma.adaptive.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, value, input, previous, total, first)
      (Window.Window{buffer, span, size, pos}, Kama{period, phase, Some{next}, Some{Ma.AdaptiveCache{Average.Sum{total, from(0)}, input}}}, Some{next})
    case (Window.Window{buffer, vs, vn, vp}, other): (Window.Window{buffer, span, size, pos}, Kama{period, phase, value, None{}}, None{})

def kama.previous(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, phase: U32, value: Maybe<&2, N>, input: N, span: U32, size: U32, pos: U32, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (window, Some{previous}): kama.rebuilt(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, previous, span, size, pos, Window.fold(~N, ~Unit, ~Ma.Changes<N>, ~(u => a => x => Ma.adaptive.change(~N, ~add, ~sub, ~abs, u, a, x)), window, Unit{}, Ma.Changes{None{}, from(0), None{}}))
    case (Window.Window{buffer, vs, vn, vp}, None{}): (Window.Window{buffer, span, size, pos}, Kama{period, phase, value, None{}}, None{})

def kama.rebuild(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, phase: U32, value: Maybe<&2, N>, input: N, window: Window.State<N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match window:
    case Window.Window{buffer, +span, +size, +pos}: kama.previous(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, span, size, pos, Window.lag(~N, Window.Window{buffer, span, U32.add(period, 1), pos}, 1))

def kama.accepted(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, phase: U32, value: Maybe<&2, N>, +input: N, previous: N, first: N, +total: Average.Sum<N>, window: Window.State<N>, good: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match good:
    case True{}:
      +next = Ma.adaptive.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, value, input, previous, Average.sum.value(~N, total), first)
      (window, Kama{period, phase, Some{next}, Some{Ma.AdaptiveCache{total, input}}}, Some{next})
    case False{}: kama.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, window)

def kama.first(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, phase: U32, value: Maybe<&2, N>, +input: N, old: N, cache: Ma.AdaptiveCache<N>, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match cache result:
    case Ma.AdaptiveCache{+before, +previous} Tuple{window, Some{+first}}:
      +total = Average.sum.change(~N, ~from, ~add, ~sub, before, abs(sub(first, old)), abs(sub(input, previous)))
      kama.accepted(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, previous, first, total, window, Bool.and(le(from(0), Average.sum.value(~N, total)), Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, Average.sum.value(~N, before), Average.sum.value(~N, total))))
    case other Tuple{window, None{}}: kama.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, window)

def kama.chosen(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, phase: U32, value: Maybe<&2, N>, cache: Maybe<&2, Ma.AdaptiveCache<N>>, input: N, result: Window.State<N> & Maybe<&2, N>, cycle: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match cache result cycle:
    case Some{data} Tuple{window, Some{old}} False{}: kama.first(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, old, data, Window.lag(~N, window, period))
    case _ Tuple{window, old} _: kama.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, input, window)

def kama(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, phase: U32, value: Maybe<&2, N>, cache: Maybe<&2, Ma.AdaptiveCache<N>>, +input: N, window: Window.State<N>, identity: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match identity:
    case True{}: (window, Kama{period, 0, Some{input}, None{}}, Some{input})
    case False{}:
      +next = U32.mod(U32.add(phase, 1), U32.add(period, 1))
      kama.chosen(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, next, value, cache, input, Window.lag(~N, window, U32.add(period, 1)), U32.is_zero(next))

def trail.movement(~N: Data, ~add: N -> N -> N, price: N, up: N, down: N, movement: Vidya.Movement<N>) -> Trail<N>:
  match movement:
    case Vidya.Movement{gain, loss}: Trail{Some{price}, add(up, gain), add(down, loss)}

def trail(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~le: N -> N -> Bool, u: Unit, acc: Trail<N>, +price: N) -> Trail<N>:
  match acc:
    case Trail{None{}, up, down}: Trail{Some{price}, up, down}
    case Trail{Some{before}, up, down}:
      trail.movement(~N, ~add, price, up, down, Vidya.movement(~N, ~from, ~sub, ~le, sub(price, before)))

def variable.output(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, span: U32, size: U32, pos: U32, +previous: N, +price: N, result: Window.State<N> & Trail<N>) -> Window.State<N> & N:
  match result:
    case (Window.Window{buffer, old_span, old_size, old_pos}, Trail{before, +up, +down}):
      +k = Vidya.coefficient(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, div(from(2), from(U32.add(period, 1))), up, down, le(add(up, down), from(0)))
      (Window.Window{buffer, span, size, pos}, add(mul(sub(price, previous), k), previous))

def variable(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, +count: U32, value: Maybe<&2, N>, +price: N, window: Window.State<N>) -> Window.State<N> & N:
  match value window:
    case None{} window: (window, price)
    case Some{+previous} Window.Window{buffer, +span, +size, +pos}:
      +zero = from(0)
      variable.output(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, span, size, pos, previous, price, Window.fold(~N, ~Unit, ~Trail<N>, ~(u => a => x => trail(~N, ~from, ~add, ~sub, ~le, u, a, x)), Window.Window{buffer, span, count, pos}, Unit{}, Trail{None{}, zero, zero}))

def scalar.variable(~N: Data, period: U32, +count: U32, need: U32, result: Window.State<N> & N) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (window, +value): (window, Scalar{period, 0, count, Some{value}}, Bool.pick(Maybe<&2, N>, U32.is_eq(count, need), Some{value}, None{}))

def scalar(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, count: U32, value: Maybe<&2, N>, +price: N, window: Window.State<N>, identity: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match identity:
    case True{}: (window, Scalar{1, 0, 1, Some{price}}, Some{price})
    case False{}:
      +need = U32.add(Ma.lookback(period, 14), 1)
      +size = U32.min(U32.add(count, 1), need)
      scalar.variable(~N, period, size, need, variable(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, size, value, price, window))

def smooth.value(~N: Data, period: U32, window: Window.State<N>, result: Ema.State<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (state, value): (window, Smooth{period, 0, state}, value)

def smooth.lag(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, state: Ema.State<N>, +price: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (window, Smooth{period, 0, state}, None{})
    case (window, Some{before}): smooth.value(~N, period, window, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, state, add(price, sub(price, before))))

def smooth(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, state: Ema.State<N>, +price: N, window: Window.State<N>, identity: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match identity:
    case True{}: (window, Smooth{period, 0, state}, Some{price})
    case False{}: smooth.lag(~N, ~from, ~add, ~sub, ~mul, ~div, period, state, price, Window.lag(~N, window, U32.div(U32.sub(period, 1), 2)))

def outer.window(~N: Data, ~from: U32 -> N, +root: U32, history: Maybe<&1, Average.State<N>>) -> Average.State<N>:
  match history:
    case None{}: Average.init(~N, ~from, root, Config.depth(root), 1)
    case Some{h}: h

def outer.done(~N: Data, fast: Frame<N>, slow: Frame<N>, root: U32, window: Window.State<N>, result: Average.State<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (history, value): (window, Outer{0, fast, slow, root, Some{history}}, value)

def outer.values(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, fast: Frame<N>, slow: Frame<N>, +root: U32, history: Maybe<&1, Average.State<N>>, window: Window.State<N>, f: Maybe<&2, N>, s: Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match f s:
    case Some{+f} Some{s}: outer.done(~N, fast, slow, root, window, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, outer.window(~N, ~from, root, history), add(f, sub(f, s))))
    case _ _: (window, Outer{0, fast, slow, root, history}, None{})

def outer.slow(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, fast: Frame<N>, root: U32, history: Maybe<&1, Average.State<N>>, f: Maybe<&2, N>, result: Window.State<N> & Frame<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (window, slow, s): outer.values(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, slow, root, history, window, f, s)

def outer.fast(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, slow: Frame<N>, root: U32, history: Maybe<&1, Average.State<N>>, +price: N, result: Window.State<N> & Frame<N> & Maybe<&2, N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match result:
    case (window, fast, f): outer.slow(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, root, history, f, frame.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, slow, price, window))

def outer.chosen(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, fast: Frame<N>, slow: Frame<N>, root: U32, history: Maybe<&1, Average.State<N>>, +price: N, window: Window.State<N>, identity: Bool) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  match identity:
    case True{}: (window, Outer{0, fast, slow, root, history}, Some{price})
    case False{}: outer.fast(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, slow, root, history, price, frame.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, price, window))

def outer(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, fast: Frame<N>, +slow: Frame<N>, root: U32, history: Maybe<&1, Average.State<N>>, price: N, window: Window.State<N>) -> Window.State<N> & Cell<N> & Maybe<&2, N>:
  outer.chosen(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, frame.period(~N, slow), fast, slow, root, history, price, window, U32.is_eq(frame.period(~N, slow), 1))

def computed(~N: Data, cells: List<&1, Cell<N>>, price: N, +selected: U32, kind: U32, output: Maybe<&2, N>, period: U32, result: Window.State<N> & Cell<N> & Maybe<&2, N>) -> Update<N>:
  match result:
    case (window, cell, value): Update{window, cell <> cells, price, selected, kind, Bool.pick(Maybe<&2, N>, U32.is_eq(period, selected), value, output)}

def update(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: Update<N>, cell: Cell<N>) -> Update<N>:
  match state cell:
    case Update{window, cells, +price, selected, kind, output} Cached{+frame}: computed(~N, cells, price, selected, kind, output, frame.period(~N, frame), cached(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, frame, price, window, U32.is_eq(frame.period(~N, frame), 1)))
    case Update{window, cells, +price, selected, kind, output} Kama{+period, phase, value, cache}: computed(~N, cells, price, selected, kind, output, period, kama(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, phase, value, cache, price, window, U32.is_eq(period, 1)))
    case Update{window, cells, +price, selected, kind, output} Scalar{+period, 0, count, value}: computed(~N, cells, price, selected, kind, output, period, scalar(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, count, value, price, window, U32.is_eq(period, 1)))
    case Update{window, cells, price, selected, kind, output} Scalar{period, delay, count, value}: Update{window, Scalar{period, U32.sub(delay, 1), count, value} <> cells, price, selected, kind, output}
    case Update{window, cells, +price, selected, kind, output} Smooth{+period, 0, state}: computed(~N, cells, price, selected, kind, output, period, smooth(~N, ~from, ~add, ~sub, ~mul, ~div, period, state, price, window, U32.is_eq(period, 1)))
    case Update{window, cells, price, selected, kind, output} Smooth{period, delay, state}: Update{window, Smooth{period, U32.sub(delay, 1), state} <> cells, price, selected, kind, output}
    case Update{window, cells, price, selected, kind, output} Outer{0, fast, +slow, root, history}: computed(~N, cells, price, selected, kind, output, frame.period(~N, slow), outer(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, slow, root, history, price, window))
    case Update{window, cells, price, selected, kind, output} Outer{delay, fast, slow, root, history}: Update{window, Outer{U32.sub(delay, 1), fast, slow, root, history} <> cells, price, selected, kind, output}

def live.bank(~N: Data, minimum: U32, maximum: U32, result: Update<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case Update{window, cells, price, selected, kind, value}: (Shared{window, List.reverse(&1, Cell<N>, cells), minimum, maximum, kind}, value)

def live.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +minimum: U32, +maximum: U32, +kind: U32, price: N, selected: U32, window: Window.State<N>, ready: Bool) -> State<N> & Maybe<&2, N>:
  match ready:
    case False{}: (Shared{window, Nil{}, minimum, maximum, kind}, None{})
    case True{}: live.bank(~N, minimum, maximum, List.foldl(~&1, ~Cell<N>, ~Update<N>, ~(u => c => update(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, u, c)), cells.collect(~N, ~from, ~div, U32.to_nat(U32.add(U32.sub(maximum, minimum), 1)), minimum, maximum, kind, Nil{}), Update{window, Nil{}, price, selected, kind, None{}}))

def live.count(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, minimum: U32, +maximum: U32, +kind: U32, price: N, selected: U32, result: Window.State<N> & U32) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, count): live.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, minimum, maximum, kind, price, selected, window, U32.is_ge(count, Bool.pick(U32, U32.is_eq(kind, 6), U32.add(maximum, 1), maximum)))

def gaussian.output(~N: Data, result: Window.State<N> & Ma.Dot<N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, Ma.Dot{weights, sum}): (window, Some{sum})

def gaussian(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, window: Window.State<N>, weights: List<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  gaussian.output(~N, Window.fold(~N, ~Unit, ~Ma.Dot<N>, ~(u => a => x => Ma.gaussian.dot(~N, ~add, ~mul, u, a, x)), window, Unit{}, Ma.Dot{weights, from(0)}))

def restore(~N: Data, period: U32, size: U32, pos: U32, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (Window.Window{buffer, old_period, old_size, old_pos}, value): (Window.Window{buffer, period, size, pos}, value)

def alma(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~weights: U32 -> List<&2, N>, +period: U32, window: Window.State<N>, identity: Bool) -> Window.State<N> & Maybe<&2, N>:
  match window identity:
    case window True{}: Window.lag(~N, window, 0)
    case Window.Window{buffer, +span, +size, +pos} False{}: restore(~N, span, size, pos, gaussian(~N, ~from, ~add, ~mul, Window.Window{buffer, span, period, pos}, weights(period)))

def live.alma.value(~N: Data, minimum: U32, maximum: U32, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, value): (Shared{window, Nil{}, minimum, maximum, 15}, value)

def live.alma(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~weights: U32 -> List<&2, N>, minimum: U32, maximum: U32, +selected: U32, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (Shared{window, Nil{}, minimum, maximum, 15}, None{})
    case (window, True{}): live.alma.value(~N, minimum, maximum, alma(~N, ~from, ~add, ~mul, ~weights, selected, window, U32.is_eq(selected, 1)))

def live.empty(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~weights: U32 -> List<&2, N>, minimum: U32, maximum: U32, kind: U32, price: N, selected: U32, window: Window.State<N>) -> State<N> & Maybe<&2, N>:
  match kind:
    case 15: live.alma(~N, ~from, ~add, ~mul, ~weights, minimum, maximum, selected, Window.full(~N, window))
    case kind: live.count(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, minimum, maximum, kind, price, selected, Window.length(~N, window))

def live(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~weights: U32 -> List<&2, N>, cells: List<&1, Cell<N>>, minimum: U32, maximum: U32, +kind: U32, price: N, selected: U32, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match cells result:
    case Nil{} Tuple{window, old}: live.empty(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~weights, minimum, maximum, kind, price, selected, window)
    case cells Tuple{window, old}: live.bank(~N, minimum, maximum, List.foldl(~&1, ~Cell<N>, ~Update<N>, ~(u => c => update(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, u, c)), cells, Update{window, Nil{}, price, selected, kind, None{}}))

def next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~weights: U32 -> List<&2, N>, state: State<N>, +price: N, selected: U32) -> State<N> & Maybe<&2, N>:
  match state:
    case Pending{+minimum, +maximum, +kind}:
      +length = reach(maximum, kind)
      live(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~weights, cells(~N, ~from, ~div, minimum, maximum, kind), minimum, maximum, kind, price, selected, Window.push(~N, Window.init(~N, length, Config.depth(length), price), price))
    case Shared{window, cells, minimum, maximum, kind}: live(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~weights, cells, minimum, maximum, kind, price, selected, Window.push(~N, window, price))
