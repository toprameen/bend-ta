import Base
import ./bar.bend as Bar

type Operands<-N: Data> is Data:
  Operands{left: N, right: N}

def binary(~N: Data, ~operation: N -> N -> N, inputs: Operands<N>) -> N:
  match inputs:
    case Operands{left, right}:
      operation(left, right)

def divided(~N: Data, ~div: N -> N -> N, numerator: N, denominator: N, fallback: N, use_fallback: Bool) -> N:
  match use_fallback:
    case True{}: fallback
    case False{}: div(numerator, denominator)

def bop(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool,
  bar: Bar.OHLC<N>
) -> N:
  match bar:
    case Bar.OHLC{open, high, low, close}:
      +range = sub(high, low)
      +zero = from_u32(0)
      divided(~N, ~div, sub(close, open), range, zero, le(range, zero))

def ibs(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~le: N -> N -> Bool,
  bar: Bar.HLC<N>
) -> N:
  match bar:
    case Bar.HLC{high, +low, close}:
      +range = sub(high, low)
      divided(~N, ~div, sub(close, low), range, div(from_u32(1), from_u32(2)), le(range, from_u32(0)))

def marketfi(
  ~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool,
  bar: Bar.HLV<N>
) -> N:
  match bar:
    case Bar.HLV{high, low, +volume}:
      +zero = from_u32(0)
      divided(~N, ~div, sub(high, low), volume, zero, eq(volume, zero))

def avgprice(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, bar: Bar.OHLC<N>) -> N:
  match bar:
    case Bar.OHLC{open, high, low, close}:
      div(add(add(add(high, low), close), open), from_u32(4))

def medprice(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, bar: Bar.HL<N>) -> N:
  match bar:
    case Bar.HL{high, low}:
      div(add(high, low), from_u32(2))

def typprice(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, bar: Bar.HLC<N>) -> N:
  match bar:
    case Bar.HLC{high, low, close}:
      div(add(add(high, low), close), from_u32(3))

def wclprice(~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, bar: Bar.HLC<N>) -> N:
  match bar:
    case Bar.HLC{high, low, close}:
      div(add(add(high, low), mul(close, from_u32(2))), from_u32(4))

def cumulative(~N: Data, ~add: N -> N -> N, total: N, value: N) -> N & Maybe<&2, N>:
  +next = add(total, value)
  (next, Some{next})
