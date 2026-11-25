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

The [moving averages example](examples/moving_averages.bend) shows batch and
single-observation streaming with `init` and `next`. Run it with
`bend examples/moving_averages.bend`.

`TA.Stream.scan` processes a chunk from an existing state and returns the
state for the next chunk. Both `scan` and `batch` return one output slot per
observation.

## Data and arithmetic

For ATR, build bars with `TA.Bar.hlc(high, low, close)`.
Supply finite observations in arrival order with aligned bar fields. Handle
missing data, timestamps, sessions, and price adjustments before calculation.
Near 1,000,000, adjacent F32 values are 0.0625 apart. Small price changes and
differences between rounded averages can disappear. Long-period smoothers can
settle slightly short of their target. Running totals lose precision as they
grow, and F32 arithmetic can overflow.

## Develop

See the [contributor guide](CONTRIBUTING.md) and [benchmarks](benchmarks/README.md).

## License

Original contributions to bend-ta are licensed under the
[Apache License 2.0](LICENSE). Portions adapted from TA-Lib retain their
BSD 3-Clause terms, included in [NOTICE](NOTICE).
