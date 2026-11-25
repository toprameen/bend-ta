import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/momentum_smooth.bend as Smooth
import ../../src/core/series.bend as Series

def close(+a: F32, +b: F32) -> Bool:
  F32.is_le(F32.abs(F32.sub(a, b)), F32.max(0.0001, F32.mul(F32.abs(b), 0.0001)))

def same(xs: List<&2, F32>, ys: List<&2, F32>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case a <> at b <> bt: Bool.and(close(a, b), same(at, bt))
    case _ _: False{}

def scalar(x: F32) -> List<&2, F32>:
  [x]

def macd(x: TA.MACD.Value()) -> List<&2, F32>:
  match x:
    case Smooth.MACDValue{a, b, c}: [a, b, c]

def stoch(x: TA.STOCH.Value()) -> List<&2, F32>:
  +x = x
  [TA.STOCH.k(x), TA.STOCH.d(x), TA.STOCH.j(x)]

def lines(x: TA.Lines.Value()) -> List<&2, F32>:
  +x = x
  [TA.Lines.first(x), TA.Lines.second(x)]

def aroon(x: TA.AROON.Value()) -> List<&2, F32>:
  +x = x
  [TA.AROON.down(x), TA.AROON.up(x)]

def vortex(x: TA.VORTEX.Value()) -> List<&2, F32>:
  +x = x
  [TA.VORTEX.plus(x), TA.VORTEX.minus(x)]

def shape(~O: Data, ~view: O -> List<&2, F32>, xs: List<&2, Maybe<&2, O>>, +at: U32, +length: U32, +warm: U32, +first: List<&2, F32>, +last: List<&2, F32>) -> Bool:
  match xs:
    case Nil{}: U32.is_eq(at, length)
    case None{} <> rest: Bool.and(U32.is_lt(at, warm), shape(~O, ~view, rest, U32.add(at, 1), length, warm, first, last))
    case Some{value} <> rest:
      +fields = view(value)
      Bool.and(U32.is_ge(at, warm), Bool.and(Bool.or(U32.is_ne(at, warm), same(fields, first)), Bool.and(Bool.or(U32.is_ne(U32.add(at, 1), length), same(fields, last)), shape(~O, ~view, rest, U32.add(at, 1), length, warm, first, last))))

def check(~O: Data, ~view: O -> List<&2, F32>, result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, O>>>, length: U32, warm: U32, first: List<&2, F32>, last: List<&2, F32>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: shape(~O, ~view, xs, 0, length, warm, first, last)

def rejected(~S: Type, result: Result<&2, &1, TA.Momentum.Error(), S>) -> Bool:
  match result:
    case Fail{e}: True{}
    case Done{state}: False{}

def all(xs: List<&2, Bool>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(h, all(t))

def continued.result(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, rest: List<&2, I>, result: S & List<&2, Maybe<&2, O>>) -> List<&2, Maybe<&2, O>>:
  match result:
    case (state, values): List.append(&2, Maybe<&2, O>, values, Series.batch(~I, ~O, ~S, ~step, rest, state))

def continued(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, first: List<&2, I>, rest: List<&2, I>, result: Result<&2, &1, TA.Momentum.Error(), S>) -> Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, O>>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{state}: Done{continued.result(~I, ~O, ~S, ~step, rest, Series.scan(~I, ~O, ~S, ~step, first, state))}

def data.F32() -> List<&2, F32>:
  [10.0, 11.0, 9.0, 12.0, 8.0, 13.0, 10.0, 14.0, 11.0, 15.0, 12.0, 16.0, 13.0, 17.0, 14.0, 18.0, 15.0, 19.0, 16.0, 20.0, 17.0, 21.0, 18.0, 22.0, 19.0, 23.0, 20.0, 24.0, 21.0, 25.0, 22.0, 26.0, 23.0, 27.0, 24.0, 28.0]

def data.HL() -> List<&2, Bar.HL<F32>>:
  [Bar.HL{12.0, 8.0}, Bar.HL{13.0, 9.0}, Bar.HL{11.0, 7.0}, Bar.HL{14.0, 10.0}, Bar.HL{10.0, 6.0}, Bar.HL{15.0, 11.0}, Bar.HL{12.0, 8.0}, Bar.HL{16.0, 12.0}, Bar.HL{13.0, 9.0}, Bar.HL{17.0, 13.0}, Bar.HL{14.0, 10.0}, Bar.HL{18.0, 14.0}, Bar.HL{15.0, 11.0}, Bar.HL{19.0, 15.0}, Bar.HL{16.0, 12.0}, Bar.HL{20.0, 16.0}, Bar.HL{17.0, 13.0}, Bar.HL{21.0, 17.0}, Bar.HL{18.0, 14.0}, Bar.HL{22.0, 18.0}, Bar.HL{19.0, 15.0}, Bar.HL{23.0, 19.0}, Bar.HL{20.0, 16.0}, Bar.HL{24.0, 20.0}, Bar.HL{21.0, 17.0}, Bar.HL{25.0, 21.0}, Bar.HL{22.0, 18.0}, Bar.HL{26.0, 22.0}, Bar.HL{23.0, 19.0}, Bar.HL{27.0, 23.0}, Bar.HL{24.0, 20.0}, Bar.HL{28.0, 24.0}, Bar.HL{25.0, 21.0}, Bar.HL{29.0, 25.0}, Bar.HL{26.0, 22.0}, Bar.HL{30.0, 26.0}]

def data.HLC() -> List<&2, Bar.HLC<F32>>:
  [Bar.HLC{12.0, 8.0, 10.0}, Bar.HLC{13.0, 9.0, 11.0}, Bar.HLC{11.0, 7.0, 9.0}, Bar.HLC{14.0, 10.0, 12.0}, Bar.HLC{10.0, 6.0, 8.0}, Bar.HLC{15.0, 11.0, 13.0}, Bar.HLC{12.0, 8.0, 10.0}, Bar.HLC{16.0, 12.0, 14.0}, Bar.HLC{13.0, 9.0, 11.0}, Bar.HLC{17.0, 13.0, 15.0}, Bar.HLC{14.0, 10.0, 12.0}, Bar.HLC{18.0, 14.0, 16.0}, Bar.HLC{15.0, 11.0, 13.0}, Bar.HLC{19.0, 15.0, 17.0}, Bar.HLC{16.0, 12.0, 14.0}, Bar.HLC{20.0, 16.0, 18.0}, Bar.HLC{17.0, 13.0, 15.0}, Bar.HLC{21.0, 17.0, 19.0}, Bar.HLC{18.0, 14.0, 16.0}, Bar.HLC{22.0, 18.0, 20.0}, Bar.HLC{19.0, 15.0, 17.0}, Bar.HLC{23.0, 19.0, 21.0}, Bar.HLC{20.0, 16.0, 18.0}, Bar.HLC{24.0, 20.0, 22.0}, Bar.HLC{21.0, 17.0, 19.0}, Bar.HLC{25.0, 21.0, 23.0}, Bar.HLC{22.0, 18.0, 20.0}, Bar.HLC{26.0, 22.0, 24.0}, Bar.HLC{23.0, 19.0, 21.0}, Bar.HLC{27.0, 23.0, 25.0}, Bar.HLC{24.0, 20.0, 22.0}, Bar.HLC{28.0, 24.0, 26.0}, Bar.HLC{25.0, 21.0, 23.0}, Bar.HLC{29.0, 25.0, 27.0}, Bar.HLC{26.0, 22.0, 24.0}, Bar.HLC{30.0, 26.0, 28.0}]

def data.OHLC() -> List<&2, Bar.OHLC<F32>>:
  [Bar.OHLC{9.0, 12.0, 8.0, 10.0}, Bar.OHLC{12.0, 13.0, 9.0, 11.0}, Bar.OHLC{8.0, 11.0, 7.0, 9.0}, Bar.OHLC{13.0, 14.0, 10.0, 12.0}, Bar.OHLC{7.0, 10.0, 6.0, 8.0}, Bar.OHLC{14.0, 15.0, 11.0, 13.0}, Bar.OHLC{9.0, 12.0, 8.0, 10.0}, Bar.OHLC{15.0, 16.0, 12.0, 14.0}, Bar.OHLC{10.0, 13.0, 9.0, 11.0}, Bar.OHLC{16.0, 17.0, 13.0, 15.0}, Bar.OHLC{11.0, 14.0, 10.0, 12.0}, Bar.OHLC{17.0, 18.0, 14.0, 16.0}, Bar.OHLC{12.0, 15.0, 11.0, 13.0}, Bar.OHLC{18.0, 19.0, 15.0, 17.0}, Bar.OHLC{13.0, 16.0, 12.0, 14.0}, Bar.OHLC{19.0, 20.0, 16.0, 18.0}, Bar.OHLC{14.0, 17.0, 13.0, 15.0}, Bar.OHLC{20.0, 21.0, 17.0, 19.0}, Bar.OHLC{15.0, 18.0, 14.0, 16.0}, Bar.OHLC{21.0, 22.0, 18.0, 20.0}, Bar.OHLC{16.0, 19.0, 15.0, 17.0}, Bar.OHLC{22.0, 23.0, 19.0, 21.0}, Bar.OHLC{17.0, 20.0, 16.0, 18.0}, Bar.OHLC{23.0, 24.0, 20.0, 22.0}, Bar.OHLC{18.0, 21.0, 17.0, 19.0}, Bar.OHLC{24.0, 25.0, 21.0, 23.0}, Bar.OHLC{19.0, 22.0, 18.0, 20.0}, Bar.OHLC{25.0, 26.0, 22.0, 24.0}, Bar.OHLC{20.0, 23.0, 19.0, 21.0}, Bar.OHLC{26.0, 27.0, 23.0, 25.0}, Bar.OHLC{21.0, 24.0, 20.0, 22.0}, Bar.OHLC{27.0, 28.0, 24.0, 26.0}, Bar.OHLC{22.0, 25.0, 21.0, 23.0}, Bar.OHLC{28.0, 29.0, 25.0, 27.0}, Bar.OHLC{23.0, 26.0, 22.0, 24.0}, Bar.OHLC{29.0, 30.0, 26.0, 28.0}]

def data.HLCV() -> List<&2, Bar.HLCV<F32>>:
  [Bar.HLCV{12.0, 8.0, 10.0, 1.0}, Bar.HLCV{13.0, 9.0, 11.0, 2.0}, Bar.HLCV{11.0, 7.0, 9.0, 3.0}, Bar.HLCV{14.0, 10.0, 12.0, 4.0}, Bar.HLCV{10.0, 6.0, 8.0, 1.0}, Bar.HLCV{15.0, 11.0, 13.0, 2.0}, Bar.HLCV{12.0, 8.0, 10.0, 3.0}, Bar.HLCV{16.0, 12.0, 14.0, 4.0}, Bar.HLCV{13.0, 9.0, 11.0, 1.0}, Bar.HLCV{17.0, 13.0, 15.0, 2.0}, Bar.HLCV{14.0, 10.0, 12.0, 3.0}, Bar.HLCV{18.0, 14.0, 16.0, 4.0}, Bar.HLCV{15.0, 11.0, 13.0, 1.0}, Bar.HLCV{19.0, 15.0, 17.0, 2.0}, Bar.HLCV{16.0, 12.0, 14.0, 3.0}, Bar.HLCV{20.0, 16.0, 18.0, 4.0}, Bar.HLCV{17.0, 13.0, 15.0, 1.0}, Bar.HLCV{21.0, 17.0, 19.0, 2.0}, Bar.HLCV{18.0, 14.0, 16.0, 3.0}, Bar.HLCV{22.0, 18.0, 20.0, 4.0}, Bar.HLCV{19.0, 15.0, 17.0, 1.0}, Bar.HLCV{23.0, 19.0, 21.0, 2.0}, Bar.HLCV{20.0, 16.0, 18.0, 3.0}, Bar.HLCV{24.0, 20.0, 22.0, 4.0}, Bar.HLCV{21.0, 17.0, 19.0, 1.0}, Bar.HLCV{25.0, 21.0, 23.0, 2.0}, Bar.HLCV{22.0, 18.0, 20.0, 3.0}, Bar.HLCV{26.0, 22.0, 24.0, 4.0}, Bar.HLCV{23.0, 19.0, 21.0, 1.0}, Bar.HLCV{27.0, 23.0, 25.0, 2.0}, Bar.HLCV{24.0, 20.0, 22.0, 3.0}, Bar.HLCV{28.0, 24.0, 26.0, 4.0}, Bar.HLCV{25.0, 21.0, 23.0, 1.0}, Bar.HLCV{29.0, 25.0, 27.0, 2.0}, Bar.HLCV{26.0, 22.0, 24.0, 3.0}, Bar.HLCV{30.0, 26.0, 28.0, 4.0}]

def reference.group1() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.AC.batch(data.HL(), 2, 4, 3), 36, 5, [0.0], [0.0]),
    check(~F32, ~scalar, TA.ADX.batch(data.HLC(), 3), 36, 5, [38.0274656679151], [22.353113831584167]),
    check(~F32, ~scalar, TA.ADXR.batch(data.HLC(), 3), 36, 7, [33.944921563842094], [22.35321496939264]),
    check(~F32, ~scalar, TA.AO.batch(data.HL(), 2, 4), 36, 3, [0.0], [0.5])
  ]
  all(checks)

def reference.group2() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.APO.batch(data.F32(), 2, 4, 1), 36, 3, [0.6666666666666661], [0.937500008290268]),
    check(~TA.AROON.Value(), ~aroon, TA.AROON.batch(data.HL(), 3), 36, 3, [66.66666666666667, 100.0], [0.0, 100.0]),
    check(~F32, ~scalar, TA.AROONOSC.batch(data.HL(), 3), 36, 3, [33.333333333333336], [100.0]),
    check(~F32, ~scalar, TA.ASI.batch(data.OHLC(), 3.0), 36, 0, [0.0], [402.3107641225827])
  ]
  all(checks)

def reference.group3() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.CCI.batch(data.HLC(), 3), 36, 2, [F32.neg(100.00000000000001)], [71.42857142857146]),
    check(~F32, ~scalar, TA.CHOP.batch(data.HLC(), 3), 36, 3, [56.34737703113705], [68.61126624481936]),
    check(~F32, ~scalar, TA.CHOPTR.batch(data.HLC(), 3), 36, 3, [56.34737703113705], [68.61126624481936]),
    check(~F32, ~scalar, TA.CMO.batch(data.F32(), 3), 36, 3, [33.33333333333333], [33.33332260268265])
  ]
  all(checks)

def reference.group4() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.CMOU.batch(data.F32(), 3), 36, 3, [33.333333333333336], [45.45454545454545]),
    check(~F32, ~scalar, TA.COPPOCK.batch(data.F32(), 3, 2, 4), 36, 6, [21.70875420875421], [12.15194306498654]),
    check(~F32, ~scalar, TA.DOSC.batch(data.F32(), 3, 2, 3, 2), 36, 7, [1.8338889306631287], [1.6339925650386533]),
    check(~F32, ~scalar, TA.DX.batch(data.HLC(), 3), 36, 3, [46.666666666666664], [33.33333691021765])
  ]
  all(checks)

def reference.group5() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.ER.batch(data.F32(), 3), 36, 3, [0.3333333333333333], [0.45454545454545453]),
    check(~TA.ERI.Value(), ~lines, TA.ERI.batch(data.HLC(), 3), 36, 2, [1.0, F32.neg(3.0)], [3.666666666744277, F32.neg(0.3333333332557231)]),
    check(~F32, ~scalar, TA.FOSC.batch(data.F32(), 3), 36, 3, [25.0], [8.333333333333329]),
    check(~F32, ~scalar, TA.IMI.batch(data.OHLC(), 3), 36, 2, [66.66666666666666], [33.33333333333333])
  ]
  all(checks)

def expected.talib_c_0_8_4_f64.macd() -> List<&2, Maybe<&2, TA.MACD.Value()>>:
  [None{}, None{},
   None{}, None{},
   None{}, Some{Smooth.MACDValue{0.71111111, 0.01481481, 0.6962963}},
   Some{Smooth.MACDValue{F32.neg(0.00296296), 0.00592593, F32.neg(0.00888889)}}, Some{Smooth.MACDValue{0.92167901, 0.46380247, 0.45787654}},
   Some{Smooth.MACDValue{0.06082634, 0.2623144, F32.neg(0.20148807)}}, Some{Smooth.MACDValue{0.93910211, 0.60070826, 0.33839385}},
   Some{Smooth.MACDValue{0.06433004, 0.33251915, F32.neg(0.26818911)}}, Some{Smooth.MACDValue{0.93888761, 0.63570338, 0.30318423}},
   Some{Smooth.MACDValue{0.0634291, 0.34956624, F32.neg(0.28613714)}}, Some{Smooth.MACDValue{0.93808964, 0.64382794, 0.2942617}},
   Some{Smooth.MACDValue{0.06286451, 0.35334622, F32.neg(0.29048172)}}, Some{Smooth.MACDValue{0.93772228, 0.64553425, 0.29218803}},
   Some{Smooth.MACDValue{0.06263456, 0.3540844, F32.neg(0.29144985)}}, Some{Smooth.MACDValue{0.93758113, 0.64583277, 0.29174836}},
   Some{Smooth.MACDValue{0.06254881, 0.35419079, F32.neg(0.29164198)}}, Some{Smooth.MACDValue{0.93752933, 0.64586006, 0.29166927}},
   Some{Smooth.MACDValue{0.06251761, 0.35418884, F32.neg(0.29167122)}}, Some{Smooth.MACDValue{0.93751057, 0.64584971, 0.29166087}},
   Some{Smooth.MACDValue{0.06250635, 0.35417803, F32.neg(0.29167168)}}, Some{Smooth.MACDValue{0.93750381, 0.64584092, 0.29166289}},
   Some{Smooth.MACDValue{0.06250228, 0.3541716, F32.neg(0.29166932)}}, Some{Smooth.MACDValue{0.93750137, 0.64583649, 0.29166489}},
   Some{Smooth.MACDValue{0.06250082, 0.35416865, F32.neg(0.29166783)}}, Some{Smooth.MACDValue{0.93750049, 0.64583457, 0.29166592}},
   Some{Smooth.MACDValue{0.0625003, 0.35416744, F32.neg(0.29166714)}}, Some{Smooth.MACDValue{0.93750018, 0.64583381, 0.29166637}},
   Some{Smooth.MACDValue{0.06250011, 0.35416696, F32.neg(0.29166685)}}, Some{Smooth.MACDValue{0.93750006, 0.64583351, 0.29166655}},
   Some{Smooth.MACDValue{0.06250004, 0.35416677, F32.neg(0.29166674)}}, Some{Smooth.MACDValue{0.93750002, 0.6458334, 0.29166662}},
   Some{Smooth.MACDValue{0.06250001, 0.35416671, F32.neg(0.29166669)}}, Some{Smooth.MACDValue{0.93750001, 0.64583336, 0.29166665}}]

def reference.group6() -> Bool:
  +checks : List<&2, Bool> = [
    check(~TA.STOCH.Value(), ~stoch, TA.KDJ.batch(data.HLC(), 3, 2, 0, 2, 0), 36, 4, [48.214285714285715, 50.29761904761905, 44.04761904761904], [56.25, 56.25, 56.25]),
    check(~TA.KST.Value(), ~lines, TA.KST.batch(data.F32(), 1, 2, 3, 4, 2, 3, 2, 3, 2), 36, 7, [184.5914270914271, 136.58750971250973], [64.82409002698859, 67.2479410015642]),
    Assert.batch(~TA.Momentum.Error(), ~TA.MACD.Value(), ~(a => b => same(macd(a), macd(b))), TA.MACD.batch(data.F32(), 2, 4, 3), expected.talib_c_0_8_4_f64.macd()),
    check(~TA.MACD.Value(), ~macd, TA.MACDFIX.batch(data.F32(), 2), 36, 26, [3.243269230769233, 3.313942307692309, F32.neg(0.07067307692307612)], [3.412083551563814, 3.3748148182178643, 0.03726873334594982])
  ]
  all(checks)

def reference.group7() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.MFI.batch(data.HLCV(), 3), 36, 3, [72.16494845360825], [69.74789915966386]),
    check(~F32, ~scalar, TA.MINUS_DI.batch(data.HLC(), 3), 36, 3, [12.903225806451612], [21.428568882778926]),
    check(~F32, ~scalar, TA.MINUS_DM.batch(data.HL(), 3), 36, 2, [2.0], [3.59999822300465]),
    check(~F32, ~scalar, TA.PLUS_DI.batch(data.HLC(), 3), 36, 3, [35.483870967741936], [42.85714121469608])
  ]
  all(checks)

def reference.group8() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.PLUS_DM.batch(data.HL(), 3), 36, 2, [1.0], [7.199997025464305]),
    check(~F32, ~scalar, TA.PPO.batch(data.F32(), 2, 4, 1), 36, 3, [6.3492063492063435], [3.614457864443051]),
    check(~F32, ~scalar, TA.PSO.batch(data.HLC(), 3, 2), 36, 4, [F32.neg(0.32506623897304265)], [0.4981744262294963]),
    check(~F32, ~scalar, TA.QSTICK.batch(data.OHLC(), 3), 36, 2, [0.3333333333333333], [F32.neg(0.3333333333333333)])
  ]
  all(checks)

def reference.group9() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.SI.batch(data.OHLC(), 3.0), 36, 1, [8.823529411764707], [71.42857142857143]),
    check(~TA.STOCH.Value(), ~stoch, TA.STOCH.batch(data.HLC(), 3, 2, 0, 2, 0), 36, 4, [48.214285714285715, 50.29761904761905, 44.04761904761904], [56.25, 56.25, 56.25]),
    check(~TA.STOCH.Value(), ~stoch, TA.STOCHF.batch(data.HLC(), 3, 2, 0), 36, 3, [71.42857142857143, 52.38095238095238, 109.52380952380952], [75.0, 56.25, 112.5]),
    check(~TA.STOCH.Value(), ~stoch, TA.STOCHRSI.batch(data.F32(), 3, 3, 2, 0), 36, 6, [38.31460674157305, 67.54440014498009, F32.neg(20.144980065241015)], [100.0, 50.00004953062065, 199.99990093875869])
  ]
  all(checks)

def reference.group10() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.TRIX.batch(data.F32(), 3), 36, 7, [4.64002642007928], [2.6033690829511125]),
    check(~F32, ~scalar, TA.TSI.batch(data.F32(), 3, 2), 36, 4, [F32.neg(20.0)], [30.232558134296518]),
    check(~F32, ~scalar, TA.ULTOSC.batch(data.HLC(), 2, 3, 5), 36, 5, [54.33455433455433], [56.13881916402924]),
    check(~F32, ~scalar, TA.VHF.batch(data.F32(), 3), 36, 3, [0.5], [0.36363636363636365])
  ]
  all(checks)

def expected.talib_c_0_8_4_f64.rsi() -> List<&2, Maybe<&2, F32>>:
  [None{}, None{}, None{}, Some{66.66666667}, Some{33.33333333},
   Some{65.59139785}, Some{45.6928839}, Some{66.2004662}, Some{46.46216769}, Some{66.46169613},
   Some{46.79565237}, Some{66.57600227}, Some{46.94225112}, Some{66.62645644}, Some{47.00709074},
   Some{66.64881221}, Some{47.03584639}, Some{66.65873466}, Some{47.04861447}, Some{66.66314198},
   Some{47.05428676}, Some{66.66510027}, Some{47.05680731}, Some{66.66597052}, Some{47.05792745},
   Some{66.66635727}, Some{47.05842528}, Some{66.66652916}, Some{47.05864653}, Some{66.66660555},
   Some{47.05874486}, Some{66.6666395}, Some{47.05878857}, Some{66.66665459}, Some{47.05880799},
   Some{66.6666613}]

def reference.group11() -> Bool:
  +checks : List<&2, Bool> = [
    check(~TA.VORTEX.Value(), ~vortex, TA.VORTEX.batch(data.HLC(), 3), 36, 3, [1.0769230769230769, 0.7692307692307693], [1.0, 0.4117647058823529]),
    check(~F32, ~scalar, TA.WAD.batch(data.HLC()), 36, 0, [0.0], [19.0]),
    check(~F32, ~scalar, TA.WILLR.batch(data.HLC(), 3), 36, 2, [F32.neg(66.66666666666666)], [F32.neg(25.0)]),
    Assert.batch(~TA.Momentum.Error(), ~F32, ~(a => b => close(a, b)), TA.RSI.batch(data.F32(), 3), expected.talib_c_0_8_4_f64.rsi())
  ]
  all(checks)

def reference() -> Bool:
  all([reference.group1(), reference.group2(), reference.group3(), reference.group4(), reference.group5(), reference.group6(), reference.group7(), reference.group8(), reference.group9(), reference.group10(), reference.group11()])

def edges.group1() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.RSI.batch([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], 3), 7, 3, [50.0], [50.0]),
    check(~F32, ~scalar, TA.CMO.batch([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], 3), 7, 3, [0.0], [0.0]),
    check(~F32, ~scalar, TA.CMOU.batch([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], 3), 7, 3, [0.0], [0.0]),
    check(~F32, ~scalar, TA.ER.batch([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], 3), 7, 3, [1.0], [1.0])
  ]
  all(checks)

def edges.group2() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.VHF.batch([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], 3), 7, 3, [0.0], [0.0]),
    check(~F32, ~scalar, TA.CMOU.batch([2.0, 8.0, 8.0, 8.0, 8.0, 8.0], 2), 6, 2, [100.0], [0.0]),
    check(~TA.AROON.Value(), ~aroon, TA.AROON.batch([Bar.HL{5.0, 1.0}, Bar.HL{4.0, 2.0}, Bar.HL{3.0, 3.0}, Bar.HL{2.0, 1.0}], 3), 4, 3, [100.0, 0.0], [100.0, 0.0]),
    check(~TA.AROON.Value(), ~aroon, TA.AROON.batch([Bar.HL{5.0, 1.0}, Bar.HL{4.0, 2.0}, Bar.HL{5.0, 1.0}, Bar.HL{5.0, 1.0}], 3), 4, 3, [100.0, 100.0], [100.0, 100.0])
  ]
  all(checks)

def edges.group3() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.IMI.batch([Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}], 2), 4, 1, [50.0], [50.0]),
    check(~F32, ~scalar, TA.SI.batch([Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}], 3.0), 4, 1, [0.0], [0.0]),
    check(~F32, ~scalar, TA.ASI.batch([Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}, Bar.OHLC{2.0, 2.0, 2.0, 2.0}], 3.0), 4, 0, [0.0], [0.0]),
    check(~F32, ~scalar, TA.CHOP.batch([Bar.HLC{101.0, 100.0, 100.0}, Bar.HLC{2.0, 1.0, 1.0}, Bar.HLC{2.0, 1.0, 1.0}, Bar.HLC{2.0, 1.0, 1.0}], 2), 4, 2, [664.3856189774724], [100.0])
  ]
  all(checks)

def edges.group4() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.CHOPTR.batch([Bar.HLC{101.0, 100.0, 100.0}, Bar.HLC{2.0, 1.0, 1.0}, Bar.HLC{2.0, 1.0, 1.0}, Bar.HLC{2.0, 1.0, 1.0}], 2), 4, 2, [1.4499569695115169], [100.0]),
    check(~F32, ~scalar, TA.PPO.batch([1.0e-16, 2.0e-16, 3.0e-16, 4.0e-16, 5.0e-16], 2, 3, 1), 5, 2, [0.0], [0.0]),
    check(~F32, ~scalar, TA.PPO.batch([0.0, 9.9999998245167e-15, 1.99999996490334e-14, 2.99999994735501e-14, 3.99999992980668e-14, 4.99999991225835e-14, 5.99999989471002e-14, 6.999999538348511e-14], 2, 3, 0), 8, 2, [0.0], [8.333332549043531]),
    check(~F32, ~scalar, TA.CCI.batch([Bar.HLC{1000001.25, 1000000.25, 1000000.75}, Bar.HLC{1000001.5, 1000000.5, 1000001.0}, Bar.HLC{1000001.0, 1000000.0, 1000000.5}, Bar.HLC{1000001.75, 1000000.75, 1000001.25}], 3), 4, 2, [F32.neg(100.00000000000001)], [80.00000000558794])
  ]
  all(checks)

def edges.group5() -> Bool:
  +checks : List<&2, Bool> = [
    check(~TA.STOCH.Value(), ~stoch, TA.STOCHRSI.batch([10.0, 11.303667068481445, 11.977303504943848, 11.695355415344238, 10.594082832336426, 9.205703735351562, 8.201189041137695, 8.065997123718262, 8.865463256835938, 10.213223457336426, 11.457938194274902, 11.998065948486328, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0], 3, 3, 2, 0), 75, 6, [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]),
    check(~F32, ~scalar, TA.PLUS_DI.batch([Bar.HLC{4.0, 2.0, 3.0}, Bar.HLC{6.0, 3.0, 5.0}, Bar.HLC{7.0, 4.0, 6.0}], 1), 3, 1, [0.6666666666666666], [0.3333333333333333]),
    check(~F32, ~scalar, TA.PLUS_DM.batch([Bar.HL{4.0, 2.0}, Bar.HL{5.0, 1.0}, Bar.HL{6.0, 0.0}], 2), 3, 1, [0.0], [0.0]),
    rejected(~TA.RSI.State(), TA.RSI.init(1))
  ]
  all(checks)

def edges.group6() -> Bool:
  +checks : List<&2, Bool> = [
    rejected(~TA.CMOU.State(), TA.CMOU.init(0)),
    rejected(~TA.ADX.State(), TA.ADX.init(100001)),
    rejected(~TA.SI.State(), TA.SI.init(0.0)),
    rejected(~TA.MACD.State(), TA.MACD.init(2, 3, 0))
  ]
  all(checks)

def edges.group7() -> Bool:
  +checks : List<&2, Bool> = [
    rejected(~TA.APO.State(), TA.APO.init(2, 3, 11)),
    rejected(~TA.STOCH.State(), TA.STOCH.init(3, 2, 11, 2, 0)),
    rejected(~TA.TSI.State(), TA.TSI.init(2, 1)),
    rejected(~TA.KST.State(), TA.KST.init(1, 2, 3, 4, 2, 2, 2, 0, 1))
  ]
  all(checks)

def edges.group8() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, TA.RSI.batch([], 3), 0, 0, [], []),
    check(~F32, ~scalar, TA.RSI.batch([1.0, 2.0], 3), 2, 2, [], [])
  ]
  all(checks)

def edges.invalid_selector() -> Bool:
  rejected(~TA.STOCHF.State(), TA.STOCHF.init(1, 1, 16))

def edges() -> Bool:
  all([edges.group1(), edges.group2(), edges.group3(), edges.group4(), edges.group5(), edges.group6(), edges.group7(), edges.group8(), edges.invalid_selector()])

def chunks.group1() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, continued(~F32, ~F32, ~TA.RSI.State(), ~TA.RSI.next, List.take(&2, F32, data.F32(), 5n), List.drop(&2, F32, data.F32(), 5n), TA.RSI.init(3)), 36, 3, [66.66666666666666], [66.66666130134134]),
    check(~TA.MACD.Value(), ~macd, continued(~F32, ~TA.MACD.Value(), ~TA.MACD.State(), ~TA.MACD.next, List.take(&2, F32, data.F32(), 5n), List.drop(&2, F32, data.F32(), 5n), TA.MACD.init(2, 4, 3)), 36, 5, [0.7111111111111121, 0.014814814814815355, 0.6962962962962967], [0.937500008290268, 0.6458333572659269, 0.2916666510243411])
  ]
  all(checks)

def chunks.group2() -> Bool:
  +checks : List<&2, Bool> = [
    check(~F32, ~scalar, continued(~Bar.HLC<F32>, ~F32, ~TA.CCI.State(), ~TA.CCI.next, List.take(&2, Bar.HLC<F32>, data.HLC(), 5n), List.drop(&2, Bar.HLC<F32>, data.HLC(), 5n), TA.CCI.init(3)), 36, 2, [F32.neg(100.00000000000001)], [71.42857142857146]),
    check(~TA.KST.Value(), ~lines, continued(~F32, ~TA.KST.Value(), ~TA.KST.State(), ~TA.KST.next, List.take(&2, F32, data.F32(), 5n), List.drop(&2, F32, data.F32(), 5n), TA.KST.init(1, 2, 3, 4, 2, 3, 2, 3, 2)), 36, 7, [184.5914270914271, 136.58750971250973], [64.82409002698859, 67.2479410015642])
  ]
  all(checks)

def chunks.group3() -> Bool:
  +checks : List<&2, Bool> = [
    check(~TA.STOCH.Value(), ~stoch, continued(~Bar.HLC<F32>, ~TA.STOCH.Value(), ~TA.STOCH.State(), ~TA.STOCH.next, List.take(&2, Bar.HLC<F32>, data.HLC(), 5n), List.drop(&2, Bar.HLC<F32>, data.HLC(), 5n), TA.STOCH.init(3, 2, 0, 2, 0)), 36, 4, [48.214285714285715, 50.29761904761905, 44.04761904761904], [56.25, 56.25, 56.25]),
    check(~F32, ~scalar, continued(~Bar.HLC<F32>, ~F32, ~TA.ADXR.State(), ~TA.ADXR.next, List.take(&2, Bar.HLC<F32>, data.HLC(), 5n), List.drop(&2, Bar.HLC<F32>, data.HLC(), 5n), TA.ADXR.init(3)), 36, 7, [33.944921563842094], [22.35321496939264])
  ]
  all(checks)

def chunks() -> Bool:
  all([chunks.group1(), chunks.group2(), chunks.group3()])

def aroonosc.history.collect(n: Nat, acc: List<&2, Bar.HL<F32>>) -> List<&2, Bar.HL<F32>>:
  match n:
    case 0n: acc
    case 1n+rest: aroonosc.history.collect(rest, Bar.HL{50.0, 50.0} <> acc)

def aroonosc.history(n: Nat) -> List<&2, Bar.HL<F32>>:
  aroonosc.history.collect(n, [Bar.HL{100.0, 25.0}, Bar.HL{75.0, 0.0}])

def aroonosc.tail(xs: List<&2, Maybe<&2, F32>>) -> Bool:
  match xs:
    case None{} <> rest: aroonosc.tail(rest)
    case Some{x} <> Nil{}: F32.is_lt(F32.abs(F32.add(x, 0.01)), 0.0000001)
    case _: False{}

def aroonosc.precise(result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, F32>>>) -> Bool:
  match result:
    case Fail{e}: False{}
    case Done{xs}: aroonosc.tail(xs)

def alternating(~O: Data, ~read: O -> F32, +up: F32, +down: F32, +tolerance: F32, result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, O>>>) -> Bool:
  match result:
    case Done{_ <> _ <> _ <> Some{a} <> Some{b} <> Some{c} <> Some{d} <> Nil{}}:
      all([F32.is_le(F32.abs(F32.sub(read(a), up)), tolerance), F32.is_le(F32.abs(F32.sub(read(b), down)), tolerance),
               F32.is_le(F32.abs(F32.sub(read(c), up)), tolerance), F32.is_le(F32.abs(F32.sub(read(d), down)), tolerance)])
    case _: False{}

def falling_line(value: Maybe<&2, TA.MACD.Value()>) -> Bool:
  match value:
    case None{}: False{}
    case Some{line}: F32.is_lt(TA.MACD.line(line), 0.0)

def alma_drop(result: Result<&2, &2, TA.Momentum.Error(), List<&2, Maybe<&2, TA.MACD.Value()>>>) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{values}: List.any(~&2, ~Maybe<&2, TA.MACD.Value()>, ~falling_line, values)

def main() -> IO(Unit):
  +prices : List<&2, F32> = [40000000.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0]
  drop = List.append(&2, F32, List.replicate(F32, 4274n, 1000000.0), [500000.0])
  +spread = F32.div(1.0, 6.0)
  do IO<Unit>:
    Unit <- Assert.check("ALMA spread on flat prices", Assert.batch(~TA.Momentum.Error(), ~F32, ~F32.is_eq,
      TA.APO.batch([100.0, 100.0, 100.0, 100.0], 2, 3, TA.MA.Kind.ALMA()), [None{}, None{}, Some{0.0}, Some{0.0}]))
    Unit <- Assert.check("ALMA MACDEXT turns negative after a drop", alma_drop(
      TA.MACDEXT.batch(drop, 4250, TA.MA.Kind.ALMA(), 4275, TA.MA.Kind.ALMA(), 1, TA.MA.Kind.SMA())))
    Unit <- Assert.check("APO after outlier", alternating(~F32, ~(x => x), spread, F32.neg(spread), 0.000002, TA.APO.batch(prices, 2, 3, 0)))
    Unit <- Assert.check("MACDEXT after outlier", alternating(~TA.MACDEXT.Value(), ~TA.MACD.line, spread, F32.neg(spread), 0.000002, TA.MACDEXT.batch(prices, 2, 0, 3, 0, 1, 0)))
    Unit <- Assert.check("PPO after outlier", alternating(~F32, ~(x => x), 12.5, F32.neg(10.0), 0.0001, TA.PPO.batch(prices, 2, 3, 0)))
    Unit <- Assert.check("PVO after outlier", alternating(~F32, ~(x => x), 12.5, F32.neg(10.0), 0.0001, TA.PVO.batch(prices, 2, 3, 0)))
    Unit <- Assert.check("reference", reference())
    Unit <- Assert.check("AROONOSC.batch", Bool.and(edges(), aroonosc.precise(TA.AROONOSC.batch(aroonosc.history(U32.to_nat(9999)), 10000))))
    Assert.check("chunks", chunks())
