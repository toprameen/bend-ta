import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA

def final_value(result: Result<&2, &2, TA.Parameter.Error(), List<&2, Maybe<&2, F32>>>, expected: F32) -> Bool:
  match result:
    case Done{[None{}, None{}, Some{value}]}: F32.is_eq(value, expected)
    case _: False{}

def correl() -> Bool:
  pairs : List<&2, TA.PairValue()> = [TA.pair(1.0, 5.0), TA.pair(2.0, 3.0), TA.pair(3.0, 1.0)]
  final_value(TA.CORREL.batch(pairs, 3), F32.neg(1.0))

def beta() -> Bool:
  pairs : List<&2, TA.PairValue()> = [TA.pair(1.0, 1.0), TA.pair(2.0, 3.0), TA.pair(8.0, 21.0)]
  final_value(TA.BETA.batch(pairs, 2), 2.0)

def operands() -> Bool:
  +values : TA.Transform.Operands() = TA.Transform.operands(12.0, 3.0)
  List.all(~&2, ~Bool, ~(value => value), [
    F32.is_eq(TA.ADD(values), 15.0),
    F32.is_eq(TA.SUB(values), 9.0),
    F32.is_eq(TA.MULT(values), 36.0),
    F32.is_eq(TA.DIV(values), 4.0)
  ])

def mavp() -> Bool:
  samples : List<&2, TA.MAVP.Sample()> = [TA.MAVP.sample(1.0, 2.0), TA.MAVP.sample(10.0, 3.0), TA.MAVP.sample(2.0, 2.0)]
  final_value(TA.MAVP.batch(samples, 2, 3, TA.MA.Kind.SMA()), 6.0)

def weighted_average() -> Bool:
  final_value(TA.MA.batch([1.0, 1.0, 3.0], 3, TA.MA.Kind.WMA()), 2.0)

def threshold_value(result: TA.Candle.State() & Maybe<&2, F32>, expected: F32) -> Bool:
  match result:
    case (state, Some{value}): F32.is_eq(value, expected)
    case _: False{}

def candle(initialized: Result<&2, &1, TA.Candle.Error(), TA.Candle.State()>, expected: F32) -> Bool:
  match initialized:
    case Done{state}: threshold_value(TA.Candle.next(state, TA.Bar.ohlc(2.0, 10.0, 2.0, 5.0)), expected)
    case Fail{error}: False{}

def pattern(result: Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>) -> Bool:
  match result:
    case Done{[Some{doji}, Some{other}]}:
      Bool.and(String.eq(TA.Pattern.show(doji), "100"), String.eq(TA.Pattern.show(other), "0"))
    case _: False{}

def doji() -> Bool:
  name : TA.Pattern.Name() = TA.CDLDOJI.name()
  setting : TA.Candle.Setting() = TA.Candle.setting(TA.Candle.RangeKind.HighLow(), 0, 0.1)
  settings = TA.Pattern.setting(TA.Pattern.defaults(), TA.Candle.Name.BodyDoji(), setting)
  pattern(TA.Pattern.batch([TA.Bar.ohlc(2.0, 4.0, 1.0, 2.0), TA.Bar.ohlc(2.0, 5.0, 1.0, 5.0)], name, settings, 0.0))

def hikkake.initialized(result: Result<&2, &1, TA.Pattern.Error(), TA.CDLHIKKAKEMOD.State()>) -> Bool:
  match result:
    case Done{state}: True{}
    case Fail{error}: False{}

def hikkake.lookback(result: TA.Lookback.Result()) -> Bool:
  match result:
    case Done{period}: U32.is_eq(period, 7)
    case Fail{error}: False{}

def hikkake() -> Bool:
  +near = TA.Candle.setting(TA.Candle.RangeKind.Shadows(), 2, 0.5)
  Bool.and(hikkake.lookback(TA.CDLHIKKAKEMOD.lookback.setting(near)), hikkake.initialized(TA.CDLHIKKAKEMOD.init.setting(near)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("public CORREL pairs", correl())
    Unit <- Assert.check("public BETA pairs", beta())
    Unit <- Assert.check("public binary operands", operands())
    Unit <- Assert.check("public MAVP samples and SMA selector", mavp())
    Unit <- Assert.check("public WMA selector", weighted_average())
    Unit <- Assert.check("public custom candle setting", candle(TA.Candle.init(TA.Candle.setting(TA.Candle.RangeKind.HighLow(), 0, 0.25)), 2.0))
    Unit <- Assert.check("public default candle setting", candle(TA.Candle.init(TA.Candle.defaults(TA.Candle.Name.ShadowLong())), 3.0))
    Unit <- Assert.check("public generic pattern with custom doji setting", doji())
    Assert.check("public modified Hikkake setting", hikkake())
