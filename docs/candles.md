# Candlestick recognizers

Named candle recognizers are exposed through `src/f32.bend`. Each named `CDL*.State()` is an owned pattern state.
`CDL*.init()` returns `Result<Pattern.Error(), State()>`; `CDL*.next(state, bar)`
returns `(state, Maybe<Pattern.Signal()>)`; `CDL*.batch(bars)` returns a result
containing one output slot per input. Bars use `Bar.OHLC<F32>` from
`src/core/bar.bend`. Batch and streaming use the same transition.

Seven names require a runtime penetration argument in `init(penetration)` and
`batch(bars, penetration)`:

| Names | Pinned reference default |
|---|---:|
| CDLABANDONEDBABY, CDLEVENINGDOJISTAR, CDLEVENINGSTAR, CDLMORNINGDOJISTAR, CDLMORNINGSTAR | 0.3 |
| CDLDARKCLOUDCOVER, CDLMATHOLD | 0.5 |

Penetration must be finite and nonnegative; values above one are accepted. These
functions require the caller to choose the value explicitly. The remaining
named initializers take no arguments.

`None` represents the pinned lookback, including the extra initial bars required
by ENGULFING and 3OUTSIDE. Ready output is always `Some{signal}`, including a
zero signal. `Patterns.Signal{negative, strength}` is an exact signed integer
representation: zero is `{False{}, 0}`, ordinary detections have magnitude 100,
and the reference's matching-endpoint ENGULFING/HARAMI/HARAMICROSS detections
have magnitude 80. Hikkake confirmation has magnitude 200. `TA.Pattern.show(signal)` formats the signed decimal value.
Bend 2.0.39 does not supply a native signed integer type. Direction and strength
are not encoded as floating point.

## Shared state and settings

Import `src/core/patterns.bend` for `Name` constructors such as `CDLDOJI{}`.
The shared F32 interface is:

| Operation | Contract |
|---|---|
| `Pattern.defaults()` | Eleven immutable reference settings. |
| `Pattern.setting(settings, candleName, replacement)` | Returns settings with one replacement; consumes no mutable global table. |
| `Pattern.lookback(patternName, settings)` | Number of initial `None` slots for those settings. |
| `Pattern.init(patternName, settings, penetration)` | Validates all settings and penetration before allocating owned buffers. |
| `Pattern.next(state, bar)` | Advances one aligned bar. |
| `Pattern.batch(bars, patternName, settings, penetration)` | Validates and runs the same transition over all bars. |

A replacement uses `Candle.Setting{kind, period, factor}` and names/range kinds
from `src/core/candle.bend`. Periods are 0 through 2^30; factors must be finite
and nonnegative. Any invalid configuration returns `InvalidParameter{}` from
`src/core/parameters.bend`, including for an empty batch. The original
indicator configuration error remains unchanged. A valid empty batch is empty.
Inputs are finite, consistent OHLC bars in arrival order; no missing-bar or
nonfinite recovery policy is applied.

One threshold state per setting is advanced for each bar. Positive periods use
preceding ranges; period zero uses the bar being evaluated. Four historical
frames retain each bar's own thresholds, so a multi-candle condition never
substitutes the latest threshold. TRISTAR deliberately compares all three
bodies against the first candle's threshold, as the pinned source specifies.
The generic core receives its numeric type and operations as leading template
arguments. Numeric settings and data remain runtime values.

Storage is O(sum of the eleven configured periods), plus four fixed history
frames. Rolling thresholds rebuild their totals at each logical wrap, giving
amortized constant work per input and worst-case work proportional to the
sum of periods when refreshes coincide. The static recognizer
states maintain all eleven settings. Large valid settings
still require enough memory for their buffers. Reinitialize to reset history.

## Hikkake confirmation state

`CDLHIKKAKE` and `CDLHIKKAKEMOD` use the specialized generic
`src/core/hikkake.bend` transition and the same signed `Pattern.Signal()`.
Their named interfaces expose `init`, `next` and `batch`; they are separate
from the static `Pattern.Name` dispatcher. Hikkake needs an inside bar followed
by a lower-high/lower-low bullish breakout, or a higher-high/higher-low bearish
breakout. Modified Hikkake needs two consecutive inside bars, plus the second
candle's close near its low for a bullish setup or near its high for a bearish
setup. Near uses that candle's own preceding threshold, delayed with the bar.

A new setup reports ±100 and replaces any outstanding setup. On the next
three bars, a close strictly above the saved last-inside high confirms a bullish
setup; a close strictly below its saved low confirms a bearish setup. The
confirming output is ±200 and clears the pending setup. A new setup takes
precedence over confirming the old one on the same bar. A tie at either saved
bound does not confirm; a later fourth bar cannot confirm an expired setup.

The first output indices are 5 for ordinary Hikkake and `max(1,Near.period)+5`
for modified Hikkake (10 with default Near). Detection and confirmation advance
during warm-up, so the first ready output may be a confirmation. Modified
Hikkake's `init.setting(near)` accepts an immutable `Candle.Setting<F32>` with
the ordinary candle-setting validation; `init()` selects default Near. Feed a
custom state through `next` or `Series.scan`. Period-zero Near uses the second
candle's own range. Ordinary Hikkake uses fixed history and confirmation state;
modified Hikkake additionally stores only its Near range window. No absolute
sample counter limits either confirmation state.

`tests/reference/hikkake.bend` contains pinned C examples of both signs,
warm-up confirmation, strict ties, expiry, custom period-zero Near and chunk
continuation. It uses `n` for warm-up, `z` for zero, `p`/`m` for ±100 and
`P`/`M` for ±200.

## Reference and numerical contract

Predicates, strict/non-strict ties, signs, strengths, penetration and lookbacks
follow [TA-Lib ccd3172940ed1d9daa4e7197f2265810852e8910](https://github.com/TA-Lib/ta-lib/tree/ccd3172940ed1d9daa4e7197f2265810852e8910/ta_codegen/input).
The shared rolling thresholds use F32 arithmetic, whereas the oracle uses
double precision. Quantization, rounding at threshold ties, overflow and
rolling-sum drift can change classifications. No universal classification or
bitwise parity guarantee is made. Body/shadow comparisons preserve the pinned
expression order, subject to the F32 operations supplied by the facade.

`tests/reference/candles.bend` contains C-oracle aligned vectors with a nonzero
case for every implemented name, both signs of strengths 80 and 100 for the
three matching-endpoint patterns, configuration checks and a streaming
continuation crossing the final recognition. The fixture uses `n` for warm-up,
`z` for zero, `p`/`m` for +100/-100, and `a`/`b` for +80/-80. Its inputs use
exact quarter-unit prices. The fixtures were produced externally from the
pinned C oracle; no external numerical tool is needed by repository checks.

## TA-Lib attribution

The recognizer predicates are derived from TA-Lib. The pinned source credits
Angelo Ciceri for the original recognizers and Mario Fortier and other listed
contributors for maintenance. Retain [the complete upstream license notice](../THIRD_PARTY_NOTICES.md)
with this derived implementation.
