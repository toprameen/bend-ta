import Base
import ../../scripts/test.bend as Runner

def show(result: Result<String, String>) -> String:
  match result:
    case Fail{error}: "error: " ++ error
    case Done{+value}: Bool.pick(String, String.is_empty(value), "<empty>", "output: " ++ value)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(Runner.expected(String.repeat("abcdefghij", 3000n) ++ "\n#|large\n")))
    IO.print(show(Runner.expected("code #|ignored\n#| first\r\n#|second\n")))
    IO.print(show(Runner.expected("#|")))
    IO.print(show(Runner.expected("code\n")))

#|output: large
#|output: first
#|second
#|<empty>
#|error: missing #| expected output
