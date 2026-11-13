# Shared TA foundation

The foundation uses generic Bend templates with F32 bindings in
[`src/f32.bend`](../src/f32.bend). The shared modules provide stream traversal,
owned windows, smoothing, and typed inputs for indicators.

## Traversal and ownership

[`Series`](../src/core/series.bend) accepts independent input/output `Data` types
and an owned state `S: Type`. Its closed `~step` consumes a state and input and
returns the next state with `Maybe<O>`. `batch` returns aligned output slots;
`scan` also returns the final state for chunked or continued processing.
`map` applies a closed stateless transform and returns plain values. Empty
input preserves state in `scan` and produces an empty output list.

`None` means warm-up. A zero result is still `Some{0}`. Record inputs keep bar
fields or paired values aligned without independently sized input arrays.
Record outputs support several values per bar. See the runnable
[foundation fixture](../tests/core/foundation.bend) and
[bar/settings fixture](../tests/reference/foundation.bend).

[`Window`](../src/core/window.bend) is the shared owned ring. The F32 interface is:

| Operation | Contract |
|---|---|
| `Window.init(period)` | Validates period before allocation and returns an owned state. |
| `Window.push(state, value)` | Returns state and the evicted value, or `None` until a full window existed before insertion. |
| `Window.lag(state, age)` | Age 0 is newest; unfilled or out-of-range ages return `None`. |
| `Window.length(state)` | Returns state and live length, saturated at the logical period. |
| Core `Window.full` | Returns state and whether the window is full. |
| Core `Window.cycled` | Returns state and whether a full window is at its logical wrap boundary. |
| Core `Window.fold` | Threads ownership over live entries from oldest to newest; accepts a closed reducer and explicit runtime context. |

Use the returned state for each subsequent operation. Capacity and wrap positions
are internal; unused power-of-two capacity never extends a logical window.
F32 periods are 1..2^30, subject to available memory. Low-level core initializers
are for numeric adapters: they assume a validated period/capacity pair. Other
element layouts must also fit Bend's allocation limits.

## Sums and seeded smoothing

`SUM.init/next` supplies a rolling sum. SMA reuses this storage and transition.
Both use O(period) storage and amortized constant work per input. At each
logical wrap, the sum is rebuilt chronologically from the live window; that
individual update costs O(period). The existing wrap position supplies the
refresh schedule, with no added counter. Between refreshes subtract/add sums
can drift. A fresh fold can still round or overflow; this is not a compensated
accumulator or a universal error bound. A refresh can recover after an earlier
finite-input overflow has left the window, using a zero derived from the current
finite observation. Nonfinite observations still have no recovery policy.

EMA and RMA share the same seeded state machine. Both emit their first mean
at input index `period-1`. EMA then uses alpha `2/(period+1)`; Wilder/RMA uses
`1/period`. Both advance `previous + alpha*(price-previous)`, and period 1
returns the input directly. `init`, `next` and `batch` are available for RMA as
for EMA. Core coefficient initialization is internal to validated adapters.

The seed sums differences from its first observation, then adds that origin
back after division. Large constant finite prices can therefore seed without
first summing several copies of that large price. This changes some rounding
from the original raw-sum seed; it does not establish TA-Lib double/FMA parity.
The centered sum and later recurrence can still overflow for extreme spreads.

## Extrema and population moments

`Extrema.next` and `Moments.next` use `Window.State()` from `Window.init`.
They insert one value and return a result only once the window is full.
`Extrema.read` and `Moments.read` inspect the current window without insertion.
To inspect both, push **once**, then thread the returned state through both
reads. Calling both `next` methods would insert the observation twice.

Extrema emits `{low, high}`. Moments emits `{mean, variance}` with population
variance, divided by the period. `Moments.stddev` derives the square root when
needed, so the generic moments core does not require a square-root operation.
Period 1 emits the sample's numerical mean and zero variance.

Each general-window read uses fresh O(period) scans and O(period) stored
samples. `Extrema.read/next` accepts an arbitrary Window and retains that scan.
Moments uses a recent observation as an origin,
computes the average difference, and squares centered differences in a second
pass. It does **not** square distances from the rounded emitted mean: that
would lose accuracy when the mean itself is unrepresentable in F32.

Fresh scans avoid historical removal drift and restore exact zero on a constant
window after an outlier leaves. Finite-window rounding, cancellation in the
returned mean, input quantization and overflow/underflow remain possible.
There is no universal error bound or correctly-rounded-mean guarantee.

## Bars and candle settings

[`Bar`](../src/core/bar.bend) supplies `HL`, `HLC`, `HLV`, `OHLC` and `OHLCV` records,
range/true-range and candle body, individual/combined shadows, color and gap
helpers. Gap predicates are strict; reverse the bar arguments for the opposite
direction. Equal open/close is the upward candle color, matching the reference
convention. `true_range(previousClose, bar)` requires a previous close; the
caller owns first-bar warm-up.

The numeric input contract remains finite observations in arrival order. Bars
must have consistent high/low bounds. F32 `Bar.valid` checks finiteness and
whether open/close lie within low..high; `is_finite` is also available for scalar
input. These checks are explicit, not silently applied or used to skip bars.
Negative prices are not automatically rejected. Volume validation belongs to a
volume indicator's input contract.

[`Candle`](../src/core/candle.bend) supplies immutable settings and one threshold
state per setting. `Candle.init(setting)` accepts a range kind, averaging period
and finite nonnegative factor. Errors distinguish `InvalidPeriod` from
`InvalidFactor` through `Candle.Error()`; the existing indicator `Error()` stays
unchanged. Period 0 is valid here and uses the current bar's range.

`Candle.next` returns the threshold for the current bar. With a positive period,
it averages the preceding ranges, excludes the current bar, and first emits at
index `period`. Multiply by the factor, then divide by two for combined shadows.
With period 0, apply that factor/range rule to the current bar immediately.
A zero factor gives a real zero threshold once ready.

`Candle.defaults(name)` provides the eleven reference settings: BodyLong,
BodyVeryLong, BodyShort, BodyDoji, ShadowLong, ShadowVeryLong, ShadowShort,
ShadowVeryShort, Near, Far and Equal. The defaults follow the
[pinned TA-Lib settings table](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/src/ta_common/ta_global.c).
Settings are per state, with no mutable global table. A pattern inspecting an
older candle must retain that candle's aligned threshold, for example using a
generic window; it must not substitute today's threshold. These primitives now
support the [candlestick recognizers](candles.md). Hikkake adds a specialized
confirmation state while reusing the aligned Near threshold.

## Extension discipline

Keep concrete numeric bindings in the facade and shared algorithms in core.
Use leading `~` arguments only for numeric types/operations and reducers;
periods, settings and data remain runtime arguments. The two-field numeric
adapter fixture exercises new window/moments code without claiming F64 support.

Specialized modules add order statistics, covariance/regression, Hilbert and
adaptive filters, dynamic MA banks and confirmation states. Monotonic extrema
queues now serve indicator-specific extrema state. The general Window-based
`Extrema.read/next` interface retains its fresh scan, because it accepts arbitrary
shared rolling windows. Costs are explicit in the family guides. Reference
compatibility needs pinned seeds, unstable settings, arithmetic policy,
boundaries and meaningful numerical fixtures.
Use compact tests through these interfaces; temporary numerical matrices and
mutations need not become permanent suites.

The [direct indicator guide](direct-indicators.md) documents the math,
bar, cumulative and lagged interfaces built on this foundation.
