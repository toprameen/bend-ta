import Base
import ../../scripts/assert.bend as Assert
import ../../f32.bend as TA

def positive_signal(+signal: TA.Pattern.Signal(), strength: U32) -> Bool:
  Bool.and(Bool.not(TA.Pattern.negative(signal)), U32.is_eq(TA.Pattern.strength(signal), strength))

def resumed(result: TA.Pattern.State() & List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> Bool:
  match result:
    case (state, [Some{first}, Some{second}]):
      Bool.and(positive_signal(first, 0), positive_signal(second, 100))
    case _: False{}

def previewed(result: TA.Pattern.State() & Maybe<&2, TA.Pattern.Signal()>) -> Bool:
  match result:
    case (state, Some{signal}):
      Bool.and(positive_signal(signal, 100),
        resumed(TA.Stream.scan(~TA.Bar.OHLC(), ~TA.Pattern.Signal(), ~TA.Pattern.State(), ~TA.Pattern.next,
          [TA.Bar.ohlc(5.0, 8.0, 3.0, 5.75), TA.Bar.ohlc(5.0, 8.0, 3.0, 5.25)], state)))
    case _: False{}

def warming_up(value: Maybe<&2, TA.Pattern.Signal()>) -> Bool:
  match value:
    case None{}: True{}
    case Some{signal}: False{}

def warmed(result: TA.CDLDOJI.State() & List<&2, Maybe<&2, TA.Pattern.Signal()>>) -> Bool:
  (state, values) = result
  Bool.and(List.all(&2, Maybe<&2, TA.Pattern.Signal()>, warming_up, values),
    previewed(TA.Pattern.preview(state, TA.Bar.ohlc(5.0, 105.0, 0.0, 5.25))))

def initial_preview(result: TA.CDLDOJI.State() & Maybe<&2, TA.Pattern.Signal()>) -> Bool:
  match result:
    case (state, None{}):
      warmed(TA.Stream.scan(~TA.Bar.OHLC(), ~TA.Pattern.Signal(), ~TA.CDLDOJI.State(), ~TA.CDLDOJI.next,
        List.replicate(TA.Bar.OHLC(), 10n, TA.Bar.ohlc(5.0, 8.0, 3.0, 5.0)), state))
    case _: False{}

def start(result: Result<&2, &1, TA.Pattern.Error(), TA.CDLDOJI.State()>) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{state}: initial_preview(TA.CDLDOJI.preview(state, TA.Bar.ohlc(5.0, 8.0, 3.0, 5.0)))

def main() -> IO(Unit):
  Assert.check("CDLDOJI preview preserves warm-up and rolling thresholds", start(TA.CDLDOJI.init()))
