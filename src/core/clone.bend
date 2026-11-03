import Base

import ./adaptive_window.bend as AdaptiveWindow
import ./advanced_oscillator.bend as AdvancedOscillator
import ./bar.bend as Bar
import ./candle.bend as Candle
import ./directional.bend as Directional
import ./extrema_queue.bend as ExtremaQueue
import ./hikkake.bend as Hikkake
import ./hilbert.bend as Hilbert
import ./ma.bend as Ma
import ./moments.bend as Moments
import ./momentum.bend as Momentum
import ./momentum_composite.bend as MomentumComposite
import ./momentum_market.bend as MomentumMarket
import ./momentum_smooth.bend as MomentumSmooth
import ./momentum_window.bend as MomentumWindow
import ./overlap.bend as Overlap
import ./pattern_state.bend as PatternState
import ./rolling.bend as Rolling
import ./rolling_average.bend as RollingAverage
import ./sma.bend as Sma
import ./squeeze.bend as Squeeze
import ./statistics.bend as Statistics
import ./statistics_window.bend as StatisticsWindow
import ./trend_composite.bend as TrendComposite
import ./variable.bend as Variable
import ./variable_shared.bend as VariableShared
import ./vidya.bend as Vidya
import ./volatility.bend as Volatility
import ./volatility_window.bend as VolatilityWindow
import ./volume.bend as Volume
import ./window.bend as Window
import ./window_signals.bend as WindowSignals

def pair(~A: Type, ~B: Type, result: A & A, rest: A -> A -> B) -> B:
  (a, b) = result
  rest(a, b)

def data(~A: Data, +value: A) -> A & A:
  (value, value)

def maybe.read(~A: Type, result: A & A) -> Maybe<&1, A> & Maybe<&1, A>:
  (a, b) = result
  (Some{a}, Some{b})

def maybe(~A: Type, ~copy: A -> A & A, value: Maybe<&1, A>) -> Maybe<&1, A> & Maybe<&1, A>:
  match value:
    case None{}: (None{}, None{})
    case Some{x}: maybe.read(~A, copy(x))

def list.read(~A: Type, left: List<&1, A>, right: List<&1, A>, result: A & A, rest: List<&1, A> -> List<&1, A> -> List<&1, A> & List<&1, A>) -> List<&1, A> & List<&1, A>:
  (a, b) = result
  rest(a <> left, b <> right)

def list.go(~A: Type, ~copy: A -> A & A, xs: List<&1, A>, left: List<&1, A>, right: List<&1, A>) -> List<&1, A> & List<&1, A>:
  match xs:
    case Nil{}: (List.reverse(&1, A, left), List.reverse(&1, A, right))
    case h <> t: list.read(~A, left, right, copy(h), a => b => list.go(~A, ~copy, t, a, b))

def list(~A: Type, ~copy: A -> A & A, xs: List<&1, A>) -> List<&1, A> & List<&1, A>:
  list.go(~A, ~copy, xs, Nil{}, Nil{})

def window(~A: Data, value: Window.State<A>) -> Window.State<A> & Window.State<A>:
  match value:
    case Window.Window{x_buffer, +x_period, +x_size, +x_pos}:
      pair(~Array<A>, ~(Window.State<A> & Window.State<A>), Array.clone(A, x_buffer), x_buffer_a => x_buffer_b =>
        (Window.Window{x_buffer_a, x_period, x_size, x_pos}, Window.Window{x_buffer_b, x_period, x_size, x_pos}))

def rolling(~N: Data, value: Rolling.State<N>) -> Rolling.State<N> & Rolling.State<N>:
  match value:
    case Rolling.Sum{x_window, +x_total}:
      pair(~Window.State<N>, ~(Rolling.State<N> & Rolling.State<N>), window(~N, x_window), x_window_a => x_window_b =>
        (Rolling.Sum{x_window_a, x_total}, Rolling.Sum{x_window_b, x_total}))

def sma(~N: Data, value: Sma.State<N>) -> Sma.State<N> & Sma.State<N>:
  match value:
    case Sma.Sma{+x_period, x_ring}:
      pair(~Rolling.State<N>, ~(Sma.State<N> & Sma.State<N>), rolling(~N, x_ring), x_ring_a => x_ring_b =>
        (Sma.Sma{x_period, x_ring_a}, Sma.Sma{x_period, x_ring_b}))

def candle(~N: Data, value: Candle.State<N>) -> Candle.State<N> & Candle.State<N>:
  match value:
    case Candle.Candle{+x_setting, x_ring, +x_previous}:
      pair(~Rolling.State<N>, ~(Candle.State<N> & Candle.State<N>), rolling(~N, x_ring), x_ring_a => x_ring_b =>
        (Candle.Candle{x_setting, x_ring_a, x_previous}, Candle.Candle{x_setting, x_ring_b, x_previous}))

def rolling_average(~N: Data, value: RollingAverage.State<N>) -> RollingAverage.State<N> & RollingAverage.State<N>:
  match value:
    case RollingAverage.Average{x_window, +x_kind, +x_cache}:
      pair(~Window.State<N>, ~(RollingAverage.State<N> & RollingAverage.State<N>), window(~N, x_window), x_window_a => x_window_b =>
        (RollingAverage.Average{x_window_a, x_kind, x_cache}, RollingAverage.Average{x_window_b, x_kind, x_cache}))

def volume.ease(~N: Data, value: Volume.Ease<N>) -> Volume.Ease<N> & Volume.Ease<N>:
  match value:
    case Volume.Ease{+x_previous, x_average, +x_divisor}:
      pair(~RollingAverage.State<N>, ~(Volume.Ease<N> & Volume.Ease<N>), rolling_average(~N, x_average), x_average_a => x_average_b =>
        (Volume.Ease{x_previous, x_average_a, x_divisor}, Volume.Ease{x_previous, x_average_b, x_divisor}))

def volatility.cvi(~N: Data, value: Volatility.Cvi<N>) -> Volatility.Cvi<N> & Volatility.Cvi<N>:
  match value:
    case Volatility.Cvi{+x_ema, x_lag}:
      pair(~Window.State<N>, ~(Volatility.Cvi<N> & Volatility.Cvi<N>), window(~N, x_lag), x_lag_a => x_lag_b =>
        (Volatility.Cvi{x_ema, x_lag_a}, Volatility.Cvi{x_ema, x_lag_b}))

def volatility.mass(~N: Data, value: Volatility.Mass<N>) -> Volatility.Mass<N> & Volatility.Mass<N>:
  match value:
    case Volatility.Mass{+x_first, +x_second, x_sum}:
      pair(~Rolling.State<N>, ~(Volatility.Mass<N> & Volatility.Mass<N>), rolling(~N, x_sum), x_sum_a => x_sum_b =>
        (Volatility.Mass{x_first, x_second, x_sum_a}, Volatility.Mass{x_first, x_second, x_sum_b}))

def pattern_state.thresholds(~N: Data, value: PatternState.Thresholds<N>) -> PatternState.Thresholds<N> & PatternState.Thresholds<N>:
  match value:
    case PatternState.Thresholds{x_body_long, x_body_very_long, x_body_short, x_body_doji, x_shadow_long, x_shadow_very_long, x_shadow_short, x_shadow_very_short, x_near, x_far, x_equal}:
      pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_body_long), x_body_long_a => x_body_long_b =>
        pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_body_very_long), x_body_very_long_a => x_body_very_long_b =>
          pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_body_short), x_body_short_a => x_body_short_b =>
            pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_body_doji), x_body_doji_a => x_body_doji_b =>
              pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_shadow_long), x_shadow_long_a => x_shadow_long_b =>
                pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_shadow_very_long), x_shadow_very_long_a => x_shadow_very_long_b =>
                  pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_shadow_short), x_shadow_short_a => x_shadow_short_b =>
                    pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_shadow_very_short), x_shadow_very_short_a => x_shadow_very_short_b =>
                      pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_near), x_near_a => x_near_b =>
                        pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_far), x_far_a => x_far_b =>
                          pair(~Candle.State<N>, ~(PatternState.Thresholds<N> & PatternState.Thresholds<N>), candle(~N, x_equal), x_equal_a => x_equal_b =>
                            (PatternState.Thresholds{x_body_long_a, x_body_very_long_a, x_body_short_a, x_body_doji_a, x_shadow_long_a, x_shadow_very_long_a, x_shadow_short_a, x_shadow_very_short_a, x_near_a, x_far_a, x_equal_a}, PatternState.Thresholds{x_body_long_b, x_body_very_long_b, x_body_short_b, x_body_doji_b, x_shadow_long_b, x_shadow_very_long_b, x_shadow_short_b, x_shadow_very_short_b, x_near_b, x_far_b, x_equal_b}))))))))))))

def pattern_state(~N: Data, value: PatternState.State<N>) -> PatternState.State<N> & PatternState.State<N>:
  match value:
    case PatternState.State{+x_name, +x_remaining, +x_penetration, x_thresholds, +x_history}:
      pair(~PatternState.Thresholds<N>, ~(PatternState.State<N> & PatternState.State<N>), pattern_state.thresholds(~N, x_thresholds), x_thresholds_a => x_thresholds_b =>
        (PatternState.State{x_name, x_remaining, x_penetration, x_thresholds_a, x_history}, PatternState.State{x_name, x_remaining, x_penetration, x_thresholds_b, x_history}))

def vidya(~N: Data, value: Vidya.State<N>) -> Vidya.State<N> & Vidya.State<N>:
  match value:
    case Vidya.Vidya{x_window, +x_previous, +x_value, +x_alpha, +x_identity}:
      pair(~Window.State<Vidya.Movement<N>>, ~(Vidya.State<N> & Vidya.State<N>), window(~Vidya.Movement<N>, x_window), x_window_a => x_window_b =>
        (Vidya.Vidya{x_window_a, x_previous, x_value, x_alpha, x_identity}, Vidya.Vidya{x_window_b, x_previous, x_value, x_alpha, x_identity}))

def ma(~N: Data, value: Ma.State<N>) -> Ma.State<N> & Ma.State<N>:
  match value:
    case Ma.Cycle{+x_state}:
      (Ma.Cycle{x_state}, Ma.Cycle{x_state})
    case Ma.Variable{x_state}:
      pair(~Vidya.State<N>, ~(Ma.State<N> & Ma.State<N>), vidya(~N, x_state), x_state_a => x_state_b =>
        (Ma.Variable{x_state_a}, Ma.Variable{x_state_b}))
    case Ma.Identity{}:
      (Ma.Identity{}, Ma.Identity{})
    case Ma.Adaptive{x_window, +x_period, +x_value, +x_cache}:
      pair(~Window.State<N>, ~(Ma.State<N> & Ma.State<N>), window(~N, x_window), x_window_a => x_window_b =>
        (Ma.Adaptive{x_window_a, x_period, x_value, x_cache}, Ma.Adaptive{x_window_b, x_period, x_value, x_cache}))
    case Ma.Gaussian{x_window, +x_weights}:
      pair(~Window.State<N>, ~(Ma.State<N> & Ma.State<N>), window(~N, x_window), x_window_a => x_window_b =>
        (Ma.Gaussian{x_window_a, x_weights}, Ma.Gaussian{x_window_b, x_weights}))
    case Ma.ZeroLag{x_window, +x_state}:
      pair(~Window.State<N>, ~(Ma.State<N> & Ma.State<N>), window(~N, x_window), x_window_a => x_window_b =>
        (Ma.ZeroLag{x_window_a, x_state}, Ma.ZeroLag{x_window_b, x_state}))
    case Ma.Hull{x_fast, x_slow, x_outer}:
      pair(~RollingAverage.State<N>, ~(Ma.State<N> & Ma.State<N>), rolling_average(~N, x_fast), x_fast_a => x_fast_b =>
        pair(~RollingAverage.State<N>, ~(Ma.State<N> & Ma.State<N>), rolling_average(~N, x_slow), x_slow_a => x_slow_b =>
          pair(~RollingAverage.State<N>, ~(Ma.State<N> & Ma.State<N>), rolling_average(~N, x_outer), x_outer_a => x_outer_b =>
            (Ma.Hull{x_fast_a, x_slow_a, x_outer_a}, Ma.Hull{x_fast_b, x_slow_b, x_outer_b}))))
    case Ma.Simple{x_state}:
      pair(~RollingAverage.State<N>, ~(Ma.State<N> & Ma.State<N>), rolling_average(~N, x_state), x_state_a => x_state_b =>
        (Ma.Simple{x_state_a}, Ma.Simple{x_state_b}))
    case Ma.Exponential{+x_state}:
      (Ma.Exponential{x_state}, Ma.Exponential{x_state})
    case Ma.Weighted{x_state}:
      pair(~RollingAverage.State<N>, ~(Ma.State<N> & Ma.State<N>), rolling_average(~N, x_state), x_state_a => x_state_b =>
        (Ma.Weighted{x_state_a}, Ma.Weighted{x_state_b}))
    case Ma.Cascade{+x_kind, +x_factor, +x_stages}:
      (Ma.Cascade{x_kind, x_factor, x_stages}, Ma.Cascade{x_kind, x_factor, x_stages})

def extrema_queue.queue(~N: Data, value: ExtremaQueue.Queue<N>) -> ExtremaQueue.Queue<N> & ExtremaQueue.Queue<N>:
  match value:
    case ExtremaQueue.Queue{x_buffer, +x_head, +x_size}:
      pair(~Array<ExtremaQueue.Entry<N>>, ~(ExtremaQueue.Queue<N> & ExtremaQueue.Queue<N>), Array.clone(ExtremaQueue.Entry<N>, x_buffer), x_buffer_a => x_buffer_b =>
        (ExtremaQueue.Queue{x_buffer_a, x_head, x_size}, ExtremaQueue.Queue{x_buffer_b, x_head, x_size}))

def extrema_queue(~N: Data, value: ExtremaQueue.State<N>) -> ExtremaQueue.State<N> & ExtremaQueue.State<N>:
  match value:
    case ExtremaQueue.State{+x_period, +x_size, +x_position, x_low, x_high}:
      pair(~ExtremaQueue.Queue<N>, ~(ExtremaQueue.State<N> & ExtremaQueue.State<N>), extrema_queue.queue(~N, x_low), x_low_a => x_low_b =>
        pair(~ExtremaQueue.Queue<N>, ~(ExtremaQueue.State<N> & ExtremaQueue.State<N>), extrema_queue.queue(~N, x_high), x_high_a => x_high_b =>
          (ExtremaQueue.State{x_period, x_size, x_position, x_low_a, x_high_a}, ExtremaQueue.State{x_period, x_size, x_position, x_low_b, x_high_b})))

def statistics.extremes(~N: Data, value: Statistics.Extremes<N>) -> Statistics.Extremes<N> & Statistics.Extremes<N>:
  match value:
    case Statistics.Extremes{x_range, +x_seen}:
      pair(~ExtremaQueue.State<N>, ~(Statistics.Extremes<N> & Statistics.Extremes<N>), extrema_queue(~N, x_range), x_range_a => x_range_b =>
        (Statistics.Extremes{x_range_a, x_seen}, Statistics.Extremes{x_range_b, x_seen}))

def moments(~N: Data, value: Moments.Cached<N>) -> Moments.Cached<N> & Moments.Cached<N>:
  match value:
    case Moments.Cached{x_window, +x_cache}:
      pair(~Window.State<N>, ~(Moments.Cached<N> & Moments.Cached<N>), window(~N, x_window), a => b =>
        (Moments.Cached{a, x_cache}, Moments.Cached{b, x_cache}))

def statistics.standard(~N: Data, value: Statistics.Standard<N>) -> Statistics.Standard<N> & Statistics.Standard<N>:
  match value:
    case Statistics.Standard{x_moments, +x_factor}:
      pair(~Moments.Cached<N>, ~(Statistics.Standard<N> & Statistics.Standard<N>), moments(~N, x_moments), a => b =>
        (Statistics.Standard{a, x_factor}, Statistics.Standard{b, x_factor}))

def statistics.parameterwindow(~N: Data, value: Statistics.ParameterWindow<N>) -> Statistics.ParameterWindow<N> & Statistics.ParameterWindow<N>:
  match value:
    case Statistics.ParameterWindow{x_window, +x_parameter}:
      pair(~Window.State<N>, ~(Statistics.ParameterWindow<N> & Statistics.ParameterWindow<N>), window(~N, x_window), x_window_a => x_window_b =>
        (Statistics.ParameterWindow{x_window_a, x_parameter}, Statistics.ParameterWindow{x_window_b, x_parameter}))

def overlap.bollinger(~N: Data, value: Overlap.Bollinger<N>) -> Overlap.Bollinger<N> & Overlap.Bollinger<N>:
  match value:
    case Overlap.Bollinger{x_average, x_moments, +x_up, +x_down, +x_kind}:
      pair(~Ma.State<N>, ~(Overlap.Bollinger<N> & Overlap.Bollinger<N>), ma(~N, x_average), x_average_a => x_average_b =>
        pair(~Moments.Cached<N>, ~(Overlap.Bollinger<N> & Overlap.Bollinger<N>), moments(~N, x_moments), x_moments_a => x_moments_b =>
          (Overlap.Bollinger{x_average_a, x_moments_a, x_up, x_down, x_kind}, Overlap.Bollinger{x_average_b, x_moments_b, x_up, x_down, x_kind})))

def overlap.acceleration(~N: Data, value: Overlap.Acceleration<N>) -> Overlap.Acceleration<N> & Overlap.Acceleration<N>:
  match value:
    case Overlap.Acceleration{x_upper, x_middle, x_lower}:
      pair(~RollingAverage.State<N>, ~(Overlap.Acceleration<N> & Overlap.Acceleration<N>), rolling_average(~N, x_upper), x_upper_a => x_upper_b =>
        pair(~RollingAverage.State<N>, ~(Overlap.Acceleration<N> & Overlap.Acceleration<N>), rolling_average(~N, x_middle), x_middle_a => x_middle_b =>
          pair(~RollingAverage.State<N>, ~(Overlap.Acceleration<N> & Overlap.Acceleration<N>), rolling_average(~N, x_lower), x_lower_a => x_lower_b =>
            (Overlap.Acceleration{x_upper_a, x_middle_a, x_lower_a}, Overlap.Acceleration{x_upper_b, x_middle_b, x_lower_b}))))

def overlap.chandekroll(~N: Data, value: Overlap.ChandeKroll<N>) -> Overlap.ChandeKroll<N> & Overlap.ChandeKroll<N>:
  match value:
    case Overlap.ChandeKroll{x_prices, x_stops, +x_atr, +x_factor}:
      pair(~ExtremaQueue.State<N>, ~(Overlap.ChandeKroll<N> & Overlap.ChandeKroll<N>), extrema_queue(~N, x_prices), x_prices_a => x_prices_b =>
        pair(~ExtremaQueue.State<N>, ~(Overlap.ChandeKroll<N> & Overlap.ChandeKroll<N>), extrema_queue(~N, x_stops), x_stops_a => x_stops_b =>
          (Overlap.ChandeKroll{x_prices_a, x_stops_a, x_atr, x_factor}, Overlap.ChandeKroll{x_prices_b, x_stops_b, x_atr, x_factor})))

def momentum.flow(~N: Data, value: Momentum.Flow<N>) -> Momentum.Flow<N> & Momentum.Flow<N>:
  match value:
    case Momentum.Flow{+x_period, +x_previous, x_window}:
      pair(~Window.State<Momentum.Flows<N>>, ~(Momentum.Flow<N> & Momentum.Flow<N>), window(~Momentum.Flows<N>, x_window), x_window_a => x_window_b =>
        (Momentum.Flow{x_period, x_previous, x_window_a}, Momentum.Flow{x_period, x_previous, x_window_b}))

def directional.adxr(~N: Data, value: Directional.ADXR<N>) -> Directional.ADXR<N> & Directional.ADXR<N>:
  match value:
    case Directional.ADXR{+x_adx, x_history}:
      pair(~Window.State<N>, ~(Directional.ADXR<N> & Directional.ADXR<N>), window(~N, x_history), x_history_a => x_history_b =>
        (Directional.ADXR{x_adx, x_history_a}, Directional.ADXR{x_adx, x_history_b}))

def momentum_window.box(~N: Data, value: MomentumWindow.Box<N>) -> MomentumWindow.Box<N> & MomentumWindow.Box<N>:
  match value:
    case MomentumWindow.Box{+x_period, x_range}:
      pair(~ExtremaQueue.State<N>, ~(MomentumWindow.Box<N> & MomentumWindow.Box<N>), extrema_queue(~N, x_range), x_range_a => x_range_b =>
        (MomentumWindow.Box{x_period, x_range_a}, MomentumWindow.Box{x_period, x_range_b}))

def momentum_window.prices(~N: Data, value: MomentumWindow.Prices<N>) -> MomentumWindow.Prices<N> & MomentumWindow.Prices<N>:
  match value:
    case MomentumWindow.Prices{+x_period, x_window}:
      pair(~Window.State<N>, ~(MomentumWindow.Prices<N> & MomentumWindow.Prices<N>), window(~N, x_window), x_window_a => x_window_b =>
        (MomentumWindow.Prices{x_period, x_window_a}, MomentumWindow.Prices{x_period, x_window_b}))

def momentum_smooth.dual(~N: Data, value: MomentumSmooth.Dual<N>) -> MomentumSmooth.Dual<N> & MomentumSmooth.Dual<N>:
  match value:
    case MomentumSmooth.Dual{x_first, x_second, +x_delay, +x_origin}:
      pair(~Ma.State<N>, ~(MomentumSmooth.Dual<N> & MomentumSmooth.Dual<N>), ma(~N, x_first), x_first_a => x_first_b =>
        pair(~Ma.State<N>, ~(MomentumSmooth.Dual<N> & MomentumSmooth.Dual<N>), ma(~N, x_second), x_second_a => x_second_b =>
          (MomentumSmooth.Dual{x_first_a, x_second_a, x_delay, x_origin}, MomentumSmooth.Dual{x_first_b, x_second_b, x_delay, x_origin})))

def momentum_smooth.macd(~N: Data, value: MomentumSmooth.MACD<N>) -> MomentumSmooth.MACD<N> & MomentumSmooth.MACD<N>:
  match value:
    case MomentumSmooth.MACD{x_oscillator, x_signal}:
      pair(~MomentumSmooth.Dual<N>, ~(MomentumSmooth.MACD<N> & MomentumSmooth.MACD<N>), momentum_smooth.dual(~N, x_oscillator), x_oscillator_a => x_oscillator_b =>
        pair(~Ma.State<N>, ~(MomentumSmooth.MACD<N> & MomentumSmooth.MACD<N>), ma(~N, x_signal), x_signal_a => x_signal_b =>
          (MomentumSmooth.MACD{x_oscillator_a, x_signal_a}, MomentumSmooth.MACD{x_oscillator_b, x_signal_b})))

def momentum_smooth.stoch(~N: Data, value: MomentumSmooth.Stoch<N>) -> MomentumSmooth.Stoch<N> & MomentumSmooth.Stoch<N>:
  match value:
    case MomentumSmooth.Stoch{x_box, x_k, x_d}:
      pair(~MomentumWindow.Box<N>, ~(MomentumSmooth.Stoch<N> & MomentumSmooth.Stoch<N>), momentum_window.box(~N, x_box), x_box_a => x_box_b =>
        pair(~Ma.State<N>, ~(MomentumSmooth.Stoch<N> & MomentumSmooth.Stoch<N>), ma(~N, x_k), x_k_a => x_k_b =>
          pair(~Ma.State<N>, ~(MomentumSmooth.Stoch<N> & MomentumSmooth.Stoch<N>), ma(~N, x_d), x_d_a => x_d_b =>
            (MomentumSmooth.Stoch{x_box_a, x_k_a, x_d_a}, MomentumSmooth.Stoch{x_box_b, x_k_b, x_d_b}))))

def momentum_composite.stochrsi(~N: Data, value: MomentumComposite.StochRSI<N>) -> MomentumComposite.StochRSI<N> & MomentumComposite.StochRSI<N>:
  match value:
    case MomentumComposite.StochRSI{+x_rsi, x_stoch}:
      pair(~MomentumSmooth.Stoch<N>, ~(MomentumComposite.StochRSI<N> & MomentumComposite.StochRSI<N>), momentum_smooth.stoch(~N, x_stoch), x_stoch_a => x_stoch_b =>
        (MomentumComposite.StochRSI{x_rsi, x_stoch_a}, MomentumComposite.StochRSI{x_rsi, x_stoch_b}))

def momentum_smooth.pipeline(~N: Data, value: MomentumSmooth.Pipeline<N>) -> MomentumSmooth.Pipeline<N> & MomentumSmooth.Pipeline<N>:
  match value:
    case MomentumSmooth.Pipeline{+x_count, x_stages}:
      pair(~List<&1, Ma.State<N>>, ~(MomentumSmooth.Pipeline<N> & MomentumSmooth.Pipeline<N>), list(~Ma.State<N>, ~(x => ma(~N, x)), x_stages), x_stages_a => x_stages_b =>
        (MomentumSmooth.Pipeline{x_count, x_stages_a}, MomentumSmooth.Pipeline{x_count, x_stages_b}))

def momentum_smooth.trix(~N: Data, value: MomentumSmooth.Trix<N>) -> MomentumSmooth.Trix<N> & MomentumSmooth.Trix<N>:
  match value:
    case MomentumSmooth.Trix{x_pipeline, +x_previous}:
      pair(~MomentumSmooth.Pipeline<N>, ~(MomentumSmooth.Trix<N> & MomentumSmooth.Trix<N>), momentum_smooth.pipeline(~N, x_pipeline), x_pipeline_a => x_pipeline_b =>
        (MomentumSmooth.Trix{x_pipeline_a, x_previous}, MomentumSmooth.Trix{x_pipeline_b, x_previous}))

def momentum_smooth.dosc(~N: Data, value: MomentumSmooth.Dosc<N>) -> MomentumSmooth.Dosc<N> & MomentumSmooth.Dosc<N>:
  match value:
    case MomentumSmooth.Dosc{+x_rsi, x_pipeline, x_signal}:
      pair(~MomentumSmooth.Pipeline<N>, ~(MomentumSmooth.Dosc<N> & MomentumSmooth.Dosc<N>), momentum_smooth.pipeline(~N, x_pipeline), x_pipeline_a => x_pipeline_b =>
        pair(~Ma.State<N>, ~(MomentumSmooth.Dosc<N> & MomentumSmooth.Dosc<N>), ma(~N, x_signal), x_signal_a => x_signal_b =>
          (MomentumSmooth.Dosc{x_rsi, x_pipeline_a, x_signal_a}, MomentumSmooth.Dosc{x_rsi, x_pipeline_b, x_signal_b})))

def momentum_smooth.pso(~N: Data, value: MomentumSmooth.Pso<N>) -> MomentumSmooth.Pso<N> & MomentumSmooth.Pso<N>:
  match value:
    case MomentumSmooth.Pso{x_box, x_pipeline}:
      pair(~MomentumWindow.Box<N>, ~(MomentumSmooth.Pso<N> & MomentumSmooth.Pso<N>), momentum_window.box(~N, x_box), x_box_a => x_box_b =>
        pair(~MomentumSmooth.Pipeline<N>, ~(MomentumSmooth.Pso<N> & MomentumSmooth.Pso<N>), momentum_smooth.pipeline(~N, x_pipeline), x_pipeline_a => x_pipeline_b =>
          (MomentumSmooth.Pso{x_box_a, x_pipeline_a}, MomentumSmooth.Pso{x_box_b, x_pipeline_b})))

def momentum_composite.tsi(~N: Data, value: MomentumComposite.TSI<N>) -> MomentumComposite.TSI<N> & MomentumComposite.TSI<N>:
  match value:
    case MomentumComposite.TSI{x_numerator, x_denominator, +x_previous}:
      pair(~MomentumSmooth.Pipeline<N>, ~(MomentumComposite.TSI<N> & MomentumComposite.TSI<N>), momentum_smooth.pipeline(~N, x_numerator), x_numerator_a => x_numerator_b =>
        pair(~MomentumSmooth.Pipeline<N>, ~(MomentumComposite.TSI<N> & MomentumComposite.TSI<N>), momentum_smooth.pipeline(~N, x_denominator), x_denominator_a => x_denominator_b =>
          (MomentumComposite.TSI{x_numerator_a, x_denominator_a, x_previous}, MomentumComposite.TSI{x_numerator_b, x_denominator_b, x_previous})))

def momentum_smooth.eri(~N: Data, value: MomentumSmooth.Eri<N>) -> MomentumSmooth.Eri<N> & MomentumSmooth.Eri<N>:
  match value:
    case MomentumSmooth.Eri{x_average, +x_origin}:
      pair(~Ma.State<N>, ~(MomentumSmooth.Eri<N> & MomentumSmooth.Eri<N>), ma(~N, x_average), x_average_a => x_average_b =>
        (MomentumSmooth.Eri{x_average_a, x_origin}, MomentumSmooth.Eri{x_average_b, x_origin}))

def momentum_composite.forecast(~N: Data, value: MomentumComposite.Forecast<N>) -> MomentumComposite.Forecast<N> & MomentumComposite.Forecast<N>:
  match value:
    case MomentumComposite.Forecast{x_window, +x_previous, +x_origin}:
      pair(~RollingAverage.State<N>, ~(MomentumComposite.Forecast<N> & MomentumComposite.Forecast<N>), rolling_average(~N, x_window), x_window_a => x_window_b =>
        (MomentumComposite.Forecast{x_window_a, x_previous, x_origin}, MomentumComposite.Forecast{x_window_b, x_previous, x_origin}))

def momentum_market.cci(~N: Data, value: MomentumMarket.CCI<N>) -> MomentumMarket.CCI<N> & MomentumMarket.CCI<N>:
  match value:
    case MomentumMarket.CCI{+x_period, +x_origin, x_window}:
      pair(~Window.State<N>, ~(MomentumMarket.CCI<N> & MomentumMarket.CCI<N>), window(~N, x_window), x_window_a => x_window_b =>
        (MomentumMarket.CCI{x_period, x_origin, x_window_a}, MomentumMarket.CCI{x_period, x_origin, x_window_b}))

def momentum_market.market(~N: Data, value: MomentumMarket.Market<N>) -> MomentumMarket.Market<N> & MomentumMarket.Market<N>:
  match value:
    case MomentumMarket.Market{+x_period, +x_previous, x_window}:
      pair(~Window.State<MomentumMarket.Terms<N>>, ~(MomentumMarket.Market<N> & MomentumMarket.Market<N>), window(~MomentumMarket.Terms<N>, x_window), x_window_a => x_window_b =>
        (MomentumMarket.Market{x_period, x_previous, x_window_a}, MomentumMarket.Market{x_period, x_previous, x_window_b}))

def momentum_composite.ultimate(~N: Data, value: MomentumComposite.Ultimate<N>) -> MomentumComposite.Ultimate<N> & MomentumComposite.Ultimate<N>:
  match value:
    case MomentumComposite.Ultimate{x_first, x_second, x_third}:
      pair(~MomentumMarket.Market<N>, ~(MomentumComposite.Ultimate<N> & MomentumComposite.Ultimate<N>), momentum_market.market(~N, x_first), x_first_a => x_first_b =>
        pair(~MomentumMarket.Market<N>, ~(MomentumComposite.Ultimate<N> & MomentumComposite.Ultimate<N>), momentum_market.market(~N, x_second), x_second_a => x_second_b =>
          pair(~MomentumMarket.Market<N>, ~(MomentumComposite.Ultimate<N> & MomentumComposite.Ultimate<N>), momentum_market.market(~N, x_third), x_third_a => x_third_b =>
            (MomentumComposite.Ultimate{x_first_a, x_second_a, x_third_a}, MomentumComposite.Ultimate{x_first_b, x_second_b, x_third_b}))))

def momentum_composite.rocleg(~N: Data, value: MomentumComposite.RocLeg<N>) -> MomentumComposite.RocLeg<N> & MomentumComposite.RocLeg<N>:
  match value:
    case MomentumComposite.RocLeg{x_history, x_average, +x_weight}:
      pair(~Window.State<N>, ~(MomentumComposite.RocLeg<N> & MomentumComposite.RocLeg<N>), window(~N, x_history), x_history_a => x_history_b =>
        pair(~Ma.State<N>, ~(MomentumComposite.RocLeg<N> & MomentumComposite.RocLeg<N>), ma(~N, x_average), x_average_a => x_average_b =>
          (MomentumComposite.RocLeg{x_history_a, x_average_a, x_weight}, MomentumComposite.RocLeg{x_history_b, x_average_b, x_weight})))

def momentum_composite.roc(~N: Data, value: MomentumComposite.Roc<N>) -> MomentumComposite.Roc<N> & MomentumComposite.Roc<N>:
  match value:
    case MomentumComposite.Roc{+x_count, x_legs, x_signal}:
      pair(~List<&1, MomentumComposite.RocLeg<N>>, ~(MomentumComposite.Roc<N> & MomentumComposite.Roc<N>), list(~MomentumComposite.RocLeg<N>, ~(x => momentum_composite.rocleg(~N, x)), x_legs), x_legs_a => x_legs_b =>
        pair(~Ma.State<N>, ~(MomentumComposite.Roc<N> & MomentumComposite.Roc<N>), ma(~N, x_signal), x_signal_a => x_signal_b =>
          (MomentumComposite.Roc{x_count, x_legs_a, x_signal_a}, MomentumComposite.Roc{x_count, x_legs_b, x_signal_b})))

def window_signals.detrended(~N: Data, value: WindowSignals.Detrended<N>) -> WindowSignals.Detrended<N> & WindowSignals.Detrended<N>:
  match value:
    case WindowSignals.Detrended{x_average, x_delayed, +x_lag}:
      pair(~RollingAverage.State<N>, ~(WindowSignals.Detrended<N> & WindowSignals.Detrended<N>), rolling_average(~N, x_average), x_average_a => x_average_b =>
        pair(~Window.State<N>, ~(WindowSignals.Detrended<N> & WindowSignals.Detrended<N>), window(~N, x_delayed), x_delayed_a => x_delayed_b =>
          (WindowSignals.Detrended{x_average_a, x_delayed_a, x_lag}, WindowSignals.Detrended{x_average_b, x_delayed_b, x_lag})))

def window_signals.cloud(~N: Data, value: WindowSignals.Cloud<N>) -> WindowSignals.Cloud<N> & WindowSignals.Cloud<N>:
  match value:
    case WindowSignals.Cloud{x_tenkan, x_kijun, x_span}:
      pair(~ExtremaQueue.State<N>, ~(WindowSignals.Cloud<N> & WindowSignals.Cloud<N>), extrema_queue(~N, x_tenkan), x_tenkan_a => x_tenkan_b =>
        pair(~ExtremaQueue.State<N>, ~(WindowSignals.Cloud<N> & WindowSignals.Cloud<N>), extrema_queue(~N, x_kijun), x_kijun_a => x_kijun_b =>
          pair(~ExtremaQueue.State<N>, ~(WindowSignals.Cloud<N> & WindowSignals.Cloud<N>), extrema_queue(~N, x_span), x_span_a => x_span_b =>
            (WindowSignals.Cloud{x_tenkan_a, x_kijun_a, x_span_a}, WindowSignals.Cloud{x_tenkan_b, x_kijun_b, x_span_b}))))

def window_signals.fractal(~N: Data, value: WindowSignals.Fractal<N>) -> WindowSignals.Fractal<N> & WindowSignals.Fractal<N>:
  match value:
    case WindowSignals.Fractal{x_window, +x_left, +x_right, +x_count}:
      pair(~Window.State<Bar.HL<N>>, ~(WindowSignals.Fractal<N> & WindowSignals.Fractal<N>), window(~Bar.HL<N>, x_window), x_window_a => x_window_b =>
        (WindowSignals.Fractal{x_window_a, x_left, x_right, x_count}, WindowSignals.Fractal{x_window_b, x_left, x_right, x_count}))

def variable.entry(~N: Data, value: Variable.Entry<N>) -> Variable.Entry<N> & Variable.Entry<N>:
  match value:
    case Variable.Waiting{+x_period, +x_delay}:
      (Variable.Waiting{x_period, x_delay}, Variable.Waiting{x_period, x_delay})
    case Variable.Active{+x_period, x_average}:
      pair(~Ma.State<N>, ~(Variable.Entry<N> & Variable.Entry<N>), ma(~N, x_average), x_average_a => x_average_b =>
        (Variable.Active{x_period, x_average_a}, Variable.Active{x_period, x_average_b}))

def variable_shared.cell(~N: Data, value: VariableShared.Cell<N>) -> VariableShared.Cell<N> & VariableShared.Cell<N>:
  match value:
    case VariableShared.Cached{+x_frame}:
      (VariableShared.Cached{x_frame}, VariableShared.Cached{x_frame})
    case VariableShared.Kama{+x_period, +x_phase, +x_value, +x_cache}:
      (VariableShared.Kama{x_period, x_phase, x_value, x_cache}, VariableShared.Kama{x_period, x_phase, x_value, x_cache})
    case VariableShared.Scalar{+x_period, +x_delay, +x_count, +x_value}:
      (VariableShared.Scalar{x_period, x_delay, x_count, x_value}, VariableShared.Scalar{x_period, x_delay, x_count, x_value})
    case VariableShared.Smooth{+x_period, +x_delay, +x_state}:
      (VariableShared.Smooth{x_period, x_delay, x_state}, VariableShared.Smooth{x_period, x_delay, x_state})
    case VariableShared.Outer{+x_delay, +x_fast, +x_slow, +x_root, x_window}:
      pair(~Maybe<&1, RollingAverage.State<N>>, ~(VariableShared.Cell<N> & VariableShared.Cell<N>), maybe(~RollingAverage.State<N>, ~(x => rolling_average(~N, x)), x_window), x_window_a => x_window_b =>
        (VariableShared.Outer{x_delay, x_fast, x_slow, x_root, x_window_a}, VariableShared.Outer{x_delay, x_fast, x_slow, x_root, x_window_b}))

def variable_shared(~N: Data, value: VariableShared.State<N>) -> VariableShared.State<N> & VariableShared.State<N>:
  match value:
    case VariableShared.Pending{+x_minimum, +x_maximum, +x_kind}:
      (VariableShared.Pending{x_minimum, x_maximum, x_kind}, VariableShared.Pending{x_minimum, x_maximum, x_kind})
    case VariableShared.Shared{x_window, x_cells, +x_minimum, +x_maximum, +x_kind}:
      pair(~Window.State<N>, ~(VariableShared.State<N> & VariableShared.State<N>), window(~N, x_window), x_window_a => x_window_b =>
        pair(~List<&1, VariableShared.Cell<N>>, ~(VariableShared.State<N> & VariableShared.State<N>), list(~VariableShared.Cell<N>, ~(x => variable_shared.cell(~N, x)), x_cells), x_cells_a => x_cells_b =>
          (VariableShared.Shared{x_window_a, x_cells_a, x_minimum, x_maximum, x_kind}, VariableShared.Shared{x_window_b, x_cells_b, x_minimum, x_maximum, x_kind})))

def variable(~N: Data, value: Variable.State<N>) -> Variable.State<N> & Variable.State<N>:
  match value:
    case Variable.State{x_entries, +x_minimum, +x_maximum, +x_kind}:
      pair(~List<&1, Variable.Entry<N>>, ~(Variable.State<N> & Variable.State<N>), list(~Variable.Entry<N>, ~(x => variable.entry(~N, x)), x_entries), x_entries_a => x_entries_b =>
        (Variable.State{x_entries_a, x_minimum, x_maximum, x_kind}, Variable.State{x_entries_b, x_minimum, x_maximum, x_kind}))
    case Variable.Buffered{x_state, +x_minimum, +x_maximum}:
      pair(~VariableShared.State<N>, ~(Variable.State<N> & Variable.State<N>), variable_shared(~N, x_state), x_state_a => x_state_b =>
        (Variable.Buffered{x_state_a, x_minimum, x_maximum}, Variable.Buffered{x_state_b, x_minimum, x_maximum}))
    case Variable.Direct{}:
      (Variable.Direct{}, Variable.Direct{})

def adaptive_window.frama(~N: Data, value: AdaptiveWindow.Frama<N>) -> AdaptiveWindow.Frama<N> & AdaptiveWindow.Frama<N>:
  match value:
    case AdaptiveWindow.Frama{+x_period, x_window, +x_previous, +x_started}:
      pair(~Window.State<Bar.HL<N>>, ~(AdaptiveWindow.Frama<N> & AdaptiveWindow.Frama<N>), window(~Bar.HL<N>, x_window), x_window_a => x_window_b =>
        (AdaptiveWindow.Frama{x_period, x_window_a, x_previous, x_started}, AdaptiveWindow.Frama{x_period, x_window_b, x_previous, x_started}))

def adaptive_window.fisher(~N: Data, value: AdaptiveWindow.Fisher<N>) -> AdaptiveWindow.Fisher<N> & AdaptiveWindow.Fisher<N>:
  match value:
    case AdaptiveWindow.Fisher{x_box, +x_smoothed, +x_fish}:
      pair(~MomentumWindow.Box<N>, ~(AdaptiveWindow.Fisher<N> & AdaptiveWindow.Fisher<N>), momentum_window.box(~N, x_box), x_box_a => x_box_b =>
        (AdaptiveWindow.Fisher{x_box_a, x_smoothed, x_fish}, AdaptiveWindow.Fisher{x_box_b, x_smoothed, x_fish}))

def advanced_oscillator.crsi(~N: Data, value: AdvancedOscillator.Crsi<N>) -> AdvancedOscillator.Crsi<N> & AdvancedOscillator.Crsi<N>:
  match value:
    case AdvancedOscillator.Crsi{+x_price_rsi, +x_streak_rsi, x_rank, +x_previous, +x_streak}:
      pair(~Window.State<N>, ~(AdvancedOscillator.Crsi<N> & AdvancedOscillator.Crsi<N>), window(~N, x_rank), x_rank_a => x_rank_b =>
        (AdvancedOscillator.Crsi{x_price_rsi, x_streak_rsi, x_rank_a, x_previous, x_streak}, AdvancedOscillator.Crsi{x_price_rsi, x_streak_rsi, x_rank_b, x_previous, x_streak}))

def advanced_oscillator.smi(~N: Data, value: AdvancedOscillator.Smi<N>) -> AdvancedOscillator.Smi<N> & AdvancedOscillator.Smi<N>:
  match value:
    case AdvancedOscillator.Smi{x_box, +x_numerator, +x_denominator, +x_signal}:
      pair(~MomentumWindow.Box<N>, ~(AdvancedOscillator.Smi<N> & AdvancedOscillator.Smi<N>), momentum_window.box(~N, x_box), x_box_a => x_box_b =>
        (AdvancedOscillator.Smi{x_box_a, x_numerator, x_denominator, x_signal}, AdvancedOscillator.Smi{x_box_b, x_numerator, x_denominator, x_signal}))

def advanced_oscillator.cycle(~N: Data, value: AdvancedOscillator.Cycle<N>) -> AdvancedOscillator.Cycle<N> & AdvancedOscillator.Cycle<N>:
  match value:
    case AdvancedOscillator.Cycle{x_box, +x_fraction, +x_value}:
      pair(~MomentumWindow.Box<N>, ~(AdvancedOscillator.Cycle<N> & AdvancedOscillator.Cycle<N>), momentum_window.box(~N, x_box), x_box_a => x_box_b =>
        (AdvancedOscillator.Cycle{x_box_a, x_fraction, x_value}, AdvancedOscillator.Cycle{x_box_b, x_fraction, x_value}))

def advanced_oscillator.stc(~N: Data, value: AdvancedOscillator.Stc<N>) -> AdvancedOscillator.Stc<N> & AdvancedOscillator.Stc<N>:
  match value:
    case AdvancedOscillator.Stc{x_macd, x_first, x_second}:
      pair(~MomentumSmooth.Dual<N>, ~(AdvancedOscillator.Stc<N> & AdvancedOscillator.Stc<N>), momentum_smooth.dual(~N, x_macd), x_macd_a => x_macd_b =>
        pair(~AdvancedOscillator.Cycle<N>, ~(AdvancedOscillator.Stc<N> & AdvancedOscillator.Stc<N>), advanced_oscillator.cycle(~N, x_first), x_first_a => x_first_b =>
          pair(~AdvancedOscillator.Cycle<N>, ~(AdvancedOscillator.Stc<N> & AdvancedOscillator.Stc<N>), advanced_oscillator.cycle(~N, x_second), x_second_a => x_second_b =>
            (AdvancedOscillator.Stc{x_macd_a, x_first_a, x_second_a}, AdvancedOscillator.Stc{x_macd_b, x_first_b, x_second_b}))))

def advanced_oscillator.wave(~N: Data, value: AdvancedOscillator.Wave<N>) -> AdvancedOscillator.Wave<N> & AdvancedOscillator.Wave<N>:
  match value:
    case AdvancedOscillator.Wave{+x_center, +x_deviation, +x_average, x_signal, +x_previous}:
      pair(~RollingAverage.State<N>, ~(AdvancedOscillator.Wave<N> & AdvancedOscillator.Wave<N>), rolling_average(~N, x_signal), x_signal_a => x_signal_b =>
        (AdvancedOscillator.Wave{x_center, x_deviation, x_average, x_signal_a, x_previous}, AdvancedOscillator.Wave{x_center, x_deviation, x_average, x_signal_b, x_previous}))

def trend_composite.delayed(~N: Data, value: TrendComposite.Delayed<N>) -> TrendComposite.Delayed<N> & TrendComposite.Delayed<N>:
  match value:
    case TrendComposite.Delayed{+x_skip, x_average}:
      pair(~Ma.State<N>, ~(TrendComposite.Delayed<N> & TrendComposite.Delayed<N>), ma(~N, x_average), x_average_a => x_average_b =>
        (TrendComposite.Delayed{x_skip, x_average_a}, TrendComposite.Delayed{x_skip, x_average_b}))

def trend_composite.macd(~N: Data, value: TrendComposite.Macd<N>) -> TrendComposite.Macd<N> & TrendComposite.Macd<N>:
  match value:
    case TrendComposite.Macd{x_fast, x_slow, x_signal, +x_origin}:
      pair(~TrendComposite.Delayed<N>, ~(TrendComposite.Macd<N> & TrendComposite.Macd<N>), trend_composite.delayed(~N, x_fast), x_fast_a => x_fast_b =>
        pair(~TrendComposite.Delayed<N>, ~(TrendComposite.Macd<N> & TrendComposite.Macd<N>), trend_composite.delayed(~N, x_slow), x_slow_a => x_slow_b =>
          pair(~Ma.State<N>, ~(TrendComposite.Macd<N> & TrendComposite.Macd<N>), ma(~N, x_signal), x_signal_a => x_signal_b =>
            (TrendComposite.Macd{x_fast_a, x_slow_a, x_signal_a, x_origin}, TrendComposite.Macd{x_fast_b, x_slow_b, x_signal_b, x_origin}))))

def trend_composite.leg(~N: Data, value: TrendComposite.Leg<N>) -> TrendComposite.Leg<N> & TrendComposite.Leg<N>:
  match value:
    case TrendComposite.Leg{+x_skip, x_state}:
      pair(~MomentumComposite.RocLeg<N>, ~(TrendComposite.Leg<N> & TrendComposite.Leg<N>), momentum_composite.rocleg(~N, x_state), x_state_a => x_state_b =>
        (TrendComposite.Leg{x_skip, x_state_a}, TrendComposite.Leg{x_skip, x_state_b}))

def trend_composite.kst(~N: Data, value: TrendComposite.Kst<N>) -> TrendComposite.Kst<N> & TrendComposite.Kst<N>:
  match value:
    case TrendComposite.Kst{x_legs, x_signal}:
      pair(~List<&1, TrendComposite.Leg<N>>, ~(TrendComposite.Kst<N> & TrendComposite.Kst<N>), list(~TrendComposite.Leg<N>, ~(x => trend_composite.leg(~N, x)), x_legs), x_legs_a => x_legs_b =>
        pair(~Ma.State<N>, ~(TrendComposite.Kst<N> & TrendComposite.Kst<N>), ma(~N, x_signal), x_signal_a => x_signal_b =>
          (TrendComposite.Kst{x_legs_a, x_signal_a}, TrendComposite.Kst{x_legs_b, x_signal_b})))

def squeeze(~N: Data, value: Squeeze.State<N>) -> Squeeze.State<N> & Squeeze.State<N>:
  match value:
    case Squeeze.Squeeze{x_box, x_bands, x_center, x_range, x_regression, +x_previous, +x_factors}:
      pair(~MomentumWindow.Box<N>, ~(Squeeze.State<N> & Squeeze.State<N>), momentum_window.box(~N, x_box), x_box_a => x_box_b =>
        pair(~Moments.Cached<N>, ~(Squeeze.State<N> & Squeeze.State<N>), moments(~N, x_bands), x_bands_a => x_bands_b =>
          pair(~RollingAverage.State<N>, ~(Squeeze.State<N> & Squeeze.State<N>), rolling_average(~N, x_center), x_center_a => x_center_b =>
            pair(~RollingAverage.State<N>, ~(Squeeze.State<N> & Squeeze.State<N>), rolling_average(~N, x_range), x_range_a => x_range_b =>
              pair(~RollingAverage.State<N>, ~(Squeeze.State<N> & Squeeze.State<N>), rolling_average(~N, x_regression), x_regression_a => x_regression_b =>
                (Squeeze.Squeeze{x_box_a, x_bands_a, x_center_a, x_range_a, x_regression_a, x_previous, x_factors}, Squeeze.Squeeze{x_box_b, x_bands_b, x_center_b, x_range_b, x_regression_b, x_previous, x_factors}))))))

def statistics_window.pair(~N: Data, value: StatisticsWindow.PairCached<N>) -> StatisticsWindow.PairCached<N> & StatisticsWindow.PairCached<N>:
  match value:
    case StatisticsWindow.PairCached{x_window, +x_cache}:
      pair(~Window.State<StatisticsWindow.PairValue<N>>, ~(StatisticsWindow.PairCached<N> & StatisticsWindow.PairCached<N>), window(~StatisticsWindow.PairValue<N>, x_window), a => b =>
        (StatisticsWindow.PairCached{a, x_cache}, StatisticsWindow.PairCached{b, x_cache}))

def statistics_window.beta(~N: Data, value: StatisticsWindow.Beta<N>) -> StatisticsWindow.Beta<N> & StatisticsWindow.Beta<N>:
  match value:
    case StatisticsWindow.Beta{+x_previous, x_window}:
      pair(~StatisticsWindow.PairCached<N>, ~(StatisticsWindow.Beta<N> & StatisticsWindow.Beta<N>), statistics_window.pair(~N, x_window), x_window_a => x_window_b =>
        (StatisticsWindow.Beta{x_previous, x_window_a}, StatisticsWindow.Beta{x_previous, x_window_b}))

def volatility_window.rogerssatchell(~N: Data, value: VolatilityWindow.RogersSatchell<N>) -> VolatilityWindow.RogersSatchell<N> & VolatilityWindow.RogersSatchell<N>:
  match value:
    case VolatilityWindow.RogersSatchell{x_window, +x_scale}:
      pair(~RollingAverage.State<N>, ~(VolatilityWindow.RogersSatchell<N> & VolatilityWindow.RogersSatchell<N>), rolling_average(~N, x_window), x_window_a => x_window_b =>
        (VolatilityWindow.RogersSatchell{x_window_a, x_scale}, VolatilityWindow.RogersSatchell{x_window_b, x_scale}))

def volatility_window.rvi(~N: Data, value: VolatilityWindow.Rvi<N>) -> VolatilityWindow.Rvi<N> & VolatilityWindow.Rvi<N>:
  match value:
    case VolatilityWindow.Rvi{x_window, +x_previous, +x_up, +x_down}:
      pair(~Moments.Cached<N>, ~(VolatilityWindow.Rvi<N> & VolatilityWindow.Rvi<N>), moments(~N, x_window), x_window_a => x_window_b =>
        (VolatilityWindow.Rvi{x_window_a, x_previous, x_up, x_down}, VolatilityWindow.Rvi{x_window_b, x_previous, x_up, x_down}))

def volatility_window.rvir(~N: Data, value: VolatilityWindow.Rvir<N>) -> VolatilityWindow.Rvir<N> & VolatilityWindow.Rvir<N>:
  match value:
    case VolatilityWindow.Rvir{x_high, x_low}:
      pair(~VolatilityWindow.Rvi<N>, ~(VolatilityWindow.Rvir<N> & VolatilityWindow.Rvir<N>), volatility_window.rvi(~N, x_high), x_high_a => x_high_b =>
        pair(~VolatilityWindow.Rvi<N>, ~(VolatilityWindow.Rvir<N> & VolatilityWindow.Rvir<N>), volatility_window.rvi(~N, x_low), x_low_a => x_low_b =>
          (VolatilityWindow.Rvir{x_high_a, x_low_a}, VolatilityWindow.Rvir{x_high_b, x_low_b})))

def hikkake(~N: Data, value: Hikkake.State<N>) -> Hikkake.State<N> & Hikkake.State<N>:
  match value:
    case Hikkake.State{+x_modified, +x_remaining, x_near, +x_history, +x_pending}:
      pair(~Candle.State<N>, ~(Hikkake.State<N> & Hikkake.State<N>), candle(~N, x_near), x_near_a => x_near_b =>
        (Hikkake.State{x_modified, x_remaining, x_near_a, x_history, x_pending}, Hikkake.State{x_modified, x_remaining, x_near_b, x_history, x_pending}))

def hilbert(~N: Data, value: Hilbert.State<N>) -> Hilbert.State<N> & Hilbert.State<N>:
  match value:
    case Hilbert.State{+x_kind, +x_count, +x_prices, +x_filters, +x_cycle, +x_period, +x_phase, +x_averages, +x_waves, +x_days, x_history}:
      pair(~Window.State<Hilbert.Sample<N>>, ~(Hilbert.State<N> & Hilbert.State<N>), window(~Hilbert.Sample<N>, x_history), x_history_a => x_history_b =>
        (Hilbert.State{x_kind, x_count, x_prices, x_filters, x_cycle, x_period, x_phase, x_averages, x_waves, x_days, x_history_a}, Hilbert.State{x_kind, x_count, x_prices, x_filters, x_cycle, x_period, x_phase, x_averages, x_waves, x_days, x_history_b}))

def preview.output(~O: Data, ~S: Type, original: S, result: S & Maybe<&2, O>) -> S & Maybe<&2, O>:
  (discarded, output) = result
  (original, output)

def preview.read(~I: Data, ~O: Data, ~S: Type, ~step: S -> I -> S & Maybe<&2, O>, value: I, result: S & S) -> S & Maybe<&2, O>:
  (original, speculative) = result
  preview.output(~O, ~S, original, step(speculative, value))

def preview(~I: Data, ~O: Data, ~S: Type, ~copy: S -> S & S, ~step: S -> I -> S & Maybe<&2, O>, state: S, value: I) -> S & Maybe<&2, O>:
  preview.read(~I, ~O, ~S, ~step, value, copy(state))
