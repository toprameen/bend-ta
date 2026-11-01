import Base
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as B
import ../../src/core/patterns.bend as Pattern
import ../../src/core/candle.bend as Candle
import ../../src/core/series.bend as Series

def plain() -> List<&2, B.OHLC<F32>>:
  [B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{4.0, 7.0, 1.0, 4.0}, B.OHLC{5.0, 9.0, 1.0, 5.0}, B.OHLC{8.0, 9.0, 1.0, 8.0}, B.OHLC{9.0, 9.0, 1.0, 9.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{6.0, 9.0, 3.0, 6.0}, B.OHLC{2.0, 9.0, 1.0, 2.0}, B.OHLC{1.0, 9.0, 1.0, 1.0}]

def modified() -> List<&2, B.OHLC<F32>>:
  [B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{4.0, 16.0, 4.0, 4.0}, B.OHLC{10.0, 14.0, 6.0, 10.0}, B.OHLC{10.0, 12.0, 5.0, 10.0}, B.OHLC{12.0, 17.0, 5.0, 12.0}, B.OHLC{14.0, 17.0, 5.0, 14.0}, B.OHLC{15.0, 17.0, 5.0, 15.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{16.0, 16.0, 4.0, 16.0}, B.OHLC{10.0, 14.0, 6.0, 10.0}, B.OHLC{10.0, 15.0, 7.0, 10.0}, B.OHLC{6.0, 15.0, 5.0, 6.0}, B.OHLC{5.0, 15.0, 5.0, 5.0}]

def expired() -> List<&2, B.OHLC<F32>>:
  [B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{4.0, 7.0, 1.0, 4.0}, B.OHLC{5.0, 9.0, 1.0, 5.0}, B.OHLC{8.0, 9.0, 1.0, 8.0}, B.OHLC{8.0, 9.0, 1.0, 8.0}, B.OHLC{9.0, 9.0, 1.0, 9.0}]

def value(x: Maybe<&2, TA.Pattern.Signal()>) -> String:
  match x:
    case None{}: "n"
    case Some{Pattern.Signal{negative, strength}}:
      match strength:
        case 100: Bool.pick(String, negative, "m", "p")
        case 200: Bool.pick(String, negative, "M", "P")
        case _: "z"

def show(xs: List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> String:
  match xs:
    case Nil{}: ""
    case x <> rest: value(x) ++ show(rest)

def result(r: Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>) -> String:
  match r:
    case Fail{e}: "invalid"
    case Done{xs}: show(xs)

def after(fuel: Nat, xs: List<&2, B.OHLC<F32>>) -> List<&2, B.OHLC<F32>>:
  match fuel xs:
    case 0n xs: xs
    case 1n+n Nil{}: []
    case 1n+n x <> rest: after(n, rest)

def continued.scan(r: TA.CDLHIKKAKE.State() & List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> String:
  match r:
    case (state, first): show(first) ++ show(Series.batch(~B.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.CDLHIKKAKE.State(), ~TA.CDLHIKKAKE.next, after(3n, plain()), state))

def continued(r: Result<&2, &1, TA.Pattern.Error(), TA.CDLHIKKAKE.State()>) -> String:
  match r:
    case Fail{e}: "invalid"
    case Done{state}: continued.scan(Series.scan(~B.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.CDLHIKKAKE.State(), ~TA.CDLHIKKAKE.next, [B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{4.0, 7.0, 1.0, 4.0}], state))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(result(TA.CDLHIKKAKE.batch(plain())))
    IO.print(result(TA.CDLHIKKAKEMOD.batch(modified())))
    IO.print(result(TA.CDLHIKKAKE.batch(expired())))
    IO.print(continued(TA.CDLHIKKAKE.init()))
    IO.print(result(Series.initialized(~B.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.CDLHIKKAKEMOD.State(), ~TA.Pattern.Error(), ~TA.CDLHIKKAKEMOD.next, modified(), TA.CDLHIKKAKEMOD.init.setting(Candle.Setting{Candle.HighLow{}, 0, 0.0}))))

#|nnnnnPzzmzM
#|nnnnnnnnnnPzzzmzM
#|nnnnnzpzzzz
#|nnnnnPzzmzM
#|nnnnnnzpzzPzzzmzM
