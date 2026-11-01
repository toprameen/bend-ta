import Base
import ./mama.bend as Mama
import ./window.bend as Win

type Sample<-N: Data> is Data:
  Sample{raw: N, smooth: N}

type Phasor<-N: Data> is Data:
  Phasor{in_phase: N, quadrature: N}

type Sine<-N: Data> is Data:
  Sine{sine: N, lead_sine: N}

type Value<-N: Data> is Data:
  Value{period: N, phase: N, trendline: N, phasor: Phasor<N>, waves: Sine<N>, trend: U32}

type State<-N: Data> is Type:
  State{kind: U32, count: U32, prices: Mama.Prices<N>, filters: Mama.Filters<N>, cycle: Mama.Cycle<N>, period: N, phase: N, averages: Mama.Prices<N>, waves: Sine<N>, days: U32, history: Win.State<Sample<N>>}

type Measures<-N: Data> is Data:
  Measures{raw: N, real: N, imaginary: N}

def init(~N: Data, ~from_u32: U32 -> N, kind: U32) -> State<N>:
  +zero = from_u32(0)
  +delay: Mama.Delay<N> = Mama.Delay{zero, zero, zero, zero, zero, zero}
  +prices: Mama.Prices<N> = Mama.Prices{zero, zero, zero}
  State{kind, 0, prices, Mama.Filters{delay, delay, delay, delay}, Mama.Cycle{zero, zero, zero, zero, zero, zero}, zero, zero, prices, Sine{zero, zero}, 0, Win.init(~Sample<N>, 50, 6n, Sample{zero, zero})}

def zero(~N: Data, ~from_u32: U32 -> N, ~le: N -> N -> Bool, +value: N) -> Bool:
  +z = from_u32(0)
  Bool.and(le(value, z), le(z, value))

def strict(~N: Data, ~le: N -> N -> Bool, a: N, b: N) -> Bool:
  Bool.not(le(b, a))

def scan.read(
  ~N: Data, result: Win.State<Sample<N>> & Maybe<&2, Sample<N>>,
  rest: Win.State<Sample<N>> -> Sample<N> -> Win.State<Sample<N>> & Measures<N>, +zero: N
) -> Win.State<Sample<N>> & Measures<N>:
  match result:
    case (history, None{}): rest(history, Sample{zero, zero})
    case (history, Some{sample}): rest(history, sample)

def scan.add(
  ~N: Data, ~add: N -> N -> N, ~mul: N -> N -> N, ~sin: N -> N, ~cos: N -> N,
  values: Measures<N>, +angle: N, sample: Sample<N>
) -> Measures<N>:
  match values sample:
    case Measures{raw, real, imaginary} Sample{x, +smooth}:
      Measures{add(raw, x), add(real, mul(sin(angle), smooth)), add(imaginary, mul(cos(angle), smooth))}

def scan(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~sin: N -> N, ~cos: N -> N,
  fuel: Nat, history: Win.State<Sample<N>>, +limit: U32, +at: U32, +turn: N, values: Measures<N>
) -> Win.State<Sample<N>> & Measures<N>:
  match fuel:
    case 0n: (history, values)
    case 1n+rest:
      +angle = div(mul(from_u32(at), turn), from_u32(limit))
      scan.read(~N, Win.lag(~Sample<N>, history, at), history => sample =>
        scan(~N, ~from_u32, ~add, ~mul, ~div, ~sin, ~cos, rest, history, limit, U32.add(at, 1), turn,
          scan.add(~N, ~add, ~mul, ~sin, ~cos, values, angle, sample)), from_u32(0))

def angle(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~le: N -> N -> Bool, ~atan: N -> N, previous: N, period: N, +real: N, +imaginary: N, degrees: N
) -> N:
  +z = from_u32(0)
  +base = Bool.pick(N, zero(~N, ~from_u32, ~le, imaginary),
    add(previous, Bool.pick(N, strict(~N, ~le, real, z), sub(z, from_u32(90)), Bool.pick(N, strict(~N, ~le, z, real), from_u32(90), z))),
    mul(atan(div(real, imaginary)), degrees))
  +phase = add(add(base, from_u32(90)), div(from_u32(360), period))
  +adjusted = Bool.pick(N, strict(~N, ~le, imaginary, z), add(phase, from_u32(180)), phase)
  Bool.pick(N, strict(~N, ~le, from_u32(315), adjusted), sub(adjusted, from_u32(360)), adjusted)

def trend(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool,
  +period: N, +previous: N, phase: N, old: Sine<N>, waves: Sine<N>, days: U32, smooth: N, +line: N
) -> U32 & U32:
  match old waves:
    case Sine{+old_sine, +old_lead} Sine{+sine, +lead}:
      +crossed = Bool.or(Bool.and(strict(~N, ~le, lead, sine), le(old_sine, old_lead)), Bool.and(strict(~N, ~le, sine, lead), le(old_lead, old_sine)))
      +next_days = Bool.pick(U32, crossed, 1, U32.min(U32.add(days, 1), 51))
      +delta = sub(phase, previous)
      +cycling = Bool.or(crossed, Bool.or(strict(~N, ~le, from_u32(next_days), div(period, from_u32(2))),
        Bool.and(strict(~N, ~le, div(mul(div(from_u32(67), from_u32(100)), from_u32(360)), period), delta),
          strict(~N, ~le, delta, div(mul(div(from_u32(3), from_u32(2)), from_u32(360)), period)))))
      +deviated = Bool.and(Bool.not(zero(~N, ~from_u32, ~le, line)), le(div(from_u32(15), from_u32(1000)), abs(div(sub(smooth, line), line))))
      (next_days, Bool.pick(U32, Bool.or(deviated, Bool.not(cycling)), 1, 0))

def finished(
  ~N: Data, +kind: U32, +count: U32, prices: Mama.Prices<N>, filters: Mama.Filters<N>, cycle: Mama.Cycle<N>, +period: N, +phase: N,
  averages: Mama.Prices<N>, +waves: Sine<N>, history: Win.State<Sample<N>>, line: N, phasor: Phasor<N>, result: U32 & U32
) -> State<N> & Maybe<&2, Value<N>>:
  match result:
    case (days, mode):
      (State{kind, U32.min(U32.add(count, 1), 64), prices, filters, cycle, period, phase, averages, waves, days, history},
        Bool.pick(Maybe<&2, Value<N>>, U32.is_ge(count, 63), Some{Value{period, phase, line, phasor, waves, mode}}, None{}))

def averages.next(~N: Data, prices: Mama.Prices<N>, value: N) -> Mama.Prices<N>:
  match prices:
    case Mama.Prices{one, two, three}: Mama.Prices{value, one, two}

def finish(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~to_u32: N -> U32, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~sin: N -> N, ~cos: N -> N,
  +kind: U32, +count: U32, prices: Mama.Prices<N>, filters: Mama.Filters<N>, cycle: Mama.Cycle<N>, +period: N, +previous: N,
  +averages: Mama.Prices<N>, old_waves: Sine<N>, days: U32, +smooth: N, phasor: Phasor<N>, +limit: U32,
  result: Win.State<Sample<N>> & Measures<N>
) -> State<N> & Maybe<&2, Value<N>>:
  match result:
    case (history, Measures{raw, real, imaginary}):
      +one = from_u32(1)
      +degrees = div(from_u32(180), mul(from_u32(4), atan(one)))
      +phase = angle(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~le, ~atan, previous, period, real, imaginary, degrees)
      +radians = div(one, degrees)
      +waves: Sine<N> = Sine{sin(mul(phase, radians)), sin(mul(add(phase, from_u32(45)), radians))}
      +average = Bool.pick(N, U32.is_zero(limit), from_u32(0), div(raw, from_u32(limit)))
      +line = Mama.smooth(~N, ~from_u32, ~add, ~sub, ~mul, ~div, averages, average)
      finished(~N, kind, count, prices, filters, cycle, period, phase, averages.next(~N, averages, average), waves, history, line, phasor,
        trend(~N, ~from_u32, ~sub, ~mul, ~div, ~abs, ~le, period, previous, phase, old_waves, waves, days, smooth, line))

def rounded.checked(~N: Data, ~to_u32: N -> U32, value: N, valid: Bool) -> U32:
  match valid:
    case False{}: 0
    case True{}: U32.min(to_u32(value), 50)

def rounded(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, ~to_u32: N -> U32, ~le: N -> N -> Bool, period: N) -> U32:
  +value = add(period, div(from_u32(1), from_u32(2)))
  rounded.checked(~N, ~to_u32, value, Bool.and(le(from_u32(0), value), le(value, from_u32(51))))

def transformed.output(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~to_u32: N -> U32, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~sin: N -> N, ~cos: N -> N,
  +kind: U32, +count: U32, prices: Mama.Prices<N>, filters: Mama.Filters<N>, cycle: Mama.Cycle<N>, +period: N, +previous: N,
  averages: Mama.Prices<N>, +waves: Sine<N>, days: U32, smooth: N, phasor: Phasor<N>, history: Win.State<Sample<N>>, short: Bool
) -> State<N> & Maybe<&2, Value<N>>:
  match short:
    case True{}:
      (State{kind, U32.min(U32.add(count, 1), 64), prices, filters, cycle, period, previous, averages, waves, days, history},
        Bool.pick(Maybe<&2, Value<N>>, U32.is_ge(count, 32), Some{Value{period, from_u32(0), from_u32(0), phasor, waves, 0}}, None{}))
    case False{}:
      +limit = rounded(~N, ~from_u32, ~add, ~div, ~to_u32, ~le, period)
      +z = from_u32(0)
      finish(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~to_u32, ~abs, ~le, ~atan, ~sin, ~cos, kind, count, prices, filters, cycle, period, previous, averages, waves, days, smooth, phasor, limit,
        scan(~N, ~from_u32, ~add, ~mul, ~div, ~sin, ~cos, U32.to_nat(limit), history, limit, 0, mul(from_u32(8), atan(from_u32(1))), Measures{z, z, z}))

def transformed(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~to_u32: N -> U32, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~sin: N -> N, ~cos: N -> N,
  +kind: U32, +count: U32, prices: Mama.Prices<N>, old_cycle: Mama.Cycle<N>, old_period: N, previous: N,
  averages: Mama.Prices<N>, +waves: Sine<N>, days: U32, +smooth: N, history: Win.State<Sample<N>>, transform: Mama.Transform<N>
) -> State<N> & Maybe<&2, Value<N>>:
  match old_cycle transform:
    case Mama.Cycle{+period, old_phase, +old_i2, +old_q2, +old_re, +old_im} Mama.Transform{filters, +i1, +q1, ji, jq}:
      +z = from_u32(0)
      +fifth = div(from_u32(1), from_u32(5))
      +four_fifths = div(from_u32(4), from_u32(5))
      +degrees = div(from_u32(180), mul(from_u32(4), atan(from_u32(1))))
      +q2 = add(mul(fifth, add(q1, ji)), mul(four_fifths, old_q2))
      +i2 = add(mul(fifth, sub(i1, jq)), mul(four_fifths, old_i2))
      +re = add(mul(fifth, add(mul(i2, old_i2), mul(q2, old_q2))), mul(four_fifths, old_re))
      +im = add(mul(fifth, sub(mul(i2, old_q2), mul(q2, old_i2))), mul(four_fifths, old_im))
      +new_period = Mama.period(~N, ~from_u32, ~add, ~mul, ~div, ~le, period,
        Mama.measured(~N, ~from_u32, ~mul, ~div, ~atan, period, re, im, degrees, Bool.or(zero(~N, ~from_u32, ~le, re), zero(~N, ~from_u32, ~le, im))))
      +smoothed = add(mul(div(from_u32(33), from_u32(100)), new_period), mul(div(from_u32(67), from_u32(100)), old_period))
      +cycle: Mama.Cycle<N> = Mama.Cycle{new_period, z, i2, q2, re, im}
      +phasor: Phasor<N> = Phasor{i1, q1}
      transformed.output(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~to_u32, ~abs, ~le, ~atan, ~sin, ~cos, kind, count, prices, filters, cycle, smoothed, previous, averages, waves, days, smooth, phasor, history, U32.is_lt(kind, 2))

def pushed(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~to_u32: N -> U32, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~sin: N -> N, ~cos: N -> N,
  result: Win.State<Sample<N>> & Maybe<&2, Sample<N>>, warmup: Bool, +kind: U32, +count: U32, +prices: Mama.Prices<N>, filters: Mama.Filters<N>, +cycle: Mama.Cycle<N>, period: N, phase: N,
  averages: Mama.Prices<N>, +waves: Sine<N>, days: U32, +price: N, +smooth: N
) -> State<N> & Maybe<&2, Value<N>>:
  match result warmup prices:
    case (history, evicted) True{} Mama.Prices{one, two, three}:
      (State{kind, U32.add(count, 1), Mama.Prices{price, one, two}, filters, cycle, period, phase, averages, waves, days, history}, None{})
    case (history, evicted) False{} Mama.Prices{one, two, three}:
      transformed(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~to_u32, ~abs, ~le, ~atan, ~sin, ~cos, kind, count, Mama.Prices{price, one, two}, cycle, period, phase, averages, waves, days, smooth, history,
        Mama.transform(~N, ~from_u32, ~add, ~sub, ~mul, ~div, filters, smooth,
          add(mul(div(from_u32(75), from_u32(1000)), Mama.cycle_period(~N, cycle)), div(from_u32(54), from_u32(100)))))

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~to_u32: N -> U32, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, ~sin: N -> N, ~cos: N -> N, state: State<N>, +price: N
) -> State<N> & Maybe<&2, Value<N>>:
  match state:
    case State{+kind, +count, +prices, filters, cycle, period, phase, averages, waves, days, history}:
      +smooth = Bool.pick(N, U32.is_lt(count, Bool.pick(U32, U32.is_lt(kind, 2), 12, 37)), from_u32(0), Mama.smooth(~N, ~from_u32, ~add, ~sub, ~mul, ~div, prices, price))
      pushed(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~to_u32, ~abs, ~le, ~atan, ~sin, ~cos, Win.push(~Sample<N>, history, Sample{price, smooth}), U32.is_lt(count, Bool.pick(U32, U32.is_lt(kind, 2), 12, 37)), kind, count, prices, filters, cycle, period, phase, averages, waves, days, price, smooth)

def scalar(~N: Data, kind: U32, value: Value<N>) -> N:
  match kind value:
    case 0 Value{period, phase, trendline, phasor, waves, trend}: period
    case 2 Value{period, phase, trendline, phasor, waves, trend}: trendline
    case _ Value{period, phase, trendline, phasor, waves, trend}: phase

def project(
  ~N: Data, ~O: Data, ~select: Value<N> -> O, result: State<N> & Maybe<&2, Value<N>>
) -> State<N> & Maybe<&2, O>:
  match result:
    case (state, None{}): (state, None{})
    case (state, Some{value}): (state, Some{select(value)})

def phasor(~N: Data, value: Value<N>) -> Phasor<N>:
  match value:
    case Value{period, phase, trendline, phasor, waves, trend}: phasor

def waves(~N: Data, value: Value<N>) -> Sine<N>:
  match value:
    case Value{period, phase, trendline, phasor, waves, trend}: waves

def mode(~N: Data, value: Value<N>) -> U32:
  match value:
    case Value{period, phase, trendline, phasor, waves, trend}: trend
