import Base
import ../src/f32.bend as TA
import ../src/core/bar.bend as Bar
import ../src/core/statistics.bend as Stats
import ../src/core/overlap.bend as Overlap
import ../src/core/momentum_window.bend as Box
import ../src/core/momentum_smooth.bend as Smooth
import ../src/core/parameters.bend as P

type Summary is Data:
  Summary{ready: U32, checksum: U32}

type Case is Data:
  Case{kind: U32, period: U32, samples: U32, shape: U32}

def price(shape: U32, +at: U32) -> F32:
  match shape:
    case 1: U32.to_f32(at)
    case 2: 64.0
    case 3: U32.to_f32(Bool.pick(U32, U32.is_zero(U32.mod(at, 2)), 32, 96))
    case _: F32.add(64.0, F32.div(U32.to_f32(U32.mod(U32.add(U32.mul(at, 1664525), 1013904223), 4093)), 16.0))

def scalar(shape: U32, at: U32) -> F32:
  price(shape, at)

def hl(shape: U32, at: U32) -> Bar.HL<F32>:
  +p = price(shape, at)
  Bar.HL{F32.add(p, 2.0), F32.sub(p, 1.0)}

def hlc(shape: U32, at: U32) -> Bar.HLC<F32>:
  +p = price(shape, at)
  Bar.HLC{F32.add(p, 2.0), F32.sub(p, 1.0), p}

def hlv(shape: U32, at: U32) -> Bar.HLV<F32>:
  +index = at
  +p = price(shape, index)
  Bar.HLV{F32.add(p, 2.0), F32.sub(p, 1.0), U32.to_f32(U32.add(100, U32.mod(index, 13)))}

def ohlc(shape: U32, at: U32) -> Bar.OHLC<F32>:
  +p = price(shape, at)
  Bar.OHLC{p, F32.add(p, 2.0), F32.sub(p, 1.0), F32.add(p, 0.5)}

def digest.scalar(value: F32) -> U32:
  F32.bits(value)

def digest.indices(value: Stats.MinMaxIndex) -> U32:
  match value:
    case Stats.MinMaxIndex{low, high}: U32.add(U32.mul(low, 31), high)

def digest.bands(value: Overlap.Bands<F32>) -> U32:
  match value:
    case Overlap.Bands{upper, middle, lower}: U32.add(U32.mul(F32.bits(upper), 31), U32.add(F32.bits(middle), F32.bits(lower)))

def digest.aroon(value: Box.Aroon<F32>) -> U32:
  match value:
    case Box.Aroon{down, up}: U32.add(U32.mul(F32.bits(down), 31), F32.bits(up))

def digest.lines(value: Smooth.StochValue<F32>) -> U32:
  match value:
    case Smooth.StochValue{one, two, three}: U32.add(U32.mul(F32.bits(one), 31), U32.add(F32.bits(two), F32.bits(three)))

def collect(~O: Data, ~hash: O -> U32, +count: U32, +checksum: U32, value: Maybe<&2, O>) -> Summary:
  match value:
    case None{}: Summary{count, U32.add(U32.mul(checksum, 31), 1)}
    case Some{x}: Summary{U32.add(count, 1), U32.add(U32.mul(checksum, 31), hash(x))}

def resume(~O: Data, ~S: Type, ~hash: O -> U32, result: S & Maybe<&2, O>, summary: Summary, rest: S -> Summary -> Summary) -> Summary:
  match result summary:
    case (state, value) Summary{count, checksum}: rest(state, collect(~O, ~hash, count, checksum, value))

def run(~I: Data, ~O: Data, ~S: Type, ~input: U32 -> U32 -> I, ~step: S -> I -> S & Maybe<&2, O>, ~hash: O -> U32, fuel: Nat, +shape: U32, +at: U32, state: S, summary: Summary) -> Summary:
  match fuel:
    case 0n: summary
    case 1n+rest: resume(~O, ~S, ~hash, step(state, input(shape, at)), summary, s => sum => run(~I, ~O, ~S, ~input, ~step, ~hash, rest, shape, U32.add(at, 1), s, sum))

def initialized(~I: Data, ~O: Data, ~S: Type, ~input: U32 -> U32 -> I, ~step: S -> I -> S & Maybe<&2, O>, ~hash: O -> U32, samples: U32, shape: U32, result: Result<&2, &1, P.Error, S>) -> Result<&2, &2, P.Error, Summary>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{run(~I, ~O, ~S, ~input, ~step, ~hash, U32.to_nat(samples), shape, 0, state, Summary{0, 0})}

def compute(config: Case) -> Result<&2, &2, P.Error, Summary>:
  match config:
    case Case{0, period, samples, shape}: initialized(~F32, ~F32, ~TA.MAX.State(), ~scalar, ~TA.MAX.next, ~digest.scalar, samples, shape, TA.MAX.init(period))
    case Case{1, period, samples, shape}: initialized(~F32, ~Stats.MinMaxIndex, ~TA.MINMAXINDEX.State(), ~scalar, ~TA.MINMAXINDEX.next, ~digest.indices, samples, shape, TA.MINMAXINDEX.init(period))
    case Case{2, period, samples, shape}: initialized(~Bar.HL<F32>, ~Overlap.Bands<F32>, ~TA.DONCHIAN.State(), ~hl, ~TA.DONCHIAN.next, ~digest.bands, samples, shape, TA.DONCHIAN.init(period))
    case Case{3, period, samples, shape}: initialized(~Bar.HL<F32>, ~Box.Aroon<F32>, ~TA.AROON.State(), ~hl, ~TA.AROON.next, ~digest.aroon, samples, shape, TA.AROON.init(period))
    case Case{4, period, samples, shape}: initialized(~Bar.HLC<F32>, ~Smooth.StochValue<F32>, ~TA.STOCHF.State(), ~hlc, ~TA.STOCHF.next, ~digest.lines, samples, shape, TA.STOCHF.init(period, 3, 0))
    case Case{5, period, samples, shape}: initialized(~F32, ~F32, ~TA.WMA.State(), ~scalar, ~TA.WMA.next, ~digest.scalar, samples, shape, TA.WMA.init(period))
    case Case{6, period, samples, shape}: initialized(~F32, ~F32, ~TA.MA.State(), ~scalar, ~TA.MA.next, ~digest.scalar, samples, shape, TA.MA.init(period, 0))
    case Case{7, period, samples, shape}: initialized(~Bar.HLV<F32>, ~F32, ~TA.EMV.State(), ~hlv, ~TA.EMV.next, ~digest.scalar, samples, shape, TA.EMV.init(period, 1.0))
    case Case{kind, period, samples, shape}: initialized(~Bar.OHLC<F32>, ~F32, ~TA.ROGERSSATCHELL.State(), ~ohlc, ~TA.ROGERSSATCHELL.next, ~digest.scalar, samples, shape, TA.ROGERSSATCHELL.init(period, 252.0))

def finish(config: Case, start: Nat, warm: Summary, result: Result<&2, &2, P.Error, Summary>) -> IO(Unit):
  match config warm result:
    case Case{kind, period, samples, shape} _ Fail{e}: IO.die(Unit, 1, "invalid indicator configuration")
    case Case{kind, period, samples, shape} Summary{warm_ready, warm_checksum} Done{Summary{ready, checksum}}:
      do IO<Unit>:
        end : Nat <- IO.now()
        IO.print(String.join([U32.show(kind), U32.show(period), U32.show(samples), U32.show(shape), Nat.show(Nat.sub(end, start)), U32.show(ready), U32.show(checksum), U32.show(warm_ready), U32.show(warm_checksum)], ","))

def measure(+config: Case, warm: Summary) -> IO(Unit):
  do IO<Unit>:
    start : Nat <- IO.now()
    finish(config, start, warm, compute(config))

def warmed(config: Case, result: Result<&2, &2, P.Error, Summary>) -> IO(Unit):
  match result:
    case Fail{e}: IO.die(Unit, 1, "invalid indicator configuration")
    case Done{summary}: measure(config, summary)

def prepare(+config: Case) -> IO(Unit):
  match config:
    case Case{kind, +period, samples, shape}: warmed(config, compute(Case{kind, period, U32.min(samples, U32.add(period, 1024)), shape}))

def valid(+config: Case, accepted: Bool) -> IO(Unit):
  match accepted:
    case False{}: IO.die(Unit, 1, "kind0..8, period2..100000, samples0..4294967295, shape0..3 required")
    case True{}: prepare(config)

def options(kind: Maybe<&2, U32>, period: Maybe<&2, U32>, samples: Maybe<&2, U32>, shape: Maybe<&2, U32>) -> IO(Unit):
  match kind period samples shape:
    case Some{+k} Some{+p} Some{+n} Some{+s}: valid(Case{k, p, n, s}, Bool.and(Bool.and(U32.is_le(k, 8), U32.is_le(s, 3)), Bool.and(U32.is_ge(p, 2), U32.is_le(p, 100000))))
    case _ _ _ _: IO.die(Unit, 1, "expected unsigned integer arguments")

def start(args: List<String>) -> IO(Unit):
  match args:
    case name <> kind <> period <> samples <> shape <> Nil{}: options(U32.read(kind), U32.read(period), U32.read(samples), U32.read(shape))
    case _: IO.die(Unit, 1, "usage: rolling <kind0..8> <period> <samples> <shape0..3>")

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    start(args)
