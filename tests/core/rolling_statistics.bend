import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/moments.bend as Moments
import ../../src/core/statistics_window.bend as Pair
import ../../src/core/window.bend as Window
import ../../src/core/config.bend as Config
import ../../src/core/parameters.bend as Params
import ../../src/core/series.bend as Series
import ../reference/statistics_moments.bend as Ref

def price(kind: U32, +at: U32) -> F32:
  match kind:
    case 0: F32.add(64.0, F32.div(U32.to_f32(U32.mod(U32.mul(at, 37), 97)), 16.0))
    case 1: F32.add(1000000.0, F32.div(U32.to_f32(U32.mod(at, 13)), 16.0))
    case 2: Bool.pick(F32, U32.is_lt(at, 129), F32.add(1000.0, F32.div(U32.to_f32(U32.mod(at, 13)), 100.0)), 0.1)
    case _: Bool.pick(F32, U32.is_eq(at, 35), F32.div(0.0, 0.0), U32.to_f32(U32.mod(at, 13)))

def inputs(fuel: Nat, +kind: U32, +at: U32, acc: List<&2, F32>) -> List<&2, F32>:
  match fuel:
    case 0n: List.reverse(&2, F32, acc)
    case 1n+rest: inputs(rest, kind, U32.add(at, 1), price(kind, at) <> acc)

def variance(value: Maybe<&2, Moments.Value<F32>>) -> Maybe<&2, F32>:
  match value:
    case None{}: None{}
    case Some{Moments.Moments{mean, variance}}: Some{variance}

def scalar(+kind: U32, +period: U32, +count: Nat) -> Bool:
  Ref.result(TA.VAR.batch(inputs(count, kind, 0, Nil{}), period, 1.0), Series.map(~Maybe<&2, Moments.Value<F32>>, ~Maybe<&2, F32>, ~variance, Series.batch(~F32, ~Moments.Value<F32>, ~TA.Window.State(), ~TA.Moments.next, inputs(count, kind, 0, Nil{}), Window.init(~F32, period, Config.depth(period), 0.0))))

def pair(value: F32) -> Pair.PairValue<F32>:
  +value = value
  Pair.PairValue{value, F32.mul(value, value)}

def fresh(state: Window.State<Pair.PairValue<F32>>, value: Pair.PairValue<F32>) -> Window.State<Pair.PairValue<F32>> & Maybe<&2, F32>:
  Pair.pair.project(~F32, ~(v => Pair.correl.ratio(~F32, ~U32.to_f32, ~F32.sub, ~F32.mul, ~F32.div, ~F32.sqrt, ~F32.min, ~F32.max, ~F32.is_gt, v)), Pair.pair.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, state, value))

def paired(+kind: U32, +period: U32, +count: Nat) -> Bool:
  Ref.result(TA.CORREL.batch(Series.map(~F32, ~Pair.PairValue<F32>, ~pair, inputs(count, kind, 0, Nil{})), period), Series.batch(~Pair.PairValue<F32>, ~F32, ~Window.State<Pair.PairValue<F32>>, ~fresh, Series.map(~F32, ~Pair.PairValue<F32>, ~pair, inputs(count, kind, 0, Nil{})), Pair.pair.init(~F32, ~U32.to_f32, period, Config.depth(period))))

def zero(value: Maybe<&2, F32>) -> Bool:
  match value:
    case Some{x}: F32.is_eq(x, 0.0)
    case None{}: False{}

def tail(xs: List<&2, Maybe<&2, F32>>, skip: Nat) -> Bool:
  match xs skip:
    case Nil{} _: True{}
    case x <> rest 0n: Bool.and(zero(x), tail(rest, 0n))
    case x <> rest 1n+n: tail(rest, n)

def recovered(skip: Nat, result: Result<&2, &2, Params.Error, List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: tail(xs, skip)

def fork.previewed(~I: Data, ~S: Type, ~next: S -> I -> S & Maybe<&2, F32>, +suffix: List<&2, I>, +expected: List<&2, Maybe<&2, F32>>, prediction: F32, result: S & Maybe<&2, F32>, other: List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case (state, value):
      Bool.and(Assert.maybe(~F32, ~(a => b => Ref.near(a, b)), value, Some{prediction}),
        Bool.and(Ref.same(Series.batch(~I, ~F32, ~S, ~next, suffix, state), expected), Ref.same(other, expected)))

def fork.copied(~I: Data, ~S: Type, ~next: S -> I -> S & Maybe<&2, F32>, ~preview: S -> I -> S & Maybe<&2, F32>, +suffix: List<&2, I>, +expected: List<&2, Maybe<&2, F32>>, probe: I, prediction: F32, result: S & S) -> Bool:
  match result:
    case (a, b): fork.previewed(~I, ~S, ~next, suffix, expected, prediction, preview(a, probe), Series.batch(~I, ~F32, ~S, ~next, suffix, b))

def fork.scanned(~I: Data, ~S: Type, ~next: S -> I -> S & Maybe<&2, F32>, ~clone: S -> S & S, ~preview: S -> I -> S & Maybe<&2, F32>, suffix: List<&2, I>, expected: List<&2, Maybe<&2, F32>>, probe: I, prediction: F32, result: S & List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case (state, values): fork.copied(~I, ~S, ~next, ~preview, suffix, expected, probe, prediction, clone(state))

def fork(~I: Data, ~S: Type, ~next: S -> I -> S & Maybe<&2, F32>, ~clone: S -> S & S, ~preview: S -> I -> S & Maybe<&2, F32>, prefix: List<&2, I>, suffix: List<&2, I>, expected: List<&2, Maybe<&2, F32>>, probe: I, prediction: F32, result: Result<&2, &1, Params.Error, S>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{state}: fork.scanned(~I, ~S, ~next, ~clone, ~preview, suffix, expected, probe, prediction, Series.scan(~I, ~F32, ~S, ~next, prefix, state))

def cached(state: Moments.Cached<F32>, value: F32) -> Moments.Cached<F32> & Maybe<&2, Moments.Value<F32>>:
  Moments.cached.next(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, value)

def mean.zero(xs: List<&2, Maybe<&2, Moments.Value<F32>>>) -> Bool:
  match xs:
    case Some{Moments.Moments{mean, variance}} <> Nil{}: F32.is_eq(mean, 0.0)
    case x <> rest: mean.zero(rest)
    case Nil{}: False{}

def aligned(value: F32) -> Pair.PairValue<F32>:
  +value = value
  Pair.PairValue{value, value}

def ranged(+scale: F32, +order: U32) -> Bool:
  +three = F32.mul(3.0, scale)
  +xs = Bool.pick(List<&2, F32>, U32.is_eq(order, 0), [0.0,scale,three], Bool.pick(List<&2, F32>, U32.is_eq(order, 1), [three,scale,0.0], [0.0,three,scale]))
  +values = Series.map(~F32, ~Pair.PairValue<F32>, ~aligned, List.append(&2, F32, xs, [scale,three]))
  Ref.result(TA.CORREL.batch(values, 3), Series.batch(~Pair.PairValue<F32>, ~F32, ~Window.State<Pair.PairValue<F32>>, ~fresh, values, Pair.pair.init(~F32, ~U32.to_f32, 3, 2n)))

def ranges(xs: List<&2, F32>) -> Bool:
  match xs:
    case Nil{}: True{}
    case +x <> rest: Bool.and(Bool.and(ranged(x, 0), Bool.and(ranged(x, 1), ranged(x, 2))), ranges(rest))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("scalar case 1", Bool.and(scalar(0, 17, 128n), paired(0, 17, 128n)))
    Unit <- Assert.check("scalar case 2", Bool.and(scalar(1, 17, 128n), paired(1, 17, 128n)))
    Unit <- Assert.check("scalar case 3", Bool.and(scalar(3, 17, 128n), paired(3, 17, 128n)))
    Unit <- Assert.check("scalar case 4", Bool.and(scalar(2, 256, 400n), paired(2, 256, 400n)))
    Unit <- Assert.check("VAR.batch case 1", recovered(384n, TA.VAR.batch(inputs(400n, 2, 0, Nil{}), 256, 1.0)))
    Unit <- Assert.check("CORREL.batch case 1", recovered(384n, TA.CORREL.batch(Series.map(~F32, ~Pair.PairValue<F32>, ~pair, inputs(400n, 2, 0, Nil{})), 256)))
    Unit <- Assert.check("VAR.batch case 2", recovered(2n, TA.VAR.batch([F32.neg(3.0e-23), F32.neg(2.0e-23), F32.neg(1.0e-23), 0.0, 1.0e-23, 2.0e-23, 3.0e-23, F32.neg(3.0e-23)], 3, 1.0)))
    Unit <- Assert.check("VAR clone and preview", fork(~F32, ~TA.VAR.State(), ~TA.VAR.next, ~TA.VAR.clone, ~TA.VAR.preview,
      [1.0, 2.0, 3.0], [4.0, 5.0], [Some{F32.div(2.0, 3.0)}, Some{F32.div(2.0, 3.0)}], 100.0, F32.div(6338.0, 3.0), TA.VAR.init(3, 1.0)))
    Unit <- Assert.check("CORREL clone and preview", fork(~TA.PairValue(), ~TA.CORREL.State(), ~TA.CORREL.next, ~TA.CORREL.clone, ~TA.CORREL.preview,
      [Pair.PairValue{1.0, 1.0}, Pair.PairValue{2.0, 2.0}, Pair.PairValue{3.0, 9.0}], [Pair.PairValue{4.0, 4.0}, Pair.PairValue{5.0, 5.0}],
      [Some{0.277350098}, Some{F32.neg(0.755928946)}], Pair.PairValue{100.0, 0.0}, F32.neg(0.665327344), TA.CORREL.init(3)))
    Unit <- Assert.check("mean.zero", mean.zero(Series.batch(~F32, ~Moments.Value<F32>, ~Moments.Cached<F32>, ~cached, [F32.neg(2.0e18), F32.neg(1.0e18), 0.0, 1.0e18], Moments.cached.init(~F32, ~U32.to_f32, 3, 2n))))
    Unit <- Assert.check("CORREL.batch case 2", recovered(2n, TA.CORREL.batch([Pair.PairValue{F32.neg(1.0e-9),1.0e9},Pair.PairValue{0.0,0.0},Pair.PairValue{1.0e-9,1.0e9}], 3)))
    Unit <- Assert.check("BETA.batch", recovered(3n, TA.BETA.batch([Pair.PairValue{11868269.0,1.0},Pair.PairValue{11868268.0,1.0e9},Pair.PairValue{11868268.0,1.0e9},Pair.PairValue{11868269.0,1.0e18}], 3)))
    Assert.check("ranges", ranges([1988183552.0,1988183296.0,2.3816159547968008e-12,2.3816161716372353e-12]))
