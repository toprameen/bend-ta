import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/config.bend as Config
import ../../src/core/window.bend as Window
import ../../src/core/series.bend as Series
import ../../src/core/extrema.bend as Extrema
import ../../src/core/moments.bend as Moments

def config(result: Result<&2, &2, Config.Error, Config.Config>, period: U32, depth: Nat) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{Config.Config{actual, actual_depth}}:
      Bool.and(U32.is_eq(actual, period), Nat.is_eq(actual_depth, depth))

def same_range(actual: TA.Extrema.Value(), expected: TA.Extrema.Value()) -> Bool:
  match actual expected:
    case Extrema.Range{low, high} Extrema.Range{want_low, want_high}:
      Bool.and(F32.is_eq(low, want_low), F32.is_eq(high, want_high))

def same_moments(actual: TA.Moments.Value(), expected: TA.Moments.Value()) -> Bool:
  match actual expected:
    case Moments.Moments{mean, variance} Moments.Moments{want_mean, want_variance}:
      Bool.and(F32.is_eq(mean, want_mean), F32.is_eq(variance, want_variance))

def prepend(u: Unit, acc: List<&2, F32>, value: F32) -> List<&2, F32>:
  value <> acc

def with_lag(result: TA.Window.State() & Maybe<&2, F32>, rest: TA.Window.State() -> Maybe<&2, F32> -> Bool) -> Bool:
  match result:
    case (window, value): rest(window, value)

def with_length(result: TA.Window.State() & U32, rest: TA.Window.State() -> U32 -> Bool) -> Bool:
  match result:
    case (window, size): rest(window, size)

def folded(result: TA.Window.State() & List<&2, F32>, expected: List<&2, F32>) -> Bool:
  match result:
    case (window, reversed): Assert.list(~F32, ~F32.is_eq, List.reverse(&2, F32, reversed), expected)

def window_contents(state: TA.Window.State(), lags: List<&2, Maybe<&2, F32>>, length: U32, values: List<&2, F32>) -> Bool:
  with_lag(TA.Window.lag(state, 0), w => newest =>
    with_lag(TA.Window.lag(w, 2), w => older =>
      with_lag(TA.Window.lag(w, 4294967295), w => too_far =>
        with_length(TA.Window.length(w), w => size =>
          Bool.and(
            Bool.and(Assert.series(~F32, ~F32.is_eq, [newest, older, too_far], lags), U32.is_eq(size, length)),
            folded(Window.fold(~F32, ~Unit, ~List<&2, F32>, ~prepend, w, Unit{}, []), values))))))

def window_scanned(result: TA.Window.State() & List<&2, Maybe<&2, F32>>, evictions: List<&2, Maybe<&2, F32>>, lags: List<&2, Maybe<&2, F32>>, length: U32, values: List<&2, F32>) -> Bool:
  match result:
    case (state, removed):
      Bool.and(Assert.series(~F32, ~F32.is_eq, removed, evictions), window_contents(state, lags, length, values))

def window_case(prices: List<&2, F32>, initialized: Result<&2, &1, TA.Error(), TA.Window.State()>, evictions: List<&2, Maybe<&2, F32>>, lags: List<&2, Maybe<&2, F32>>, length: U32, values: List<&2, F32>) -> Bool:
  match initialized:
    case Fail{error}: False{}
    case Done{window}:
      window_scanned(Series.scan(~F32, ~F32, ~TA.Window.State(), ~TA.Window.push, prices, window), evictions, lags, length, values)

def stats(prices: List<&2, F32>, initialized: Result<&2, &1, TA.Error(), TA.Window.State()>, expected: List<&2, Maybe<&2, TA.Moments.Value()>>) -> Bool:
  match initialized:
    case Fail{error}: False{}
    case Done{window}:
      Assert.series(~TA.Moments.Value(), ~same_moments,
        Series.batch(~F32, ~TA.Moments.Value(), ~TA.Window.State(), ~TA.Moments.next, prices, window), expected)

def extrema(initialized: Result<&2, &1, TA.Error(), TA.Window.State()>) -> Bool:
  match initialized:
    case Fail{error}: False{}
    case Done{window}:
      Assert.series(~TA.Extrema.Value(), ~same_range,
        Series.batch(~F32, ~TA.Extrema.Value(), ~TA.Window.State(), ~TA.Extrema.next, [1.0, 4.0, 4.0, 2.0, 3.0, 0.0], window),
        [None{}, None{}, Some{Extrema.Range{1.0, 4.0}}, Some{Extrema.Range{2.0, 4.0}}, Some{Extrema.Range{2.0, 4.0}}, Some{Extrema.Range{0.0, 3.0}}])

def shared_moments(bounds: Maybe<&2, TA.Extrema.Value()>, result: TA.Window.State() & Maybe<&2, TA.Moments.Value()>) -> Bool:
  match result:
    case (window, moments):
      Bool.and(Assert.maybe(~TA.Extrema.Value(), ~same_range, bounds, Some{Extrema.Range{0.0, 4.0}}),
        Assert.maybe(~TA.Moments.Value(), ~same_moments, moments, Some{Moments.Moments{2.0, 4.0}}))

def shared_extrema(result: TA.Window.State() & Maybe<&2, TA.Extrema.Value()>) -> Bool:
  match result:
    case (window, bounds): shared_moments(bounds, TA.Moments.read(window))

def shared_scanned(result: TA.Window.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case (window, removed): shared_extrema(TA.Extrema.read(window))

def shared(initialized: Result<&2, &1, TA.Error(), TA.Window.State()>) -> Bool:
  match initialized:
    case Fail{error}: False{}
    case Done{window}:
      shared_scanned(Series.scan(~F32, ~F32, ~TA.Window.State(), ~TA.Window.push, [0.0, 4.0], window))

def sum(initialized: Result<&2, &1, TA.Error(), TA.SUM.State()>) -> Bool:
  match initialized:
    case Fail{error}: False{}
    case Done{state}:
      Assert.series(~F32, ~F32.is_eq,
        Series.batch(~F32, ~F32, ~TA.SUM.State(), ~TA.SUM.next, [1.0, 2.0, 3.0, 4.0, 5.0], state),
        [None{}, None{}, Some{6.0}, Some{9.0}, Some{12.0}])

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("zero period", Result.is_fail(&2, &2, Config.Error, Config.Config, Config.make(0)))
    Unit <- Assert.check("period one depth", config(Config.make(1), 1, 0n))
    Unit <- Assert.check("period three depth", config(Config.make(3), 3, 2n))
    Unit <- Assert.check("period four depth", config(Config.make(4), 4, 2n))
    Unit <- Assert.check("period five depth", config(Config.make(5), 5, 3n))
    Unit <- Assert.check("maximum period depth", config(Config.make(1073741824), 1073741824, 30n))
    Unit <- Assert.check("oversized period", Result.is_fail(&2, &2, Config.Error, Config.Config, Config.make(1073741825)))
    Unit <- Assert.check("empty window", window_case([], TA.Window.init(3), [], [None{}, None{}, None{}], 0, []))
    Unit <- Assert.check("wrapped window", window_case([1.0, 2.0, 3.0, 4.0, 5.0], TA.Window.init(3),
      [None{}, None{}, None{}, Some{1.0}, Some{2.0}], [Some{5.0}, Some{3.0}, None{}], 3, [3.0, 4.0, 5.0]))
    Unit <- Assert.check("single-slot window", window_case([7.0, 8.0], TA.Window.init(1),
      [None{}, Some{7.0}], [Some{8.0}, None{}, None{}], 1, [8.0]))
    Unit <- Assert.check("invalid window", Result.is_fail(&2, &1, TA.Error(), TA.Window.State(), TA.Window.init(0)))
    Unit <- Assert.check("rolling moments", stats([3.0, 6.0, 9.0, 12.0], TA.Window.init(3),
      [None{}, None{}, Some{Moments.Moments{6.0, 6.0}}, Some{Moments.Moments{9.0, 6.0}}]))
    Unit <- Assert.check("centered variance", stats([1000000.0, 1000000.0625], TA.Window.init(2), [None{}, Some{Moments.Moments{1000000.0, 0.0009765625}}]))
    Unit <- Assert.check("variance after eviction", stats([16.0, 4.0, 4.0, 4.0], TA.Window.init(2),
      [None{}, Some{Moments.Moments{10.0, 36.0}}, Some{Moments.Moments{4.0, 0.0}}, Some{Moments.Moments{4.0, 0.0}}]))
    Unit <- Assert.check("single-slot moments", stats([7.0, 8.0], TA.Window.init(1), [Some{Moments.Moments{7.0, 0.0}}, Some{Moments.Moments{8.0, 0.0}}]))
    Unit <- Assert.check("rolling extrema", extrema(TA.Window.init(3)))
    Unit <- Assert.check("shared window reads", shared(TA.Window.init(2)))
    Unit <- Assert.check("streaming sum", sum(TA.SUM.init(3)))
    Assert.check("standard deviation", F32.is_eq(TA.Moments.stddev(Moments.Moments{2.0, 4.0}), 2.0))
