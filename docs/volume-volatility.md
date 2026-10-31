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
window, restoring zero after all volume leaves. EMV freshly reads the centered
window mean to avoid historical subtract/add drift. Both scans cost O(period)
per input; their storage is O(period). ADR and MASSI inherit the rolling sum
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
