# bend-ta

F32 technical analysis in Bend for streaming and batch calculations.

## Use

Import the [F32 API](src/f32.bend) using a path relative to your Bend file.

```bend
import Base
import ./src/f32.bend as TA

def averages() -> Result<&2, &2, TA.Error(), List<&2, Maybe<&2, F32>>>:
  TA.SMA.batch([3.0, 6.0, 9.0, 12.0], 3)
```

The result is `Done{[None{}, None{}, Some{6.0}, Some{9.0}]}`. `None` marks
warm-up. An invalid period returns `Fail`.

Run `bend examples/moving_averages.bend` from the repository root.

Use `init` and `next` for streaming, passing the returned state into each
update. `batch` returns one slot per observation.

## Data and arithmetic

Supply finite observations in arrival order with aligned bar fields. Handle
missing data, timestamps, sessions, and price adjustments before calculation.
F32 arithmetic can overflow or round away small changes.

## Develop

See the [contributor guide](CONTRIBUTING.md) and [benchmarks](benchmarks/README.md).

## License

Original contributions to bend-ta are licensed under the
[Apache License 2.0](LICENSE). Portions adapted from TA-Lib retain their
BSD 3-Clause terms, included in [NOTICE](NOTICE).
