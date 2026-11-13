import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/parameters.bend as P
import ../../src/core/series.bend as Series
import ../../src/core/window_signals.bend as W
import ../../src/core/market_state.bend as M
import ../../src/core/variable.bend as V
import ../../src/core/transform.bend as Transform

def nan(+x: F32) -> Bool:
  Bool.not(F32.is_eq(x, x))

def near(+x: F32, +y: F32) -> Bool:
  Bool.or(F32.is_eq(x, y), Bool.or(Bool.and(nan(x), nan(y)), F32.is_lt(F32.abs(F32.sub(x, y)), 0.00001)))

def same(xs: List<&2, Maybe<&2, F32>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case None{} <> xs None{} <> ys: same(xs, ys)
    case Some{x} <> xs Some{y} <> ys: Bool.and(near(x, y), same(xs, ys))
    case _ _: False{}

def scalar(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{xs}: same(xs, ys)

def invalid(~S: Type, r: Result<&2, &1, P.Error, S>) -> Bool:
  match r:
    case Fail{e}: True{}
    case Done{s}: False{}

def cloud(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, W.CloudValue<F32>>>>) -> Bool:
  match r:
    case Done{[None{}, None{}, None{}, Some{W.CloudValue{a, b, c, d}}, Some{W.CloudValue{e, f, g, h}}]}: List.all(~&2, ~Bool, ~(x => x), [near(a, 5.0), near(b, 4.5), near(c, 4.75), near(d, 4.5), near(e, 5.5), near(f, 5.0), near(g, 5.25), near(h, 4.5)])
    case _: False{}

def fractal(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, W.PivotFlags>>>) -> Bool:
  match r:
    case Done{[None{}, None{}, Some{W.PivotFlags{100, 100, 1}}, Some{W.PivotFlags{0, 0, 2}}, Some{W.PivotFlags{100, 0, 3}}, Some{W.PivotFlags{0, 0, 4}}]}: True{}
    case _: False{}

def zigzag(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, M.ZigValue<F32>>>>) -> Bool:
  match r:
    case Done{[None{}, Some{M.ZigValue{a, Bar.Up{}, 1}}, Some{M.ZigValue{b, Bar.Down{}, 2}}, Some{M.ZigValue{c, Bar.Up{}, 3}}, Some{M.ZigValue{d, Bar.Down{}, 4}}]}: List.all(~&2, ~Bool, ~(x => x), [near(a, 11.0), near(b, 8.0), near(c, 12.0), near(d, 7.0)])
    case _: False{}

def continued(r: TA.MAVP.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match r:
    case (state, first): Bool.and(same(first, [None{}, None{}, Some{6.0}]), same(Series.batch(~V.Sample<F32>, ~F32, ~TA.MAVP.State(), ~TA.MAVP.next, [V.Sample{20.0, 3.0}, V.Sample{3.0, 2.0}, V.Sample{30.0, 3.0}], state), [Some{12.166667}, Some{7.111111}, Some{18.791667}]))

def resume(r: Result<&2, &1, P.Error, TA.MAVP.State()>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{s}: continued(Series.scan(~V.Sample<F32>, ~F32, ~TA.MAVP.State(), ~TA.MAVP.next, [V.Sample{1.0, 2.0}, V.Sample{10.0, 2.0}, V.Sample{2.0, 2.0}], s))

def shifts(a: W.DisplayShift, b: W.DisplayShift, c: W.DisplayShift) -> Bool:
  match a b c:
    case W.DisplayShift{True{}, 3} W.DisplayShift{False{}, 26} W.DisplayShift{True{}, 2}: True{}
    case _ _ _: False{}

def main() -> IO(Unit):
  +undefined = F32.div(0.0, 0.0)
  +inf = F32.div(1.0, 0.0)
  do IO<Unit>:
    Unit <- Assert.check("DPO.batch case 1", scalar(TA.DPO.batch([2.0, 4.0, 6.0, 8.0], 2), [None{}, None{}, Some{F32.neg(3.0)}, Some{F32.neg(3.0)}]))
    Unit <- Assert.check("DPO.batch case 2", scalar(TA.DPO.batch([1.0, 2.0, 3.0, 4.0, 5.0], 4), [None{}, None{}, None{}, Some{F32.neg(1.5)}, Some{F32.neg(1.5)}]))
    Unit <- Assert.check("RVOL.batch case 1", scalar(TA.RVOL.batch([2.0, 4.0, 6.0, 8.0], 2), [None{}, None{}, Some{2.0}, Some{1.6}]))
    Unit <- Assert.check("RVOL.batch case 2", scalar(TA.RVOL.batch([0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 6.0], 2), [None{}, None{}, Some{undefined}, Some{inf}, Some{0.0}, Some{0.0}, Some{inf}]))
    Unit <- Assert.check("VWAP.batch case 1", same(TA.VWAP.batch([Bar.HLCV{3.0, 1.0, 2.0, 0.0}, Bar.HLCV{5.0, 3.0, 4.0, 2.0}, Bar.HLCV{7.0, 5.0, 6.0, 2.0}]), [Some{0.0}, Some{4.0}, Some{5.0}]))
    Unit <- Assert.check("VWAP.batch case 2", same(TA.VWAP.batch([Bar.HLCV{3.0, 1.0, 2.0, 1.0}, Bar.HLCV{undefined, 1.0, 2.0, 9.0}, Bar.HLCV{5.0, 3.0, 4.0, inf}, Bar.HLCV{5.0, 3.0, 4.0, 1.0}]), [Some{2.0}, Some{2.0}, Some{2.0}, Some{3.0}]))
    Unit <- Assert.check("VWAP.batch case 3", same(TA.VWAP.batch([Bar.HLCV{3.0e20, 3.0e20, 3.0e20, 3.0e20}]), [Some{inf}]))
    Unit <- Assert.check("ICHIMOKU.batch", cloud(TA.ICHIMOKU.batch([Bar.HL{3.0, 1.0}, Bar.HL{5.0, 1.0}, Bar.HL{4.0, 2.0}, Bar.HL{8.0, 4.0}, Bar.HL{6.0, 3.0}], 2, 3, 4)))
    Unit <- Assert.check("FRACTAL.batch", fractal(TA.FRACTAL.batch([Bar.HL{2.0, 0.0}, Bar.HL{5.0, F32.neg(2.0)}, Bar.HL{3.0, 1.0}, Bar.HL{5.0, 1.0}, Bar.HL{4.0, 0.0}, Bar.HL{4.0, 0.0}], 1, 1)))
    Unit <- Assert.check("ZIGZAG.batch", zigzag(TA.ZIGZAG.batch([Bar.HL{10.0, 9.0}, Bar.HL{11.0, 10.0}, Bar.HL{12.0, 8.0}, Bar.HL{12.0, 9.0}, Bar.HL{10.0, 7.0}], 10.0, 1)))
    Unit <- Assert.check("MAVP.init", resume(TA.MAVP.init(2, 3, 1)))
    Unit <- Assert.check("MAVP.batch", scalar(TA.MAVP.batch([V.Sample{3.0, undefined}, V.Sample{4.0, inf}, V.Sample{5.0, F32.neg(inf)}], 1, 2, 10), [Some{3.0}, Some{4.0}, Some{5.0}]))
    Unit <- Assert.check("shifts", shifts(TA.DPO.display_shift(4), TA.ICHIMOKU.display_shift(26), TA.FRACTAL.display_shift(2)))
    Unit <- Assert.check("nan", Bool.and(nan(TA.DIV(Transform.Operands{0.0, 0.0})), Bool.and(F32.is_eq(TA.DIV(Transform.Operands{1.0, 0.0}), inf), U32.is_eq(F32.bits(TA.DIV(Transform.Operands{F32.neg(0.0), 2.0})), 2147483648))))
    Unit <- Assert.check("DPO.init", List.all(~&2, ~Bool, ~(x => x), [invalid(~TA.DPO.State(), TA.DPO.init(1)), invalid(~TA.RVOL.State(), TA.RVOL.init(100001)), invalid(~TA.ICHIMOKU.State(), TA.ICHIMOKU.init(2, 1, 2)), invalid(~TA.FRACTAL.State(), TA.FRACTAL.init(0, 1)), invalid(~TA.ZIGZAG.State(), TA.ZIGZAG.init(undefined, 1)), invalid(~TA.ZIGZAG.State(), TA.ZIGZAG.init(5.0, 0)), invalid(~TA.MAVP.State(), TA.MAVP.init(3, 2, 1)), invalid(~TA.MAVP.State(), TA.MAVP.init(1, 10001, 0)), invalid(~TA.MAVP.State(), TA.MAVP.init(1, 2, 11))]))
    Assert.check("DPO.batch case 3", Bool.and(scalar(TA.DPO.batch([], 2), []), scalar(TA.MAVP.batch([V.Sample{3.0, 2.0}], 2, 3, 1), [None{}])))
