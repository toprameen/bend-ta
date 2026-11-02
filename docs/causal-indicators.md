# Causal, dynamic and anchored indicators

These interfaces follow the authored algorithms at TA-Lib commit
[`ccd3172940ed1d9daa4e7197f2265810852e8910`](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input).
They preserve one output slot per observation. Batch uses the same `next` as a
continued stream. Initialize a new state to reset an anchor or index origin.
Parameters are explicit; the facade supplies no implicit reference defaults.

## Inputs, outputs and warm-up

| Interface | Input | Parameters | First available output, zero-based |
|---|---|---|---|
| `DPO` | F32 price | period 2..100000 | max(period−1, floor(period/2)+1) |
| `RVOL` | F32 volume | period 1..100000 | period |
| `ICHIMOKU` | `Bar.HL<F32>` | tenkan, kijun, span_b, each 2..100000 | max(tenkan,kijun,span_b)−1 |
| `FRACTAL` | `Bar.HL<F32>` | left, right, each 1..100000 | left+right |
| `ZIGZAG` | `Bar.HL<F32>` | sensitivity 0..100, minimum 1..100000 | minimum |
| `MAVP` | `MAVP.Sample()` | minimum, maximum 1..10000; minimum≤maximum; MA kind | `Ma.lookback(maximum,kind)` |
| `VWAP` | `Bar.HLCV<F32>` | none | 0 |
| `DIV` | `Transform.Operands<F32>` | none | stateless |

Configured interfaces expose `State()`, `init`, `next` and `batch`. Invalid
configuration returns `Parameters.InvalidParameter` before allocating windows.
`VWAP.init()` returns its state directly and `VWAP.batch` returns the output
list directly. `DIV` returns the scalar division directly. Input constructors
live in `core/bar.bend`, `core/variable.bend` and `core/transform.bend`.

## Calculation time and chart position

`DPO` subtracts the current period's SMA from the price
floor(period/2)+1 observations ago. At period 2 it needs an extra observation
beyond the SMA's own warm-up. Its centered, compensated mean cache refreshes
after each logical wrap and falls back to a fresh scan when a numerical guard
rejects an update. Storage is O(period); scheduled refreshes give amortized O(1)
updates, while a guard fallback can cost O(period). Floating arithmetic need not
be bitwise equal to TA-Lib's running sum.

`ICHIMOKU.Value()` has `tenkan`, `kijun`, `span_a` and `span_b`. Each midpoint
uses the highest high and lowest low of its own current window. Span A is the
mean of Tenkan and Kijun. All four fields become available together after the
longest window; periods need not be ordered. There is no Chikou close output.

`FRACTAL.Value()` has `high` and `low` flags, each 100 or 0, plus the confirmed
pivot's absolute `index`. A candidate is a strict high/low against every other
bar in its left/right window. Ties suppress the corresponding flag; both flags
may be set for an outside bar. The output arrives only after `right` later
observations confirm the candidate. Earlier output slots are never rewritten.

`DisplayShift()` is `{backward: Bool, bars: U32}` from `core/window_signals.bend`.
`DPO.display_shift(period)` is backward by floor(period/2)+1;
`FRACTAL.display_shift(right)` is backward by right;
`ICHIMOKU.display_shift(kijun)` is forward by kijun for both spans. These helpers
assume valid parameters. They describe chart placement only: calculation and
availability remain at the current input slot. They do not move arrays or
make later confirmation available earlier.

`ZIGZAG.Value()` has the current `pivot`, `direction: Bar.Direction` and absolute
pivot `index`. The first bar seeds a down leg at its low. A reversal is tested
before extension and requires the sensitivity threshold and minimum age since
the last extreme. Equal extremes reset that age. Reversal replaces the running
pivot with the current high or low. This is the pinned source's causal running
pivot, not a retrospectively interpolated polyline. No future bar is read.

Fractal and ZigZag indices start at zero. As with indexed extrema, a state
supports at most 4294967295 observations: the final valid index is 4294967294.
Reset before the count wraps. Resetting begins a new index origin.

## Dynamic moving averages

`MAVP.Sample()` contains `{price: F32, period: F32}`. Each period is clamped in
the real domain before integer truncation: NaN and values below minimum select
minimum; values above maximum, including positive infinity, select maximum.
No nonfinite value reaches an unchecked float-to-integer conversion.

MA kinds follow [the moving-average contract](overlap-statistics.md). Kind 11
(`DEFAULT`) is accepted only when maximum=1; unknown kinds fail. This validates
the entire bank before reading observations, even if an invalid kind might not
be requested by particular data. Period 1 retains the underlying identity rule.

All selections retain the common maximum-period lookback. Recursive averages
start after `lookback(maximum)−lookback(period)` observations, so their seeds
stay aligned when the selected period changes. No recursive state is advanced
only when selected.

A shared price window serves banks containing at least four periods. SMA, WMA,
TRIMA and KAMA retain each period's guarded arithmetic cache and refresh clock,
using the same calculations as fixed-period MA states. HMA shares its raw
fast/slow history and retains only each period's square-root-sized outer window.
VIDYA keeps a scalar recurrence per period; ZLEMA keeps one EMA per period.
ALMA uses selected-window evaluation when the band contains at least 12 periods,
constructing its deterministic weights for that output; narrower bands retain
cached weight banks. Smaller bands keep their ordinary states: the extra
outgoing-value slot in a shared tape can erase the storage saving for two
nearby periods. Identity banks need no history.

Let R=maximum−minimum+1 and p be the selected period. SMA/WMA/TRIMA, KAMA and
ZLEMA use O(maximum+R) storage; HMA uses
O(maximum+R+sum(sqrt(period))). Their normal cached updates traverse R entries;
scheduled refreshes and numerical guard fallbacks scan the affected windows.
The first complete output can seed every period's cache, costing the sum of
their window lengths. VIDYA uses O(maximum+R) storage but scans the active CMO
windows on each update. Wide-band ALMA uses O(maximum) storage and O(p) work per
available output. Other recursive kinds retain independent constant-size states
and O(R) traversal. No broad bank duplicates every full raw-price window. The
public limit does not promise that every accepted bank is economical. Batch and
streaming use the same transitions.

`tests/core/mavp.bend` retains compact pinned-C targets from TA-Lib revision
`ccd3172940ed1d9daa4e7197f2265810852e8910`, unstable periods zero, for SMA, WMA,
TRIMA, KAMA, HMA, ZLEMA, VIDYA and ALMA. It checks complete warm-up alignment and
changing period choices with 1e−5 absolute tolerance. Larger exact baseline and
numeric-adapter comparisons remain external validation evidence.

## Volume and undefined arithmetic

`RVOL` divides today's volume by the mean of the preceding period volumes,
reading the cached mean before pushing today's observation. Its centered,
compensated cache refreshes after each logical wrap and uses a fresh scan when
a numerical guard rejects an update. Storage is O(period), with amortized O(1)
scheduled updates and O(period) guard fallbacks. An all-zero baseline is exactly
zero; raw division returns Inf or NaN as appropriate inside `Some`, rather than
a fallback or warm-up slot.
`DIV` likewise uses raw Base IEEE division and preserves signed zero.

`VWAP` accumulates typical-price times volume and total volume from initialization.
It starts at zero, updates the ratio when cumulative volume is positive, and
otherwise repeats its previous value. Choose sessions/anchors outside the
library by creating new state. Both batch and streaming skip a bar when its
computed typical price or volume is nonfinite and repeat the prior value.
This adopts the pinned batch rule consistently; the reference C streaming API
instead rejects nonfinite bars. Finite products that overflow are accumulated,
so overflow remains visible. Typical-price arithmetic itself can overflow in
F32, in which case that bar is skipped by the stated computed-price rule.

Other interfaces assume finite observations in arrival order. None validates
market-bar ordering or repairs missing data. F32 rounding, overflow and branch
thresholds can differ from the reference's double arithmetic; these contracts
claim neither universal TA-Lib parity nor financial-data error bounds.

DPO and RVOL require O(period) storage and use the guarded mean caches described
above.
Ichimoku maintains three extrema queue pairs, using O(sum of its periods)
storage and amortized constant update work, with an O(period) prune burst.
Fractal scans left+right+1 observations.
ZigZag and VWAP have constant-size state and constant work per observation.
