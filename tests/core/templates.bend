import Base
import ../../scripts/assert.bend as Assert
import ../../src/core/extrema_queue.bend as Queue
import ../../src/core/extrema.bend as Extrema
import ../../src/core/ema.bend as Ema
import ../../src/core/sma.bend as Sma
import ../../src/core/series.bend as Series
import ../../src/core/window.bend as Window
import ../../src/core/moments.bend as Moments
import ../../src/core/change.bend as Change
import ../../src/core/transform.bend as Transform
import ../../src/core/bar.bend as Bar
import ../../src/core/vidya.bend as Vidya
import ../../src/core/statistics_window.bend as Pair

type Number is Data:
  Number{value: F32, marker: U32}

def from_u32(n: U32) -> Number:
  Number{U32.to_f32(n), 77}

def add(a: Number, b: Number) -> Number:
  match a b:
    case Number{x, m} Number{y, n}:
      Number{F32.add(x, y), 77}

def sub(a: Number, b: Number) -> Number:
  match a b:
    case Number{x, m} Number{y, n}:
      Number{F32.sub(x, y), 77}

def mul(a: Number, b: Number) -> Number:
  match a b:
    case Number{x, m} Number{y, n}:
      Number{F32.mul(x, y), 77}

def div(a: Number, b: Number) -> Number:
  match a b:
    case Number{x, m} Number{y, n}:
      Number{F32.div(x, y), 77}

def ema_step(state: Ema.State<Number>, price: Number) -> Ema.State<Number> & Maybe<&2, Number>:
  Ema.next(~Number, ~from_u32, ~add, ~sub, ~mul, ~div, state, price)

def sma_step(state: Sma.State<Number>, price: Number) -> Sma.State<Number> & Maybe<&2, Number>:
  Sma.next(~Number, ~from_u32, ~add, ~sub, ~div, state, price)

def same_number(actual: Number, expected: Number) -> Bool:
  match actual expected:
    case Number{x, marker} Number{y, wanted}: Bool.and(F32.is_eq(x, y), U32.is_eq(marker, wanted))

def expected_number(value: F32) -> Number:
  Number{value, 77}

def moments_step(state: Window.State<Number>, price: Number) -> Window.State<Number> & Maybe<&2, Moments.Value<Number>>:
  Moments.next(~Number, ~from_u32, ~add, ~sub, ~mul, ~div, state, price)

def same_moments(actual: Moments.Value<Number>, expected: Moments.Value<Number>) -> Bool:
  match actual expected:
    case Moments.Moments{mean, variance} Moments.Moments{want_mean, want_variance}:
      Bool.and(same_number(mean, want_mean), same_number(variance, want_variance))

def eq(a: Number, b: Number) -> Bool:
  match a b:
    case Number{x, m} Number{y, n}: F32.is_eq(x, y)

def le(a: Number, b: Number) -> Bool:
  match a b:
    case Number{x, m} Number{y, n}: F32.is_le(x, y)

def ratio_step(state: Window.State<Number>, price: Number) -> Window.State<Number> & Maybe<&2, Number>:
  Change.next(~Number, ~(x => y => Change.guarded(~Number, ~from_u32, ~eq, ~div, x, y)), state, price)

def abs(value: Number) -> Number:
  match value:
    case Number{x, marker}: Number{F32.abs(x), marker}

def vidya_step(state: Vidya.State<Number>, price: Number) -> Vidya.State<Number> & Maybe<&2, Number>:
  Vidya.next(~Number, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~le, state, price)

def cached(state: Moments.Cached<Number>, value: Number) -> Moments.Cached<Number> & Maybe<&2, Moments.Value<Number>>:
  Moments.cached.next(~Number, ~from_u32, ~add, ~sub, ~mul, ~div, ~abs, ~le, state, value)

def paired(state: Pair.PairCached<Number>, value: Number) -> Pair.PairCached<Number> & Maybe<&2, Number>:
  +value = value
  Pair.pair.cached.project(~Number, ~(v => Pair.beta.ratio(~Number, ~from_u32, ~div, ~(a => b => Bool.not(le(a, b))), v)), Pair.pair.cached.next(~Number, ~from_u32, ~add, ~sub, ~mul, ~div, ~le, state, Pair.PairValue{value, mul(from_u32(2), value)}))

def queued(state: Queue.State<Number>, price: Number) -> Queue.State<Number> & Maybe<&2, Queue.Value<Number>>:
  +value = price
  Queue.next(~Number, ~le, ~(a => b => le(b, a)), state, value, value)

def queued_value(value: Queue.Value<Number>) -> Extrema.Value<Number>:
  match value:
    case Queue.Value{low, high, low_age, high_age, size}: Extrema.Range{low, high}

def same_range(actual: Extrema.Value<Number>, expected: Extrema.Value<Number>) -> Bool:
  match actual expected:
    case Extrema.Range{low, high} Extrema.Range{want_low, want_high}:
      Bool.and(same_number(low, want_low), same_number(high, want_high))

def range(low: F32, high: F32) -> Maybe<&2, Extrema.Value<Number>>:
  Some{Extrema.Range{expected_number(low), expected_number(high)}}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("EMA adapter", Assert.series(~Number, ~same_number,
      Series.batch(~Number, ~Number, ~Ema.State<Number>, ~ema_step, [from_u32(3), from_u32(6), from_u32(9), from_u32(15)], Ema.init(~Number, ~from_u32, ~div, 3)),
      [None{}, None{}, Some{expected_number(6.0)}, Some{expected_number(10.5)}]))
    Unit <- Assert.check("SMA adapter", Assert.series(~Number, ~same_number,
      Series.batch(~Number, ~Number, ~Sma.State<Number>, ~sma_step, [from_u32(3), from_u32(6), from_u32(9), from_u32(12), from_u32(15)], Sma.init(~Number, ~from_u32, 3, 2n)),
      [None{}, None{}, Some{expected_number(6.0)}, Some{expected_number(9.0)}, Some{expected_number(12.0)}]))
    Unit <- Assert.check("window moments adapter", Assert.series(~Moments.Value<Number>, ~same_moments,
      Series.batch(~Number, ~Moments.Value<Number>, ~Window.State<Number>, ~moments_step, [from_u32(3), from_u32(6), from_u32(9)], Window.init(~Number, 3, 2n, from_u32(0))),
      [None{}, None{}, Some{Moments.Moments{expected_number(6.0), expected_number(6.0)}}]))
    Unit <- Assert.check("guarded ratio adapter", Assert.series(~Number, ~same_number,
      Series.batch(~Number, ~Number, ~Window.State<Number>, ~ratio_step, [from_u32(3), from_u32(0), from_u32(6), from_u32(12)], Window.init(~Number, 1, 0n, from_u32(0))),
      [None{}, Some{expected_number(0.0)}, Some{expected_number(0.0)}, Some{expected_number(2.0)}]))
    Unit <- Assert.check("IBS adapter", same_number(Transform.ibs(~Number, ~from_u32, ~sub, ~div, ~le, Bar.HLC{from_u32(8), from_u32(0), from_u32(6)}), expected_number(0.75)))
    Unit <- Assert.check("VIDYA adapter", Assert.series(~Number, ~same_number,
      Series.batch(~Number, ~Number, ~Vidya.State<Number>, ~vidya_step, [from_u32(1), from_u32(2), from_u32(4), from_u32(4)], Vidya.init(~Number, ~from_u32, ~div, 3, 2, 1n)),
      [None{}, None{}, Some{expected_number(2.75)}, Some{expected_number(3.375)}]))
    Unit <- Assert.check("extrema queue adapter", Assert.series(~Extrema.Value<Number>, ~same_range,
      Series.map(~Maybe<&2, Queue.Value<Number>>, ~Maybe<&2, Extrema.Value<Number>>,
        ~(v => Maybe.map(&2, Queue.Value<Number>, Extrema.Value<Number>, queued_value, v)),
        Series.batch(~Number, ~Queue.Value<Number>, ~Queue.State<Number>, ~queued,
          [from_u32(3), from_u32(6), from_u32(6), from_u32(1), from_u32(9), from_u32(0), from_u32(2)], Queue.init(~Number, ~from_u32, 3, 2n))),
      [None{}, None{}, range(3.0, 6.0), range(1.0, 6.0), range(1.0, 9.0), range(0.0, 9.0), range(0.0, 9.0)]))
    Unit <- Assert.check("cached moments adapter", Assert.series(~Moments.Value<Number>, ~same_moments,
      Series.batch(~Number, ~Moments.Value<Number>, ~Moments.Cached<Number>, ~cached, [from_u32(3), from_u32(6), from_u32(9), from_u32(12)], Moments.cached.init(~Number, ~from_u32, 3, 2n)),
      [None{}, None{}, Some{Moments.Moments{expected_number(6.0), expected_number(6.0)}}, Some{Moments.Moments{expected_number(9.0), expected_number(6.0)}}]))
    Assert.check("cached pair adapter", Assert.series(~Number, ~same_number,
      Series.batch(~Number, ~Number, ~Pair.PairCached<Number>, ~paired, [from_u32(3), from_u32(6), from_u32(9), from_u32(12)], Pair.pair.cached.init(~Number, ~from_u32, 3, 2n)),
      [None{}, None{}, Some{expected_number(2.0)}, Some{expected_number(2.0)}]))
