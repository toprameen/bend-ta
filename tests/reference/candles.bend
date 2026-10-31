import Base
import ../../src/f32.bend as TA
import ../../src/core/bar.bend as Bar
import ../../src/core/patterns.bend as Pattern
import ../../src/core/candle.bend as Candle
import ../../src/core/series.bend as Series

def show.one(x: Maybe<&2, TA.Pattern.Signal()>) -> String:
  match x:
    case None{}: "n"
    case Some{Pattern.Signal{negative, strength}}:
      match strength:
        case 0: "z"
        case 80: Bool.pick(String, negative, "b", "a")
        case 100: Bool.pick(String, negative, "m", "p")
        case other: "unexpected-strength"

def show.list(xs: List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> String:
  match xs:
    case Nil{}: ""
    case h <> t: String.append(show.one(h), show.list(t))

def show(result: Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{xs}: show.list(xs)


def b(open: U32, high: U32, low: U32, close: U32) -> Bar.OHLC<F32>:
  Bar.OHLC{F32.div(U32.to_f32(open), 4.0), F32.div(U32.to_f32(high), 4.0), F32.div(U32.to_f32(low), 4.0), F32.div(U32.to_f32(close), 4.0)}

def history(xs: List<&2, Bar.OHLC<F32>>) -> List<&2, Bar.OHLC<F32>>:
  +bar: Bar.OHLC<F32> = b(40, 56, 32, 48)
  bar <> bar <> bar <> bar <> bar <> bar <> bar <> bar <> bar <> bar <> xs

def verify(expected: String, result: Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>) -> Bool:
  String.eq(expected, show(result))

def continued(tail: List<&2, Bar.OHLC<F32>>, result: TA.Pattern.State() & List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> String:
  match result:
    case (state, prefix): String.append(show.list(prefix), show.list(Series.batch(~Bar.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.Pattern.State(), ~TA.Pattern.next, tail, state)))

def chunked(name: Pattern.Name, prefix: List<&2, Bar.OHLC<F32>>, tail: List<&2, Bar.OHLC<F32>>, result: Result<&2, &1, TA.Pattern.Error(), TA.Pattern.State()>) -> String:
  match result:
    case Fail{e}: "invalid"
    case Done{state}: continued(tail, Series.scan(~Bar.OHLC<F32>, ~TA.Pattern.Signal(), ~TA.Pattern.State(), ~TA.Pattern.next, prefix, state))

type Case is Data:
  Case{name: Pattern.Name, tail: List<&2, Bar.OHLC<F32>>, expected: String, penetration: F32}

def named(name: Pattern.Name, xs: List<&2, Bar.OHLC<F32>>, penetration: F32) -> Result<&2, &2, TA.Pattern.Error(), List<&2, Maybe<&2, TA.Pattern.Signal()>>>:
  match name:
    case Pattern.CDL2CROWS{}: TA.CDL2CROWS.batch(xs)
    case Pattern.CDL3BLACKCROWS{}: TA.CDL3BLACKCROWS.batch(xs)
    case Pattern.CDL3INSIDE{}: TA.CDL3INSIDE.batch(xs)
    case Pattern.CDL3LINESTRIKE{}: TA.CDL3LINESTRIKE.batch(xs)
    case Pattern.CDL3OUTSIDE{}: TA.CDL3OUTSIDE.batch(xs)
    case Pattern.CDL3STARSINSOUTH{}: TA.CDL3STARSINSOUTH.batch(xs)
    case Pattern.CDL3WHITESOLDIERS{}: TA.CDL3WHITESOLDIERS.batch(xs)
    case Pattern.CDLABANDONEDBABY{}: TA.CDLABANDONEDBABY.batch(xs, penetration)
    case Pattern.CDLADVANCEBLOCK{}: TA.CDLADVANCEBLOCK.batch(xs)
    case Pattern.CDLBELTHOLD{}: TA.CDLBELTHOLD.batch(xs)
    case Pattern.CDLBREAKAWAY{}: TA.CDLBREAKAWAY.batch(xs)
    case Pattern.CDLCLOSINGMARUBOZU{}: TA.CDLCLOSINGMARUBOZU.batch(xs)
    case Pattern.CDLCONCEALBABYSWALL{}: TA.CDLCONCEALBABYSWALL.batch(xs)
    case Pattern.CDLCOUNTERATTACK{}: TA.CDLCOUNTERATTACK.batch(xs)
    case Pattern.CDLDARKCLOUDCOVER{}: TA.CDLDARKCLOUDCOVER.batch(xs, penetration)
    case Pattern.CDLDOJI{}: TA.CDLDOJI.batch(xs)
    case Pattern.CDLDOJISTAR{}: TA.CDLDOJISTAR.batch(xs)
    case Pattern.CDLDRAGONFLYDOJI{}: TA.CDLDRAGONFLYDOJI.batch(xs)
    case Pattern.CDLENGULFING{}: TA.CDLENGULFING.batch(xs)
    case Pattern.CDLEVENINGDOJISTAR{}: TA.CDLEVENINGDOJISTAR.batch(xs, penetration)
    case Pattern.CDLEVENINGSTAR{}: TA.CDLEVENINGSTAR.batch(xs, penetration)
    case Pattern.CDLGAPSIDESIDEWHITE{}: TA.CDLGAPSIDESIDEWHITE.batch(xs)
    case Pattern.CDLGRAVESTONEDOJI{}: TA.CDLGRAVESTONEDOJI.batch(xs)
    case Pattern.CDLHAMMER{}: TA.CDLHAMMER.batch(xs)
    case Pattern.CDLHANGINGMAN{}: TA.CDLHANGINGMAN.batch(xs)
    case Pattern.CDLHARAMI{}: TA.CDLHARAMI.batch(xs)
    case Pattern.CDLHARAMICROSS{}: TA.CDLHARAMICROSS.batch(xs)
    case Pattern.CDLHIGHWAVE{}: TA.CDLHIGHWAVE.batch(xs)
    case Pattern.CDLHOMINGPIGEON{}: TA.CDLHOMINGPIGEON.batch(xs)
    case Pattern.CDLIDENTICAL3CROWS{}: TA.CDLIDENTICAL3CROWS.batch(xs)
    case Pattern.CDLINNECK{}: TA.CDLINNECK.batch(xs)
    case Pattern.CDLINVERTEDHAMMER{}: TA.CDLINVERTEDHAMMER.batch(xs)
    case Pattern.CDLKICKING{}: TA.CDLKICKING.batch(xs)
    case Pattern.CDLKICKINGBYLENGTH{}: TA.CDLKICKINGBYLENGTH.batch(xs)
    case Pattern.CDLLADDERBOTTOM{}: TA.CDLLADDERBOTTOM.batch(xs)
    case Pattern.CDLLONGLEGGEDDOJI{}: TA.CDLLONGLEGGEDDOJI.batch(xs)
    case Pattern.CDLLONGLINE{}: TA.CDLLONGLINE.batch(xs)
    case Pattern.CDLMARUBOZU{}: TA.CDLMARUBOZU.batch(xs)
    case Pattern.CDLMATCHINGLOW{}: TA.CDLMATCHINGLOW.batch(xs)
    case Pattern.CDLMATHOLD{}: TA.CDLMATHOLD.batch(xs, penetration)
    case Pattern.CDLMORNINGDOJISTAR{}: TA.CDLMORNINGDOJISTAR.batch(xs, penetration)
    case Pattern.CDLMORNINGSTAR{}: TA.CDLMORNINGSTAR.batch(xs, penetration)
    case Pattern.CDLONNECK{}: TA.CDLONNECK.batch(xs)
    case Pattern.CDLPIERCING{}: TA.CDLPIERCING.batch(xs)
    case Pattern.CDLRICKSHAWMAN{}: TA.CDLRICKSHAWMAN.batch(xs)
    case Pattern.CDLRISEFALL3METHODS{}: TA.CDLRISEFALL3METHODS.batch(xs)
    case Pattern.CDLSEPARATINGLINES{}: TA.CDLSEPARATINGLINES.batch(xs)
    case Pattern.CDLSHOOTINGSTAR{}: TA.CDLSHOOTINGSTAR.batch(xs)
    case Pattern.CDLSHORTLINE{}: TA.CDLSHORTLINE.batch(xs)
    case Pattern.CDLSPINNINGTOP{}: TA.CDLSPINNINGTOP.batch(xs)
    case Pattern.CDLSTALLEDPATTERN{}: TA.CDLSTALLEDPATTERN.batch(xs)
    case Pattern.CDLSTICKSANDWICH{}: TA.CDLSTICKSANDWICH.batch(xs)
    case Pattern.CDLTAKURI{}: TA.CDLTAKURI.batch(xs)
    case Pattern.CDLTASUKIGAP{}: TA.CDLTASUKIGAP.batch(xs)
    case Pattern.CDLTHRUSTING{}: TA.CDLTHRUSTING.batch(xs)
    case Pattern.CDLTRISTAR{}: TA.CDLTRISTAR.batch(xs)
    case Pattern.CDLUNIQUE3RIVER{}: TA.CDLUNIQUE3RIVER.batch(xs)
    case Pattern.CDLUPSIDEGAP2CROWS{}: TA.CDLUPSIDEGAP2CROWS.batch(xs)
    case Pattern.CDLXSIDEGAP3METHODS{}: TA.CDLXSIDEGAP3METHODS.batch(xs)

def check(xs: List<&2, Case>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Case{name, tail, expected, penetration} <> rest:
      Bool.and(verify(expected, named(name, history(tail), penetration)), check(rest))

def cases.part14() -> List<&2, Case>:
  Case{Pattern.CDLHARAMICROSS{}, [b(0, 1, 0, 0), b(1, 2, 0, 2), b(0, 1, 0, 0), b(0, 6, 0, 6), b(2, 2, 0, 1)], "nnnnnnnnnnnzzzm", 0.3} <>
  Nil{}

def cases.part13() -> List<&2, Case>:
  Case{Pattern.CDLHARAMI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(7, 7, 0, 0), b(1, 1, 0, 1)], "nnnnnnnnnnnzzzp", 0.3} <>
  Case{Pattern.CDLHARAMI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 8, 0, 8), b(5, 5, 0, 5)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLHARAMICROSS{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(6, 6, 0, 0), b(6, 6, 0, 6)], "nnnnnnnnnnnzzza", 0.3} <>
  Case{Pattern.CDLHARAMICROSS{}, [b(0, 1, 0, 1), b(0, 1, 0, 1), b(0, 1, 0, 1), b(2, 8, 0, 8), b(8, 8, 0, 8)], "nnnnnnnnnnnzzzb", 0.3} <>
  Case{Pattern.CDLHARAMICROSS{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(7, 7, 0, 1), b(2, 2, 0, 2)], "nnnnnnnnnnnzzzp", 0.3} <>
  cases.part14()

def cases.part12() -> List<&2, Case>:
  Case{Pattern.CDLENGULFING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 1), b(1, 1, 0, 0)], "nnzzzzzzzzzzzzb", 0.3} <>
  Case{Pattern.CDLENGULFING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 0, 1), b(0, 3, 0, 3)], "nnzzzzzzzzzzzzp", 0.3} <>
  Case{Pattern.CDLENGULFING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 1), b(2, 2, 0, 0)], "nnzzzzzzzzzzzzm", 0.3} <>
  Case{Pattern.CDLHARAMI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(6, 6, 0, 0), b(0, 1, 0, 0)], "nnnnnnnnnnnzzza", 0.3} <>
  Case{Pattern.CDLHARAMI{}, [b(0, 1, 0, 0), b(1, 2, 0, 2), b(0, 1, 0, 0), b(0, 6, 0, 6), b(5, 6, 0, 6)], "nnnnnnnnnnnzzzb", 0.3} <>
  cases.part13()

def cases.part11() -> List<&2, Case>:
  Case{Pattern.CDLTRISTAR{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 0, 2), b(1, 1, 0, 1), b(2, 3, 0, 3)], "nnnnnnnnnnnnzmp", 0.3} <>
  Case{Pattern.CDLUNIQUE3RIVER{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(8, 8, 1, 1), b(3, 3, 0, 2), b(1, 2, 0, 2)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDLUPSIDEGAP2CROWS{}, [b(0, 1, 0, 0), b(65, 65, 0, 65), b(3, 10, 0, 10), b(13, 13, 0, 12), b(14, 14, 0, 11)], "nnnnnnnnnnnnzzm", 0.3} <>
  Case{Pattern.CDLXSIDEGAP3METHODS{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(5, 5, 0, 3), b(2, 2, 0, 0), b(1, 4, 0, 4)], "nnzzzzzzzzzzzzm", 0.3} <>
  Case{Pattern.CDLENGULFING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(0, 2, 0, 2)], "nnzzzzzzzzzzzba", 0.3} <>
  cases.part12()

def cases.part10() -> List<&2, Case>:
  Case{Pattern.CDLSTALLEDPATTERN{}, [b(160, 160, 159, 160), b(16, 18, 16, 16), b(0, 30, 0, 7), b(10, 19, 0, 17), b(18, 18, 0, 18)], "nnnnnnnnnnnnzzm", 0.3} <>
  Case{Pattern.CDLSTICKSANDWICH{}, [b(0, 1, 0, 0), b(0, 27, 0, 0), b(2, 2, 0, 1), b(2, 3, 2, 2), b(1, 1, 0, 0)], "nnnnnnnzzzzzzzp", 0.3} <>
  Case{Pattern.CDLTAKURI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 1)], "nnnnnnnnnnzzzzp", 0.3} <>
  Case{Pattern.CDLTASUKIGAP{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(4, 4, 0, 4), b(2, 2, 0, 0), b(1, 3, 0, 3)], "nnnnnnnzzzzzzzm", 0.3} <>
  Case{Pattern.CDLTHRUSTING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(7, 7, 1, 1), b(0, 2, 0, 2)], "nnnnnnnnnnnzzzm", 0.3} <>
  cases.part11()

def cases.part9() -> List<&2, Case>:
  Case{Pattern.CDLRISEFALL3METHODS{}, [b(11, 11, 0, 2), b(0, 1, 0, 1), b(9, 10, 0, 10), b(5, 11, 0, 11), b(7, 7, 0, 0)], "nnnnnnnnnnnnnnm", 0.3} <>
  Case{Pattern.CDLSEPARATINGLINES{}, [b(0, 132, 0, 0), b(0, 160, 0, 0), b(0, 160, 0, 0), b(0, 1, 0, 0), b(5, 5, 0, 0)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLSHOOTINGSTAR{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(0, 1, 0, 0), b(1, 4, 0, 2)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLSHORTLINE{}, [b(1, 1, 0, 0), b(1, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 1)], "nnnnnnnnnnmmppp", 0.3} <>
  Case{Pattern.CDLSPINNINGTOP{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(2, 5, 0, 3)], "nnnnnnnnnnzzzzp", 0.3} <>
  cases.part10()

def cases.part8() -> List<&2, Case>:
  Case{Pattern.CDLMORNINGDOJISTAR{}, [b(0, 1, 0, 0), b(0, 1, 0, 1), b(20, 21, 0, 1), b(0, 1, 0, 0), b(0, 7, 0, 7)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDLMORNINGSTAR{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(11, 11, 0, 4), b(3, 3, 0, 2), b(1, 7, 0, 7)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDLONNECK{}, [b(0, 1, 0, 0), b(0, 50, 0, 0), b(0, 1, 0, 0), b(7, 7, 1, 1), b(0, 1, 0, 0)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLPIERCING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(9, 9, 3, 3), b(0, 7, 0, 7)], "nnnnnnnnnnnzzzp", 0.3} <>
  Case{Pattern.CDLRICKSHAWMAN{}, [b(1, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(0, 1, 0, 0), b(6, 9, 4, 7)], "nnnnnnnnnnzzzzp", 0.3} <>
  cases.part9()

def cases.part7() -> List<&2, Case>:
  Case{Pattern.CDLLONGLEGGEDDOJI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 1)], "nnnnnnnnnnppppp", 0.3} <>
  Case{Pattern.CDLLONGLINE{}, [b(2, 2, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(39, 39, 0, 3)], "nnnnnnnnnnzzzzm", 0.3} <>
  Case{Pattern.CDLMARUBOZU{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(5, 5, 0, 0)], "nnnnnnnnnnzzzzm", 0.3} <>
  Case{Pattern.CDLMATCHINGLOW{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(1, 1, 0, 0)], "nnnnnnzzzzzzzzp", 0.3} <>
  Case{Pattern.CDLMATHOLD{}, [b(0, 10, 0, 10), b(12, 12, 0, 11), b(9, 12, 0, 9), b(8, 12, 0, 8), b(9, 13, 0, 13)], "nnnnnnnnnnnnnnp", 0.3} <>
  cases.part8()

def cases.part6() -> List<&2, Case>:
  Case{Pattern.CDLINNECK{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(7, 7, 1, 1), b(0, 1, 0, 1)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLINVERTEDHAMMER{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 0, 2), b(1, 2, 0, 1)], "nnnnnnnnnnnzzzp", 0.3} <>
  Case{Pattern.CDLKICKING{}, [b(0, 1, 0, 1), b(2, 3, 2, 3), b(0, 1, 0, 1), b(7, 13, 7, 13), b(6, 6, 0, 0)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLKICKINGBYLENGTH{}, [b(0, 2, 0, 1), b(0, 1, 0, 1), b(7, 8, 3, 8), b(9, 15, 9, 15), b(7, 7, 0, 0)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLLADDERBOTTOM{}, [b(3, 3, 2, 2), b(2, 2, 1, 1), b(1, 1, 0, 0), b(1, 3, 0, 0), b(2, 4, 0, 4)], "nnnnnnnnnnnnnnp", 0.3} <>
  cases.part7()

def cases.part5() -> List<&2, Case>:
  Case{Pattern.CDLHARAMI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(11, 11, 0, 5), b(11, 11, 0, 11)], "nnnnnnnnnnnzzza", 0.3} <>
  Case{Pattern.CDLHARAMICROSS{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(24, 24, 0, 0), b(2, 2, 0, 1)], "nnnnnnnnnnnzzzp", 0.3} <>
  Case{Pattern.CDLHIGHWAVE{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(4, 7, 0, 3)], "nnnnnnnnnnzzzzm", 0.3} <>
  Case{Pattern.CDLHOMINGPIGEON{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(6, 6, 0, 0), b(2, 2, 0, 1)], "nnnnnnnnnnnzzzp", 0.3} <>
  Case{Pattern.CDLIDENTICAL3CROWS{}, [b(4, 4, 2, 2), b(3, 10, 3, 3), b(4, 4, 1, 3), b(3, 3, 0, 1), b(1, 1, 0, 0)], "nnnnnnnnnnnnzzm", 0.3} <>
  cases.part6()

def cases.part4() -> List<&2, Case>:
  Case{Pattern.CDLEVENINGSTAR{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 8, 0, 8), b(9, 9, 0, 9), b(10, 10, 0, 4)], "nnnnnnnnnnnnzzm", 0.3} <>
  Case{Pattern.CDLGAPSIDESIDEWHITE{}, [b(1, 1, 0, 0), b(1, 1, 0, 0), b(2, 2, 0, 1), b(3, 3, 0, 3), b(3, 4, 0, 4)], "nnnnnnnzzzzzzzp", 0.3} <>
  Case{Pattern.CDLGRAVESTONEDOJI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 4, 0, 1)], "nnnnnnnnnnzzzzp", 0.3} <>
  Case{Pattern.CDLHAMMER{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 1, 2)], "nnnnnnnnnnnzzzp", 0.3} <>
  Case{Pattern.CDLHANGINGMAN{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 1, 2)], "nnnnnnnnnnnzzzm", 0.3} <>
  cases.part5()

def cases.part3() -> List<&2, Case>:
  Case{Pattern.CDLDOJI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0)], "nnnnnnnnnnppppp", 0.3} <>
  Case{Pattern.CDLDOJISTAR{}, [b(0, 1, 0, 1), b(4, 5, 0, 5), b(0, 1, 0, 1), b(2, 8, 0, 8), b(9, 9, 0, 9)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLDRAGONFLYDOJI{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 0, 2)], "nnnnnnnnnnzzzzp", 0.3} <>
  Case{Pattern.CDLENGULFING{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(2, 2, 0, 1), b(0, 3, 0, 3)], "nnzzzzzzzzzzzzp", 0.3} <>
  Case{Pattern.CDLEVENINGDOJISTAR{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 7, 0, 7), b(8, 8, 0, 8), b(6, 6, 0, 0)], "nnnnnnnnnnnnzzm", 0.3} <>
  cases.part4()

def cases.part2() -> List<&2, Case>:
  Case{Pattern.CDLBREAKAWAY{}, [b(14, 14, 0, 5), b(3, 3, 2, 2), b(1, 2, 1, 1), b(1, 1, 0, 0), b(0, 4, 0, 4)], "nnnnnnnnnnnnnnp", 0.3} <>
  Case{Pattern.CDLCLOSINGMARUBOZU{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 1, 0, 0), b(0, 1, 0, 0), b(54, 54, 0, 0)], "nnnnnnnnnnzzzzm", 0.3} <>
  Case{Pattern.CDLCONCEALBABYSWALL{}, [b(0, 1, 0, 0), b(2, 2, 0, 1), b(4, 4, 3, 3), b(2, 4, 1, 1), b(1, 5, 0, 0)], "nnnnnnnnnnnnnzp", 0.3} <>
  Case{Pattern.CDLCOUNTERATTACK{}, [b(0, 160, 0, 0), b(0, 132, 0, 0), b(0, 160, 0, 0), b(1, 7, 0, 7), b(8, 8, 0, 2)], "nnnnnnnnnnnzzzm", 0.3} <>
  Case{Pattern.CDLDARKCLOUDCOVER{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 1, 0, 0), b(1, 7, 0, 7), b(8, 8, 0, 2)], "nnnnnnnnnnnzzzm", 0.3} <>
  cases.part3()

def cases.part1() -> List<&2, Case>:
  Case{Pattern.CDL3STARSINSOUTH{}, [b(0, 1, 0, 0), b(1, 1, 0, 1), b(15, 15, 0, 8), b(9, 9, 0, 8), b(2, 2, 1, 1)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDL3WHITESOLDIERS{}, [b(159, 160, 159, 159), b(1, 1, 0, 1), b(0, 1, 0, 0), b(1, 2, 0, 2), b(2, 7, 0, 7)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDLABANDONEDBABY{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(10, 10, 3, 3), b(0, 1, 0, 0), b(2, 8, 2, 8)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDLADVANCEBLOCK{}, [b(1, 1, 0, 1), b(0, 1, 0, 0), b(2, 9, 1, 9), b(3, 11, 3, 11), b(11, 12, 0, 12)], "nnnnnnnnnnnnzzm", 0.3} <>
  Case{Pattern.CDLBELTHOLD{}, [b(0, 1, 0, 0), b(0, 1, 0, 1), b(0, 1, 0, 0), b(0, 1, 0, 0), b(95, 95, 0, 0)], "nnnnnnnnnnzzzzm", 0.3} <>
  cases.part2()

def cases.part0() -> List<&2, Case>:
  Case{Pattern.CDL2CROWS{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(0, 7, 0, 7), b(10, 10, 0, 8), b(9, 9, 0, 1)], "nnnnnnnnnnnnzzm", 0.3} <>
  Case{Pattern.CDL3BLACKCROWS{}, [b(1, 106, 1, 1), b(0, 4, 0, 0), b(5, 23, 0, 3), b(4, 4, 0, 2), b(3, 3, 0, 1)], "nnnnnnnnnnnnnzm", 0.3} <>
  Case{Pattern.CDL3INSIDE{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(7, 7, 0, 0), b(2, 2, 1, 1), b(8, 8, 7, 8)], "nnnnnnnnnnnnzzp", 0.3} <>
  Case{Pattern.CDL3LINESTRIKE{}, [b(0, 1, 0, 0), b(4, 4, 0, 3), b(3, 3, 0, 2), b(2, 2, 0, 1), b(0, 5, 0, 5)], "nnnnnnnnzzzzzzm", 0.3} <>
  Case{Pattern.CDL3OUTSIDE{}, [b(0, 1, 0, 0), b(0, 1, 0, 0), b(3, 3, 0, 3), b(4, 4, 0, 2), b(0, 1, 0, 1)], "nnnzzzzzzzzzzzm", 0.3} <>
  cases.part1()

def cases() -> List<&2, Case>:
  Case{Pattern.CDL2CROWS{}, [b(40, 56, 32, 48), b(40, 56, 32, 48), b(40, 52, 40, 52), b(160, 160, 56, 56), b(80, 80, 48, 48)], "nnnnnnnnnnnnzzm", 0.3} <> cases.part0()

def settings() -> TA.Pattern.Settings():
  TA.Pattern.setting(TA.Pattern.defaults(), Candle.BodyDoji{}, Candle.Setting{Candle.HighLow{}, 0, 0.1})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(check(cases())))
    IO.print(chunked(Pattern.CDL3WHITESOLDIERS{}, history([b(159, 160, 159, 159), b(1, 1, 0, 1), b(0, 1, 0, 0), b(1, 2, 0, 2)]), [b(2, 7, 0, 7)], TA.CDL3WHITESOLDIERS.init()))
    IO.print(show(TA.Pattern.batch([b(8, 12, 4, 8), b(8, 12, 4, 12)], Pattern.CDLDOJI{}, settings(), 0.0)))
    IO.print(show(TA.CDLENGULFING.batch([])))
    IO.print(show(TA.CDLMORNINGSTAR.batch([], F32.neg(1.0))))
    IO.print(show(TA.CDLMORNINGSTAR.batch([], F32.div(0.0, 0.0))))
    IO.print(show(TA.Pattern.batch([], Pattern.CDLDOJI{}, TA.Pattern.setting(settings(), Candle.Near{}, Candle.Setting{Candle.HighLow{}, 1073741825, 1.0}), 0.0)))

#|True
#|nnnnnnnnnnnnzzp
#|pz
#|
#|invalid
#|invalid
#|invalid
