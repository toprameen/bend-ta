import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./ma.bend as Ma
import ./rolling_average.bend as Average
import ./moments.bend as Moments
import ./statistics.bend as Stats
import ./momentum_window.bend as Box
import ./volatility.bend as Volatility

type Factors<-N: Data> is Data:
  Factors{deviations: N, wide: N, normal: N, narrow: N}


type State<-N: Data> is Type:
  Squeeze{box: Box.Box<N>, bands: Window.State<N>, center: Average.State<N>, range: Average.State<N>, regression: Average.State<N>, previous: Maybe<&2, N>, factors: Factors<N>}


type Value<-N: Data> is Data:
  SqueezeValue{momentum: N, negative: Bool, strength: U32}


def init(~N: Data, ~from: U32 -> N, +bb: U32, +kc: U32, deviations: N, wide: N, normal: N, narrow: N) -> State<N>:
  Squeeze{Box.box.init(~N, ~from, kc, Ma.buffer_depth(kc)), Window.init(~N, bb, Ma.buffer_depth(bb), from(0)), Average.init(~N, ~from, kc, Ma.buffer_depth(kc), 0), Average.init(~N, ~from, kc, Ma.buffer_depth(kc), 0), Stats.regress.init(~N, ~from, kc, Ma.buffer_depth(kc)), None{}, Factors{deviations, wide, normal, narrow}}


def inside(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~lt: N -> N -> Bool, +center: N, +range: N, lower: N, upper: N, +factor: N) -> Bool:
  +width = mul(factor, range)
  Bool.and(lt(sub(center, width), lower), lt(upper, add(center, width)))


def value(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, factors: Factors<N>, bands: Moments.Value<N>, +center: N, +range: N, momentum: N) -> Value<N>:
  match factors bands:
    case Factors{deviations, +wide, +normal, +narrow} Moments.Moments{+mean, variance}:
      +width = mul(deviations, sqrt(variance))
      +lower = sub(mean, width)
      +upper = add(mean, width)
      +in_narrow = inside(~N, ~add, ~sub, ~mul, ~lt, center, range, lower, upper, narrow)
      +in_normal = inside(~N, ~add, ~sub, ~mul, ~lt, center, range, lower, upper, normal)
      +in_wide = inside(~N, ~add, ~sub, ~mul, ~lt, center, range, lower, upper, wide)
      +out = Bool.and(lt(lower, sub(center, mul(wide, range))), lt(add(center, mul(wide, range)), upper))
      +level = Bool.pick(U32, in_narrow, 3, Bool.pick(U32, in_normal, 2, Bool.pick(U32, Bool.or(in_wide, out), 1, 0)))
      SqueezeValue{momentum, Bool.and(Bool.not(in_wide), out), level}


def emitted(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, box: Box.Box<N>, bands: Window.State<N>, center: Average.State<N>, range: Average.State<N>, previous: Maybe<&2, N>, +factors: Factors<N>, +kc: N, result: Average.State<N> & Maybe<&2, Stats.Regression<N>>, bb: Maybe<&2, Moments.Value<N>>, tr: Maybe<&2, N>) -> State<N> & Maybe<&2, Value<N>>:
  match result bb tr:
    case (regression, Some{Stats.Regression{intercept, slope, endpoint, forecast}}) Some{moments} Some{span}: (Squeeze{box, bands, center, range, regression, previous, factors}, Some{value(~N, ~add, ~sub, ~mul, ~lt, ~sqrt, factors, moments, kc, span, endpoint)})
    case (regression, _) _ _: (Squeeze{box, bands, center, range, regression, previous, factors}, None{})


def ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, ~sqrt: N -> N, ~abs: N -> N, ~le: N -> N -> Bool, state: State<N>, +price: N, bounds: Maybe<&2, Box.Bounds<N>>, kc: Maybe<&2, N>, bb: Maybe<&2, Moments.Value<N>>, tr: Maybe<&2, N>) -> State<N> & Maybe<&2, Value<N>>:
  match state bounds kc:
    case Squeeze{box, bands, center, range, regression, previous, factors} Some{Box.Bounds{size, high, low, up, down, close}} Some{+mean}:
      +dev = sub(price, div(add(div(add(high, low), from(2)), mean), from(2)))
      emitted(~N, ~add, ~sub, ~mul, ~lt, ~sqrt, box, bands, center, range, previous, factors, mean, Stats.regress.cached(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, regression, dev), bb, tr)
    case _ _ _: (state, None{})


def with(~N: Data, ~A: Type, ~B: Data, result: A & Maybe<&2, B>, continue: A -> Maybe<&2, B> -> State<N> & Maybe<&2, Value<N>>) -> State<N> & Maybe<&2, Value<N>>:
  match result:
    case (state, value): continue(state, value)


def range.emitted(~N: Data, previous: Maybe<&2, N>, result: Average.State<N> & Maybe<&2, N>) -> Maybe<&2, N> & Average.State<N> & Maybe<&2, N>:
  match result:
    case (range, value): (previous, range, value)


def range.pushed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~mul: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, range: Average.State<N>, result: Maybe<&2, N> & Maybe<&2, N>) -> Maybe<&2, N> & Average.State<N> & Maybe<&2, N>:
  match result:
    case (previous, None{}): (previous, range, None{})
    case (previous, Some{value}): range.emitted(~N, previous, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, range, value))


def ranged(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, ~sqrt: N -> N, ~abs: N -> N, box: Box.Box<N>, bands: Window.State<N>, center: Average.State<N>, regression: Average.State<N>, factors: Factors<N>, result: Maybe<&2, N> & Average.State<N> & Maybe<&2, N>, +bar: Bar.HLC<N>) -> State<N> & Maybe<&2, Value<N>>:
  match result bar:
    case (previous, range, tr) Bar.HLC{high, low, +price}:
      with(~N, ~Box.Box<N>, ~Box.Bounds<N>, Box.box.next(~N, ~(x => y => le(y, x)), ~le, box, bar), box => bounds =>
        with(~N, ~Window.State<N>, ~Moments.Value<N>, Moments.next(~N, ~from, ~add, ~sub, ~mul, ~div, bands, price), bands => bb =>
          with(~N, ~Average.State<N>, ~N, Average.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, center, price), center => kc =>
            ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~lt, ~sqrt, ~abs, ~le, Squeeze{box, bands, center, range, regression, previous, factors}, price, bounds, kc, bb, tr))))


def next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, ~sqrt: N -> N, state: State<N>, +bar: Bar.HLC<N>) -> State<N> & Maybe<&2, Value<N>>:
  match state:
    case Squeeze{box, bands, center, range, regression, previous, factors}: ranged(~N, ~from, ~add, ~sub, ~mul, ~div, ~le, ~lt, ~sqrt, ~abs, box, bands, center, regression, factors, range.pushed(~N, ~from, ~add, ~sub, ~div, ~mul, ~abs, ~le, range, Volatility.range.next(~N, ~sub, ~abs, ~max, previous, bar)), bar)
