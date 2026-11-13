# Momentum and directional indicators

The F32 facade binds the shared momentum and directional algorithms. The
common initialization recipes live in
`core/momentum_init.bend`. The facade validates configuration and binds numeric
operations and MA construction. Inputs and periods are runtime values. All functions expose
`State()`, `init(parameters...)`, `next(state, observation)` and
`batch(observations, parameters...)`. Batch uses the same transition as streaming;
retain the returned owned state to continue a stream. Every input has one aligned
output slot. `None` means warm-up. Finite observations in arrival order are the
input contract; no implicit sorting, missing-bar handling or OHLC validation occurs.

New configurations return `Momentum.Error()`, an alias for
`core/parameters.bend`'s `Error`, whose constructor is `InvalidParameter`.
Each period has the reference's minimum below and a maximum of 100000. Existing
SMA/EMA/RMA/direct-function configuration retains its separately documented limit.
All parameters are explicit; default values are not silently substituted. Invalid
configuration fails before any owned window is allocated. Valid empty batches
return `Done{[]}`; short inputs contain only warm-up slots.

The reference contract is TA-Lib commit
[`ccd3172940ed1d9daa4e7197f2265810852e8910`](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910),
with **all unstable periods explicitly set to zero**. The reference's automatic
stabilization policy is not enabled. There is no start-index compatibility API:
a fresh stream starts at its first supplied observation. SI starts at index 1;
ASI and WAD seed a new cumulative line with zero at index 0.

## Interface and first output

Indices are zero based. `p`, `f`, `s` and `q` refer to the corresponding explicit
periods. `L(p,kind)` means the shared MA dispatcher's warm-up; for SMA/EMA/WMA it
is `p-1`. `HL`, `HLC`, `OHLC` and `HLCV` are records in `core/bar.bend`.

| Function | Input | Parameters, in order | First output index |
|---|---|---|---|
| RSI, CMO, CMOU | F32 | period >= 2 | p |
| IMI | OHLC | period >= 2 | p-1 |
| PLUS_DM, MINUS_DM | HL | period >= 1 | max(1,p-1) |
| PLUS_DI, MINUS_DI | HLC | period >= 1 | p |
| DX | HLC | period >= 2 | p |
| ADX | HLC | period >= 2 | 2p-1 |
| ADXR | HLC | period >= 2 | 3p-2 |
| AO | HL | fast >= 2, slow >= 2 | max(f,s)-1 |
| AC | HL | fast >= 2, slow >= 2, signal >= 2 | max(f,s)+q-2 |
| APO, PPO | F32 | fast >= 2, slow >= 2, MA kind | L(max(f,s),kind) |
| MACD | F32 | fast >= 2, slow >= 2, signal >= 1 | max(f,s)+q-2 |
| MACDFIX | F32 | signal >= 1 | 25+q-1 |
| AROON, AROONOSC | HL | period >= 2 | p |
| ASI, SI | OHLC | finite limit move F32(1e-8)..F32(3e37) | 0, 1 respectively |
| CCI | HLC | period >= 2 | p-1 |
| CHOP, CHOPTR | HLC | period >= 2 | p |
| COPPOCK | F32 | WMA >= 1, ROC-1 >= 1, ROC-2 >= 1 | max(ROC-1,ROC-2)+WMA-1 |
| DOSC | F32 | RSI >= 2, first EMA >= 2, second EMA >= 2, signal SMA >= 2 | RSI+first+second+signal-3 |
| ER, VHF | F32 | period >= 2 | p |
| ERI | HLC | EMA period >= 1 | p-1 |
| FOSC | F32 | period >= 2 | p |
| KST | F32 | ROC-1..ROC-4 >= 1, SMA-1..SMA-4 >= 1, signal >= 1 | max(ROC-i+SMA-i-1)+q-1 |
| MFI | HLCV | period >= 2 | p |
| PSO | HLC | Fast-K >= 1, EMA >= 1 | Fast-K-1+2(EMA-1) |
| QSTICK | OHLC | SMA period >= 1 | p-1 |
| STOCH, KDJ | HLC | Fast-K >= 1, Slow-K >= 1, K MA kind, Slow-D >= 1, D MA kind | Fast-K-1+L(Slow-K,K kind)+L(Slow-D,D kind) |
| STOCHF | HLC | Fast-K >= 1, Fast-D >= 1, D MA kind | Fast-K-1+L(Fast-D,D kind) |
| STOCHRSI | F32 | RSI >= 2, Fast-K >= 1, Fast-D >= 1, D MA kind | RSI+Fast-K-1+L(Fast-D,D kind) |
| TRIX | F32 | EMA period >= 1 | 3(p-1)+1 |
| TSI | F32 | first EMA >= 2, second EMA >= 2 | first+second-1 |
| ULTOSC | HLC | first >= 1, second >= 1, third >= 1 | max(first,second,third) |
| VORTEX | HLC | period >= 1 | p |
| WAD | HLC | none | 0 |
| WILLR | HLC | period >= 2 | p-1 |

AROON returns `Aroon{down,up}`. MACD and MACDFIX return
`MACDValue{line,signal,histogram}`. STOCH, STOCHF, STOCHRSI and KDJ share
`StochValue{k,d,j}`, where `j=3k-2d`; the three stochastic names also expose this
useful derived field. ERI returns `Lines{first,second}` for bull power and bear
power. KST uses the same record for KST and its signal. VORTEX returns
`Vortex{plus,minus}`. These types are exposed by the function's `Value()` alias
(or `STOCH.Value()`/`MACD.Value()` for the shared output families).

Selected MA kinds follow the shared dispatcher, including its period-one
identity behavior and explicit rejection of unsupported kinds. APO/PPO swap
inverted fast/slow periods. MACD swaps them and delays the fast EMA seed so its
first complete window ends at the slow EMA's first complete window. MACDFIX uses
fixed 0.15/0.075 coefficients, rather than 2/13 and 2/27. AO/AC preserve caller
period order, so reversing the legs negates the oscillator. ULTOSC sorts its
three periods and weights the shortest, middle and longest pressure ratios 4:2:1.

## Seeds and numerical choices

RSI/CMO seed average gain and loss from the first `p` close-to-close changes,
then use Wilder smoothing. RSI returns 50 when both magnitudes are zero; CMO
returns 0. A zero change keeps the previous mathematical ratio while the smoothed
magnitudes remain positive. This prevents independent F32 decay rounding from
creating artificial RSI variation during a halt. CMOU uses the latest `p`
changes; IMI uses the latest `p` close-minus-open bodies and returns 50 for doji
windows. Their finite-window totals are recomputed, so expired movement cannot
leave a running-sum residue in a fully flat window.

Directional movement uses strict positive, strictly dominant up/down changes;
equal outside moves contribute zero. DM seeds `p-1` changes, while DI/DX apply
one Wilder update before their first output. Period-one DI returns a fraction,
without the usual factor of 100. ADX averages its first `p` eligible DX values
and freezes its live value when the source's range/DM guard is inactive. ADXR
averages ADX with its value `p-1` outputs earlier. Reference `ta_round_pos` is an
identity at the pinned revision; no integer rounding is applied.

AROON maintains a `p+1`-bar extrema queue and chooses the most recent equal extreme. AROONOSC
scales the signed numeric difference of the selected integer positions before
any price-level percentage rounding. WILLR and raw
stochastic stages maintain `p`-bar extrema queues. WILLR uses the source's scaled flatness test and
clamps to [-100,0]. Raw stochastic returns zero for a scaled-flat range; PSO
uses neutral 50, then two mean-seeded EMAs and `tanh(value/2)`. CCI uses a fresh
mean absolute deviation with the factor 0.015. CHOP uses raw highs/lows, while
CHOPTR uses true highs/lows; both return 100 for a degenerate window. CHOP is
allowed to exceed 100 after gaps. VORTEX and ULTOSC guard their true-range sums
with an exact positive comparison. ER returns 1 for a flat window; VHF returns 0.
MFI applies the pinned scaled typical-price tie test, zero-total output and
clamped positive-flow numerator. PPO retains the strict absolute 1e-14 slow-MA
guard, so its tiny-quote behavior intentionally differs from scale-invariant
range oscillators. The shared core accepts that predicate as a numeric capability.
For F32, the nearest representable 1e-14 is below the reference threshold, so
`Momentum.ppo_zero` includes that nearest lower value; this matches the strict
double threshold for representable F32 denominators. A wider facade can bind
its own predicate without changing the oscillator algorithm.

Spread oscillators and ERI smooth differences from a retained first-observation
origin. CCI forms typical-price differences before averaging. These avoid rounding
large absolute price levels before subtracting small residuals. Kind 7 MAMA
bypasses spread centering because its zero seed is not translation invariant.
FOSC keeps both regression-window values and its prior forecast relative to an
origin. It uses the shared centered regression forecast from the *preceding*
period, then compares that forecast delta with the current price delta. KST/COPPOCK and TRIX retain the
reference's ratio-first ROC arithmetic; their zero lagged denominator returns
zero. EMA chains feed only fully initialized stage outputs into the next stage.

F32 rounding still affects all recurrences, threshold tests and near-zero
ratios. Centering cannot recover input differences already lost to F32, and a
price minus a distant origin can overflow for extreme opposite-sign inputs.
Midpoint/typical-price transforms, seed totals, cumulative sums, regression
products and divisions can overflow or underflow. Long recursive tails can lose
magnitude earlier than binary64. This is not bit parity, a universal error bound,
nonfinite-data recovery or a performance claim.

## Storage and validation

Owned rings hide capacity and wrapping. RSI/CMO, DM/DI/DX/ADX, SI/ASI and WAD use
constant-size state; ADXR owns an ADX lag ring. CMOU,
IMI, MFI, CCI, CHOP/CHOPTR, VORTEX, ULTOSC, ER and VHF cost O(period) per sample
and O(period) storage. WILLR, AROON/AROONOSC and stochastic range stages use
owned monotonic extrema queues: amortized constant update work, O(period)
worst-case pruning and O(period) storage. FOSC inherits the regression
window scan. EMA stages use constant-size state; SMA and lag stages own period-sized rings. Selected SMA
and weighted means rebuild their totals in O(period) per sample; adaptive MAs
inherit their documented scan costs. KST/COPPOCK own their ROC
lags, smoothing stages and signal. Batch traversal/output storage is O(n).

`tests/reference/momentum.bend` contains source-oracle first/last values and
complete alignment checks for all 44 functions, focused neutral/tie/gap/expiry/
seed tests, invalid configurations and six chunk-continuation cases. The inert
numbers were generated from the pinned C library with unstable periods zero,
using exact representable inputs and `max(1e-4,abs(reference)*1e-4)` tolerance.
External development probes compare all outputs across mixed, flat, tiny-quote,
large-offset and halt streams, inverted periods, minimum periods and selected
MA kinds on actual native and JavaScript output. The tolerance describes these
cases only. The repository's Bend-only gate and fixture runner remain the
portable checks; external generators and raw logs are not repository sources.

## TA-Lib attribution

The implementations and reference examples were derived from the pinned
TA-Lib authored algorithms under
[`ta_codegen/input`](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input).
Retain [the complete upstream license notice](../NOTICE).
