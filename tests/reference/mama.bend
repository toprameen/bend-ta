import Base
import ../../src/f32.bend as TA
import ../../src/core/mama.bend as Mama
import ../../src/core/series.bend as Series

type Target is Data:
  Target{index: Nat, mama: F32, fama: F32}

def at(index: Nat, xs: List<&2, Maybe<&2, TA.MAMA.Value()>>) -> Maybe<&2, TA.MAMA.Value()>:
  match index xs:
    case 0n h <> t: h
    case 1n+rest h <> t: at(rest, t)
    case _ Nil{}: None{}

def ready(xs: List<&2, Maybe<&2, TA.MAMA.Value()>>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Some{v} <> t: ready(t)
    case None{} <> t: False{}

def aligned(count: Nat, xs: List<&2, Maybe<&2, TA.MAMA.Value()>>) -> Bool:
  match count xs:
    case 0n xs: ready(xs)
    case 1n+rest None{} <> t: aligned(rest, t)
    case _ _: False{}

def close(+expected: F32, actual: F32, tolerance: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(actual, expected)), tolerance)

def target(expected_mama: F32, expected_fama: F32, +tolerance: F32, value: Maybe<&2, TA.MAMA.Value()>) -> Bool:
  match value:
    case None{}: False{}
    case Some{Mama.Value{mama, fama}}: Bool.and(close(expected_mama, mama, tolerance), close(expected_fama, fama, tolerance))

def targets(+xs: List<&2, Maybe<&2, TA.MAMA.Value()>>, expected: List<&2, Target>, +tolerance: F32) -> Bool:
  match expected:
    case Nil{}: True{}
    case Target{index, mama, fama} <> t:
      Bool.and(target(mama, fama, tolerance, at(index, xs)), targets(xs, t, tolerance))

def check(expected: List<&2, Target>, tolerance: F32, result: Result<&2, &2, TA.MAMA.Error(), List<&2, Maybe<&2, TA.MAMA.Value()>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{+xs}: Bool.and(aligned(32n, xs), targets(xs, expected, tolerance))

def oscillator(index: U32) -> F32:
  match index:
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
    case other: 12.0

def samples(~price: U32 -> F32, count: Nat, +index: U32) -> List<&2, F32>:
  match count:
    case 0n: Nil{}
    case 1n+rest: price(index) <> samples(~price, rest, U32.add(index, 1))

def constant(index: U32) -> F32:
  5.0

def negative(index: U32) -> F32:
  F32.sub(F32.div(U32.to_f32(index), 4.0), 20.0)

def cycle(index: U32) -> F32:
  oscillator(U32.mod(index, 12))

def shifted(index: U32) -> F32:
  F32.add(10000.0, cycle(index))

def continued(tail: List<&2, F32>, result: TA.MAMA.State() & List<&2, Maybe<&2, TA.MAMA.Value()>>) -> List<&2, Maybe<&2, TA.MAMA.Value()>>:
  match result:
    case (state, prefix): List.append(&2, Maybe<&2, TA.MAMA.Value()>, prefix, Series.batch(~F32, ~TA.MAMA.Value(), ~TA.MAMA.State(), ~TA.MAMA.next, tail, state))

def chunked(result: Result<&2, &1, TA.MAMA.Error(), TA.MAMA.State()>) -> Result<&2, &2, TA.MAMA.Error(), List<&2, Maybe<&2, TA.MAMA.Value()>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{continued(samples(~negative, 160n, 20), Series.scan(~F32, ~TA.MAMA.Value(), ~TA.MAMA.State(), ~TA.MAMA.next, samples(~negative, 20n, 0), state))}

def valid(result: Result<&2, &2, TA.MAMA.Error(), List<&2, Maybe<&2, TA.MAMA.Value()>>>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{xs}: "valid"

def expected.constant() -> List<&2, Target>:
  [Target{32n, 4.999983646869698, 4.960701874098815}, Target{33n, 4.999991823434849, 4.970524361432823}, Target{47n, 4.999999999500942, 4.999474732009067}, Target{80n, 5.0, 4.999999960426649}, Target{100n, 5.0, 4.999999999874504}, Target{142n, 5.0, 4.999999999999998}, Target{179n, 5.0, 4.999999999999998}]

def expected.negative() -> List<&2, Target>:
  [Target{32n, F32.neg(12.25137259488542), F32.neg(12.860451628410868)}, Target{33n, F32.neg(12.00068629744271), F32.neg(12.645510295668828)}, Target{47n, F32.neg(9.301323388071067), F32.neg(10.136510037735471)}, Target{80n, F32.neg(0.25000000804356093), F32.neg(1.0006333028349927)}, Target{100n, 4.749999999999993, 3.9999979916497392}, Target{142n, 15.25, 14.499999999988638}, Target{179n, 24.5, 23.749999999999993}]

def expected.cycle() -> List<&2, Target>:
  [Target{32n, 8.073985173980136, 9.412886411846252}, Target{33n, 9.536992586990067, 9.443912955632205}, Target{47n, 9.789446658942595, 9.421565711898735}, Target{80n, 7.992630630881862, 9.348558484518687}, Target{100n, 11.956256579442078, 10.152017878366138}, Target{142n, 9.671499438056724, 9.392290100488411}, Target{179n, 9.787924467888743, 9.402180564563087}]

def expected.shifted() -> List<&2, Target>:
  [Target{32n, 10006.459769049921, 9616.11497582162}, Target{33n, 10008.72988452496, 9714.268702997455}, Target{47n, 10009.759243821012, 9936.81790401962}, Target{80n, 10007.992625859577, 10007.591304231071}, Target{100n, 10011.956256543084, 10009.932602322187}, Target{142n, 10009.671499438056, 10009.390809932444}, Target{179n, 10009.787924467888, 10009.402155666729}]

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(check(expected.constant(), 0.000005, TA.MAMA.batch(samples(~constant, 180n, 0), 0.5, 0.05))))
    IO.print(Bool.show(check(expected.negative(), 0.00002, TA.MAMA.batch(samples(~negative, 180n, 0), 0.5, 0.05))))
    IO.print(Bool.show(check(expected.cycle(), 0.00002, TA.MAMA.batch(samples(~cycle, 180n, 0), 0.5, 0.05))))
    IO.print(Bool.show(check(expected.shifted(), 0.01, TA.MAMA.batch(samples(~shifted, 180n, 0), 0.5, 0.05))))
    IO.print(Bool.show(check(expected.negative(), 0.00002, chunked(TA.MAMA.init(0.5, 0.05)))))
    IO.print(valid(TA.MAMA.batch([], 0.5, 0.05)))
    IO.print(valid(TA.MAMA.batch([], 0.0, 0.05)))
    IO.print(valid(TA.MAMA.batch([], 0.5, F32.div(0.0, 0.0))))

#|True
#|True
#|True
#|True
#|True
#|valid
#|invalid
#|invalid
