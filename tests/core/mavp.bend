import Base
import ../../src/f32.bend as TA
import ../../src/core/variable.bend as Variable
import ../../src/core/parameters.bend as P

def samples(periods: List<&2, F32>, +at: U32) -> List<&2, Variable.Sample<F32>>:
  match periods:
    case Nil{}: Nil{}
    case p <> rest: Variable.Sample{U32.to_f32(at), p} <> samples(rest, U32.add(at, 1))

def near(+a: F32, +b: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(a, b)), 0.00001)

def matches(skip: Nat, xs: List<&2, Maybe<&2, F32>>, ys: List<&2, F32>) -> Bool:
  match skip xs ys:
    case 0n Nil{} Nil{}: True{}
    case 0n Some{x} <> rest y <> tail: Bool.and(near(x, y), matches(0n, rest, tail))
    case 1n+rest None{} <> xs ys: matches(rest, xs, ys)
    case _ _ _: False{}

def check(skip: Nat, expected: List<&2, F32>, result: Result<&2, &2, P.Error, List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Done{xs}: matches(skip, xs, expected)
    case Fail{e}: False{}

def main() -> IO(Unit):
  +ordinary = samples([2.0, 2.0, 2.0, 2.0, 2.0, 3.0, 5.0, 2.0], 1)
  do IO<Unit>:
    IO.print(Bool.show(check(4n, [4.5, 5.0, 5.0, 7.5], TA.MAVP.batch(ordinary, 2, 5, 0))))
    IO.print(Bool.show(check(4n, [4.66666667, 5.33333333, 5.66666667, 7.66666667], TA.MAVP.batch(ordinary, 2, 5, 2))))
    IO.print(Bool.show(check(4n, [4.5, 5.0, 5.0, 7.5], TA.MAVP.batch(ordinary, 2, 5, 5))))
    IO.print(Bool.show(check(5n, [5.44444444, 6.13580247, 6.96433471], TA.MAVP.batch(ordinary, 2, 5, 6))))
    IO.print(Bool.show(check(5n, [6.66666667, 7.33333333, 8.33333333], TA.MAVP.batch(ordinary, 2, 5, 9))))
    IO.print(Bool.show(check(6n, [7.0, 7.5], TA.MAVP.batch(ordinary, 2, 5, 12))))
    IO.print(Bool.show(check(4n, [4.55555556, 5.125, 5.17558299, 7.50205761], TA.MAVP.batch(ordinary, 2, 5, 14))))
    IO.print(Bool.show(check(11n, [12.0, 12.0109869, 13.0], TA.MAVP.batch(samples([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.0, 2.0, 3.0], 1), 1, 12, 15))))

#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
