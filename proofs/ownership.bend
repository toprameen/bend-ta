import Base
import ../src/core/clone.bend as Clone
import ../src/core/window.bend as Window
import ../src/core/rolling.bend as Rolling
import ../src/core/sma.bend as Sma
import ../src/core/moments.bend as Moments
import ../src/core/statistics_window.bend as StatisticsWindow

law array_clone:
  for ~A: Data
  for value: Array<A>
  {(value, value) == Array.clone(A, value) : Array<A> & Array<A>}

def array_clone(A, value):
  match value:
    case ALeaf{x}:
      {==}
    case ANode{xs, ys}:
      %array_clone(~A, xs) : {(ANode{xs, ys}, ANode{xs, ys}) == Array.clone.node(A, _, Array.clone(A, ys)) : Array<A> & Array<A>}
      %array_clone(~A, ys) : {(ANode{xs, ys}, ANode{xs, ys}) == Array.clone.node(A, (xs, xs), _) : Array<A> & Array<A>}
      {==}

law window_clone:
  for ~A: Data
  for state: Window.State<A>
  {(state, state) == Clone.window(~A, state) : Window.State<A> & Window.State<A>}

def window_clone(A, state):
  match state:
    case Window.Window{buffer, period, size, pos}:
      %array_clone(~A, buffer) : {(Window.Window{buffer, period, size, pos}, Window.Window{buffer, period, size, pos}) == Clone.pair(~Array<A>, ~(Window.State<A> & Window.State<A>), _, a => b => (Window.Window{a, period, size, pos}, Window.Window{b, period, size, pos})) : Window.State<A> & Window.State<A>}
      {==}

law data_clone:
  for ~A: Data
  for value: A
  {(value, value) == Clone.data(~A, value) : A & A}

def data_clone(A, value):
  {==}

law rolling_clone:
  for ~N: Data
  for state: Rolling.State<N>
  {(state, state) == Clone.rolling(~N, state) : Rolling.State<N> & Rolling.State<N>}

def rolling_clone(N, state):
  match state:
    case Rolling.Sum{window, total}:
      %window_clone(~N, window) : {(Rolling.Sum{window, total}, Rolling.Sum{window, total}) == Clone.pair(~Window.State<N>, ~(Rolling.State<N> & Rolling.State<N>), _, a => b => (Rolling.Sum{a, total}, Rolling.Sum{b, total})) : Rolling.State<N> & Rolling.State<N>}
      {==}

law sma_clone:
  for ~N: Data
  for state: Sma.State<N>
  {(state, state) == Clone.sma(~N, state) : Sma.State<N> & Sma.State<N>}

def sma_clone(N, state):
  match state:
    case Sma.Sma{period, ring}:
      %rolling_clone(~N, ring) : {(Sma.Sma{period, ring}, Sma.Sma{period, ring}) == Clone.pair(~Rolling.State<N>, ~(Sma.State<N> & Sma.State<N>), _, a => b => (Sma.Sma{period, a}, Sma.Sma{period, b})) : Sma.State<N> & Sma.State<N>}
      {==}

law moments_clone:
  for ~N: Data
  for state: Moments.Cached<N>
  {(state, state) == Clone.moments(~N, state) : Moments.Cached<N> & Moments.Cached<N>}

def moments_clone(N, state):
  match state:
    case Moments.Cached{window, cache}:
      %window_clone(~N, window) : {(Moments.Cached{window, cache}, Moments.Cached{window, cache}) == Clone.pair(~Window.State<N>, ~(Moments.Cached<N> & Moments.Cached<N>), _, a => b => (Moments.Cached{a, cache}, Moments.Cached{b, cache})) : Moments.Cached<N> & Moments.Cached<N>}
      {==}

law pair_clone:
  for ~N: Data
  for state: StatisticsWindow.PairCached<N>
  {(state, state) == Clone.statistics_window.pair(~N, state) : StatisticsWindow.PairCached<N> & StatisticsWindow.PairCached<N>}

def pair_clone(N, state):
  match state:
    case StatisticsWindow.PairCached{window, cache}:
      %window_clone(~StatisticsWindow.PairValue<N>, window) : {(StatisticsWindow.PairCached{window, cache}, StatisticsWindow.PairCached{window, cache}) == Clone.pair(~Window.State<StatisticsWindow.PairValue<N>>, ~(StatisticsWindow.PairCached<N> & StatisticsWindow.PairCached<N>), _, a => b => (StatisticsWindow.PairCached{a, cache}, StatisticsWindow.PairCached{b, cache})) : StatisticsWindow.PairCached<N> & StatisticsWindow.PairCached<N>}
      {==}

law beta_clone:
  for ~N: Data
  for state: StatisticsWindow.Beta<N>
  {(state, state) == Clone.statistics_window.beta(~N, state) : StatisticsWindow.Beta<N> & StatisticsWindow.Beta<N>}

def beta_clone(N, state):
  match state:
    case StatisticsWindow.Beta{previous, window}:
      %pair_clone(~N, window) : {(StatisticsWindow.Beta{previous, window}, StatisticsWindow.Beta{previous, window}) == Clone.pair(~StatisticsWindow.PairCached<N>, ~(StatisticsWindow.Beta<N> & StatisticsWindow.Beta<N>), _, a => b => (StatisticsWindow.Beta{previous, a}, StatisticsWindow.Beta{previous, b})) : StatisticsWindow.Beta<N> & StatisticsWindow.Beta<N>}
      {==}

law preview_copy:
  for ~I: Data
  for ~O: Data
  for ~S: Type
  for ~copy: S -> S & S
  for ~step: S -> I -> S & Maybe<&2, O>
  for ~copy_ok: @s: S -> {(s, s) == copy(s) : S & S}
  for state: S
  for value: I
  for next: S
  for output: Maybe<&2, O>
  for transition: {(next, output) == step(state, value) : S & Maybe<&2, O>}
  {Clone.preview(~I, ~O, ~S, ~copy, ~step, state, value) == (state, output) : S & Maybe<&2, O>}

def preview_copy(I, O, S, copy, step, copy_ok, state, value, next, output, transition):
  %copy_ok(state) : {Clone.preview.read(~I, ~O, ~S, ~step, value, _) == (state, output) : S & Maybe<&2, O>}
  %transition : {Clone.preview.output(~O, ~S, state, _) == (state, output) : S & Maybe<&2, O>}
  {==}
