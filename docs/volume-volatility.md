# Volume and volatility functions

These functions use the generic volume/volatility cores and the F32 facade.
Batch and streaming share one transition. `None` means warm-up; zero is a
computed value. Bars come from `src/core/bar.bend`: `CV{close,volume}`,
`HLCV{high,low,close,volume}`, `HL`, `HLC` and `HLV` request only needed fields.
Inputs are finite observations in arrival order, with consistent bar bounds;
volume is normally nonnegative. Validation, session resets and missing-data
recovery remain explicit caller responsibilities.

| Function | Input | Initialization | First output index |
|---|---|---|---:|
| AD | HLCV | Zero cumulative money-flow volume | 0 |
| OBV | CV | First observation's volume | 0 |
| NVI, PVI | CV | Index 1000 at first observation | 0 |
| PVT | CV | Zero cumulative price-volume trend | 0 |
| CMF | HLCV | Full window of money flow and volume | period-1 |
| EFI | CV | EMA seeded by mean of first period price-change × volume values | period |
| EMV | HLV | Full window of one-bar ease-of-movement values | period |
| ADR | HL | Mean of high-low ranges | period-1 |
| TRANGE | HLC | Previous close required | 1 |
| ATR | HLC | Mean of first period true ranges, then Wilder smoothing | period |
| NATR | HLC | Same ATR seed; normalize by current close | period |
| CVI | HL | Range EMA followed by lagged percent change | period-1+lag |
| MASSI | HL | Two range EMAs followed by rolling ratio sum | 2×(fast-1)+slow-1 |
| PVO | Volume scalar | Shared percentage-price-oscillator transition on volume | selected MA lookback |
| ADOSC | HLCV | Both A/D EMAs seeded from first cumulative A/D value | max(fast,slow)−1 |
| KVO | HLCV | Reference bar, then raw volume-force seeds and zero signal | max(fast,slow,signal) |
| ROGERSSATCHELL | OHLC | Full window of per-bar log variance terms | period−1 |
| RVI | Scalar | Full deviation window, then mean-seeded Wilder up/down legs | deviation_period+period−2 |
| RVIR | HL | Mean of independently initialized high and low RVIs | deviation_period+period−2 |

Each name has `State()`, `init`, `next` and `batch`. Unparameterized AD, OBV,
NVI, PVI, PVT and TRANGE initialize directly and their batches return an aligned
list. Parameterized initializers return `Result<Parameters.Error, State()>`;
their batches return the same error type around the aligned output list.
`VolumeError()` exposes that configuration error type. Empty valid batches are
empty; invalid configuration fails even with empty input. Thread state through
`Series.scan` to continue across chunks; a fresh batch starts a fresh calculation.

Period arguments are explicit and newly introduced configurations follow the
pinned limits: 1..100000 for ADR, ATR, NATR, EFI and EMV; 2..100000 for CMF,
CVI's smoothing period and both MASSI periods; CVI's lag is 1..100000.
`EMV.init(period,divisor)` requires a finite divisor in 1..3e37 (reference
default 10000). `CVI.init(period,lag)` and `MASSI.init(fast,slow)` take both
periods explicitly. PVO takes fast/slow periods and the shared MA selector;
its selector support and lookback follow the overlap/momentum contracts.

AD and CMF use zero money flow for nonpositive high-low range. CMF divides only
by a positive window volume total. NVI updates on falling volume, PVI on rising
volume, and OBV on price direction with unchanged prices retaining the total.
NVI/PVI retain the prior index when a candidate is nonfinite, while advancing
the remembered price and volume. PVT and NVI/PVI skip a relative-price update
when previous close is exactly zero. EMV returns a raw zero when the range or
computed box ratio is exactly zero; tiny nonzero values are not suppressed.

ATR, EFI, CVI and MASSI use the project's shared centered seeds and smoothing
recurrence. These interfaces apply no automatic unstable-period discard;
reference comparisons explicitly disable it. NATR period one deliberately
returns raw true range, as the pinned source does; other periods return
`100*ATR/close`, with zero for exactly zero close. MASSI substitutes ratio one
when its second EMA is exactly zero. CVI uses difference-first percent change
and an exact-zero lagged EMA guard.

AD/OBV/PVT and rolling sums can accumulate F32 error. CMF freshly scans its
window, restoring zero after all volume leaves. EMV uses a centered compensated mean cache, refreshed at each logical wrap
and rebuilt on ill-conditioned updates. Its ordinary amortized work is constant;
refreshes and guarded fallbacks cost O(period). CMF retains O(period) scan work
per input. Both use O(period) storage. ADR and MASSI inherit the rolling sum
refresh at each logical wrap: amortized constant work, with O(period) work on
that update. Other recurrences have constant work per input, with O(period)
storage where a rolling window or lag is needed.
Fresh centered means can still lose accuracy when large signed one-bar EMV
values cancel to a small mean. External checks compare both an independent
operation-by-operation F32 model and a magnitude-aware C reference tolerance
for that conditioning case. No universal error bound or double-precision
TA-Lib equivalence is established. Extreme finite input can overflow an
intermediate calculation, and input quantization is irreversible.

The compact `tests/reference/volume.bend` fixture supplies hand-calculated
examples, a pinned C example for CVI/MASSI, continuation and configuration
checks, and an NVI overflow-retention case. Broader pinned-C comparisons and
temporary numerical harnesses live outside the repository. Algorithms follow
the catalog's pinned revision; retain [the upstream notice](../THIRD_PARTY_NOTICES.md).

## Volume filters and relative volatility

`ADOSC.init(fast,slow)` and `KVO.init(fast,slow,signal)` require every period
in 2..100000. ADOSC preserves argument order: swapping fast and slow reverses
the result. It accumulates the same money-flow volume as AD, seeds both
averages from the first A/D value, then emits their difference after the
longest EMA lookback. It does not use the ordinary EMA's mean seed.

KVO returns a `KVO.Value()` record, `VolumeFilter.Lines{kvo,signal}` from
`src/core/volume_filter.bend`, with both lines ready together. The first bar
anchors prices and range. The next bar seeds both force EMAs from its force,
so the oscillator and signal begin at zero inside warm-up. Trend follows the
change in high+low+close, retaining its direction on a tie. To preserve small
representable moves on large price baselines, the change is calculated by
summing each field's difference from the preceding bar. Cumulative range
starts with both anchor ranges, resets to previous+current range on a trend
change, and otherwise accumulates the current range. Volume force is
`volume*abs(2*range/cumulative_range−1)*100*trend`, or zero when cumulative
range is exactly zero. All filter updates use difference-first EMA arithmetic.
No automatic unstable-period discard is applied.

`ROGERSSATCHELL.init(period,annualization)` requires period 1..100000 and finite
annualization in 0..3e37. It consumes OHLC bars and returns volatility in log
return units. Each positive-price bar contributes
`log(high/close)*log(high/open)+log(low/close)*log(low/open)`; any nonpositive
price contributes zero while still occupying one window slot. The result is
`sqrt(annualization)*sqrt(mean_term)`, with zero for a nonpositive mean term.
The scale is applied after the root. A centered compensated mean cache refreshes
at logical wraps and uses a fresh window on ill-conditioned updates. Consistent OHLC bounds are assumed; a malformed
bar can contribute a negative term.

`RVI.init(period,deviation_period)` and `RVIR.init(period,deviation_period)`
require smoothing periods 1..100000 and deviation periods 2..100000. RVI routes
the fresh population standard deviation into the up leg for a rising input,
into the down leg for a falling input, and into neither on a tie. Both legs
use mean-seeded Wilder smoothing. Output is `100*up/(up+down)`, or 50 for an
exactly zero total. RVIR runs that calculation independently on highs and lows
and averages the two outputs. There is no additional unstable discard.

ADOSC and KVO use constant work and storage per sample. ROGERSSATCHELL uses
O(period) storage with ordinary amortized constant updates; refreshes and guarded
fallbacks take O(period). RVI and RVIR retain O(deviation period) storage and
fresh scan work per sample;
RVI smoothing state has constant size. F32 logarithms, roots, filters and
products may lose precision or overflow even with finite observations.
`tests/reference/volume_filters.bend` checks pinned C values and seeds,
argument reversal, trend/price ties, nonpositive-price fallback, scaling,
validation and continuation with 2e−5 absolute/relative tolerance.
