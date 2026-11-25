import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/momentum_smooth.bend as Smooth
import ../../src/core/series.bend as Series

def close(+a: F32, +b: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(a, b)), F32.max(0.0004, F32.mul(0.0004, F32.abs(b))))

def same(xs: List<&2, F32>, ys: List<&2, F32>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case a <> rest b <> tail: Bool.and(close(a, b), same(rest, tail))
    case _ _: False{}

def scalar(x: F32) -> List<&2, F32>:
  [x]

def lines(value: TA.Lines.Value()) -> List<&2, F32>:
  +value = value
  [TA.Lines.first(value), TA.Lines.second(value)]

def macd(value: Smooth.MACDValue<F32>) -> List<&2, F32>:
  match value:
    case Smooth.MACDValue{a, b, c}: [a, b, c]

def trend(value: TA.SUPERTREND.Value()) -> List<&2, F32>:
  +value = value
  [TA.SUPERTREND.line(value), Bool.pick(F32, TA.SUPERTREND.is_up(value), 1.0, F32.neg(1.0))]

def squeeze(value: TA.SQZMOM.Value()) -> List<&2, F32>:
  +value = value
  +level = U32.to_f32(TA.SQZMOM.strength(value))
  [TA.SQZMOM.momentum(value), Bool.pick(F32, TA.SQZMOM.negative(value), F32.neg(level), level)]

def shape(~O: Data, ~view: O -> List<&2, F32>, xs: List<&2, Maybe<&2, O>>, +at: U32, +warm: U32, +first: List<&2, F32>, +last: List<&2, F32>) -> Bool:
  match xs:
    case Nil{}: U32.is_eq(at, 36)
    case None{} <> rest: Bool.and(U32.is_lt(at, warm), shape(~O, ~view, rest, U32.add(at, 1), warm, first, last))
    case Some{value} <> rest:
      +fields = view(value)
      Bool.and(U32.is_ge(at, warm), Bool.and(Bool.or(U32.is_ne(at, warm), same(fields, first)), Bool.and(Bool.or(U32.is_ne(at, 35), same(fields, last)), shape(~O, ~view, rest, U32.add(at, 1), warm, first, last))))

def check(~O: Data, ~view: O -> List<&2, F32>, result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, O>>>, warm: U32, first: List<&2, F32>, last: List<&2, F32>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: shape(~O, ~view, xs, 0, warm, first, last)

def exact.values(xs: List<&2, Maybe<&2, F32>>, ys: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case None{} <> rest None{} <> tail: exact.values(rest, tail)
    case Some{x} <> rest Some{y} <> tail: Bool.and(F32.is_eq(x, y), exact.values(rest, tail))
    case _ _: False{}

def exact(result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, F32>>>, expected: List<&2, Maybe<&2, F32>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: exact.values(xs, expected)

def all(xs: List<&2, Bool>) -> Bool:
  match xs:
    case Nil{}: True{}
    case x <> rest: Bool.and(x, all(rest))

def rejected(~S: Type, result: Result<&2, &1, TA.Momentum.Error(), S>) -> Bool:
  match result:
    case Fail{e}: True{}
    case Done{state}: False{}

def continued.result(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, rest: List<&2, I>, result: S & List<&2, Maybe<&2, O>>) -> List<&2, Maybe<&2, O>>:
  match result:
    case (state, values): List.append(&2, Maybe<&2, O>, values, Series.batch(~I, ~O, ~S, ~step, rest, state))

def continued(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, first: List<&2, I>, rest: List<&2, I>, result: Result<&2, &1, TA.Momentum.Error(), S>) -> Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, O>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{continued.result(~I, ~O, ~S, ~step, rest, Series.scan(~I, ~O, ~S, ~step, first, state))}

def prices() -> List<&2, F32>:
  [10.0, 11.0, 9.0, 12.0, 8.0, 13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]

def hl(+x: F32) -> Bar.HL<F32>:
  Bar.HL{F32.add(x, 2.0), F32.sub(x, 2.0)}

def hlc(+x: F32) -> Bar.HLC<F32>:
  Bar.HLC{F32.add(x, 2.0), F32.sub(x, 2.0), x}

def expected.talib_c_0_8_4_f64.sar() -> List<&2, Maybe<&2, F32>>:
  [None{}, Some{8.0}, Some{13.0}, Some{7.0}, Some{14.0},
   Some{6.0}, Some{6.0}, Some{6.18}, Some{6.5728}, Some{6.949888},
   Some{7.55289472}, Some{8.11972104}, Some{8.91014335}, Some{9.63733189}, Some{10.5735987},
   Some{11.41623883}, Some{12.0}, Some{12.96}, Some{13.0}, Some{14.0},
   Some{14.0}, Some{15.0}, Some{15.0}, Some{16.0}, Some{16.0},
   Some{17.0}, Some{17.0}, Some{18.0}, Some{18.0}, Some{19.0},
   Some{19.0}, Some{20.0}, Some{20.0}, Some{21.0}, Some{21.0},
   Some{22.0}]

def references() -> Bool:
  all([
    check(~F32, ~scalar, TA.FRAMA.batch(Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), prices()), 4), 4, [11.902464866638184], [15.895751953125]),
    check(~F32, ~scalar, TA.MCGD.batch(prices(), 4), 3, [9.93891429901123], [18.383743286132812]),
    Assert.batch(~TA.Momentum.Error(), ~F32, ~(a => b => close(a, b)), TA.SAR.batch(Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), prices()), 0.019999999552965164, 0.20000000298023224), expected.talib_c_0_8_4_f64.sar()),
    check(~F32, ~scalar, TA.SAREXT.batch(Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), prices()), 0.0, 0.029999999329447746, 0.019999999552965164, 0.029999999329447746, 0.20000000298023224, 0.03999999910593033, 0.019999999552965164, 0.30000001192092896), 1, [8.0], [22.0]),
    check(~TA.SUPERTREND.Value(), ~trend, TA.SUPERTREND.batch(Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), prices()), 4, 1.5), 4, [0.875, 1.0], [19.642927169799805, 1.0]),
    check(~F32, ~scalar, TA.CG.batch(prices(), 4), 3, [F32.sub(0.0, 2.452380895614624)], [F32.sub(0.0, 2.441176414489746)]),
    check(~F32, ~scalar, TA.CRSI.batch(prices(), 3, 2, 5), 6, [32.314292907714844], [64.44444274902344]),
    check(~F32, ~scalar, TA.CTI.batch(prices(), 4), 3, [0.4000000059604645], [0.650791347026825]),
    check(~TA.FISHER.Value(), ~lines, TA.FISHER.batch(Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), prices()), 4), 3, [0.34282824397087097, 0.0], [0.6301165819168091, 0.4172086715698242]),
    check(~TA.KSTEXT.Value(), ~lines, TA.KSTEXT.batch(prices(), 1, 2, 3, 4, 2, 3, 2, 4, 3, 1, 1), 9, [208.8278045654297, 148.0941925048828], [94.83035278320312, 77.7447280883789]),
    check(~TA.MACDEXT.Value(), ~macd, TA.MACDEXT.batch(prices(), 3, 1, 6, 1, 3, 1), 7, [0.8520408272743225, 0.49829933047294617, 0.35374149680137634], [1.0416580438613892, 0.8472078442573547, 0.19445018470287323]),
    check(~TA.SMI.Value(), ~lines, TA.SMI.batch(Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), prices()), 4, 2, 3, 2), 7, [25.85669708251953, 17.47380256652832], [24.2718448638916, 20.92665672302246]),
    check(~TA.SQZMOM.Value(), ~squeeze, TA.SQZMOM.batch(Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), prices()), 4, 2.0, 4, 2.0, 1.5, 1.0), 6, [0.0625, 3.0], [1.7999999523162842, 3.0]),
    check(~F32, ~scalar, TA.STC.batch(prices(), 3, 6, 4), 11, [100.0], [66.66390991210938]),
    check(~TA.WAVETREND.Value(), ~lines, TA.WAVETREND.batch(Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), prices()), 4, 3, 3), 10, [8.227673530578613, 21.920747756958008], [49.999996185302734, 36.11110305786133])
  ])

def invalids() -> Bool:
  Bool.and(all([
    rejected(~TA.FRAMA.State(), TA.FRAMA.init(3)),
    rejected(~TA.MCGD.State(), TA.MCGD.init(1)),
    rejected(~TA.SAR.State(), TA.SAR.init(F32.sub(0.0, 1.0), 0.2))
  ]), all([
    rejected(~TA.CRSI.State(), TA.CRSI.init(3, 2, 10001)),
    rejected(~TA.MACDEXT.State(), TA.MACDEXT.init(3, 11, 6, 1, 2, 1)),
    rejected(~TA.SQZMOM.State(), TA.SQZMOM.init(4, 2.0, 4, 1.0, 2.0, 1.0))
  ]))

def chunks() -> Bool:
  all([
    check(~F32, ~scalar, continued(~Bar.HL<F32>, ~F32, ~TA.FRAMA.State(), ~TA.FRAMA.next, Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), [10.0, 11.0, 9.0, 12.0, 8.0]), Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]), TA.FRAMA.init(4)), 4, [11.902464866638184], [15.895751953125]),
    check(~F32, ~scalar, continued(~Bar.HL<F32>, ~F32, ~TA.SAREXT.State(), ~TA.SAREXT.next, Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), [10.0, 11.0, 9.0, 12.0, 8.0]), Series.map(~F32, ~Bar.HL<F32>, ~(x => hl(x)), [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]), TA.SAREXT.init(0.0, 0.029999999329447746, 0.019999999552965164, 0.029999999329447746, 0.20000000298023224, 0.03999999910593033, 0.019999999552965164, 0.30000001192092896)), 1, [8.0], [22.0]),
    check(~F32, ~scalar, continued(~F32, ~F32, ~TA.CRSI.State(), ~TA.CRSI.next, [10.0, 11.0, 9.0, 12.0, 8.0], [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0], TA.CRSI.init(3, 2, 5)), 6, [32.314292907714844], [64.44444274902344]),
    check(~TA.SMI.Value(), ~lines, continued(~Bar.HLC<F32>, ~TA.SMI.Value(), ~TA.SMI.State(), ~TA.SMI.next, Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), [10.0, 11.0, 9.0, 12.0, 8.0]), Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]), TA.SMI.init(4, 2, 3, 2)), 7, [25.85669708251953, 17.47380256652832], [24.2718448638916, 20.92665672302246]),
    check(~TA.WAVETREND.Value(), ~lines, continued(~Bar.HLC<F32>, ~TA.WAVETREND.Value(), ~TA.WAVETREND.State(), ~TA.WAVETREND.next, Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), [10.0, 11.0, 9.0, 12.0, 8.0]), Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]), TA.WAVETREND.init(4, 3, 3)), 10, [8.227673530578613, 21.920747756958008], [49.999996185302734, 36.11110305786133]),
    check(~TA.SQZMOM.Value(), ~squeeze, continued(~Bar.HLC<F32>, ~TA.SQZMOM.Value(), ~TA.SQZMOM.State(), ~TA.SQZMOM.next, Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), [10.0, 11.0, 9.0, 12.0, 8.0]), Series.map(~F32, ~Bar.HLC<F32>, ~(x => hlc(x)), [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]), TA.SQZMOM.init(4, 2.0, 4, 2.0, 1.5, 1.0)), 6, [0.0625, 3.0], [1.7999999523162842, 3.0]),
    check(~F32, ~scalar, continued(~F32, ~F32, ~TA.STC.State(), ~TA.STC.next, [10.0, 11.0, 9.0, 12.0, 8.0], [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0], TA.STC.init(3, 6, 4)), 11, [100.0], [66.66390991210938]),
    check(~TA.MACDEXT.Value(), ~macd, continued(~F32, ~TA.MACDEXT.Value(), ~TA.MACDEXT.State(), ~TA.MACDEXT.next, [10.0, 11.0, 9.0, 12.0, 8.0], [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0], TA.MACDEXT.init(3, 1, 6, 1, 3, 1)), 7, [0.8520408272743225, 0.49829933047294617, 0.35374149680137634], [1.0416580438613892, 0.8472078442573547, 0.19445018470287323]),
    check(~TA.KSTEXT.Value(), ~lines, continued(~F32, ~TA.KSTEXT.Value(), ~TA.KSTEXT.State(), ~TA.KSTEXT.next, [10.0, 11.0, 9.0, 12.0, 8.0], [13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0], TA.KSTEXT.init(1, 2, 3, 4, 2, 3, 2, 4, 3, 1, 1)), 9, [208.8278045654297, 148.0941925048828], [94.83035278320312, 77.7447280883789])
  ])

def reversal_bars() -> List<&2, Bar.HL<F32>>:
  [Bar.HL{10.0, 8.0}, Bar.HL{11.0, 9.0}, Bar.HL{12.0, 10.0}, Bar.HL{10.0, 8.0},
   Bar.HL{9.0, 7.0}, Bar.HL{11.0, 9.0}, Bar.HL{12.0, 10.0}, Bar.HL{8.0, 6.0}]

def boundaries() -> Bool:
  all([
    exact(TA.SAR.batch(reversal_bars(), 0.0, 0.0),
      [None{}, Some{8.0}, Some{8.0}, Some{12.0}, Some{12.0}, Some{12.0}, Some{7.0}, Some{12.0}]),
    exact(TA.SAREXT.batch(reversal_bars(), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
      [None{}, Some{8.0}, Some{8.0}, Some{F32.sub(0.0, 12.0)}, Some{F32.sub(0.0, 12.0)}, Some{F32.sub(0.0, 12.0)}, Some{7.0}, Some{F32.sub(0.0, 12.0)}]),
    exact(TA.SAR.batch([Bar.HL{10.0, 8.0}, Bar.HL{11.0, 7.0}], 0.0, 0.0), [None{}, Some{11.0}]),
    exact(TA.CG.batch([1.0, F32.sub(0.0, 1.0), 2.0, F32.sub(0.0, 2.0)], 2),
      [None{}, Some{F32.sub(0.0, 1.5)}, Some{0.0}, Some{F32.sub(0.0, 1.5)}]),
    exact(TA.MCGD.batch([2.0, 0.0, 2.0, 0.0], 2), [None{}, Some{2.0}, Some{2.0}, Some{2.0}])
  ])

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("references", references())
    Unit <- Assert.check("invalids", invalids())
    Unit <- Assert.check("chunks", chunks())
    Assert.check("boundaries", boundaries())
