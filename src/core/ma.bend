import Base
import ./config.bend as Config
import ./parameters.bend as Parameters
import ./window.bend as Window
import ./rolling_average.bend as Average
import ./ema.bend as Ema
import ./vidya.bend as Vidya
import ./mama.bend as Mama

type AdaptiveCache<-N: Data> is Data:
  AdaptiveCache{total: Average.Sum<N>, previous: N}

type State<-N: Data> is Type:
  Cycle{state: Mama.State<N>}
  Variable{state: Vidya.State<N>}
  Identity{}
  Adaptive{window: Window.State<N>, period: U32, value: Maybe<&2, N>, cache: Maybe<&2, AdaptiveCache<N>>}
  Gaussian{window: Window.State<N>, weights: List<&2, N>}
  ZeroLag{window: Window.State<N>, state: Ema.State<N>}
  Hull{fast: Average.State<N>, slow: Average.State<N>, outer: Average.State<N>}
  Simple{state: Average.State<N>}
  Exponential{state: Ema.State<N>}
  Weighted{state: Average.State<N>}
  Cascade{kind: U32, factor: N, stages: List<&2, Ema.State<N>>}

def cascade.stages(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, count: Nat, +period: U32) -> List<&2, Ema.State<N>>:
  match count:
    case 0n: Nil{}
    case 1n+rest: Ema.init(~N, ~from, ~div, period) <> cascade.stages(~N, ~from, ~div, rest, period)

def cascade.finish(~N: Data, state: Ema.State<N>, result: List<&2, Ema.State<N>> & Maybe<&2, List<&2, N>>, x: N) -> List<&2, Ema.State<N>> & Maybe<&2, List<&2, N>>:
  match result:
    case (states, None{}): (state <> states, None{})
    case (states, Some{values}): (state <> states, Some{x <> values})

def cascade.read(~N: Data, states: List<&2, Ema.State<N>>, result: Ema.State<N> & Maybe<&2, N>, rest: List<&2, Ema.State<N>> -> N -> List<&2, Ema.State<N>> & Maybe<&2, List<&2, N>>) -> List<&2, Ema.State<N>> & Maybe<&2, List<&2, N>>:
  match result:
    case (state, None{}): (state <> states, None{})
    case (state, Some{+x}): cascade.finish(~N, state, rest(states, x), x)

def cascade.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, fuel: Nat, states: List<&2, Ema.State<N>>, input: Maybe<&2, N>) -> List<&2, Ema.State<N>> & Maybe<&2, List<&2, N>>:
  match fuel states input:
    case 0n _ _: (states, Some{Nil{}})
    case 1n+rest Nil{} _: (Nil{}, Some{Nil{}})
    case 1n+rest h <> t None{}: (h <> t, None{})
    case 1n+rest h <> t Some{x}:
      cascade.read(~N, t, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, h, x), ss => xx => cascade.step(~N, ~from, ~add, ~sub, ~mul, ~div, rest, ss, Some{xx}))

def cascade.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, kind: U32, +v: N, values: List<&2, N>) -> N:
  match values:
    case +a <> b <> Nil{}: add(a, sub(a, b))
    case a <> b <> c <> Nil{}: add(c, mul(from(3), sub(a, b)))
    case a <> b <> +c <> +d <> +e <> +f <> Nil{}:
      +d1 = sub(c, d)
      +d2 = sub(d, e)
      +d3 = sub(e, f)
      +vv = mul(v, v)
      +vvv = mul(vv, v)
      add(c, add(mul(mul(from(3), v), d1), add(mul(mul(from(3), vv), sub(d1, d2)), mul(vvv, add(sub(d1, d2), sub(d3, d2))))))
    case _: from(0)

def cascade.output(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, +kind: U32, +factor: N, result: List<&2, Ema.State<N>> & Maybe<&2, List<&2, N>>) -> State<N> & Maybe<&2, N>:
  match result:
    case (stages, None{}): (Cascade{kind, factor, stages}, None{})
    case (stages, Some{values}): (Cascade{kind, factor, stages}, Some{cascade.value(~N, ~from, ~add, ~sub, ~mul, kind, factor, values)})

def next.simple(~N: Data, result: Average.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, value): (Simple{state}, value)

def next.exponential(~N: Data, result: Ema.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, value): (Exponential{state}, value)

type Changes<-N: Data> is Data:
  Changes{previous: Maybe<&2, N>, total: N, first: Maybe<&2, N>}

def adaptive.change(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, u: Unit, acc: Changes<N>, +x: N) -> Changes<N>:
  match acc:
    case Changes{None{}, total, first}: Changes{Some{x}, total, Some{x}}
    case Changes{Some{p}, total, first}: Changes{Some{x}, add(total, abs(sub(x, p))), first}

def adaptive.base(~N: Data, value: Maybe<&2, N>, fallback: N) -> N:
  match value:
    case None{}: fallback
    case Some{x}: x

def adaptive.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, value: Maybe<&2, N>, +x: N, previous: N, +total: N, +first: N) -> N:
  +er = Bool.pick(N, le(total, from(0)), from(1), Bool.pick(N, le(abs(sub(x, first)), total), div(abs(sub(x, first)), total), from(1)))
  +slow = div(from(2), from(31))
  +sc = add(slow, mul(er, sub(div(from(2), from(3)), slow)))
  +base = adaptive.base(~N, value, previous)
  add(base, mul(mul(sc, sc), sub(x, base)))

def adaptive.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, value: Maybe<&2, N>, +x: N, previous: N, result: Window.State<N> & Changes<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, Changes{last, +total, Some{first}}):
      +next = adaptive.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, value, x, previous, total, first)
      (Adaptive{window, period, Some{next}, Some{AdaptiveCache{Average.Sum{total, from(0)}, x}}}, Some{next})
    case (window, other): (Adaptive{window, period, value, None{}}, None{})

def adaptive.previous(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, value: Maybe<&2, N>, x: N, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (Adaptive{window, period, value, None{}}, None{})
    case (window, Some{previous}): adaptive.finish(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, x, previous, Window.fold(~N, ~Unit, ~Changes<N>, ~(u => a => x => adaptive.change(~N, ~add, ~sub, ~abs, u, a, x)), window, Unit{}, Changes{None{}, from(0), None{}}))

def adaptive.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, value: Maybe<&2, N>, x: N, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (Adaptive{window, period, value, None{}}, None{})
    case (window, True{}): adaptive.previous(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, x, Window.lag(~N, window, 1))

def adaptive.accepted(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, value: Maybe<&2, N>, +input: N, previous: N, first: N, +total: Average.Sum<N>, window: Window.State<N>, good: Bool) -> State<N> & Maybe<&2, N>:
  match good:
    case True{}:
      +next = adaptive.value(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, value, input, previous, Average.sum.value(~N, total), first)
      (Adaptive{window, period, Some{next}, Some{AdaptiveCache{total, input}}}, Some{next})
    case False{}: adaptive.previous(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, input, Window.lag(~N, window, 1))

def adaptive.first(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, value: Maybe<&2, N>, +input: N, old: N, cache: AdaptiveCache<N>, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match cache result:
    case AdaptiveCache{+before, +previous} Tuple{window, Some{+first}}:
      +total = Average.sum.change(~N, ~from, ~add, ~sub, before, abs(sub(first, old)), abs(sub(input, previous)))
      adaptive.accepted(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, input, previous, first, total, window, Bool.and(le(from(0), Average.sum.value(~N, total)), Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, Average.sum.value(~N, before), Average.sum.value(~N, total))))
    case other Tuple{window, None{}}: adaptive.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, input, Window.full(~N, window))

def adaptive.chosen(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, value: Maybe<&2, N>, cache: Maybe<&2, AdaptiveCache<N>>, removed: Maybe<&2, N>, input: N, window: Window.State<N>, cycle: Bool) -> State<N> & Maybe<&2, N>:
  match cache removed cycle:
    case Some{data} Some{old} False{}: adaptive.first(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, input, old, data, Window.lag(~N, window, period))
    case _ _ _: adaptive.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, input, Window.full(~N, window))

def adaptive.cached(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, value: Maybe<&2, N>, cache: Maybe<&2, AdaptiveCache<N>>, input: N, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (Window.Window{buffer, capacity, size, +pos}, old): adaptive.chosen(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, cache, old, input, Window.Window{buffer, capacity, size, pos}, U32.is_zero(pos))

type Dot<-N: Data> is Data:
  Dot{weights: List<&2, N>, sum: N}

def gaussian.dot(~N: Data, ~add: N -> N -> N, ~mul: N -> N -> N, u: Unit, acc: Dot<N>, x: N) -> Dot<N>:
  match acc:
    case Dot{Nil{}, sum}: Dot{Nil{}, sum}
    case Dot{w <> ws, sum}: Dot{ws, add(sum, mul(w, x))}

def gaussian.finish(~N: Data, weights: List<&2, N>, result: Window.State<N> & Dot<N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, Dot{ws, sum}): (Gaussian{window, weights}, Some{sum})

def gaussian.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, +weights: List<&2, N>, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (Gaussian{window, weights}, None{})
    case (window, True{}): gaussian.finish(~N, weights, Window.fold(~N, ~Unit, ~Dot<N>, ~(u => a => x => gaussian.dot(~N, ~add, ~mul, u, a, x)), window, Unit{}, Dot{weights, from(0)}))

def gaussian.push.result(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, weights: List<&2, N>, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, old): gaussian.ready(~N, ~from, ~add, ~mul, weights, Window.full(~N, window))

def gaussian.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, window: Window.State<N>, weights: List<&2, N>, x: N) -> State<N> & Maybe<&2, N>:
  gaussian.push.result(~N, ~from, ~add, ~mul, weights, Window.push(~N, window, x))

def zerolag.finish(~N: Data, window: Window.State<N>, result: Ema.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, value): (ZeroLag{window, state}, value)

def zerolag.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, state: Ema.State<N>, +x: N, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (ZeroLag{window, state}, None{})
    case (window, Some{lagged}): zerolag.finish(~N, window, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, state, add(x, sub(x, lagged))))

def zerolag.length(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, state: Ema.State<N>, x: N, result: Window.State<N> & Bool) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (ZeroLag{window, state}, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): zerolag.ready(~N, ~from, ~add, ~sub, ~mul, ~div, state, x, Window.lag(~N, Window.Window{buffer, period, size, pos}, U32.sub(period, 1)))

def zerolag.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, state: Ema.State<N>, x: N, result: Window.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (window, old): zerolag.length(~N, ~from, ~add, ~sub, ~mul, ~div, state, x, Window.full(~N, window))

def weighted.output(~N: Data, result: Average.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, output): (Weighted{state}, output)

def hull.outer(~N: Data, fast: Average.State<N>, slow: Average.State<N>, result: Average.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (outer, output): (Hull{fast, slow, outer}, output)

def hull.values(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, fast: Average.State<N>, slow: Average.State<N>, outer: Average.State<N>, fast_value: Maybe<&2, N>, slow_value: Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match fast_value slow_value:
    case Some{+f} Some{s}: hull.outer(~N, fast, slow, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, outer, add(f, sub(f, s))))
    case _ _: (Hull{fast, slow, outer}, None{})

def hull.slow(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, fast: Average.State<N>, outer: Average.State<N>, fast_value: Maybe<&2, N>, result: Average.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (slow, slow_value): hull.values(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, slow, outer, fast_value, slow_value)

def hull.fast(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, slow: Average.State<N>, outer: Average.State<N>, x: N, result: Average.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (fast, value): hull.slow(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, outer, value, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, slow, x))

def next.variable(~N: Data, result: Vidya.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, value): (Variable{state}, value)

def next.cycle(~N: Data, result: Mama.State<N> & Maybe<&2, Mama.Value<N>>) -> State<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (Cycle{state}, None{})
    case (state, Some{Mama.Value{mama, fama}}): (Cycle{state}, Some{mama})

def next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: State<N>, +price: N) -> State<N> & Maybe<&2, N>:
  match state:
    case Cycle{state}: next.cycle(~N, Mama.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, ~atan, state, price))
    case Variable{state}: next.variable(~N, Vidya.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, state, price))
    case Identity{}: (Identity{}, Some{price})
    case Adaptive{window, period, value, cache}: adaptive.cached(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, value, cache, price, Window.push(~N, window, price))
    case Gaussian{window, weights}: gaussian.pushed(~N, ~from, ~add, ~mul, window, weights, price)
    case ZeroLag{window, state}: zerolag.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, state, price, Window.push(~N, window, price))
    case Hull{fast, slow, outer}: hull.fast(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, slow, outer, price, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, fast, price))
    case Simple{state}: next.simple(~N, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, state, price))
    case Exponential{state}: next.exponential(~N, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, state, price))
    case Weighted{state}: weighted.output(~N, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, state, price))
    case Cascade{kind, factor, stages}: cascade.output(~N, ~from, ~add, ~sub, ~mul, kind, factor, cascade.step(~N, ~from, ~add, ~sub, ~mul, ~div, 6n, stages, Some{price}))

def buffer_depth(+period: U32) -> Nat:
  Config.depth(period)

def root.go(fuel: Nat, +low: U32, +high: U32, +period: U32) -> U32:
  match fuel:
    case 0n: low
    case 1n+rest:
      +mid = U32.div(U32.add(U32.add(low, high), 1), 2)
      +ok = U32.is_le(mid, U32.div(period, U32.max(mid, 1)))
      root.go(rest, Bool.pick(U32, ok, mid, low), Bool.pick(U32, ok, high, U32.sub(mid, 1)), period)

def gaussian.weights.collect(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, fuel: Nat, +at: U32, +center: N, +scale: N, acc: List<&2, N>) -> List<&2, N>:
  match fuel:
    case 0n: List.reverse(&2, N, acc)
    case 1n+rest:
      +distance = div(sub(from(at), center), scale)
      gaussian.weights.collect(~N, ~from, ~sub, ~mul, ~div, ~exp, rest, U32.add(at, 1), center, scale, exp(sub(from(0), div(mul(distance, distance), from(2)))) <> acc)

def gaussian.weights(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, fuel: Nat, at: U32, center: N, scale: N) -> List<&2, N>:
  gaussian.weights.collect(~N, ~from, ~sub, ~mul, ~div, ~exp, fuel, at, center, scale, Nil{})

def gaussian.sum(~N: Data, ~add: N -> N -> N, xs: List<&2, N>, acc: N) -> N:
  match xs:
    case Nil{}: acc
    case x <> rest: gaussian.sum(~N, ~add, rest, add(acc, x))

def gaussian.normalize.collect(~N: Data, ~div: N -> N -> N, xs: List<&2, N>, +total: N, acc: List<&2, N>) -> List<&2, N>:
  match xs:
    case Nil{}: List.reverse(&2, N, acc)
    case x <> rest: gaussian.normalize.collect(~N, ~div, rest, total, div(x, total) <> acc)

def gaussian.normalize(~N: Data, ~div: N -> N -> N, xs: List<&2, N>, total: N) -> List<&2, N>:
  gaussian.normalize.collect(~N, ~div, xs, total, Nil{})

def gaussian.coefficients(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, sigma: N, offset: N) -> List<&2, N>:
  +weights = gaussian.weights(~N, ~from, ~sub, ~mul, ~div, ~exp, U32.to_nat(period), 0, floor(mul(offset, from(U32.sub(period, 1)))), div(from(period), sigma))
  gaussian.normalize(~N, ~div, weights, gaussian.sum(~N, ~add, weights, from(0)))

def gaussian.window.make(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, depth: Nat, sigma: N, offset: N) -> State<N>:
  Gaussian{Window.init(~N, period, depth, from(0)), gaussian.coefficients(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, sigma, offset)}

def gaussian.choose(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, period: U32, depth: Nat, sigma: N, offset: N, identity: Bool) -> State<N>:
  match identity:
    case True{}: Identity{}
    case False{}: gaussian.window.make(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, depth, sigma, offset)

def gaussian.make(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, depth: Nat, sigma: N, offset: N) -> State<N>:
  gaussian.choose(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, depth, sigma, offset, U32.is_eq(period, 1))

def hull.make(~N: Data, ~from: U32 -> N, +period: U32, +half: U32, +root: U32) -> State<N>:
  Hull{Average.init(~N, ~from, half, buffer_depth(half), 1), Average.init(~N, ~from, period, buffer_depth(period), 1), Average.init(~N, ~from, root, buffer_depth(root), 1)}

def Kind.SMA() -> U32: 0
def Kind.EMA() -> U32: 1
def Kind.WMA() -> U32: 2
def Kind.DEMA() -> U32: 3
def Kind.TEMA() -> U32: 4
def Kind.TRIMA() -> U32: 5
def Kind.KAMA() -> U32: 6
def Kind.MAMA() -> U32: 7
def Kind.T3() -> U32: 8
def Kind.HMA() -> U32: 9
def Kind.Identity() -> U32: 10
def Kind.ZLEMA() -> U32: 12
def Kind.RMA() -> U32: 13
def Kind.VIDYA() -> U32: 14
def Kind.ALMA() -> U32: 15

def make.kind(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, depth: Nat, +kind: U32, factor: N, selected: Nat) -> State<N>:
  match selected:
    case 0n: Simple{Average.init(~N, ~from, period, depth, 0)}
    case 1n: Exponential{Ema.init(~N, ~from, ~div, period)}
    case 2n: Weighted{Average.init(~N, ~from, period, depth, 1)}
    case 3n: Cascade{kind, factor, cascade.stages(~N, ~from, ~div, 2n, period)}
    case 4n: Cascade{kind, factor, cascade.stages(~N, ~from, ~div, 3n, period)}
    case 5n: Weighted{Average.init(~N, ~from, period, depth, 2)}
    case 6n: Adaptive{Window.init(~N, U32.add(period, 1), buffer_depth(U32.add(period, 1)), from(0)), period, None{}, None{}}
    case 7n: Cycle{Mama.init(~N, ~from, ~div, div(from(1), from(2)), div(from(1), from(20)))}
    case 8n: Cascade{kind, factor, cascade.stages(~N, ~from, ~div, 6n, period)}
    case 9n: hull.make(~N, ~from, period, U32.max(1, U32.div(period, 2)), root.go(32n, 1, period, period))
    case 10n: Identity{}
    case 12n: ZeroLag{Window.init(~N, U32.add(U32.div(U32.sub(period, 1), 2), 1), buffer_depth(U32.add(U32.div(U32.sub(period, 1), 2), 1)), from(0)), Ema.init(~N, ~from, ~div, period)}
    case 13n: Exponential{Ema.init.alpha(~N, ~from, period, div(from(1), from(period)))}
    case 14n: Variable{Vidya.init(~N, ~from, ~div, period, U32.div(U32.add(U32.mul(3, period), 2), 4), buffer_depth(U32.div(U32.add(U32.mul(3, period), 2), 4)))}
    case 15n: gaussian.make(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, depth, from(6), div(from(85), from(100)))
    case _: Identity{}

def make(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, depth: Nat, +kind: U32, factor: N) -> State<N>:
  make.kind(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, depth, kind, factor, U32.to_nat(Bool.pick(U32, U32.is_eq(period, 1), Kind.Identity(), kind)))

def supported(+kind: U32) -> Bool:
  Bool.and(U32.is_le(kind, Kind.ALMA()), U32.is_ne(kind, 11))

def init.checked(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, kind: U32, valid: Bool) -> Result<&2, &1, Parameters.Error, State<N>>:
  match valid:
    case False{}: Fail{Parameters.InvalidParameter{}}
    case True{}: Done{make(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, buffer_depth(period), kind, div(from(7), from(10)))}

def valid(+period: U32, +kind: U32) -> Bool:
  Bool.and(Bool.and(U32.is_gt(period, 0), U32.is_le(period, 100000)), Bool.or(supported(kind), Bool.and(U32.is_eq(period, 1), U32.is_le(kind, Kind.ALMA()))))

def init(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~exp: N -> N, ~floor: N -> N, +period: U32, +kind: U32) -> Result<&2, &1, Parameters.Error, State<N>>:
  init.checked(~N, ~from, ~add, ~sub, ~mul, ~div, ~exp, ~floor, period, kind, valid(period, kind))
def lookback.selected(+period: U32, kind: Nat) -> U32:
  match kind:
    case 3n: U32.mul(2, U32.sub(period, 1))
    case 4n: U32.mul(3, U32.sub(period, 1))
    case 6n: period
    case 7n: 32
    case 8n: U32.mul(6, U32.sub(period, 1))
    case 9n: U32.sub(U32.add(period, root.go(32n, 1, period, period)), 2)
    case 10n: 0
    case 11n: 0
    case 12n: U32.add(U32.sub(period, 1), U32.div(U32.sub(period, 1), 2))
    case 14n: U32.div(U32.add(U32.mul(3, period), 2), 4)
    case _: U32.sub(period, 1)

def lookback(+period: U32, kind: U32) -> U32:
  Bool.pick(U32, U32.is_le(period, 1), 0, lookback.selected(period, U32.to_nat(kind)))
