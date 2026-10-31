import Base
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/parameters.bend as P
import ../../src/core/overlap.bend as O
import ../../src/core/series.bend as Series

def show(~A: Data, ~format: A -> String, value: Result<&2, &2, P.Error, List<&2, Maybe<&2, A>>>) -> String:
  match value:
    case Fail{e}: "invalid"
    case Done{xs}: List.show(~&2, ~Maybe<&2, A>, ~(x => Maybe.show(~&2, ~A, ~format, x)), xs)

def bands(v: O.Bands<F32>) -> String:
  match v:
    case O.Bands{u, m, l}: F32.show(u) ++ "," ++ F32.show(m) ++ "," ++ F32.show(l)

def stops(v: O.Stops<F32>) -> String:
  match v:
    case O.Stops{h, l}: F32.show(h) ++ "," ++ F32.show(l)

def prices(v: Bar.OHLC<F32>) -> String:
  match v:
    case Bar.OHLC{o, h, l, c}: F32.show(o) ++ "," ++ F32.show(h) ++ "," ++ F32.show(l) ++ "," ++ F32.show(c)

def close.values(xs: List<&2, Maybe<&2, F32>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs expected:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: close.values(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(F32.is_lt(F32.abs(F32.sub(x, y)), 0.00001), close.values(xs, ys))
    case _ _: False{}

def close(value: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, expected: List<&2, Maybe<&2, F32>>) -> String:
  match value:
    case Fail{e}: "False"
    case Done{xs}: Bool.show(close.values(xs, expected))

def identity.values(xs: List<&2, Maybe<&2, F32>>) -> String:
  match xs:
    case Some{x} <> Some{y} <> Nil{}: Bool.show(Bool.and(U32.is_eq(F32.bits(x), 2147483648), F32.is_eq(y, 1.0)))
    case _: "False"

def identity(value: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>) -> String:
  match value:
    case Fail{e}: "False"
    case Done{xs}: identity.values(xs)

def continued.scan(value: TA.WMA.State() & List<&2, Maybe<&2, F32>>) -> String:
  match value:
    case (state, first): List.show(~&2, ~Maybe<&2, F32>, ~(v => Maybe.show(~&2, ~F32, ~F32.show, v)), Series.batch(~F32, ~F32, ~TA.WMA.State(), ~TA.WMA.next, [3.0, 4.0], state))

def continued(value: Result<&2, &1, P.Error, TA.WMA.State()>) -> String:
  match value:
    case Fail{e}: "invalid"
    case Done{state}: continued.scan(Series.scan(~F32, ~F32, ~TA.WMA.State(), ~TA.WMA.next, [1.0, 2.0], state))

def main() -> IO(Unit):
  +ramp : List<&2, F32> = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
  +bars : List<&2, Bar.HLC<F32>> = [Bar.HLC{3.0, 1.0, 2.0}, Bar.HLC{4.0, 2.0, 3.0}, Bar.HLC{5.0, 3.0, 4.0}, Bar.HLC{6.0, 4.0, 5.0}, Bar.HLC{7.0, 5.0, 6.0}]
  do IO<Unit>:
    IO.print(close(TA.WMA.batch([1.0, 2.0, 3.0, 4.0], 3), [None{}, None{}, Some{2.3333333}, Some{3.3333333}]))
    IO.print(close(TA.WMA.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38], 3), [None{}, None{}, Some{1.0e38}, Some{1.0e38}]))
    IO.print(close(TA.T3.batch([1.0e38, 1.0e38, 1.0e38, 1.0e38, 1.0e38, 1.0e38, 1.0e38], 2, 0.7), [None{}, None{}, None{}, None{}, None{}, None{}, Some{1.0e38}]))
    IO.print(show(~F32, ~F32.show, TA.TRIMA.batch(ramp, 4)))
    IO.print(show(~F32, ~F32.show, TA.DEMA.batch(ramp, 2)))
    IO.print(show(~F32, ~F32.show, TA.TEMA.batch(ramp, 2)))
    IO.print(show(~F32, ~F32.show, TA.T3.batch(ramp, 2, 0.0)))
    IO.print(close(TA.HMA.batch([1.0, 2.0, 3.0, 4.0, 5.0], 4), [None{}, None{}, None{}, None{}, Some{5.0}]))
    IO.print(show(~F32, ~F32.show, TA.ZLEMA.batch([1.0, 2.0, 3.0, 4.0, 5.0], 3)))
    IO.print(close(TA.KAMA.batch([1.0, 2.0, 3.0, 4.0], 2), [None{}, None{}, Some{2.4444444}, Some{3.1358025}]))
    IO.print(show(~F32, ~F32.show, TA.ALMA.batch([1.0, 2.0, 3.0, 4.0], 4, 1.0e30, 0.5)))
    IO.print(identity(TA.ALMA.batch([F32.neg(0.0), 1.0], 1, 6.0, 0.85)))
    IO.print(identity(TA.MA.batch([F32.neg(0.0), 1.0], 1, 11)))
    IO.print(show(~F32, ~F32.show, TA.MA.batch([], 2, 11)))
    IO.print(show(~F32, ~F32.show, TA.ALMA.batch([], 0, 6.0, 0.85)))
    IO.print(show(~TA.BBANDS.Value(), ~bands, TA.BBANDS.batch([0.0, 2.0, 4.0], 2, 2.0, 1.0, 0)))
    IO.print(show(~F32, ~F32.show, TA.BBW.batch([0.0, 2.0, 4.0], 2, 2.0, 1.0, 0)))
    IO.print(close(TA.PERCENTB.batch([1000000.0, 1000000.0625, 1000000.125], 2, 2.0, 1.5, 0), [None{}, Some{0.714285714}, Some{0.714285714}]))
    IO.print(show(~F32, ~F32.show, TA.PERCENTB.batch([7.0, 7.0, 7.0], 2, 2.0, 2.0, 0)))
    IO.print(show(~TA.KC.Value(), ~bands, TA.KC.batch(bars, 2, 3, 2.0)))
    IO.print(show(~TA.CKSP.Value(), ~stops, TA.CKSP.batch(bars, 2, 1.0, 2)))
    IO.print(show(~TA.ACCBANDS.Value(), ~bands, TA.ACCBANDS.batch([Bar.HLC{3.0, 1.0, 2.0}, Bar.HLC{3.0, 1.0, 2.0}], 2)))
    IO.print(show(~TA.DONCHIAN.Value(), ~bands, TA.DONCHIAN.batch([Bar.HL{4.0, 2.0}, Bar.HL{5.0, 3.0}, Bar.HL{3.0, 0.0}], 2)))
    IO.print(show(~F32, ~F32.show, TA.MIDPRICE.batch([Bar.HL{4.0, 2.0}, Bar.HL{5.0, 3.0}, Bar.HL{3.0, 0.0}], 2)))
    IO.print(show(~F32, ~F32.show, TA.VWMA.batch([Bar.CV{2.0, 1.0}, Bar.CV{4.0, 3.0}, Bar.CV{8.0, 1.0}], 2)))
    IO.print(List.show(~&2, ~Maybe<&2, TA.HA.Value()>, ~(x => Maybe.show(~&2, ~TA.HA.Value(), ~prices, x)), TA.HA.batch([Bar.OHLC{2.0, 5.0, 1.0, 4.0}, Bar.OHLC{4.0, 8.0, 2.0, 6.0}, Bar.OHLC{6.0, 9.0, 3.0, 8.0}])))
    IO.print(continued(TA.WMA.init(3)))
    IO.print(close(TA.ALMA.batch([1.0], 100000, 6.0, 0.85), [None{}]))

#|True
#|True
#|True
#|[None, None, None, Some(2.5), Some(3.5), Some(4.5), Some(5.5), Some(6.5)]
#|[None, None, Some(3), Some(4), Some(5), Some(6), Some(7), Some(8)]
#|[None, None, None, Some(4), Some(5), Some(6), Some(7), Some(8)]
#|[None, None, None, None, None, None, Some(5.5), Some(6.5)]
#|True
#|[None, None, None, Some(4), Some(5)]
#|True
#|[None, None, None, Some(2)]
#|True
#|True
#|invalid
#|invalid
#|[None, Some(3,1,0), Some(5,3,2)]
#|[None, Some(300), Some(100)]
#|True
#|[None, Some(0.5), Some(0.5)]
#|[None, None, None, Some(8.5,4.5,0.5), Some(9.5,5.5,1.5)]
#|[None, None, None, Some(4,4), Some(5,5)]
#|[None, Some(9,2,-1)]
#|[None, Some(5,3.5,2), Some(5,2.5,0)]
#|[None, Some(3.5), Some(2.5)]
#|[None, Some(3.5), Some(5)]
#|[Some(3,5,1,3), Some(3,8,2,5), Some(4,9,3,6.5)]
#|[Some(2.3333333), Some(3.3333333)]

#|True
