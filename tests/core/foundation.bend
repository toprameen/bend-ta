import Base
import ../../src/f32.bend as TA
import ../../src/core/config.bend as Config
import ../../src/core/window.bend as Window
import ../../src/core/series.bend as Series
import ../../src/core/extrema.bend as Extrema
import ../../src/core/moments.bend as Moments

def config.case(result: Result<&2, &2, Config.Error, Config.Config>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{Config.Config{period, depth}}:
      U32.show(period) ++ ":" ++ Nat.show(depth)

def show(~O: Data, ~value: O -> String, xs: List<&2, Maybe<&2, O>>) -> String:
  List.show(~&2, ~Maybe<&2, O>, ~(v => Maybe.show(~&2, ~O, ~value, v)), xs)

def range(value: TA.Extrema.Value()) -> String:
  match value:
    case Extrema.Range{low, high}:
      F32.show(low) ++ ":" ++ F32.show(high)

def moments(value: TA.Moments.Value()) -> String:
  match value:
    case Moments.Moments{mean, variance}:
      F32.show(mean) ++ ":" ++ F32.show(variance)

def fold(u: Unit, acc: String, value: F32) -> String:
  acc ++ F32.show(value) ++ ","

def window.folded(result: TA.Window.State() & String, text: String) -> String:
  match result:
    case (window, folded):
      text ++ " | [" ++ folded ++ "]"

def window.lagged(result: TA.Window.State() & Maybe<&2, F32>, rest: TA.Window.State() -> String -> String) -> String:
  match result:
    case (window, value):
      rest(window, Maybe.show(~&2, ~F32, ~F32.show, value))

def window.length(result: TA.Window.State() & U32, text: String) -> String:
  match result:
    case (window, size):
      window.folded(Window.fold(~F32, ~Unit, ~String, ~fold, window, Unit{}, ""), text ++ " | " ++ U32.show(size))

def window.scanned(result: TA.Window.State() & List<&2, Maybe<&2, F32>>) -> String:
  match result:
    case (window, removed):
      +prefix = show(~F32, ~F32.show, removed)
      window.lagged(TA.Window.lag(window, 0), w => a =>
        window.lagged(TA.Window.lag(w, 2), w => b =>
          window.lagged(TA.Window.lag(w, 4294967295), w => c =>
            window.length(TA.Window.length(w), prefix ++ " | " ++ a ++ "," ++ b ++ "," ++ c))))

def window.case(xs: List<&2, F32>, initialized: Result<&2, &1, TA.Error(), TA.Window.State()>) -> String:
  match initialized:
    case Fail{e}:
      "invalid"
    case Done{window}:
      window.scanned(Series.scan(~F32, ~F32, ~TA.Window.State(), ~TA.Window.push, xs, window))

def stats.case(xs: List<&2, F32>, initialized: Result<&2, &1, TA.Error(), TA.Window.State()>) -> String:
  match initialized:
    case Fail{e}:
      "invalid"
    case Done{window}:
      show(~TA.Moments.Value(), ~moments, Series.batch(~F32, ~TA.Moments.Value(), ~TA.Window.State(), ~TA.Moments.next, xs, window))

def extrema.case(xs: List<&2, F32>, initialized: Result<&2, &1, TA.Error(), TA.Window.State()>) -> String:
  match initialized:
    case Fail{e}:
      "invalid"
    case Done{window}:
      show(~TA.Extrema.Value(), ~range, Series.batch(~F32, ~TA.Extrema.Value(), ~TA.Window.State(), ~TA.Extrema.next, xs, window))

def shared.stats(result: TA.Window.State() & Maybe<&2, TA.Moments.Value()>) -> String:
  match result:
    case (window, value):
      Maybe.show(~&2, ~TA.Moments.Value(), ~moments, value)

def shared.extrema(result: TA.Window.State() & Maybe<&2, TA.Extrema.Value()>) -> String:
  match result:
    case (window, value):
      Maybe.show(~&2, ~TA.Extrema.Value(), ~range, value) ++ " | " ++ shared.stats(TA.Moments.read(window))

def shared.scanned(result: TA.Window.State() & List<&2, Maybe<&2, F32>>) -> String:
  match result:
    case (window, values):
      shared.extrema(TA.Extrema.read(window))

def shared(initialized: Result<&2, &1, TA.Error(), TA.Window.State()>) -> String:
  match initialized:
    case Fail{e}:
      "invalid"
    case Done{window}:
      shared.scanned(Series.scan(~F32, ~F32, ~TA.Window.State(), ~TA.Window.push, [0.0, 4.0], window))

def sum.case(result: Result<&2, &1, TA.Error(), TA.SUM.State()>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{state}:
      show(~F32, ~F32.show, Series.batch(~F32, ~F32, ~TA.SUM.State(), ~TA.SUM.next, [1.0, 2.0, 3.0, 4.0, 5.0], state))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(config.case(Config.make(0)))
    IO.print(config.case(Config.make(1)))
    IO.print(config.case(Config.make(3)))
    IO.print(config.case(Config.make(4)))
    IO.print(config.case(Config.make(5)))
    IO.print(config.case(Config.make(1073741824)))
    IO.print(config.case(Config.make(1073741825)))
    IO.print(window.case([], TA.Window.init(3)))
    IO.print(window.case([1.0, 2.0, 3.0, 4.0, 5.0], TA.Window.init(3)))
    IO.print(window.case([7.0, 8.0], TA.Window.init(1)))
    IO.print(window.case([], TA.Window.init(0)))
    IO.print(stats.case([3.0, 6.0, 9.0, 12.0], TA.Window.init(3)))
    IO.print(stats.case([1000000.0, 1000000.0625], TA.Window.init(2)))
    IO.print(stats.case([16.0, 4.0, 4.0, 4.0], TA.Window.init(2)))
    IO.print(stats.case([7.0, 8.0], TA.Window.init(1)))
    IO.print(extrema.case([1.0, 4.0, 4.0, 2.0, 3.0, 0.0], TA.Window.init(3)))
    IO.print(shared(TA.Window.init(2)))
    IO.print(sum.case(TA.SUM.init(3)))
    IO.print(F32.show(TA.Moments.stddev(Moments.Moments{2.0, 4.0})))

#|invalid
#|1:0
#|3:2
#|4:2
#|5:3
#|1073741824:30
#|invalid
#|[] | None,None,None | 0 | []
#|[None, None, None, Some(1), Some(2)] | Some(5),Some(3),None | 3 | [3,4,5,]
#|[None, Some(7)] | Some(8),None,None | 1 | [8,]
#|invalid
#|[None, None, Some(6:6), Some(9:6)]
#|[None, Some(1000000:0.0009765625)]
#|[None, Some(10:36), Some(4:0), Some(4:0)]
#|[Some(7:0), Some(8:0)]
#|[None, None, Some(1:4), Some(2:4), Some(2:4), Some(0:3)]
#|Some(0:4) | Some(2:4)
#|[None, None, Some(6), Some(9), Some(12)]
#|2
