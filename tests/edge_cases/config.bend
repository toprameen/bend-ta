import Base
import ../../src/core/config.bend as Config

def show(r: Result<&2, &2, Config.Error, Config.Config>) -> String:
  match r:
    case Fail{e}:
      "invalid"
    case Done{Config.Config{period, depth}}:
      U32.show(period) ++ ":" ++ Nat.show(depth)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(Config.make(0)))
    IO.print(show(Config.make(1)))
    IO.print(show(Config.make(3)))
    IO.print(show(Config.make(4)))
    IO.print(show(Config.make(5)))
    IO.print(show(Config.make(1073741824)))
    IO.print(show(Config.make(1073741825)))

#|invalid
#|1:0
#|3:2
#|4:2
#|5:3
#|1073741824:30
#|invalid
