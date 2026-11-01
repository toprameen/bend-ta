# Library design

## Shared numeric code

Core templates receive a numeric `~N: Data` and only the operations they need.
For example, an EMA update receives `~add`, `~sub` and `~mul`. Concrete numeric
types and operations are closed template arguments; periods and data remain
ordinary runtime arguments. This creates a compiled specialization for each
numeric implementation without generating a new version for every period.

The F32 facade binds Base operations and names concrete state types. Callers
do not pass templates or buffer sizes. Explicit compile-time function arguments
are intentional: passing operation records to ordinary field-access helpers
can retain record creation and indirect function calls in emitted code.

Generic code constructs constants through `from_u32`. It must not silently
introduce F32 literals or convert a wider value through F32. New capabilities,
such as comparison, square root or logarithm, belong only on templates that
need them. Floating-point addition is not associative; do not require algebraic
field laws to instantiate an indicator.

## State and output contracts

`src/f32.bend` supplies the following interface for both `EMA` and `SMA`:

| Operation | Contract |
|---|---|
| `init(period)` | Returns `Fail` for an invalid period, otherwise `Done{state}`. |
| `next(state, price)` | Returns `(next_state, Maybe<F32>)`; use the returned state for the next sample. |
| `batch(prices, period)` | Validates the period, initializes state and applies the same `next` operation to each input. |

State type names are `EMA.State()` and `SMA.State()`. Error type `Error()` is
the shared configuration error. Internally it has one constructor,
`InvalidPeriod{}` in `src/core/config.bend`.

Output alignment is positional: no timestamps are synthesized or dropped.
Each input produces one slot. `None` means that the initial window is incomplete,
not that a market bar is missing. Period 1 returns each input immediately; EMA
uses a direct identity path to avoid cancellation in the general update formula.
An empty valid batch is empty, and a batch shorter than the period is all `None`.

EMA uses an SMA seed at sample `period` (accumulated as centered differences), then
`value + alpha * (price - value)`, with `alpha = 2 / (period + 1)`.
SMA emits its rolling sum divided by the period once the window is complete.
The first complete window is included in both outputs.

## Owned rolling storage

SMA owns an array whose capacity is the next power of two at least as large as
the requested period. The write position wraps at the logical period, so the
unused capacity does not extend the window. Reads and writes preserve ownership;
the implementation does not use shared arrays or `@unsafe`.

Configuration permits periods 1 through 2^30. The depth calculation is bounded
and does not allocate; SMA allocates only after validation. The limit reserves
space in Bend's block-class range for a future two-word numeric representation.
It is a representation limit, not a promise that such a buffer fits in RAM.
Core initialization helpers assume the facade has validated configuration.
Buffer depth uses Base's integer log2 of `2*period-1`; the validated upper bound
keeps that calculation within U32.

EMA has constant-size state. SMA uses O(period) storage. EMA performs fixed numeric work per sample. SMA rebuilds its rolling total
once per logical period: amortized work is constant, with O(period) work at
that refresh. Batch traversal and output storage are O(n).
No throughput or GPU-speedup claim is made.

## Numeric and data policy

The initial interface assumes finite prices in arrival order. It neither sorts
bars nor adjusts for splits, timestamps or sessions. NaN and infinity generally propagate through Base arithmetic. Individual
source-defined holds and VWAP's skip-and-repeat behavior are specified in the
family contracts. Do not use `None` to represent those values implicitly.

F32 seed sums can overflow, a rolling sum can accumulate rounding error, and
an EMA's intermediate subtraction can overflow for extreme inputs. The shared
foundation adds centered fresh-window moments; the rolling sum now
rebuilds at each logical wrap, while remaining uncompensated. Reference fixtures and state/ownership checks do not establish comprehensive
financial-data conformance or proven numerical error bounds.

## F64 and additional indicators

Keep the same core and add a typed facade when a suitable F64 backend is chosen.
Native F64 is not available in the tested Bend version. A software F64 adapter
would be named `f64_soft.bend` so its cost is explicit; it should remain optional.
Different imported numeric types are not automatically interchangeable.

Wilder smoothing, rolling extrema, RSI, MACD and Bollinger Bands are now
implemented; see the [family guide](foundation-indicators.md). Further
extensions must specify seeds, warm-up and output alignment, and add a working
implementation with independent reference examples. Specialized filters and dynamic-period interfaces have separate family guides;
additional numeric backends require their own implementation and validation.

The two-field numeric wrapper in `tests/core/templates.bend` tests shared code
and array layouts with a representation different from F32. It is a test adapter,
not an implementation or accuracy claim for F64. Future numeric facades should
run common contract cases plus precision-specific numerical reference vectors.

## Shared foundation

See [foundation.md](foundation.md) for generalized input/output traversal and
state-preserving scans, owned windows/lags, rolling sums, Wilder smoothing,
fresh-window extrema/population moments, and typed bar/candle-setting interfaces.
These primitives support the catalog's F32 interfaces. Additional numeric
facades and universal TA-Lib compatibility require separate validation.
