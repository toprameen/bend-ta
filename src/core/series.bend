import Base

# Every input has one output slot. None means the indicator is warming up.
def resume(
  -N: Data, -S: Type, result: S & Maybe<&2, N>,
  rest: S -> Maybe<&2, N> -> List<&2, Maybe<&2, N>>
) -> List<&2, Maybe<&2, N>>:
  match result:
    case (state, value):
      rest(state, value)

# Both batch and live feeds use the same step. The reverse accumulator keeps
# result construction tail-recursive instead of recursing once per list cell.
def collect(
  ~N: Data, ~S: Type, ~step: S -> N -> S & Maybe<&2, N>,
  xs: List<&2, N>, state: S, acc: List<&2, Maybe<&2, N>>
) -> List<&2, Maybe<&2, N>>:
  match xs:
    case Nil{}:
      List.reverse(&2, Maybe<&2, N>, acc)
    case h <> t:
      resume(N, S, step(state, h), s => v => collect(~N, ~S, ~step, t, s, v <> acc))

def batch(
  ~N: Data, ~S: Type, ~step: S -> N -> S & Maybe<&2, N>,
  xs: List<&2, N>, state: S
) -> List<&2, Maybe<&2, N>>:
  collect(~N, ~S, ~step, xs, state, Nil{})
