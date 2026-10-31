import Base

type Delay<-N: Data> is Data:
  Delay{one: N, two: N, three: N, four: N, five: N, six: N}

type Filtered<-N: Data> is Data:
  Filtered{history: Delay<N>, value: N}

type Filters<-N: Data> is Data:
  Filters{detrender: Delay<N>, quadrature: Delay<N>, in_phase: Delay<N>, advance: Delay<N>}

type Transform<-N: Data> is Data:
  Transform{filters: Filters<N>, i1: N, q1: N, ji: N, jq: N}

type Cycle<-N: Data> is Data:
  Cycle{period: N, phase: N, i2: N, q2: N, re: N, im: N}

type Prices<-N: Data> is Data:
  Prices{one: N, two: N, three: N}

type Value<-N: Data> is Data:
  Value{mama: N, fama: N}

type State<-N: Data> is Data:
  State{fast: N, slow: N, count: U32, prices: Prices<N>, filters: Filters<N>, cycle: Cycle<N>, value: Value<N>}

def init(~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, fast: N, slow: N) -> State<N>:
  +zero = from_u32(0)
  +delay: Delay<N> = Delay{zero, zero, zero, zero, zero, zero}
  State{fast, slow, 0, Prices{zero, zero, zero}, Filters{delay, delay, delay, delay}, Cycle{zero, zero, zero, zero, zero, zero}, Value{zero, zero}}

def lag3(~N: Data, delay: Delay<N>) -> N:
  match delay:
    case Delay{one, two, three, four, five, six}: three

def filter(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  delay: Delay<N>, +price: N, adjusted: N
) -> Filtered<N>:
  match delay:
    case Delay{+one, +two, +three, +four, +five, six}:
      +a = div(from_u32(962), from_u32(10000))
      +b = div(from_u32(5769), from_u32(10000))
      Filtered{Delay{price, one, two, three, four, five},
        mul(add(mul(a, sub(price, six)), mul(b, sub(two, four))), adjusted)}

def transform.finish(~N: Data, detrender: Delay<N>, quadrature: Delay<N>, i1: N, q1: N, ji: Filtered<N>, jq: Filtered<N>) -> Transform<N>:
  match ji jq:
    case Filtered{in_phase, ji} Filtered{advance, jq}:
      Transform{Filters{detrender, quadrature, in_phase, advance}, i1, q1, ji, jq}

def transform.q1(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +adjusted: N, +i1: N, detrender: Delay<N>, in_phase: Delay<N>, advance: Delay<N>, result: Filtered<N>
) -> Transform<N>:
  match result:
    case Filtered{quadrature, +q1}:
      transform.finish(~N, detrender, quadrature, i1, q1,
        filter(~N, ~from_u32, ~add, ~sub, ~mul, ~div, in_phase, i1, adjusted),
        filter(~N, ~from_u32, ~add, ~sub, ~mul, ~div, advance, q1, adjusted))

def transform.detrender(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  +adjusted: N, +quadrature: Delay<N>, in_phase: Delay<N>, advance: Delay<N>, result: Filtered<N>
) -> Transform<N>:
  match result:
    case Filtered{detrender, value}:
      transform.q1(~N, ~from_u32, ~add, ~sub, ~mul, ~div, adjusted, lag3(~N, quadrature), detrender, in_phase, advance,
        filter(~N, ~from_u32, ~add, ~sub, ~mul, ~div, quadrature, value, adjusted))

def transform(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  filters: Filters<N>, smoothed: N, +adjusted: N
) -> Transform<N>:
  match filters:
    case Filters{detrender, quadrature, in_phase, advance}:
      transform.detrender(~N, ~from_u32, ~add, ~sub, ~mul, ~div, adjusted, quadrature, in_phase, advance,
        filter(~N, ~from_u32, ~add, ~sub, ~mul, ~div, detrender, smoothed, adjusted))

def smooth(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  prices: Prices<N>, +price: N
) -> N:
  match prices:
    case Prices{one, two, three}:
      add(price, div(add(add(mul(sub(one, price), from_u32(3)), mul(sub(two, price), from_u32(2))), sub(three, price)), from_u32(10)))

def phase(
  ~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~atan: N -> N,
  i1: N, q1: N, degrees: N, zero: Bool
) -> N:
  match zero:
    case True{}: from_u32(0)
    case False{}: mul(atan(div(q1, i1)), degrees)

def alpha.choose(
  ~N: Data, ~from_u32: U32 -> N, ~div: N -> N -> N, ~le: N -> N -> Bool,
  fast: N, +slow: N, delta: N, fast_phase: Bool
) -> N:
  match fast_phase:
    case True{}: fast
    case False{}:
      +value = div(fast, delta)
      Bool.pick(N, le(value, slow), slow, value)

def alpha(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool,
  fast: N, slow: N, previous: N, phase: N
) -> N:
  +delta = sub(previous, phase)
  alpha.choose(~N, ~from_u32, ~div, ~le, fast, slow, delta, le(delta, from_u32(1)))

def measured(
  ~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~atan: N -> N,
  previous: N, re: N, im: N, degrees: N, zero: Bool
) -> N:
  match zero:
    case True{}: previous
    case False{}: div(from_u32(360), mul(atan(div(im, re)), degrees))

def period(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool,
  +previous: N, +value: N
) -> N:
  +upper = mul(div(from_u32(3), from_u32(2)), previous)
  +lower = mul(div(from_u32(67), from_u32(100)), previous)
  +a = Bool.pick(N, le(value, upper), value, upper)
  +b = Bool.pick(N, le(a, lower), lower, a)
  +c = Bool.pick(N, le(b, from_u32(6)), from_u32(6), b)
  +d = Bool.pick(N, le(c, from_u32(50)), c, from_u32(50))
  add(mul(div(from_u32(1), from_u32(5)), d), mul(div(from_u32(4), from_u32(5)), previous))

def update(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~le: N -> N -> Bool, ~atan: N -> N,
  +fast: N, +slow: N, +count: U32, prices: Prices<N>, cycle: Cycle<N>, value: Value<N>, +price: N, result: Transform<N>
) -> State<N> & Maybe<&2, Value<N>>:
  match cycle value result:
    case Cycle{+old_period, old_phase, +old_i2, +old_q2, +old_re, +old_im} Value{old_mama, old_fama} Transform{filters, +i1, +q1, ji, jq}:
      +zero = from_u32(0)
      +one = from_u32(1)
      +fifth = div(one, from_u32(5))
      +four_fifths = div(from_u32(4), from_u32(5))
      +degrees = div(from_u32(180), mul(from_u32(4), atan(one)))
      +angle = phase(~N, ~from_u32, ~mul, ~div, ~atan, i1, q1, degrees, Bool.and(le(i1, zero), le(zero, i1)))
      +a = alpha(~N, ~from_u32, ~sub, ~div, ~le, fast, slow, old_phase, angle)
      +mama = add(mul(a, price), mul(sub(one, a), old_mama))
      +half_alpha = div(a, from_u32(2))
      +fama = add(mul(half_alpha, mama), mul(sub(one, half_alpha), old_fama))
      +q2 = add(mul(fifth, add(q1, ji)), mul(four_fifths, old_q2))
      +i2 = add(mul(fifth, sub(i1, jq)), mul(four_fifths, old_i2))
      +re = add(mul(fifth, add(mul(i2, old_i2), mul(q2, old_q2))), mul(four_fifths, old_re))
      +im = add(mul(fifth, sub(mul(i2, old_q2), mul(q2, old_i2))), mul(four_fifths, old_im))
      +new_period = period(~N, ~from_u32, ~add, ~mul, ~div, ~le, old_period,
        measured(~N, ~from_u32, ~mul, ~div, ~atan, old_period, re, im, degrees,
          Bool.or(Bool.and(le(re, zero), le(zero, re)), Bool.and(le(im, zero), le(zero, im)))))
      +output: Value<N> = Value{mama, fama}
      (State{fast, slow, U32.min(U32.add(count, 1), 33), prices, filters, Cycle{new_period, angle, i2, q2, re, im}, output},
        Bool.pick(Maybe<&2, Value<N>>, U32.is_ge(count, 32), Some{output}, None{}))

def cycle_period(~N: Data, cycle: Cycle<N>) -> N:
  match cycle:
    case Cycle{period, phase, i2, q2, re, im}: period

def next.phase(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~le: N -> N -> Bool, ~atan: N -> N,
  +fast: N, +slow: N, +count: U32, +prices: Prices<N>, filters: Filters<N>, +cycle: Cycle<N>, value: Value<N>, +price: N, warmup: Bool
) -> State<N> & Maybe<&2, Value<N>>:
  match prices warmup:
    case Prices{+one, +two, three} True{}:
      (State{fast, slow, U32.add(count, 1), Prices{price, one, two}, filters, cycle, value}, None{})
    case Prices{+one, +two, three} False{}:
      update(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~le, ~atan, fast, slow, count, Prices{price, one, two}, cycle, value, price,
        transform(~N, ~from_u32, ~add, ~sub, ~mul, ~div, filters, smooth(~N, ~from_u32, ~add, ~sub, ~mul, ~div, prices, price),
          add(mul(div(from_u32(75), from_u32(1000)), cycle_period(~N, cycle)), div(from_u32(54), from_u32(100)))))

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~le: N -> N -> Bool, ~atan: N -> N,
  state: State<N>, price: N
) -> State<N> & Maybe<&2, Value<N>>:
  match state:
    case State{fast, slow, +count, prices, filters, cycle, value}:
      next.phase(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~le, ~atan, fast, slow, count, prices, filters, cycle, value, price, U32.is_lt(count, 12))
