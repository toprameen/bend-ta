import Base
import ./window.bend as Window
import ./moments.bend as Moments
import ./rolling_average.bend as Average

type PairValue<-N: Data> is Data:
  PairValue{x: N, y: N}

type Cross<-N: Data> is Data:
  Cross{xx: N, yy: N, xy: N}

type PairCenter<-N: Data> is Data:
  PairCenter{origin: PairValue<N>, delta: PairValue<N>}

type PairSums<-N: Data> is Data:
  PairSums{x: Average.Sum<N>, y: Average.Sum<N>, xx: Average.Sum<N>, yy: Average.Sum<N>, xy: Average.Sum<N>, flat_x: Bool, flat_y: Bool}

type PairCache<-N: Data> is Data:
  PairCache{origin: PairValue<N>, sums: PairSums<N>, peak: PairValue<N>}

type PairCached<-N: Data> is Type:
  PairCached{window: Window.State<PairValue<N>>, cache: Maybe<&2, PairCache<N>>}

type Beta<-N: Data> is Type:
  Beta{previous: Maybe<&2, PairValue<N>>, window: PairCached<N>}

type Powers<-N: Data> is Data:
  Powers{second: N, fourth: N}

def pair.delta(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, origin: PairValue<N>, sum: PairValue<N>, value: PairValue<N>) -> PairValue<N>:
  match origin sum value:
    case PairValue{ox, oy} PairValue{sx, sy} PairValue{x, y}: PairValue{add(sx, sub(x, ox)), add(sy, sub(y, oy))}

def pair.cross(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, center: PairCenter<N>, sum: Cross<N>, value: PairValue<N>) -> Cross<N>:
  match center sum value:
    case PairCenter{PairValue{ox, oy}, PairValue{mx, my}} Cross{xx, yy, xy} PairValue{x, y}:
      +dx = sub(sub(x, ox), mx)
      +dy = sub(sub(y, oy), my)
      Cross{add(xx, mul(dx, dx)), add(yy, mul(dy, dy)), add(xy, mul(dx, dy))}

def pair.finish(~N: Data, result: Window.State<PairValue<N>> & Cross<N>) -> Window.State<PairValue<N>> & Maybe<&2, Cross<N>>:
  match result:
    case (window, value): (window, Some{value})

def pair.centered(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +count: N, origin: PairValue<N>, result: Window.State<PairValue<N>> & PairValue<N>) -> Window.State<PairValue<N>> & Maybe<&2, Cross<N>>:
  match result:
    case (window, PairValue{x, y}): pair.finish(~N, Window.fold(~PairValue<N>, ~PairCenter<N>, ~Cross<N>, ~(c => s => x => pair.cross(~N, ~add, ~sub, ~mul, c, s, x)), window, PairCenter{origin, PairValue{div(x, count), div(y, count)}}, Cross{from(0), from(0), from(0)}))

def pair.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, count: U32, result: Window.State<PairValue<N>> & Maybe<&2, PairValue<N>>) -> Window.State<PairValue<N>> & Maybe<&2, Cross<N>>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{+origin}): pair.centered(~N, ~from, ~add, ~sub, ~mul, ~div, from(count), origin, Window.fold(~PairValue<N>, ~PairValue<N>, ~PairValue<N>, ~(o => s => x => pair.delta(~N, ~add, ~sub, o, s, x)), window, origin, PairValue{from(0), from(0)}))

def pair.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, result: Window.State<PairValue<N>> & Bool) -> Window.State<PairValue<N>> & Maybe<&2, Cross<N>>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): pair.anchor(~N, ~from, ~add, ~sub, ~mul, ~div, period, Window.lag(~PairValue<N>, Window.Window{buffer, period, size, pos}, 0))

def pair.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, result: Window.State<PairValue<N>> & Maybe<&2, PairValue<N>>) -> Window.State<PairValue<N>> & Maybe<&2, Cross<N>>:
  match result:
    case (window, old): pair.ready(~N, ~from, ~add, ~sub, ~mul, ~div, Window.full(~PairValue<N>, window))

def pair.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, window: Window.State<PairValue<N>>, value: PairValue<N>) -> Window.State<PairValue<N>> & Maybe<&2, Cross<N>>:
  pair.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, Window.push(~PairValue<N>, window, value))

def beta.ratio.if(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, xx: N, xy: N, valid: Bool) -> N:
  match valid:
    case False{}: from(0)
    case True{}: div(xy, xx)

def beta.ratio(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, ~gt: N -> N -> Bool, value: Cross<N>) -> N:
  match value:
    case Cross{+xx, yy, xy}: beta.ratio.if(~N, ~from, ~div, xx, xy, gt(xx, from(0)))

def correl.ratio.if(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, xx: N, yy: N, xy: N, valid: Bool) -> N:
  match valid:
    case False{}: from(0)
    case True{}: max(sub(from(0), from(1)), min(from(1), div(xy, sqrt(mul(xx, yy)))))

def correl.ratio(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sqrt: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, value: Cross<N>) -> N:
  match value:
    case Cross{+xx, +yy, xy}: correl.ratio.if(~N, ~from, ~sub, ~mul, ~div, ~sqrt, ~min, ~max, xx, yy, xy, Bool.and(gt(xx, from(0)), Bool.and(gt(yy, from(0)), gt(mul(xx, yy), from(0)))))

def pair.project(~N: Data, ~project: Cross<N> -> N, result: Window.State<PairValue<N>> & Maybe<&2, Cross<N>>) -> Window.State<PairValue<N>> & Maybe<&2, N>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{value}): (window, Some{project(value)})

def pair.init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat) -> Window.State<PairValue<N>>:
  Window.init(~PairValue<N>, period, depth, PairValue{from(0), from(0)})

def pair.cached.init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat) -> PairCached<N>:
  PairCached{pair.init(~N, ~from, period, depth), None{}}

def pair.sums.zero(~N: Data, ~from: U32 -> N) -> PairSums<N>:
  +zero : Average.Sum<N> = Average.Sum{from(0), from(0)}
  PairSums{zero, zero, zero, zero, zero, True{}, True{}}

def pair.sums.add(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, origin: PairValue<N>, sums: PairSums<N>, value: PairValue<N>) -> PairSums<N>:
  match origin sums value:
    case PairValue{ox, oy} PairSums{sx, sy, xx, yy, xy, fx, fy} PairValue{x, y}:
      +dx = sub(x, ox)
      +dy = sub(y, oy)
      PairSums{Average.sum.add(~N, ~add, ~sub, sx, dx), Average.sum.add(~N, ~add, ~sub, sy, dy), Average.sum.add(~N, ~add, ~sub, xx, mul(dx, dx)), Average.sum.add(~N, ~add, ~sub, yy, mul(dy, dy)), Average.sum.add(~N, ~add, ~sub, xy, mul(dx, dy)), Bool.and(fx, Bool.and(le(dx, from(0)), le(from(0), dx))), Bool.and(fy, Bool.and(le(dy, from(0)), le(from(0), dy)))}

def pair.sums.change(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~le: N -> N -> Bool, origin: PairValue<N>, sums: PairSums<N>, old: PairValue<N>, value: PairValue<N>) -> PairSums<N>:
  match origin sums old value:
    case PairValue{+ox, +oy} PairSums{sx, sy, xx, yy, xy, fx, fy} PairValue{px, py} PairValue{x, y}:
      +dx = sub(x, ox)
      +dy = sub(y, oy)
      +rx = sub(px, ox)
      +ry = sub(py, oy)
      PairSums{Average.sum.change(~N, ~from, ~add, ~sub, sx, rx, dx), Average.sum.change(~N, ~from, ~add, ~sub, sy, ry, dy), Average.sum.change(~N, ~from, ~add, ~sub, xx, mul(rx, rx), mul(dx, dx)), Average.sum.change(~N, ~from, ~add, ~sub, yy, mul(ry, ry), mul(dy, dy)), Average.sum.change(~N, ~from, ~add, ~sub, xy, mul(rx, ry), mul(dx, dy)), Bool.and(fx, Bool.and(le(dx, from(0)), le(from(0), dx))), Bool.and(fy, Bool.and(le(dy, from(0)), le(from(0), dy)))}

def pair.sums.cross(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, period: U32, sums: PairSums<N>) -> Cross<N>:
  match sums:
    case PairSums{sx, sy, xx, yy, xy, fx, fy}:
      +x = Average.sum.value(~N, sx)
      +y = Average.sum.value(~N, sy)
      +n = from(period)
      Cross{sub(Average.sum.value(~N, xx), mul(x, div(x, n))), sub(Average.sum.value(~N, yy), mul(y, div(y, n))), sub(Average.sum.value(~N, xy), mul(x, div(y, n)))}

def pair.sums.peak(~N: Data, ~le: N -> N -> Bool, sums: PairSums<N>, peak: PairValue<N>) -> PairValue<N>:
  match sums peak:
    case PairSums{x, y, xx, yy, xy, fx, fy} PairValue{+px, +py}:
      +qx = Average.sum.value(~N, xx)
      +qy = Average.sum.value(~N, yy)
      PairValue{Bool.pick(N, le(px, qx), qx, px), Bool.pick(N, le(py, qy), qy, py)}

def pair.cache.good(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, +period: U32, sums: PairSums<N>, peak: PairValue<N>, value: Cross<N>) -> Bool:
  match sums peak value:
    case PairSums{sx, sy, qx, qy, qxy, fx, fy} PairValue{+px, +py} Cross{+xx, +yy, +xy}:
      +zero = from(0)
      +bound_x = mul(px, from(16))
      +bound_y = mul(py, from(16))
      +safe_x = Bool.or(Bool.and(fx, le(xx, zero)), Moments.energy.safe(~N, ~from, ~div, ~le, xx, period))
      +safe_y = Bool.or(Bool.and(fy, le(yy, zero)), Moments.energy.safe(~N, ~from, ~div, ~le, yy, period))
      Bool.and(safe_x, Bool.and(safe_y, Bool.and(le(sub(bound_x, bound_x), zero), Bool.and(le(sub(bound_y, bound_y), zero), Bool.and(le(sub(xx, xx), zero), Bool.and(le(sub(yy, yy), zero), Bool.and(le(sub(xy, xy), zero), Bool.and(le(div(px, from(16)), xx), le(div(py, from(16)), yy)))))))))

def pair.cross.safe(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, value: Cross<N>) -> Bool:
  match value:
    case Cross{+xx, +yy, +xy}:
      +zero = from(0)
      +magnitude = Bool.pick(N, le(xy, zero), sub(zero, xy), xy)
      +product = mul(xx, yy)
      +bounded = mul(product, from(16))
      +normal = Bool.and(Moments.energy.safe(~N, ~from, ~div, ~le, product, 1), le(sub(bounded, bounded), zero))
      Bool.or(Bool.or(le(xx, zero), le(yy, zero)), Bool.and(normal, le(div(div(yy, from(65536)), magnitude), div(magnitude, xx))))

def pair.cached.fresh(~N: Data, window: Window.State<PairValue<N>>, value: Maybe<&2, Cross<N>>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  (PairCached{window, None{}}, value)

def pair.cached.fallback(~N: Data, result: Window.State<PairValue<N>> & Maybe<&2, Cross<N>>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match result:
    case (window, value): pair.cached.fresh(~N, window, value)

def pair.cached.preserved(~N: Data, cache: PairCache<N>, result: Window.State<PairValue<N>> & Maybe<&2, Cross<N>>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match result:
    case (window, value): (PairCached{window, Some{cache}}, value)

def pair.cached.emit(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, window: Window.State<PairValue<N>>, cache: PairCache<N>, value: Cross<N>, safe: Bool) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match safe:
    case True{}: (PairCached{window, Some{cache}}, Some{value})
    case False{}: pair.cached.preserved(~N, cache, pair.ready(~N, ~from, ~add, ~sub, ~mul, ~div, Window.full(~PairValue<N>, window)))

def pair.cached.accept(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, window: Window.State<PairValue<N>>, origin: PairValue<N>, sums: PairSums<N>, peak: PairValue<N>, +value: Cross<N>, good: Bool) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match good:
    case True{}: pair.cached.emit(~N, ~from, ~add, ~sub, ~mul, ~div, window, PairCache{origin, sums, peak}, value, pair.cross.safe(~N, ~from, ~sub, ~mul, ~div, ~le, value))
    case False{}: pair.cached.fallback(~N, pair.ready(~N, ~from, ~add, ~sub, ~mul, ~div, Window.full(~PairValue<N>, window)))

def pair.cached.rebuilt(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, +period: U32, +origin: PairValue<N>, result: Window.State<PairValue<N>> & PairSums<N>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match result:
    case (window, +sums):
      +peak = pair.sums.peak(~N, ~le, sums, PairValue{from(0), from(0)})
      +value = pair.sums.cross(~N, ~from, ~sub, ~mul, ~div, period, sums)
      pair.cached.accept(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, window, origin, sums, peak, value, pair.cache.good(~N, ~from, ~sub, ~mul, ~div, ~le, period, sums, peak, value))

def pair.cached.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, period: U32, result: Window.State<PairValue<N>> & Maybe<&2, PairValue<N>>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match result:
    case (window, None{}): pair.cached.fresh(~N, window, None{})
    case (window, Some{+origin}): pair.cached.rebuilt(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, period, origin, Window.fold(~PairValue<N>, ~PairValue<N>, ~PairSums<N>, ~(o => s => x => pair.sums.add(~N, ~from, ~add, ~sub, ~mul, ~le, o, s, x)), window, origin, pair.sums.zero(~N, ~from)))

def pair.cached.full(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, window: Window.State<PairValue<N>>, full: Bool) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match window full:
    case window False{}: pair.cached.fresh(~N, window, None{})
    case Window.Window{buffer, +period, size, pos} True{}: pair.cached.anchor(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, period, Window.lag(~PairValue<N>, Window.Window{buffer, period, size, pos}, 0))

def pair.cached.rebuild(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, window: Window.State<PairValue<N>>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match window:
    case Window.Window{buffer, +period, +size, pos}: pair.cached.full(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, Window.Window{buffer, period, size, pos}, U32.is_eq(size, period))

def pair.cached.checked(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, window: Window.State<PairValue<N>>, origin: PairValue<N>, sums: PairSums<N>, peak: PairValue<N>, +value: Cross<N>, good: Bool) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match good:
    case False{}: pair.cached.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, window)
    case True{}: pair.cached.emit(~N, ~from, ~add, ~sub, ~mul, ~div, window, PairCache{origin, sums, peak}, value, pair.cross.safe(~N, ~from, ~sub, ~mul, ~div, ~le, value))

def pair.cached.updated(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, window: Window.State<PairValue<N>>, +origin: PairValue<N>, +sums: PairSums<N>, peak: PairValue<N>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match window:
    case Window.Window{buffer, +period, size, pos}:
      +next_peak = pair.sums.peak(~N, ~le, sums, peak)
      +value = pair.sums.cross(~N, ~from, ~sub, ~mul, ~div, period, sums)
      pair.cached.checked(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, Window.Window{buffer, period, size, pos}, origin, sums, next_peak, value, pair.cache.good(~N, ~from, ~sub, ~mul, ~div, ~le, period, sums, next_peak, value))

def pair.cached.select(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, cache: Maybe<&2, PairCache<N>>, input: PairValue<N>, window: Window.State<PairValue<N>>, old: Maybe<&2, PairValue<N>>, cycle: Bool) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match cache old cycle:
    case None{} Some{old} False{}: pair.cached.fallback(~N, pair.ready(~N, ~from, ~add, ~sub, ~mul, ~div, Window.full(~PairValue<N>, window)))
    case Some{PairCache{+origin, sums, peak}} Some{old} False{}: pair.cached.updated(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, window, origin, pair.sums.change(~N, ~from, ~add, ~sub, ~mul, ~le, origin, sums, old, input), peak)
    case _ _ _: pair.cached.rebuild(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, window)

def pair.cached.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, cache: Maybe<&2, PairCache<N>>, input: PairValue<N>, result: Window.State<PairValue<N>> & Maybe<&2, PairValue<N>>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match result:
    case (Window.Window{buffer, period, size, +pos}, old): pair.cached.select(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, cache, input, Window.Window{buffer, period, size, pos}, old, U32.is_zero(pos))

def pair.cached.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, state: PairCached<N>, +input: PairValue<N>) -> PairCached<N> & Maybe<&2, Cross<N>>:
  match state:
    case PairCached{window, cache}: pair.cached.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, cache, input, Window.push(~PairValue<N>, window, input))

def pair.cached.project(~N: Data, ~project: Cross<N> -> N, result: PairCached<N> & Maybe<&2, Cross<N>>) -> PairCached<N> & Maybe<&2, N>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{project(value)})

def beta.init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat) -> Beta<N>:
  Beta{None{}, pair.cached.init(~N, ~from, period, depth)}

def relative.if(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, +previous: N, current: N, zero: Bool) -> N:
  match zero:
    case True{}: from(0)
    case False{}: div(sub(current, previous), previous)

def relative(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, +previous: N, current: N) -> N:
  relative.if(~N, ~from, ~sub, ~div, previous, current, eq(previous, from(0)))

def beta.emit(~N: Data, previous: PairValue<N>, result: PairCached<N> & Maybe<&2, N>) -> Beta<N> & Maybe<&2, N>:
  match result:
    case (window, value): (Beta{Some{previous}, window}, value)

def beta.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, ~le: N -> N -> Bool, state: Beta<N>, +value: PairValue<N>) -> Beta<N> & Maybe<&2, N>:
  match state value:
    case Beta{None{}, window} value: (Beta{Some{value}, window}, None{})
    case Beta{Some{PairValue{px, py}}, window} PairValue{x, y}: beta.emit(~N, value, pair.cached.project(~N, ~(v => beta.ratio(~N, ~from, ~div, ~gt, v)), pair.cached.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, window, PairValue{relative(~N, ~from, ~sub, ~div, ~eq, px, x), relative(~N, ~from, ~sub, ~div, ~eq, py, y)})))

def fourth.step(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, center: Moments.Center<N>, sum: Powers<N>, value: N) -> Powers<N>:
  match center sum:
    case Moments.Center{origin, delta} Powers{second, fourth}:
      +d = sub(sub(value, origin), delta)
      +square = mul(d, d)
      Powers{add(second, square), add(fourth, mul(square, square))}

def fourth.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, result: Window.State<N> & Powers<N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, Powers{second, fourth}):
      +n = from(period)
      +nm1 = from(U32.sub(period, 1))
      +denom = mul(from(U32.sub(period, 2)), from(U32.sub(period, 3)))
      +variance = div(second, nm1)
      +a = div(mul(n, add(n, from(1))), mul(nm1, denom))
      +b = div(mul(from(3), mul(nm1, nm1)), denom)
      (window, Some{sub(mul(a, div(fourth, mul(variance, variance))), b)})

def fourth.centered(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, +period: U32, origin: N, result: Window.State<N> & N) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, delta): fourth.finish(~N, ~from, ~add, ~sub, ~mul, ~div, period, Window.fold(~N, ~Moments.Center<N>, ~Powers<N>, ~(c => s => x => fourth.step(~N, ~add, ~sub, ~mul, c, s, x)), window, Moments.Center{origin, div(delta, from(period))}, Powers{from(0), from(0)}))

def fourth.anchor(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, period: U32, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, None{}): (window, None{})
    case (window, Some{+origin}): fourth.centered(~N, ~from, ~add, ~sub, ~mul, ~div, period, origin, Window.fold(~N, ~N, ~N, ~(o => s => x => Moments.delta(~N, ~add, ~sub, o, s, x)), window, origin, from(0)))

def fourth.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, False{}): (window, None{})
    case (Window.Window{buffer, +period, size, pos}, True{}): fourth.anchor(~N, ~from, ~add, ~sub, ~mul, ~div, period, Window.lag(~N, Window.Window{buffer, period, size, pos}, 0))

def fourth.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, old): fourth.ready(~N, ~from, ~add, ~sub, ~mul, ~div, Window.full(~N, window))

def kurtosis.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, window: Window.State<N>, price: N) -> Window.State<N> & Maybe<&2, N>:
  fourth.pushed(~N, ~from, ~add, ~sub, ~mul, ~div, Window.push(~N, window, price))

def variance(~N: Data, value: Moments.Value<N>) -> N:
  match value:
    case Moments.Moments{mean, variance}: variance
