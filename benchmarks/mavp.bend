import Base
import ../f32.bend as TA
import ../src/core/variable.bend as Variable
import ../src/core/ma.bend as Ma
import ../src/core/parameters.bend as P

type Case is Data:
  Case{kind: U32, minimum: U32, maximum: U32, samples: U32}

type Summary is Data:
  Summary{ready: U32, checksum: U32}

def sample(+minimum: U32, maximum: U32, +at: U32) -> Variable.Sample<F32>:
  Variable.Sample{F32.add(64.0, F32.div(U32.to_f32(U32.mod(U32.add(U32.mul(at, 1664525), 1013904223), 4093)), 16.0)), U32.to_f32(U32.add(minimum, U32.mod(at, U32.add(U32.sub(maximum, minimum), 1))))}

def collect(+ready: U32, +checksum: U32, result: TA.MAVP.State() & Maybe<&2, F32>, rest: TA.MAVP.State() -> U32 -> U32 -> Summary) -> Summary:
  match result:
    case (state, None{}): rest(state, ready, U32.add(U32.mul(checksum, 31), 1))
    case (state, Some{value}): rest(state, U32.add(ready, 1), U32.add(U32.mul(checksum, 31), F32.bits(value)))

def run(fuel: Nat, +minimum: U32, +maximum: U32, +at: U32, state: TA.MAVP.State(), ready: U32, checksum: U32) -> Summary:
  match fuel:
    case 0n: Summary{ready, checksum}
    case 1n+rest: collect(ready, checksum, TA.MAVP.next(state, sample(minimum, maximum, at)), s => r => h => run(rest, minimum, maximum, U32.add(at, 1), s, r, h))

def initialized(minimum: U32, maximum: U32, samples: U32, result: Result<&2, &1, P.Error, TA.MAVP.State()>) -> Result<&2, &2, P.Error, Summary>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{run(U32.to_nat(samples), minimum, maximum, 0, state, 0, 0)}

def compute(config: Case) -> Result<&2, &2, P.Error, Summary>:
  match config:
    case Case{kind, +minimum, +maximum, samples}: initialized(minimum, maximum, samples, TA.MAVP.init(minimum, maximum, kind))

def finish(config: Case, start: Nat, warm: Summary, result: Result<&2, &2, P.Error, Summary>) -> IO(Unit):
  match config warm result:
    case _ _ Fail{e}: IO.die(Unit, 1, "invalid MAVP configuration")
    case Case{kind, minimum, maximum, samples} Summary{warm_ready, warm_checksum} Done{Summary{ready, checksum}}:
      do IO<Unit>:
        end : Nat <- IO.now()
        IO.print(String.join([U32.show(kind), U32.show(minimum), U32.show(maximum), U32.show(samples), Nat.show(Nat.sub(end, start)), U32.show(ready), U32.show(checksum), U32.show(warm_ready), U32.show(warm_checksum)], ","))

def measure(+config: Case, warm: Summary) -> IO(Unit):
  do IO<Unit>:
    start : Nat <- IO.now()
    finish(config, start, warm, compute(config))

def warmed(config: Case, result: Result<&2, &2, P.Error, Summary>) -> IO(Unit):
  match result:
    case Fail{e}: IO.die(Unit, 1, "invalid MAVP configuration")
    case Done{summary}: measure(config, summary)

def prepare(+config: Case) -> IO(Unit):
  match config:
    case Case{+kind, minimum, +maximum, samples}: warmed(config, compute(Case{kind, minimum, maximum, U32.min(samples, U32.add(Ma.lookback(maximum, kind), 1024))}))

def options(kind: Maybe<&2, U32>, minimum: Maybe<&2, U32>, maximum: Maybe<&2, U32>, samples: Maybe<&2, U32>) -> IO(Unit):
  match kind minimum maximum samples:
    case Some{k} Some{lo} Some{hi} Some{n}: prepare(Case{k, lo, hi, n})
    case _ _ _ _: IO.die(Unit, 1, "expected unsigned integer arguments")

def start(args: List<String>) -> IO(Unit):
  match args:
    case name <> kind <> minimum <> maximum <> samples <> Nil{}: options(U32.read(kind), U32.read(minimum), U32.read(maximum), U32.read(samples))
    case _: IO.die(Unit, 1, "usage: mavp <kind> <minimum> <maximum> <samples>")

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    start(args)
