# bend-ta

Technical analysis written in Bend, with F32 interfaces for streaming and batch
calculations. Numeric algorithms share a template core; callers use named,
typed indicator interfaces.

## Use

Import `src/f32.bend` by a relative path from your program:

```bend
import Base
import ./src/f32.bend as TA

def averages() -> Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>:
  TA.SMA.batch([3.0, 6.0, 9.0, 12.0], 3)
```

The result is `Done{[None{}, None{}, Some{6.0}, Some{9.0}]}`. SMA emits its first
mean once the window is full; `Fail` reports an invalid period.

Run the [moving-average example](examples/moving_averages.bend) from the repository root:

```sh
bend examples/moving_averages.bend
```

Stateful indicators expose `init`, `next` and `batch`. Initialize a state, then
pass each observation to `next` with the state returned by the previous call.
Batch calculations use the same transitions and retain one output slot per
observation. `None` denotes warm-up; its duration depends on the indicator.
Stateless transforms operate directly on observations.
Use `lookback` to query startup alignment, `clone` to branch a state, and
`preview` to inspect one update without committing it; see the
[state guide](docs/state.md) for ownership and cost.

## Indicator reference

The [function catalog](docs/ta-lib-indicator-catalog.md) records implementation
status, parameters and reference sources. The [F32 interface](src/f32.bend)
defines the callable functions and result types.

| Family | Guide |
|---|---|
| Math, price transforms and lagged changes | [Functions and numerical conventions](docs/direct-indicators.md) |
| Moving averages, bands and statistics | [Seeds, windows and multi-line results](docs/overlap-statistics.md) |
| Momentum and directional indicators | [Parameters and output alignment](docs/momentum.md) |
| Volume and volatility | [Bar inputs and accumulation](docs/volume-volatility.md) |
| Adaptive trend and oscillators | [State machines and composite seeds](docs/advanced-trend.md) |
| Cycles and recursive filters | [Startup and precision limits](docs/cycles-filters.md) |
| Causal, dynamic and anchored indicators | [Confirmation, display offsets and period banks](docs/causal-indicators.md) |
| Candlestick patterns | [Settings and signed strengths](docs/candles.md) |

## Data and arithmetic

Supply finite observations in arrival order and align fields before constructing
bar records. Handle missing data, timestamps, sessions and price adjustments
before calculation. Nonfinite input validation and recovery are the caller's
responsibility; VWAP defines an explicit skip-and-repeat rule in its
[contract](docs/causal-indicators.md).

F32 arithmetic rounds at each operation and can overflow or lose small changes.
The family guides specify seeds, lookbacks, parameter limits, computational costs
and numerical differences from TA-Lib. Consult those contracts when choosing
an indicator or comparing results with another implementation.

## Develop

All library code, tests and tooling are Bend. See
[CONTRIBUTING.md](CONTRIBUTING.md) for toolchain requirements, the source policy
and the contribution workflow. Run checks from the repository root:

```sh
bend scripts/check_repo.bend    # enforce the source policy and type-check Bend
bend scripts/test.bend          # compile and execute native tests
bend scripts/test.bend -- --js  # also test emitted JavaScript
```

The [design guide](docs/design.md) explains numeric templates and typed bindings;
the [shared foundation](docs/foundation.md) describes windows, ownership and
stream traversal. Keep algorithms in `src/core/` and concrete numeric bindings
in `src/f32.bend`.

For repeatable performance measurements, see the [rolling benchmarks](benchmarks/README.md).

See [third-party notices](THIRD_PARTY_NOTICES.md) for reference-source attribution.
