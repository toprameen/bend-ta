# Hilbert cycles and Swiss Army Knife filters

These F32 interfaces provide `init`, `next` and `batch`. Every batch retains one
`Maybe` slot per observation and applies the same transition as streaming.
Initialize once and carry the returned state across chunks. A valid empty batch
is empty. The shared parameter error is `Parameters.InvalidParameter{}` from
`src/core/parameters.bend`.

## Hilbert transform family

| Interface | Parameters | Output | Initial `None` slots |
|---|---|---|---:|
| `HT_DCPERIOD` | None | F32 smoothed cycle length in observations | 32 |
| `HT_PHASOR` | None | `Hilbert.Phasor{in_phase, quadrature}` | 32 |
| `HT_TRENDLINE` | None | F32 adaptive trendline | 63 |
| `HT_DCPHASE` | None | F32 cycle phase in degrees | 63 |
| `HT_SINE` | None | `Hilbert.Sine{sine, lead_sine}` | 63 |
| `HT_TRENDMODE` | None | U32, 1 for trend and 0 for cycle | 63 |

`init()` returns `Done{state}` with the shared result type; these functions have
no configuration to reject. The multi-line public type aliases are
`HT_PHASOR.Value()` and `HT_SINE.Value()`; import `src/core/hilbert.bend` to match
their constructors. All six state aliases are owned `Type` values.

The generic engine reuses MAMA's four-price smoothing, six-delay Hilbert FIR,
guarded homodyne period measurement, rate limits and 6..50 instantaneous-period
clamp. Its period smoother is `0.33 * period + 0.67 * previous`. The initial
smoothed period can be below six while approaching the clamp. The phasor is the
three-observation delayed detrender and its Hilbert quadrature.

The two 32-slot interfaces start Hilbert updates at index 12. The four 63-slot
interfaces start at index 37. All delays, adaptive periods and trend averages
start at zero. Earlier observations advance raw price history and the four-price
smoother, but do not advance the Hilbert stages. This distinction matters: the
period estimate exposed by `HT_DCPERIOD` does not share the initial transient of
the internally estimated period used by `HT_DCPHASE`.

Phase scans the most recent rounded smoothed-period count of smoothed prices,
newest first. It uses the reference's guarded atan ratio, quadrant adjustment,
90-degree offset, one-observation WMA lag correction and upper wrap at 315 degrees.
Sine outputs apply sine to that phase and its 45-degree lead. Trendline averages
**raw** prices over that same count, then weights the current and three previous
averages by 4, 3, 2, 1 over 10. Trend mode combines sine crossings, elapsed trend
observations, phase advance and a 1.5% deviation from trendline.

The engine owns one window of 50 raw/smoothed pairs. The window has power-of-two
capacity; logical wrapping remains inside the shared window module. Reverse
scans use bounded tail traversal. The rounded scan count is checked before
numeric-to-integer conversion and capped at 50. Startup counts saturate at 64; the trend-day
counter saturates at 51, beyond every possible comparison threshold. State size
and per-observation work are bounded independently of stream length. The four
longer-warm-up interfaces perform scans of at most 50 observations.

## Swiss Army Knife family

| Interface | Period bounds | Other parameter | Output |
|---|---|---|---|
| `SWAK_BUTTER` | 2..10000 | None | Two-pole Butterworth low-pass |
| `SWAK_GAUSS` | 2..10000 | None | Two-pole Gaussian low-pass |
| `SWAK_2PHP` | 2..10000 | None | Two-pole high-pass |
| `SWAK_BP` | 5..2000 | Finite delta in 0.05..0.5 | Band-pass |
| `SWAK_HP` | 5..100000 | None | One-pole high-pass |

Call `init(period)` and `batch(prices, period)`, or `init(period, delta)` and
`batch(prices, period, delta)` for band-pass. Period and delta are runtime data.
All outputs are F32. Invalid configuration fails even for an empty batch. There
is no structural warm-up: every input yields `Some`, beginning with index zero.
The usual reference period is 20 and band-pass delta is 0.1; arguments are
explicit.

One shared engine constructs coefficients and applies the recurrence. The first
observation seeds both input delay slots. Butterworth and Gaussian output delays
start at that price; high-pass and band-pass output delays start at zero. The
first observation still executes the recurrence, so its low-pass result can
include F32 rounding. The equations retain the reference's newest-output outer
addition. The two-pole alpha uses `2.415 * (2 * sin(pi / period)^2)`; the high-pass
alpha uses its half-angle form; band-pass uses `(1 - sin(t)) / cos(t)`. These
avoid the reference's identified long-period coefficient cancellations.

State is fixed-size `Data` with two numeric input and two numeric output delays.
There are no arrays, period-length initialization loops or unbounded counters.
Accepted upper bounds therefore require constant-size initialization and fixed
work per observation.

## Numerical contract and reference evidence

All eleven follow TA-Lib revision
[`ccd3172940ed1d9daa4e7197f2265810852e8910`](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input).
The library implements **unstable period zero**, with no automatic stabilization
or additional discard setting. These are the source lookbacks under that setting.
The retained TA-Lib attribution in [candles.md](candles.md#ta-lib-attribution)
covers these derived algorithms.

The [MAMA arithmetic contract](mama.md#arithmetic-and-reference-evidence) also
applies to Hilbert cycles: centered fresh four-price WMA and difference-form FIR
avoid baseline cancellation and rolling-WMA drift. Trendline's final four-average
WMA uses the same centered arithmetic. The remaining cycle equations, reverse
scan order and filter recurrence preserve the reference's operation grouping.
Pi and all generic constants are built from the supplied numeric operations;
there are no F32 literals or F32 conversions in the shared engines.

F32 is sensitive to phase conditioning. On flat prices, pure linear ramps,
Nyquist alternation, or otherwise negligible quadrature, tiny rounding residuals
can change atan ratios, period estimates, phase, sine and categorical trend
outputs. Large baselines can suppress small cycles before the Hilbert stages.
Finite input does not imply close agreement with a double implementation in
these regimes. Overflow and underflow remain possible. Phase has no stable
meaning when its estimated cycle vanishes; no missing-value or recovery policy
is added for that case.

External native and emitted-JS comparisons against the compiled pinned C library
covered 156 configurations/series and 39,936 aligned slots per backend. Inputs
included zeros, constants, ramps, varied prices, cycles, shifted cycles,
alternation, impulse, step and small values. Printed native and JS results agreed
throughout. On the ordinary cycle/varied series, maximum observed errors were
below 0.000016 period observations, 0.0000042 phasor units, 0.0000044 trendline
units, 0.0024 phase degrees and 0.000032 sine units; trend classifications agreed.
At a 10,000 baseline, period error reached 0.0114 and phase error 0.0362 degrees.
The 1,000,000-baseline, flat and degenerate series produced larger differences:
linear-ramp period error reached 10.4 observations, flat phase error approached
170 degrees, and some trend classifications differed. These measured cases are
limits of comparison evidence, not universal accuracy guarantees.

A further six filter configurations each processed 30,000 observations at their
period caps, including both band-pass delta boundaries. Complete native outputs stayed
finite; native/JS samples every 1,000 observations agreed. Against the actual C
oracle, maximum errors on a size-two step plus a quarter-unit cycle were below
0.008 for the two low-pass filters, 0.00064 for two-pole high-pass, 0.0042 for
band-pass, and 0.000079 for one-pole high-pass. Long-period recurrences accumulate
F32 rounding; these measurements do not establish a stability or error bound for
all finite sequences.

The two compact fixtures in `tests/reference/hilbert.bend` and
`tests/reference/filters.bend` exercise every name, independent pinned-C targets
on a 180-observation repeating integer cycle, exact alignment, first-observation
filter seeds, flat-series bounds, empty/short input, configuration boundaries and
split-state continuation. Target tolerance is 0.0002 absolute; trend flags compare
exactly. The cycle is `[10,12,14,13,11,8,6,7,9,11,13,12]`, repeated fifteen times.
Hilbert targets use lookback, lookback+1, 80, 100 and 179; filter targets use 0, 1,
2, 30 and 179 at period 20, delta 0.1. Fixtures require no external oracle.
