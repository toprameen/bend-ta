import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as B
import ./candles.bend as Candles
import ../../src/core/candle.bend as Candle
import ../../src/core/series.bend as Series

def plain() -> List<&2, B.OHLC<F32>>:
  [B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{4.0, 7.0, 1.0, 4.0}, B.OHLC{5.0, 9.0, 1.0, 5.0}, B.OHLC{8.0, 9.0, 1.0, 8.0}, B.OHLC{9.0, 9.0, 1.0, 9.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{6.0, 9.0, 3.0, 6.0}, B.OHLC{2.0, 9.0, 1.0, 2.0}, B.OHLC{1.0, 9.0, 1.0, 1.0}]

def modified() -> List<&2, B.OHLC<F32>>:
  [B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{4.0, 16.0, 4.0, 4.0}, B.OHLC{10.0, 14.0, 6.0, 10.0}, B.OHLC{10.0, 12.0, 5.0, 10.0}, B.OHLC{12.0, 17.0, 5.0, 12.0}, B.OHLC{14.0, 17.0, 5.0, 14.0}, B.OHLC{15.0, 17.0, 5.0, 15.0}, B.OHLC{10.0, 20.0, 0.0, 10.0}, B.OHLC{16.0, 16.0, 4.0, 16.0}, B.OHLC{10.0, 14.0, 6.0, 10.0}, B.OHLC{10.0, 15.0, 7.0, 10.0}, B.OHLC{6.0, 15.0, 5.0, 6.0}, B.OHLC{5.0, 15.0, 5.0, 5.0}]

def expired() -> List<&2, B.OHLC<F32>>:
  [B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{4.0, 7.0, 1.0, 4.0}, B.OHLC{5.0, 9.0, 1.0, 5.0}, B.OHLC{8.0, 9.0, 1.0, 8.0}, B.OHLC{8.0, 9.0, 1.0, 8.0}, B.OHLC{9.0, 9.0, 1.0, 9.0}]

def continued.scan(r: TA.CDLHIKKAKE.State() & List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> List<&2, Maybe<&2, TA.Pattern.Signal()>>:
  match r:
    case (state, first): List.append(&2, Maybe<&2, TA.Pattern.Signal()>, first, Series.batch(~B.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.CDLHIKKAKE.State(), ~TA.CDLHIKKAKE.next, List.drop(&2, B.OHLC<F32>, plain(), 3n), state))

def continued(r: Result<&2, &1, TA.Pattern.Error(), TA.CDLHIKKAKE.State()>) -> Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>:
  match r:
    case Fail{error}: Fail{error}
    case Done{state}: Done{continued.scan(Series.scan(~B.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.CDLHIKKAKE.State(), ~TA.CDLHIKKAKE.next, [B.OHLC{5.0, 10.0, 0.0, 5.0}, B.OHLC{5.0, 8.0, 2.0, 5.0}, B.OHLC{4.0, 7.0, 1.0, 4.0}], state))}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("hikkake confirmation", Candles.verify("nnnnnPzzmzM", TA.CDLHIKKAKE.batch(plain())))
    Unit <- Assert.check("modified hikkake confirmation", Candles.verify("nnnnnnnnnnPzzzmzM", TA.CDLHIKKAKEMOD.batch(modified())))
    Unit <- Assert.check("expired confirmation", Candles.verify("nnnnnzpzzzz", TA.CDLHIKKAKE.batch(expired())))
    Unit <- Assert.check("hikkake streaming", Candles.verify("nnnnnPzzmzM", continued(TA.CDLHIKKAKE.init())))
    Assert.check("custom modified hikkake setting", Candles.verify("nnnnnnzpzzPzzzmzM", Series.initialized(~B.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.CDLHIKKAKEMOD.State(), ~TA.Pattern.Error(), ~TA.CDLHIKKAKEMOD.next, modified(), TA.CDLHIKKAKEMOD.init.setting(Candle.Setting{Candle.HighLow{}, 0, 0.0}))))
