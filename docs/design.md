# Library design

## Shared numeric code

Core algorithms take `~N: Data` and the operations they use as closed template
arguments. The [F32 facade](../src/f32.bend) supplies Base operations and exposes
concrete state types. Periods, coefficients, and observations are runtime
arguments, so one specialization handles every period. Passing operation
records at runtime can retain allocations and indirect calls in emitted code.

Build numeric constants through `from_u32` to preserve the selected precision.
Keep capabilities such as square root and logarithm local to the templates
that use them. Account for floating-point rounding when rearranging formulas
or stating laws.

## State and output contracts

Batch and streaming share the same transition. Batch validates configuration
before traversal and retains one output slot per observation in input order.
An empty valid batch returns an empty result. See the [state guide](state.md)
for ownership and warm-up and [proof coverage](laws.md) for the checked contracts.

## Owned rolling storage

The [shared window](foundation.md#traversal-and-ownership) wraps at its logical
period and uses an owned power-of-two buffer. For periods 1 through 2^30,
`Config.depth` computes the integer log2 of `2*period-1` within U32. The upper
bound leaves room for two-word elements in Bend's block classes. Actual
allocation depends on available memory and follows validation.

## Numeric and data policy

Callers supply finite, ordered, aligned observations. The family guides cover
rounding, overflow, and indicator-specific behavior such as
[VWAP's skip rule](causal-indicators.md#volume-and-undefined-arithmetic).
`None` denotes warm-up. Numeric results can be nonfinite.

## Additional numeric types

Additional numeric facades should instantiate the same core and run shared
contract cases and precision-specific reference fixtures. The
[two-field test adapter](../tests/core/templates.bend) exercises shared
algorithms and array layouts with a second representation.
