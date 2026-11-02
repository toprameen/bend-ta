# An independent numeric representation tests the shared template seam.
# This two-field wrapper is a test adapter, not an F64 implementation.
import Base
import ../../src/core/extrema_queue.bend as Queue
import ../../src/core/ema.bend as Ema
import ../../src/core/sma.bend as Sma
import ../../src/core/series.bend as Series
import ../../src/core/window.bend as Window
import ../../src/core/moments.bend as Moments
import ../../src/core/change.bend as Change
import ../../src/core/transform.bend as Transform
import ../../src/core/bar.bend as Bar
import ../../src/core/vidya.bend as Vidya

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

def number(n: Number) -> String:
  match n:
    case Number{x, marker}:
      F32.show(x) ++ ":" ++ U32.show(marker)

def value(v: Maybe<&2, Number>) -> String:
  Maybe.show(~&2, ~Number, ~number, v)

def show(xs: List<&2, Maybe<&2, Number>>) -> String:
  List.show(~&2, ~Maybe<&2, Number>, ~value, xs)

def moments_step(state: Window.State<Number>, price: Number) -> Window.State<Number> & Maybe<&2, Moments.Value<Number>>:
  Moments.next(~Number, ~from_u32, ~add, ~sub, ~mul, ~div, state, price)

def moments_value(value: Moments.Value<Number>) -> String:
  match value:
    case Moments.Moments{mean, variance}:
      number(mean) ++ "/" ++ number(variance)

def moments_show(value: Maybe<&2, Moments.Value<Number>>) -> String:
  Maybe.show(~&2, ~Moments.Value<Number>, ~moments_value, value)

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

def queued(state: Queue.State<Number>, price: Number) -> Queue.State<Number> & Maybe<&2, Queue.Value<Number>>:
  +value = price
  Queue.next(~Number, ~le, ~(a => b => le(b, a)), state, value, value)

def queued_value(value: Queue.Value<Number>) -> String:
  match value:
    case Queue.Value{low, high, low_age, high_age, size}: number(low) ++ "/" ++ number(high)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(Series.batch(~Number, ~Number, ~Ema.State<Number>, ~ema_step, [from_u32(3), from_u32(6), from_u32(9), from_u32(15)], Ema.init(~Number, ~from_u32, ~div, 3))))
    IO.print(show(Series.batch(~Number, ~Number, ~Sma.State<Number>, ~sma_step, [from_u32(3), from_u32(6), from_u32(9), from_u32(12), from_u32(15)], Sma.init(~Number, ~from_u32, 3, 2n))))
    IO.print(List.show(~&2, ~Maybe<&2, Moments.Value<Number>>, ~moments_show, Series.batch(~Number, ~Moments.Value<Number>, ~Window.State<Number>, ~moments_step, [from_u32(3), from_u32(6), from_u32(9)], Window.init(~Number, 3, 2n, from_u32(0)))))
    IO.print(show(Series.batch(~Number, ~Number, ~Window.State<Number>, ~ratio_step, [from_u32(3), from_u32(0), from_u32(6), from_u32(12)], Window.init(~Number, 1, 0n, from_u32(0)))))
    IO.print(number(Transform.ibs(~Number, ~from_u32, ~sub, ~div, ~le, Bar.HLC{from_u32(8), from_u32(0), from_u32(6)})))
    IO.print(show(Series.batch(~Number, ~Number, ~Vidya.State<Number>, ~vidya_step, [from_u32(1), from_u32(2), from_u32(4), from_u32(4)], Vidya.init(~Number, ~from_u32, ~div, 3, 2, 1n))))
    IO.print(List.show(~&2, ~Maybe<&2, Queue.Value<Number>>, ~(v => Maybe.show(~&2, ~Queue.Value<Number>, ~queued_value, v)), Series.batch(~Number, ~Queue.Value<Number>, ~Queue.State<Number>, ~queued, [from_u32(3), from_u32(6), from_u32(6), from_u32(1), from_u32(9), from_u32(0), from_u32(2)], Queue.init(~Number, ~from_u32, 3, 2n))))

#|[None, None, Some(6:77), Some(10.5:77)]
#|[None, None, Some(6:77), Some(9:77), Some(12:77)]
#|[None, None, Some(6:77/6:77)]
#|[None, Some(0:77), Some(0:77), Some(2:77)]
#|0.75:77
#|[None, None, Some(2.75:77), Some(3.375:77)]

#|[None, None, Some(3:77/6:77), Some(1:77/6:77), Some(1:77/9:77), Some(0:77/9:77), Some(0:77/9:77)]
