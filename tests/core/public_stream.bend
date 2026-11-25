import Base
import ../../f32.bend as TA

def check_second_chunk(chunk: TA.SMA.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match chunk:
    case (_, [Some{first}, Some{second}]): Bool.and(F32.is_eq(first, 9.0), F32.is_eq(second, 12.0))
    case _: False{}

def check_first_chunk(chunk: TA.SMA.State() & List<&2, Maybe<&2, F32>>) -> Bool:
  match chunk:
    case (state, [None{}, None{}, Some{value}]):
      Bool.and(F32.is_eq(value, 6.0), check_second_chunk(TA.Stream.scan(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [12.0, 15.0], state)))
    case _: False{}

def check_chunks(initialized: Result<&2, &1, TA.Error(), TA.SMA.State()>) -> Bool:
  match initialized:
    case Done{state}: check_first_chunk(TA.Stream.scan(~F32, ~F32, ~TA.SMA.State(), ~TA.SMA.next, [3.0, 6.0, 9.0], state))
    case Fail{error}: False{}

def check(passed: Bool) -> IO(Unit):
  match passed:
    case True{}: IO.pure(Unit, Unit{})
    case False{}: IO.die(Unit, 1, "public SMA scan chunk alignment and continuation")

def main() -> IO(Unit):
  check(check_chunks(TA.SMA.init(3)))
