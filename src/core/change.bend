import Base
import ./window.bend as Window

def nonzero(~N: Data, ~from_u32: U32 -> N, ~view: N -> N -> N, current: N, previous: N, zero: Bool) -> N:
  match zero:
    case True{}: from_u32(0)
    case False{}: view(current, previous)

def guarded(~N: Data, ~from_u32: U32 -> N, ~eq: N -> N -> Bool, ~view: N -> N -> N, current: N, +previous: N) -> N:
  nonzero(~N, ~from_u32, ~view, current, previous, eq(previous, from_u32(0)))

def percent(~N: Data, ~from_u32: U32 -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, current: N, +previous: N) -> N:
  mul(div(sub(current, previous), previous), from_u32(100))

def fraction(~N: Data, ~sub: N -> N -> N, ~div: N -> N -> N, current: N, +previous: N) -> N:
  div(sub(current, previous), previous)

def ratio100(~N: Data, ~from_u32: U32 -> N, ~mul: N -> N -> N, ~div: N -> N -> N, current: N, previous: N) -> N:
  mul(div(current, previous), from_u32(100))

def pushed(~N: Data, ~view: N -> N -> N, current: N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, N>:
  match result:
    case (window, None{}):
      (window, None{})
    case (window, Some{previous}):
      (window, Some{view(current, previous)})

def next(~N: Data, ~view: N -> N -> N, window: Window.State<N>, +current: N) -> Window.State<N> & Maybe<&2, N>:
  pushed(~N, ~view, current, Window.push(~N, window, current))
