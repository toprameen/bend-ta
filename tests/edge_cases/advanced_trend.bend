import Base
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/momentum_smooth.bend as Smooth

def same(xs: List<&2, Maybe<&2, F32>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case None{} <> rest None{} <> tail: same(rest, tail)
    case Some{x} <> rest Some{y} <> tail: Bool.and(F32.is_eq(x, y), same(rest, tail))
    case _ _: False{}

def scalar(result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, F32>>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: same(xs, expected)

def bars() -> List<&2, Bar.HL<F32>>:
  [Bar.HL{10.0, 8.0}, Bar.HL{11.0, 9.0}, Bar.HL{12.0, 10.0}, Bar.HL{10.0, 8.0}, Bar.HL{9.0, 7.0}, Bar.HL{11.0, 9.0}, Bar.HL{12.0, 10.0}, Bar.HL{8.0, 6.0}]

def sar() -> Bool:
  Bool.and(
    scalar(TA.SAR.batch(bars(), 0.0, 0.0), [None{}, Some{8.0}, Some{8.0}, Some{12.0}, Some{12.0}, Some{12.0}, Some{7.0}, Some{12.0}]),
    scalar(TA.SAREXT.batch(bars(), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0), [None{}, Some{8.0}, Some{8.0}, Some{F32.sub(0.0, 12.0)}, Some{F32.sub(0.0, 12.0)}, Some{F32.sub(0.0, 12.0)}, Some{7.0}, Some{F32.sub(0.0, 12.0)}]))

def ties() -> Bool:
  Bool.and(
    scalar(TA.SAR.batch([Bar.HL{10.0, 8.0}, Bar.HL{11.0, 7.0}], 0.0, 0.0), [None{}, Some{11.0}]),
    scalar(TA.CG.batch([1.0, F32.sub(0.0, 1.0), 2.0, F32.sub(0.0, 2.0)], 2), [None{}, Some{F32.sub(0.0, 1.5)}, Some{0.0}, Some{F32.sub(0.0, 1.5)}]))

def mcgd() -> Bool:
  scalar(TA.MCGD.batch([2.0, 0.0, 2.0, 0.0], 2), [None{}, Some{2.0}, Some{2.0}, Some{2.0}])

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(sar()))
    IO.print(Bool.show(ties()))
    IO.print(Bool.show(mcgd()))

#|True
#|True
#|True
