# Adaptive trends and composed oscillators

All interfaces below expose `init`, `next` and `batch` in `src/f32.bend`.
Periods, MA selectors and coefficients are runtime parameters. Invalid settings
return `Parameters.InvalidParameter`; validation precedes allocation. Batches
use the streaming transition and retain one optional output per input.

Periods are at most 100000. A period is at least 2 except where specified below;
CRSI's rank window is at most 10000. Real parameters must be finite and within
TA-Lib's parameter range, bounded in magnitude by 3e37. Input observations must
be finite; missing-data handling and nonfinite recovery are caller concerns.

The reference is TA-Lib revision
[`ccd3172940ed1d9daa4e7197f2265810852e8910`](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input).
The recipes follow its authored function sources with all unstable periods set
to zero. The library does not expose TA-Lib's process-global unstable or automatic
stabilization settings. The reference fixtures use the pinned C implementation,
F32-representable observations, and tolerance `max(0.0004, abs(reference)*0.0004)`.
These examples establish neither double-precision parity nor an error bound.

## Adaptive and trailing lines

| Interface | Input and parameters | First output index and seed |
|---|---|---|
| FRAMA | HL; even period | `period`; the preceding midpoint seeds the recurrence |
| MCGD | real; period | `period-1`; first observation seeds the line |
| SAR | HL; acceleration, maximum | 1; first bar seeds the second bar's stop |
| SAREXT | HL; start, reversal offset, long init/step/max, short init/step/max | 1; zero start selects SAR's initial direction; positive/negative start forces long/short |
| SUPERTREND | HLC; ATR period, multiplier | `period`; first ATR seeds both bands and an uptrend |

FRAMA partitions its full HL window into two equal halves. Its alpha is
`exp((-4.6/log(2))*log((range1+range2)/range))` when both half ranges are positive
and their sum exceeds the whole range; otherwise the line is the current
midpoint. The recurrence uses `alpha*midpoint + (1-alpha)*previous`.

MCGD updates `previous + (price-previous)/(period*(price/previous)^4)`.
It retains the previous line if that candidate is nonfinite, including a zero
price that produces an undefined or overflowing step. Its intended domain is
positive prices; finite signed and zero inputs follow this explicit recurrence.

SAR and SAREXT share the same stop engine. A strictly positive minus-directional
movement selects an initial short trade; ties select long. A low equal to a
long stop reverses short, and a high equal to a short stop reverses long.
The first update clamps against the second bar twice, matching the reference's
startup convention. Acceleration initial values and steps are capped at the
corresponding maximum. SAREXT applies its multiplicative offset at reversal and
negates short outputs; SAR emits the unsigned stop. Forced SAREXT starts preserve
those reversal tests on the first published bar.

SUPERTREND carries upper and lower bands independently and releases each using
the preceding close. It tests the current close against the current carried band.
The value contains `line` and `direction` (`Bar.Up` or `Bar.Down`). A zero
multiplier is supported; the independent bands can cross and need not remain on
the expected side of the close.

## Window and recursive oscillators

| Interface | Parameters and output | First output index |
|---|---|---|
| CG | period; real | `period-1` |
| CTI | period; real | `period-1` |
| FISHER | HL period; `Lines{first: fisher, second: previous fisher}` | `period-1` |
| CRSI | price RSI period, streak RSI period, rank period; real | `max(price period, streak period+1, rank period+1)` |
| SMI | HLC range period, fast EMA, slow EMA, signal EMA; `Lines{SMI, signal}` | `range+fast+slow+signal-4` |
| STC | fast EMA, slow EMA, cycle period; real | `max(fast,slow)-1+2*(cycle-1)` |
| WAVETREND | HLC channel, average, signal; `Lines{WT1, WT2}` | `2*(channel-1)+average-1+signal-1` |

CG weights observations from oldest to newest by `period..1`, negates the
weighted/plain sum ratio, and uses `-(period+1)/2` when the signed denominator is
exactly zero. Its fresh F32 window sums replace the C implementation's exact
multi-limb sums; cancellation and overflow remain possible on signed inputs.
CTI correlates prices against a rising ramp. Fresh deviations around the newest
price avoid subtracting raw price-level moments. It returns zero for a degenerate
price variance and clamps a computed correlation to [-1,1].

FISHER uses the midpoint series for both channel extremes. A range within
`1e-14*(abs(highest)+abs(lowest))` is neutral. Its zero-seeded smoothing uses 0.66
and 0.67, limits values above 0.99 to 0.999 (symmetrically below -0.99), and feeds
the limited value back. The trigger is the preceding transformed value, initially
zero.

CRSI averages Wilder RSI of closes, Wilder RSI of signed run lengths, and the
strict percent rank of the current one-bar return among the preceding rank-window
returns. Equal closes reset the run to zero; a zero preceding close gives return
zero. The streak's first input is on the second bar, so its RSI requires an extra
bar. Flat RSI uses the shared RSI neutral value of 50.

SMI smooths `close-(highest+lowest)/2` and `highest-lowest` separately through
slow then fast SMA-seeded EMAs. It divides the first by half the second and
multiplies by 100; an exactly zero divisor gives zero. The signal is another
SMA-seeded EMA and withholds earlier SMI values until both outputs exist.

STC uses the aligned MACD EMA seeds, swapping fast and slow periods when needed.
Each of its two stochastic stages retains its preceding fraction on an exactly
zero range, initially zero. Each half-weight smoother seeds from its first
fraction.

WAVETREND stages typical price EMA, absolute-distance EMA, normalized-distance
EMA, then a simple signal mean. Average and signal periods may be 1. Once the
price EMA is seeded, a repeated typical-price/EMA pair forces the distance to
zero; this avoids a frozen F32 residual becoming an oscillator extreme on flat
data. A zero scaled divisor `0.015*deviation` also gives zero.

## MA composition and squeeze state

MACDEXT accepts fast period/type, slow period/type and signal period/type and
returns `MACDValue{line, signal, histogram}`. The fast/slow periods and their types
are swapped together when the slow period is smaller. Each MA begins after an
explicit delay so its first output aligns with the longer lookback; the signal
then consumes the resulting difference. Its first index is
`max(MAlookback(fast,type), MAlookback(slow,type))+MAlookback(signal,type)`.

KSTEXT accepts four ROC periods, four MA periods, signal period, leg MA type and
signal MA type. ROC and MA periods may be 1. Each leg begins after its own delay,
so its seed ends at the longest `ROCperiod+MAlookback`. The four weighted lines
sum in order with weights 1,2,3,4; the signal consumes this sum. Output is
`Lines{KST, signal}`, beginning at that longest lookback plus the signal lookback.

MA selectors follow the shared MA contract, including period-1 identity and
selector 10 disabled. Selector 11 is rejected above period 1. The common
`Ma.lookback(period,kind)` helper assumes validated configuration and zero
instability; it describes the shared factories' seed schedules.

SQZMOM accepts BB period/deviation, KC period, and wide/normal/narrow channel
factors, ordered `wide >= normal >= narrow >= 0`. It computes close-population
Bollinger bands, a simple true-range mean, an HL Donchian midpoint and a close
mean. The close's deviation from the midpoint/mean anchor feeds a KC-period
endpoint regression. Its first index is `max(BB-1, 2*(KC-1))`.

`SqueezeValue{momentum, negative, strength}` encodes squeeze levels 3 (inside
narrow), 2 (inside normal), 1 (inside wide), 0 (between), and -1 (released, with
`negative=True` and `strength=1`). Comparisons against all bands are strict;
factor ties and zero factors are supported. Population moments and regression
reuse the centered shared F32 formulas.

## Storage, work and arithmetic

SAR, MCGD and the ATR/EMA state use constant space. Windows and lag buffers own
power-of-two arrays; their logical lengths remain the requested periods. FRAMA,
CG and CTI retain fresh chronological scans. SQZMOM retains fresh population
moments, while its close/true-range means and regression use the shared caches.
WAVETREND uses the same mean cache for its signal. Ordinary cached updates have
constant amortized work, with O(period) refreshes and guarded fresh fallbacks.
Repeated ill-conditioned windows can still require a scan on each observation.
FISHER, SMI and STC range stages use monotonic queues, with amortized constant
update work and an O(period) worst-case prune burst. SQZMOM also uses queued
range extrema and retains its population-moments scans. Stored windows and queues use
space proportional to the sum of their periods. CRSI rank scans its preceding
return window. MACDEXT and KSTEXT inherit their selected MAs' costs and KSTEXT's ROC lag
storage. Batch traversal is linear in the number of observations in addition to
indicator work and output storage.

Large accepted windows allocate substantial memory. Maximum-period validation
exercises allocation and individual completed scans; it does not promise that
all maximum periods combined are economical for long streams. F32 rounds each
operation, so EMA update ordering, centered seeds and fresh scans can differ
from TA-Lib's double/FMA arithmetic. Near branch boundaries those differences
can also affect trend or squeeze classification. Finite inputs can still produce
intermediate overflow or underflow; no universal numerical tolerance is claimed.
