import Base
import ../../scripts/assert.bend as Assert
import ../../scripts/test.bend as Runner

def rejected(result: Result<String, Unit>) -> IO(Unit):
  match result:
    case Done{value}: IO.die(Unit, 1, "execution failure was ignored")
    case Fail{message}: Assert.check("report execution failure", String.eq(message, "test: JavaScript\nassertion failed"))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("discover tests", Runner.fixture("tests/reference/moving_averages.bend"))
    Unit <- Assert.check("discover examples", Runner.fixture("examples/moving_averages.bend"))
    Unit <- Assert.check("skip support modules", Bool.not(Runner.fixture("scripts/support.bend")))
    Unit <- Assert.check("skip fixture data", Bool.not(Runner.fixture("tests/data/prices.csv")))
    ok : Result<String, Unit> <- Runner.checked("test: native", Done{"output"})
    Unit <- Assert.check("accept successful execution", Result.is_done(&1, &1, String, Unit, ok))
    failed : Result<String, Unit> <- Runner.checked("test: JavaScript", Fail{"assertion failed"})
    rejected(failed)
