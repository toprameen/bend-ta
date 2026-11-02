# State, preview and lookbacks

Import `src/f32.bend` as `TA`. Each named stateful indicator provides `init`,
`next`, `clone`, `preview` and `batch`; stateless transforms operate directly
on observations. Operations consume owned state and return the state to use
next. Batch and streaming calculations use the same transitions.

## Lookbacks

`NAME.lookback` accepts the same parameters as `NAME.init` and returns
`TA.Lookback.Result()`: `Done{count}` or `Fail{InvalidParameter{}}`.
A stateless transform accepts no lookback parameters and returns `Done{0}`.
Queries validate parameters without allocating indicator state or rolling buffers.
The initialization functions retain their existing error types.

The count is the number of initial `None` outputs, equivalently the zero-based
index of the first ready output. For example, `TA.SMA.lookback(3)` returns
`Done{2}`: samples one and two are `None`, and sample three is the first mean.
Obtaining that first output therefore takes `count + 1` observations. This is
startup alignment, not a statement that a recursive indicator forgets older
observations after that many samples.

The count assumes valid observations in arrival order under the indicator's
input contract. It does not account for caller-filtered missing bars or guarantee
finite arithmetic. Zero can mean an immediate value, including a source-defined
startup zero. Consult family guides for seeds and confirmation delays.

Moving-average selectors affect the count. For instance, a cascade takes longer
to seed than a plain average. MAVP uses the common lookback for its maximum
configured period, even when an input selects a shorter period.

Named candle queries use default settings. For custom settings,
`TA.Pattern.lookback.checked(name, settings, penetration)` validates settings and
returns the common result type. The existing raw
`TA.Pattern.lookback(name, settings)` remains available for already validated
settings. `TA.CDLHIKKAKEMOD.lookback.setting(near)` queries its custom setting.

## Clone

`NAME.clone(state)` returns `(original, copy)`. Both states start at the same
point and can advance independently. It copies every owned buffer, including
unused physical capacity, as well as warm-up counters, recursive values and
cached rolling aggregates. It does not replay an input history.

For a period-three SMA that has consumed `[3.0, 6.0]`, cloning and advancing one
branch with `9.0` yields `6.0`. Advancing the other branch with `12.0` yields
`7.0`; neither branch alters the other.

Copying scalar state has constant cost. Copying owned state costs time and
additional memory proportional to all its allocated storage. This includes
power-of-two buffer capacity, nested indicator states and MAVP period-bank
storage where applicable. The copy must be retained or discarded like any
other owned Bend value.

## Preview

`NAME.preview(state, observation)` returns `(original, output)`. It clones the
state, performs one ordinary `next` on the copy, discards that speculative state
and returns the original unchanged. Repeated previews therefore do not advance
warm-up, history, counters or recursive values.

For the SMA above, previewing `9.0` produces `Some{6.0}`. A subsequent real
`next` with `12.0` still produces `Some{7.0}`. During warm-up, preview can return
`None` just as `next` does. Structured inputs and outputs use exactly the same
types as the corresponding `next` operation.

A preview costs a clone plus one update. For frequent committed updates use
`next`; for several speculative updates clone once and advance the resulting
branch. Preview does not validate observations beyond the indicator's ordinary
input policy. Supply finite, aligned observations as described in the README
and family guides.
