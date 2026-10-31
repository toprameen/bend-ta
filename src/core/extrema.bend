import Base
import ./window.bend as Window

type Value<-N: Data> is Data:
  Range{low: N, high: N}

def step(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, u: Unit, acc: Maybe<&2, Value<N>>, +price: N) -> Maybe<&2, Value<N>>:
  match acc:
    case None{}:
      Some{Range{price, price}}
    case Some{Range{low, high}}:
      Some{Range{min(low, price), max(high, price)}}

def ready(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, result: Window.State<N> & Bool) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, False{}):
      (window, None{})
    case (window, True{}):
      Window.fold(~N, ~Unit, ~Maybe<&2, Value<N>>, ~(u => acc => x => step(~N, ~min, ~max, u, acc, x)), window, Unit{}, None{})

def read(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, window: Window.State<N>) -> Window.State<N> & Maybe<&2, Value<N>>:
  ready(~N, ~min, ~max, Window.full(~N, window))

def pushed(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, result: Window.State<N> & Maybe<&2, N>) -> Window.State<N> & Maybe<&2, Value<N>>:
  match result:
    case (window, old):
      read(~N, ~min, ~max, window)

def next(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, window: Window.State<N>, price: N) -> Window.State<N> & Maybe<&2, Value<N>>:
  pushed(~N, ~min, ~max, Window.push(~N, window, price))
