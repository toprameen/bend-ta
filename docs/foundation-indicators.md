# Foundation catalog group

All **155 entries originally marked Foundation** in the pinned
[TA-Lib catalog](ta-lib-indicator-catalog.md) now have F32 interfaces. SUM retains
its existing state interface and gains batch support; the remaining entries add
new indicator interfaces. MA dispatch, MAMA and VIDYA were also implemented as
shared dependencies and exposed directly. The catalog now marks 192 names
Existing under their documented F32 contracts.

| Family | Original Foundation entries | Current contracts |
|---|---:|---|
| Candlestick recognizers | 59 | [Patterns, signed strengths and settings](candles.md) |
| Momentum and directional indicators | 44 | [Parameters, seeds and multi-line outputs](momentum.md) |
| Overlap and statistics | 37 | [Averages, channels, regression and order statistics](overlap-statistics.md) |
| Volume and volatility | 15 | [Accumulation, true range and range smoothing](volume-volatility.md) |

The remaining 45 catalog entries retain Advanced or API decision labels. The
two Hikkake recognizers are among those remaining entries; the 59 implemented
candle names are the complete original Foundation subset.

## Shared implementation

Algorithms, initialization recipes and stream transitions live in generic core
modules. Numeric types and operations are leading template arguments; periods,
selectors, settings and observations are runtime values. The F32 facade binds
operations, validates configuration and exposes named `State`, `init`, `next`
and `batch` interfaces. No working F64 backend is implied.

Owned windows provide chronological folds, lags and indexed extrema. Shared
components supply weighted/adaptive/cascaded moving averages, population
moments, centered regression, fresh sorted windows and aligned candle
thresholds. Batch applies the same transition as streaming; `Series.scan`
retains the final state for continuation. Stateless functions from the earlier
[Direct group](direct-indicators.md) continue to use plain mapping.

Multi-line results are named records and become available at the common
lookback. `None` is warm-up, distinct from zero, an undefined numeric result
or no pattern. Candle signals carry exact sign and integer strength separately
from prices. Absolute extrema indices use U32 and have the documented per-state
observation horizon. Parameters are explicit rather than silently defaulted.
Floating configuration bounds are compared in F32, including their rounded
boundary constants. See each family for minima, maxima and error types.

The shared moving-average selector covers every recognized code 0..15. DEFAULT
(11) is invalid above period one; period one is an identity for every recognized
code. Invalid selectors fail explicitly. MAMA uses its shared
[cycle engine](mama.md). VIDYA adapts from the first price using the changes
seen so far, first emits after its CMO window is full, and has an immediate
period-one identity. Its fresh movement scans cost O(CMO period) per input.

## Numeric and cost choices

Startup uses explicit zero unstable-period discard. Automatic reference
stabilization and mutable global compatibility settings are not applied.
Centered differences preserve small residuals on large baselines, and selected
algebraic rearrangements avoid unnecessary intermediate overflow. Each family's
guide names these choices and their limits; the implementations do not claim
double-precision or bitwise TA-Lib parity.

SUM/SMA now rebuild the live total at each logical wrap, reducing historical
subtract/add drift without another counter. Their work is amortized constant,
with O(period) work at the refresh. Fresh scans can still round or overflow,
and errors remain possible between refreshes. Candle thresholds, ADR and MASSI
inherit that schedule. Other window scans and sorting costs are stated in the
family guides; no constant-time extrema/order-statistics claim is made.

Permanent Bend fixtures exercise every implemented name and shared contracts,
with selected independent numerical and boundary examples. Larger C-oracle,
streaming and mutation matrices remain outside the repository. Maintained
library code, tests and tooling remain Bend. Preserve the
[TA-Lib notice](../THIRD_PARTY_NOTICES.md) when distributing the derived code.
