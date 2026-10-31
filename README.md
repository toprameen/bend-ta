# bend-ta

Technical analysis for Bend 2, with one shared template core and a typed F32
interface. SMA, EMA, Wilder/RMA and rolling SUM are available, together with shared
window, moments, extrema and candle-setting primitives. The catalog's original
32 Direct functions and all 155 original Foundation entries now have F32 interfaces.
MA, MAMA and VIDYA complete their needed dependencies: 192 catalog functions
are implemented under the documented F32 contracts. See the
[family guide](docs/foundation-indicators.md) and [Direct guide](docs/direct-indicators.md).

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
docs/foundation.md       shared windows, traversal, statistics and candle settings
scripts/                 Bend test runner and source-policy gate
```

## Use

Import `src/f32.bend` by a relative path from your program:

```bend
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

All project-maintained program logic is Bend. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the source policy and contribution workflow.

Use Bend 2.0.39, Git, Clang and the standard Unix utilities `find`, `mktemp` and
`rm`. macOS and Linux are supported. Node or Bun is needed only for optional
JavaScript-backend tests; there are no npm dependencies.

```sh
bend scripts/check_repo.bend    # enforce the source policy and type-check Bend
bend scripts/test.bend          # compile and execute native tests
bend scripts/test.bend -- --js  # also test emitted JavaScript
```

If needed, invoke Bend by its executable path and set `BEND` to the same path
for child compilations. `BEND_JS` selects the JS executable (default: `node`).
The runner discovers fixtures through Git, including non-ignored untracked files,
and removes its temporary outputs after ordinary success or failure. Every Bend
test and example ends in `#|` lines defining its expected stdout.

CI installs the pinned Bend release, runs the policy gate and executes both
backends. GitHub's language badge is independent of this source policy.

## Precision and next steps

F32 calculations round at each operation. Rolling sums can drift, seed sums can
overflow, and sufficiently small price changes can be lost. These fixtures test
the initial contracts; they do not establish TA-Lib parity or universal error
bounds. Rebuilding the state starts a fresh calculation.

The shared core takes numeric operations as compile-time `~` arguments. An F64
facade can bind a wider numeric implementation without copying indicators.
There is no F64 implementation or dependency in this scaffold. See
[the design](docs/design.md) for that seam and [the implemented indicator families](docs/foundation-indicators.md).

See [the shared foundation](docs/foundation.md) for the new interfaces, ownership,
complexity and numerical limits. The permanent suite uses compact family fixtures, with the shared contracts
exercised on both backends. Broad numerical matrices remain external.

The repository is private and is not published to BendHub. An open-source
license has not been selected.
