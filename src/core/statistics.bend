import Base
import ./extrema_queue.bend as Queue
import ./window.bend as Window
import ./moments.bend as Moments
import ./ordered.bend as Ordered
import ./rolling_average.bend as Average

type Regression<-N: Data> is Data:
  Regression{intercept: N, slope: N, endpoint: N, forecast: N}

type RegressSum<-N: Data> is Data:
  RegressSum{at: U32, delta_sum: N, xy: N, xx: N}

type RegressCenter<-N: Data> is Data:
  RegressCenter{origin: N, center: N}

def regress.step(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, context: RegressCenter<N>, acc: RegressSum<N>, price: N) -> RegressSum<N>:
  match context acc:
    case RegressCenter{origin, center} RegressSum{+at, sum, xy, xx}:
      +dx = sub(from(at), center)
      +dy = sub(price, origin)
      RegressSum{U32.add(at, 1), add(sum, dy), add(xy, mul(dx, dy)), add(xx, mul(dx, dx))}

def regress.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +origin: N, +center: N, result: Window.State<N> & RegressSum<N>) -> Window.State<N> & Maybe<&2, Regression<N>>:
  match result:
    case (window, RegressSum{count, sum, xy, xx}):
      +mean = add(origin, div(sum, from(count)))
      +slope = div(xy, xx)
      (window, Some{Regression{sub(mean, mul(slope, center)), slope, add(mean, mul(slope, center)), add(mean, mul(slope, add(center, from(1))))}})

def regress.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, Regression<N>>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{+origin}):
      +center = div(from(U32.sub(period, 1)), from(2))
      regress.finish(~N, ~from, ~add, ~sub, ~mul, ~div, origin, center, Window.fold(~N, ~RegressCenter<N>, ~RegressSum<N>, ~(c => a => x => regress.step(~N, ~from, ~add, ~sub, ~mul, c, a, x)), window, RegressCenter{origin, center}, RegressSum{0, from(0), from(0), from(0)}))

def regress.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, Regression<N>>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): regress.anchor(~N, ~from, ~add, ~sub, ~mul, ~div, period, Window.lag(~N, Window.Window{buffer, period, size, pos}, U32.sub(period, 1)))

def regress.init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat) -> Average.State<N>:
  Average.init(~N, ~from, period, depth, 1)

def regress.restore(~N: Data, kind: U32, cache: Maybe<&2, Average.Values<N>>, result: Window.State<N> & Maybe<&2, Regression<N>>) -> Average.State<N> & Maybe<&2, Regression<N>>:
  match result:
    case (window, value): (Average.Average{window, kind, cache}, value)

def regress.checked(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, kind: U32, +cache: Average.Values<N>, window: Window.State<N>, origin: N, +center: N, +total: N, xy: N, xx: N, good: Bool) -> Average.State<N> & Maybe<&2, Regression<N>>:
  match good:
    case True{}: regress.restore(~N, kind, Some{cache}, regress.finish(~N, ~from, ~add, ~sub, ~mul, ~div, origin, center, (window, RegressSum{period, total, xy, xx})))
    case False{}: regress.restore(~N, kind, Some{cache}, regress.ready(~N, ~from, ~add, ~sub, ~mul, ~div, Window.full(~N, window)))

def regress.conditioned(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, period: U32, +origin: N, +center: N, total: N, +weight: N, +center_sum: N, +xy: N, xx: N) -> Bool:
  +mean = add(origin, div(total, from(period)))
  +slope = div(xy, xx)
  +offset = mul(slope, center)
  Bool.and(le(abs(origin), mul(from(8), abs(mean))), Bool.and(Bool.and(Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, weight, xy), Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, center_sum, xy)), Bool.and(Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, mean, sub(mean, offset)), Bool.and(Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, mean, add(mean, offset)), Average.stable(~N, ~from, ~sub, ~mul, ~abs, ~le, mean, add(mean, mul(slope, add(center, from(1)))))))))

def regress.values(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, +period: U32, kind: U32, +cache: Average.Values<N>, window: Window.State<N>) -> Average.State<N> & Maybe<&2, Regression<N>>:
  match cache:
    case Average.Values{+origin, total, weighted, left, divisor}:
      +count = from(period)
      +center = div(from(U32.sub(period, 1)), from(2))
      +sum = Average.sum.value(~N, total)
      +weight = Average.sum.value(~N, weighted)
      +center_sum = mul(add(center, from(1)), sum)
      +xy = sub(weight, center_sum)
      +xx = div(mul(count, sub(mul(count, count), from(1))), from(12))
      regress.checked(~N, ~from, ~add, ~sub, ~mul, ~div, period, kind, cache, window, origin, center, sum, xy, xx, regress.conditioned(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, origin, center, sum, weight, center_sum, xy, xx))

def regress.output(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, result: Average.State<N> & Maybe<&2, N>) -> Average.State<N> & Maybe<&2, Regression<N>>:
  match result:
    case (Average.Average{window, kind, None{}}, value): (Average.Average{window, kind, None{}}, None{})
    case (Average.Average{Window.Window{buffer, +period, size, pos}, kind, Some{cache}}, value): regress.values(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, period, kind, cache, Window.Window{buffer, period, size, pos})

def regress.cached(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: Average.State<N>, price: N) -> Average.State<N> & Maybe<&2, Regression<N>>:
  regress.output(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, state, price))

type Extrema<-N: Data> is Data:
  Extrema{low: N, high: N, low_index: U32, high_index: U32}

type Extremes<-N: Data> is Type:
  Extremes{range: Queue.State<N>, seen: U32}

def extreme.init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat) -> Extremes<N>:
  Extremes{Queue.init(~N, ~from, period, depth), 0}

def extreme.output(~N: Data, +seen: U32, result: Queue.State<N> & Maybe<&2, Queue.Value<N>>) -> Extremes<N> & Maybe<&2, Extrema<N>>:
  match result:
    case (range, None{}): (Extremes{range, seen}, None{})
    case (range, Some{Queue.Value{low, high, low_age, high_age, size}}): (Extremes{range, seen}, Some{Extrema{low, high, U32.sub(U32.sub(seen, 1), low_age), U32.sub(U32.sub(seen, 1), high_age)}})

def extreme.next(~N: Data, ~le: N -> N -> Bool, state: Extremes<N>, +price: N) -> Extremes<N> & Maybe<&2, Extrema<N>>:
  match state:
    case Extremes{range, seen}: extreme.output(~N, U32.add(seen, 1), Queue.next(~N, ~le, ~(a => b => le(b, a)), range, price, price))

def list.step(~N: Data, u: Unit, xs: List<&2, N>, x: N) -> List<&2, N>:
  x <> xs

type Quantile<-N: Data> is Data:
  Quantile{at: U32, lower_at: U32, lower: N, upper: N, found: Bool}

def quantile.step(~N: Data, ~from: U32 -> N, ~le: N -> N -> Bool, +position: N, acc: Quantile<N>, +x: N) -> Quantile<N>:
  match acc:
    case Quantile{+at, lower_at, lower, upper, +found}:
      +below = le(from(at), position)
      Quantile{U32.add(at, 1), Bool.pick(U32, below, at, lower_at), Bool.pick(N, below, x, lower), Bool.pick(N, Bool.or(below, Bool.not(found)), x, upper), Bool.or(found, Bool.not(below))}

def quantile.fold(~N: Data, ~from: U32 -> N, ~le: N -> N -> Bool, +position: N, xs: List<&2, N>, acc: Quantile<N>) -> Quantile<N>:
  match xs:
    case Nil{}: acc
    case x <> rest: quantile.fold(~N, ~from, ~le, position, rest, quantile.step(~N, ~from, ~le, position, acc, x))

def quantile.value(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, position: N, acc: Quantile<N>) -> N:
  match acc:
    case Quantile{at, lower_at, +lower, upper, found}: add(lower, mul(sub(upper, lower), sub(position, from(lower_at))))

def quantile.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, +position: N, result: Window.State<N> & List<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, xs): (window, Some{quantile.value(~N, ~from, ~add, ~sub, ~mul, position, quantile.fold(~N, ~from, ~le, position, Ordered.sort(~N, ~le, xs), Quantile{0, 0, from(0), from(0), False{}}))})

def quantile.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, percent: N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): quantile.finish(~N, ~from, ~add, ~sub, ~mul, ~le, div(mul(percent, from(U32.sub(period, 1))), from(100)), Window.fold(~N, ~Unit, ~List<&2, N>, ~(u => a => x => list.step(~N, u, a, x)), Window.Window{buffer, period, size, pos}, Unit{}, Nil{}))

def quantile.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, percent: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): quantile.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, percent, Window.full(~N, window))

def quantile.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, window: Window.State<N>, price: N, percent: N) -> Window.State<N> & Maybe<&2, N>:
  quantile.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, percent, Window.push(~N, window, price))

def rank.step(~N: Data, ~lt: N -> N -> Bool, current: N, count: U32, previous: N) -> U32:
  U32.add(count, Bool.pick(U32, lt(previous, current), 1, 0))

def rank.push(~N: Data, value: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): (window, Some{value})

def rank.finish(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, period: U32, +price: N, result: Window.State<N> & U32) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, count): rank.push(~N, div(mul(from(count), from(100)), from(period)), Window.push(~N, window, price))

def rank.warm(~N: Data, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): (window, None{})

def rank.ready(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, +price: N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): rank.warm(~N, Window.push(~N, window, price))
    case (Window.Window{buffer, +period, size, pos}, True{}): rank.finish(~N, ~from, ~mul, ~div, period, price, Window.fold(~N, ~N, ~U32, ~(c => a => x => rank.step(~N, ~lt, c, a, x)), Window.Window{buffer, period, size, pos}, price, 0))

def rank.next(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, window: Window.State<N>, price: N) -> Window.State<N> & Maybe<&2, N>:
  rank.ready(~N, ~from, ~mul, ~div, ~lt, price, Window.full(~N, window))

def deviation.step(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~abs: N -> N, center: Moments.Center<N>, sum: N, price: N) -> N:
  match center:
    case Moments.Center{origin, mean_delta}: add(sum, abs(sub(sub(price, origin), mean_delta)))

def deviation.finish(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, count: U32, result: Window.State<N> & N) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, sum): (window, Some{div(sum, from(count))})

def deviation.centered(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, +count: U32, origin: N, result: Window.State<N> & N) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, sum): deviation.finish(~N, ~from, ~div, count, Window.fold(~N, ~Moments.Center<N>, ~N, ~(c => a => x => deviation.step(~N, ~add, ~sub, ~abs, c, a, x)), window, Moments.Center{origin, div(sum, from(count))}, from(0)))

def deviation.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, count: U32, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{+origin}): deviation.centered(~N, ~from, ~add, ~sub, ~div, ~abs, count, origin, Window.fold(~N, ~N, ~N, ~(c => a => x => Moments.delta(~N, ~add, ~sub, c, a, x)), window, origin, from(0)))

def deviation.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): deviation.anchor(~N, ~from, ~add, ~sub, ~div, ~abs, period, Window.lag(~N, Window.Window{buffer, period, size, pos}, 0))

def deviation.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): deviation.ready(~N, ~from, ~add, ~sub, ~div, ~abs, Window.full(~N, window))

def deviation.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, window: Window.State<N>, price: N) -> Window.State<N> & Maybe<&2, N>:
  deviation.pushed(~N, ~from, ~add, ~sub, ~div, ~abs, Window.push(~N, window, price))

type ParameterWindow<-N: Data> is Type:
  ParameterWindow{window: Window.State<N>, parameter: N}

type Standard<-N: Data> is Type:
  Standard{moments: Moments.Cached<N>, factor: N}

type MinMax<-N: Data> is Data:
  MinMax{min: N, max: N}

type MinMaxIndex is Data:
  MinMaxIndex{min_index: U32, max_index: U32}

def parameter.output(~N: Data, parameter: N, result: Window.State<N> & Maybe<&2, N>) -> ParameterWindow<N> & Maybe<&2, N>:
  match result:
    case (window, value): (ParameterWindow{window, parameter}, value)

def standard.finish(~N: Data, ~mul: N -> N -> N, ~sqrt: N -> N, +factor: N, result: Moments.Cached<N> & Maybe<&2, Moments.Value<N>>) -> Standard<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (Standard{window, factor}, None{})
    case (window, Some{Moments.Moments{mean, variance}}): (Standard{window, factor}, Some{mul(factor, sqrt(variance))})

def standard.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: Standard<N>, price: N) -> Standard<N> & Maybe<&2, N>:
  match state:
    case Standard{window, factor}: standard.finish(~N, ~mul, ~sqrt, factor, Moments.cached.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, window, price))

def nearest.collect(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, +target: N, xs: List<&2, N>, +at: U32, value: N, +found: Bool) -> N:
  match xs:
    case Nil{}: value
    case x <> Nil{}: Bool.pick(N, found, value, x)
    case x <> rest: nearest.collect(~N, ~from, ~mul, ~le, target, rest, U32.add(at, 1), Bool.pick(N, found, value, x), Bool.or(found, le(target, mul(from(U32.add(at, 1)), from(100)))))

def nearest.fold(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, target: N, xs: List<&2, N>, at: U32) -> N:
  nearest.collect(~N, ~from, ~mul, ~le, target, xs, at, from(0), False{})

def nearest.finish(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, target: N, result: Window.State<N> & List<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, xs): (window, Some{nearest.fold(~N, ~from, ~mul, ~le, target, Ordered.sort(~N, ~le, xs), 0)})

def nearest.ready(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, percent: N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): nearest.finish(~N, ~from, ~mul, ~le, mul(percent, from(period)), Window.fold(~N, ~Unit, ~List<&2, N>, ~(u => a => x => list.step(~N, u, a, x)), Window.Window{buffer, period, size, pos}, Unit{}, Nil{}))

def nearest.pushed(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, percent: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): nearest.ready(~N, ~from, ~mul, ~le, percent, Window.full(~N, window))

def percentile.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, state: ParameterWindow<N>, price: N) -> ParameterWindow<N> & Maybe<&2, N>:
  match state:
    case ParameterWindow{window, +percent}: parameter.output(~N, percent, nearest.pushed(~N, ~from, ~mul, ~le, percent, Window.push(~N, window, price)))


def angle(~N: Data, ~from: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~atan: N -> N, value: Regression<N>) -> N:
  match value:
    case Regression{intercept, slope, endpoint, forecast}: mul(atan(slope), div(from(180), mul(from(4), atan(from(1)))))
