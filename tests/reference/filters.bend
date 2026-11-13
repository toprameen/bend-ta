import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/series.bend as Series
import ../../src/core/parameters.bend as Params

type Target<-O: Data> is Data:
  Target{index: Nat, value: O}

def cycle(at: U32) -> F32:
  match at:
    case 0: 10.0
    case 1: 12.0
    case 2: 14.0
    case 3: 13.0
    case 4: 11.0
    case 5: 8.0
    case 6: 6.0
    case 7: 7.0
    case 8: 9.0
    case 9: 11.0
    case 10: 13.0
    case _: 12.0

def samples(count: Nat, +index: U32) -> List<&2, F32>:
  match count:
    case 0n: []
    case 1n+rest: cycle(U32.mod(index, 12)) <> samples(rest, U32.add(index, 1))

def at(~O: Data, index: Nat, xs: List<&2, Maybe<&2, O>>) -> Maybe<&2, O>:
  match index xs:
    case 0n h <> t: h
    case 1n+rest h <> t: at(~O, rest, t)
    case _ Nil{}: None{}

def aligned(~O: Data, count: Nat, xs: List<&2, Maybe<&2, O>>) -> Bool:
  match count xs:
    case _ Nil{}: True{}
    case 0n Some{v} <> t: aligned(~O, 0n, t)
    case 1n+rest None{} <> t: aligned(~O, rest, t)
    case _ _: False{}

def near(a: F32, b: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(a, b)), 0.0002)

def target(~O: Data, ~equal: O -> O -> Bool, expected: O, actual: Maybe<&2, O>) -> Bool:
  match actual:
    case None{}: False{}
    case Some{v}: equal(expected, v)

def targets(~O: Data, ~equal: O -> O -> Bool, +xs: List<&2, Maybe<&2, O>>, expected: List<&2, Target<O>>) -> Bool:
  match expected:
    case Nil{}: True{}
    case Target{index, value} <> rest: Bool.and(target(~O, ~equal, value, at(~O, index, xs)), targets(~O, ~equal, xs, rest))

def check(~O: Data, ~equal: O -> O -> Bool, warmup: Nat, expected: List<&2, Target<O>>, result: Result<&2, &2, Params.Error, List<&2, Maybe<&2, O>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{+xs}: Bool.and(aligned(~O, warmup, xs), targets(~O, ~equal, xs, expected))

def continued(~O: Data, ~S: Type, ~step: S -> F32 -> S & Maybe<&2, O>, result: S & List<&2, Maybe<&2, O>>) -> List<&2, Maybe<&2, O>>:
  match result:
    case (state, prefix): List.append(&2, Maybe<&2, O>, prefix, Series.batch(~F32, ~O, ~S, ~step, samples(160n, 20), state))

def chunked(~O: Data, ~S: Type, ~step: S -> F32 -> S & Maybe<&2, O>, result: Result<&2, &1, Params.Error, S>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, O>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{continued(~O, ~S, ~step, Series.scan(~F32, ~O, ~S, ~step, samples(20n, 0), state))}

def valid(~S: Type, result: Result<&2, &1, Params.Error, S>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{s}: True{}

def expected.SWAK_BUTTER() -> List<&2, Target<F32>>:
  [Target{0n, 10.0}, Target{1n, 10.073026674088684}, Target{2n, 10.382342943604534}, Target{30n, 11.222966797681181}, Target{179n, 9.79681418146415}]

def expected.SWAK_GAUSS() -> List<&2, Target<F32>>:
  [Target{0n, 10.0}, Target{1n, 10.292106696354736}, Target{2n, 10.945158381708668}, Target{30n, 10.345984040436866}, Target{179n, 10.359877797635816}]

def expected.SWAK_2PHP() -> List<&2, Target<F32>>:
  [Target{0n, 0.0}, Target{1n, 1.3086881412974403}, Target{2n, 1.6170955087942955}, Target{30n, F32.neg(1.9776072886735103)}, Target{179n, F32.neg(0.2362233873291897)}]

def expected.SWAK_BP() -> List<&2, Target<F32>>:
  [Target{0n, 0.0}, Target{1n, 0.0609374941825076}, Target{2n, 0.2342533576910025}, Target{30n, 0.049278673379271644}, Target{179n, F32.neg(0.1648316015362304)}]

def expected.SWAK_HP() -> List<&2, Target<F32>>:
  [Target{0n, 0.0}, Target{1n, 1.7265425280053608}, Target{2n, 2.980949101011142}, Target{30n, F32.neg(4.127533655699895)}, Target{179n, 1.3696082705775396}]

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("SWAK_BUTTER.batch case 1", check(~F32, ~near, 0n, expected.SWAK_BUTTER(), TA.SWAK_BUTTER.batch(samples(180n, 0), 20)))
    Unit <- Assert.check("SWAK_BUTTER.next", check(~F32, ~near, 0n, expected.SWAK_BUTTER(), chunked(~F32, ~TA.SWAK_BUTTER.State(), ~TA.SWAK_BUTTER.next, TA.SWAK_BUTTER.init(20))))
    Unit <- Assert.check("SWAK_BUTTER.batch case 2", check(~F32, ~near, 0n, [Target{0n, 5.0}], TA.SWAK_BUTTER.batch([5.0], 20)))
    Unit <- Assert.check("SWAK_BUTTER.batch case 3", check(~F32, ~near, 0n, [], TA.SWAK_BUTTER.batch([], 20)))
    Unit <- Assert.check("SWAK_BUTTER.init case 1", valid(~TA.SWAK_BUTTER.State(), TA.SWAK_BUTTER.init(2)))
    Unit <- Assert.check("SWAK_BUTTER.init case 2", valid(~TA.SWAK_BUTTER.State(), TA.SWAK_BUTTER.init(10000)))
    Unit <- Assert.check("SWAK_BUTTER.init case 3", Bool.not(valid(~TA.SWAK_BUTTER.State(), TA.SWAK_BUTTER.init(1))))
    Unit <- Assert.check("SWAK_BUTTER.init case 4", Bool.not(valid(~TA.SWAK_BUTTER.State(), TA.SWAK_BUTTER.init(10001))))
    Unit <- Assert.check("SWAK_GAUSS.batch case 1", check(~F32, ~near, 0n, expected.SWAK_GAUSS(), TA.SWAK_GAUSS.batch(samples(180n, 0), 20)))
    Unit <- Assert.check("SWAK_GAUSS.next", check(~F32, ~near, 0n, expected.SWAK_GAUSS(), chunked(~F32, ~TA.SWAK_GAUSS.State(), ~TA.SWAK_GAUSS.next, TA.SWAK_GAUSS.init(20))))
    Unit <- Assert.check("SWAK_GAUSS.batch case 2", check(~F32, ~near, 0n, [Target{0n, 5.0}], TA.SWAK_GAUSS.batch([5.0], 20)))
    Unit <- Assert.check("SWAK_GAUSS.batch case 3", check(~F32, ~near, 0n, [], TA.SWAK_GAUSS.batch([], 20)))
    Unit <- Assert.check("SWAK_GAUSS.init case 1", valid(~TA.SWAK_GAUSS.State(), TA.SWAK_GAUSS.init(2)))
    Unit <- Assert.check("SWAK_GAUSS.init case 2", valid(~TA.SWAK_GAUSS.State(), TA.SWAK_GAUSS.init(10000)))
    Unit <- Assert.check("SWAK_GAUSS.init case 3", Bool.not(valid(~TA.SWAK_GAUSS.State(), TA.SWAK_GAUSS.init(1))))
    Unit <- Assert.check("SWAK_GAUSS.init case 4", Bool.not(valid(~TA.SWAK_GAUSS.State(), TA.SWAK_GAUSS.init(10001))))
    Unit <- Assert.check("SWAK_2PHP.batch case 1", check(~F32, ~near, 0n, expected.SWAK_2PHP(), TA.SWAK_2PHP.batch(samples(180n, 0), 20)))
    Unit <- Assert.check("SWAK_2PHP.next", check(~F32, ~near, 0n, expected.SWAK_2PHP(), chunked(~F32, ~TA.SWAK_2PHP.State(), ~TA.SWAK_2PHP.next, TA.SWAK_2PHP.init(20))))
    Unit <- Assert.check("SWAK_2PHP.batch case 2", check(~F32, ~near, 0n, [Target{0n, 0.0}], TA.SWAK_2PHP.batch([5.0], 20)))
    Unit <- Assert.check("SWAK_2PHP.batch case 3", check(~F32, ~near, 0n, [], TA.SWAK_2PHP.batch([], 20)))
    Unit <- Assert.check("SWAK_2PHP.init case 1", valid(~TA.SWAK_2PHP.State(), TA.SWAK_2PHP.init(2)))
    Unit <- Assert.check("SWAK_2PHP.init case 2", valid(~TA.SWAK_2PHP.State(), TA.SWAK_2PHP.init(10000)))
    Unit <- Assert.check("SWAK_2PHP.init case 3", Bool.not(valid(~TA.SWAK_2PHP.State(), TA.SWAK_2PHP.init(1))))
    Unit <- Assert.check("SWAK_2PHP.init case 4", Bool.not(valid(~TA.SWAK_2PHP.State(), TA.SWAK_2PHP.init(10001))))
    Unit <- Assert.check("SWAK_BP.batch case 1", check(~F32, ~near, 0n, expected.SWAK_BP(), TA.SWAK_BP.batch(samples(180n, 0), 20, 0.1)))
    Unit <- Assert.check("SWAK_BP.next", check(~F32, ~near, 0n, expected.SWAK_BP(), chunked(~F32, ~TA.SWAK_BP.State(), ~TA.SWAK_BP.next, TA.SWAK_BP.init(20, 0.1))))
    Unit <- Assert.check("SWAK_BP.batch case 2", check(~F32, ~near, 0n, [Target{0n, 0.0}], TA.SWAK_BP.batch([5.0], 20, 0.1)))
    Unit <- Assert.check("SWAK_BP.batch case 3", check(~F32, ~near, 0n, [], TA.SWAK_BP.batch([], 20, 0.1)))
    Unit <- Assert.check("SWAK_BP.init case 1", valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(5, 0.05)))
    Unit <- Assert.check("SWAK_BP.init case 2", valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(2000, 0.05)))
    Unit <- Assert.check("SWAK_BP.init case 3", Bool.not(valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(4, 0.5))))
    Unit <- Assert.check("SWAK_BP.init case 4", Bool.not(valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(2001, 0.5))))
    Unit <- Assert.check("SWAK_HP.batch case 1", check(~F32, ~near, 0n, expected.SWAK_HP(), TA.SWAK_HP.batch(samples(180n, 0), 20)))
    Unit <- Assert.check("SWAK_HP.next", check(~F32, ~near, 0n, expected.SWAK_HP(), chunked(~F32, ~TA.SWAK_HP.State(), ~TA.SWAK_HP.next, TA.SWAK_HP.init(20))))
    Unit <- Assert.check("SWAK_HP.batch case 2", check(~F32, ~near, 0n, [Target{0n, 0.0}], TA.SWAK_HP.batch([5.0], 20)))
    Unit <- Assert.check("SWAK_HP.batch case 3", check(~F32, ~near, 0n, [], TA.SWAK_HP.batch([], 20)))
    Unit <- Assert.check("SWAK_HP.init case 1", valid(~TA.SWAK_HP.State(), TA.SWAK_HP.init(5)))
    Unit <- Assert.check("SWAK_HP.init case 2", valid(~TA.SWAK_HP.State(), TA.SWAK_HP.init(100000)))
    Unit <- Assert.check("SWAK_HP.init case 3", Bool.not(valid(~TA.SWAK_HP.State(), TA.SWAK_HP.init(4))))
    Unit <- Assert.check("SWAK_HP.init case 4", Bool.not(valid(~TA.SWAK_HP.State(), TA.SWAK_HP.init(100001))))
    Unit <- Assert.check("SWAK_BP.init case 5", Bool.not(valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(20, 0.0))))
    Unit <- Assert.check("SWAK_BP.init case 6", Bool.not(valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(20, 0.51))))
    Unit <- Assert.check("SWAK_BP.init case 7", Bool.not(valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(20, F32.div(0.0, 0.0)))))
    Assert.check("SWAK_BP.init case 8", Bool.not(valid(~TA.SWAK_BP.State(), TA.SWAK_BP.init(20, F32.div(1.0, 0.0)))))
