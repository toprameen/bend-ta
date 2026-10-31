# MAMA engine

`src/core/mama.bend` supplies the shared MESA adaptive moving average engine for
the moving-average selector and the F32 `MAMA` interface. Its constant-size
`State<N>` is `Data`, contains fixed delay records, and owns no arrays.

`MAMA.init(fast, slow)` validates finite F32 limits in 0.01 through 0.99 and
returns `Result<MAMA.Error(), MAMA.State()>`. Limits need not be ordered.
`MAMA.next(state, price)` returns the next state and `Maybe<MAMA.Value()>`.
`MAMA.batch(prices, fast, slow)` validates first and uses the same transition.
`MAMA.Error()` is `Parameters.Error` with `InvalidParameter{}`. A valid empty
batch is empty; invalid limits fail even for empty input.

The result constructor is `Mama.Value{mama, fama}` from the core module. The
usual limits are 0.5 and 0.05. The shared MA selector uses those values and
projects `mama`. The direct interface returns both lines. Inputs are assumed
finite, in arrival order; missing values and nonfinite recovery are not defined.

The fixed warm-up is 32 observations: indices 0 through 31 return `None`, and
index 32 is the first `Some{Value{...}}`. Price history advances immediately;
the Hilbert stages and zero-seeded adaptive averages begin at index 12. Four
six-sample delay filters replace the reference's odd/even circular buffers.
Period estimates retain the reference's guarded atan ratios, successive rate
and 6..50 clamps, and smoothing. No unstable-period extension is implemented.

The low-level generic interface is:

- `init(~N, ~from_u32, ~div, fast, slow) -> State<N>` assumes validated limits.
- `next(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~le, ~atan, state, price)` returns
  `(State<N>, Maybe<Value<N>>)`. Numeric capabilities are closed templates;
  prices and limits are runtime values.

## Arithmetic and reference evidence

Initialization and adaptive equations follow the pinned
[TA-Lib MAMA source](https://github.com/TA-Lib/ta-lib/blob/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input/mama/mama.c).
The engine makes two deliberate floating-point choices. Its four-price WMA is
computed freshly as centered differences from the newest price. Its Hilbert
FIR computes `a*(current-lag6) + b*(lag2-lag4)`, with a=0.0962 and b=0.5769,
before the period adjustment. These are algebraically equivalent to the
reference operations. Centering avoids rolling-WMA drift and cancellation of
separately weighted large baselines.

A direct F32 transcription of the source-ordered Hilbert sums produced a
spurious adaptive transient on a crossing-zero linear ramp; the difference
form removes that observed error. It is the library's arithmetic contract.
F32 quantization, phase sensitivity near zero, transcendental differences,
overflow and underflow can still change adaptive decisions. Universal error
bounds or TA-Lib bitwise parity are not claimed.

External comparisons against the pinned actual C oracle covered 30 cases and
5,400 aligned slots per backend, including zero, constants, a 1,000,000 baseline,
trends, crossing zero, oscillation, a shifted oscillation, alternation, impulse,
and varied prices at three limit pairs. Native and emitted JS matched bitwise
in that matrix. Maximum observed absolute error was below 0.000013 for ordinary
scales, 0.00551 for a 10,000 baseline oscillation, and 0.551 for a 1,000,000
constant. Those are measurements for these cases, not guarantees.

`tests/reference/mama.bend` checks pinned C values at seven positions on four
180-sample series, exact warm-up, a split-state continuation and configuration
boundaries. Tolerances are 0.000005 for constant 5, 0.00002 for the crossing-zero
ramp and cycle, and 0.01 for the shifted cycle. Fixtures require no external
oracle to run. The TA-Lib license and attribution retained in
[candles.md](candles.md#ta-lib-attribution) also cover this derived engine.
