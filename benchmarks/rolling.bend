import Base
import ../src/f32.bend as TA
import ../src/core/bar.bend as Bar
import ../src/core/statistics.bend as Stats
import ../src/core/overlap.bend as Overlap
import ../src/core/momentum_window.bend as Box
import ../src/core/momentum_smooth.bend as Smooth
import ../src/core/parameters.bend as P
import ../src/core/squeeze.bend as Squeeze
import ../src/core/variable.bend as Variable
import ../src/core/statistics_window.bend as StatWindow

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

def pair.input(+shape: U32, +at: U32, ordinary: Bool) -> StatWindow.PairValue<F32>:
  match ordinary:
    case True{}: StatWindow.PairValue{price(shape, at), price(shape, U32.add(at, 7))}
    case False{}:
      +unit = Bool.pick(F32, U32.is_lt(U32.mod(at, 4), 2), 1.0, F32.neg(1.0))
      +other = Bool.pick(F32, U32.is_lt(U32.mod(U32.add(at, 1), 4), 2), 1.0, F32.neg(1.0))
      +scale = Bool.pick(F32, U32.is_eq(shape, 4), 1.0, 1.0e-20)
      StatWindow.PairValue{F32.mul(unit, scale), F32.mul(other, scale)}

def pair(shape: U32, at: U32) -> StatWindow.PairValue<F32>:
  +shape = shape
  pair.input(shape, at, U32.is_lt(shape, 4))

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

def variable(shape: U32, at: U32) -> Variable.Sample<F32>:
  +index = at
  Variable.Sample{price(shape, index), F32.add(2.0, U32.to_f32(U32.mod(index, 63)))}

def digest.pair(value: Smooth.Lines<F32>) -> U32:
  match value:
    case Smooth.Lines{first, second}: U32.add(U32.mul(F32.bits(first), 31), F32.bits(second))

def digest.squeeze(value: Squeeze.Value<F32>) -> U32:
  match value:
    case Squeeze.SqueezeValue{momentum, negative, strength}: U32.add(F32.bits(momentum), U32.add(Bool.pick(U32, negative, 31, 0), strength))

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
    case Case{8, period, samples, shape}: initialized(~Bar.OHLC<F32>, ~F32, ~TA.ROGERSSATCHELL.State(), ~ohlc, ~TA.ROGERSSATCHELL.next, ~digest.scalar, samples, shape, TA.ROGERSSATCHELL.init(period, 252.0))

    case Case{9, period, samples, shape}: initialized(~F32, ~F32, ~TA.TRIMA.State(), ~scalar, ~TA.TRIMA.next, ~digest.scalar, samples, shape, TA.TRIMA.init(period))
    case Case{10, period, samples, shape}: initialized(~F32, ~F32, ~TA.KAMA.State(), ~scalar, ~TA.KAMA.next, ~digest.scalar, samples, shape, TA.KAMA.init(period))
    case Case{11, period, samples, shape}: initialized(~F32, ~F32, ~TA.HMA.State(), ~scalar, ~TA.HMA.next, ~digest.scalar, samples, shape, TA.HMA.init(period))
    case Case{12, period, samples, shape}: initialized(~F32, ~F32, ~TA.DPO.State(), ~scalar, ~TA.DPO.next, ~digest.scalar, samples, shape, TA.DPO.init(period))
    case Case{13, period, samples, shape}: initialized(~F32, ~F32, ~TA.RVOL.State(), ~scalar, ~TA.RVOL.next, ~digest.scalar, samples, shape, TA.RVOL.init(period))
    case Case{14, period, samples, shape}: initialized(~Bar.HLC<F32>, ~Overlap.Bands<F32>, ~TA.ACCBANDS.State(), ~hlc, ~TA.ACCBANDS.next, ~digest.bands, samples, shape, TA.ACCBANDS.init(period))
    case Case{15, period, samples, shape}: initialized(~Bar.HLC<F32>, ~Smooth.Lines<F32>, ~TA.WAVETREND.State(), ~hlc, ~TA.WAVETREND.next, ~digest.pair, samples, shape, TA.WAVETREND.init(10, 21, period))
    case Case{16, +period, samples, shape}: initialized(~Bar.HLC<F32>, ~Squeeze.Value<F32>, ~TA.SQZMOM.State(), ~hlc, ~TA.SQZMOM.next, ~digest.squeeze, samples, shape, TA.SQZMOM.init(period, 2.0, period, 2.0, 1.5, 1.0))
    case Case{17, period, samples, shape}: initialized(~F32, ~F32, ~TA.LINEARREG.State(), ~scalar, ~TA.LINEARREG.next, ~digest.scalar, samples, shape, TA.LINEARREG.init(period))
    case Case{18, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 0))
    case Case{19, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 2))
    case Case{20, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 5))
    case Case{21, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 6))
    case Case{22, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 9))
    case Case{23, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 12))
    case Case{24, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 14))
    case Case{25, period, samples, shape}: initialized(~Variable.Sample<F32>, ~F32, ~TA.MAVP.State(), ~variable, ~TA.MAVP.next, ~digest.scalar, samples, shape, TA.MAVP.init(2, period, 15))
    case Case{26, period, samples, shape}: initialized(~F32, ~F32, ~TA.VAR.State(), ~scalar, ~TA.VAR.next, ~digest.scalar, samples, shape, TA.VAR.init(period, 1.0))
    case Case{27, period, samples, shape}: initialized(~F32, ~F32, ~TA.STDDEV.State(), ~scalar, ~TA.STDDEV.next, ~digest.scalar, samples, shape, TA.STDDEV.init(period, 1.0))
    case Case{28, period, samples, shape}: initialized(~F32, ~Overlap.Bands<F32>, ~TA.BBANDS.State(), ~scalar, ~TA.BBANDS.next, ~digest.bands, samples, shape, TA.BBANDS.init(period, 2.0, 2.0, 0))
    case Case{29, period, samples, shape}: initialized(~F32, ~F32, ~TA.BBW.State(), ~scalar, ~TA.BBW.next, ~digest.scalar, samples, shape, TA.BBW.init(period, 2.0, 2.0, 0))
    case Case{30, period, samples, shape}: initialized(~F32, ~F32, ~TA.PERCENTB.State(), ~scalar, ~TA.PERCENTB.next, ~digest.scalar, samples, shape, TA.PERCENTB.init(period, 2.0, 2.0, 0))
    case Case{31, period, samples, shape}: initialized(~F32, ~F32, ~TA.RVI.State(), ~scalar, ~TA.RVI.next, ~digest.scalar, samples, shape, TA.RVI.init(14, period))
    case Case{32, period, samples, shape}: initialized(~Bar.HL<F32>, ~F32, ~TA.RVIR.State(), ~hl, ~TA.RVIR.next, ~digest.scalar, samples, shape, TA.RVIR.init(14, period))
    case Case{33, period, samples, shape}: initialized(~StatWindow.PairValue<F32>, ~F32, ~TA.CORREL.State(), ~pair, ~TA.CORREL.next, ~digest.scalar, samples, shape, TA.CORREL.init(period))
    case Case{kind, period, samples, shape}: initialized(~StatWindow.PairValue<F32>, ~F32, ~TA.BETA.State(), ~pair, ~TA.BETA.next, ~digest.scalar, samples, shape, TA.BETA.init(period))

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
    case False{}: IO.die(Unit, 1, "kind0..34, period2..100000, samples0..4294967295, shape0..5 (4/5 CORREL only); MAVP period<=10000 required")
    case True{}: prepare(config)

def options(kind: Maybe<&2, U32>, period: Maybe<&2, U32>, samples: Maybe<&2, U32>, shape: Maybe<&2, U32>) -> IO(Unit):
  match kind period samples shape:
    case Some{+k} Some{+p} Some{+n} Some{+s}: valid(Case{k, p, n, s}, Bool.and(Bool.and(U32.is_le(k, 34), Bool.and(U32.is_le(s, 5), Bool.or(U32.is_le(s, 3), U32.is_eq(k, 33)))), Bool.and(Bool.and(U32.is_ge(p, 2), U32.is_le(p, 100000)), Bool.or(Bool.or(U32.is_lt(k, 18), U32.is_gt(k, 25)), U32.is_le(p, 10000)))))
    case _ _ _ _: IO.die(Unit, 1, "expected unsigned integer arguments")

def start(args: List<String>) -> IO(Unit):
  match args:
    case name <> kind <> period <> samples <> shape <> Nil{}: options(U32.read(kind), U32.read(period), U32.read(samples), U32.read(shape))
    case _: IO.die(Unit, 1, "usage: rolling <kind0..34> <period> <samples> <shape0..5 (4/5 CORREL only)>")

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    start(args)
