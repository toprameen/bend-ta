import Base

def map.collect(~I: Data, ~O: Data, ~transform: I -> O, xs: List<&2, I>, acc: List<&2, O>) -> List<&2, O>:
  match xs:
    case Nil{}:
      List.reverse(&2, O, acc)
    case h <> t:
      map.collect(~I, ~O, ~transform, t, transform(h) <> acc)

def map(~I: Data, ~O: Data, ~transform: I -> O, xs: List<&2, I>) -> List<&2, O>:
  map.collect(~I, ~O, ~transform, xs, Nil{})

def resume(
  -O: Data, -S: Type, result: S & Maybe<&2, O>,
  rest: S -> Maybe<&2, O> -> S & List<&2, Maybe<&2, O>>
) -> S & List<&2, Maybe<&2, O>>:
  match result:
    case (state, value):
      rest(state, value)

def collect(
  ~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>,
  xs: List<&2, I>, state: S, acc: List<&2, Maybe<&2, O>>
) -> S & List<&2, Maybe<&2, O>>:
  match xs:
    case Nil{}:
      (state, List.reverse(&2, Maybe<&2, O>, acc))
    case h <> t:
      resume(O, S, step(state, h), s => v => collect(~I, ~O, ~S, ~step, t, s, v <> acc))

def scan(
  ~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>,
  xs: List<&2, I>, state: S
) -> S & List<&2, Maybe<&2, O>>:
  collect(~I, ~O, ~S, ~step, xs, state, Nil{})

def values(-O: Data, -S: Type, result: S & List<&2, Maybe<&2, O>>) -> List<&2, Maybe<&2, O>>:
  match result:
    case (state, xs):
      xs

def batch(
  ~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>,
  xs: List<&2, I>, state: S
) -> List<&2, Maybe<&2, O>>:
  values(O, S, scan(~I, ~O, ~S, ~step, xs, state))

def initialized(
  ~I: Data, ~O: Data, ~S: Type, ~E: Data, ~step: S -> I -> S & Maybe<&2, O>,
  xs: List<&2, I>, result: Result<&2, &1, E, S>
) -> Result<&2, &2, E, List<&2, Maybe<&2, O>>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{state}: Done{batch(~I, ~O, ~S, ~step, xs, state)}
