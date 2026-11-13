# Math, price transforms and changes

The [F32 facade](../src/f32.bend) binds Base operations to the shared formulas
for math, price transforms, and lagged price changes.

## Stateless functions

These functions return one raw F32 value with no state or warm-up:

| Family | Functions | Input |
|---|---|---|
| Unary math | ACOS, ASIN, ATAN, CEIL, COS, COSH, EXP, FLOOR, LN, LOG10, SIN, SINH, SQRT, TAN, TANH | F32 |
| Paired arithmetic | ADD, SUB, MULT | `Transform.Operands<F32>{left, right}` |
| Price transforms | AVGPRICE, MEDPRICE, TYPPRICE, WCLPRICE | OHLC, HL, HLC, HLC respectively |
| Bar ratios | BOP, IBS, MARKETFI | OHLC, HLC, HLV respectively |

Import the [bar records](../src/core/bar.bend) and
[operand record](../src/core/transform.bend) when constructing inputs.
`Series.map(~I, ~O, ~transform, xs)` applies a closed stateless transform to a
list and preserves length/order, returning `List<O>`. Empty input is empty.
Paired values travel as one record; there is no parallel-array zip that could
silently truncate mismatched columns. Callers align their observations before
constructing the records.

The four price formulas follow the pinned source's operation order:

- AVGPRICE: `((high + low) + close + open) / 4`.
- MEDPRICE: `(high + low) / 2`.
- TYPPRICE: `((high + low) + close) / 3`.
- WCLPRICE: `((high + low) + close*2) / 4`.

BOP is `(close-open)/(high-low)`, with zero for a nonpositive range.
IBS is `(close-low)/(high-low)`, with 0.5 for a nonpositive range.
These are exact range comparisons, without an epsilon. IBS is not clamped when
close lies outside the bar. MARKETFI is `(high-low)/volume`, with zero only when
volume is exactly zero; tiny nonzero volume still divides. It is Bill Williams'
Market Facilitation Index, distinct from the [Money Flow Index](momentum.md) implemented as MFI.

Bar transforms do not implicitly call `Bar.valid`, skip observations or infer
sessions. The caller selects input validation. Arithmetic can overflow or
underflow even for finite input. Unary functions retain Base F32 domain behavior:
for example, SQRT of a negative number and LN of a negative number produce NaN,
LN(0) produces negative infinity, and EXP can overflow to infinity. These are
raw numeric results, not `None` or configuration errors. Angles are in radians;
CEIL/FLOOR remain numeric values and support negative inputs.

## Lagged changes

MOM, ROC, ROCP, ROCR and ROCR100 have `State()`, `init(period)`, `next(state,x)`
and `batch(xs,period)`. They share the owned window implementation, with one
window per stream. Initialization validates the period before allocation;
`next` returns the next state and a `Maybe<F32>`, and batch returns a Result with
aligned slots. Periods follow the foundation's 1..2^30 range, subject to memory,
rather than the reference's 100000 maximum; callers supply the period explicitly.

The first output is at zero-based index **period**, after period+1 observations.
The evicted observation is exactly period bars behind the current one. Empty
valid batches are empty, short batches are all `None`, and invalid periods fail.

| Function | Bend calculation after warm-up | Constant nonzero input |
|---|---|---:|
| MOM | current - previous | 0 |
| ROC | ((current - previous) / previous) * 100 | 0 |
| ROCP | (current - previous) / previous | 0 |
| ROCR | current / previous | 1 |
| ROCR100 | (current / previous) * 100 | 100 |

All four normalized variants return a real zero when the lagged observation is
exactly zero. MOM still returns the difference. Tiny nonzero denominators are
not suppressed. These functions do not add an unstable-period discard.

**Intentional ROC arithmetic difference:** pinned TA-Lib uses
`(current/previous - 1)*100` in double precision. Bend's F32 implementation uses
the difference-first form above to preserve small representable changes on a
large price baseline. For 1000000 followed by 1000000.0625, it retains a change
near 0.00000625%, whereas ratio-first F32 produces about 0.000011920929%.
This is an explicit rounding policy, not a claim of bit identity. As elsewhere,
very large opposite-sign spreads can overflow subtraction; F32 cannot recover
price differences already lost during input quantization.

## Cumulative sum and Wilder smoothing

CUMSUM has `init()` (zero), `next(state,x)` and `batch(xs)`. Its state is the
running F32 total. It emits immediately and uses plain left-to-right addition.
Every fresh batch starts at its supplied first observation; thread the returned
state through `Series.scan` to continue across chunks. Resetting is explicit.
Compensation, automatic session resets and protection against loss of small
increments on a large total are not supplied.

RMA uses the [shared Wilder smoother](foundation.md) with an SMA seed,
coefficient 1/period, and first output at index period-1. Period 1 returns each
input directly.

## Reference and validation scope

The implementation follows the TA-Lib revision recorded in [NOTICE](../NOTICE)
with the documented ROC arithmetic. The C reference build reports development
version 0.8.4.

The concise [transform fixture](../tests/reference/transforms.bend) covers every
stateless binding with nontrivial inputs, domain results, signed zero, guards
and typed mapping. The [change fixture](../tests/reference/changes.bend) covers
units, warm-up, zero denominators, small price changes, and CUMSUM continuation
versus reset. The existing numeric adapter also exercises generic lag/ratio and
bar-transform code with a two-field representation.

Broader reference comparisons run outside the checkout against the pinned C
library on the same F32-quantized inputs, with explicit tolerances and NaN/Inf
classification. Numeric-zero signs may differ from a particular reference
backend: the local reference TAN(-0) returned +0 while Base F32 retained -0.
