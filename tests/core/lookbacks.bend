import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA
import ../../src/core/candle.bend as Candle
import ../../src/core/patterns.bend as Patterns

def check(result: TA.Lookback.Result(), expected: U32) -> Bool:
  match result:
    case Done{value}: U32.is_eq(value, expected)
    case Fail{e}: False{}

def invalid(result: TA.Lookback.Result()) -> Bool:
  match result:
    case Fail{e}: True{}
    case Done{value}: False{}

def all(values: List<&2, Bool>) -> Bool:
  List.all(~&2, ~Bool, ~(x => x), values)

def main() -> IO(Unit):
  +nan = F32.div(0.0, 0.0)
  do IO<Unit>:
    Unit <- Assert.check("AC.lookback", all([
      check(TA.AC.lookback(5, 34, 5), 37), check(TA.ACCBANDS.lookback(20), 19), check(TA.ACOS.lookback(), 0),
      check(TA.AD.lookback(), 0), check(TA.ADD.lookback(), 0), check(TA.ADOSC.lookback(3, 10), 9),
      check(TA.ADR.lookback(14), 13), check(TA.ADX.lookback(14), 27), check(TA.ADXR.lookback(14), 40),
      check(TA.ALMA.lookback(9, 6.0, 0.85), 8), check(TA.AO.lookback(5, 34), 33), check(TA.APO.lookback(12, 26, 1), 25),
      check(TA.AROON.lookback(14), 14), check(TA.AROONOSC.lookback(14), 14), check(TA.ASI.lookback(3.0), 0),
      check(TA.ASIN.lookback(), 0), check(TA.ATAN.lookback(), 0), check(TA.ATR.lookback(14), 14),
      check(TA.AVGDEV.lookback(14), 13), check(TA.AVGPRICE.lookback(), 0), check(TA.BBANDS.lookback(20, 2.0, 2.0, 0), 19),
      check(TA.BBW.lookback(20, 2.0, 2.0, 0), 19), check(TA.BETA.lookback(5), 5), check(TA.BOP.lookback(), 0),
      check(TA.CCI.lookback(14), 13), check(TA.CDL2CROWS.lookback(), 12), check(TA.CDL3BLACKCROWS.lookback(), 13),
      check(TA.CDL3INSIDE.lookback(), 12), check(TA.CDL3LINESTRIKE.lookback(), 8), check(TA.CDL3OUTSIDE.lookback(), 3),
      check(TA.CDL3STARSINSOUTH.lookback(), 12), check(TA.CDL3WHITESOLDIERS.lookback(), 12), check(TA.CDLABANDONEDBABY.lookback(0.3), 12),
      check(TA.CDLADVANCEBLOCK.lookback(), 12), check(TA.CDLBELTHOLD.lookback(), 10), check(TA.CDLBREAKAWAY.lookback(), 14),
      check(TA.CDLCLOSINGMARUBOZU.lookback(), 10), check(TA.CDLCONCEALBABYSWALL.lookback(), 13), check(TA.CDLCOUNTERATTACK.lookback(), 11),
      check(TA.CDLDARKCLOUDCOVER.lookback(0.5), 11), check(TA.CDLDOJI.lookback(), 10), check(TA.CDLDOJISTAR.lookback(), 11),
      check(TA.CDLDRAGONFLYDOJI.lookback(), 10), check(TA.CDLENGULFING.lookback(), 2), check(TA.CDLEVENINGDOJISTAR.lookback(0.3), 12),
      check(TA.CDLEVENINGSTAR.lookback(0.3), 12), check(TA.CDLGAPSIDESIDEWHITE.lookback(), 7), check(TA.CDLGRAVESTONEDOJI.lookback(), 10),
      check(TA.CDLHAMMER.lookback(), 11), check(TA.CDLHANGINGMAN.lookback(), 11), check(TA.CDLHARAMI.lookback(), 11),
      check(TA.CDLHARAMICROSS.lookback(), 11), check(TA.CDLHIGHWAVE.lookback(), 10), check(TA.CDLHIKKAKE.lookback(), 5),
      check(TA.CDLHIKKAKEMOD.lookback(), 10), check(TA.CDLHOMINGPIGEON.lookback(), 11), check(TA.CDLIDENTICAL3CROWS.lookback(), 12),
      check(TA.CDLINNECK.lookback(), 11), check(TA.CDLINVERTEDHAMMER.lookback(), 11), check(TA.CDLKICKING.lookback(), 11),
      check(TA.CDLKICKINGBYLENGTH.lookback(), 11), check(TA.CDLLADDERBOTTOM.lookback(), 14), check(TA.CDLLONGLEGGEDDOJI.lookback(), 10),
      check(TA.CDLLONGLINE.lookback(), 10), check(TA.CDLMARUBOZU.lookback(), 10), check(TA.CDLMATCHINGLOW.lookback(), 6),
      check(TA.CDLMATHOLD.lookback(0.5), 14), check(TA.CDLMORNINGDOJISTAR.lookback(0.3), 12), check(TA.CDLMORNINGSTAR.lookback(0.3), 12),
      check(TA.CDLONNECK.lookback(), 11), check(TA.CDLPIERCING.lookback(), 11), check(TA.CDLRICKSHAWMAN.lookback(), 10),
      check(TA.CDLRISEFALL3METHODS.lookback(), 14), check(TA.CDLSEPARATINGLINES.lookback(), 11), check(TA.CDLSHOOTINGSTAR.lookback(), 11),
      check(TA.CDLSHORTLINE.lookback(), 10), check(TA.CDLSPINNINGTOP.lookback(), 10), check(TA.CDLSTALLEDPATTERN.lookback(), 12),
      check(TA.CDLSTICKSANDWICH.lookback(), 7), check(TA.CDLTAKURI.lookback(), 10), check(TA.CDLTASUKIGAP.lookback(), 7),
      check(TA.CDLTHRUSTING.lookback(), 11), check(TA.CDLTRISTAR.lookback(), 12), check(TA.CDLUNIQUE3RIVER.lookback(), 12),
      check(TA.CDLUPSIDEGAP2CROWS.lookback(), 12), check(TA.CDLXSIDEGAP3METHODS.lookback(), 2), check(TA.CEIL.lookback(), 0),
      check(TA.CG.lookback(10), 9), check(TA.CHOP.lookback(14), 14), check(TA.CHOPTR.lookback(14), 14),
      check(TA.CKSP.lookback(10, 1.0, 9), 18), check(TA.CMF.lookback(20), 19), check(TA.CMO.lookback(14), 14),
      check(TA.CMOU.lookback(14), 14), check(TA.COPPOCK.lookback(10, 11, 14), 23), check(TA.CORREL.lookback(30), 29),
      check(TA.COS.lookback(), 0), check(TA.COSH.lookback(), 0), check(TA.CRSI.lookback(3, 2, 100), 101),
      check(TA.CTI.lookback(20), 19), check(TA.CUMSUM.lookback(), 0), check(TA.CVI.lookback(10, 10), 19),
      check(TA.DEMA.lookback(30), 58), check(TA.DIV.lookback(), 0), check(TA.DONCHIAN.lookback(20), 19),
      check(TA.DOSC.lookback(14, 5, 3, 9), 28), check(TA.DPO.lookback(20), 19), check(TA.DX.lookback(14), 14),
      check(TA.EFI.lookback(13), 13), check(TA.EMA.lookback(30), 29), check(TA.EMV.lookback(14, 10000.0), 14),
      check(TA.ER.lookback(10), 10), check(TA.ERI.lookback(13), 12), check(TA.EXP.lookback(), 0),
      check(TA.FISHER.lookback(10), 9), check(TA.FLOOR.lookback(), 0), check(TA.FOSC.lookback(5), 5),
      check(TA.FRACTAL.lookback(2, 2), 4), check(TA.FRAMA.lookback(16), 16), check(TA.HA.lookback(), 0),
      check(TA.HMA.lookback(20), 22), check(TA.HT_DCPERIOD.lookback(), 32), check(TA.HT_DCPHASE.lookback(), 63),
      check(TA.HT_PHASOR.lookback(), 32), check(TA.HT_SINE.lookback(), 63), check(TA.HT_TRENDLINE.lookback(), 63),
      check(TA.HT_TRENDMODE.lookback(), 63), check(TA.IBS.lookback(), 0), check(TA.ICHIMOKU.lookback(9, 26, 52), 51),
      check(TA.IMI.lookback(14), 13), check(TA.KAMA.lookback(30), 30), check(TA.KC.lookback(20, 10, 2.0), 19),
      check(TA.KDJ.lookback(9, 3, 13, 3, 13), 12), check(TA.KST.lookback(10, 15, 20, 30, 10, 10, 10, 15, 9), 52), check(TA.KSTEXT.lookback(10, 15, 20, 30, 10, 10, 10, 15, 9, 0, 0), 52),
      check(TA.KURTOSIS.lookback(30), 29), check(TA.KVO.lookback(34, 55, 13), 55), check(TA.LINEARREG.lookback(14), 13),
      check(TA.LINEARREG_ANGLE.lookback(14), 13), check(TA.LINEARREG_INTERCEPT.lookback(14), 13), check(TA.LINEARREG_SLOPE.lookback(14), 13),
      check(TA.LN.lookback(), 0), check(TA.LOG10.lookback(), 0), check(TA.MA.lookback(30, 0), 29),
      check(TA.MACD.lookback(12, 26, 9), 33), check(TA.MACDEXT.lookback(12, 0, 26, 0, 9, 0), 33), check(TA.MACDFIX.lookback(9), 33),
      check(TA.MAMA.lookback(0.5, 0.05), 32), check(TA.MARKETFI.lookback(), 0), check(TA.MASSI.lookback(9, 25), 40),
      check(TA.MAVP.lookback(2, 30, 0), 29), check(TA.MAX.lookback(30), 29), check(TA.MAXINDEX.lookback(30), 29),
      check(TA.MCGD.lookback(14), 13), check(TA.MEDIAN.lookback(30), 29), check(TA.MEDPRICE.lookback(), 0),
      check(TA.MFI.lookback(14), 14), check(TA.MIDPOINT.lookback(14), 13), check(TA.MIDPRICE.lookback(14), 13),
      check(TA.MIN.lookback(30), 29), check(TA.MININDEX.lookback(30), 29), check(TA.MINMAX.lookback(30), 29),
      check(TA.MINMAXINDEX.lookback(30), 29), check(TA.MINUS_DI.lookback(14), 14), check(TA.MINUS_DM.lookback(14), 13),
      check(TA.MOM.lookback(10), 10), check(TA.MULT.lookback(), 0), check(TA.NATR.lookback(14), 14),
      check(TA.NVI.lookback(), 0), check(TA.OBV.lookback(), 0), check(TA.PERCENTB.lookback(20, 2.0, 2.0, 0), 19),
      check(TA.PERCENTILE.lookback(100, 50.0), 99), check(TA.PERCENTRANK.lookback(100), 100), check(TA.PLUS_DI.lookback(14), 14),
      check(TA.PLUS_DM.lookback(14), 13), check(TA.PPO.lookback(12, 26, 1), 25), check(TA.PSO.lookback(8, 5), 15),
      check(TA.PVI.lookback(), 0), check(TA.PVO.lookback(12, 26, 1), 25), check(TA.PVT.lookback(), 0),
      check(TA.QSTICK.lookback(10), 9), check(TA.RMA.lookback(30), 29), check(TA.ROC.lookback(10), 10),
      check(TA.ROCP.lookback(10), 10), check(TA.ROCR.lookback(10), 10), check(TA.ROCR100.lookback(10), 10),
      check(TA.ROGERSSATCHELL.lookback(10, 252.0), 9), check(TA.RSI.lookback(14), 14), check(TA.RVI.lookback(14, 10), 22),
      check(TA.RVIR.lookback(14, 10), 22), check(TA.RVOL.lookback(20), 20), check(TA.SAR.lookback(0.02, 0.2), 1),
      check(TA.SAREXT.lookback(0.0, 0.0, 0.02, 0.02, 0.2, 0.02, 0.02, 0.2), 1), check(TA.SI.lookback(3.0), 1), check(TA.SIN.lookback(), 0),
      check(TA.SINH.lookback(), 0), check(TA.SMA.lookback(30), 29), check(TA.SMI.lookback(13, 2, 25, 9), 45),
      check(TA.SQRT.lookback(), 0), check(TA.SQZMOM.lookback(20, 2.0, 20, 2.0, 1.5, 1.0), 38), check(TA.STC.lookback(23, 50, 10), 67),
      check(TA.STDDEV.lookback(5, 1.0), 4), check(TA.STOCH.lookback(5, 3, 0, 3, 0), 8), check(TA.STOCHF.lookback(5, 3, 0), 6),
      check(TA.STOCHRSI.lookback(14, 5, 3, 0), 20), check(TA.SUB.lookback(), 0), check(TA.SUM.lookback(30), 29),
      check(TA.SUPERTREND.lookback(10, 3.0), 10), check(TA.SWAK_2PHP.lookback(20), 0), check(TA.SWAK_BP.lookback(20, 0.1), 0),
      check(TA.SWAK_BUTTER.lookback(20), 0), check(TA.SWAK_GAUSS.lookback(20), 0), check(TA.SWAK_HP.lookback(20), 0),
      check(TA.T3.lookback(5, 0.7), 24), check(TA.TAN.lookback(), 0), check(TA.TANH.lookback(), 0),
      check(TA.TEMA.lookback(30), 87), check(TA.TRANGE.lookback(), 1), check(TA.TRIMA.lookback(30), 29),
      check(TA.TRIX.lookback(30), 88), check(TA.TSF.lookback(14), 13), check(TA.TSI.lookback(25, 13), 37),
      check(TA.TYPPRICE.lookback(), 0), check(TA.ULTOSC.lookback(7, 14, 28), 28), check(TA.VAR.lookback(5, 1.0), 4),
      check(TA.VHF.lookback(28), 28), check(TA.VIDYA.lookback(12, 9), 9), check(TA.VORTEX.lookback(14), 14),
      check(TA.VWAP.lookback(), 0), check(TA.VWMA.lookback(30), 29), check(TA.WAD.lookback(), 0),
      check(TA.WAVETREND.lookback(10, 21, 4), 41), check(TA.WCLPRICE.lookback(), 0), check(TA.WILLR.lookback(14), 13),
      check(TA.WMA.lookback(30), 29), check(TA.ZIGZAG.lookback(5.0, 1), 1), check(TA.ZLEMA.lookback(30), 43)
    ]))
    Unit <- Assert.check("EMA.lookback", all([
      check(TA.EMA.lookback(1073741824), 1073741823), check(TA.MOM.lookback(1073741824), 1073741824),
      check(TA.MAVP.lookback(1, 10000, 8), 59994), check(TA.MAVP.lookback(1, 1, 11), 0),
      check(TA.MA.lookback(1, 11), 0), check(TA.MA.lookback(20, 10), 0),
      check(TA.DPO.lookback(2), 2), check(TA.KVO.lookback(2, 3, 20), 20),
      check(TA.STOCH.lookback(1, 1, 11, 1, 11), 0),
      check(TA.CDLHIKKAKEMOD.lookback.setting(Candle.Setting{Candle.HighLow{}, 0, 0.2}), 6)
    ]))
    Assert.check("SMA.lookback", all([
      invalid(TA.SMA.lookback(0)), invalid(TA.MOM.lookback(1073741825)), invalid(TA.MA.lookback(2, 11)),
      invalid(TA.MAVP.lookback(4, 3, 0)), invalid(TA.RSI.lookback(1)), invalid(TA.CVI.lookback(3, 0)),
      invalid(TA.SAR.lookback(nan, 0.2)), invalid(TA.MAMA.lookback(0.0, 0.1)),
      invalid(TA.ALMA.lookback(3, 0.0, 0.5)), invalid(TA.BBANDS.lookback(3, 2.0, 2.0, 11)),
      invalid(TA.VAR.lookback(3, nan)), invalid(TA.CDLMORNINGSTAR.lookback(nan)),
      invalid(TA.Pattern.lookback.checked(Patterns.CDLDOJI{}, TA.Pattern.defaults(), nan)),
      invalid(TA.CDLHIKKAKEMOD.lookback.setting(Candle.Setting{Candle.HighLow{}, 1, F32.neg(1.0)}))
    ]))
