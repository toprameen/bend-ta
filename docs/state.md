# State, preview and lookbacks

Import the [F32 facade](../src/f32.bend) as `TA`. Pass the state returned by
each update into the next call. Batch applies the same updates in input order.

## Lookbacks

`NAME.lookback` accepts the same parameters as `NAME.init` and returns
`TA.Lookback.Result()`, either `Done{count}` or `Fail{InvalidParameter{}}`.
Queries validate parameters without allocating state. Stateless transforms
have a parameterless lookback of `Done{0}`.

The count is the number of initial `None` slots and the zero-based index of the
first ready output. `TA.SMA.lookback(3)` returns `Done{2}`. The third
observation produces the first mean. Recursive indicators can continue to
depend on earlier observations after warm-up.

Count valid observations supplied to the indicator. A lookback of zero means
the first observation produces an output. See the family guides for seeds and
confirmation delays.

MA warm-up depends on the kind and period. MAVP uses the lookback for its
maximum configured period even when an observation selects a shorter one.

Named candle queries use default settings. For custom settings,
`TA.Pattern.lookback.checked(name, settings, penetration)` validates custom
settings. Use `TA.Pattern.lookback(name, settings)` with already validated
settings. `TA.CDLHIKKAKEMOD.lookback.setting(near)` accepts a custom Near setting.

## Clone

`NAME.clone(state)` returns `(original, copy)` at the same point in the stream.
Both states can advance independently. Cloning copies buffers, counters,
recursive values, and caches directly.

For a period-three SMA that has consumed `[3.0, 6.0]`, cloning and advancing one
branch with `9.0` yields `6.0`. Advancing the other branch with `12.0` yields
`7.0`; neither branch alters the other.

Scalar state has constant clone cost. For buffered state, time and memory
scale with allocated storage, including unused buffer capacity, nested states,
and MAVP period banks.

## Preview

`NAME.preview(state, observation)` returns `(original, output)`. It clones
the state, runs one `next` on the copy, and discards the advanced copy.

For the SMA above, previewing `9.0` produces `Some{6.0}`. A subsequent real
`next` with `12.0` still produces `Some{7.0}`. Preview uses the same input
contract and optional outputs as `next`.

A preview costs a clone plus one update. For several speculative updates,
clone once and advance that branch with `next`.
