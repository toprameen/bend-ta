import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/candle.bend as Candle
import ../../src/core/series.bend as Series

def seed.values(xs: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs:
    case None{} <> None{} <> None{} <> Some{+x} <> Nil{}:
      Bool.and(TA.is_finite(x), F32.is_eq(x, 1.0e38))
    case other:
      False{}

def seed(result: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: seed.values(xs)

def final(xs: List<&2, Maybe<&2, F32>>, +expected: F32) -> Bool:
  match xs:
    case Some{value} <> Nil{}: F32.is_eq(value, expected)
    case head <> rest: final(rest, expected)
    case Nil{}: False{}

def restored(result: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>, expected: F32) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: final(xs, expected)

def rebuild.chunk(result: TA.SUM.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case (state, first): final(Series.batch(~F32, ~F32, ~TA.SUM.State(), ~TA.SUM.next, [1.0], state), 2.0)

def rebuild.stream(result: Result<&2, &1, TA.Error(), TA.SUM.State()>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{state}: rebuild.chunk(Series.scan(~F32, ~F32, ~TA.SUM.State(), ~TA.SUM.next, [16777216.0, 1.0, 1.0], state))

def cycle(n: Nat) -> List<&2, F32>:
  match n:
    case 0n: Nil{}
    case 1n+rest: 1000000.0 <> 1000000.625 <> 1000000.3125 <> 1000000.125 <> cycle(rest)

def candles(xs: List<&2, Bar.OHLC<F32>>, result: Result<&2, &1, TA.Candle.Error(), TA.Candle.State()>) -> Result<&2, &2, Candle.Error, List<&2, Maybe<&2, F32>>>:
  match result:
    case Fail{error}: Fail{error}
    case Done{state}:
      Done{Series.batch(~Bar.OHLC<F32>, ~F32, ~TA.Candle.State(), ~TA.Candle.next, xs, state)}

def candle_error(~A: Type, result: Result<&2, &1, Candle.Error, A>, expected: Candle.Error) -> Bool:
  match result expected:
    case Fail{Candle.InvalidPeriod{}} Candle.InvalidPeriod{}: True{}
    case Fail{Candle.InvalidFactor{}} Candle.InvalidFactor{}: True{}
    case _ _: False{}

def spread(value: F32) -> Bar.OHLC<F32>:
  Bar.OHLC{1.0, F32.add(1.0, value), 1.0, 1.0}

def up(value: Bar.Direction) -> Bool:
  match value:
    case Bar.Up{}: True{}
    case Bar.Down{}: False{}

def same_kind(actual: Candle.RangeKind, expected: Candle.RangeKind) -> Bool:
  match actual expected:
    case Candle.RealBody{} Candle.RealBody{}: True{}
    case Candle.HighLow{} Candle.HighLow{}: True{}
    case Candle.Shadows{} Candle.Shadows{}: True{}
    case _ _: False{}

def setting(actual: Candle.Setting<F32>, expected: Candle.Setting<F32>) -> Bool:
  match actual expected:
    case Candle.Setting{k, period, factor} Candle.Setting{want, length, scale}:
      Bool.and(same_kind(k, want), Bool.and(U32.is_eq(period, length), F32.is_eq(factor, scale)))

def main() -> IO(Unit):
  +sample : Bar.OHLC<F32> = Bar.OHLC{1.0, 5.0, 0.0, 3.0}
  do IO<Unit>:
    Unit <- Assert.check("RMA ramp", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.RMA.batch([3.0, 6.0, 9.0, 12.0, 14.0], 3), [None{}, None{}, Some{6.0}, Some{8.0}, Some{10.0}]))
    Unit <- Assert.check("RMA period one", Assert.batch(~TA.Error(), ~F32, ~F32.is_eq, TA.RMA.batch([1000000.0, 0.01], 1), [Some{1000000.0}, Some{0.01}]))
    Unit <- Assert.check("RMA invalid period", Result.is_fail(&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>, TA.RMA.batch([], 0)))
    Unit <- Assert.check("EMA seed stays finite", seed(TA.EMA.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38], 4)))
    Unit <- Assert.check("RMA seed stays finite", seed(TA.RMA.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38], 4)))
    Unit <- Assert.check("candle range window", Assert.batch(~Candle.Error, ~F32, ~F32.is_eq,
      candles([spread(2.0), spread(4.0), spread(100.0), spread(8.0)], TA.Candle.init(Candle.Setting{Candle.HighLow{}, 2, 2.0})),
      [None{}, None{}, Some{6.0}, Some{104.0}]))
    Unit <- Assert.check("current candle body", Assert.batch(~Candle.Error, ~F32, ~F32.is_eq,
      candles([sample], TA.Candle.init(Candle.Setting{Candle.RealBody{}, 0, 1.0})), [Some{2.0}]))
    Unit <- Assert.check("current candle shadows", Assert.batch(~Candle.Error, ~F32, ~F32.is_eq,
      candles([sample], TA.Candle.init(Candle.Setting{Candle.Shadows{}, 0, 2.0})), [Some{3.0}]))
    Unit <- Assert.check("oversized candle period", candle_error(~TA.Candle.State(), TA.Candle.init(Candle.Setting{Candle.RealBody{}, 1073741825, 1.0}), Candle.InvalidPeriod{}))
    Unit <- Assert.check("negative candle factor", candle_error(~TA.Candle.State(), TA.Candle.init(Candle.Setting{Candle.RealBody{}, 0, F32.neg(1.0)}), Candle.InvalidFactor{}))
    Unit <- Assert.check("NaN candle factor", candle_error(~TA.Candle.State(), TA.Candle.init(Candle.Setting{Candle.RealBody{}, 0, F32.div(0.0, 0.0)}), Candle.InvalidFactor{}))
    Unit <- Assert.check("candle defaults", List.all(~&2, ~Bool, ~(passed => passed), [
      setting(TA.Candle.defaults(Candle.BodyLong{}), Candle.Setting{Candle.RealBody{}, 10, 1.0}),
      setting(TA.Candle.defaults(Candle.BodyVeryLong{}), Candle.Setting{Candle.RealBody{}, 10, 3.0}),
      setting(TA.Candle.defaults(Candle.BodyShort{}), Candle.Setting{Candle.RealBody{}, 10, 1.0}),
      setting(TA.Candle.defaults(Candle.BodyDoji{}), Candle.Setting{Candle.HighLow{}, 10, 0.1}),
      setting(TA.Candle.defaults(Candle.ShadowLong{}), Candle.Setting{Candle.RealBody{}, 0, 1.0}),
      setting(TA.Candle.defaults(Candle.ShadowVeryLong{}), Candle.Setting{Candle.RealBody{}, 0, 2.0}),
      setting(TA.Candle.defaults(Candle.ShadowShort{}), Candle.Setting{Candle.Shadows{}, 10, 1.0}),
      setting(TA.Candle.defaults(Candle.ShadowVeryShort{}), Candle.Setting{Candle.HighLow{}, 10, 0.1}),
      setting(TA.Candle.defaults(Candle.Near{}), Candle.Setting{Candle.HighLow{}, 5, 0.2}),
      setting(TA.Candle.defaults(Candle.Far{}), Candle.Setting{Candle.HighLow{}, 5, 0.6}),
      setting(TA.Candle.defaults(Candle.Equal{}), Candle.Setting{Candle.HighLow{}, 5, 0.05})
    ]))
    Unit <- Assert.check("body and shadows", Assert.list(~F32, ~F32.is_eq,
      [Bar.body(~F32, ~F32.sub, ~F32.abs, sample), Bar.upper_shadow(~F32, ~F32.sub, ~F32.max, sample), Bar.lower_shadow(~F32, ~F32.sub, ~F32.min, sample)],
      [2.0, 2.0, 1.0]))
    Unit <- Assert.check("bar direction", List.all(~&2, ~Bool, ~(passed => passed), [
      up(Bar.color(~F32, ~F32.is_ge, sample)),
      up(Bar.color(~F32, ~F32.is_ge, Bar.OHLC{2.0, 2.0, 2.0, 2.0})),
      Bool.not(up(Bar.color(~F32, ~F32.is_ge, Bar.OHLC{3.0, 5.0, 0.0, 1.0})))
    ]))
    Unit <- Assert.check("Bar.body_gap_up case 1", Bar.body_gap_up(~F32, ~F32.min, ~F32.max, ~F32.is_gt, Bar.OHLC{5.0, 7.0, 5.0, 6.0}, sample))
    Unit <- Assert.check("Bar.gap_up", Bool.not(Bar.gap_up(~F32, ~F32.is_gt, Bar.OHLC{5.0, 7.0, 5.0, 6.0}, sample)))
    Unit <- Assert.check("Bar.body_gap_up case 2", Bool.not(Bar.body_gap_up(~F32, ~F32.min, ~F32.max, ~F32.is_gt, Bar.OHLC{3.0, 7.0, 3.0, 6.0}, sample)))
    Unit <- Assert.check("range and true range", Assert.list(~F32, ~F32.is_eq,
      [Bar.range(~F32, ~F32.sub, Bar.HL{7.0, 4.0}), TA.true_range(10.0, Bar.HLC{7.0, 4.0, 5.0})], [3.0, 6.0]))
    Unit <- Assert.check("valid and invalid observations", List.all(~&2, ~Bool, ~(passed => passed), [
      TA.Bar.valid(sample), Bool.not(TA.Bar.valid(Bar.OHLC{1.0, 0.0, 2.0, 3.0})), Bool.not(TA.is_finite(F32.div(1.0, 0.0)))
    ]))
    Unit <- Assert.check("SUM.batch case 1", Bool.and(restored(TA.SUM.batch([16777216.0, 1.0, 1.0, 1.0], 2), 2.0), restored(TA.SMA.batch([16777216.0, 1.0, 1.0, 1.0], 2), 1.0)))
    Unit <- Assert.check("SUM.batch case 2", restored(TA.SUM.batch([3.0e38, 3.0e38, 1.0, 1.0], 2), 2.0))
    Unit <- Assert.check("SUM.init", rebuild.stream(TA.SUM.init(2)))
    Assert.check("SUM.batch case 3", restored(TA.SUM.batch(cycle(5n), 3), 3000001.0))
