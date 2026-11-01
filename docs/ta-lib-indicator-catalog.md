# TA-Lib function catalog and Bend implementation assessment

Assessed **2026-10-30**. This is a source-led implementation plan. Proposed work and numerical
validation requirements are stated explicitly.

## Scope and reproducible inventory

This document covers **all 237 named calculation functions** in the pinned
TA-Lib catalog: **61 candlestick recognizers, 27 math operators/transforms, and
149 other indicator/statistical/price functions**. Every name has its own entry.
Multiple outputs, parameter combinations, float/double entry-point variants and
batch/streaming entry points are not counted as additional indicators.
Lifecycle, abstract-API metadata, settings setters, lookback functions and
stream-handle management are infrastructure, not extra calculation functions;
their relevant semantics are discussed below.

The function-name sets agree exactly across:

- [Core API metadata at ccd3172940ed1d9daa4e7197f2265810852e8910](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_func_api.xml),
  committed 2026-10-29.
- [Python wrapper groups at c9f01aa2bf4ef251ea86605951181a8cec69d13c](https://github.com/TA-Lib/ta-lib-python/blob/c9f01aa2bf4ef251ea86605951181a8cec69d13c/talib/__init__.py)
  and its [generated function definitions](https://github.com/TA-Lib/ta-lib-python/blob/c9f01aa2bf4ef251ea86605951181a8cec69d13c/talib/_func.pxi).
- [Release v0.8.3 metadata](https://github.com/TA-Lib/ta-lib/blob/v0.8.3/ta_func_api.xml),
  the latest release found at assessment time. Its name set is also 237; this
  name-set check does not assert that every main-branch implementation byte equals
  the release.

The live [function index](https://ta-lib.org/functions/) is useful for navigation,
but pinned metadata and source define this assessment. The older “150+” and
current “200+” descriptions are marketing summaries, not the inventory used here.
Each entry links its authored upstream specification and algorithm plus generated
public implementation. The **Interface** line is extracted from upstream metadata;
parameter labels/defaults/ranges are reference facts, not proposed Bend identifiers.
`real` means a reference double-valued output that our numeric facade would map to
`N`; it does not mean native F64 already exists in Bend.

## Assessed baseline and implemented contracts

The original assessment at `a01bb1f06f3e9a81650d48c27f782cbbd287dcd7`
covered the SMA/EMA scaffold and planned additional work. All 237 catalog names
now have F32 interfaces and are marked Existing under their documented project
contracts. This records interface coverage, not universal numerical parity with
TA-Lib. Each entry links its owning guide for the current seed, lookback,
parameters, costs and limitations; original implementation/validation discussion
retains the source-led assessment context.

See [the design](design.md), [foundation](foundation.md),
[F32 facade](../src/f32.bend), [advanced trend/oscillators](advanced-trend.md),
[cycle/filter precision limits](cycles-filters.md) and
[causal/dynamic/anchored contracts](causal-indicators.md).

The existing core passes concrete numeric operations as leading `~` template
arguments, while periods and data are runtime arguments. Keep that pattern and
request only the capabilities each algorithm uses. Do not insert F32 literals
or conversions into generic algorithms. Fractions, negative constants, pi,
comparisons, absolute value, square root and transcendental operations need
explicit precision-appropriate bindings where used.

Base F32 supplies the arithmetic, comparisons, square root, exp/log and
trigonometric operations needed by this catalog. The F32 facade now supplies a
finite classifier using bit inspection.
No tested native F64 facade or fused multiply-add capability is established here.
An optional software F64 would need more than basic arithmetic for the entries
requiring sqrt/log/trig. A general proof-oriented math library is not a prerequisite
for the F32 implementation work.

## How to read readiness and blockers

Readiness is an engineering assessment, not a tested implementation status:

| Label | Meaning |
|---|---|
| Existing | A named F32 interface is implemented under its documented project contract; TA-Lib numerical/interface parity is not established. |
| Direct | A local arithmetic/map implementation is straightforward once common input/output and domain rules are chosen. |
| Foundation | Implement shared rolling, smoothing, bar, output or settings primitives first. These are buildable library dependencies. |
| Advanced | Stateful algorithms, adaptive filters or delicate numerical methods need a source-led port and stronger reference tests. |
| API decision | Settle a public contract such as multi-output alignment, dynamic periods, integer results, display shifts or undefined values before exposing it. |

A missing primitive is not a Bend language blocker. The clear present blockers
are to **unqualified TA-Lib numerical/behavioral equivalence**: the reference
uses double precision, some recurrences and thresholds use fused arithmetic,
startup/settings behavior varies by function, and the tested pinned-oracle matrices do not establish universal equivalence. F32 implementations can still be useful if their numerical
contract and differences are explicit. No entry below constitutes a proof of
performance, accuracy, GPU support or reference parity.

## Shared work that unlocks the catalog

This table records the original component plan. The [foundation guide](foundation.md)
and [implemented family guide](foundation-indicators.md) describe current components;
the rows below retain the original design plan rather than an unfinished-work list:

| Component | Bend design and beneficiaries |
|---|---|
| General input/output traversal | Generalize the current scalar `series` helper to input `I`, output `O` and owned state `S`. Preserve one result slot per input. Supports paired series, OHLC(V), multi-line indicators, integer indices and pattern outputs. |
| Typed inputs | Use small `HL`, `HLC`, `OHLC`, `CloseVolume`, `HLCV` or paired-value records rather than demand unused fields. Batch adapters validate equal lengths; do not silently truncate a zip. |
| Named output records | MACD/Bollinger/KVO/etc. return named records. Choose whether the aggregate becomes available at the latest component lookback or has per-field availability. A compatibility adapter must use TA-Lib's common output start. |
| Result vocabulary | `None` means warm-up. Zero means an actual numeric result or no candle pattern. Mathematical undefined results, rejected input and provisional pivots must not be silently collapsed into the same `None`. |
| Owned windows and lags | Reuse the logical-period/power-of-two ring discipline. Add lag access, paired sums, rolling rebuilds and bounded sample counters. New public periods need their own limits and allocation validation. |
| Extrema | Start with a correct window scan if useful; an owned monotonic queue can provide amortized O(1) updates. Keep latest-tie policy and absolute indices explicit. |
| Smoothing | Separate seed policy from update recurrence. Add Wilder/RMA, WMA, cascaded EMA, adaptive averages and a typed MA dispatcher. Public SMA/EMA composition alone may not reproduce a composite indicator's seed alignment. |
| Stable statistics | Centered/rebased sums, variance/covariance, regression and fourth moments, with periodic and collapse-triggered rebuilds. F32 thresholds need validation against F32 error, not unexamined double epsilon constants. |
| Order statistics | An owned ring plus sorted multiset/window supports median/percentile/rank. A scan/copy-and-sort baseline is simpler but must disclose O(period) or O(period log period) work. Optimize after correctness. |
| Candle engine | Share body/wick/color/gap helpers and immutable per-instance candle settings with lag-aligned range averages. Keep integer direction/strength separate from the numeric price type. |
| Hilbert/filter engine | Reuse delay lines, parity branches, coefficient generation and phase/period state across the HT/MAMA and SWAK families. Reuse a core without assuming every member has identical startup rules. |
| Compatibility configuration | Store warm-up mode, seed/compatibility choice and candle settings immutably in each state. Avoid TA-Lib-style mutable process globals in a composable library. |

Bend state that owns arrays needs a `Type`-capable state representation; scalar
states can remain `Data` where appropriate. The numeric type can remain `~N: Data`.
Do not assume all state records are freely duplicable. Model signed trend/pattern
values as an algebraic direction plus magnitude, or another explicit signed type;
U32 alone cannot hold negative signals. Absolute indices should be integer values,
not F32 values whose exact integer range ends at 2^24. Counter overflow and
subrange-versus-stream coordinates need a declared limit.

## Compatibility and numerical considerations shared by every entry

1. **Warm-up and seeds.** Output starts are not universally `period-1`.
   Price changes require a previous bar, cascades add startup stages, and candle
   lookbacks depend on settings. Current TA-Lib also supports explicit unstable
   counts and `TA_UNSTABLE_AUTO_PREC_4`/`TA_UNSTABLE_AUTO_PREC_8`; recursive and
   composite lookbacks can add period-dependent auto adjustments. Capture the
   actual configuration rather than assuming a historical default. See
   [unstable-period machinery](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_common/ta_memory.h)
   and [public enums/settings types](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/include/ta_defs.h).
2. **Double versus F32 and fused arithmetic.** A float-input TA-Lib routine still
   calculates in double; our F32 core rounds throughout. Shared source does not
   make F32 and F64 identical. Some upstream recurrences explicitly fuse operations
   or deliberately prohibit fusion. F64 alone would not settle that discrepancy.
   Near a comparison threshold a small numeric error changes an integer signal,
   so an approximate-price tolerance is not enough for every output.
   See [the reference precision contract](https://ta-lib.org/api/#44-input-type-float-vs-double).
3. **Domains, zero and invalid bars.** Different functions intentionally return
   zero, 50, 0.5, one, NaN or infinity for different degenerate cases. There is no
   universal safe-divide fallback. The existing project assumes finite input;
   new functions need to state whether they preserve that precondition or offer
   checked input. Batch and upstream streaming invalid-input policies can differ,
   as VWAP illustrates. Output-undefined behavior is a separate issue.
4. **No look-ahead through display offsets.** Store a value when its inputs become
   available. Keep chart offsets separate, especially for DPO, FRACTAL and
   ICHIMOKU. The pinned ZIGZAG is a causal running-pivot state machine, not a
   retroactively interpolated polyline. Latest forming bars require an explicit
   replay/rollback contract; the current design naturally consumes finalized bars.
5. **Window arithmetic.** Floating-point addition is not associative. Reordering,
   compensation, periodic rebuilding or replacing a formula with an algebraic
   equivalent can improve F32 behavior while changing reference results. Document
   that numerical choice; do not assume proof success certifies IEEE accuracy.
6. **MA selection.** The pinned dispatcher has 14 actual kinds: SMA, EMA, WMA,
   DEMA, TEMA, TRIMA, KAMA, MAMA, T3, HMA, ZLEMA, RMA, VIDYA and ALMA; it also has
   DISABLED and DEFAULT selectors. Constants are not a promise that a selected
   type uses every supplied period. Exposing only SMA/EMA is partial dispatch
   support and must be named as such.
7. **Timestamp and session semantics.** These functions operate on ordered bars;
   they do not sort, fill gaps, adjust splits or infer calendar/session boundaries.
   Reset cumulative or session-anchored state explicitly. Keep that integration
   layer separate from indicator arithmetic.
8. **Public API limits.** Upstream ranges printed below are metadata bounds, not
   our current global period rule. Validate multi-period relationships, integer
   lengths, real parameters and memory before allocation. Parameter defaults are
   runtime configuration; do not generate a template specialization per period.

## Validation required when implementing an entry

For every new indicator, commit a contract and Bend fixtures for its seed,
first-output index, empty/short input, invalid parameters and named outputs.
Compare batch with repeated `next` on the same finalized bars. Use the entry's
specific cases below, plus constant, monotonic, oscillating, gapped and
outlier-expiration series where applicable.

Generate independent golden data outside this repository using a pinned TA-Lib
build or its Python wrapper. Record core/wrapper versions, input values,
parameters, compatibility mode, unstable settings, candle settings, reference
output start, expected values and comparison policy. Committed fixtures may be
inert data; all executable source committed to this repository remains Bend under
[CONTRIBUTING](../CONTRIBUTING.md). The library must not call C TA-Lib at runtime.

For F32, compare a reference also fed the **same F32-quantized input** so input
quantization is separated from arithmetic error; this still leaves double
intermediate results in the oracle. Use per-output absolute/relative tolerances
and explicit NaN/Inf expectations. For discrete pattern, trend, rank and index
outputs, test exact boundary classes instead of hiding a changed classification
behind a float tolerance. Include long runs, large offsets with small spreads,
small quote units, near-zero divisors and counter/window boundaries.

This document was validated for catalog coverage, interface extraction, source
links and consistency with the current repository. It does **not** execute or
certify 235 unimplemented functions. Before adapting upstream program text,
retain the applicable [upstream license notices](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/LICENSE)
and choose the project's release license; the prose below is an original plan.

## Suggested implementation order

1. Generalize input/output traversal, bars, integer results, settings and oracle
   fixture metadata; strengthen existing SMA/EMA numerical tests.
2. Add lag/range helpers, Wilder/RMA, WMA, extrema and straightforward arithmetic
   transforms. Implement MOM/ROC variants, RSI, TRANGE/ATR/NATR and basic volume
   accumulators using those foundations.
3. Add aligned compositions: MACD family, stochastic family, ADX family,
   money-flow/volume oscillators and the full selected MA dispatcher.
4. Build stable variance/covariance/regression and order statistics; then
   Bollinger-derived functions, RVI/RVIR, percentiles and higher moments.
5. Add the candle-settings engine and its recognizers in source-tested batches;
   retain separate confirmation-state tests for HIKKAKE variants.
6. Add adaptive/Hilbert/SWAK algorithms and special dynamic-period/display/pivot
   interfaces with their own precision and state tests.

This order is a dependency proposal, not a committed roadmap or time estimate.

## Catalog by upstream group

| Group | Functions |
|---|---:|
| [Overlap Studies](#overlap-studies-34) | 34 |
| [Momentum Indicators](#momentum-indicators-63) | 63 |
| [Volume Indicators](#volume-indicators-14) | 14 |
| [Volatility Indicators](#volatility-indicators-11) | 11 |
| [Statistic Functions](#statistic-functions-13) | 13 |
| [Price Transform](#price-transform-6) | 6 |
| [Cycle Indicators](#cycle-indicators-8) | 8 |
| [Pattern Recognition](#pattern-recognition-61) | 61 |
| [Math Operators](#math-operators-12) | 12 |
| [Math Transform](#math-transform-15) | 15 |
| **Total** | **237** |

Readiness totals: **192 Existing**, **8 API decision**, **37 Advanced**.

## Overlap Studies (34)

### `ACCBANDS` — Acceleration Bands

**Interface:** inputs `High`, `Low`, `Close`; outputs `outRealUpperBand` (real), `outRealMiddleBand` (real), `outRealLowerBand` (real).

**Parameters:** Time Period = `20` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** typed HLC input, rolling sums, multi-output records.

**Bend implementation:** Map each bar to an expanded high, unchanged close and expanded low, then run three period-matched SMAs. The expansion factor is 4*(high-low)/(high+low). Return a record holding upper, middle and lower bands from one streaming state. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The source substitutes the raw high/low when their sum is negligible relative to their magnitudes; a fixed absolute epsilon gives different results for tiny prices. Warm-up follows SMA. F32 can overflow the high+low sum or lose cancellation information, so use scale-aware numeric policy and reference vectors.

**Validation:** Constant HLC bars; tiny rescaled prices; high=-low to exercise the denominator fallback.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/accbands/accbands.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/accbands/accbands.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ACCBANDS.c).

### `ALMA` — Arnaud Legoux Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `9` (integer, 1..100000); Sigma = `6` (double, 0.01..3e+37); Offset = `0.85` (double, 0..1).

**Readiness:** Existing. **Dependencies:** weighted window kernel, exp/floor numeric operations, owned ring.

**Bend implementation:** Precompute Gaussian weights for the runtime period, sigma and offset; normalize them once, then dot the weights with each owned rolling window. The source floors offset*(period-1) before building the weights. Keep the kernel reusable for later finite impulse-response indicators. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** This is an O(period) dot product per sample initially, not an EMA recurrence. Extreme sigma can underflow every F32 weight; validate normalization and distinguish rejection from a TA-Lib-compatible result. Period 1 should return the input directly, including its signed zero. A future F64 adapter needs exp and floor.

**Validation:** Offset 0 versus 1 on an impulse; odd/even periods; period-1 negative zero; extreme sigma.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/alma/alma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/alma/alma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ALMA.c).

### `BBANDS` — Bollinger Bands

**Interface:** inputs `inReal`; outputs `outRealUpperBand` (real), `outRealMiddleBand` (real), `outRealLowerBand` (real).

**Parameters:** Time Period = `20` (integer, 2..100000); Deviations up = `2` (double, -3e+37..3e+37); Deviations down = `2` (double, -3e+37..3e+37); MA Type = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** stable rolling variance, MA dispatcher, multi-output records.

**Bend implementation:** Combine the selected moving average with population standard deviation of the original input window. Emit middle, middle+up_multiplier*sd and middle-down_multiplier*sd. Keep variance independent of the chosen center MA; share its state with STDDEV rather than computing squared-price sums naively. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Current upstream defaults the period to 20. Warm-up is max(MA lookback, STDDEV lookback), which matters for adaptive or disabled MA types. Up/down factors are independent and may be negative in the source API. F32 cancellation on large-offset, low-variance data is the main numerical concern; matching the stable reference needs more than an EMA and sqrt.

**Validation:** Constant and large-offset low-noise data; asymmetric deviations; a MA type whose lookback differs from period-1.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/bbands/bbands.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/bbands/bbands.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_BBANDS.c).

### `CKSP` — Chande Kroll Stop

**Interface:** inputs `High`, `Low`, `Close`; outputs `outHighStop` (real), `outLowStop` (real).

**Parameters:** Time Period = `10` (integer, 2..100000); Multiplier = `1` (double, 0..3e+37); Stop Period = `9` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** ATR/Wilder smoothing, rolling extrema, typed HLC input, multi-output records.

**Bend implementation:** Compute ATR and period-window high/low extrema. Form initial high-stop=highest_high-multiplier*ATR and low-stop=lowest_low+multiplier*ATR, then take a stop-period maximum of high-stops and minimum of low-stops. Preserve both stages as streaming states and return the two stops together. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The first stop needs the previous close for true range, and the second stage adds another full window. The pinned lookback also carries ATR unstable-period/automatic-offset semantics. Do not confuse these channel stops with a direction-switching SuperTrend line. Reusing a proven extrema primitive avoids repeated window scans.

**Validation:** Stop period 1; multiplier 0; a gap bar followed by expiry of the old extreme; unequal first and second periods.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cksp/cksp.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cksp/cksp.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CKSP.c).

### `DEMA` — Double Exponential Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** EMA cascade, composed warm-up.

**Bend implementation:** Run EMA1 on prices and EMA2 on valid EMA1 outputs, then return 2*EMA1-EMA2 when both stages are ready. A small record can own both states, with no need to materialize intermediate arrays. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The source lookback is twice the selected EMA lookback, including its instability settings. Existing bend-ta EMA emits earlier than current automatic TA-Lib defaults and uses a different F32 expression order. Seed each stage according to the chosen compatibility contract; do not feed warm-up zeroes into stage two. Period 1 is an identity special case.

**Validation:** An impulse spanning both warm-ups; period 1; a long constant input and an external seeded-reference vector.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dema/dema.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dema/dema.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_DEMA.c).

### `DONCHIAN` — Donchian Channels

**Interface:** inputs `High`, `Low`; outputs `outRealUpperBand` (real), `outRealMiddleBand` (real), `outRealLowerBand` (real).

**Parameters:** Time Period = `20` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** rolling extrema, typed HL input, multi-output records.

**Bend implementation:** Track the rolling maximum high and minimum low over the same period. Emit those endpoints and their midpoint in a band record. Monotone deques or an owned block-extrema buffer can make updates efficient without changing the public period API. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The current source includes the current bar and emits after period-1 history; it does not automatically shift the channel to exclude today for breakout testing. This is a contract distinction with trading strategies. Validate the minimum period from metadata and large-period memory bounds. Midpoint addition can overflow F32 even when both endpoints are finite.

**Validation:** A new current-bar extreme; expiry of the only old extreme; repeated equal highs and lows; comparison with explicitly shifted channels.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/donchian/donchian.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/donchian/donchian.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_DONCHIAN.c).

### `EMA` — Exponential Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** existing core/ema.bend, compatibility configuration.

**Bend implementation:** Reuse the existing shared EMA state and F32 facade. It already SMA-seeds the first period of prices and then advances a constant-size recurrence. Keep numeric type and operations as leading template parameters, with the period supplied at runtime.

**Blockers and special considerations:** Existing support is not TA-Lib parity: upstream uses a derived beta/alpha pair and fused arithmetic, and its lookback includes configurable or automatic instability suppression. bend-ta emits its SMA seed immediately and uses previous+alpha*(price-previous). F32 versus double, startup selection, period limits and expression order all need a named compatibility policy.

**Validation:** Period 1 with a sharp magnitude change; exact first seed; long small increments on a large baseline; reference lookback under each instability mode.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ema/ema.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ema/ema.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_EMA.c).

### `FRAMA` — Fractal Adaptive Moving Average

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `16` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** two-half rolling extrema, log/exp numeric operations, typed HL input, adaptive smoothing.

**Bend implementation:** Split an even-length high/low window into two halves, estimate fractal dimension from their ranges and the full range, and derive an adaptive smoothing coefficient. Update the midpoint price recursively; share the half-window extrema machinery rather than rebuilding windows each step.

**Blockers and special considerations:** The pinned source rejects odd periods, seeds from a midpoint, and has a period-plus-instability lookback. It returns the current midpoint directly for flat or alpha-at-least-one regimes instead of evaluating a log of zero. Preserve these branches. F32 near the range comparisons can select a different regime; log/exp are required of future numeric adapters.

**Validation:** Odd-period rejection; a flat market; a trending ramp; tiny positive half-ranges around the direct-price branch.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/frama/frama.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/frama/frama.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_FRAMA.c).

### `HMA` — Hull Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** WMA cascade, integer period derivation, owned rings.

**Bend implementation:** Compose WMA(floor(period/2)), WMA(period), and an outer WMA(floor(sqrt(period))) over 2*short-long. Own all three states and pass only valid de-lagged values to the final stage. Calculate derived periods with integer-safe helpers. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Flooring conventions matter for odd periods. The source specializes periods 2 and 3 because both derived short periods are 1, and period 1 is identity. Its WMA accumulators periodically reseed to control drift; a long-run F32 implementation should have an equivalent stability policy. The final lookback is WMA(period)+WMA(sqrt-period).

**Validation:** Periods 1, 2, 3 and an odd square-adjacent period; impulse response; long-ramp drift across reseeding boundaries.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/hma/hma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/hma/hma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HMA.c).

### `HT_TRENDLINE` — Hilbert Transform - Instantaneous Trendline

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** shared Hilbert engine, price history ring, adaptive window mean.

**Bend implementation:** Use the Hilbert estimator's smoothed cycle period to choose a bounded recent-price mean, then apply the source 4,3,2,1 temporal smoothing of that mean. The bounded history can be an owned ring shared with other cycle-dependent indicators.

**Blockers and special considerations:** The fixed lookback is 63 plus function-specific instability settings. The mean consumes raw input prices, not the smoothed-price projection used for phase. Rounded cycle length makes the output discontinuously sensitive to F32 period estimates. Do not replace it with a fixed-period EMA or assume its warm-up equals HT_DCPERIOD's.

**Validation:** Trend plus a sinusoidal component; constant prices; changing inferred integer window lengths; alignment against the pinned reference.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_trendline/ht_trendline.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_trendline/ht_trendline.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HT_TRENDLINE.c).

### `ICHIMOKU` — Ichimoku Kinko Hyo

**Interface:** inputs `High`, `Low`; outputs `outTenkanSen` (real), `outKijunSen` (real), `outSenkouSpanA` (real), `outSenkouSpanB` (real).

**Parameters:** Tenkan Period = `9` (integer, 2..100000); Kijun Period = `26` (integer, 2..100000); Senkou B Period = `52` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** three MIDPRICE windows, multi-output records, display-shift metadata.

**Bend implementation:** Compose high/low midpoint windows for Tenkan, Kijun and Senkou B; form Senkou A from the two already-computed midpoint lines. Emit a four-field causal current-bar record, and carry plotting offsets separately from calculation timestamps.

**Blockers and special considerations:** Pinned TA-Lib returns four outputs, with no Chikou close output. Its spans are not moved in the arrays: separate DisplayShift metadata marks both as +Kijun-period. Warm-up is longest of the three periods minus one; periods need not be ordered. Shifting arrays inside next would conflict with bend-ta's positional alignment and can cause look-ahead mistakes.

**Validation:** Nonstandard period orderings; exact first complete longest window; verify current-bar outputs separately from a +Kijun display shift.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ichimoku/ichimoku.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ichimoku/ichimoku.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ICHIMOKU.c).

### `KAMA` — Kaufman Adaptive Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** rolling absolute changes, lag ring, adaptive smoothing.

**Bend implementation:** Maintain the absolute one-bar change sum and the period-lagged price. Divide net period movement by that volatility measure, blend fixed fast/slow constants, square the coefficient and advance one adaptive average state. A lag ring and running change sum are reusable for ER and related indicators. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The source treats a zero-volatility window as efficiency 1 and clamps the ratio, seeds from the preceding price rather than an SMA, and makes period 1 identity. Flat-window reset logic removes residual running-sum drift. Warm-up is period plus instability settings for periods above 1. F32 sign/cancellation errors in the volatility sum require guards.

**Validation:** Monotone versus alternating prices; a long flat run after activity; period 1; the first nonflat change after an all-flat window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kama/kama.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kama/kama.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KAMA.c).

### `KC` — Keltner Channels

**Interface:** inputs `High`, `Low`, `Close`; outputs `outRealUpperBand` (real), `outRealMiddleBand` (real), `outRealLowerBand` (real).

**Parameters:** Time Period = `20` (integer, 2..100000); ATR Period = `10` (integer, 1..100000); Deviations = `2` (double, -3e+37..3e+37).

**Readiness:** Existing. **Dependencies:** EMA, ATR, typical-price transform, typed HLC input, multi-output records.

**Bend implementation:** Run an EMA over typical price (high+low+close)/3 and ATR over the same HLC bars. Once both streams are ready, emit the EMA center and center plus/minus the deviation multiplier times ATR. Each child state advances on every bar. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The pinned implementation centers on typical-price EMA, not close-price EMA; Keltner variants differ on this. Warm-up is max(EMA lookback, ATR lookback), including instability settings. The ATR period is independent of the center period. F32 gap handling, true-range seed and arbitrary deviation factors need explicit contracts.

**Validation:** Bars whose close differs greatly from their typical price; unequal EMA/ATR periods; a gap; zero deviation multiplier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kc/kc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kc/kc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KC.c).

### `MA` — Moving average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000); MA Type = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** typed MA selector, all supported moving-average states, sum-type ownership.

**Bend implementation:** Add a public MA-kind enum with a state sum type whose alternatives own the selected moving-average implementation. Dispatch once at initialization where possible, while retaining runtime period and MA selection. Keep direct typed facades for callers that know the kind. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Current upstream dispatches 14 MA kinds, plus a disabled identity mode; implementing only SMA/EMA must be advertised as partial support. MAMA ignores the period in favor of fixed limits, T3 supplies factor 0.7, VIDYA derives its CMO period, and ALMA supplies sigma/offset defaults. Period 1 bypasses the selected algorithm. Owned array states require a Type-capable state wrapper.

**Validation:** Every enum alternative against its direct function; disabled/period-1 identity; MAMA, VIDYA and ALMA dispatcher defaults.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ma/ma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ma/ma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MA.c).

### `MAMA` — MESA Adaptive Moving Average

**Interface:** inputs `inReal`; outputs `outMAMA` (real), `outFAMA` (real).

**Parameters:** Fast Limit = `0.5` (double, 0.01..0.99); Slow Limit = `0.05` (double, 0.01..0.99).

**Readiness:** Existing. **Dependencies:** shared Hilbert engine, adaptive smoothing, multi-output records.

**Bend implementation:** Use Hilbert in-phase/quadrature state to estimate phase change and derive a coefficient limited by fast/slow settings. Update the MAMA line and its FAMA follower, whose coefficient is half the MAMA coefficient, then return both lines together. Current F32 contract: [implemented interface and limits](mama.md).

**Blockers and special considerations:** This is a feedback signal-processing algorithm, not a conventional EMA with a variable period. The source seeds recursive output values at zero and includes a 32-bar fixed component plus parameter-dependent instability warm-up. Preserve phase fallback and coefficient clamp ordering. No presumed fast-limit>=slow-limit rule should be invented beyond verified validation. F32 boundary differences can persist through recursion.

**Validation:** A phase-changing sine wave; constant input; unequal and reversed limit values accepted by the source; first valid MAMA/FAMA pair.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mama/mama.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mama/mama.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MAMA.c).

### `MAVP` — Moving average with variable period

**Interface:** inputs `inReal`, `inPeriods`; outputs `outReal` (real).

**Parameters:** Minimum Period = `2` (integer, 1..10000); Maximum Period = `30` (integer, 1..10000); MA Type = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** MA dispatcher, period normalization, parallel fixed-period state bank or batch planner.

**Bend implementation:** Normalize each per-bar period by clamping and integer truncation, then select the corresponding fixed-period MA result. A faithful streaming design needs a bank of period-specific histories/states or a documented recomputation strategy; the batch implementation may group outputs by their selected period.

**Blockers and special considerations:** It is not an EMA whose coefficient changes according to today's period: each selected value comes from a separately computed fixed-period MA. Upstream uses the maximum period for warm-up and maps NaN/below-min periods to the minimum. The finite period range and supported MA kind control state/memory cost. A batch-first interface may be preferable until streaming costs are explicit.

**Validation:** An alternating period series compared with separately computed MAs; fractional/out-of-range/NaN periods; min=max; a non-SMA MA kind.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mavp/mavp.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mavp/mavp.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MAVP.c).

### `MCGD` — McGinley Dynamic

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** finite-result classification, adaptive scalar recursion.

**Bend implementation:** Keep the previous McGinley line and apply previous+(price-previous)/(period*(price/previous)^4), using explicit products for the fourth power. If the proposed update is nonfinite, retain the previous line, matching the pinned algorithm's recovery branch.

**Blockers and special considerations:** The seed is the first price, followed by period-1 plus instability warm-up. A generic numeric adapter needs finite-result detection, which is not part of the current indicator template signature. Zero prices, a zero carried line and tiny price/line ratios are real behavior cases, not only invalid-input accidents. This denominator is especially fragile in F32.

**Validation:** A zero seed then nonzero prices; a live zero price; tiny price/line ratios causing an overflowing step; flat input.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mcgd/mcgd.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mcgd/mcgd.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MCGD.c).

### `MIDPOINT` — MidPoint over period

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** single-series rolling extrema.

**Bend implementation:** Track maximum and minimum of one scalar series over a logical period and return their midpoint. Reuse the same owned extrema implementation that will support MAX/MIN rather than the existing rolling-sum buffer. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** This consumes extrema of one series; it is not the midpoint of separately supplied high/low series. Warm-up is period-1. A comparison capability must be bound by numeric facades. F32 midpoint arithmetic needs an overflow-aware policy, and a compatibility mode should preserve the reference's expression order instead of assuming all algebraic rewrites are equivalent.

**Validation:** An asymmetric window where the midpoint differs from its mean; old-extreme expiry; repeated values; large same-sign endpoints.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/midpoint/midpoint.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/midpoint/midpoint.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MIDPOINT.c).

### `MIDPRICE` — Midpoint Price over period

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** typed HL input, rolling high/low extrema.

**Bend implementation:** Maintain maximum high and minimum low over the same period and emit their midpoint. Share the high/low extrema state with Donchian and the three windows used by Ichimoku. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Unlike MEDPRICE, this is a windowed transform, and unlike MIDPOINT, it uses two independent input series. Its first output follows period-1 history. The planned bar/pair input needs aligned high and low values and a documented policy for malformed bars. Avoid losing a finite midpoint to overflowing F32 endpoint addition.

**Validation:** A series where highest high and lowest low occur on different bars; period boundary; malformed high<low policy; expiry of extrema.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/midprice/midprice.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/midprice/midprice.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MIDPRICE.c).

### `RMA` — Wilder's Smoothed Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** generalized smoothing seed/coefficient, scalar recursive state.

**Bend implementation:** Reuse the implemented common seed/update state machine, with Wilder coefficient 1/period for RMA rather than EMA's 2/(period+1). Expose it as a generic numeric template and reuse it for ATR and directional-movement families.

**Blockers and special considerations:** Pinned TA-Lib forms separate beta/alpha coefficients and uses fused updates; copying the mathematical recurrence alone will not give double-precision bit identity. Its lookback is period-1 plus configurable/automatic instability, and period 1 returns the input. Choose a shared initialization convention before composing RMA with true range or gains/losses.

**Validation:** Exact SMA seed; period 1; an impulse with known geometric decay; compare RMA(TRANGE) with the planned ATR alignment.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rma/rma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rma/rma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_RMA.c).

### `SAR` — Parabolic SAR

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Acceleration Factor = `0.02` (double, 0..3e+37); AF Maximum = `0.2` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed HL input, direction enum, scalar reversal state.

**Bend implementation:** Model long/short direction, current SAR, extreme point, acceleration factor and recent high/low as an explicit state machine. Apply reversal tests before the next projected stop and clamp the projection against the recent bars as the source does.

**Blockers and special considerations:** Warm-up is one bar. Direction is initialized using one-bar minus-directional movement, with ties choosing long. Equality can trigger a reversal, and acceleration is bounded by its maximum. A generic EMA-like helper cannot capture these transition rules. F32 rounding can alter reversal timing, so reference fixtures must compare the state transitions, not only approximate stop levels.

**Validation:** Equal first-bar directional moves; exact touch of SAR; gaps reversing each direction; acceleration above maximum; flat high/low bars.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sar/sar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sar/sar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SAR.c).

### `SAREXT` — Parabolic SAR - Extended

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Start Value = `0` (double, -3e+37..3e+37); Offset on Reverse = `0` (double, 0..3e+37); AF Init Long = `0.02` (double, 0..3e+37); AF Long = `0.02` (double, 0..3e+37); AF Max Long = `0.2` (double, 0..3e+37); AF Init Short = `0.02` (double, 0..3e+37); AF Short = `0.02` (double, 0..3e+37); AF Max Short = `0.2` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** SAR state machine, direction-specific parameters, signed result or typed direction output.

**Bend implementation:** Generalize the SAR state machine with separate long/short initial, increment and maximum acceleration parameters, an optional explicit starting stop and a reversal offset. Keep internal direction separate from numeric sign and offer a compatibility encoder for the signed scalar result.

**Blockers and special considerations:** The source uses the sign of Start Value to select initial direction, and negative outputs encode short SAR. This can conflict with negative-priced markets, so a typed result is safer internally. Offset on Reverse is a fractional multiplier, not a percent divided by 100. Warm-up remains one bar; preserve asymmetric clamp/reversal order.

**Validation:** Explicit positive/negative start values; asymmetric long/short acceleration; nonzero reversal offset; agreement with basic SAR under equivalent defaults after decoding direction.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sarext/sarext.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sarext/sarext.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SAREXT.c).

### `SMA` — Simple Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** existing core/sma.bend, existing owned rolling sum.

**Bend implementation:** Reuse the existing SMA core, which validates the period through the facade, owns a power-of-two-capacity ring and wraps at the logical period. Both batch and streaming already consume the same next transition and preserve one output slot per input.

**Blockers and special considerations:** The current implementation emits at period-1 like the reference, but has only small contract tests and no broad TA-Lib error guarantee. F32 sums drift and can overflow; the source uses double arithmetic. Current bend-ta period bounds differ from upstream's 100000 limit. Period 1 and empty/short batches should retain the existing documented behavior.

**Validation:** Hand-calculated rolling windows; period 1; logical period not a power of two; long large-offset/small-change sequences.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sma/sma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sma/sma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SMA.c).

### `SUPERTREND` — SuperTrend

**Interface:** inputs `High`, `Low`, `Close`; outputs `outSupertrend` (real), `outTrend` (integer).

**Parameters:** Time Period = `10` (integer, 2..100000); Multiplier = `3` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** ATR, typed HLC input, band-ratchet state, multi-output records.

**Bend implementation:** Maintain ATR, independently ratcheted upper/lower bands, previous close and an explicit trend enum. Seed both bands from the first valid midpoint/ATR pair, then apply the source release and crossing tests; emit the chosen band and direction together.

**Blockers and special considerations:** Upstream seeds the first valid trend long and inherits ATR lookback. Equality does not flip direction; it uses strict close comparisons. Do not infer the carried direction by comparing the output line with a band: the bands can coincide or cross. The line is not guaranteed monotone within one trend. F32 comparison differences are categorical compatibility risks.

**Validation:** A constant series; zero multiplier with coincident bands; exact band touches; gaps where bands cross; persistent first seeded trend.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/supertrend/supertrend.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/supertrend/supertrend.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SUPERTREND.c).

### `SWAK_BUTTER` — Swiss Army Knife - Butterworth Filter

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..10000).

**Readiness:** Existing. **Dependencies:** two-pole filter engine, sin/sqrt numeric operations.

**Bend implementation:** Use the shared second-order filter state with a Butterworth coefficient factory. Feed its symmetric input combination x[t]+2*x[t-1]+x[t-2] into the recurrence, keeping both previous inputs and outputs in a fixed-size owned record.

**Blockers and special considerations:** Unlike the high-pass family, the source seeds previous outputs with the first price so constant input starts at its level. Preserve the source coefficient and feed-forward ordering if comparing to a reference. Its warm-up is instability-controlled. Large-period F32 coefficient subtraction can degrade DC behavior and settling, even though the state is small.

**Validation:** A constant nonzero series from startup; step and impulse responses; periods at range limits; comparison with Gaussian output to prevent shared-coefficient mixups.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_butter/swak_butter.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_butter/swak_butter.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SWAK_BUTTER.c).

### `SWAK_GAUSS` — Swiss Army Knife - Gaussian Filter

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..10000).

**Readiness:** Existing. **Dependencies:** two-pole filter engine, sin/sqrt numeric operations.

**Bend implementation:** Instantiate the shared second-order filter state with the Gaussian factory and a current-input-only feed-forward term. It shares feedback coefficients with the source's Butterworth/two-pole high-pass designs but has a different input term and startup state.

**Blockers and special considerations:** The source seeds both output delays to the first input and uses a squared coefficient as the current-input gain. Do not copy Butterworth's symmetric input taps merely because the feedback coefficients match. Instability warm-up and F32 pole/normalization error need separate validation; future numeric adapters require the relevant transcendental operations.

**Validation:** Constant input; a one-bar impulse; direct comparison of the distinct Gaussian and Butterworth kernels; long-period settling.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_gauss/swak_gauss.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_gauss/swak_gauss.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SWAK_GAUSS.c).

### `T3` — Triple Exponential Moving Average (T3)

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `5` (integer, 1..100000); Volume Factor = `0.7` (double, 0..1).

**Readiness:** Existing. **Dependencies:** six-stage EMA cascade, coefficient polynomial.

**Bend implementation:** Maintain six sequential EMA stages and combine stages three through six using the volume-factor-derived polynomial coefficients. Seed successive stages from complete windows of the preceding stage, then keep all live stages in a single composite state. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The source lookback is six*(period-1) plus T3-specific instability, not six arbitrary calls that independently discard every EMA instability period. Factor 0 reduces the output combination to stage three; period 1 is explicitly identity. Polynomial cancellation and fused operation order make this a numerically sensitive F32 composition even though the algorithm is straightforward.

**Validation:** Volume factors 0 and 1; period 1; exact staged first output; long constant and step inputs.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/t3/t3.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/t3/t3.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_T3.c).

### `TEMA` — Triple Exponential Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** three-stage EMA cascade, composed warm-up.

**Bend implementation:** Run three EMA stages on successively valid outputs and emit 3*EMA1-3*EMA2+EMA3. Share an EMA cascade helper with DEMA and use one composite state instead of allocating intermediate batch lists. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The source lookback is three times EMA lookback, including the selected instability policy. First outputs depend on each stage's seed alignment, and period 1 is an identity specialization. Subtracting highly correlated stage values amplifies F32 cancellation. Keep expression ordering and numerical tolerances documented rather than claiming exact TA-Lib agreement.

**Validation:** A ramp and impulse spanning all three warm-ups; period 1; check stage composition against separately computed EMA references.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tema/tema.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tema/tema.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TEMA.c).

### `TRIMA` — Triangular Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** triangular weighted window, rolling partial sums.

**Bend implementation:** Implement a symmetric triangular window, with distinct odd- and even-period weights. A first implementation can use an owned weighted ring and direct dot product; a later rolling-partial-sum state can reduce per-bar work while retaining the same public contract. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Odd periods have one central maximum weight; even periods have two equal central weights. This is not generally SMA(SMA(x,period),period), which changes both the window and warm-up. Reference lookback is period-1. F32 running numerator drift and different summation orders need numerical tests before replacing a direct kernel with an optimized recurrence.

**Validation:** Odd/even impulse-response weights; a constant series; exact first output; contrast with an incorrectly doubled-period SMA cascade.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/trima/trima.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/trima/trima.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TRIMA.c).

### `VIDYA` — Variable Index Dynamic Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `12` (integer, 1..100000); CMO Period = `9` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** rolling directional-change sums, lag ring, adaptive smoothing.

**Bend implementation:** Maintain rolling sums of positive and negative price changes for the CMO period. Scale EMA's coefficient by the absolute normalized CMO magnitude and update a carried VIDYA line. Keep the CMO window and averaging period independent in the public state. Current F32 contract: [implemented interface and limits](foundation-indicators.md).

**Blockers and special considerations:** The source uses unsmoothed rolling gain/loss sums, not Wilder-smoothed CMO, seeds from the initial price and returns the input for averaging period 1. A wholly flat window resets sums and sets the adaptive coefficient to zero, holding the previous line. Lookback is CMO period plus parameter-dependent instability. F32 sum drift must not manufacture adaptation in a flat market.

**Validation:** Alternating versus one-direction changes; a long flat tail; averaging period 1; different CMO/EMA periods and MA-dispatcher-derived defaults.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vidya/vidya.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vidya/vidya.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_VIDYA.c).

### `VWMA` — Volume Weighted Moving Average

**Interface:** inputs `inReal`, `Volume`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** typed price-volume input, two rolling sums.

**Bend implementation:** Maintain rolling price*volume and volume sums in a paired ring, and emit their ratio for each complete window. Reuse the same accumulation building blocks as rolling VWAP-like calculations while keeping this indicator's input price explicit. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Upstream evaluates the ratio as mean(price*volume)/mean(volume); changing the operation order affects exact compatibility. An all-zero-volume window produces NaN and explicitly resets residual sums; it does not emit zero or the last value. Period 1 is identity even with zero volume. Products and long volume sums can overflow F32, so a typed missing/error policy and reference behavior must be chosen.

**Validation:** Equal volumes reducing to SMA; a dominant-volume bar; all-zero volume after nonzero history; period 1 with zero volume.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vwma/vwma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vwma/vwma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_VWMA.c).

### `WMA` — Weighted Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** weighted rolling sums, owned price ring, periodic reseeding.

**Bend implementation:** Track the ordinary window sum and the weighted numerator with newest sample weighted by the period, then update both as the oldest sample expires. A reusable weighted-window state can support HMA and triangular kernels without exposing array capacity. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The denominator is period*(period+1)/2; avoid U32 overflow by converting safely before multiplication. Current upstream periodically rescans after 8*period updates to limit accumulated drift. Preserve that stability issue in F32 even if the initial implementation uses a direct dot product. Warm-up is period-1, and period 1 is identity.

**Validation:** A short ramp showing newest-heavy weights; period 1; non-power-of-two windows; long sequences across a reseed boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wma/wma.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wma/wma.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_WMA.c).

### `ZIGZAG` — Zig Zag

**Interface:** inputs `High`, `Low`; outputs `outZigZag` (real), `outTrend` (integer), `outPivotIdx` (integer).

**Parameters:** Sensitivity = `5` (double, 0..100); Minimum Trend Length = `1` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** typed HL input, direction/pivot state, integer index output, multi-output records.

**Bend implementation:** Port the pinned causal state machine: carry trend, current extreme pivot and bars since that pivot; test percentage reversal and minimum trend age, otherwise extend the current extreme. Emit running pivot price, trend and pivot index together as one current-bar result.

**Blockers and special considerations:** Pinned TA-Lib does not retroactively interpolate a completed ZigZag polyline. Reversal is tested before extension on outside bars; equal extrema extend to the newer pivot index. It seeds a down leg at an earlier low, and first output is after minimum-trend-length bars. Preserve absolute index semantics and clarify how a caller resets or slices a stream. A charting adapter may draw tentative legs separately.

**Validation:** An outside bar that both reverses and extends; equal extrema updating only pivot age/index; sensitivity 0/100; minimum-age boundary.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/zigzag/zigzag.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/zigzag/zigzag.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ZIGZAG.c).

### `ZLEMA` — Zero-Lag Exponential Moving Average

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** EMA, lag ring, de-lag price transform.

**Bend implementation:** Store floor((period-1)/2) bars of history, form the de-lagged series 2*current-lagged, and feed it through an EMA state. Reuse the existing EMA machinery only after its seed and compatibility policy have been generalized appropriately. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Lookback is lag plus EMA lookback, and period 1 is identity. The source intentionally uses 2*x-lag rather than x+(x-lag), since they round differently; its EMA uses fused double arithmetic. De-lagging can amplify noise and overflow F32. Odd/even lag rounding and the seed window over transformed values need explicit tests.

**Validation:** Odd/even periods; a ramp with known lag reduction; period 1; cancellation-sensitive input comparing the two de-lag expressions.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/zlema/zlema.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/zlema/zlema.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ZLEMA.c).

## Momentum Indicators (63)

### `AC` — Accelerator/Decelerator Oscillator

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Fast Period = `5` (integer, 2..100000); Slow Period = `34` (integer, 2..100000); Signal Period = `5` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** median-price transform, SMA, composed warm-up.

**Bend implementation:** Feed each high/low midpoint into fast and slow SMA states, subtract their aligned outputs to obtain AO, then subtract a signal-period SMA of AO. Store the three owned states together and publish only after the signal window is complete. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The lookback is AO's longer-window lookback plus the signal SMA lookback. Preserve AO's supplied fast/slow ordering rather than silently swapping the periods; reversing them changes the sign. F32 subtraction near zero needs absolute tolerance.

**Validation:** Compare the composed AO-minus-SMA chain; reverse the two price-average periods and check the sign reversal.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ac/ac.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ac/ac.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AC.c).

### `ADX` — Average Directional Movement Index

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** OHLC bar input, directional movement, true range, Wilder smoothing, warm-up configuration.

**Bend implementation:** Build one shared directional-movement state carrying prior high/low/close and Wilder-smoothed positive movement, negative movement and true range. Form DX from the two directional indices; seed ADX from a period of DX values and continue Wilder smoothing. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Base lookback is 2*period-1 plus the configured ADX unstable discard, whose current default can be period-scaled Auto. Strict competing-movement comparisons make equal up/down movement contribute neither side. Preserve zero-range and zero-direction branches; F32 ratio and recursive-decay behavior require dedicated vectors.

**Validation:** Use equal competing moves, a flat-to-trending transition, and explicit unstable=0 versus current-default captures.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adx/adx.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adx/adx.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ADX.c).

### `ADXR` — Average Directional Movement Index Rating

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** ADX, lag buffer.

**Bend implementation:** Run ADX and retain a lag of period-1 ADX outputs in an owned ring. Return the mean of the current ADX and that lagged value, with the lag applied to valid ADX samples rather than to initial warm-up slots. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** TA-Lib uses period-1, not period, between the two ADX values. Its lookback adds period-1 to ADX's full configured lookback. This inherits ADX's seeds and Auto/manual unstable settings; averaging cannot repair a mismatched ADX initialization.

**Validation:** Use a changing ADX sequence to distinguish period-1 from period lag; verify the first valid output index.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adxr/adxr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adxr/adxr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ADXR.c).

### `AO` — Awesome Oscillator

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Fast Period = `5` (integer, 2..100000); Slow Period = `34` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** high/low input, median-price transform, SMA.

**Bend implementation:** Transform each bar to (high+low)/2, update two SMA states, and subtract the slow result from the fast result once both are ready. No volume or close field is needed. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The longer of the two windows determines availability. Unlike APO and MACD, inverted fast/slow periods are accepted without swapping, producing the negated series. Equal periods should yield zero; extreme midpoint addition and cancelling averages need F32 checks.

**Validation:** Check constant midpoints, equal periods and an inverted period pair against a direct pair of SMAs.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ao/ao.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ao/ao.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AO.c).

### `APO` — Absolute Price Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Fast Period = `12` (integer, 2..100000); Slow Period = `26` (integer, 2..100000); MA Type = `1` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** moving-average dispatch, aligned composition.

**Bend implementation:** Instantiate two selected moving-average states, align their valid results at a common bar, and emit fast minus slow. Initially an explicitly restricted SMA/EMA implementation is possible, with other MA types added through a typed dispatch layer rather than copied APO algorithms. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Current default MA type is EMA. TA-Lib swaps inverted fast/slow periods, unlike AO, and requires the selected MA's own warm-up. MAMA ignores its period, making two MAMA legs identical. A full TA-Lib-style API is blocked on supporting its complete MA selection, not on arithmetic.

**Validation:** Compare default EMA and explicit SMA; test swapped periods and identical-period cancellation.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/apo/apo.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/apo/apo.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_APO.c).

### `AROON` — Aroon

**Interface:** inputs `High`, `Low`; outputs `outAroonDown` (real), `outAroonUp` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** high/low input, indexed rolling extrema, multi-output records.

**Bend implementation:** Maintain highest-high and lowest-low candidates with their bar indices over period+1 bars. Convert the ages to 100*(period-age)/period and return a record containing down and up, keeping integer ages outside the numeric price representation. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The window includes today and the bar period positions back. Ties select the most recent equal high or low. A period-sized window or oldest-tie deque produces a different indicator. Output order in TA-Lib is down then up; named Bend fields avoid positional confusion.

**Validation:** Use a plateau of tied highs/lows and an extremum exactly at the oldest included bar.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/aroon/aroon.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/aroon/aroon.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AROON.c).

### `AROONOSC` — Aroon Oscillator

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** indexed rolling extrema, AROON core.

**Bend implementation:** Reuse AROON's period+1 indexed extrema and calculate up minus down, or directly scale the difference between the two selected indices. Keep this as another view of the same extrema state so tie and window rules cannot diverge. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The full lookback is period. Most-recent ties and the extra bar are as important here as for AROON. Integer index subtraction needs a signed result before conversion; unsigned underflow would corrupt negative oscillator values.

**Validation:** Check equality to AroonUp-AroonDown, including ties and both positive and negative index differences.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/aroonosc/aroonosc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/aroonosc/aroonosc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AROONOSC.c).

### `ASI` — Wilder Accumulative Swing Index

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Limit Move = `3` (double, 1e-8..3e+37).

**Readiness:** Existing. **Dependencies:** OHLC bar input, SI core, cumulative accumulator.

**Bend implementation:** Reuse the SI per-bar calculation and keep its running sum alongside the previous close/body. The first input establishes the anchor and emits zero; subsequent inputs add their unrounded Swing Index to that anchor-relative total. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Unlike SI, ASI has zero lookback and starts a fresh cumulative line at the requested range's first bar. Decide whether Bend exposes only fresh streams or a compatibility start-range API. Validate a positive limit move and document F32 long-run accumulation drift; do not round each swing to integers.

**Validation:** Check initial zero, cumulative agreement with SI, and a reset at a later start bar.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/asi/asi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/asi/asi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ASI.c).

### `BOP` — Balance Of Power

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** OHLC bar input.

**Bend implementation:** Use a stateless generic bar transform: divide close-open by high-low, with the source's zero/nonpositive-range branch. Only subtraction, division and comparison capabilities are needed, so the numeric template is small.

**Blockers and special considerations:** There is no warm-up. The source returns zero when the bar range is nonpositive; it does not assume every supplied bar is well formed. Preserve that branch and avoid an arbitrary fixed epsilon that erases valid small quoted ranges. The implemented F32 function accepts a typed OHLC record.

**Validation:** Test bullish/bearish bars, a zero-range bar and an inverted high/low bar.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/bop/bop.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/bop/bop.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_BOP.c).

### `CCI` — Commodity Channel Index

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** HLC bar input, typical-price transform, owned window, mean absolute deviation.

**Bend implementation:** Store a period of typical prices, compute that window's mean and then the mean absolute distance from the same mean, and divide the current typical-price deviation by 0.015 times that distance. A straightforward O(period) scan is an honest first implementation. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Availability begins after period prices. Mean absolute deviation cannot be replaced by standard deviation, nor maintained by merely updating distances from the old mean. Preserve scaled near-flat checks and the zero output. F32 cancellation at high price offsets warrants centered sums and threshold-focused tests.

**Validation:** Use a flat window, a single outlier and large-offset small-spread bars; compare against an explicit window calculation.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cci/cci.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cci/cci.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CCI.c).

### `CG` — Center of Gravity Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned window, weighted sums, accurate accumulation.

**Bend implementation:** Retain a period of prices and compute the negative ratio of an age-weighted sum to the ordinary sum, with the newest sample weighted one. Begin with a bounded window scan; later optimize the two sums only after numerical behavior is specified.

**Blockers and special considerations:** This is Ehlers' negative unshifted form. A zero denominator yields -(period+1)/2, not a carried previous value or zero. Current upstream uses exact finite-window accumulation where possible; ordinary F32 running sums cannot promise that contract. Positive input is the intended domain, with severe sensitivity near a zero sum.

**Validation:** Check constant positive prices, cancellation to an exact zero sum, and weight orientation on a ramp.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cg/cg.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cg/cg.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CG.c).

### `CHOP` — Choppiness Index

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** HLC bar input, true range, rolling extrema, rolling sums, log10.

**Bend implementation:** Accumulate true range over a period and track the window's raw highest high and lowest low. Return 100*log10(sumTR/rawRange)/log10(period), with explicit degenerate handling. A simple rescanned window can establish correctness before a streaming extrema optimization. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** A period of true ranges needs period+1 bars. A gap before the window affects the numerator but not its raw high-low box, so readings can exceed 100 and must not be clamped. Zero box height or no true range returns 100. Avoid leaving a rolling-sum residue after a flat window.

**Validation:** Include a gap into the window that makes CHOP exceed 100, plus a fully flat window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/chop/chop.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/chop/chop.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CHOP.c).

### `CHOPTR` — Choppiness Index (True Range Box)

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** HLC bar input, true-high/true-low transform, rolling extrema, rolling sums, log10.

**Bend implementation:** Use the CHOP logarithmic calculation but form each extremum from max(high,previousClose) and min(low,previousClose). Track the highest true high, lowest true low and summed true ranges over the same period. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** This is the true-range-box version and must remain distinct from CHOP. It consumes the prior close before the window. No true range returns 100; for valid bars the ratio is bounded by the period. Exact zero recovery after old movement expires matters more than avoiding an O(period) rescan initially.

**Validation:** Compare CHOP and CHOPTR across a gap into the window; check a straight run and a flat window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/choptr/choptr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/choptr/choptr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CHOPTR.c).

### `CMO` — Chande Momentum Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** price changes, Wilder smoothing, warm-up configuration.

**Bend implementation:** Split each price change into nonnegative gain and loss, seed their average values over a period, Wilder-smooth both, and return 100*(gain-loss)/(gain+loss). Share the change/smoothing machinery with RSI but use a distinct output transform. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** TA-Lib's CMO is Wilder-smoothed; Chande's unsmoothed moving-window form is CMOU. The full lookback includes the configured CMO unstable discard and one prior price. A zero gain-plus-loss total returns zero. F32 decay can reach rounding residue sooner than binary64.

**Validation:** Compare smoothed CMO with CMOU after an old shock leaves the window; include flat and all-rising data.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cmo/cmo.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cmo/cmo.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CMO.c).

### `CMOU` — Chande Momentum Oscillator (Unsmoothed)

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** price changes, rolling gain/loss sums.

**Bend implementation:** Keep a ring of positive and negative changes and update the two finite-window sums on entry/expiry. Return 100*(upSum-downSum)/(upSum+downSum); recompute or reset carefully when the complete window becomes flat. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** This is the unsmoothed CMO variant: no Wilder state and no unstable discard. The first value needs period changes, hence period+1 prices. A zero total returns zero. Sum drift must not turn a fully flat window into a nonzero oscillator after an earlier move expires.

**Validation:** Exercise a single jump followed by enough unchanged bars to expire it, and compare the resulting exact-zero tail.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cmou/cmou.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cmou/cmou.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CMOU.c).

### `COPPOCK` — Coppock Curve

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** WMA Period = `10` (integer, 1..100000); ROC-1 Period = `11` (integer, 1..100000); ROC-2 Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** ROC lag buffers, WMA.

**Bend implementation:** Compute two percentage ROCs, add them, and feed that sum into a WMA. The streaming state owns the necessary price history and the WMA window; it need not materialize whole intermediate series. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The two ROCs are summed rather than averaged. ROC-period order is not restricted and the lookback is max(ROC periods)+WMA period-1. Each zero lagged price contributes zero for its leg. Positive prices are the intended domain; other libraries may differ by a factor of two.

**Validation:** Test swapped ROC periods, a hand-computed pair of ROCs and the sum-versus-average amplitude distinction.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/coppock/coppock.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/coppock/coppock.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_COPPOCK.c).

### `CRSI` — Connors Relative Strength Index

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `3` (integer, 2..100000); Streak Period = `2` (integer, 2..100000); Rank Period = `100` (integer, 2..10000).

**Readiness:** Existing. **Dependencies:** RSI, signed streak state, ROCP, percent rank, aligned composition.

**Bend implementation:** Combine RSI of closes, RSI of a signed up/down streak, and the strict percent rank of the current one-bar return among earlier returns. Keep signed streak counts in an integer representation and average the three aligned 0..100 outputs.

**Blockers and special considerations:** An unchanged close resets the streak to zero. Percent rank excludes the current observation and counts strictly smaller prior returns. The two RSI legs inherit RSI's configured unstable discard, with streak RSI starting one bar later. Current flat-RSI behavior is 50, so old oracle versions change flat CRSI too.

**Validation:** Use tied returns, streak reversal/equality and all-flat prices under a recorded TA-Lib version/configuration.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/crsi/crsi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/crsi/crsi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CRSI.c).

### `CTI` — Correlation Trend Indicator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned window, stable centered covariance, sqrt, clamp.

**Bend implementation:** Calculate the Pearson correlation of the trailing prices with an increasing time coordinate. Reuse a centered rolling regression/covariance primitive, with the coordinate variance computed from the period instead of storing a second input series.

**Blockers and special considerations:** Minimum period is two; constant prices return zero and results are clamped to [-1,1]. Naive sums of squares lose F32 spread at large price offsets. A centered or rescanned formulation is preferable, but changed rounding needs toleranced reference tests rather than a binary64 parity claim.

**Validation:** Check ascending/descending ramps at +/-1, constant prices at zero, and a large-offset tiny-variation window.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cti/cti.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cti/cti.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CTI.c).

### `DOSC` — Derivative Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000); First Smoothing Period = `5` (integer, 2..100000); Second Smoothing Period = `3` (integer, 2..100000); Signal Period = `9` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** RSI, EMA, SMA, composed warm-up.

**Bend implementation:** Stream RSI through a first EMA and a second EMA, then subtract a signal-period SMA of that twice-smoothed series. Bundle stage counters and state so only valid output from one stage feeds the next. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Lookback is RSI plus both EMA lookbacks plus the signal SMA lookback; configured EMA unstable discard counts twice. Smoothing periods are ordered stages and must not be silently sorted. Signal period is at least two. Current flat RSI is 50; the completed DOSC still settles at zero on constant input.

**Validation:** Compare with the explicit four-stage chain and swap the EMA periods to detect incorrect stage sorting.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dosc/dosc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dosc/dosc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_DOSC.c).

### `DPO` — Detrended Price Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** lag buffer, SMA, display-shift metadata.

**Bend implementation:** Keep the price displaced by floor(period/2)+1 bars and subtract the current period SMA. Emit the computed value on the current observation, alongside optional display-shift metadata for callers wanting the conventional left-shifted chart.

**Blockers and special considerations:** The source delays price, not the moving average. Plotting at a negative display shift is a separate concern; moving an output into a prior bar would violate an append-only next API. The lookback is max(period-1,displacement), which matters for short periods.

**Validation:** Use a nonlinear sequence and short odd/even periods to distinguish delayed-price from delayed-average formulas and plotting alignment.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dpo/dpo.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dpo/dpo.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_DPO.c).

### `DX` — Directional Movement Index

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** directional movement, true range, Wilder smoothing, warm-up configuration.

**Bend implementation:** Expose the directional-movement engine's normalized absolute spread: 100*abs(plusDI-minusDI)/(plusDI+minusDI). Retain the previous DX as explicit state because degenerate later bars can require carrying it forward. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Current source carries previous DX when the directional denominator is zero, with zero on the initial degenerate output. It is not always a stateless division returning zero. Initial DM/TR sums, Wilder steps and the configured DX Auto/manual discard must match the chosen compatibility contract.

**Validation:** Test a directional episode followed by degenerate bars, plus equal competing high/low movements and a flat initial seed.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dx/dx.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/dx/dx.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_DX.c).

### `ER` — Kaufman Efficiency Ratio

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** lag buffer, absolute changes, rolling sum.

**Bend implementation:** Retain the price period bars back and a window of absolute one-bar changes. Divide absolute net change by total path length, applying the source's limiting/flat rules. The same primitive can support KAMA without copying the path calculation. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The first value consumes period+1 prices. A dead-flat window returns one, not zero, matching KAMA's convention; the result is bounded to 0..1. Keep exact-zero recovery when old changes expire and prevent a roundoff-sized denominator from manufacturing efficiency beyond one.

**Validation:** Check a monotonic path, an oscillating round trip, and a shock followed by a fully expired flat window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/er/er.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/er/er.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ER.c).

### `ERI` — Elder Ray Index (Bull Power / Bear Power)

**Interface:** inputs `High`, `Low`, `Close`; outputs `outBullPower` (real), `outBearPower` (real).

**Parameters:** Time Period = `13` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** HLC bar input, EMA, multi-output records.

**Bend implementation:** Maintain one EMA of close and return named bullPower=high-EMA and bearPower=low-EMA fields. Both outputs must share exactly the same EMA state and output alignment. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The full configured EMA lookback applies. This API returns two lines, unlike vendors that plot only their sum; no selectable average is part of this function. These are cancelling differences near crossings, making absolute tolerance essential when comparing F32 against binary64 references.

**Validation:** Assert bullPower-bearPower equals high-low within tolerance, and test close/EMA crossings on a flat market.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/eri/eri.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/eri/eri.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ERI.c).

### `FISHER` — Fisher Transform

**Interface:** inputs `High`, `Low`; outputs `outFisher` (real), `outTrigger` (real).

**Parameters:** Time Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** high/low midpoint, rolling extrema, log, multi-output records, warm-up configuration.

**Bend implementation:** Locate the current midpoint inside its trailing midpoint channel, smooth the centered position recursively, apply the source's limiter, and feed a logarithmic Fisher transform into another recurrence. Return Fisher and the previous Fisher as trigger.

**Blockers and special considerations:** A flat channel uses neutral position 0.5. The limiter is a thresholded jump to +/-0.999 when the intermediate exceeds +/-0.99, not a simple clamp to 0.99. Zero seeds precede a configured FISHER unstable discard. F32 logarithms and limiter crossings need explicit tolerance and branch tests.

**Validation:** Use constant midpoints, persistent channel extremes and inputs on each side of the limiter threshold.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/fisher/fisher.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/fisher/fisher.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_FISHER.c).

### `FOSC` — Forecast Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `5` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** rolling linear regression, one-step forecast, lagged forecast.

**Bend implementation:** Fit a regression over the period prices preceding the current bar, extrapolate that fit one coordinate forward, and emit 100*(currentPrice-forecast)/currentPrice. Store the forecast until the next price arrives to preserve causal evaluation. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The first output needs period prior observations and a current observation. A same-bar regression comparison is a different CFO-style series. Exact zero current price yields zero; near-zero positive prices amplify errors. F32 regression should center values to protect small departures from a large level.

**Validation:** Check a perfect linear trend at zero forecast error and a single surprise current bar; verify no current-price leakage into its forecast.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/fosc/fosc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/fosc/fosc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_FOSC.c).

### `FRACTAL` — Williams Fractal

**Interface:** inputs `High`, `Low`; outputs `outSwingHigh` (integer), `outSwingLow` (integer).

**Parameters:** Left Bars = `2` (integer, 1..100000); Right Bars = `2` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** high/low window, integer outputs, delayed confirmation, display-shift metadata.

**Bend implementation:** Buffer leftBars+rightBars+1 bars and, at each new bar, test the candidate rightBars positions behind it against every other high/low in the window. Return separate integer swingHigh and swingLow flags at the confirmation bar.

**Blockers and special considerations:** Both comparisons are strict: any tied high cancels only the high flag, and any tied low cancels only the low flag. The source emits 100/0 and reports a negative display shift for plotting at the pivot. Bend needs an explicit confirmation/pivot-index convention to avoid suggesting the signal was available earlier.

**Validation:** Use plateaus, an outside bar that is both pivots, and a late bar that invalidates an apparent but unconfirmed pivot.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/fractal/fractal.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/fractal/fractal.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_FRACTAL.c).

### `IBS` — Internal Bar Strength

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** HLC bar input.

**Bend implementation:** Compute (close-low)/(high-low) as a stateless generic transform, returning 0.5 for a nonpositive bar range. An HLC input record avoids passing parallel lists of potentially different lengths.

**Blockers and special considerations:** No warm-up is needed. The exact range test intentionally avoids a fixed quote-unit epsilon. Output is not clamped: a close outside its high/low range can produce values outside 0..1. Neutral 0.5 must not be replaced by the zero convention used by several other oscillators.

**Validation:** Test close at low/mid/high, zero/inverted ranges and a close outside its own bar.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ibs/ibs.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ibs/ibs.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_IBS.c).

### `IMI` — Intraday Momentum Index

**Interface:** inputs `Open`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** open/close input, rolling body gain/loss sums.

**Bend implementation:** For each candle split close-open into nonnegative up-body and down-body magnitudes. Sum each over the period, then return 100*up/(up+down). Reuse owned rolling-sum mechanics while retaining a pair of related totals. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Availability starts after period bars, rather than period changes between closes. Equal open/close contributes zero. An all-doji window returns neutral 50 in the actual source. Preserve expiry-to-flat behavior and do not confuse these intrabar changes with RSI's close-to-close changes.

**Validation:** Use alternating bullish/bearish bodies, all-doji candles and a large body that expires out of the window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/imi/imi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/imi/imi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_IMI.c).

### `KDJ` — KDJ Stochastic

**Interface:** inputs `High`, `Low`, `Close`; outputs `outK` (real), `outD` (real), `outJ` (real).

**Parameters:** Fast-K Period = `9` (integer, 1..100000); Slow-K Period = `3` (integer, 1..100000); Slow-K MA = `13` (MA selector; see common enum notes); Slow-D Period = `3` (integer, 1..100000); Slow-D MA = `13` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** stochastic core, moving-average dispatch, RMA, multi-output records.

**Bend implementation:** Reuse the slow stochastic pipeline for K and D, then compute J=3*K-2*D in the same output record. Keep one raw-stochastic window and the two selected smoothing states. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Current defaults use RMA/Wilder smoothing, not SMA, and seed each smoother with an initial mean. J is intentionally unbounded. Flat raw stochastic is zero. A full selectable-MA interface requires the MA dispatch foundation, and combined output starts only when D is available.

**Validation:** Compare SMA-selected K/D with STOCH, test default RMA transients, and retain a case where J leaves 0..100.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kdj/kdj.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kdj/kdj.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KDJ.c).

### `KST` — Know Sure Thing (Pring)

**Interface:** inputs `inReal`; outputs `outKST` (real), `outKSTSignal` (real).

**Parameters:** ROC-1 Period = `10` (integer, 1..100000); ROC-2 Period = `15` (integer, 1..100000); ROC-3 Period = `20` (integer, 1..100000); ROC-4 Period = `30` (integer, 1..100000); SMA-1 Period = `10` (integer, 1..100000); SMA-2 Period = `10` (integer, 1..100000); SMA-3 Period = `10` (integer, 1..100000); SMA-4 Period = `15` (integer, 1..100000); Signal Period = `9` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** ROC, SMA, multi-output records, aligned composition.

**Bend implementation:** Run four ROC legs with their own smoothing SMA periods; add their aligned values with fixed weights 1,2,3,4. Feed the weighted sum into a signal SMA and return the line/signal pair when both are valid. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Do not divide by the weight total or reorder the legs: weights belong to positions, not sorted period lengths. Each ROC keeps its zero-divisor rule. The first output is governed by the latest ROC-plus-SMA leg and then the signal SMA; signal period one yields identical line and signal.

**Validation:** Check position-dependent weights, unequal leg warm-ups and the signal-period-one identity.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kst/kst.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kst/kst.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KST.c).

### `KSTEXT` — Know Sure Thing with controllable MA type

**Interface:** inputs `inReal`; outputs `outKST` (real), `outKSTSignal` (real).

**Parameters:** ROC-1 Period = `10` (integer, 1..100000); ROC-2 Period = `15` (integer, 1..100000); ROC-3 Period = `20` (integer, 1..100000); ROC-4 Period = `30` (integer, 1..100000); MA-1 Period = `10` (integer, 1..100000); MA-2 Period = `10` (integer, 1..100000); MA-3 Period = `10` (integer, 1..100000); MA-4 Period = `15` (integer, 1..100000); Signal Period = `9` (integer, 1..100000); ROC MA = `0` (MA selector; see common enum notes); Signal MA = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** ROC, moving-average dispatch, multi-output records, aligned composition.

**Bend implementation:** Generalize KST by selecting one MA type for all four ROC smoothing legs and another for the signal. Compute actual lookback for each period/type pair and align their weighted sum before starting the selected signal state.

**Blockers and special considerations:** Full MA support is a dependency; accepting unsupported enum values would misstate compatibility. SMA/SMA should reduce to KST. Signal period one bypasses smoothing for every signal MA type; MAMA's period-insensitive behavior and each selected type's unstable discard complicate warm-up.

**Validation:** Compare SMA/SMA to KST, mix MA types with different lookbacks, and check signal period one for a non-SMA selection.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kstext/kstext.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kstext/kstext.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KSTEXT.c).

### `MACD` — Moving Average Convergence/Divergence

**Interface:** inputs `inReal`; outputs `outMACD` (real), `outMACDSignal` (real), `outMACDHist` (real).

**Parameters:** Fast Period = `12` (integer, 2..100000); Slow Period = `26` (integer, 2..100000); Signal Period = `9` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** EMA compatibility state, multi-output records, aligned composition.

**Bend implementation:** Coordinate fast and slow EMA seeds so their first published difference occurs at the same bar, then feed those differences to a signal EMA. Return a record of line, signal and line-minus-signal histogram from the same step. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Running two existing EMAs independently from bar zero is not sufficient for TA-Lib's source seed placement. Swapped periods are normalized. Full lookback includes slow and signal EMA lookbacks with recorded unstable settings. Signal period one must publish signal=line and histogram=0 without misalignment.

**Validation:** Check first-output seeds against a pinned oracle, inverted periods and signal period one, including batch/stream agreement.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/macd/macd.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/macd/macd.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MACD.c).

### `MACDEXT` — MACD with controllable MA type

**Interface:** inputs `inReal`; outputs `outMACD` (real), `outMACDSignal` (real), `outMACDHist` (real).

**Parameters:** Fast Period = `12` (integer, 2..100000); Fast MA = `0` (MA selector; see common enum notes); Slow Period = `26` (integer, 2..100000); Slow MA = `0` (MA selector; see common enum notes); Signal Period = `9` (integer, 1..100000); Signal MA = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** moving-average dispatch, multi-output records, aligned composition.

**Bend implementation:** Use a three-stage configurable MA composition: independent fast and slow type/period pairs feed their difference into a third selected MA. Encapsulate this dispatch and coordination once rather than writing a special algorithm per type combination.

**Blockers and special considerations:** When periods are swapped, their MA types must travel with them. The larger actual MA lookback, not simply the larger period, drives the input alignment. Two MAMA legs are identical even at different periods. Signal period one bypasses any selected signal type. Current defaults are all SMA.

**Validation:** Test mixed MA types whose lookback order differs from period order; compare SMA/SMA/SMA composition and signal-period-one behavior.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/macdext/macdext.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/macdext/macdext.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MACDEXT.c).

### `MACDFIX` — Moving Average Convergence/Divergence Fix 12/26

**Interface:** inputs `inReal`; outputs `outMACD` (real), `outMACDSignal` (real), `outMACDHist` (real).

**Parameters:** Signal Period = `9` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** EMA coefficient/seed control, MACD output record.

**Bend implementation:** Reuse the coordinated MACD engine with fixed fast and slow seed lengths 12/26 but explicitly bind smoothing coefficients 0.15 and 0.075. Keep the signal-period parameter and three-output record. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** This is not an alias for MACD(12,26): those standard EMA coefficients are 2/13 and 2/27. The existing EMA initializer computes coefficients from a period, so an internal validated coefficient/seed seam is needed. Lookback and unstable settings still follow the fixed 26-period and signal EMA paths.

**Validation:** Use a changing series that distinguishes fixed coefficients from MACD(12,26), and test signal period one.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/macdfix/macdfix.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/macdfix/macdfix.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MACDFIX.c).

### `MFI` — Money Flow Index

**Interface:** inputs `High`, `Low`, `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** HLCV bar input, typical-price transform, rolling money-flow sums.

**Bend implementation:** Classify each typical-price change as positive, negative or unchanged; place typicalPrice*volume into the corresponding period ring and emit 100*positive/(positive+negative). Carry prior typical price and the two finite-window totals. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The first value requires period changes and hence period+1 bars. Equal typical prices contribute neither flow. No flow returns zero, while quote/volume rescaling should otherwise preserve the ratio. Source guards scaled price differences; F32 money-flow products and large totals may overflow even when the ratio is modest.

**Validation:** Test unchanged prices with nonzero volume, zero volumes, a flow leaving the window and quote/volume rescaling.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mfi/mfi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mfi/mfi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MFI.c).

### `MINUS_DI` — Minus Directional Indicator

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** directional movement, true range, Wilder smoothing, warm-up configuration.

**Bend implementation:** Expose negative directional movement divided by smoothed true range from the common directional engine. For period greater than one, use its source-specific initial period-1 sums and subsequent Wilder updates, then multiply the ratio by 100. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The period-one special case returns raw -DM/TR without multiplying by 100, so a generic normalized wrapper would be wrong. Equal competing moves select neither direction. Zero true range returns zero; configured MINUS_DI unstable discard applies only to the smoothed path.

**Validation:** Test period one separately from period two, equal competing moves, and an exactly flat true-range denominator.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minus_di/minus_di.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minus_di/minus_di.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MINUS_DI.c).

### `MINUS_DM` — Minus Directional Movement

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** high/low input, directional movement, Wilder smoothing, warm-up configuration.

**Bend implementation:** Compute max(previousLow-low,0) only when it strictly exceeds high-previousHigh. Period one emits that raw movement; larger periods seed a sum of the first period-1 movements and keep a Wilder-smoothed total. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** This output is a smoothed movement total, not an average and not a percentage. Returning the RMA result without its period scaling would be incorrect. The base lookback is period-1 for the smoothed path plus its configured unstable discard, versus one for period one.

**Validation:** Use equal opposing movements, isolated down moves and period-one versus multi-period outputs to detect wrong scaling.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minus_dm/minus_dm.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minus_dm/minus_dm.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MINUS_DM.c).

### `MOM` — Momentum

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** lag buffer.

**Bend implementation:** Keep a period-lag price ring and return current minus lagged price. Warm-up slots are None until the old price exists; a generic numeric subtraction is the only arithmetic capability required.

**Blockers and special considerations:** The first output is at index period, consuming period+1 samples. MOM is a price difference, not a percentage return. F32 may erase small differences between large prices, so the public precision limitation is visible even in this simplest indicator.

**Validation:** Check a constant sequence, an affine ramp, period one and a large-level change smaller than F32 spacing.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mom/mom.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mom/mom.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MOM.c).

### `PLUS_DI` — Plus Directional Indicator

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** directional movement, true range, Wilder smoothing, warm-up configuration.

**Bend implementation:** Expose positive movement divided by smoothed true range from the common directional engine. Select a positive high increase only when it is strictly larger than the competing low decrease, then follow the source's initial sums and Wilder recurrence. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** As with MINUS_DI, period one returns +DM/TR without the usual factor 100. Multi-period output uses 100 times the ratio. Preserve zero true-range handling and the PLUS_DI-specific unstable setting; do not share counters blindly with ADX, which has a different additional seed stage.

**Validation:** Check an outside bar with equal legs, pure upward movement, period one and zero-range bars.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/plus_di/plus_di.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/plus_di/plus_di.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PLUS_DI.c).

### `PLUS_DM` — Plus Directional Movement

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** high/low input, directional movement, Wilder smoothing, warm-up configuration.

**Bend implementation:** Select a positive high-to-high increase only when larger than the competing downward low movement. Emit raw movement at period one; otherwise maintain the Wilder-smoothed movement total from the initial period-1 sum. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The output retains price units and is a total, unlike PLUS_DI and an ordinary mean-seeded RMA. Equal competing legs both become zero. The smoothed path's first bar and optional configured unstable discard need a separate readiness counter from the raw path.

**Validation:** Use equal competing legs and isolated upward gaps; compare raw period-one values with a hand-updated Wilder total.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/plus_dm/plus_dm.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/plus_dm/plus_dm.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PLUS_DM.c).

### `PPO` — Percentage Price Oscillator

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Fast Period = `12` (integer, 2..100000); Slow Period = `26` (integer, 2..100000); MA Type = `1` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** moving-average dispatch, aligned composition, zero-divisor policy.

**Bend implementation:** Reuse the APO fast/slow MA composition and scale its difference by 100/slowMA. Keep the slow value available in the shared state rather than deriving it from the already-subtracted APO result. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Current default is EMA; inverted fast/slow periods are swapped. The source maps a slow average strictly inside (-1e-14,1e-14) to zero; values just outside can produce very large results. Source SMA and general paths include specialized flat/numeric handling, so define a tested F32 zero policy rather than blindly copying a fixed binary64 epsilon. Positive prices are intended.

**Validation:** Compare with normalized APO, test equal periods, swapped periods and zero or tiny slow-average values.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ppo/ppo.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ppo/ppo.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PPO.c).

### `PSO` — Premier Stochastic Oscillator

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Fast-K Period = `8` (integer, 1..100000); EMA Period = `5` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** rolling extrema, EMA, tanh, HLC bar input.

**Bend implementation:** Normalize raw Fast-K as 0.1*(K-50), pass it through two EMA stages, and emit tanh(secondEMA/2). Keep the affine transform before smoothing and use a raw-stochastic primitive whose flat-window value can be selected explicitly. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** PSO uses neutral Fast-K=50 on a flat window, unlike STOCHF's zero. Both EMAs are mean-seeded and inherit configured EMA lookbacks. Using tanh avoids overflow of the equivalent exponential quotient. Bind tanh as a needed template capability; no new external math dependency is required for F32.

**Validation:** Check flat input at zero output, composed-stage agreement and out-of-range close values that would overflow an exponential quotient.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pso/pso.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pso/pso.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PSO.c).

### `QSTICK` — Qstick

**Interface:** inputs `Open`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** open/close input, SMA.

**Bend implementation:** Transform each input candle to close-open and feed that signed body into the existing generic SMA. The wrapper owns only the SMA state and a typed open/close input conversion. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** This function is specifically a simple average, without an MA-type parameter or recursive unstable period. Period one returns the raw candle body. It consumes period bars, not close-to-close changes. Near-cancelling bullish/bearish bodies and large price offsets need F32 absolute-tolerance fixtures.

**Validation:** Check period-one identity, alternating equal bullish/bearish bodies and a hand-computed full window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/qstick/qstick.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/qstick/qstick.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_QSTICK.c).

### `ROC` — Rate of change : ((price/prevPrice)-1)*100

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** lag buffer, zero-divisor policy.

**Bend implementation:** Reuse the shared owned window and validated init/next/batch interface. Compute ((current-previous)/previous)*100 after period prior samples exist. The generic core and concrete F32 binding are implemented; see [the interface and arithmetic policy](direct-indicators.md).

**Blockers and special considerations:** This deliberately uses difference-first arithmetic to retain small F32 changes on large positive price baselines, rather than the pinned double implementation's ratio-first expression. Exact zero previous price returns zero. Tiny divisors and extreme opposite-sign spreads can still overflow. First availability is index period, and no double-precision bit parity is claimed.

**Validation:** Test equal prices, a known percentage jump, zero lagged price and near-equal large prices.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/roc/roc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/roc/roc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ROC.c).

### `ROCP` — Rate of change Percentage: (price-prevPrice)/prevPrice

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** lag buffer, zero-divisor policy.

**Bend implementation:** Use the common lag buffer and compute (current-lagged)/lagged without percentage scaling. Expose this as a distinct view so callers cannot confuse fractional returns with ROC's percentage units.

**Blockers and special considerations:** Exact zero lagged price returns zero; availability starts at index period. The source's difference-first ordering differs from ROC's ratio-first ordering, especially under F32 cancellation and rounding. Positive prices are intended, and a near-zero denominator remains ill-conditioned.

**Validation:** Check fractional-return units, zero lagged price and a near-equal pair where ratio-first and difference-first arithmetic round differently.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rocp/rocp.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rocp/rocp.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ROCP.c).

### `ROCR` — Rate of change ratio: (price/prevPrice)

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** lag buffer, zero-divisor policy.

**Bend implementation:** Reuse the lag state and emit current/lagged as a raw ratio. This needs no subtraction or percentage factor, so its numeric template can require fewer operations than ROC.

**Blockers and special considerations:** A constant nonzero series reads one, whereas ROC and ROCP read zero. A zero denominator still yields zero under the source convention. Publish only after period prior positions exist, and document the positive-price domain and potentially huge ratios near zero.

**Validation:** Test constant nonzero input at one, a doubled price at two and the zero-denominator branch.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rocr/rocr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rocr/rocr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ROCR.c).

### `ROCR100` — Rate of change ratio 100 scale: (price/prevPrice)*100

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** lag buffer, zero-divisor policy.

**Bend implementation:** Return 100 times the current-to-lagged ratio from the shared rate-of-change state. Keep the multiplication after the division to follow the source's operation ordering.

**Blockers and special considerations:** This is a ratio on a base-100 scale, not percentage change: a constant nonzero series reads 100, not zero. A zero lagged price yields zero. F32 multiplication can overflow after a finite ratio, and near-zero divisors require explicit finite-domain tests.

**Validation:** Check constant input at 100, a doubled price at 200, and the exact-zero lagged-price rule.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rocr100/rocr100.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rocr100/rocr100.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ROCR100.c).

### `RSI` — Relative Strength Index

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** price changes, Wilder smoothing, warm-up configuration.

**Bend implementation:** Split price changes into gains and losses, seed each average over a period, then Wilder-smooth both and compute 100*averageGain/(averageGain+averageLoss). This avoids explicitly forming an infinite gain/loss ratio when losses vanish. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Pinned current TA-Lib returns neutral 50 on an all-flat seed; versions through 0.8.1 returned zero. All-rising/falling inputs yield 100/0. Full lookback adds the configured RSI Auto/manual unstable discard. Long flat tails reveal recursive residue and F32 underflow behavior earlier than binary64, so version and tolerance are essential.

**Validation:** Capture all-flat, only-rising, only-falling and move-then-long-flat cases with the exact upstream version and unstable setting recorded.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rsi/rsi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rsi/rsi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_RSI.c).

### `SI` — Wilder Swing Index

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Limit Move = `3` (double, 1e-8..3e+37).

**Readiness:** Existing. **Dependencies:** OHLC bar input, previous-bar state, validated positive limit move.

**Bend implementation:** Carry prior close and prior candle body. Combine current close change, current/prior bodies and high/low distances into Wilder's piecewise swing denominator, then scale the signed numerator by the limit-move ratio. Only a single prior bar is required. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The first output is at index one. A zero swing denominator returns zero; outputs are unrounded and may exceed +/-100 when moves exceed the configured limit. Validate limitMove independently of period validation. The exact source arithmetic and F32 cancellation across previous/current bodies deserve focused fixtures.

**Validation:** Exercise each denominator case, a zero denominator, a gap exceeding the limit and the first valid bar.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/si/si.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/si/si.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SI.c).

### `SMI` — Stochastic Momentum Index

**Interface:** inputs `High`, `Low`, `Close`; outputs `outSMI` (real), `outSMISignal` (real).

**Parameters:** Time Period = `13` (integer, 2..100000); Fast Period = `2` (integer, 2..100000); Slow Period = `25` (integer, 2..100000); Signal Period = `9` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** rolling high/low extrema, EMA chains, multi-output records.

**Bend implementation:** Subtract the rolling high/low midpoint from close and separately retain the range width. Double-smooth numerator and denominator through slow-then-fast EMA stages, divide to obtain SMI, then feed SMI to a signal EMA and return both lines.

**Blockers and special considerations:** The range is divided by two in the final normalization. All EMA stages are mean-seeded and their configured lookbacks accumulate; both outputs are withheld until the signal exists. Zero smoothed range gives zero. Reordering the first two smoothing stages changes transient results even with the same total lookback.

**Validation:** Check a flat channel, extreme channel positions and asymmetric fast/slow periods against the explicit staged composition.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/smi/smi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/smi/smi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SMI.c).

### `SQZMOM` — Squeeze Momentum and Level

**Interface:** inputs `High`, `Low`, `Close`; outputs `outMomentum` (real), `outSqueeze` (integer).

**Parameters:** BB Period = `20` (integer, 2..100000); Deviations = `2` (double, 0..3e+37); KC Period = `20` (integer, 2..100000); Wide Factor = `2` (double, 0..3e+37); Normal Factor = `1.5` (double, 0..3e+37); Narrow Factor = `1` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** stable variance, SMA, true range, rolling extrema, rolling regression, mixed output record.

**Bend implementation:** Combine Bollinger bounds, Keltner-style SMA center/true-range width and a linear regression of close relative to a Donchian/SMA anchor. Return the regression momentum together with a signed integer compression level derived from narrow/normal/wide channel containment.

**Blockers and special considerations:** Width uses an SMA of TRANGE, not Wilder ATR. Validate wide>=normal>=narrow>=0 and use strict containment. Integer squeeze levels are 3/2/1, -1 for release and 0 otherwise. The two outputs begin at their common latest readiness; F32 errors near band crossings can change classification, not just numeric tolerance.

**Validation:** Test each compression level and exact boundary, equal factors, invalid ordering and mismatched BB/KC periods.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sqzmom/sqzmom.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sqzmom/sqzmom.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SQZMOM.c).

### `STC` — Schaff Trend Cycle

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Fast Period = `23` (integer, 2..100000); Slow Period = `50` (integer, 2..100000); Cycle Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** MACD-compatible line, rolling extrema, recursive normalization, warm-up configuration.

**Bend implementation:** Build the MACD line, normalize it in a cycle window, smooth with fixed weight 0.5, and repeat that normalized/smoothed stage. Store prior fractions explicitly so a zero normalization range can retain the previous fraction rather than divide.

**Blockers and special considerations:** Each fraction starts from zero until defined, while each smoother begins from its first input. Inverted fast/slow periods are swapped. The full lookback includes EMA warm-up, two cycle windows and STC's own configured unstable discard. These recurrences make start-history and flat-after-move behavior part of compatibility.

**Validation:** Check a flat start, a trend followed by a zero-range plateau, swapped periods and explicit warm-up settings.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stc/stc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stc/stc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_STC.c).

### `STOCH` — Stochastic

**Interface:** inputs `High`, `Low`, `Close`; outputs `outSlowK` (real), `outSlowD` (real).

**Parameters:** Fast-K Period = `5` (integer, 1..100000); Slow-K Period = `3` (integer, 1..100000); Slow-K MA = `0` (MA selector; see common enum notes); Slow-D Period = `3` (integer, 1..100000); Slow-D MA = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** rolling extrema, moving-average dispatch, HLC bar input, multi-output records.

**Bend implementation:** Calculate raw Fast-K from the close's position in the trailing high/low window, smooth it into Slow-K, then smooth Slow-K into Slow-D. Bundle the extrema state and both selected MA states and return named K/D fields. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** A flat raw range produces zero, using the source's scaled flatness rule. The first paired output includes both smoothing lookbacks; earlier valid K values are internal. Full selectable-MA compatibility requires implementing those MA types and their warm-ups, rather than assuming every lookback is period-1.

**Validation:** Check flat windows, period-one smoothers and a non-SMA selection with a longer warm-up.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stoch/stoch.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stoch/stoch.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_STOCH.c).

### `STOCHF` — Stochastic Fast

**Interface:** inputs `High`, `Low`, `Close`; outputs `outFastK` (real), `outFastD` (real).

**Parameters:** Fast-K Period = `5` (integer, 1..100000); Fast-D Period = `3` (integer, 1..100000); Fast-D MA = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** rolling extrema, moving-average dispatch, HLC bar input, multi-output records.

**Bend implementation:** Use the raw stochastic position as Fast-K and feed it to one selected MA for Fast-D. Reuse the same raw position primitive as STOCH but keep a distinct paired-output interface. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The period-sized high/low window includes the current bar. A scaled-zero range gives Fast-K zero, not PSO's neutral 50. Both outputs start after the D lookback, even though raw K exists sooner. Invalid close values outside the bar should follow an explicitly documented input policy.

**Validation:** Compare Fast-D with an MA of raw K; check a flat window and D-period-one identity.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stochf/stochf.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stochf/stochf.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_STOCHF.c).

### `STOCHRSI` — Stochastic Relative Strength Index

**Interface:** inputs `inReal`; outputs `outFastK` (real), `outFastD` (real).

**Parameters:** Time Period = `14` (integer, 2..100000); Fast-K Period = `5` (integer, 1..100000); Fast-D Period = `3` (integer, 1..100000); Fast-D MA = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** RSI, scalar stochastic core, moving-average dispatch, multi-output records.

**Bend implementation:** Feed valid RSI outputs into a scalar high/low/current stochastic stage, then smooth its Fast-K into Fast-D. The price-series RSI state and RSI-window extrema must remain separate owned states. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The first output includes RSI's full configured lookback plus Fast-K and D warm-ups. A flat RSI window returns zero for Fast-K, even though current flat RSI itself is 50. This is the fast stochastic RSI form, not automatically the common two-SMA TradingView variant.

**Validation:** Check constant RSI, current flat-RSI behavior, and equality with the explicit RSI-then-STOCHF chain under recorded settings.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stochrsi/stochrsi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stochrsi/stochrsi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_STOCHRSI.c).

### `TRIX` — 1-day Rate-Of-Change (ROC) of a Triple Smooth EMA

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** EMA chains, one-step ROC.

**Bend implementation:** Pass prices through three EMA stages of the same period and compute a one-bar percentage change of the third stage. Keep the previous third-EMA output rather than retaining an entire extra series. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The source lookback is three configured EMA lookbacks plus one. Each stage seeds from what its predecessor publishes; updating all three immediately from the first price gives a different transient. A zero previous third-EMA value yields zero. Near-zero and F32-flattened smoothed values can distort returns.

**Validation:** Compare a three-EMA-plus-ROC chain, a constant sequence and a zero previous smoothed value.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/trix/trix.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/trix/trix.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TRIX.c).

### `TSI` — True Strength Index

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** First Smoothing Period = `25` (integer, 2..100000); Second Smoothing Period = `13` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** price changes, EMA chains, zero-divisor policy.

**Bend implementation:** Double-smooth signed one-bar changes and absolute changes through parallel first-period and second-period EMA chains. Divide the signed chain by the absolute chain and multiply by 100, retaining counters to feed only valid stage outputs. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The two periods are ordered by application, not normalized to fast/slow; do not sort them. Seed each EMA from its own initial mean and add one input change to the summed configured EMA lookbacks. Exactly zero absolute-change denominator returns neutral zero. F32 long-tail decay can alter near-flat behavior.

**Validation:** Use asymmetric periods, all-flat input, one-direction moves and a change in sign after the seed.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tsi/tsi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tsi/tsi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TSI.c).

### `ULTOSC` — Ultimate Oscillator

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** First Period = `7` (integer, 1..100000); Second Period = `14` (integer, 1..100000); Third Period = `28` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** HLC bar input, true range, rolling sums, period normalization.

**Bend implementation:** Calculate buying pressure as close-min(low,previousClose) and true range per bar. Maintain pressure/range sums at three normalized periods and return the 4/2/1 weighted mean of their ratios on a 0..100 scale. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** TA-Lib sorts the three periods, so weights attach to shortest/middle/longest rather than argument positions. First availability is the longest period of changes, requiring one extra bar. Preserve each zero-range denominator contribution and ensure independent sum expiry does not leave a flat-window residue.

**Validation:** Permute the same three periods and require unchanged output; include flat ranges and a gap against the prior close.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ultosc/ultosc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ultosc/ultosc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ULTOSC.c).

### `VHF` — Vertical Horizontal Filter

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `28` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** rolling close extrema, absolute changes, rolling sum.

**Bend implementation:** Divide the range of the latest period closes by the sum of the latest period absolute changes. Share lag/change storage with ER while keeping VHF's different extrema-based numerator. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** The numerator spans period closes, whereas the denominator consumes period changes and thus one older close. Using the same number of input prices for both is an off-by-one error. A zero total path returns zero; unlike ER, a flat window is not one. Current source avoids accumulated residue by recomputing the path.

**Validation:** Test a move just outside the numerator window but inside the change window, plus a fully flat window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vhf/vhf.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vhf/vhf.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_VHF.c).

### `VORTEX` — Vortex Indicator

**Interface:** inputs `High`, `Low`, `Close`; outputs `outPlusVI` (real), `outMinusVI` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** HLC bar input, true range, rolling sums, multi-output records.

**Bend implementation:** Form absolute high-current minus low-previous and low-current minus high-previous movements alongside true range. Maintain the three period sums and return named plusVI/minusVI ratios against the shared range sum. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** There is no Wilder smoothing or unstable period. Each term needs a prior bar, placing the first output at index period. A zero true-range sum returns zero on both sides. Correct ring expiry and F32 sum drift matter after active bars are replaced by a flat window.

**Validation:** Check the first valid index, a flat window, high/low cross-gap terms and equality with a direct three-sum calculation.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vortex/vortex.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vortex/vortex.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_VORTEX.c).

### `WAD` — Williams' Accumulation/Distribution

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** HLC bar input, previous close, cumulative accumulator.

**Bend implementation:** Anchor a stream at zero, then add close-min(low,previousClose) for an up close, close-max(high,previousClose) for a down close, or zero for equality. Carry only previous close and the accumulated value. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** This is Williams accumulation/distribution, not the volume-weighted AD line. It has no volume input and zero lookback: the first requested bar emits zero. Restarting at a new origin shifts the cumulative line by a constant. F32 long-running sums may need compensated accumulation or an explicit reset policy.

**Validation:** Check unchanged closes, gaps in both directions, initial zero and separate streams anchored at different bars.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wad/wad.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wad/wad.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_WAD.c).

### `WAVETREND` — WaveTrend Oscillator

**Interface:** inputs `High`, `Low`, `Close`; outputs `outWT1` (real), `outWT2` (real).

**Parameters:** Channel Period = `10` (integer, 2..100000); Average Period = `21` (integer, 1..100000); Signal Period = `4` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** typical-price transform, EMA chains, SMA, multi-output records, repetition detection.

**Bend implementation:** EMA-smooth typical price, EMA-smooth its absolute deviation from that average, normalize the signed deviation by 0.015 times the deviation average, then EMA-smooth into WT1 and SMA-smooth WT1 into WT2. Bundle all stage state and previous-repeat checks.

**Blockers and special considerations:** This is not CCI followed by an average: its center and deviation are exponential. The source zeroes a frozen repeated price/EMA gap to prevent roundoff from driving a flat market toward +/-66.67. Three EMA warm-ups accumulate, and both lines publish only when WT2 is ready. F32 makes frozen-gap tests particularly important.

**Validation:** Test long constant tails after movement, a zero-deviation seed and the exact staged composition with source repetition handling.

**Bend interface:** Implemented under [the F32 contract](advanced-trend.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wavetrend/wavetrend.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wavetrend/wavetrend.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_WAVETREND.c).

### `WILLR` — Williams' %R

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** rolling high/low extrema, HLC bar input, clamp.

**Bend implementation:** Track highest high and lowest low over the period and return -100*(highest-close)/(highest-lowest). Reuse the stochastic extrema window while keeping this function's output scaling, flat rule and clamp in its own final transform. Current F32 contract: [implemented interface and limits](momentum.md).

**Blockers and special considerations:** Current source returns zero on a scaled-flat range and clamps results to [-100,0], including malformed closes outside the channel. It starts at index period-1, not period. A fixed absolute epsilon would make behavior depend on quote units; bind a deliberate F32-scaled comparison policy.

**Validation:** Check close at each channel endpoint, flat windows, tiny quote units and closes outside the channel to verify clamping.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/willr/willr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/willr/willr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_WILLR.c).

## Volume Indicators (14)

### `AD` — Chaikin A/D Line

**Interface:** inputs `High`, `Low`, `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed HLCV inputs, money-flow multiplier, cumulative state.

**Bend implementation:** Compute the close-location multiplier ((close-low)-(high-close))/(high-low), multiply by volume and add to cumulative AD, starting at zero. Share the multiplier with CMF and ADOSC. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** When high is not greater than low, add zero rather than divide. The accumulation anchor matters; do not reset at sessions unless explicitly requested. Large accumulated volume can erase small F32 increments.

**Validation:** Close at high/low/midpoint, zero/inverted range, zero volume and reset/subrange behavior.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ad/ad.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ad/ad.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AD.c).

### `ADOSC` — Chaikin A/D Oscillator

**Interface:** inputs `High`, `Low`, `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** Fast Period = `3` (integer, 2..100000); Slow Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** money-flow multiplier, cumulative AD, EMA primitives, stabilization settings.

**Bend implementation:** Feed the cumulative AD value into fast and slow exponential states and emit their difference. Implement the pinned ADOSC seed path directly, rather than assuming the ordinary public EMA init/next composition reproduces it.

**Blockers and special considerations:** Source initializes both EMA values from the initial AD anchor and has a composite auto-stabilization adjustment. Fast/slow orientation and nearly cancelling large volume averages require reference vectors; current bend-ta EMA alone does not establish parity.

**Validation:** Unequal and reversed periods, a flow-sign reversal, flat ranges and zero/explicit/auto unstable settings.

**Bend interface:** Implemented under [the F32 contract](volume-volatility.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adosc/adosc.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adosc/adosc.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ADOSC.c).

### `CMF` — Chaikin Money Flow

**Interface:** inputs `High`, `Low`, `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** money-flow multiplier, paired rolling sums, typed HLCV inputs.

**Bend implementation:** Keep rolling money-flow-volume and total-volume sums, then divide the former by the latter over the same period. Use the same per-bar multiplier as AD. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** A nonpositive range contributes zero flow but its volume still enters the denominator. Zero total volume produces zero. Output is an unscaled ratio, not percent; malformed closes outside the bar are not automatically clamped upstream.

**Validation:** All-zero volume, one flat-range bar, close at high/low, and a malformed close to document validation differences.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cmf/cmf.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cmf/cmf.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CMF.c).

### `EFI` — Elder's Force Index

**Interface:** inputs `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** Time Period = `13` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** previous close, EMA primitives, typed close-volume inputs.

**Bend implementation:** Compute force=(close-previousClose)*volume, then feed the resulting stream into the EMA core. The first raw force requires two closes. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Seed the EMA from complete force observations and inherit EMA stabilization; period1 returns raw force. Price-volume products overflow F32 earlier than prices themselves.

**Validation:** Period1 signed force, first output alignment for a longer period, a flat close and a high-volume spike.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/efi/efi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/efi/efi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_EFI.c).

### `EMV` — Arms Ease of Movement

**Interface:** inputs `High`, `Low`, `Volume`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000); Volume Divisor = `10000` (double, 1..3e+37).

**Readiness:** Existing. **Dependencies:** previous midpoint, rolling mean, typed HLV inputs.

**Bend implementation:** Compute midpoint movement times the current high-low range and volume divisor divided by volume, then SMA-smooth those raw values. Store the prior midpoint even when the current raw result is zero. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Zero range or zero volume contributes zero. The user volume divisor is an output scale; period1 is unsmoothed. Reordering the equivalent product/division changes rounding and overflow.

**Validation:** Zero-volume/flat-range bar followed by movement, divisor scaling, period1 and a hand-calculated window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/emv/emv.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/emv/emv.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_EMV.c).

### `KVO` — Klinger Volume Oscillator

**Interface:** inputs `High`, `Low`, `Close`, `Volume`; outputs `outKVO` (real), `outKVOSignal` (real).

**Parameters:** Fast Period = `34` (integer, 2..100000); Slow Period = `55` (integer, 2..100000); Signal Period = `13` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** typed HLCV inputs, trend state, EMA primitives, multi-output records.

**Bend implementation:** Track direction of H+L+C, directional cumulative range and volume force; form fast-minus-slow EMA force and a signal EMA. Keep named oscillator and signal outputs in one state.

**Blockers and special considerations:** Hold the previous trend when H+L+C ties. The pinned 1997 force is volume*abs(2*dm/cm-1)*100*trend, not abs(2*(dm/cm-1)). Zero cumulative range gives zero force; fast and slow EMAs seed from the first force, while the oscillator and signal seed at zero, with composite warm-up.

**Validation:** Equal H+L+C, trend reversal resetting cumulative range, zero range, and both output fields under explicit stabilization.

**Bend interface:** Implemented under [the F32 contract](volume-volatility.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kvo/kvo.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kvo/kvo.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KVO.c).

### `MARKETFI` — Market Facilitation Index

**Interface:** inputs `High`, `Low`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed HLV inputs.

**Bend implementation:** Emit (high-low)/volume per bar; no temporal state or window is needed. Name it Bill Williams Market Facilitation Index in the API to distinguish it from MFI money flow.

**Blockers and special considerations:** Use an exact zero-volume test: zero volume returns zero, while tiny nonzero volume must still divide. Valid finite inputs can overflow the F32 quotient.

**Validation:** Zero and tiny positive volume, normal bars and zero range; distinguish from MFI.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/marketfi/marketfi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/marketfi/marketfi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MARKETFI.c).

### `NVI` — Negative Volume Index

**Interface:** inputs `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** previous close-volume, finite-value classification, cumulative index.

**Bend implementation:** Seed the index at 1000. Only when volume falls, update it by index*(close-previousClose)/previousClose; otherwise carry it. Retain the previous close and volume on every bar. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Equal volume does not update. Zero previous close carries the index. The pinned implementation keeps the last finite index when a candidate overflows; reproducing that policy needs numeric finite classification. The anchor determines the entire level.

**Validation:** Equal/qualifying/opposite volume changes, zero previous close, explicit reset and an overflowing candidate.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/nvi/nvi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/nvi/nvi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_NVI.c).

### `OBV` — On Balance Volume

**Interface:** inputs `inReal`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** previous price, cumulative state, typed price-volume inputs.

**Bend implementation:** Seed OBV with the first bar volume, then add current volume on a price rise, subtract on a fall and carry on an equal price. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Upstream accepts a generic real-price input, not necessarily close. Do not seed zero accidentally. Very large cumulative volume is especially sensitive to F32 spacing and cancellation.

**Validation:** First-bar volume, equal prices with changing volume, rise/fall sequence and a large accumulated baseline.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/obv/obv.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/obv/obv.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_OBV.c).

### `PVI` — Positive Volume Index

**Interface:** inputs `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** previous close-volume, finite-value classification, cumulative index.

**Bend implementation:** Seed the index at 1000. Only when volume rises, update it by index*(close-previousClose)/previousClose; otherwise carry it. Retain the previous close and volume on every bar. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Equal volume does not update. Zero previous close carries the index. The pinned implementation keeps the last finite index when a candidate overflows; reproducing that policy needs numeric finite classification. The anchor determines the entire level.

**Validation:** Equal/qualifying/opposite volume changes, zero previous close, explicit reset and an overflowing candidate.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pvi/pvi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pvi/pvi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PVI.c).

### `PVO` — Percentage Volume Oscillator

**Interface:** inputs `Volume`; outputs `outReal` (real).

**Parameters:** Fast Period = `12` (integer, 2..100000); Slow Period = `26` (integer, 2..100000); MA Type = `1` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** MA dispatch, volume series, paired MA alignment.

**Bend implementation:** Apply one selected MA type to fast and slow volume streams and emit 100*(fast-slow)/slow, or zero if the slow average is inside the reference near-zero band. Reuse the oscillator machinery of PPO with volume input. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Default MA is EMA, unlike some older oscillator assumptions. Swap fast/slow periods if reversed. MAMA ignores period, so selecting it makes the two averages identical; dispatch and warm-up must match the selected type. Pinned source uses TA_IS_ZERO (strictly between -1e-14 and 1e-14), not exact zero; an F32-specific relative rule would be a deliberate compatibility difference.

**Validation:** Default EMA, reversed periods, zero volume and MAMA mode once implemented.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pvo/pvo.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pvo/pvo.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PVO.c).

### `PVT` — Price Volume Trend

**Interface:** inputs `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** previous close, cumulative state, typed close-volume inputs.

**Bend implementation:** Seed zero at the anchor and accumulate volume*(close-previousClose)/previousClose at each subsequent bar. Use fractional returns, not a percent multiplier. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Zero previous close contributes nothing. The absolute level depends on where the accumulation starts. Long sums and products need F32 overflow/drift tests.

**Validation:** Known fractional price changes, zero previous close, equal close and restarting at a later bar.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pvt/pvt.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/pvt/pvt.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PVT.c).

### `RVOL` — Relative Volume

**Interface:** inputs `Volume`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** previous-window rolling mean, typed volume input, numeric domain policy.

**Bend implementation:** Compute current volume divided by the mean of the previous period volumes, then insert current volume into the window. This order excludes the current bar from its baseline.

**Blockers and special considerations:** Lookback is period, requiring period+1 observations. The pinned raw division deliberately emits Inf for positive current volume over zero baseline, and NaN for 0/0; do not replace these with zero or warm-up None.

**Validation:** Prior volumes [1,1] then 10 yields 10 for period2; test all-zero baseline and a nonzero bar following it.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rvol/rvol.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rvol/rvol.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_RVOL.c).

### `VWAP` — Volume Weighted Average Price

**Interface:** inputs `High`, `Low`, `Close`, `Volume`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed HLCV inputs, cumulative weighted sums, finite-value classification.

**Bend implementation:** Keep cumulative sum(typicalPrice*volume) and sum(volume), returning their ratio once cumulative volume is positive. Explicit state initialization/reset supplies the anchor; no automatic session/calendar behavior is implied.

**Blockers and special considerations:** Pinned batch code skips nonfinite typical-price or volume bars and repeats the prior result, initially zero; stream entry points reject nonfinite bars. Finite products can still overflow. Choose and document one Bend invalid-input contract or separate batch-compatibility behavior.

**Validation:** Leading zero volume, a later zero-volume bar, a nonfinite bar followed by recovery, anchor reset and large finite products.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vwap/vwap.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/vwap/vwap.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_VWAP.c).

## Volatility Indicators (11)

### `ADR` — Average Day Range

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** typed high-low inputs, rolling mean.

**Bend implementation:** Feed each high-low range into the existing SMA transition, with a period-specific facade and reference fixtures. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** It is the mean of individual ranges, not the highest-high minus lowest-low channel width. Bars have no calendar meaning unless the caller supplies daily bars. Upstream does not reject high below low.

**Validation:** Trending bars where mean range differs from channel width; flat/inverted ranges and first complete window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adr/adr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/adr/adr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ADR.c).

### `ATR` — Average True Range

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** true range, Wilder smoothing, stabilization settings.

**Bend implementation:** Feed true ranges into a Wilder smoother with an initial mean of period true ranges, followed by (previous*(period-1)+TR)/period. Keep prior close inside indicator state. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Without extra stabilization, period TR changes require period+1 price bars. Current TA-Lib adds configurable/auto warm-up; period1 reduces to true range through beta=0/alpha=1. F32 recurrence/order can diverge from a double/FMA reference.

**Validation:** Gap series, first seed at the correct price index, period1 and explicit zero versus auto stabilization.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/atr/atr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/atr/atr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ATR.c).

### `BBW` — Bollinger BandWidth

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..100000); Deviations up = `2` (double, -3e+37..3e+37); Deviations down = `2` (double, -3e+37..3e+37); MA Type = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** Bollinger bands, MA dispatch, stable variance.

**Bend implementation:** Consume the three BBANDS outputs and compute 100*(upper-lower)/middle in that order. Reuse one band state rather than recomputing mean/variance independently. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Zero middle returns zero; near-zero middle can produce a huge result. Percent scaling matters. Non-SMA middle still uses population deviation about the simple mean; strict band-composition rounding needs explicit policy.

**Validation:** Constant prices, asymmetric deviation multipliers, zero middle and alternate MA middle.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/bbw/bbw.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/bbw/bbw.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_BBW.c).

### `CVI` — Chaikin's Volatility

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 2..100000); ROC Period = `10` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** EMA primitives, lag buffer, typed high-low inputs.

**Bend implementation:** EMA-smooth high-low spreads, retain the smoothed value ROC-period bars ago, then emit 100*(current-lagged)/lagged. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Averaging and ROC periods are independent. Lagged zero produces zero; use the source EMA seed and inherited stabilization before counting the ROC lag.

**Validation:** Different EMA/ROC periods, a spread step change and a fully flat zero-spread series.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cvi/cvi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cvi/cvi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CVI.c).

### `MASSI` — Mass Index

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Fast Period = `9` (integer, 2..100000); Slow Period = `25` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** two EMA stages, rolling sum, typed high-low inputs.

**Bend implementation:** Apply two sequential same-period EMAs to high-low spread, divide first EMA by second, then sum the ratio over the slow period. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Fast and slow periods are roles and are not swapped. A zero second EMA maps the ratio to one, so fully flat inputs yield the summation period. Both EMA stages contribute to seed/warm-up.

**Validation:** Flat range must yield slowPeriod, unequal/reversed-role periods and a range spike propagating through both stages.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/massi/massi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/massi/massi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MASSI.c).

### `NATR` — Normalized Average True Range

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** ATR, typed HLC inputs.

**Bend implementation:** For periods above one, compute the Wilder ATR recurrence and emit 100*ATR/currentClose, or zero for zero close. Retain a NATR-specific stabilization setting rather than blindly aliasing public ATR. For period1, preserve the source exception: emit unnormalized true range. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Pinned NATR period1 is an exception to its percentage formula, even when close is zero. For larger periods normalization happens after smoothing, not before. Its unstable-period identifier is NATR rather than ATR; a reusable recurrence must not force the wrong lookback settings.

**Validation:** Period1 with TR=5 and close=100 must emit5, and zero close still emits TR; test larger-period zero close and differing ATR/NATR unstable settings.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/natr/natr.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/natr/natr.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_NATR.c).

### `PERCENTB` — Bollinger Bands %B

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..100000); Deviations up = `2` (double, -3e+37..3e+37); Deviations down = `2` (double, -3e+37..3e+37); MA Type = `0` (MA selector; see common enum notes).

**Readiness:** Existing. **Dependencies:** Bollinger bands, MA dispatch, stable variance.

**Bend implementation:** Use the current input and BBANDS endpoints to emit (price-lower)/(upper-lower), returning 0.5 for equal bands. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Output is a ratio, not percent, and may be outside [0,1]. With asymmetric deviations the middle is not generally 0.5. Preserve computation from actual rounded band endpoints if comparing to pinned TA-Lib.

**Validation:** Equal bands, inputs outside the bands, asymmetric multipliers and exact middle-band input.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/percentb/percentb.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/percentb/percentb.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PERCENTB.c).

### `ROGERSSATCHELL` — Rogers-Satchell Volatility

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** Time Period = `10` (integer, 1..100000); Annualization = `252` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC inputs, log and sqrt, stable rolling sum.

**Bend implementation:** Per bar compute log(H/O)*log(H/C)+log(L/O)*log(L/C); maintain a rolling term sum and emit sqrt(annualization)*sqrt(sum/period) when the sum is positive.

**Blockers and special considerations:** A bar with any nonpositive price contributes zero but still counts in the window. Clamp a nonpositive window sum to zero. Pinned code periodically rebuilds and reanchors after collapse; F32 log ratios near one lose precision.

**Validation:** Flat bars, a nonpositive-price bar, outlier expiration, annualization=1 and scaled annualization.

**Bend interface:** Implemented under [the F32 contract](volume-volatility.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rogerssatchell/rogerssatchell.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rogerssatchell/rogerssatchell.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ROGERSSATCHELL.c).

### `RVI` — Relative Volatility Index

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000); StdDev Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** stable standard deviation, Wilder smoothing, previous price.

**Bend implementation:** Compute rolling population standard deviation; route it to up/down buckets by comparison with previous price, Wilder-smooth each bucket, and return 100*up/(up+down).

**Blockers and special considerations:** This is Donald Dorsey Relative Volatility Index, not Relative Vigor Index. Ties feed neither bucket; a zero total yields 50. Standard-deviation and smoothing periods are independent and warm-ups compose.

**Validation:** All-flat input gives 50; compare repeated-price ties, strictly rising/falling paths and different deviation/smoothing periods.

**Bend interface:** Implemented under [the F32 contract](volume-volatility.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rvi/rvi.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rvi/rvi.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_RVI.c).

### `RVIR` — Relative Volatility Index, refined high/low form

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 1..100000); StdDev Period = `10` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** RVI, typed high-low inputs, paired state.

**Bend implementation:** Maintain an RVI on highs and another on lows with the same configuration; output their arithmetic mean when both are ready.

**Blockers and special considerations:** This is the 1995 revised Relative Volatility Index. It is not an RVI of the midpoint, and both components must share aligned readiness and settings.

**Validation:** A bar sequence with diverging high/low movements; compare against separately computed RVI legs and flat input.

**Bend interface:** Implemented under [the F32 contract](volume-volatility.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rvir/rvir.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/rvir/rvir.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_RVIR.c).

### `TRANGE` — True Range

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** previous close, typed HLC inputs, numeric abs and max.

**Bend implementation:** Store previous close and emit max(high-low,abs(high-previousClose),abs(low-previousClose)). Emit no value for the first bar. Current F32 contract: [implemented interface and limits](volume-volatility.md).

**Blockers and special considerations:** Do not substitute high-low on the first bar; the pinned function requires prior close. Keep raw bar ordering/validation explicit and preserve max/abs operation order for reference work.

**Validation:** A price gap beyond the high-low span, a flat current bar with a gap, and first-bar alignment.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/trange/trange.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/trange/trange.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TRANGE.c).

## Statistic Functions (13)

### `BETA` — Beta

**Interface:** inputs `inReal0`, `inReal1`; outputs `outReal` (real).

**Parameters:** Time Period = `5` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** paired price inputs, return transform, stable covariance.

**Bend implementation:** Convert both price series to fractional returns, maintain centered return moments, and emit covariance(return0,return1)/variance(return0). Keep the input ordering explicit in the facade.

**Blockers and special considerations:** The first input is the denominator/independent series; reversing inputs changes beta. period returns require period+1 prices. A zero prior price produces a zero return; pinned degeneracy checks are relative to moment scale.

**Validation:** Return1=2*return0 yields beta2; reverse inputs, zero prior price, constant returns and tiny return scales.

**Bend interface:** Implemented under [the F32 contract](overlap-statistics.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/beta/beta.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/beta/beta.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_BETA.c).

### `CORREL` — Pearson's Correlation Coefficient (r)

**Interface:** inputs `inReal0`, `inReal1`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 1..100000).

**Readiness:** Existing. **Dependencies:** paired inputs, stable covariance, centered rolling moments.

**Bend implementation:** Maintain paired centered sums and cross-products over the same window, periodically rebuilding; normalize covariance by the product of standard deviations.

**Blockers and special considerations:** The source outputs zero for degenerate windows and clamps finite correlations to [-1,1]. It uses scale-relative variance checks and guards the variance product against underflow. F32 requires scaled formulas/threshold validation, not copied double epsilons.

**Validation:** Perfect positive/negative correlation, either series constant, tiny-unit rescaling and large outlier expiration.

**Bend interface:** Implemented under [the F32 contract](overlap-statistics.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/correl/correl.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/correl/correl.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CORREL.c).

### `KURTOSIS` — Rolling Excess Kurtosis

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 4..10000).

**Readiness:** Existing. **Dependencies:** centered rolling moments through fourth order, owned ring, undefined numeric result.

**Bend implementation:** Maintain centered first-through-fourth moments with rebuilds after collapse/outlier departure, then apply the sample-adjusted Fisher excess-kurtosis estimator G2. Keep the finite-sample factors in configuration.

**Blockers and special considerations:** Minimum period is4. This is not biased population excess kurtosis; constant windows return NaN rather than zero. Fourth powers overflow F32 quickly, so use scaled/recentered calculations and an explicit undefined-output contract.

**Validation:** Reject period3, compare G2 on a known window, constant data returns undefined/NaN, and test translation/scaling plus outlier expiration.

**Bend interface:** Implemented under [the F32 contract](overlap-statistics.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kurtosis/kurtosis.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/kurtosis/kurtosis.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_KURTOSIS.c).

### `LINEARREG` — Linear Regression

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling linear regression.

**Bend implementation:** Fit y=b+m*x with chronological x=0..period-1 and emit the fitted value at x=period-1. Share period constants, sum(y), weighted sum(y), and periodic/collapse rebuilding across the regression family. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** A fit endpoint is not a moving average of predictions. A rising [1,2,3] window should output3. Pinned C uses reverse weights plus a reversed denominator; preserve the resulting chronological orientation.

**Validation:** A known straight line, constant data, period2, large-offset small slope and an expiring outlier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg/linearreg.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg/linearreg.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_LINEARREG.c).

### `LINEARREG_ANGLE` — Linear Regression Angle

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling linear regression.

**Bend implementation:** Fit y=b+m*x with chronological x=0..period-1 and emit atan(slope)*180/pi. Share period constants, sum(y), weighted sum(y), and periodic/collapse rebuilding across the regression family. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Angles are degrees and depend on price scale; they are not scale-invariant trend strength. Requires atan and a precision-appropriate pi constant. Pinned C uses reverse weights plus a reversed denominator; preserve the resulting chronological orientation.

**Validation:** A known straight line, constant data, period2, large-offset small slope and an expiring outlier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg_angle/linearreg_angle.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg_angle/linearreg_angle.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_LINEARREG_ANGLE.c).

### `LINEARREG_INTERCEPT` — Linear Regression Intercept

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling linear regression.

**Bend implementation:** Fit y=b+m*x with chronological x=0..period-1 and emit the fitted intercept at x=0. Share period constants, sum(y), weighted sum(y), and periodic/collapse rebuilding across the regression family. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Use chronological coordinates with the oldest sample at x=0; the intercept of [1,2,3] is1, not the current endpoint3. Read the C weighting/sign together rather than misreading a bars-ago formula. Pinned C uses reverse weights plus a reversed denominator; preserve the resulting chronological orientation.

**Validation:** A known straight line, constant data, period2, large-offset small slope and an expiring outlier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg_intercept/linearreg_intercept.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg_intercept/linearreg_intercept.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_LINEARREG_INTERCEPT.c).

### `LINEARREG_SLOPE` — Linear Regression Slope

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling linear regression.

**Bend implementation:** Fit y=b+m*x with chronological x=0..period-1 and emit the fitted slope per bar. Share period constants, sum(y), weighted sum(y), and periodic/collapse rebuilding across the regression family. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** A rising arithmetic sequence must give a positive slope. Keep integer coordinate constants separate from prices; intermediate U32 products for n²/n³ can overflow. Pinned C uses reverse weights plus a reversed denominator; preserve the resulting chronological orientation.

**Validation:** A known straight line, constant data, period2, large-offset small slope and an expiring outlier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg_slope/linearreg_slope.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/linearreg_slope/linearreg_slope.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_LINEARREG_SLOPE.c).

### `MEDIAN` — Rolling Median

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 2..10000).

**Readiness:** Existing. **Dependencies:** owned ring, sorted window, ordered numeric capability.

**Bend implementation:** Maintain an owned chronological ring plus an ordered multiset/window; emit the middle element for odd windows and the average of the two central elements for even windows. A copy-and-sort baseline is simpler but more expensive. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Finite inputs are required for ordering. Even-period median differs from nearest-rank PERCENTILE at50. Handle duplicate deletion exactly once, and avoid overflow when averaging central values.

**Validation:** [1,2,3,4] gives2.5; odd window, repeated values, and a departing repeated middle value.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/median/median.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/median/median.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MEDIAN.c).

### `PERCENTILE` — Percentile (nearest rank)

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `100` (integer, 2..10000); Percentile = `50` (double, 0..100).

**Readiness:** Existing. **Dependencies:** owned ring, sorted window, rank calculation.

**Bend implementation:** Sort or maintain the current period samples, choose the one-based rank ceil(percentile*period/100) clamped to1..period, and emit that observed value. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** This is nearest rank, not interpolated quantile. Parameter/rank arithmetic is configuration work; avoid computing large integer ranks through F32. Ordered structures require finite inputs and careful duplicate removal.

**Validation:** Endpoints0/100, 50th percentile of [1,2,3,4] gives2, short windows and duplicate ranks.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/percentile/percentile.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/percentile/percentile.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PERCENTILE.c).

### `PERCENTRANK` — Percent Rank

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `100` (integer, 2..10000).

**Readiness:** Existing. **Dependencies:** previous-window ring, ordered comparisons.

**Bend implementation:** Compare the current sample with each of the previous period samples, count strictly smaller values, emit 100*count/period, then insert the current sample. An ordered count structure can optimize later. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Current sample is excluded from the baseline: lookback is period. Ties, including signed-zero ties, do not count; a constant stream returns0. NaN silently breaks ranking upstream, so finite-input policy is important.

**Validation:** Constant data gives0, a new maximum gives100, duplicate ties and the first available output.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/percentrank/percentrank.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/percentrank/percentrank.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_PERCENTRANK.c).

### `STDDEV` — Standard Deviation

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `5` (integer, 2..100000); Deviations = `1` (double, -3e+37..3e+37).

**Readiness:** Existing. **Dependencies:** stable variance, sqrt.

**Bend implementation:** Reuse the variance engine and emit sqrt(populationVariance)*deviations. Keep the multiplier outside the root as the source does. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** This is population deviation, not sample deviation. Negative Deviations is allowed by metadata and changes output sign. Only small numerical negative residue should be handled by the variance engine; do not mask arbitrary invalid inputs.

**Validation:** Reject period1; constant input at a valid period, a known population variance, negative multiplier and large-baseline tiny-spread windows.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stddev/stddev.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/stddev/stddev.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_STDDEV.c).

### `TSF` — Time Series Forecast

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling linear regression.

**Bend implementation:** Fit y=b+m*x with chronological x=0..period-1 and emit the fitted value at x=period. Share period constants, sum(y), weighted sum(y), and periodic/collapse rebuilding across the regression family. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** This is a one-bar-ahead forecast emitted on the current bar, not a future observed value or permission to shift information backward. A [1,2,3] window predicts4. Pinned C uses reverse weights plus a reversed denominator; preserve the resulting chronological orientation.

**Validation:** A known straight line, constant data, period2, large-offset small slope and an expiring outlier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tsf/tsf.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tsf/tsf.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TSF.c).

### `VAR` — Variance

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `5` (integer, 1..100000); Deviations = `1` (double, -3e+37..3e+37).

**Readiness:** Existing. **Dependencies:** stable rolling moments, owned ring, rebuild policy.

**Bend implementation:** Build a centered rolling population-variance engine using a nearby shift, first/second centered sums and periodic/collapse-triggered rebuilds. The pinned source already uses these defenses; avoid naive E[x²]-E[x]² in F32.

**Blockers and special considerations:** Divide by period, not period-1; the exposed Deviations parameter is accepted but ignored. F32 rebase thresholds need their own error analysis, so matching the formula is not numerical or bitwise parity.

**Validation:** Large baseline with tiny spread, exact constant/period1 windows, an outlier leaving, and differing Deviations with identical results.

**Bend interface:** Implemented under [the F32 contract](overlap-statistics.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/var/var.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/var/var.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_VAR.c).

## Price Transform (6)

### `AVGDEV` — Average Deviation

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `14` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling mean, window scan.

**Bend implementation:** Keep the current window and its mean, then compute the mean absolute distance of each sample from that current mean. Start with a straightforward O(period) scan per output. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Updating the mean changes every absolute distance, so a rolling sum of old absolute deviations is incorrect. It is mean absolute deviation, not standard deviation or median absolute deviation.

**Validation:** An asymmetric window with a known mean/deviation, constant data and a departing outlier.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/avgdev/avgdev.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/avgdev/avgdev.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AVGDEV.c).

### `AVGPRICE` — Average Price

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed bar inputs, numeric capabilities.

**Bend implementation:** Map each bar to (high + low + close + open) / 4 using template arithmetic and constants constructed without an intermediate F32 conversion in the generic core.

**Blockers and special considerations:** Four-price input requires an OHLC record. Preserve a documented summation order; the HA close formula can round differently even though it is algebraically equal. No rolling warm-up or temporal state is needed.

**Validation:** One hand-calculated bar, equal OHLC prices and large finite inputs; confirm batch/stream equivalence.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/avgprice/avgprice.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/avgprice/avgprice.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_AVGPRICE.c).

### `HA` — Heikin-Ashi Candles

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outHAOpen` (real), `outHAHigh` (real), `outHALow` (real), `outHAClose` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC inputs, multi-output records, recursive warm-up.

**Bend implementation:** Emit a synthetic OHLC record. HA close averages raw OHLC; HA open averages the previous synthetic open/close; high/low enclose raw extremes and the synthetic body. Seed from the first raw open/close midpoint. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** It is recursive and has configured stabilization, not an independently computable per-bar transform. Synthetic candles are not executable market prices. Match the pinned initialization and arithmetic order, and retain the unshifted time index.

**Validation:** One-bar initialization, a gap, equal prices, and long-prefix versus restarted calculations under explicit warm-up settings.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ha/ha.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ha/ha.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HA.c).

### `MEDPRICE` — Median Price

**Interface:** inputs `High`, `Low`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed bar inputs, numeric capabilities.

**Bend implementation:** Map each bar to (high + low) / 2 using template arithmetic and constants constructed without an intermediate F32 conversion in the generic core.

**Blockers and special considerations:** This is a per-bar midpoint, not a rolling median. A midpoint expression that avoids overflow may intentionally differ from the upstream arithmetic. No rolling warm-up or temporal state is needed.

**Validation:** One hand-calculated bar, equal OHLC prices and large finite inputs; confirm batch/stream equivalence.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/medprice/medprice.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/medprice/medprice.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MEDPRICE.c).

### `TYPPRICE` — Typical Price

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed bar inputs, numeric capabilities.

**Bend implementation:** Map each bar to (high + low + close) / 3 using template arithmetic and constants constructed without an intermediate F32 conversion in the generic core.

**Blockers and special considerations:** Use this exact shared expression in volume composites, so VWAP and MFI do not silently use a different typical-price convention. No rolling warm-up or temporal state is needed.

**Validation:** One hand-calculated bar, equal OHLC prices and large finite inputs; confirm batch/stream equivalence.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/typprice/typprice.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/typprice/typprice.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TYPPRICE.c).

### `WCLPRICE` — Weighted Close Price

**Interface:** inputs `High`, `Low`, `Close`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed bar inputs, numeric capabilities.

**Bend implementation:** Map each bar to (high + low + 2 * close) / 4 using template arithmetic and constants constructed without an intermediate F32 conversion in the generic core.

**Blockers and special considerations:** The close has double weight. Scaling each operand first can avoid overflow but changes rounding; choose and test the operation order. No rolling warm-up or temporal state is needed.

**Validation:** One hand-calculated bar, equal OHLC prices and large finite inputs; confirm batch/stream equivalence.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wclprice/wclprice.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/wclprice/wclprice.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_WCLPRICE.c).

## Cycle Indicators (8)

### `HT_DCPERIOD` — Hilbert Transform - Dominant Cycle Period

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** shared Hilbert engine, four-bar WMA, atan numeric operation.

**Bend implementation:** Build a reusable Hilbert state with separate odd/even delay taps, detrender, in-phase/quadrature estimates and smoothed real/imaginary products. Convert the phase change into a cycle-period estimate, apply the source change-rate and 6..50 clamps, then emit the smoothed period.

**Blockers and special considerations:** The fixed lookback component is 32, plus source instability settings; do not assume the historical fixed number is the full default warm-up. This is a specific Ehlers estimator, not a generic FFT. Preserve tap ordering, degree/radian conversions and zero-product guards. F32 and transcendental rounding can affect the clamped period.

**Validation:** Sine waves near periods 6 and 50; a constant series; even/odd starting indices; first valid output with instability options.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_dcperiod/ht_dcperiod.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_dcperiod/ht_dcperiod.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HT_DCPERIOD.c).

### `HT_DCPHASE` — Hilbert Transform - Dominant Cycle Phase

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** shared Hilbert engine, 50-value smoothed-price ring, sin/cos/atan numeric operations.

**Bend implementation:** Extend the shared Hilbert period state with a short smoothed-price ring. Project the most recent rounded dominant-cycle window onto sine and cosine components, then apply the source phase corrections and wrap convention to produce a phase in degrees.

**Blockers and special considerations:** Its fixed lookback is 63 plus instability suppression. Replacing the source atan-ratio and explicit quadrant adjustments with an unexamined atan2 changes edge behavior. Preserve rounded cycle-length selection, zero-imaginary handling and the wrap above 315 degrees. F32 near a rounding threshold changes which historical bars enter the projection.

**Validation:** A phase-shifted sine wave through wrap boundaries; a constant input; cycles whose inferred length lies near an integer rounding boundary.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_dcphase/ht_dcphase.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_dcphase/ht_dcphase.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HT_DCPHASE.c).

### `HT_PHASOR` — Hilbert Transform - Phasor Components

**Interface:** inputs `inReal`; outputs `outInPhase` (real), `outQuadrature` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** shared Hilbert engine, multi-output records.

**Bend implementation:** Expose the shared Hilbert estimator's delayed in-phase component and current quadrature component as one record. Keep the full period-estimation state, because its adaptive period factor feeds back into the Hilbert taps even when only the phasor outputs are requested.

**Blockers and special considerations:** The fixed lookback component is 32 plus configured/automatic instability. Output is not the later smoothed I2/Q2 pair: the source emits its delayed I1 and Q1 values. Generalize the batch helper for a record output and test ordering explicitly. Different tap startup or parity changes the signal even if the names look correct.

**Validation:** Known sine-wave phase relation; constant input; odd/even startup paths; swap-detection checks on the two output fields.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_phasor/ht_phasor.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_phasor/ht_phasor.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HT_PHASOR.c).

### `HT_SINE` — Hilbert Transform - SineWave

**Interface:** inputs `inReal`; outputs `outSine` (real), `outLeadSine` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** Hilbert phase projection, sin numeric operation, multi-output records.

**Bend implementation:** Reuse the dominant-cycle phase projection, then emit sin(phase) and sin(phase+45 degrees) together. Both outputs should be computed from the same phase state so warm-up and phase corrections remain identical.

**Blockers and special considerations:** The second output is a fixed 45-degree phase lead, not a future price observation. Source warm-up is 63 plus instability settings. Keep degree/radian conversion explicit and preserve the phase estimator's wrap and zero guards. F32 phase error can move crossover bars, so compare events as well as numeric amplitudes.

**Validation:** Phase-wrap and lead-sine crossovers on a synthetic cycle; flat input; matching first valid indices for both fields.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_sine/ht_sine.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_sine/ht_sine.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HT_SINE.c).

### `HT_TRENDMODE` — Hilbert Transform - Trend vs Cycle Mode

**Interface:** inputs `inReal`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** Hilbert phase and trendline engines, integer/enum output, mode-switch state.

**Bend implementation:** Combine phase/sine-crossing state, elapsed trend days, the smoothed dominant period and the adaptive trendline. Reproduce the ordered source rules to emit the cycle/trend classification, represented as a typed enum or an integer compatibility result.

**Blockers and special considerations:** This is not simply a price-above-trendline Boolean. A sine crossing, phase-rate band and minimum trend age can force cycle mode, while a 1.5% displacement rule can override them. Fixed lookback is 63 plus instability suppression. F32 comparisons can change categorical outputs; scalar floating tolerances alone are insufficient validation.

**Validation:** Pure cycles, strong trends and flat prices; equality at crossing thresholds; precedence where the displacement override and a cycle condition both apply.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_trendmode/ht_trendmode.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ht_trendmode/ht_trendmode.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_HT_TRENDMODE.c).

### `SWAK_2PHP` — Swiss Army Knife - Two-Pole High-Pass Filter

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 2..10000).

**Readiness:** Existing. **Dependencies:** two-pole filter engine, sin/sqrt numeric operations, coefficient validation.

**Bend implementation:** Precompute the Ehlers two-pole coefficients and keep two previous inputs plus two previous outputs. Advance a second-order high-pass recurrence driven by x[t]-2*x[t-1]+x[t-2]. Reuse a typed filter state with distinct coefficient factories for the SWAK family.

**Blockers and special considerations:** The source seeds previous inputs from the first price and outputs at zero, then suppresses an automatic/configured instability count. F32 cancellation in the second difference and coefficient computation is significant for slowly changing prices or long periods. Use the source's stable coefficient expressions and avoid claiming its double/FMA settling behavior for F32.

**Validation:** Constant input yielding zero response; impulse and step responses; large periods; native/JS comparison through the warm-up boundary.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_2php/swak_2php.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_2php/swak_2php.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SWAK_2PHP.c).

### `SWAK_BP` — Swiss Army Knife - Band-Pass Filter

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 5..2000); Delta = `0.1` (double, 0.05..0.5).

**Readiness:** Existing. **Dependencies:** two-pole filter engine, sin/cos numeric operations, bandwidth coefficient configuration.

**Bend implementation:** Compute period- and delta-dependent band-pass coefficients once, then update a two-output-delay recurrence driven by x[t]-x[t-2]. A common filter core can share state mechanics with the other SWAK variants while keeping each coefficient factory distinct.

**Blockers and special considerations:** Delta controls bandwidth, and the source limits its range and the period separately from other SWAK filters. Its lookback varies with settling characteristics, not a simple period window. The expression (1-sin(t))/cos(t) avoids a less stable equivalent coefficient form. F32 poles close to one need long-run stability tests and a precision-specific warm-up policy.

**Validation:** On-band and off-band sine waves; minimum/maximum delta; constant input; long-period narrow-band impulse decay.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_bp/swak_bp.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_bp/swak_bp.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SWAK_BP.c).

### `SWAK_HP` — Swiss Army Knife - High-Pass Filter

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `20` (integer, 5..100000).

**Readiness:** Existing. **Dependencies:** one-pole filter engine, sin/cos numeric operations.

**Bend implementation:** Compute the high-pass coefficient at initialization and retain the previous input and output. Each step combines the latest first difference with the decayed previous output, giving constant-size streaming state.

**Blockers and special considerations:** The source seeds its previous input from the first price and output at zero, with a period-derived automatic/configured instability count. Its stable trigonometric coefficient form should be retained instead of an algebraically convenient cancellation-prone version. Large periods and small changes around large F32 baselines can collapse the driving difference to zero.

**Validation:** Constant prices; step response and decay; smallest allowed period; tiny changes around a large baseline.

**Bend interface:** Implemented under [the F32 contract](cycles-filters.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_hp/swak_hp.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/swak_hp/swak_hp.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SWAK_HP.c).

## Pattern Recognition (61)

All 61 pattern functions are implementable in pure Bend after shared foundations: immutable OHLC bars; generic input/output traversal; a nonnegative magnitude plus direction or equivalent signed result; candle color defined by close>=open; real body, upper/lower wick, body-gap and full-range-gap helpers; and lag-aligned configurable candle settings. Each setting carries range kind (real body, high-low or combined shadows), averaging period and factor. A positive averaging period uses preceding ranges excluding the evaluated bar; period zero uses that bar’s own range, and combined-shadow averages are divided by2. Bind numeric operations as ~ parameters, keep settings as ordinary initialization data, and freeze them in each state. None is warmup; a normal zero means no recognized pattern. Lookbacks in entries are upstream preceding-bar counts, not simply geometric pattern lengths, and must be re-evaluated for custom settings. TA-Lib global settings should be an immutable per-instance configuration, not mutable globals. F32 changes and the upstream fused-double arithmetic at some penetration boundaries can change a discrete pattern classification; test exact and neighboring thresholds against a pinned oracle rather than promise universal parity. No foreign implementation is needed, but the existing scalar output helper must be generalized. Most textbook trend context is not separately computed by the source: port its actual tests and document interpretive limits. HIKKAKE variants additionally need causal pending-candidate/confirmation state.

Source for shared settings and geometric helpers: [utility macros](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_utility.h) and [candle defaults/settings](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_common/ta_global.c). Each lookback below is a count of preceding bars; the first possible output index must include that history.

### `CDL2CROWS` — Two Crows

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong.

**Bend implementation:** Keep three bars. Recognize a long rising first body, a falling second body entirely gapped above it, then a falling third bar opening strictly inside the second body and closing strictly inside the first. Emit a bearish magnitude100 result. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The third body need not engulf the second, unlike UPSIDEGAP2CROWS. BodyLong is evaluated at the first bar using its own preceding range window. Source implements this geometry without a separate market-trend filter. Upstream lookback is `BodyLong + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a valid three-bar setup, then move the final close exactly onto either first-body endpoint and expect no match.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl2crows/cdl2crows.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl2crows/cdl2crows.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL2CROWS.c).

### `CDL3BLACKCROWS` — Three Black Crows

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: ShadowVeryShort.

**Bend implementation:** Hold the three falling crows plus their preceding bar. Require that preceding bar to rise, all three crows to fall with descending closes, later opens inside prior bodies, and very short lower shadows. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** This recognizer actually reads four bars, including the earlier rising bar and its high. Preserve per-crow ShadowVeryShort thresholds; a generic three-black-bars predicate omits required conditions. Upstream lookback is `ShadowVeryShort + 3` preceding bars; setting names here mean their averaging periods.

**Validation:** Use a declining three-crow sequence preceded first by a rising bar and then a falling bar; only the source-qualified context should match.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3blackcrows/cdl3blackcrows.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3blackcrows/cdl3blackcrows.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL3BLACKCROWS.c).

### `CDL3INSIDE` — Three Inside Up/Down

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Use three retained bars and lagged BodyLong/BodyShort thresholds. Require a long first body, a strictly contained short second body, and a third bar of opposite color to the first closing beyond its open. Report the reversal direction. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The second candle has no separate color requirement. Strict body containment differs from HARAMI equality variants; the third close must pass, rather than merely touch, the first open. Successful output is plus or minus100. Upstream lookback is `max(BodyShort,BodyLong) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both directions, a same-color second candle, and second-body or final-close equality at the boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3inside/cdl3inside.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3inside/cdl3inside.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL3INSIDE.c).

### `CDL3LINESTRIKE` — Three-Line Strike

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Near.

**Bend implementation:** Keep four bars. The first three share a color and progressive closes, with later opens within Near-expanded prior bodies. The fourth reverses color, opens past the third close and crosses beyond the first open. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Emit the direction of the three-bar run, not the fourth candle: an upward run followed by a large falling strike returns plus100. Near uses separate historical thresholds for the first and second bars. Upstream lookback is `Near + 3` preceding bars; setting names here mean their averaging periods.

**Validation:** Test upward and downward runs and assert output sign, plus a fourth close equal to the first open that must fail.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3linestrike/cdl3linestrike.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3linestrike/cdl3linestrike.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL3LINESTRIKE.c).

### `CDL3OUTSIDE` — Three Outside Up/Down

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers.

**Bend implementation:** Recognize a strict opposite-color engulfing pair in the first two bars, then require a third close farther in the engulfing direction. A tiny state with two prior open/close pairs suffices; output the second bar color times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** No candle-setting averages are used. Source requires strict engulfing and reports only magnitude100, so composing the permissive magnitude80 ENGULFING result would be incorrect. Its lookback remains3 although the predicate reads three bars. Upstream lookback is `3` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a strict engulf plus confirming close, and a pair sharing one endpoint that ENGULFING accepts at80 but this function rejects.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3outside/cdl3outside.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3outside/cdl3outside.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL3OUTSIDE.c).

### `CDL3STARSINSOUTH` — Three Stars In The South

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort, ShadowLong, ShadowVeryShort.

**Bend implementation:** Keep three falling bars. Test a long first body with long lower wick, a smaller second body with a lower wick and constrained open/low, then a short near-marubozu strictly inside the second high-low range. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** BodyLong, BodyShort, ShadowLong and ShadowVeryShort have independent periods. All three candles are falling despite the positive result. The second low may equal the first low, while the final range containment is strict. Upstream lookback is `max(max(ShadowVeryShort,ShadowLong),max(BodyLong,BodyShort)) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Use a qualifying all-falling sequence and assert plus100; distinguish equality allowed at the second low from equality rejected at final containment.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3starsinsouth/cdl3starsinsouth.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3starsinsouth/cdl3starsinsouth.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL3STARSINSOUTH.c).

### `CDL3WHITESOLDIERS` — Three Advancing White Soldiers

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, Far, Near, ShadowVeryShort.

**Bend implementation:** Keep three rising bars with higher closes and very short upper wicks. Check that later opens lie within Near-expanded earlier bodies, later bodies are not Far-shorter than predecessors, and the final body exceeds the BodyShort threshold. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Use the source predicates rather than requiring three BodyLong classifications: the code specifically applies the final not-short test plus the relative-size checks. Return plus100; no separate longer-term trend qualification is implemented. Upstream lookback is `max(max(ShadowVeryShort,BodyShort),max(Far,Near)) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a valid sequence and independently violate the upper-shadow, Near-open and Far-shrinking boundaries.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3whitesoldiers/cdl3whitesoldiers.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdl3whitesoldiers/cdl3whitesoldiers.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDL3WHITESOLDIERS.c).

### `CDLABANDONEDBABY` — Abandoned Baby

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.3` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, BodyLong, BodyShort.

**Bend implementation:** Combine three bars: long first body, doji middle bar, and opposite-color nonshort final body penetrating the first by the configured fraction. Require complete high-low gaps on both sides of the middle doji. Return final direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Full-range gaps, including wicks, distinguish this from morning/evening doji stars. Penetration defaults to0.3 and is an explicit runtime option; preserve source validation and strict threshold tests. F32 and fused-double threshold arithmetic can disagree near equality. Upstream lookback is `max(max(BodyDoji,BodyLong),BodyShort) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test rising and falling reversals, a body-only gap with touching wicks, and closes exactly at or just past the penetration threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlabandonedbaby/cdlabandonedbaby.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlabandonedbaby/cdlabandonedbaby.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLABANDONEDBABY.c).

### `CDLADVANCEBLOCK` — Advance Block

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, Far, Near, ShadowLong, ShadowShort.

**Bend implementation:** Implement the three-rising-bar predicate using named subconditions for weakening bodies and/or upper wicks. Maintain lag-specific BodyLong, ShadowShort, ShadowLong, Near and Far averages, then combine the four alternative weakening branches. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** This is a disjunction of distinct source cases, not simply three shrinking bodies. The first bar must be long with a short upper wick; later opening and increasing-close constraints remain mandatory for every branch. Upstream lookback is `max(max(max(ShadowLong,ShadowShort),max(Far,Near)),BodyLong) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Provide one positive fixture per weakening branch and controls where shrinking bodies occur without the required rising-close/open geometry.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdladvanceblock/cdladvanceblock.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdladvanceblock/cdladvanceblock.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLADVANCEBLOCK.c).

### `CDLBELTHOLD` — Belt-hold

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, ShadowVeryShort.

**Bend implementation:** For each OHLC bar, compare its body with BodyLong and its opening-side wick with ShadowVeryShort. A rising body needs a tiny lower wick; a falling body needs a tiny upper wick. Return its body color times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Both length and wick tests are strict. The upper or lower wick on the closing side is unconstrained. No preceding-bar price comparison or independent market-trend filter should be added for TA-Lib compatibility. Upstream lookback is `max(BodyLong,ShadowVeryShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both directions, exact equality with the BodyLong threshold, and a long closing-side wick that should not invalidate the pattern.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlbelthold/cdlbelthold.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlbelthold/cdlbelthold.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLBELTHOLD.c).

### `CDLBREAKAWAY` — Breakaway

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong.

**Bend implementation:** Keep five bars. After a long first candle and same-color gapped second, require successive directional high/low movement in bars3 and4. The fifth reverses color and closes inside the original gap. Output its direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Bars1,2 and4 share a color; bar3 may have either color. Preserve strict gap-close limits and the initial BodyLong history. This predicate is substantially more specific than a five-day price reversal. Upstream lookback is `BodyLong + 4` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both mirror directions, allow the third candle to change color, and reject a fifth close exactly at a gap boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlbreakaway/cdlbreakaway.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlbreakaway/cdlbreakaway.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLBREAKAWAY.c).

### `CDLCLOSINGMARUBOZU` — Closing Marubozu

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, ShadowVeryShort.

**Bend implementation:** Classify a long body and require its closing-side wick to be very short: upper wick for a rising candle, lower wick for a falling candle. Reuse candle geometry and two independent setting averages. Emit body direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** An opening-side wick is permitted, unlike full MARUBOZU, and BELTHOLD checks the opposite end. Both body and closing-wick comparisons are strict. Missing foundations are the bar/output and settings infrastructure, not numeric operations. Upstream lookback is `max(BodyLong,ShadowVeryShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Construct a long bar with only an opening-side wick: closing marubozu should pass while full marubozu fails.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlclosingmarubozu/cdlclosingmarubozu.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlclosingmarubozu/cdlclosingmarubozu.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLCLOSINGMARUBOZU.c).

### `CDLCONCEALBABYSWALL` — Concealing Baby Swallow

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: ShadowVeryShort.

**Bend implementation:** Hold four falling bars. The first two have very short wicks; the third body gaps downward but has an upper wick reaching into the second body. The fourth high-low range strictly engulfs the third. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Only the bullish interpretation is implemented, even though all candles are falling. No BodyLong setting is consulted for the first two near-marubozu candles. The final containment includes wicks, not merely real bodies. Upstream lookback is `ShadowVeryShort + 3` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a qualifying four-falling-bar setup and a fourth body engulf that fails to engulf the third full high-low range.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlconcealbabyswall/cdlconcealbabyswall.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlconcealbabyswall/cdlconcealbabyswall.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLCONCEALBABYSWALL.c).

### `CDLCOUNTERATTACK` — Counterattack

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, Equal.

**Bend implementation:** Keep a pair of opposite-color long bodies and compare their closes within the Equal tolerance computed for the first bar. Maintain separate BodyLong windows for both evaluated bars. Output the second direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The close comparison is a configurable inclusive tolerance band, not floating-point equality. Do not add an opening-gap condition absent from the implementation. Evaluate both body-length tests before updating their historical totals. Upstream lookback is `max(Equal,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both directions and close differences exactly at, just inside and just outside the Equal band.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlcounterattack/cdlcounterattack.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlcounterattack/cdlcounterattack.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLCOUNTERATTACK.c).

### `CDLDARKCLOUDCOVER` — Dark Cloud Cover

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.5` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong.

**Bend implementation:** Test a long rising first body and a falling second candle that opens above the first high. Its close must stay above the first open but fall below the configurable penetration threshold inside the first body. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Penetration defaults to0.5; upstream accepts a nonnegative value up to its numeric maximum rather than capping it at1. The first-high opening gap uses wicks, and penetration is strict. Do not assume the second body has a BodyLong requirement. Upstream lookback is `BodyLong + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a close exactly at the penetration threshold, a body-gap-only opening below the prior high, and nondefault penetration.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldarkcloudcover/cdldarkcloudcover.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldarkcloudcover/cdldarkcloudcover.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLDARKCLOUDCOVER.c).

### `CDLDOJI` — Doji

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji.

**Bend implementation:** For each bar compute absolute close-minus-open and compare inclusively with the BodyDoji threshold. Reuse the historical candle-range average for the setting rather than treating only exact open-equals-close as a doji. Return100 on a match. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The result is a shape marker and always positive100; it is not a bullish forecast. BodyDoji may use high-low range with a factor, and a zero averaging period refers to the evaluated candle range itself. Upstream lookback is `BodyDoji` preceding bars; setting names here mean their averaging periods.

**Validation:** Test an exact doji, a small nonzero body exactly on the threshold, and a body just beyond it; repeat with a zero-period setting.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldoji/cdldoji.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldoji/cdldoji.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLDOJI.c).

### `CDLDOJISTAR` — Doji Star

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, BodyLong.

**Bend implementation:** Keep a long first body and a second doji whose body strictly gaps in the direction of the first candle. Use BodyLong at lag1 and BodyDoji at the current bar. Output the direction opposite the first bar times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Only real bodies must gap; wicks can overlap, unlike ABANDONEDBABY. No third confirmation candle is required, and no separate trend-state estimator is present. Return negative after a rising first candle and positive after a falling first candle. Upstream lookback is `max(BodyDoji,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a doji body gap with overlapping wicks, and a touching real-body endpoint that must fail.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldojistar/cdldojistar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldojistar/cdldojistar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLDOJISTAR.c).

### `CDLDRAGONFLYDOJI` — Dragonfly Doji

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, ShadowVeryShort.

**Bend implementation:** Classify a doji with a very short upper wick and a lower wick longer than the ShadowVeryShort threshold. This is a current-bar shape predicate backed by BodyDoji and ShadowVeryShort range averages. Emit100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The lower wick need only exceed the very-short threshold, whereas TAKURI requires the separate very-long classification. Output remains positive100 irrespective of the doji body color or external trend. Upstream lookback is `max(BodyDoji,ShadowVeryShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a qualifying lower-wick doji, equality at either wick boundary, and compare the same bar with TAKURI.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldragonflydoji/cdldragonflydoji.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdldragonflydoji/cdldragonflydoji.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLDRAGONFLYDOJI.c).

### `CDLENGULFING` — Engulfing Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers.

**Bend implementation:** Retain the previous open/close pair. For opposite-colored bodies, require the current body to engulf the previous with at least one strict endpoint. Return current direction with magnitude100 when both ends are strict, or80 when one matches. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** No candle-setting averages are needed. Preserve the exact strict/inclusive disjunction and the upstream lookback2 despite the two-bar predicate. Both endpoints equal is not a match. Do not reduce results to a Bool or a fixed magnitude100. Upstream lookback is `2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both directions for strict100, one-equal-endpoint80, and both-equal-endpoint0 results.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlengulfing/cdlengulfing.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlengulfing/cdlengulfing.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLENGULFING.c).

### `CDLEVENINGDOJISTAR` — Evening Doji Star

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.3` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, BodyLong, BodyShort.

**Bend implementation:** Use three bars: long rising first body, upward body-gapped doji, then a falling nonshort final body closing beyond the penetration fraction into the first. Store independent lag-aligned BodyLong, BodyDoji and BodyShort histories. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Penetration defaults to0.3 and the final threshold is strict. Wicks need not gap, and the final body must exceed BodyShort even though the middle bar uses BodyDoji. Preserve source lookback when custom averaging periods differ. Upstream lookback is `max(max(BodyDoji,BodyLong),BodyShort) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a qualifying evening doji star, a final body classified short, and equality at the penetration threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdleveningdojistar/cdleveningdojistar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdleveningdojistar/cdleveningdojistar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLEVENINGDOJISTAR.c).

### `CDLEVENINGSTAR` — Evening Star

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.3` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Combine a long rising first candle, a short second real body gapped upward, and a falling final candle that is not short and penetrates the first body. Reuse a star helper with the doji/short middle classification explicit. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** BodyShort is evaluated at both middle and final bars against their own histories. The middle candle color is unrestricted. Penetration defaults to0.3; a generic three-EMA or reversal composition does not describe this pattern. Upstream lookback is `max(BodyShort,BodyLong) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both middle-candle colors, a doji middle candle, and final bodies on either side of the nonshort boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdleveningstar/cdleveningstar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdleveningstar/cdleveningstar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLEVENINGSTAR.c).

### `CDLGAPSIDESIDEWHITE` — Up/Down-gap side-by-side white lines

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Equal, Near.

**Bend implementation:** Keep three bars and recognize two rising candles whose bodies both remain entirely above or below the first body. Their body sizes must be Near-equal and their opens Equal-close. Emit the original gap direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Both follow-up candles are rising even for the bearish output. Preserve separate Near-size and Equal-open tolerances, evaluated at the second bar, and require that the third body not fill the original window. Upstream lookback is `max(Near,Equal) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a downside-gap pair of rising candles yielding negative100 and a third body that closes the gap and must fail.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlgapsidesidewhite/cdlgapsidesidewhite.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlgapsidesidewhite/cdlgapsidesidewhite.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLGAPSIDESIDEWHITE.c).

### `CDLGRAVESTONEDOJI` — Gravestone Doji

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, ShadowVeryShort.

**Bend implementation:** Classify a doji with a very short lower wick and an upper wick longer than the same ShadowVeryShort threshold. Reuse the doji shape kernel with wick roles explicit. Emit100 when the geometry matches. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Despite the customary bearish interpretation, upstream emits positive100 rather than negative100. It checks geometry only and does not require an uptrend. Both wick comparisons are strict, while the doji body test is inclusive. Upstream lookback is `max(BodyDoji,ShadowVeryShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both body colors and verify plus100, then move either wick exactly onto its threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlgravestonedoji/cdlgravestonedoji.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlgravestonedoji/cdlgravestonedoji.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLGRAVESTONEDOJI.c).

### `CDLHAMMER` — Hammer

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, Near, ShadowLong, ShadowVeryShort.

**Bend implementation:** Classify a short body, long lower wick and very short upper wick; additionally require the lower body edge to lie at or below the previous low plus Near tolerance. Keep the prior bar and current/lagged setting ranges. Emit100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The previous-low positioning test distinguishes the implementation from a context-free hammer silhouette. There is no independent downtrend detector. BodyShort and wick tests are strict; the previous-low-plus-Near comparison is inclusive. Upstream lookback is `max(max(max(BodyShort,ShadowLong),ShadowVeryShort),Near) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Use identical hammer geometry at two price levels relative to the prior low, testing exactly at the inclusive Near boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhammer/cdlhammer.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhammer/cdlhammer.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHAMMER.c).

### `CDLHANGINGMAN` — Hanging Man

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, Near, ShadowLong, ShadowVeryShort.

**Bend implementation:** Reuse the short-body/long-lower-wick/tiny-upper-wick kernel, but position the lower body edge at or above the previous high minus Near tolerance. Preserve the previous high and lagged Near range state. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Its distinction from HAMMER is source-defined positioning relative to the previous high, not a separately calculated uptrend. A silhouette-only common implementation would wrongly make the two functions identical. Upstream lookback is `max(max(max(BodyShort,ShadowLong),ShadowVeryShort),Near) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test the same shape near the prior high versus prior low and equality at previous-high-minus-Near.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhangingman/cdlhangingman.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhangingman/cdlhangingman.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHANGINGMAN.c).

### `CDLHARAMI` — Harami Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Keep a long first body followed by a short second body contained within it. Return the opposite of the first color with magnitude100 for strict containment and80 for inclusive containment involving equal endpoints. Use separate setting histories. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The second body color is unrestricted. BodyShort comparison is inclusive, BodyLong is strict, and the inclusive containment branch must remain distinct from the strict branch. A binary pattern result loses meaningful upstream magnitude information. Upstream lookback is `max(BodyShort,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test strict100 and edge-equal80 in both directions, plus a second bar of the same color as the first.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlharami/cdlharami.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlharami/cdlharami.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHARAMI.c).

### `CDLHARAMICROSS` — Harami Cross Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, BodyLong.

**Bend implementation:** Use the HARAMI body-containment structure with BodyDoji in place of BodyShort for the second bar. Emit the opposite of the long first bar, preserving100 for strict containment and80 for endpoint equality. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Doji tolerance is configurable and inclusive, so exact open-equals-close is insufficient. BodyLong still uses its own preceding window, and the implementation does not require a particular color for the doji. Upstream lookback is `max(BodyDoji,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a nonzero doji-sized body on a first-body endpoint, strict interior containment, and a body just too large to be a doji.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlharamicross/cdlharamicross.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlharamicross/cdlharamicross.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHARAMICROSS.c).

### `CDLHIGHWAVE` — High-Wave Candle

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, ShadowVeryLong.

**Bend implementation:** Compute a short body with both upper and lower wicks exceeding the ShadowVeryLong threshold. The same historical shadow classification supplies both wick comparisons. Emit body color times100; otherwise emit zero. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Unlike LONGLEGGEDDOJI, this uses BodyShort rather than BodyDoji and requires both very-long wicks. The signed result follows candle color, not a trend reversal inference. Zero-period shadow settings can scale the current real body. Upstream lookback is `max(BodyShort,ShadowVeryLong)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a short body with two qualifying wicks, only one qualifying wick, and the exact very-long threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhighwave/cdlhighwave.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhighwave/cdlhighwave.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHIGHWAVE.c).

### `CDLHIKKAKE` — Hikkake Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, pending-pattern confirmation state.

**Bend implementation:** Implement a state machine: detect an inside bar followed by a directional high/low breakout, emit the opposite-breakout candidate direction at100, and retain its inside-bar bounds. A qualifying close during the next three bars emits the same direction at200.

**Blockers and special considerations:** New candidates take precedence and replace the pending pattern; confirmation is emitted on the confirming bar, not backfilled. Expiry and initial warm-up history matter, so three-bar geometry alone is insufficient. No candle-settings averages are used. Upstream lookback is `5` preceding bars; setting names here mean their averaging periods.

**Validation:** Test candidates in both directions, confirmation on the third allowed bar versus the next bar, and a new candidate replacing a pending one.

**Bend interface:** Implemented under [the F32 contract](candles.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhikkake/cdlhikkake.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhikkake/cdlhikkake.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHIKKAKE.c).

### `CDLHIKKAKEMOD` — Modified Hikkake Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Near, pending-pattern confirmation state.

**Bend implementation:** Extend the HIKKAKE state machine with two nested inside bars and a Near-positioned close in the earlier inside bar. Retain the inner bar bounds for a breakout candidate and subsequent three-bar confirmation. Emit candidate100 and confirmation200 with direction.

**Blockers and special considerations:** Four-bar setup geometry and lag2 Near averaging differ from ordinary HIKKAKE. Preserve candidate replacement priority, expiry, and source initialization. Configuration must freeze the Near setting per state rather than reading mutable global settings during a stream. Upstream lookback is `max(1,Near) + 5` preceding bars; setting names here mean their averaging periods.

**Validation:** Test an otherwise valid HIKKAKE without the extra nesting/Near condition, both modified directions, and confirmation exactly at the expiry boundary.

**Bend interface:** Implemented under [the F32 contract](candles.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhikkakemod/cdlhikkakemod.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhikkakemod/cdlhikkakemod.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHIKKAKEMOD.c).

### `CDLHOMINGPIGEON` — Homing Pigeon

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Keep two falling bars. Require a long first body and a short second body strictly inside the first real body. Use BodyLong and BodyShort at their respective bar offsets, then emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Both candles must be falling; generic HARAMI permits other second colors and has equality magnitudes, so it cannot simply supply this output. The second short-body threshold is inclusive, while body containment is strict. Upstream lookback is `max(BodyShort,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a valid pair, the same geometry with a rising second bar, and a contained body touching one endpoint.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhomingpigeon/cdlhomingpigeon.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlhomingpigeon/cdlhomingpigeon.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLHOMINGPIGEON.c).

### `CDLIDENTICAL3CROWS` — Identical Three Crows

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Equal, ShadowVeryShort.

**Bend implementation:** Keep three falling bars with lower closes and very short lower wicks. Each later open must lie within the Equal tolerance around the prior close. Maintain per-offset ShadowVeryShort and Equal ranges. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Unlike THREEBLACKCROWS, the predicate does not require a fourth preceding rising bar. Equal means an inclusive configurable tolerance band, not exact price identity; wick tests remain strict. Upstream lookback is `max(ShadowVeryShort,Equal) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test later opens at both edges of the Equal band and a prior falling context that this recognizer still accepts.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlidentical3crows/cdlidentical3crows.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlidentical3crows/cdlidentical3crows.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLIDENTICAL3CROWS.c).

### `CDLINNECK` — In-Neck Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, Equal.

**Bend implementation:** Test a long falling first bar and rising second bar opening below the first low. Its close must lie inclusively between the first close and first-close-plus-Equal. Reuse the neck-family bar kernel with the close interval explicit. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** INNECK compares the rebound with the previous close, ONNECK uses the previous low, and THRUSTING requires a close beyond the Equal band. These similar names must retain distinct thresholds. Upstream lookback is `max(Equal,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test final close equal to the prior close, equal to the upper Equal boundary, and just beyond that band.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlinneck/cdlinneck.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlinneck/cdlinneck.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLINNECK.c).

### `CDLINVERTEDHAMMER` — Inverted Hammer

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, ShadowLong, ShadowVeryShort.

**Bend implementation:** Classify a short body with a long upper wick and tiny lower wick, then require its whole real body to gap below the previous real body. Keep the previous open/close and current setting range state. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The gap is between bodies rather than complete high-low ranges. No separate downtrend detector is implemented. Its geometry resembles SHOOTINGSTAR but gap direction and output sign differ. Upstream lookback is `max(max(BodyShort,ShadowLong),ShadowVeryShort) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a body gap with overlapping wicks, a touching body endpoint, and an otherwise identical gap-up shape.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlinvertedhammer/cdlinvertedhammer.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlinvertedhammer/cdlinvertedhammer.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLINVERTEDHAMMER.c).

### `CDLKICKING` — Kicking

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, ShadowVeryShort.

**Bend implementation:** Keep two opposite-color long bodies with very short wicks at both ends. Require a full high-low gap upward after a falling first bar or downward after a rising one. Reuse the marubozu kernel and emit the second direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Full-range gaps differ from body-gap predicates. Each marubozu is compared with its own BodyLong and ShadowVeryShort history. A compatible implementation must not infer output from whichever body is larger—that is KICKINGBYLENGTH. Upstream lookback is `max(ShadowVeryShort,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test rising and falling kicks, touching wicks, and differing body lengths without changing the second-color result.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlkicking/cdlkicking.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlkicking/cdlkicking.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLKICKING.c).

### `CDLKICKINGBYLENGTH` — Kicking - bull/bear determined by the longer marubozu

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, ShadowVeryShort.

**Bend implementation:** Reuse the exact opposite-marubozu/full-gap recognition of KICKING, then choose output direction from the candle with the longer real body. Keep both body sizes and colors. Emit that selected direction with magnitude100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The source selects the second body only when strictly longer; equal lengths select the first bar. This can produce the opposite sign from KICKING for otherwise identical geometry. Preserve this tie rule explicitly. Upstream lookback is `max(ShadowVeryShort,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test first-longer, second-longer and exactly equal bodies; compare output signs with KICKING.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlkickingbylength/cdlkickingbylength.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlkickingbylength/cdlkickingbylength.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLKICKINGBYLENGTH.c).

### `CDLLADDERBOTTOM` — Ladder Bottom

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: ShadowVeryShort.

**Bend implementation:** Retain five bars: the first three fall with decreasing opens and closes, the fourth falls with a nontrivial upper wick, and the fifth rises, opening above the fourth body and closing above its high. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Only ShadowVeryShort classification is needed; the first three bodies are not required to pass a BodyLong test. The fourth upper wick must strictly exceed its threshold, and final open/close breaks are strict. Upstream lookback is `ShadowVeryShort + 4` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a qualifying sequence, equality at the fourth high for the final close, and a fourth wick exactly at its threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlladderbottom/cdlladderbottom.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlladderbottom/cdlladderbottom.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLLADDERBOTTOM.c).

### `CDLLONGLEGGEDDOJI` — Long Legged Doji

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, ShadowLong.

**Bend implementation:** Classify a doji body, then require at least one wick to exceed ShadowLong. Reuse current-bar body and wick geometry plus independent setting averages. Emit100 for a recognized shape. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The implementation uses an OR: one long wick is sufficient, even though the name may suggest two. Output is always positive100; RICKSHAWMAN additionally requires two long wicks and central body positioning. Upstream lookback is `max(BodyDoji,ShadowLong)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test only-upper-long and only-lower-long cases, plus a doji with neither wick above the threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdllongleggeddoji/cdllongleggeddoji.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdllongleggeddoji/cdllongleggeddoji.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLLONGLEGGEDDOJI.c).

### `CDLLONGLINE` — Long Line Candle

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, ShadowShort.

**Bend implementation:** Test a body above BodyLong and both wicks below ShadowShort. Maintain one body-range average and one shadow-range average; return body direction times100 for a match. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** This uses the short-wick setting rather than the stricter very-short setting used by MARUBOZU. Its current-bar geometry requires no additional price context. Body and both wick thresholds are strict. Upstream lookback is `max(BodyLong,ShadowShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a long bar whose wicks pass ShadowShort but fail ShadowVeryShort, distinguishing LONGLINE from MARUBOZU.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdllongline/cdllongline.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdllongline/cdllongline.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLLONGLINE.c).

### `CDLMARUBOZU` — Marubozu

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, ShadowVeryShort.

**Bend implementation:** Classify a long body with both upper and lower wicks below ShadowVeryShort. Share the candle geometry and settings implementation with BELTHOLD and CLOSINGMARUBOZU, keeping both wick tests mandatory. Return body color times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** This is a relative threshold classification, not a requirement that open/close exactly equal high/low. BodyLong and ShadowVeryShort may use independent averaging periods and ranges; do not replace them with fixed percentages. Upstream lookback is `max(BodyLong,ShadowVeryShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test small nonzero wicks that fit the configured thresholds, exact wick-threshold equality, and both candle colors.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmarubozu/cdlmarubozu.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmarubozu/cdlmarubozu.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLMARUBOZU.c).

### `CDLMATCHINGLOW` — Matching Low

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Equal.

**Bend implementation:** Keep two falling candles and compare their closes within the first bar Equal tolerance. Use a lag1 Equal range average; no body-size or opening-price condition is required. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The recognizer has no BodyLong test and does not require identical closes. Similar-looking pairs with opposite second color belong to other recognizers. Inclusive tolerance boundaries and source positive output should remain explicit. Upstream lookback is `Equal + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test two falling bars with close difference exactly Equal, just beyond Equal, and a rising second candle.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmatchinglow/cdlmatchinglow.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmatchinglow/cdlmatchinglow.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLMATCHINGLOW.c).

### `CDLMATHOLD` — Mat Hold

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.5` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Keep five bars: long rising first, small falling body gapped up, two additional small reaction bodies, then a rising close above all reaction highs. Bound reaction penetration into the first body with the runtime fraction. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Only the bullish pattern is implemented. The third/fourth bodies may be either color, but their position and descent tests remain mandatory. Penetration defaults to0.5 and limits how deeply reaction bodies reach; it is not a final-close threshold. Upstream lookback is `max(BodyShort,BodyLong) + 4` preceding bars; setting names here mean their averaging periods.

**Validation:** Test nondefault penetration, alternate colors in middle reaction bars, and a final close above reaction bodies but below their highest wick.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmathold/cdlmathold.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmathold/cdlmathold.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLMATHOLD.c).

### `CDLMORNINGDOJISTAR` — Morning Doji Star

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.3` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, BodyLong, BodyShort.

**Bend implementation:** Keep a long falling first bar, a downward body-gapped doji and a rising nonshort third body closing past the penetration fraction into the first. Use separate lagged BodyLong, BodyDoji and BodyShort histories. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Penetration defaults to0.3. Wicks may overlap, unlike ABANDONEDBABY, and the final rising body must exceed its BodyShort classification. Upstream threshold expressions can use fused double arithmetic; F32 branch agreement needs boundary fixtures. Upstream lookback is `max(max(BodyDoji,BodyLong),BodyShort) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a valid body-gap with overlapping wicks, a final short body, and exact versus just-past penetration.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmorningdojistar/cdlmorningdojistar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmorningdojistar/cdlmorningdojistar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLMORNINGDOJISTAR.c).

### `CDLMORNINGSTAR` — Morning Star

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** Penetration = `0.3` (double, 0..3e+37).

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Use the star kernel with a long falling first body, short body-gapped second bar and nonshort rising third bar. Check the final close against the configured penetration into the first body, using lag-correct range averages. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The middle body color is unrestricted and may be a doji if it passes BodyShort. Penetration defaults to0.3; BodyShort at middle and final bars must use their own historical windows. Upstream lookback is `max(BodyShort,BodyLong) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both colors of the middle bar and custom BodyShort averaging periods that make the two classification thresholds differ.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmorningstar/cdlmorningstar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlmorningstar/cdlmorningstar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLMORNINGSTAR.c).

### `CDLONNECK` — On-Neck Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, Equal.

**Bend implementation:** Test a long falling first candle, then a rising candle opening below its low and closing within an inclusive Equal band around that low. Share OHLC and neck-family state while keeping this center distinct. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The equality reference is prior low, not prior close. Neither the rebound body size nor a generic trend calculation is consulted. Equal tolerance comes from the prior bar history and can differ from an arbitrary fixed epsilon. Upstream lookback is `max(Equal,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a rebound close near the previous low but far from the previous close, and equality at both Equal-band edges.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlonneck/cdlonneck.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlonneck/cdlonneck.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLONNECK.c).

### `CDLPIERCING` — Piercing Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong.

**Bend implementation:** Recognize a long falling first body and long rising second body opening below the first low. Its close must stay below the first open but pass the first body midpoint. Maintain BodyLong thresholds at both offsets. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The implementation uses a strict midpoint comparison, although prose definitions sometimes say at least halfway. There is no penetration parameter here. Full opening gap below the prior low differs from a body-only gap. Upstream lookback is `BodyLong + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test closes exactly at midpoint, just above midpoint and exactly at the prior open; only the interior-above-midpoint case matches.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlpiercing/cdlpiercing.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlpiercing/cdlpiercing.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLPIERCING.c).

### `CDLRICKSHAWMAN` — Rickshaw Man

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, Near, ShadowLong.

**Bend implementation:** Classify a doji with both wicks longer than ShadowLong and a real body intersecting the Near band around the high-low midpoint. Maintain BodyDoji, ShadowLong and Near range averages. Emit100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The body need not be centered exactly: its interval must intersect the midpoint tolerance band. Both long-shadow conditions are mandatory, distinguishing it from LONGLEGGEDDOJI. Output is a positive shape marker, independent of color. Upstream lookback is `max(max(BodyDoji,ShadowLong),Near)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a doji with two long wicks but body just outside the central Near band, then one touching its inclusive boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlrickshawman/cdlrickshawman.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlrickshawman/cdlrickshawman.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLRICKSHAWMAN.c).

### `CDLRISEFALL3METHODS` — Rising/Falling Three Methods

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Keep exactly five bars: long first and final candles share a color, three short intervening candles oppose it and move against the initial run, each body overlapping the initial high-low range. The final candle resumes beyond the first close. Emit initial direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Only exactly three reaction candles are recognized, and their colors are explicitly constrained despite broader textbook variants. Range overlap is not full body containment. Preserve separate BodyLong/BodyShort history for each tested offset. Upstream lookback is `max(BodyShort,BodyLong) + 4` preceding bars; setting names here mean their averaging periods.

**Validation:** Test bullish/bearish cases, a four-reaction-bar variant that should not be treated identically, and partial range overlap versus complete containment.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlrisefall3methods/cdlrisefall3methods.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlrisefall3methods/cdlrisefall3methods.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLRISEFALL3METHODS.c).

### `CDLSEPARATINGLINES` — Separating Lines

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, Equal, ShadowVeryShort.

**Bend implementation:** Keep opposite-color bars with opens within the prior Equal band. Require the second to be a long belt-hold shape: tiny lower wick if rising or tiny upper wick if falling. Emit its direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The prior bar does not need a long body; the final bar does. Opens use inclusive Equal tolerance rather than literal equality. Reuse BELTHOLD geometry without accidentally importing other contextual requirements. Upstream lookback is `max(max(ShadowVeryShort,BodyLong),Equal) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a short first bar with a valid final belt hold and opens at the Equal-band boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlseparatinglines/cdlseparatinglines.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlseparatinglines/cdlseparatinglines.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLSEPARATINGLINES.c).

### `CDLSHOOTINGSTAR` — Shooting Star

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, ShadowLong, ShadowVeryShort.

**Bend implementation:** Classify a short body, long upper wick and tiny lower wick whose entire real body gaps above the previous real body. Reuse the inverted-hammer shape kernel with the opposite body-gap direction. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Wicks may overlap across the gap; the source compares real-body endpoints. No separate uptrend detector or confirmation bar is required. Body, shadow and gap inequalities are strict. Upstream lookback is `max(max(BodyShort,ShadowLong),ShadowVeryShort) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test an upward body gap with overlapping wicks, a touching endpoint, and the same shape gapped downward.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlshootingstar/cdlshootingstar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlshootingstar/cdlshootingstar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLSHOOTINGSTAR.c).

### `CDLSHORTLINE` — Short Line Candle

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort, ShadowShort.

**Bend implementation:** Classify a body below BodyShort with both wicks below ShadowShort. Use current-bar candle geometry and independent lag-free setting averages, then report body color times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** All three size comparisons are strict. A small body alone is insufficient: long wicks would instead qualify other shapes. With averaging period zero, each setting uses the evaluated candle range according to its configured range type. Upstream lookback is `max(BodyShort,ShadowShort)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a short-bodied bar with one long wick, strict threshold equality and both body colors.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlshortline/cdlshortline.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlshortline/cdlshortline.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLSHORTLINE.c).

### `CDLSPINNINGTOP` — Spinning Top

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyShort.

**Bend implementation:** Compute a short body and require each wick to be longer than that real body. Reuse only BodyShort averaging plus geometry; the wick-to-body tests are direct comparisons rather than shadow-setting classifications. Emit body direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** A zero-size doji body can qualify if both wicks are positive. Do not substitute ShadowLong thresholds: the source uses body length itself. Body color uses close greater than or equal to open for positive direction. Upstream lookback is `BodyShort` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a zero-body bar with two positive wicks and a bar where one wick exactly equals its body length.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlspinningtop/cdlspinningtop.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlspinningtop/cdlspinningtop.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLSPINNINGTOP.c).

### `CDLSTALLEDPATTERN` — Stalled Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort, Near, ShadowVeryShort.

**Bend implementation:** Hold three rising bars with higher closes. The first two bodies must be long, the second has a tiny upper wick and opens within a Near-expanded first body, and the third is short near the second body shoulder. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** Unlike ADVANCEBLOCK, this specifically requires two long bodies followed by a short body. Preserve the third-open inequality containing its own body length and the prior Near allowance; a simple shrinking-body detector is insufficient. Upstream lookback is `max(max(BodyLong,BodyShort),max(ShadowVeryShort,Near)) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a valid shoulder-riding third body, a second body failing BodyLong, and a third open just below the permitted shoulder boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlstalledpattern/cdlstalledpattern.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlstalledpattern/cdlstalledpattern.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLSTALLEDPATTERN.c).

### `CDLSTICKSANDWICH` — Stick Sandwich

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Equal.

**Bend implementation:** Keep a falling-rising-falling three-bar sequence. The middle low must be above the first close and the final close must lie within an Equal band around the first close. Maintain the Equal range average at lag2. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The middle candle must trade entirely above the first close, not simply close above it. First/final matching lows here refer to close prices, with inclusive tolerance. No BodyLong or BodyShort setting is involved. Upstream lookback is `Equal + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test matching closes where the middle wick crosses the first close, and closes exactly at the Equal-band boundary.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlsticksandwich/cdlsticksandwich.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlsticksandwich/cdlsticksandwich.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLSTICKSANDWICH.c).

### `CDLTAKURI` — Takuri (Dragonfly Doji with very long lower shadow)

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji, ShadowVeryLong, ShadowVeryShort.

**Bend implementation:** Use a doji body, very short upper wick and very long lower wick. Reuse the dragonfly geometry with the lower-wick test driven by ShadowVeryLong rather than ShadowVeryShort. Maintain three independent setting averages. Emit100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** This is always a positive shape marker; do not derive sign from body color. ShadowVeryLong can be based on the current real body when its averaging period is zero. Preserve inclusive doji and strict wick tests. Upstream lookback is `max(max(BodyDoji,ShadowVeryShort),ShadowVeryLong)` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a dragonfly-shaped bar whose lower wick is not very long, and one exactly on versus above the very-long threshold.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdltakuri/cdltakuri.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdltakuri/cdltakuri.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLTAKURI.c).

### `CDLTASUKIGAP` — Tasuki Gap

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: Near.

**Bend implementation:** Keep an initial body gap followed by an opposite-color candle opening inside the post-gap body and closing partway into the unfilled gap. Require Near-equal sizes for the last two bodies. Return the post-gap direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The gap must remain partly open after the final candle, and the two-body size difference must be strictly below the Near threshold. Source has mirror upward/downward branches; the first candle color is not independently constrained. Upstream lookback is `Near + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test each direction, final closes exactly at the far gap edge, and last-two body sizes exactly Near apart.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdltasukigap/cdltasukigap.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdltasukigap/cdltasukigap.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLTASUKIGAP.c).

### `CDLTHRUSTING` — Thrusting Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, Equal.

**Bend implementation:** Test a long falling first bar and a rising second bar opening below its low. Its close must pass the first-close-plus-Equal band but stay at or below the first midpoint. Reuse neck-family state with this interval. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The lower penetration boundary is strict and the midpoint upper boundary inclusive. This distinguishes it from INNECK and PIERCING. The second body is not required to be long by the source. Upstream lookback is `max(Equal,BodyLong) + 1` preceding bars; setting names here mean their averaging periods.

**Validation:** Test close at the midpoint, at first-close-plus-Equal and just above midpoint to distinguish the neighboring patterns.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlthrusting/cdlthrusting.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlthrusting/cdlthrusting.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLTHRUSTING.c).

### `CDLTRISTAR` — Tristar Pattern

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyDoji.

**Bend implementation:** Keep three doji-sized bodies and test a second-body gap, followed by a third body retreating from the second extreme. An upward star returns bearish100; a downward star returns bullish100. Reuse candle body-gap helpers. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The source compares all three body sizes with the same BodyDoji average computed for the first candle; do not independently average each bar. The gap uses bodies, and the third-body extreme test is strict. Upstream lookback is `BodyDoji + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Use changing recent ranges so three per-bar thresholds would differ, plus upward and downward gaps with third-body equality at the extreme.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdltristar/cdltristar.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdltristar/cdltristar.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLTRISTAR.c).

### `CDLUNIQUE3RIVER` — Unique 3 River

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Keep a long falling first body, a second falling harami-like body with a lower low, and a short rising third candle opening above the second low. Maintain BodyLong at lag2 and BodyShort at the current bar. Emit bullish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The source permits the second open to equal the first open but requires the second close above the first close. It does not enforce the comment’s optional preference that the third body remain below the second close. Upstream lookback is `max(BodyShort,BodyLong) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test the second-open equality case and a third short rising body above the second close, which should not be rejected for a textbook-only condition.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlunique3river/cdlunique3river.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlunique3river/cdlunique3river.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLUNIQUE3RIVER.c).

### `CDLUPSIDEGAP2CROWS` — Upside Gap Two Crows

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers, immutable candle settings, lag-aligned range averages: BodyLong, BodyShort.

**Bend implementation:** Keep a long rising first body, a short falling second body gapped upward and a falling third body strictly engulfing the second while remaining above the first close. Maintain BodyLong/BodyShort at the first two offsets. Emit bearish100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** The third candle closes above the first close, unlike TWO CROWS, whose final close lies inside the first body. The second body may equal its short threshold; all gap/engulf boundaries are strict. Upstream lookback is `max(BodyShort,BodyLong) + 2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test a valid engulfing third body, a third close inside the first body, and a second body exactly at BodyShort.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlupsidegap2crows/cdlupsidegap2crows.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlupsidegap2crows/cdlupsidegap2crows.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLUPSIDEGAP2CROWS.c).

### `CDLXSIDEGAP3METHODS` — Upside/Downside Gap Three Methods

**Interface:** inputs `Open`, `High`, `Low`, `Close`; outputs `outInteger` (integer).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** typed OHLC bars, generic input/output batch traversal, signed pattern result, candle geometry helpers.

**Bend implementation:** Keep three bars: first two have the same color and a body gap in that direction; the third reverses color, opens strictly inside the second body and closes strictly inside the first. Emit the first direction times100. Current F32 contract: [implemented interface and limits](candles.md).

**Blockers and special considerations:** No candle-setting averages are used, and the source needs only a two-bar lookback. The final candle closes the gap rather than preserving it, distinguishing this pattern from TASUKIGAP. Preserve strict endpoint containment. Upstream lookback is `2` preceding bars; setting names here mean their averaging periods.

**Validation:** Test both directions and final open/close exactly on a containing-body endpoint, which should fail.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlxsidegap3methods/cdlxsidegap3methods.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cdlxsidegap3methods/cdlxsidegap3methods.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CDLXSIDEGAP3METHODS.c).

## Math Operators (12)

### `ADD` — Vector Arithmetic Add

**Interface:** inputs `inReal0`, `inReal1`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** paired inputs, generic series traversal.

**Bend implementation:** Consume an aligned pair of values and apply ~add; F32 binds F32.add. Represent pairs as one input record so batch and streaming cannot silently consume different row counts.

**Blockers and special considerations:** The implemented interface accepts one typed operand record; Series.map preserves alignment without a parallel-array zip. Large same-sign inputs may overflow; small increments can disappear.

**Validation:** Positive/negative pairs, empty and unequal-length inputs, and an F32 scale-limit case.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/add/add.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/add/add.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ADD.c).

### `CUMSUM` — Cumulative Sum

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** running sum.

**Bend implementation:** Keep one running total initialized to zero and emit the updated sum on every input. State initialization defines the accumulation anchor.

**Blockers and special considerations:** F32 totals can stop changing when new values are small relative to the accumulated magnitude. Compensated sums change arithmetic relative to TA-Lib; document that choice and explicit reset behavior.

**Validation:** Positive and alternating-sign streams, long small increments after a large prefix, and explicit state reset.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cumsum/cumsum.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cumsum/cumsum.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CUMSUM.c).

### `DIV` — Vector Arithmetic Div

**Interface:** inputs `inReal0`, `inReal1`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** paired inputs, numeric domain policy.

**Bend implementation:** Map aligned pairs using ~div. The upstream source performs raw IEEE division with no denominator guard; keep this behavior in a compatibility interface.

**Blockers and special considerations:** Zero division is observably Inf or NaN, not zero. A checked Bend API may return an explicit domain result, but this must be separate from None used for warm-up.

**Validation:** Nonzero division, positive/negative zero denominators, 0/0, and mismatched input lengths.

**Bend interface:** Implemented under [the F32 contract](causal-indicators.md); see its seed, alignment, parameter, cost and numerical limits. The assessment discussion above retains its original planning context.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/div/div.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/div/div.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_DIV.c).

### `MAX` — Highest value over a specified period

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** monotonic extrema queue, owned ring.

**Bend implementation:** Maintain a monotonic queue of candidate values plus absolute sample indices; expire candidates outside the logical period and emit the maximum. An O(period) scan is a simpler correct first implementation. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** A queue gives amortized constant updates only after its ownership/index behavior is implemented and tested. Comparisons need explicit finite-input assumptions. Preserve source behavior around repeated extrema and expiration.

**Validation:** Repeated extrema crossing the window boundary, increasing/decreasing inputs, and a non-power-of-two window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/max/max.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/max/max.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MAX.c).

### `MAXINDEX` — Index of highest value over a specified period

**Interface:** inputs `inReal`; outputs `outInteger` (integer).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** monotonic extrema queue, integer index output, generic output type.

**Bend implementation:** Reuse extrema state but emit the absolute index of the highest sample in the input stream. On equal extrema keep the most recent sample, matching the pinned source. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Return an integer/index type rather than F32, which loses exact integers beyond 2^24. Decide whether batch subranges report indices in the original input or a rebased stream; TA-Lib uses original input indices.

**Validation:** All-equal windows must select the newest index; test expiration, nonzero subrange offsets and large indices.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/maxindex/maxindex.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/maxindex/maxindex.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MAXINDEX.c).

### `MIN` — Lowest value over a specified period

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** monotonic extrema queue, owned ring.

**Bend implementation:** Maintain a monotonic queue of candidate values plus absolute sample indices; expire candidates outside the logical period and emit the minimum. An O(period) scan is a simpler correct first implementation. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** A queue gives amortized constant updates only after its ownership/index behavior is implemented and tested. Comparisons need explicit finite-input assumptions. Preserve source behavior around repeated extrema and expiration.

**Validation:** Repeated extrema crossing the window boundary, increasing/decreasing inputs, and a non-power-of-two window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/min/min.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/min/min.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MIN.c).

### `MININDEX` — Index of lowest value over a specified period

**Interface:** inputs `inReal`; outputs `outInteger` (integer).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** monotonic extrema queue, integer index output, generic output type.

**Bend implementation:** Reuse extrema state but emit the absolute index of the lowest sample in the input stream. On equal extrema keep the most recent sample, matching the pinned source. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Return an integer/index type rather than F32, which loses exact integers beyond 2^24. Decide whether batch subranges report indices in the original input or a rebased stream; TA-Lib uses original input indices.

**Validation:** All-equal windows must select the newest index; test expiration, nonzero subrange offsets and large indices.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minindex/minindex.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minindex/minindex.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MININDEX.c).

### `MINMAX` — Lowest and highest values over a specified period

**Interface:** inputs `inReal`; outputs `outMin` (real), `outMax` (real).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** monotonic extrema queue, multi-output records.

**Bend implementation:** Update one minimum queue and one maximum queue for the same input and period; emit a named {minimum, maximum} record once both are ready. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** This is one catalog function with two outputs, not two independent indicators. A shared window index ensures both outputs refer to the same bars; generalize the scalar-only batch result.

**Validation:** Constant, alternating-extreme and monotonic windows; compare both fields against independent MIN and MAX results.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minmax/minmax.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minmax/minmax.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MINMAX.c).

### `MINMAXINDEX` — Indexes of lowest and highest values over a specified period

**Interface:** inputs `inReal`; outputs `outMinIdx` (integer), `outMaxIdx` (integer).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** monotonic extrema queue, integer index output, multi-output records.

**Bend implementation:** Compose the min-index and max-index queues and emit an integer-index pair, retaining the latest index on equality for each side. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** Neither field is a price. Preserve original-input coordinates and typed integer output; avoid floating-point conversion of indices.

**Validation:** Equal min/max ties, nonzero start offset and expiration of the selected extrema.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minmaxindex/minmaxindex.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/minmaxindex/minmaxindex.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MINMAXINDEX.c).

### `MULT` — Vector Arithmetic Mult

**Interface:** inputs `inReal0`, `inReal1`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** paired inputs, generic series traversal.

**Bend implementation:** Consume an aligned pair of values and apply ~mul; F32 binds F32.mul. Represent pairs as one input record so batch and streaming cannot silently consume different row counts.

**Blockers and special considerations:** The implemented interface accepts one typed operand record; Series.map preserves alignment without a parallel-array zip. Products can overflow or underflow even when both inputs are finite.

**Validation:** Positive/negative pairs, empty and unequal-length inputs, and an F32 scale-limit case.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mult/mult.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mult/mult.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_MULT.c).

### `SUB` — Vector Arithmetic Subtraction

**Interface:** inputs `inReal0`, `inReal1`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** paired inputs, generic series traversal.

**Bend implementation:** Consume an aligned pair of values and apply ~sub; F32 binds F32.sub. Represent pairs as one input record so batch and streaming cannot silently consume different row counts.

**Blockers and special considerations:** The implemented interface accepts one typed operand record; Series.map preserves alignment without a parallel-array zip. Close large operands can lose meaningful differences before subtraction because input quantization already occurred.

**Validation:** Positive/negative pairs, empty and unequal-length inputs, and an F32 scale-limit case.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sub/sub.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sub/sub.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SUB.c).

### `SUM` — Summation

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** Time Period = `30` (integer, 2..100000).

**Readiness:** Existing. **Dependencies:** owned ring, rolling sum.

**Bend implementation:** Generalize the existing rolling-sum storage into an exposed rolling SUM using its logical period and subtract-old/add-new transition. Emit after a complete window. Current F32 contract: [implemented interface and limits](overlap-statistics.md).

**Blockers and special considerations:** The existing SMA already supplies the core mechanism. Add drift/rebuild policy for long series and outlier expiration; do not assume one period bound is valid for every upstream function.

**Validation:** Window sums by hand, period1, non-power-of-two periods, and an outlier leaving a long-running window.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sum/sum.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sum/sum.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SUM.c).

## Math Transform (15)

### `ACOS` — Vector Trigonometric ACos

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~acos, bound to F32.acos in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Restrict a checked interface to [-1,1], or deliberately retain IEEE NaN outside it. The result is in radians. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** -1, 0 and 1; values just inside/outside both boundaries.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/acos/acos.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/acos/acos.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ACOS.c).

### `ASIN` — Vector Trigonometric ASin

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~asin, bound to F32.asin in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Domain is [-1,1]; preserve radians and signed-zero behavior. An undefined result must not be mistaken for warm-up. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** -1, -0, 0 and 1, plus a value outside the domain.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/asin/asin.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/asin/asin.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ASIN.c).

### `ATAN` — Vector Trigonometric ATan

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~atan, bound to F32.atan in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** No finite-input domain restriction; output is radians. Large magnitudes approach signed pi/2. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** Negative, zero and positive input; large magnitudes approaching pi/2.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/atan/atan.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/atan/atan.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_ATAN.c).

### `CEIL` — Vector Ceil

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~ceil, bound to F32.ceil in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Keep the output numeric, rather than converting to U32: negative inputs and very large integral floats remain valid. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** -1.2, -0.2, 0, 1 and 1.2, including signed zero.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ceil/ceil.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ceil/ceil.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_CEIL.c).

### `COS` — Vector Trigonometric Cos

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~cos, bound to F32.cos in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Arguments are radians; large-angle argument reduction and F32 rounding can differ from the double oracle. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, pi/2 and pi, plus a large angle with a tolerance.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cos/cos.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cos/cos.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_COS.c).

### `COSH` — Vector Trigonometric Cosh

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~cosh, bound to F32.cosh in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Rapid exponential growth can overflow F32 at inputs still representable in double. Decide whether overflow is returned or checked. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, symmetric positive/negative inputs, and the F32 overflow boundary.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cosh/cosh.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/cosh/cosh.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_COSH.c).

### `EXP` — Vector Arithmetic Exp

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~exp, bound to F32.exp in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Positive overflow and negative underflow occur much earlier in F32 than in double. Preserve zero-underflow versus domain error. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, positive/negative arguments, and underflow/overflow thresholds.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/exp/exp.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/exp/exp.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_EXP.c).

### `FLOOR` — Vector Floor

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~floor, bound to F32.floor in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Return a numeric value, including negatives; truncation toward zero is not floor. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** -1.2, -0.2, 0 and 1.2; large already-integral values.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/floor/floor.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/floor/floor.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_FLOOR.c).

### `LN` — Vector Log Natural

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~log, bound to F32.log in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Positive inputs have real results; zero produces negative infinity and negatives produce NaN in a raw IEEE interface. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 1, values on either side of 1, zero and negative input.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ln/ln.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/ln/ln.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_LN.c).

### `LOG10` — Vector Log10

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~log10, bound to F32.log10 in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Use the dedicated Base operation to avoid changing rounding through log(x)/log(10). Domain behavior follows LN. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 1, 10 and 100, plus zero and negative inputs.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/log10/log10.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/log10/log10.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_LOG10.c).

### `SIN` — Vector Trigonometric Sin

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~sin, bound to F32.sin in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Arguments are radians; near-zero results need absolute tolerance, and very large angles need explicit accuracy tests. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, pi/2, pi and a large-angle input.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sin/sin.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sin/sin.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SIN.c).

### `SINH` — Vector Trigonometric Sinh

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~sinh, bound to F32.sinh in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Odd symmetry and signed zero matter; large magnitude can overflow F32. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, symmetric small inputs and large positive/negative arguments.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sinh/sinh.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sinh/sinh.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SINH.c).

### `SQRT` — Vector Square Root

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~sqrt, bound to F32.sqrt in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Negative arguments produce NaN in the raw interface; do not clamp them merely to keep output finite. Preserve signed zero. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, 4, a negative input and values near zero.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sqrt/sqrt.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/sqrt/sqrt.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_SQRT.c).

### `TAN` — Vector Trigonometric Tan

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~tan, bound to F32.tan in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Poles near odd multiples of pi/2 amplify tiny input differences. A large F32 result can be valid and need not match double closely. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, pi/4 and values on both sides of pi/2.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tan/tan.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tan/tan.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TAN.c).

### `TANH` — Vector Trigonometric Tanh

**Interface:** inputs `inReal`; outputs `outReal` (real).

**Parameters:** none.

**Readiness:** Existing. **Dependencies:** numeric capabilities, unary series mapping.

**Bend implementation:** Map each sample through a template operation ~tanh, bound to F32.tanh in the facade. No rolling state or warm-up is required; emit one result for every input.

**Blockers and special considerations:** Large finite magnitudes saturate at +/-1. Preserve odd symmetry and signed zero. A future F64 facade needs the same operation; the current optional software-F64 idea does not establish these capabilities.

**Validation:** 0, symmetric small inputs and large saturation inputs.

**Bend interface:** Implemented under the [F32 direct-group contract](direct-indicators.md); reference metadata above does not imply identical defaults, parameter limits or arithmetic.

**Sources:** [specification](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tanh/tanh.md), [algorithm](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/tanh/tanh.c), [public implementation](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_func/ta_TANH.c).

## Completeness and maintenance

This revision contains exactly one named entry per core XML abbreviation and Python grouped function name: **237 entries, no missing names and no duplicate entries**. All 237 linked authored specifications, algorithm files and generated implementation files exist in the pinned snapshot. Parameter defaults, bounds, required inputs and output names/types were extracted from that XML rather than inferred from indicator names.

When refreshing, pin both core and Python revisions, compare the new name sets, then review changed implementations and metadata. A matching name set alone cannot detect a changed seed, threshold, output convention or warm-up default. Keep the catalog descriptive of what was inspected, and update readiness only after the corresponding Bend code and validation exist.
