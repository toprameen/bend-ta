import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/parameters.bend as Params

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("VIDYA trend then flat", Assert.batch(~Params.Error, ~F32, ~F32.is_eq, TA.VIDYA.batch([1.0, 2.0, 4.0, 4.0, 4.0, 6.0], 3, 2), [None{}, None{}, Some{2.75}, Some{3.375}, Some{3.375}, Some{4.6875}]))
    Unit <- Assert.check("VIDYA first output", Assert.batch(~Params.Error, ~F32, ~F32.is_eq, TA.VIDYA.batch([4.0, 3.0, 1.0], 3, 2), [None{}, None{}, Some{2.25}]))
    Unit <- Assert.check("VIDYA period one", Assert.batch(~Params.Error, ~F32, ~F32.is_eq, TA.VIDYA.batch([1.0, 2.0, 4.0], 1, 100000), [Some{1.0}, Some{2.0}, Some{4.0}]))
    Unit <- Assert.check("VIDYA constant prices", Assert.batch(~Params.Error, ~F32, ~F32.is_eq, TA.VIDYA.batch([5.0, 5.0, 5.0, 5.0], 3, 2), [None{}, None{}, Some{5.0}, Some{5.0}]))
    Unit <- Assert.check("VIDYA empty", Assert.batch(~Params.Error, ~F32, ~F32.is_eq, TA.VIDYA.batch([], 3, 2), []))
    Assert.check("VIDYA invalid periods", Result.is_fail(&2, &2, Params.Error, List<&2, Maybe<&2, F32>>, TA.VIDYA.batch([], 1, 1)))
