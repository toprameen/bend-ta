import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/parameters.bend as P
import ../../src/core/overlap.bend as O
import ../../src/core/series.bend as Series

def bands(actual: TA.BBANDS.Value(), expected: O.Bands<F32>) -> Bool:
  match expected:
    case O.Bands{upper, middle, lower}:
      +actual = actual
      Bool.and(F32.is_eq(TA.BBANDS.upper(actual), upper),
        Bool.and(F32.is_eq(TA.BBANDS.middle(actual), middle), F32.is_eq(TA.BBANDS.lower(actual), lower)))

def stops(actual: TA.CKSP.Value(), expected: O.Stops<F32>) -> Bool:
  match expected:
    case O.Stops{high, low}:
      +actual = actual
      Bool.and(F32.is_eq(TA.CKSP.high_stop(actual), high), F32.is_eq(TA.CKSP.low_stop(actual), low))

def prices(actual: Bar.OHLC<F32>, expected: Bar.OHLC<F32>) -> Bool:
  match actual expected:
    case Bar.OHLC{o, h, l, c} Bar.OHLC{expected_o, expected_h, expected_l, expected_c}:
      Bool.and(F32.is_eq(o, expected_o), Bool.and(F32.is_eq(h, expected_h), Bool.and(F32.is_eq(l, expected_l), F32.is_eq(c, expected_c))))

def close.values(xs: List<&2, Maybe<&2, F32>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs expected:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: close.values(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(F32.is_lt(F32.abs(F32.sub(x, y)), 0.00001), close.values(xs, ys))
    case _ _: False{}

def close(value: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match value:
    case Fail{e}: False{}
    case Done{xs}: close.values(xs, expected)

def identity.values(xs: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs:
    case Some{x} <> Some{y} <> Nil{}: Bool.and(U32.is_eq(F32.bits(x), 2147483648), F32.is_eq(y, 1.0))
    case _: False{}

def identity(value: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>) -> Bool:
  match value:
    case Fail{e}: False{}
    case Done{xs}: identity.values(xs)

def continued.scan(value: TA.WMA.State() & List<&2, Maybe<&2, F32>>) -> Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>:
  match value:
    case (state, first): Done{Series.batch(~F32, ~F32, ~TA.WMA.State(), ~TA.WMA.next, [3.0, 4.0], state)}

def continued(value: Result<&2, &1, P.Error, TA.WMA.State()>) -> Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>:
  match value:
    case Fail{e}: Fail{e}
    case Done{state}: continued.scan(Series.scan(~F32, ~F32, ~TA.WMA.State(), ~TA.WMA.next, [1.0, 2.0], state))

def main() -> IO(Unit):
  +ramp : List<&2, F32> = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
  +bars : List<&2, Bar.HLC<F32>> = [Bar.HLC{3.0, 1.0, 2.0}, Bar.HLC{4.0, 2.0, 3.0}, Bar.HLC{5.0, 3.0, 4.0}, Bar.HLC{6.0, 4.0, 5.0}, Bar.HLC{7.0, 5.0, 6.0}]
  do IO<Unit>:
    Unit <- Assert.check("WMA.batch case 1", close(TA.WMA.batch([1.0, 2.0, 3.0, 4.0], 3), [None{}, None{}, Some{2.3333333}, Some{3.3333333}]))
    Unit <- Assert.check("WMA.batch case 2", close(TA.WMA.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38], 3), [None{}, None{}, Some{1.0e38}, Some{1.0e38}]))
    Unit <- Assert.check("T3.batch case 1", close(TA.T3.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38, 1.0e38, 1.0e38, 1.0e38], 2, 0.7), [None{}, None{}, None{}, None{}, None{}, None{}, Some{1.0e38}]))
    Unit <- Assert.check("TRIMA.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.TRIMA.batch(ramp, 4), [None{}, None{}, None{}, Some{2.5}, Some{3.5}, Some{4.5}, Some{5.5}, Some{6.5}]))
    Unit <- Assert.check("DEMA.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.DEMA.batch(ramp, 2), [None{}, None{}, Some{3.0}, Some{4.0}, Some{5.0}, Some{6.0}, Some{7.0}, Some{8.0}]))
    Unit <- Assert.check("TEMA.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.TEMA.batch(ramp, 2), [None{}, None{}, None{}, Some{4.0}, Some{5.0}, Some{6.0}, Some{7.0}, Some{8.0}]))
    Unit <- Assert.check("T3.batch case 2", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.T3.batch(ramp, 2, 0.0), [None{}, None{}, None{}, None{}, None{}, None{}, Some{5.5}, Some{6.5}]))
    Unit <- Assert.check("HMA.batch", close(TA.HMA.batch([1.0, 2.0, 3.0, 4.0, 5.0], 4), [None{}, None{}, None{}, None{}, Some{5.0}]))
    Unit <- Assert.check("ZLEMA.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.ZLEMA.batch([1.0, 2.0, 3.0, 4.0, 5.0], 3), [None{}, None{}, None{}, Some{4.0}, Some{5.0}]))
    Unit <- Assert.check("KAMA.batch", close(TA.KAMA.batch([1.0, 2.0, 3.0, 4.0], 2), [None{}, None{}, Some{2.4444444}, Some{3.1358025}]))
    Unit <- Assert.check("ALMA concentrated at the kernel center", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.ALMA.batch([40000000.0, 2.0, 1.0, 40000004.0], 4, 1.0e30, 0.5), [None{}, None{}, None{}, Some{2.0}]))
    Unit <- Assert.check("ALMA.batch case 2", identity(TA.ALMA.batch([F32.neg(0.0), 1.0], 1, 6.0, 0.85)))
    Unit <- Assert.check("MA.batch case 1", identity(TA.MA.batch([F32.neg(0.0), 1.0], 1, 11)))
    Unit <- Assert.check("MA.batch case 2", Result.is_fail(&2, &2, P.Error, List<&2, Maybe<&2, F32>>, TA.MA.batch([], 2, 11)))
    Unit <- Assert.check("ALMA.batch case 3", Result.is_fail(&2, &2, P.Error, List<&2, Maybe<&2, F32>>, TA.ALMA.batch([], 0, 6.0, 0.85)))
    Unit <- Assert.check("BBANDS.batch", Assert.batch(~P.Error, ~O.Bands<F32>, ~bands, TA.BBANDS.batch([0.0, 2.0, 4.0], 2, 2.0, 1.0, 0), [None{}, Some{O.Bands{3.0, 1.0, 0.0}}, Some{O.Bands{5.0, 3.0, 2.0}}]))
    Unit <- Assert.check("BBW.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.BBW.batch([0.0, 2.0, 4.0], 2, 2.0, 1.0, 0), [None{}, Some{300.0}, Some{100.0}]))
    Unit <- Assert.check("PERCENTB.batch case 1", close(TA.PERCENTB.batch([1000000.0, 1000000.0625, 1000000.125], 2, 2.0, 1.5, 0), [None{}, Some{0.714285714}, Some{0.714285714}]))
    Unit <- Assert.check("PERCENTB.batch case 2", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.PERCENTB.batch([7.0, 7.0, 7.0], 2, 2.0, 2.0, 0), [None{}, Some{0.5}, Some{0.5}]))
    Unit <- Assert.check("KC.batch", Assert.batch(~P.Error, ~O.Bands<F32>, ~bands, TA.KC.batch(bars, 2, 3, 2.0), [None{}, None{}, None{}, Some{O.Bands{8.5, 4.5, 0.5}}, Some{O.Bands{9.5, 5.5, 1.5}}]))
    Unit <- Assert.check("CKSP.batch", Assert.batch(~P.Error, ~O.Stops<F32>, ~stops, TA.CKSP.batch(bars, 2, 1.0, 2), [None{}, None{}, None{}, Some{O.Stops{4.0, 4.0}}, Some{O.Stops{5.0, 5.0}}]))
    Unit <- Assert.check("ACCBANDS.batch", Assert.batch(~P.Error, ~O.Bands<F32>, ~bands, TA.ACCBANDS.batch([Bar.HLC{3.0, 1.0, 2.0}, Bar.HLC{3.0, 1.0, 2.0}], 2), [None{}, Some{O.Bands{9.0, 2.0, F32.neg(1.0)}}]))
    Unit <- Assert.check("DONCHIAN.batch", Assert.batch(~P.Error, ~O.Bands<F32>, ~bands, TA.DONCHIAN.batch([Bar.HL{4.0, 2.0}, Bar.HL{5.0, 3.0}, Bar.HL{3.0, 0.0}], 2), [None{}, Some{O.Bands{5.0, 3.5, 2.0}}, Some{O.Bands{5.0, 2.5, 0.0}}]))
    Unit <- Assert.check("MIDPRICE.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.MIDPRICE.batch([Bar.HL{4.0, 2.0}, Bar.HL{5.0, 3.0}, Bar.HL{3.0, 0.0}], 2), [None{}, Some{3.5}, Some{2.5}]))
    Unit <- Assert.check("VWMA.batch", Assert.batch(~P.Error, ~F32, ~F32.is_eq, TA.VWMA.batch([Bar.CV{2.0, 1.0}, Bar.CV{4.0, 3.0}, Bar.CV{8.0, 1.0}], 2), [None{}, Some{3.5}, Some{5.0}]))
    Unit <- Assert.check("HA.batch", Assert.series(~Bar.OHLC<F32>, ~prices, TA.HA.batch([Bar.OHLC{2.0, 5.0, 1.0, 4.0}, Bar.OHLC{4.0, 8.0, 2.0, 6.0}, Bar.OHLC{6.0, 9.0, 3.0, 8.0}]), [Some{Bar.OHLC{3.0, 5.0, 1.0, 3.0}}, Some{Bar.OHLC{3.0, 8.0, 2.0, 5.0}}, Some{Bar.OHLC{4.0, 9.0, 3.0, 6.5}}]))
    Unit <- Assert.check("WMA.init", Assert.batch(~P.Error, ~F32, ~F32.is_eq, continued(TA.WMA.init(3)), [Some{2.3333333}, Some{3.3333333}]))
    Assert.check("ALMA.batch case 4", close(TA.ALMA.batch([1.0], 100000, 6.0, 0.85), [None{}]))
