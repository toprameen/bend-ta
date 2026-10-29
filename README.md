# bend-ta

Technical analysis for Bend 2, with one shared template core and a typed F32
interface. This is an initial scaffold with working SMA and EMA calculations.

## Layout

```text
src/f32.bend              public F32 interface
src/core/config.bend      period validation and buffer sizing
src/core/series.bend      aligned batch output using streaming steps
src/core/rolling.bend     owned rolling-sum buffer
src/core/smoothing.bend   numeric smoothing formulas
src/core/ema.bend         generic EMA state and initialization
src/core/sma.bend         generic SMA state
examples/                runnable Bend programs
tests/                   reference, edge-case and template fixtures
docs/design.md           contracts and extension points, including F64
```

## Use

Import `src/f32.bend` by a relative path from your program:

```python
import Base
import ./src/f32.bend as TA

# A Result: invalid configuration is Fail; valid output is Done.
def averages() -> Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>:
  TA.SMA.batch([3.0, 6.0, 9.0, 12.0], 3)
```

That result is `Done{[None{}, None{}, Some{6.0}, Some{9.0}]}`.
Run the complete example with:

```sh
bend examples/moving_averages.bend
```

Both indicators expose `init(period)`, `next(state, price)` and
`batch(prices, period)`. A streaming `next` returns the next state beside a
`Maybe<F32>` output. Pass the returned state to the next call.

- Periods must be from 1 through 1,073,741,824. Invalid periods return `Fail`.
  Large SMA periods still require enough memory for their buffer.
- Every batch input has an output slot; the first `period - 1` slots are `None`.
- EMA starts with the first complete window's SMA, then uses
  `alpha = 2 / (period + 1)`. SMA starts with the first complete window's mean.
- Period 1 returns each input directly; EMA avoids cancellation in that case.
- A valid empty batch returns `Done{[]}`. A short batch contains only `None`.
- Inputs are assumed finite. NaN and infinity are not rejected, and no missing
  value or recovery policy is implemented yet.

## Develop

Use Bend 2.0.39 and Bun 1.4.2. Native tests also need the Clang version required
by your Bend installation. There are no npm package dependencies to install.

```sh
bun run test          # compile and run JavaScript
bun run test:native   # also compile and run native C
```

If Bend is not on PATH, set `BEND` to its executable path. The runner writes
generated files to a temporary directory and removes them afterwards. Every
Bend test and example ends in `#|` lines defining its expected stdout.

## Precision and next steps

F32 calculations round at each operation. Rolling sums can drift, seed sums can
overflow, and sufficiently small price changes can be lost. These fixtures test
the initial contracts; they do not establish TA-Lib parity or universal error
bounds. Rebuilding the state starts a fresh calculation.

The shared core takes numeric operations as compile-time `~` arguments. An F64
facade can bind a wider numeric implementation without copying indicators.
There is no F64 implementation or dependency in this scaffold. See
[the design](docs/design.md) for that seam and the planned RSI/MACD work.

The repository is private and is not published to BendHub. An open-source
license has not been selected.
