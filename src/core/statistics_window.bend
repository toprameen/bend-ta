import Base
import ./window.bend as Window
import ./moments.bend as Moments

type PairValue<-N: Data> is Data:
  PairValue{x: N, y: N}

type Cross<-N: Data> is Data:
  Cross{xx: N, yy: N, xy: N}

type PairCenter<-N: Data> is Data:
  PairCenter{origin: PairValue<N>, delta: PairValue<N>}

type Beta<-N: Data> is Type:
  Beta{previous: Maybe<&2, PairValue<N>>, window: Window.State<PairValue<N>>}

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

def beta.init(~N: Data, ~from: U32 -> N, period: U32, depth: Nat) -> Beta<N>:
  Beta{None{}, pair.init(~N, ~from, period, depth)}

def relative.if(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, +previous: N, current: N, zero: Bool) -> N:
  match zero:
    case True{}: from(0)
    case False{}: div(sub(current, previous), previous)

def relative(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, +previous: N, current: N) -> N:
  relative.if(~N, ~from, ~sub, ~div, previous, current, eq(previous, from(0)))

def beta.emit(~N: Data, previous: PairValue<N>, result: Window.State<PairValue<N>> & Maybe<&2, N>) -> Beta<N> & Maybe<&2, N>:
  match result:
    case (window, value): (Beta{Some{previous}, window}, value)

def beta.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~gt: N -> N -> Bool, state: Beta<N>, +value: PairValue<N>) -> Beta<N> & Maybe<&2, N>:
  match state value:
    case Beta{None{}, window} value: (Beta{Some{value}, window}, None{})
    case Beta{Some{PairValue{px, py}}, window} PairValue{x, y}: beta.emit(~N, value, pair.project(~N, ~(v => beta.ratio(~N, ~from, ~div, ~gt, v)), pair.next(~N, ~from, ~add, ~sub, ~mul, ~div, window, PairValue{relative(~N, ~from, ~sub, ~div, ~eq, px, x), relative(~N, ~from, ~sub, ~div, ~eq, py, y)})))

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
