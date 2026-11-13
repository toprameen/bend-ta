import Base
import ../../scripts/assert.bend as Assert
import ../../src/core/statistics.bend as Stats
import ../../src/core/rolling_average.bend as Average
import ../../src/core/series.bend as Series
import ../../src/core/config.bend as Config

def next(state: Average.State<F32>, price: F32) -> Average.State<F32> & Maybe<&2, Stats.Regression<F32>>:
  Stats.regress.cached(~F32, ~U32.to_f32, ~F32.add, ~F32.sub, ~F32.mul, ~F32.div, ~F32.abs, ~F32.is_le, state, price)

def price(kind: U32, +index: U32, period: U32) -> F32:
  match kind:
    case 0: F32.div(U32.to_f32(index), 8.0)
    case 1: 64.0
    case 2: Bool.pick(F32, U32.is_eq(index, U32.add(period, 3)), 1.0e20, 1.0)
    case 4: Bool.pick(F32, U32.is_lt(index, 129), F32.add(1000.0, F32.div(U32.to_f32(U32.mod(index, 13)), 100.0)), 0.1)
    case _: Bool.pick(F32, U32.is_eq(index, period), 1.0e20, F32.add(1.0, F32.div(U32.to_f32(U32.mod(index, 7)), 8.0)))

def samples(fuel: Nat, +kind: U32, +index: U32, +period: U32, acc: List<&2, F32>) -> List<&2, F32>:
  match fuel:
    case 0n: List.reverse(&2, F32, acc)
    case 1n+rest: samples(rest, kind, U32.add(index, 1), period, price(kind, index, period) <> acc)

def ramp(xs: List<&2, Maybe<&2, Stats.Regression<F32>>>, +index: U32) -> Bool:
  match xs:
    case Nil{}: True{}
    case None{} <> rest: Bool.and(U32.is_lt(index, 6), ramp(rest, U32.add(index, 1)))
    case Some{Stats.Regression{a, b, c, d}} <> rest: Bool.and(Bool.and(U32.is_ge(index, 6), Bool.and(F32.is_eq(a, F32.div(U32.to_f32(U32.sub(index, 6)), 8.0)), F32.is_eq(b, 0.125))), Bool.and(Bool.and(F32.is_eq(c, F32.div(U32.to_f32(index), 8.0)), F32.is_eq(d, F32.div(U32.to_f32(U32.add(index, 1)), 8.0))), ramp(rest, U32.add(index, 1))))

def ramp.result(result: Average.State<F32> & List<&2, Maybe<&2, Stats.Regression<F32>>>) -> Bool:
  match result:
    case (state, xs): ramp(xs, 0)

def last(xs: List<&2, Maybe<&2, Stats.Regression<F32>>>) -> Maybe<&2, Stats.Regression<F32>>:
  match xs:
    case Nil{}: None{}
    case x <> Nil{}: x
    case x <> rest: last(rest)

def flat.value(+expected: F32, value: Maybe<&2, Stats.Regression<F32>>) -> Bool:
  match value:
    case None{}: False{}
    case Some{Stats.Regression{a, b, c, d}}: Bool.and(Bool.and(F32.is_eq(a, expected), F32.is_eq(b, 0.0)), Bool.and(F32.is_eq(c, expected), F32.is_eq(d, expected)))

def flat(expected: F32, result: Average.State<F32> & List<&2, Maybe<&2, Stats.Regression<F32>>>) -> Bool:
  match result:
    case (state, xs): flat.value(expected, last(xs))

def cancellation.value(value: Maybe<&2, Stats.Regression<F32>>) -> Bool:
  match value:
    case None{}: False{}
    case Some{Stats.Regression{a, b, c, d}}: U32.is_zero(F32.bits(d))

def cancellation(result: Average.State<F32> & List<&2, Maybe<&2, Stats.Regression<F32>>>) -> Bool:
  match result:
    case (state, xs): cancellation.value(last(xs))

def run(count: Nat, kind: U32, +period: U32) -> Average.State<F32> & List<&2, Maybe<&2, Stats.Regression<F32>>>:
  Series.scan(~F32, ~Stats.Regression<F32>, ~Average.State<F32>, ~next, samples(count, kind, 0, period, Nil{}), Stats.regress.init(~F32, ~U32.to_f32, period, Config.depth(period)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("ramp.result", ramp.result(run(32n, 0, 7)))
    Unit <- Assert.check("flat case 1", flat(64.0, run(40n, 1, 17)))
    Unit <- Assert.check("flat case 2", flat(1.0, run(38n, 2, 17)))
    Unit <- Assert.check("cancellation", cancellation(run(27n, 3, 16)))
    Assert.check("flat case 3", flat(0.1, run(385n, 4, 256)))
