import Base
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/candle.bend as Candle
import ../../src/core/series.bend as Series

def show(xs: List<&2, Maybe<&2, F32>>) -> String:
  List.show(~&2, ~Maybe<&2, F32>, ~(v => Maybe.show(~&2, ~F32, ~F32.show, v)), xs)

def numeric(result: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{xs}: show(xs)

def seed.values(xs: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs:
    case None{} <> None{} <> None{} <> Some{+x} <> Nil{}:
      Bool.and(TA.is_finite(x), F32.is_eq(x, 1.0e38))
    case other:
      False{}

def seed(result: Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{xs}: Bool.show(seed.values(xs))

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

def candles(xs: List<&2, Bar.OHLC<F32>>, result: Result<&2, &1, TA.Candle.Error(), TA.Candle.State()>) -> String:
  match result:
    case Fail{Candle.InvalidPeriod{}}: "period"
    case Fail{Candle.InvalidFactor{}}: "factor"
    case Done{state}:
      show(Series.batch(~Bar.OHLC<F32>, ~F32, ~TA.Candle.State(), ~TA.Candle.next, xs, state))

def spread(value: F32) -> Bar.OHLC<F32>:
  Bar.OHLC{1.0, F32.add(1.0, value), 1.0, 1.0}

def direction(value: Bar.Direction) -> String:
  match value:
    case Bar.Up{}: "Up"
    case Bar.Down{}: "Down"

def kind(value: Candle.RangeKind) -> String:
  match value:
    case Candle.RealBody{}: "body"
    case Candle.HighLow{}: "range"
    case Candle.Shadows{}: "shadows"

def setting(value: Candle.Setting<F32>) -> String:
  match value:
    case Candle.Setting{k, period, factor}:
      kind(k) ++ ":" ++ U32.show(period) ++ ":" ++ F32.show(factor)

def defaults(names: List<&2, Candle.Name>) -> List<&2, String>:
  match names:
    case Nil{}: Nil{}
    case h <> t: setting(TA.Candle.defaults(h)) <> defaults(t)

def main() -> IO(Unit):
  +sample : Bar.OHLC<F32> = Bar.OHLC{1.0, 5.0, 0.0, 3.0}
  do IO<Unit>:
    IO.print(numeric(TA.RMA.batch([3.0, 6.0, 9.0, 12.0, 14.0], 3)))
    IO.print(numeric(TA.RMA.batch([1000000.0, 0.01], 1)))
    IO.print(numeric(TA.RMA.batch([], 0)))
    IO.print(seed(TA.EMA.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38], 4)))
    IO.print(seed(TA.RMA.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38], 4)))
    IO.print(candles([spread(2.0), spread(4.0), spread(100.0), spread(8.0)], TA.Candle.init(Candle.Setting{Candle.HighLow{}, 2, 2.0})))
    IO.print(candles([sample], TA.Candle.init(Candle.Setting{Candle.RealBody{}, 0, 1.0})))
    IO.print(candles([sample], TA.Candle.init(Candle.Setting{Candle.Shadows{}, 0, 2.0})))
    IO.print(candles([], TA.Candle.init(Candle.Setting{Candle.RealBody{}, 1073741825, 1.0})))
    IO.print(candles([], TA.Candle.init(Candle.Setting{Candle.RealBody{}, 0, F32.neg(1.0)})))
    IO.print(candles([], TA.Candle.init(Candle.Setting{Candle.RealBody{}, 0, F32.div(0.0, 0.0)})))
    IO.print(List.show(~&2, ~String, ~(s => s), defaults([Candle.BodyLong{}, Candle.BodyVeryLong{}, Candle.BodyShort{}, Candle.BodyDoji{}, Candle.ShadowLong{}, Candle.ShadowVeryLong{}, Candle.ShadowShort{}, Candle.ShadowVeryShort{}, Candle.Near{}, Candle.Far{}, Candle.Equal{}])))
    IO.print(F32.show(Bar.body(~F32, ~F32.sub, ~F32.abs, sample)) ++ ":" ++ F32.show(Bar.upper_shadow(~F32, ~F32.sub, ~F32.max, sample)) ++ ":" ++ F32.show(Bar.lower_shadow(~F32, ~F32.sub, ~F32.min, sample)))
    IO.print(direction(Bar.color(~F32, ~F32.is_ge, sample)) ++ ":" ++ direction(Bar.color(~F32, ~F32.is_ge, Bar.OHLC{2.0, 2.0, 2.0, 2.0})) ++ ":" ++ direction(Bar.color(~F32, ~F32.is_ge, Bar.OHLC{3.0, 5.0, 0.0, 1.0})))
    IO.print(Bool.show(Bar.body_gap_up(~F32, ~F32.min, ~F32.max, ~F32.is_gt, Bar.OHLC{5.0, 7.0, 5.0, 6.0}, sample)))
    IO.print(Bool.show(Bar.gap_up(~F32, ~F32.is_gt, Bar.OHLC{5.0, 7.0, 5.0, 6.0}, sample)))
    IO.print(Bool.show(Bar.body_gap_up(~F32, ~F32.min, ~F32.max, ~F32.is_gt, Bar.OHLC{3.0, 7.0, 3.0, 6.0}, sample)))
    IO.print(F32.show(Bar.range(~F32, ~F32.sub, Bar.HL{7.0, 4.0})) ++ ":" ++ F32.show(TA.true_range(10.0, Bar.HLC{7.0, 4.0, 5.0})))
    IO.print(Bool.show(TA.Bar.valid(sample)) ++ ":" ++ Bool.show(TA.Bar.valid(Bar.OHLC{1.0, 0.0, 2.0, 3.0})) ++ ":" ++ Bool.show(TA.is_finite(F32.div(1.0, 0.0))))
    IO.print(Bool.show(Bool.and(restored(TA.SUM.batch([16777216.0, 1.0, 1.0, 1.0], 2), 2.0), restored(TA.SMA.batch([16777216.0, 1.0, 1.0, 1.0], 2), 1.0))))
    IO.print(Bool.show(restored(TA.SUM.batch([3.0e38, 3.0e38, 1.0, 1.0], 2), 2.0)))
    IO.print(Bool.show(rebuild.stream(TA.SUM.init(2))))
    IO.print(Bool.show(restored(TA.SUM.batch(cycle(5n), 3), 3000001.0)))

#|[None, None, Some(6), Some(8), Some(10)]
#|[Some(1000000), Some(0.01)]
#|invalid
#|True
#|True
#|[None, None, Some(6), Some(104)]
#|[Some(2)]
#|[Some(3)]
#|period
#|factor
#|factor
#|[body:10:1, body:10:3, body:10:1, range:10:0.1, body:0:1, body:0:2, shadows:10:1, range:10:0.1, range:5:0.2, range:5:0.6, range:5:0.05]
#|2:2:1
#|Up:Up:Down
#|True
#|False
#|False
#|3:6
#|True:False:False
#|True
#|True
#|True
#|True
