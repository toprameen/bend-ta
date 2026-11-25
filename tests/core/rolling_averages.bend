import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/series.bend as Series
import ../../src/core/parameters.bend as P

def samples(fuel: Nat, +index: U32, +period: U32, acc: List<&2, F32>) -> List<&2, F32>:
  match fuel:
    case 0n: List.reverse(&2, F32, acc)
    case 1n+rest: samples(rest, U32.add(index, 1), period, Bool.pick(F32, U32.is_eq(index, U32.add(period, 3)), 1.0e20, 1.0) <> acc)

def last(xs: List<&2, Maybe<&2, F32>>) -> Maybe<&2, F32>:
  match xs:
    case Nil{}: None{}
    case x <> Nil{}: x
    case x <> rest: last(rest)

def one.value(expected: F32, value: Maybe<&2, F32>) -> Bool:
  match value:
    case None{}: False{}
    case Some{x}: F32.is_eq(x, expected)

def one(expected: F32, result: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: one.value(expected, last(xs))

def expired(+period: U32, kind: U32) -> Bool:
  one(1.0, TA.MA.batch(samples(U32.to_nat(U32.add(U32.mul(2, period), 4)), 0, period, Nil{}), period, kind))

def block.samples(fuel: Nat, +index: U32, acc: List<&2, F32>) -> List<&2, F32>:
  match fuel:
    case 0n: List.reverse(&2, F32, acc)
    case 1n+rest: block.samples(rest, U32.add(index, 1), Bool.pick(F32, U32.is_lt(index, 129), F32.add(1000.0, F32.div(U32.to_f32(U32.mod(index, 13)), 100.0)), 0.1) <> acc)

def block(kind: U32) -> Bool:
  one(0.1, TA.MA.batch(block.samples(385n, 0, Nil{}), 256, kind))

def provisional(result: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Done{[None{}, None{}, None{}, None{}, None{}, Some{a}, Some{b}, Some{x}]}: U32.is_zero(F32.bits(x))
    case _: False{}

def continued(previous: Maybe<&2, F32>, result: TA.MA.State() & Maybe<&2, F32>) -> Bool:
  match previous result:
    case Some{+before} Tuple{state, Some{after}}:
      +fast = F32.div(2.0, 3.0)
      U32.is_eq(F32.bits(after), F32.bits(F32.add(before, F32.mul(F32.mul(fast, fast), F32.sub(1.0, before)))))
    case _ _: False{}

def streamed(result: TA.MA.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case (state, xs): continued(last(xs), TA.MA.next(state, 1.0))

def adaptive(result: Result<&2, &1, P.Error, TA.MA.State()>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{state}: streamed(Series.scan(~F32, ~F32, ~TA.MA.State(), ~TA.MA.next, samples(39n, 0, 17, Nil{}), state))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("expired case 1", expired(17, 0))
    Unit <- Assert.check("expired case 2", expired(17, 2))
    Unit <- Assert.check("expired case 3", expired(17, 5))
    Unit <- Assert.check("expired case 4", expired(16, 5))
    Unit <- Assert.check("HMA.batch", provisional(TA.HMA.batch([1.0, 1.125, 1.25, 1.375, 1.5, 1.0e20, 1.75, 1.0], 5)))
    Unit <- Assert.check("MA.init", adaptive(TA.MA.init(17, 6)))
    Unit <- Assert.check("block case 1", block(0))
    Unit <- Assert.check("block case 2", block(2))
    Assert.check("block case 3", block(5))
