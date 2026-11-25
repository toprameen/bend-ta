import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as B
import ../../src/core/volume_filter.bend as V
import ../../src/core/parameters.bend as P
import ../../src/core/series.bend as Series

def near(x: F32, +y: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(x, y)), F32.mul(0.00002, F32.max(1.0, F32.abs(y))))

def same(xs: List<&2, Maybe<&2, F32>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: same(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(near(x, y), same(xs, ys))
    case _ _: False{}

def result(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{xs}: same(xs, ys)

def lines(xs: List<&2, Maybe<&2, TA.KVO.Value()>>, ys: List<&2, Maybe<&2, TA.KVO.Value()>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: lines(xs, ys)
    case Some{+value} <> xs Some{V.Lines{y, t}} <> ys:
      Bool.and(Bool.and(near(TA.KVO.kvo(value), y), near(TA.KVO.signal(value), t)), lines(xs, ys))
    case _ _: False{}

def kvo(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, TA.KVO.Value()>>>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{xs}: lines(xs, [None{}, None{}, None{}, Some{V.Lines{F32.neg(14.6825397), F32.neg(7.989418)}}, Some{V.Lines{F32.neg(13.5846561), F32.neg(11.7195767)}}, Some{V.Lines{35.5709877, 19.8074662}}])

def kvo.centered(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, TA.KVO.Value()>>>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{xs}: lines(xs, [None{}, None{}, None{}, Some{V.Lines{F32.neg(22.4603175), F32.neg(11.6931217)}}, Some{V.Lines{4.0608466, F32.neg(1.1904762)}}, Some{V.Lines{F32.neg(38.1106702), F32.neg(25.8039389)}}])

def rvi.continued(r: TA.RVI.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match r:
    case (state, first): Bool.and(same(first, [None{}, None{}, Some{66.6666667}]), same(Series.batch(~F32, ~F32, ~TA.RVI.State(), ~TA.RVI.next, [2.0, 4.0, 1.0], state), [Some{66.6666667}, Some{90.9090909}, Some{28.5714286}]))

def rvi.init(r: Result<&2, &1, P.Error, TA.RVI.State()>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{state}: rvi.continued(Series.scan(~F32, ~F32, ~TA.RVI.State(), ~TA.RVI.next, [1.0, 3.0, 2.0], state))

def invalid(~S: Type, r: Result<&2, &1, P.Error, S>) -> Bool:
  match r:
    case Fail{e}: True{}
    case Done{state}: False{}

def main() -> IO(Unit):
  +bars : List<&2, B.HLCV<F32>> = [B.HLCV{12.0, 8.0, 11.0, 2.0}, B.HLCV{15.0, 9.0, 10.0, 4.0}, B.HLCV{14.0, 10.0, 13.0, 3.0}, B.HLCV{8.0, 4.0, 7.0, 6.0}, B.HLCV{11.0, 7.0, 9.0, 3.0}, B.HLCV{11.0, 7.0, 9.0, 8.0}]
  +ohlc : List<&2, B.OHLC<F32>> = [B.OHLC{2.0, 4.0, 1.0, 2.0}, B.OHLC{0.0, 8.0, 2.0, 4.0}, B.OHLC{1.0, 1.0, 1.0, 1.0}, B.OHLC{2.0, 2.0, 2.0, 2.0}]
  do IO<Unit>:
    Unit <- Assert.check("ADOSC.batch case 1", result(TA.ADOSC.batch(bars, 2, 3), [None{}, None{}, Some{F32.neg(0.12037037)}, Some{0.47376543}, Some{0.41486626}, Some{0.26676097}]))
    Unit <- Assert.check("ADOSC.batch case 2", result(TA.ADOSC.batch(bars, 3, 2), [None{}, None{}, Some{0.12037037}, Some{F32.neg(0.47376543)}, Some{F32.neg(0.41486626)}, Some{F32.neg(0.26676097)}]))
    Unit <- Assert.check("KVO.batch case 1", kvo(TA.KVO.batch(bars, 2, 3, 2)))
    Unit <- Assert.check("KVO.batch case 2", kvo.centered(TA.KVO.batch([B.HLCV{1000000.125, 1000000.0, 1000000.0625, 1.0}, B.HLCV{1000000.25, 1000000.0625, 1000000.125, 2.0}, B.HLCV{1000000.1875, 1000000.0625, 1000000.1875, 3.0}, B.HLCV{1000000.1875, 1000000.0, 1000000.125, 4.0}, B.HLCV{1000000.25, 1000000.0, 1000000.125, 5.0}, B.HLCV{1000000.125, 1000000.0, 1000000.0625, 6.0}], 2, 3, 2)))
    Unit <- Assert.check("RVI.init", rvi.init(TA.RVI.init(2, 2)))
    Unit <- Assert.check("RVI.batch", result(TA.RVI.batch([1.0, 3.0, 2.0, 2.0, 4.0], 1, 3), [None{}, None{}, Some{0.0}, Some{50.0}, Some{100.0}]))
    Unit <- Assert.check("RVIR.batch", result(TA.RVIR.batch([B.HL{3.0, 1.0}, B.HL{5.0, 2.0}, B.HL{4.0, 1.0}, B.HL{4.0, 1.0}, B.HL{6.0, 3.0}], 2, 2), [None{}, None{}, Some{58.3333333}, Some{58.3333333}, Some{90.4545455}]))
    Unit <- Assert.check("ROGERSSATCHELL.batch case 1", result(TA.ROGERSSATCHELL.batch(ohlc, 2, 1.0), [None{}, Some{0.69314718}, Some{0.0}, Some{0.0}]))
    Unit <- Assert.check("ROGERSSATCHELL.batch case 2", result(TA.ROGERSSATCHELL.batch(ohlc, 1, 4.0), [Some{1.96051629}, Some{0.0}, Some{0.0}, Some{0.0}]))
    Unit <- Assert.check("ADOSC.init", Bool.and(invalid(~TA.ADOSC.State(), TA.ADOSC.init(1, 2)), Bool.and(invalid(~TA.KVO.State(), TA.KVO.init(2, 2, 1)), invalid(~TA.RVI.State(), TA.RVI.init(2, 1)))))
    Assert.check("ROGERSSATCHELL.init", Bool.and(invalid(~TA.ROGERSSATCHELL.State(), TA.ROGERSSATCHELL.init(1, F32.neg(1.0))), result(TA.RVI.batch([], 1, 2), [])))
