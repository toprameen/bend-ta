# Overlap and statistics

The F32 facade adds ACCBANDS, ALMA, BBANDS, CKSP, DEMA, DONCHIAN, HMA,
KAMA, KC, MIDPOINT, MIDPRICE, T3, TEMA, TRIMA, VWMA, WMA, ZLEMA,
BBW, PERCENTB, LINEARREG, LINEARREG_ANGLE, LINEARREG_INTERCEPT,
LINEARREG_SLOPE, MEDIAN, PERCENTILE, PERCENTRANK, STDDEV, TSF, AVGDEV,
HA, MAX, MAXINDEX, MIN, MININDEX, MINMAX, MINMAXINDEX, VAR, CORREL, BETA
and KURTOSIS. Existing SUM
also gains `batch` using its existing state interface and error type. Its
uncompensated total is now rebuilt at each logical wrap, reducing historical
drift while retaining the numerical limits described in the foundation guide.

Every configured indicator exposes `init`, `next`, and `batch`. New validation
returns `Parameters.Error.InvalidParameter` before allocation. Batch preserves
one slot per input and applies the same transition as streaming; valid empty
input is empty. `None` means incomplete initialization. HA requires no
configuration and emits from the first bar. Existing SUM configuration remains
unchanged.

Parameters are explicit runtime arguments, in source order. In particular:
`ALMA.init(period, sigma, offset)`, `T3.init(period, factor)`,
`BBANDS.init(period, up, down, kind)` (also BBW/PERCENTB),
`KC.init(period, atr_period, deviation)`, `CKSP.init(period, multiplier, stop_period)`,
`PERCENTILE.init(period, percent)` and `STDDEV.init(period, factor)`.

New periods have maximum 100000, except MEDIAN, PERCENTILE and PERCENTRANK,
whose source maximum is 10000. Minimum 1 applies to individual moving averages
and VWMA; the remaining configured indicators require at least 2, except KC's
ATR period and CKSP's stop period, which permit 1. Sigma is finite and in
0.01..3e37; offset and T3 factor are in 0..1; percentile is in 0..100. Deviation
factors can be negative and have magnitude at most 3e37. CKSP's multiplier is
in 0..3e37. No periods, numeric factors or input observations are template
arguments. Generic `Overlap.accbands.init`, `bollinger.init`, `keltner.init`
and `chande.init` own their stage composition and initialization rules, so
another numeric facade binds the same recipes. Facades validate finite ranges
and source-specific parameter bounds before these helpers allocate storage.

## Shared moving averages

`core/ma.bend` provides an owned `State<N>`, validated `init`, and `next` with
leading numeric type/operation bindings. `MA` binds these operations to F32.
Kinds follow the pinned source enum:

| Kind | Strategy |
|---|---|
| 0 | SMA |
| 1 | EMA |
| 2 | WMA |
| 3 | DEMA |
| 4 | TEMA |
| 5 | TRIMA |
| 6 | KAMA |
| 7 | MAMA, supplied by the shared cycle engine |
| 8 | T3, factor 0.7 |
| 9 | HMA |
| 10 | Disabled, identity |
| 11 | DEFAULT, invalid for periods above 1 |
| 12 | ZLEMA |
| 13 | RMA |
| 14 | VIDYA, CMO period `(3*period+2)/4` |
| 15 | ALMA, sigma 6 and offset 0.85 |

Period 1 is an identity for every recognized kind, including DEFAULT, and
preserves the input's signed zero. Unsupported selectors fail explicitly.
Individual ALMA and T3 also preserve this identity. MAMA selection supplies
fast limit 0.5 and slow limit 0.05 and otherwise ignores the selected period. Low-level `make` helpers
assume that the caller has validated the configuration.

EMA/RMA and the EMA cascades use the existing centered SMA seed and
`previous + alpha*(input-previous)` update. Cascaded stages receive only valid
outputs; no warm-up zeros enter the next stage. KAMA seeds from the preceding
price, uses a fresh window of absolute changes, treats a flat window as
efficiency 1, clamps efficiency to 1 and squares the blended coefficient.
HMA floors both half-period and integer square root. ZLEMA waits for its
`floor((period-1)/2)` lag before seeding an EMA on adjusted prices. ALMA floors
`offset*(period-1)` and precomputes normalized Gaussian weights.

| Function | First output index with zero instability |
|---|---|
| WMA, TRIMA, ALMA, VWMA, SMA/RMA/EMA selected through MA | period-1 |
| DEMA | 2*(period-1) |
| TEMA | 3*(period-1) |
| T3 | 6*(period-1) |
| KAMA | period, except period 1 is immediate |
| HMA | period+floor(sqrt(period))-2 |
| ZLEMA | period-1+floor((period-1)/2) |
| MAMA selected through MA | 32, except period 1 is immediate |
| VIDYA selected through MA | derived CMO period, except period 1 is immediate |

No automatic or configurable instability discard is applied. This is the
project's explicit startup contract; the pinned TA-Lib defaults can discard
additional observations. EMA expression order and precision differ from the
reference double/FMA implementation.

## Window statistics and bars

Regression uses chronological coordinates 0..period-1, centered around their
midpoint, and centered price differences. `core/statistics.bend` returns one
record containing intercept, slope, current endpoint and one-step forecast.
LINEARREG selects the endpoint, TSF selects the forecast, and ANGLE converts
`atan(slope)` to degrees. AVGDEV computes residuals from an origin and mean
delta, avoiding subtraction from an already rounded large mean. STDDEV uses
population variance, then applies its multiplier.

MEDIAN averages the middle pair for even periods. PERCENTILE uses the source's
nearest rank `ceil(percent*period/100)`, clamped to 1..period; it does not
interpolate. The shared sorted quantile primitive supports interpolation and
is used for MEDIAN. PERCENTRANK compares the current observation strictly
against the preceding period observations; its first output index is period.
All other scalar window statistics first emit at period-1. Indexed extrema
choose the latest equal extremum and return absolute zero-based arrival
indices. MINMAX and MINMAXINDEX have named two-field records.

DONCHIAN includes the current bar, returning upper/middle/lower fields from
maximum high and minimum low. MIDPRICE selects its middle. ACCBANDS smooths
expanded high, close and expanded low with three centered cached means.
ACCBANDS and DONCHIAN first emit at period-1; BBANDS/BBW/PERCENTB
first emit at the later of the selected MA lookback and period-1.
SMA selected through MA uses the same centered mean cache as ACCBANDS; the
standalone SMA uses its rolling sum with periodic refreshes. BBANDS returns the same
band record with independent up/down deviation factors. For SMA-selected
bands, the center comes from fresh centered moments. BBW and PERCENTB form
ratios from deviation and centered residuals before rounding band endpoints;
this avoids cancellation on large-offset narrow bands. A zero center gives
BBW zero; zero width gives PERCENTB 0.5. Other selected averages still carry
their own rounding and seed errors.

KC uses typical-price EMA and the shared ATR. Its first output index is
`max(period-1, atr_period)`. Each leg starts its seed at that output's own
trailing lookback: the shorter leg initially skips observations so its seed
ends at the combined first output. CKSP uses period-window high/low extrema
and ATR to form initial stops, then returns the stop-period maximum high-stop
and minimum low-stop. Its first output index is period+stop_period-1. Both
use the ATR initialization described in the volume/volatility guide.

VWMA consumes `Bar.CV` and divides fresh centered price-volume and volume sums; a zero
volume sum can produce NaN or infinity. Period 1 returns the price directly.
HA consumes and returns `Bar.OHLC`. Its first open is `(open+close)/2`; every
later open uses the previous HA open and previous HA close, and its close is
the current raw OHLC average.

## Costs and numerical limits

All algorithms retain bounded state, and batch retains O(n) output slots.
EMA/RMA and cascades use O(1) work and state per sample. MA-selected SMA,
ACCBANDS, WMA/TRIMA and KAMA keep period-sized windows and cached scalar totals.
Ordinary updates perform fixed numeric work; logical wraps rebuild from the
window in O(period). Cancellation or nonfinite intermediate guards can also
trigger fresh scans, so repeated ill-conditioned windows can still cost
O(period) per sample. HMA composes three weighted caches. The LINEARREG family,
TSF and FOSC reuse the weighted cache for centered regression, falling back to
the fresh formula when cancellation makes cached reconstruction unsafe.
ALMA has O(period) initialization, dot-product work and storage. Moments,
AVGDEV and VWMA use fresh O(period) scans. MEDIAN/PERCENTILE sort a fresh window
in O(period log period) time and O(period) storage. PERCENTRANK scans its
preceding period observations.
MAX/MIN/MINMAX and their indexed variants, MIDPOINT/MIDPRICE, DONCHIAN and
CKSP's price/stop windows use owned monotonic queues. Updates have amortized
constant work with an O(period) worst-case prune burst and O(period) storage.
The two candidate buffers use more payload storage than a single scalar ring;
see [benchmarks and storage tradeoffs](../benchmarks/README.md). Latest equal
extrema are selected by the indexed family. Midpoint/channel high ties retain
the earliest equal value, preserving Base min/max signed-zero behavior.
Order statistics retain their fresh sort costs.

Finite inputs in arrival order are assumed. Malformed bars, negative volumes,
missing values and nonfinite recovery are not separately validated. F32
rounds every operation; sums, ratios and large opposing differences can still
overflow or lose precision. Weighted means use centered differences and EMA
cascade combinations use differences to avoid unnecessary overflow on large
constant inputs. Cached means and weighted totals retain a common origin and
compensated scalar sums, including their chronological rebuilds. Weighted
recurrences also carry the correction terms from their dependent total and
half-window sums; discarding those terms can leave a residual after a long
block expires. These caches add fixed scalar state without another raw window
per leg. If a compensated rebuild becomes nonfinite, one plain chronological
fold preserves the fresh formula's overflow category. KAMA separately refreshes
its cached absolute price changes. Guards rebuild on large cancellation or
scale changes. Regression also checks reconstructed slope and
endpoint cancellation and uses its original fresh centered scan when needed.
These checks preserve recovery properties, not a universal F32 error bound;
arithmetic regrouping can change result bits. SUM/SMA retain their own rolling
sum and logical-wrap refresh. Fresh sums still have rounding/overflow limits.
An indexed-extrema state accepts at most 4294967295 observations; its last
representable emitted index is 4294967294. Callers must stop or reinitialize
before another observation would overflow the U32 count. Reinitialization
starts a new index origin. No absolute-index guarantee applies beyond this
explicit per-state horizon. There is no F64 backend,
bitwise TA-Lib parity or universal error guarantee.

VIDYA seeds from the first price and adapts through its partial CMO window.
The first output is at the CMO period, except for an immediate period-one
identity. Its fresh movement scans use O(CMO period) work and storage.
The standalone `VIDYA.init(period,cmo)` validates smoothing periods 1..100000
and CMO periods 2..100000.

The permanent fixtures cover hand-calculated warm-ups, seeds, index ties,
nearest rank versus median, population variance, centered small residuals,
ALMA's floored offset and identity, asymmetric bands, KC/CKSP starts and
stream continuation. External probes compare both generated backends against
the pinned C library with unstable periods explicitly zero.

## Paired and higher moments

`VAR.init(period,factor)` accepts periods 1..100000 and finite factors with
magnitude at most 3e37. The factor is validated but has no effect, matching the
reference's legacy deviation argument. VAR returns population variance, with
zero for period one and for a constant window. Its first output is at period−1.
It projects the existing fresh centered population-moments calculation.

`CORREL.init(period)` and `BETA.init(period)` accept periods 1..100000.
Each observation is an aligned `TA.PairValue()` record, constructed as
`StatWindow.PairValue{x,y}` from `src/core/statistics_window.bend`. CORREL
uses price/value levels; BETA uses each field's one-bar fractional return,
`(current-previous)/previous`, substituting zero when that field's previous
price is exactly zero. BETA is the slope of y returns against x returns.
Their first outputs occur at period−1 and period respectively. CORREL returns
zero when either field is constant and clamps a defined answer to [−1,1].
BETA returns zero for constant x returns. Period one consequently emits zero
immediately for CORREL and after one reference observation for BETA.

`KURTOSIS.init(period)` accepts 4..10000. It emits the sample-adjusted Fisher
excess kurtosis G2, using sample variance in the standardization and the finite
sample correction. This differs from population fourth-moment kurtosis minus
three. The first output occurs at period−1. A constant window produces
`Some{NaN}` through 0/0; it has completed warm-up and does not produce `None`.

Pair and fourth-moment windows use fresh centered scans: first sum differences
from a current window observation, then retain the unrounded mean difference
when forming residual products. This preserves representable small variation
on a large baseline and clears historical outliers as soon as they leave.
Storage and work per output are O(period). The paired observations are owned
Data records; the containing arrays remain owned Type state.

Returns still round to F32 before their window is scanned. Nearly equal
returns can therefore have a large relative slope error even when all price
inputs are exactly representable: an external period-two example yields
about −471217 versus the double reference's −479999. The implementation agrees
with an independent operation-by-operation F32 return/moment model there.
Very small residual products can underflow and large products can overflow;
no double-precision equivalence or universal error bound is claimed.
`tests/reference/statistics_moments.bend` exercises centered residuals,
return direction/zero prices, sample correction, degenerate outputs, validation
and continuation. Its scalar comparisons allow 2e−5 absolute/relative error.

## Reference provenance

Algorithms and contracts were checked against TA-Lib commit
[`ccd3172940ed1d9daa4e7197f2265810852e8910`](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910),
including authored `ta_codegen/input` specifications and public implementations
in `src/ta_func`. These implementations adapt the referenced mathematical
algorithms to the project's generic state and numeric interfaces.

Retain [the complete upstream license notice](../THIRD_PARTY_NOTICES.md).
