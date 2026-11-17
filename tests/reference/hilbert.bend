import Base
import ../../scripts/assert.bend as Assert
import ../../src/f32.bend as TA
import ../../src/core/series.bend as Series
import ../../src/core/parameters.bend as Params
import ../../src/core/hilbert.bend as H

type Target<-O: Data> is Data:
  Target{index: Nat, value: O}

def cycle(at: U32) -> F32:
  match at:
    case 0: 10.0
    case 1: 12.0
    case 2: 14.0
    case 3: 13.0
    case 4: 11.0
    case 5: 8.0
    case 6: 6.0
    case 7: 7.0
    case 8: 9.0
    case 9: 11.0
    case 10: 13.0
    case _: 12.0

def samples(count: Nat, +index: U32) -> List<&2, F32>:
  match count:
    case 0n: []
    case 1n+rest: cycle(U32.mod(index, 12)) <> samples(rest, U32.add(index, 1))

def at(~O: Data, index: Nat, xs: List<&2, Maybe<&2, O>>) -> Maybe<&2, O>:
  match index xs:
    case 0n h <> t: h
    case 1n+rest h <> t: at(~O, rest, t)
    case _ Nil{}: None{}

def aligned(~O: Data, count: Nat, xs: List<&2, Maybe<&2, O>>) -> Bool:
  match count xs:
    case _ Nil{}: True{}
    case 0n Some{v} <> t: aligned(~O, 0n, t)
    case 1n+rest None{} <> t: aligned(~O, rest, t)
    case _ _: False{}

def near(a: F32, b: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(a, b)), 0.0002)

def target(~O: Data, ~equal: O -> O -> Bool, expected: O, actual: Maybe<&2, O>) -> Bool:
  match actual:
    case None{}: False{}
    case Some{v}: equal(expected, v)

def targets(~O: Data, ~equal: O -> O -> Bool, +xs: List<&2, Maybe<&2, O>>, expected: List<&2, Target<O>>) -> Bool:
  match expected:
    case Nil{}: True{}
    case Target{index, value} <> rest: Bool.and(target(~O, ~equal, value, at(~O, index, xs)), targets(~O, ~equal, xs, rest))

def check(~O: Data, ~equal: O -> O -> Bool, warmup: Nat, expected: List<&2, Target<O>>, result: Result<&2, &2, Params.Error, List<&2, Maybe<&2, O>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{+xs}: Bool.and(aligned(~O, warmup, xs), targets(~O, ~equal, xs, expected))

def continued(~O: Data, ~S: Type, ~step: S -> F32 -> S & Maybe<&2, O>, result: S & List<&2, Maybe<&2, O>>) -> List<&2, Maybe<&2, O>>:
  match result:
    case (state, prefix): List.append(&2, Maybe<&2, O>, prefix, Series.batch(~F32, ~O, ~S, ~step, samples(160n, 20), state))

def chunked(~O: Data, ~S: Type, ~step: S -> F32 -> S & Maybe<&2, O>, result: Result<&2, &1, Params.Error, S>) -> Result<&2, &2, Params.Error, List<&2, Maybe<&2, O>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{continued(~O, ~S, ~step, Series.scan(~F32, ~O, ~S, ~step, samples(20n, 0), state))}

def phasor(expected: H.Phasor<F32>, actual: TA.HT_PHASOR.Value()) -> Bool:
  match expected:
    case H.Phasor{i, q}:
      +actual = actual
      Bool.and(near(i, TA.HT_PHASOR.in_phase(actual)), near(q, TA.HT_PHASOR.quadrature(actual)))

def sine(expected: H.Sine<F32>, actual: TA.HT_SINE.Value()) -> Bool:
  match expected:
    case H.Sine{s, l}:
      +actual = actual
      Bool.and(near(s, TA.HT_SINE.sine(actual)), near(l, TA.HT_SINE.lead_sine(actual)))

def expected.talib_c_0_8_4_f64.HT_DCPERIOD() -> List<&2, Target<F32>>:
  [Target{32n, 11.92295071985235}, Target{33n, 12.077108440828512}, Target{80n, 12.156406539708739}, Target{100n, 12.271019266697724}, Target{179n, 12.046254600269366}]

def expected.talib_c_0_8_4_f64.HT_DCPHASE() -> List<&2, Target<F32>>:
  [Target{63n, 124.06079267824805}, Target{64n, 149.85949826995704}, Target{80n, 311.5518791876817}, Target{100n, 191.80383437354484}, Target{179n, 42.33249919360765}]

def expected.talib_c_0_8_4_f64.HT_PHASOR() -> List<&2, Target<H.Phasor<F32>>>:
  [Target{32n, H.Phasor{0.8843453054535184, F32.neg(1.9981376648357745)}}, Target{33n, H.Phasor{F32.neg(0.4974932238062076), F32.neg(3.388473477776854)}}, Target{80n, H.Phasor{0.9167497900131895, F32.neg(2.035170784688031)}}, Target{100n, H.Phasor{2.871668374108188, F32.neg(1.648600533959532)}}, Target{179n, H.Phasor{F32.neg(3.99903541077151), F32.neg(0.43746573524564336)}}]

def expected.talib_c_0_8_4_f64.HT_SINE() -> List<&2, Target<H.Sine<F32>>>:
  [Target{63n, H.Sine{0.8284437842189178, 0.18976734992361857}}, Target{64n, H.Sine{0.5021221774345251, F32.neg(0.2564496087903278)}}, Target{80n, H.Sine{F32.neg(0.7483554361535663), F32.neg(0.06014474086468286)}}, Target{100n, H.Sine{F32.neg(0.20456155958094757), F32.neg(0.8368009558538353)}}, Target{179n, H.Sine{0.673431937241693, 0.9989164338946218}}]

def expected.talib_c_0_8_4_f64.HT_TRENDLINE() -> List<&2, Target<F32>>:
  [Target{63n, 10.789010989010988}, Target{64n, 10.792857142857143}, Target{80n, 10.411538461538461}, Target{100n, 10.5}, Target{179n, 10.5}]

def expected.talib_c_0_8_4_f64.HT_TRENDMODE() -> List<&2, Target<U32>>:
  [Target{63n, 1}, Target{64n, 1}, Target{80n, 1}, Target{100n, 1}, Target{179n, 1}]

def flat(count: Nat) -> List<&2, F32>:
  match count:
    case 0n: []
    case 1n+rest: 5.0 <> flat(rest)

def range(lower: F32, upper: F32, +value: F32) -> Bool:
  Bool.and(F32.is_le(lower, value), F32.is_le(value, upper))

def phase_bounds(value: F32) -> Bool:
  range(F32.neg(45.0), 315.0, value)

def period_bounds(value: F32) -> Bool:
  range(0.0, 50.0, value)

def phasor_flat(value: H.Phasor<F32>) -> Bool:
  phasor(H.Phasor{0.0, 0.0}, value)

def sine_bounds(value: H.Sine<F32>) -> Bool:
  match value:
    case H.Sine{s, l}: Bool.and(range(F32.neg(1.0), 1.0, s), range(F32.neg(1.0), 1.0, l))

def line_flat(value: F32) -> Bool:
  near(5.0, value)

def flag_bounds(value: U32) -> Bool:
  U32.is_le(value, 1)

def bounded.values(~O: Data, ~within: O -> Bool, xs: List<&2, Maybe<&2, O>>) -> Bool:
  match xs:
    case Nil{}: True{}
    case None{} <> rest: bounded.values(~O, ~within, rest)
    case Some{v} <> rest: Bool.and(within(v), bounded.values(~O, ~within, rest))

def bounded(~O: Data, ~within: O -> Bool, result: Result<&2, &2, Params.Error, List<&2, Maybe<&2, O>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: bounded.values(~O, ~within, xs)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("HT_DCPERIOD.batch case 1", check(~F32, ~near, 32n, expected.talib_c_0_8_4_f64.HT_DCPERIOD(), TA.HT_DCPERIOD.batch(samples(180n, 0))))
    Unit <- Assert.check("HT_DCPERIOD.next", check(~F32, ~near, 32n, expected.talib_c_0_8_4_f64.HT_DCPERIOD(), chunked(~F32, ~TA.HT_DCPERIOD.State(), ~TA.HT_DCPERIOD.next, TA.HT_DCPERIOD.init())))
    Unit <- Assert.check("HT_DCPERIOD.batch case 2", check(~F32, ~near, 32n, [], TA.HT_DCPERIOD.batch([0.0, 0.0, 0.0])))
    Unit <- Assert.check("HT_DCPERIOD.batch case 3", check(~F32, ~near, 32n, [], TA.HT_DCPERIOD.batch([])))
    Unit <- Assert.check("HT_DCPHASE.batch case 1", check(~F32, ~near, 63n, expected.talib_c_0_8_4_f64.HT_DCPHASE(), TA.HT_DCPHASE.batch(samples(180n, 0))))
    Unit <- Assert.check("HT_DCPHASE.next", check(~F32, ~near, 63n, expected.talib_c_0_8_4_f64.HT_DCPHASE(), chunked(~F32, ~TA.HT_DCPHASE.State(), ~TA.HT_DCPHASE.next, TA.HT_DCPHASE.init())))
    Unit <- Assert.check("HT_DCPHASE.batch case 2", check(~F32, ~near, 63n, [], TA.HT_DCPHASE.batch([0.0, 0.0, 0.0])))
    Unit <- Assert.check("HT_DCPHASE.batch case 3", check(~F32, ~near, 63n, [], TA.HT_DCPHASE.batch([])))
    Unit <- Assert.check("HT_PHASOR.batch case 1", check(~H.Phasor<F32>, ~phasor, 32n, expected.talib_c_0_8_4_f64.HT_PHASOR(), TA.HT_PHASOR.batch(samples(180n, 0))))
    Unit <- Assert.check("HT_PHASOR.next", check(~H.Phasor<F32>, ~phasor, 32n, expected.talib_c_0_8_4_f64.HT_PHASOR(), chunked(~H.Phasor<F32>, ~TA.HT_PHASOR.State(), ~TA.HT_PHASOR.next, TA.HT_PHASOR.init())))
    Unit <- Assert.check("HT_PHASOR.batch case 2", check(~H.Phasor<F32>, ~phasor, 32n, [], TA.HT_PHASOR.batch([0.0, 0.0, 0.0])))
    Unit <- Assert.check("HT_PHASOR.batch case 3", check(~H.Phasor<F32>, ~phasor, 32n, [], TA.HT_PHASOR.batch([])))
    Unit <- Assert.check("HT_SINE.batch case 1", check(~H.Sine<F32>, ~sine, 63n, expected.talib_c_0_8_4_f64.HT_SINE(), TA.HT_SINE.batch(samples(180n, 0))))
    Unit <- Assert.check("HT_SINE.next", check(~H.Sine<F32>, ~sine, 63n, expected.talib_c_0_8_4_f64.HT_SINE(), chunked(~H.Sine<F32>, ~TA.HT_SINE.State(), ~TA.HT_SINE.next, TA.HT_SINE.init())))
    Unit <- Assert.check("HT_SINE.batch case 2", check(~H.Sine<F32>, ~sine, 63n, [], TA.HT_SINE.batch([0.0, 0.0, 0.0])))
    Unit <- Assert.check("HT_SINE.batch case 3", check(~H.Sine<F32>, ~sine, 63n, [], TA.HT_SINE.batch([])))
    Unit <- Assert.check("HT_TRENDLINE.batch case 1", check(~F32, ~near, 63n, expected.talib_c_0_8_4_f64.HT_TRENDLINE(), TA.HT_TRENDLINE.batch(samples(180n, 0))))
    Unit <- Assert.check("HT_TRENDLINE.next", check(~F32, ~near, 63n, expected.talib_c_0_8_4_f64.HT_TRENDLINE(), chunked(~F32, ~TA.HT_TRENDLINE.State(), ~TA.HT_TRENDLINE.next, TA.HT_TRENDLINE.init())))
    Unit <- Assert.check("HT_TRENDLINE.batch case 2", check(~F32, ~near, 63n, [], TA.HT_TRENDLINE.batch([0.0, 0.0, 0.0])))
    Unit <- Assert.check("HT_TRENDLINE.batch case 3", check(~F32, ~near, 63n, [], TA.HT_TRENDLINE.batch([])))
    Unit <- Assert.check("HT_TRENDMODE.batch case 1", check(~U32, ~U32.is_eq, 63n, expected.talib_c_0_8_4_f64.HT_TRENDMODE(), TA.HT_TRENDMODE.batch(samples(180n, 0))))
    Unit <- Assert.check("HT_TRENDMODE.next", check(~U32, ~U32.is_eq, 63n, expected.talib_c_0_8_4_f64.HT_TRENDMODE(), chunked(~U32, ~TA.HT_TRENDMODE.State(), ~TA.HT_TRENDMODE.next, TA.HT_TRENDMODE.init())))
    Unit <- Assert.check("HT_TRENDMODE.batch case 2", check(~U32, ~U32.is_eq, 63n, [], TA.HT_TRENDMODE.batch([0.0, 0.0, 0.0])))
    Unit <- Assert.check("HT_TRENDMODE.batch case 3", check(~U32, ~U32.is_eq, 63n, [], TA.HT_TRENDMODE.batch([])))
    Unit <- Assert.check("HT_DCPERIOD.batch case 4", bounded(~F32, ~period_bounds, TA.HT_DCPERIOD.batch(flat(180n))))
    Unit <- Assert.check("HT_DCPHASE.batch case 4", bounded(~F32, ~phase_bounds, TA.HT_DCPHASE.batch(flat(180n))))
    Unit <- Assert.check("HT_PHASOR.batch case 4", bounded(~H.Phasor<F32>, ~phasor_flat, TA.HT_PHASOR.batch(flat(180n))))
    Unit <- Assert.check("HT_SINE.batch case 4", bounded(~H.Sine<F32>, ~sine_bounds, TA.HT_SINE.batch(flat(180n))))
    Unit <- Assert.check("HT_TRENDLINE.batch case 4", bounded(~F32, ~line_flat, TA.HT_TRENDLINE.batch(flat(180n))))
    Assert.check("HT_TRENDMODE.batch case 4", bounded(~U32, ~flag_bounds, TA.HT_TRENDMODE.batch(flat(180n))))
