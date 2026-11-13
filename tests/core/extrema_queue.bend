import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/parameters.bend as P
import ../../src/core/statistics.bend as Stats
import ../../src/core/overlap.bend as Overlap
import ../../src/core/bar.bend as Bar
import ../../src/core/series.bend as Series
import ../../src/core/extrema_queue.bend as Queue

def indices(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, Stats.MinMaxIndex>>>) -> Bool:
  match r:
    case Done{[None{}, None{}, Some{Stats.MinMaxIndex{2, 0}}, Some{Stats.MinMaxIndex{2, 3}}, Some{Stats.MinMaxIndex{4, 3}}, Some{Stats.MinMaxIndex{4, 5}}, Some{Stats.MinMaxIndex{4, 6}}]}: True{}
    case _: False{}

def burst(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, Stats.MinMaxIndex>>>) -> Bool:
  match r:
    case Done{[None{}, None{}, None{}, None{}, None{}, None{}, Some{Stats.MinMaxIndex{6, 0}}, Some{Stats.MinMaxIndex{6, 7}}]}: True{}
    case _: False{}

def expired(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, Stats.MinMax<F32>>>>) -> Bool:
  match r:
    case Done{[None{}, None{}, Some{Stats.MinMax{a, b}}, Some{Stats.MinMax{c, d}}, Some{Stats.MinMax{e, f}}]}: List.all(~&2, ~Bool, ~(x => x), [F32.is_eq(a, 1.0), F32.is_eq(b, 9.0), F32.is_eq(c, 1.0), F32.is_eq(d, 3.0), F32.is_eq(e, 2.0), F32.is_eq(f, 4.0)])
    case _: False{}

def zeros(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>, a: U32, b: U32, c: U32) -> Bool:
  match r:
    case Done{[None{}, Some{x}, Some{y}, Some{z}]}: Bool.and(U32.is_eq(F32.bits(x), a), Bool.and(U32.is_eq(F32.bits(y), b), U32.is_eq(F32.bits(z), c)))
    case _: False{}

def bands(r: Result<&2, &2, P.Error, List<&2, Maybe<&2, Overlap.Bands<F32>>>>) -> Bool:
  match r:
    case Done{[None{}, Some{Overlap.Bands{h1, m1, l1}}, Some{Overlap.Bands{h2, m2, l2}}, Some{Overlap.Bands{h3, m3, l3}}]}: List.all(~&2, ~Bool, ~(x => x), [U32.is_eq(F32.bits(h1), 0), U32.is_eq(F32.bits(l1), 2147483648), U32.is_eq(F32.bits(h2), 2147483648), U32.is_eq(F32.bits(l2), 0), U32.is_eq(F32.bits(h3), 0), U32.is_eq(F32.bits(l3), 2147483648)])
    case _: False{}

def one(r: Queue.State<F32> & Maybe<&2, Queue.Value<F32>>) -> Bool:
  match r:
    case (state, Some{Queue.Value{low, high, 0, 0, 1}}): Bool.and(F32.is_eq(low, 3.0), F32.is_eq(high, 9.0))
    case _: False{}

def continued(r: TA.MINMAXINDEX.State() & List<&2, Maybe<&2, Stats.MinMaxIndex>>) -> Bool:
  match r:
    case (state, first): indices(Done{List.append(&2, Maybe<&2, Stats.MinMaxIndex>, first, Series.batch(~F32, ~Stats.MinMaxIndex, ~TA.MINMAXINDEX.State(), ~TA.MINMAXINDEX.next, [5.0, 1.0, 5.0, 5.0], state))})

def resumed(r: Result<&2, &1, P.Error, TA.MINMAXINDEX.State()>) -> Bool:
  match r:
    case Fail{e}: False{}
    case Done{state}: continued(Series.scan(~F32, ~Stats.MinMaxIndex, ~TA.MINMAXINDEX.State(), ~TA.MINMAXINDEX.next, [4.0, 2.0, 2.0], state))

def bar(value: F32) -> Bar.HL<F32>:
  +x = value
  Bar.HL{x, x}

def main() -> IO(Unit):
  +values : List<&2, F32> = [0.0, F32.neg(0.0), 0.0, F32.neg(0.0)]
  do IO<Unit>:
    Unit <- Assert.check("MINMAXINDEX.batch case 1", indices(TA.MINMAXINDEX.batch([4.0, 2.0, 2.0, 5.0, 1.0, 5.0, 5.0], 3)))
    Unit <- Assert.check("MINMAXINDEX.batch case 2", burst(TA.MINMAXINDEX.batch([9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 10.0], 7)))
    Unit <- Assert.check("MINMAX.batch", expired(TA.MINMAX.batch([9.0, 1.0, 2.0, 3.0, 4.0], 3)))
    Unit <- Assert.check("MAX.batch", zeros(TA.MAX.batch(values, 2), 2147483648, 0, 2147483648))
    Unit <- Assert.check("MIDPOINT.batch", zeros(TA.MIDPOINT.batch(values, 2), 0, 0, 0))
    Unit <- Assert.check("DONCHIAN.batch", bands(TA.DONCHIAN.batch(Series.map(~F32, ~Bar.HL<F32>, ~bar, values), 2)))
    Unit <- Assert.check("one", one(Queue.next(~F32, ~F32.is_le, ~F32.is_ge, Queue.init(~F32, ~U32.to_f32, 1, 0n), 3.0, 9.0)))
    Assert.check("MINMAXINDEX.init", resumed(TA.MINMAXINDEX.init(3)))
