import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/clone.bend as Clone
import ../../src/core/series.bend as Series
import ../../src/core/config.bend as Config
import ../../src/core/parameters.bend as Params
import ../../src/core/overlap.bend as Overlap
import ../../src/core/window.bend as Window
import ../../src/core/variable.bend as Variable

def near(+a: F32, +b: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(a, b)), 0.00001)

def slot(a: Maybe<&2, F32>, b: Maybe<&2, F32>) -> Bool:
  match a b:
    case None{} None{}: True{}
    case Some{x} Some{y}: near(x, y)
    case _ _: False{}

def same(xs: List<&2, Maybe<&2, F32>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case h <> t x <> rest: Bool.and(slot(h, x), same(t, rest))
    case _ _: False{}

def sma.forks(result: TA.SMA.State() & TA.SMA.State()) -> Bool:
  (a, b) = result
  Bool.and(same(Series.batch(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [10.0,11.0], a), [Some{5.0},Some{8.0}]), same(Series.batch(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [4.0,5.0], b), [Some{3.0},Some{4.0}]))

def preview.last(result: TA.SMA.State() & Maybe<&2, F32>) -> Bool:
  (state, value) = result
  Bool.and(slot(value, Some{F32.div(5.0,3.0)}), same(Series.batch(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [4.0], state), [Some{3.0}]))

def preview.first(result: TA.SMA.State() & Maybe<&2, F32>) -> Bool:
  (state, value) = result
  Bool.and(slot(value, Some{F32.div(14.0,3.0)}), preview.last(TA.SMA.preview(state, 0.0)))

def preview.empty(result: TA.SMA.State() & Maybe<&2, F32>) -> Bool:
  (state, value) = result
  Bool.and(slot(value, None{}), same(Series.batch(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [1.0,2.0,3.0], state), [None{},None{},Some{2.0}]))

def sma.ready(kind: U32, result: TA.SMA.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match kind result:
    case 0 Tuple{state, values}: sma.forks(TA.SMA.clone(state))
    case _ Tuple{state, values}: preview.first(TA.SMA.preview(state, 9.0))

def sma.start(kind: U32, result: Result<&2, &1, Config.Error, TA.SMA.State()>) -> Bool:
  match kind result:
    case _ Fail{e}: False{}
    case 2 Done{state}: preview.empty(TA.SMA.preview(state, 9.0))
    case kind Done{state}: sma.ready(kind, Series.scan(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [1.0,2.0,3.0], state))

def band(value: Maybe<&2, Overlap.Bands<F32>>, +center: F32, +deviation: F32) -> Bool:
  match value:
    case None{}: False{}
    case Some{Overlap.Bands{high, middle, low}}: Bool.and(near(middle, center), Bool.and(near(high, F32.add(center, deviation)), near(low, F32.sub(center, deviation))))

def bands(xs: List<&2, Maybe<&2, Overlap.Bands<F32>>>, first: F32, second: F32, +deviation: F32) -> Bool:
  match xs:
    case [a,b]: Bool.and(band(a, first, deviation), band(b, second, deviation))
    case _: False{}

def bands.forks(result: TA.BBANDS.State() & TA.BBANDS.State()) -> Bool:
  (a, b) = result
  Bool.and(bands(Series.batch(~F32, ~TA.BBANDS.Value(), ~TA.BBANDS.State(), ~TA.BBANDS.next, [10.0,11.0], a), 5.0, 8.0, F32.sqrt(F32.div(38.0,3.0))), bands(Series.batch(~F32, ~TA.BBANDS.Value(), ~TA.BBANDS.State(), ~TA.BBANDS.next, [4.0,5.0], b), 3.0, 4.0, F32.sqrt(F32.div(2.0,3.0))))

def bands.ready(result: TA.BBANDS.State() & List<&2, Maybe<&2, TA.BBANDS.Value()>>) -> Bool:
  (state, values) = result
  bands.forks(TA.BBANDS.clone(state))

def bands.start(result: Result<&2, &1, Params.Error, TA.BBANDS.State()>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{state}: bands.ready(Series.scan(~F32, ~TA.BBANDS.Value(), ~TA.BBANDS.State(), ~TA.BBANDS.next, [1.0,2.0,3.0], state))

def maximum.forks(result: TA.MAX.State() & TA.MAX.State()) -> Bool:
  (a, b) = result
  Bool.and(same(Series.batch(~F32, ~F32, ~TA.MAX.State(), ~TA.MAX.next, [9.0,8.0], a), [Some{9.0},Some{9.0}]), same(Series.batch(~F32, ~F32, ~TA.MAX.State(), ~TA.MAX.next, [1.0,0.0], b), [Some{3.0},Some{3.0}]))

def maximum.ready(result: TA.MAX.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  (state, values) = result
  maximum.forks(TA.MAX.clone(state))

def maximum.start(result: Result<&2, &1, Params.Error, TA.MAX.State()>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{state}: maximum.ready(Series.scan(~F32, ~F32, ~TA.MAX.State(), ~TA.MAX.next, [4.0,2.0,3.0], state))

def sample(price: F32) -> Variable.Sample<F32>:
  Variable.Sample{price,4.0}

def variable.forks(result: TA.MAVP.State() & TA.MAVP.State()) -> Bool:
  (a, b) = result
  Bool.and(same(Series.batch(~TA.MAVP.Sample(), ~F32, ~TA.MAVP.State(), ~TA.MAVP.next, [Variable.Sample{10.0,3.0},Variable.Sample{11.0,2.0}], a), [Some{F32.div(17.0,3.0)},Some{10.5}]), same(Series.batch(~TA.MAVP.Sample(), ~F32, ~TA.MAVP.State(), ~TA.MAVP.next, [Variable.Sample{5.0,3.0},Variable.Sample{6.0,2.0}], b), [Some{4.0},Some{5.5}]))

def variable.ready(result: TA.MAVP.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  (state, values) = result
  variable.forks(TA.MAVP.clone(state))

def variable.start(result: Result<&2, &1, Params.Error, TA.MAVP.State()>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{state}: variable.ready(Series.scan(~TA.MAVP.Sample(), ~F32, ~TA.MAVP.State(), ~TA.MAVP.next, Series.map(~F32, ~TA.MAVP.Sample(), ~sample, [1.0,2.0,3.0,4.0]), state))

type Number is Data:
  Number{value: F32, marker: U32}

def multi.value(result: Window.State<Number> & Maybe<&2, Number>) -> Bool:
  match result:
    case (state, Some{Number{value, marker}}): Bool.and(near(value,1.0), U32.is_eq(marker,77))
    case _: False{}

def multi.changed(copy: Window.State<Number>, result: Window.State<Number> & Maybe<&2, Number>) -> Bool:
  (state, old) = result
  multi.value(Window.lag(~Number,copy,2))

def multi.forks(result: Window.State<Number> & Window.State<Number>) -> Bool:
  (a, b) = result
  multi.changed(b, Window.push(~Number,a,Number{9.0,99}))

def multi.ready(result: Window.State<Number> & List<&2, Maybe<&2, Number>>) -> Bool:
  (state, values) = result
  multi.forks(Clone.window(~Number,state))

def push(state: Window.State<Number>, value: Number) -> Window.State<Number> & Maybe<&2, Number>:
  Window.push(~Number,state,value)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("SMA.init case 1", sma.start(0,TA.SMA.init(3)))
    Unit <- Assert.check("SMA.init case 2", sma.start(1,TA.SMA.init(3)))
    Unit <- Assert.check("SMA.init case 3", sma.start(2,TA.SMA.init(3)))
    Unit <- Assert.check("BBANDS.init", bands.start(TA.BBANDS.init(3,1.0,1.0,0)))
    Unit <- Assert.check("MAX.init", maximum.start(TA.MAX.init(3)))
    Unit <- Assert.check("MAVP.init", variable.start(TA.MAVP.init(2,4,0)))
    Assert.check("multi.ready", multi.ready(Series.scan(~Number, ~Number, ~Window.State<Number>, ~push, [Number{1.0,77},Number{2.0,88},Number{3.0,99}], Window.init(~Number,3,2n,Number{0.0,0}))))
