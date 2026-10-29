# An independent numeric representation tests the shared template seam.
# This two-field wrapper is a test adapter, not an F64 implementation.
import Base
import ../../src/core/ema.bend as Ema
import ../../src/core/sma.bend as Sma
import ../../src/core/series.bend as Series

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

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(Series.batch(~Number, ~Ema.State<Number>, ~ema_step, [from_u32(3), from_u32(6), from_u32(9), from_u32(15)], Ema.init(~Number, ~from_u32, ~div, 3))))
    IO.print(show(Series.batch(~Number, ~Sma.State<Number>, ~sma_step, [from_u32(3), from_u32(6), from_u32(9), from_u32(12), from_u32(15)], Sma.init(~Number, ~from_u32, 3, 2n))))

#|[None, None, Some(6:77), Some(10.5:77)]
#|[None, None, Some(6:77), Some(9:77), Some(12:77)]
