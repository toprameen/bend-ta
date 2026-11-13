# Rolling-window benchmarks

Use the same Bend compiler, machine and runtime for both versions. Compile once;
compiler startup is outside the measurement:

```sh
bend benchmarks/rolling.bend -o /tmp/bend-ta-rolling
/tmp/bend-ta-rolling 1 256 100000 0
bend benchmarks/rolling.bend -o /tmp/bend-ta-rolling.js
node /tmp/bend-ta-rolling.js 1 256 100000 0
```

Arguments are indicator kind, period, sample count and input shape. Periods are
2..100000. A sample count smaller than the period measures initialization and
warm-up without a completed window; zero measures the empty case.

| Kind | Indicator |
|---:|---|
| 0 | MAX |
| 1 | MINMAXINDEX |
| 2 | DONCHIAN |
| 3 | AROON |
| 4 | STOCHF, D period 3 and SMA selector |
| 5 | WMA |
| 6 | MA with SMA selector |
| 7 | EMV, divisor 1 |
| 8 | ROGERSSATCHELL, annualization 252 |
| 9 | TRIMA |
| 10 | KAMA |
| 11 | HMA |
| 12 | DPO |
| 13 | RVOL |
| 14 | ACCBANDS |
| 15 | WAVETREND, channel 10 and average 21 |
| 16 | SQZMOM, both periods equal, factors 2/1.5/1 |
| 17 | LINEARREG |
| 18..25 | MAVP kinds 0/2/5/6/9/12/14/15, minimum 2 |
| 26 | VAR, legacy deviation argument 1 |
| 27 | STDDEV, factor 1 |
| 28..30 | BBANDS/BBW/PERCENTB, factors 2/2 and SMA selector |
| 31..32 | RVI/RVIR, smoothing period 14 |
| 33..34 | CORREL/BETA, second series offset by seven observations |

Shapes are deterministic varied prices (0), ascending prices (1), constant
prices (2), and alternating prices (3). Bar fields are generated consistently
from each price. The varied sequence uses wrapping U32 arithmetic and prices
on a bounded grid; these synthetic workloads do not represent every market
series. CORREL also accepts exact orthogonal ±1 axes (shape 4) and the
same axes scaled by 1e-20 (shape 5), exposing covariance and tiny-energy fallback
costs. These shapes are restricted to CORREL.

The rolling MAVP cases select periods 2..64, clamped to the configured band;
their maximum must be at most 10000. For arbitrary bands and selectors cycling
through every period, use the dedicated benchmark:

```sh
bend benchmarks/mavp.bend -o /tmp/bend-ta-mavp
/tmp/bend-ta-mavp 2 2 256 20000
bend benchmarks/mavp.bend -o /tmp/bend-ta-mavp.js
node /tmp/bend-ta-mavp.js 2 2 256 20000
```

Its arguments are MA kind, minimum, maximum and sample count. Its CSV layout
replaces the rolling benchmark's first four fields with those four arguments.
It warms `min(samples, lookback(maximum,kind)+1024)` observations and uses the
same timed initialization/update/checksum/release method.

One untimed history of `min(samples, period+1024)` observations warms the code.
The measured run then initializes fresh state and applies `next` to every
observation. Every output slot contributes to a checksum; no output list is
retained. Timing includes input generation, state initialization, updates,
checksumming and state release. There are no parallel calls or GPU requests.

The single CSV output row contains:

```text
kind,period,samples,shape,elapsed_ms,ready,checksum,warm_ready,warm_checksum
```

`IO.now` has integer-millisecond resolution. Lengthen a workload when timing
falls near that resolution; do not infer precise ratios from zero/one-ms rows.
Checksums consume results and detect differences in this workload; they do not
replace exact correctness tests.

For a comparison, use an unchanged baseline checkout and copy only this same
benchmark source into its `benchmarks/` directory. Compile both versions, repeat
each case, alternate before/after execution order, and compare output counts and
checksums as well as timing. Arithmetic reordering can legitimately change F32
bit checksums; record both and validate numerical changes independently. Within
a variant, identical arguments must reproduce the checksum. Keep builds, tests and other benchmarks idle during
measurement. Report the compiler, runtime, hardware, repetitions and timing
spread. Performance measurements are manual evidence, not CI timing thresholds.

## Recorded comparisons

| Workload | Baseline | Measurements | Metadata |
|---|---|---|---|
| Extrema queues and mean-only scans | `47efbd08018b99ec43c4b0378d59cc66b489172d` | [CSV](results/rolling-2026-11-01.csv) | [JSON](results/rolling-2026-11-01.json) |
| Rolling averages, regression and MAVP | `a97592ff46be2cb0f73d12e2224a6f4c8de4fa9a` | [CSV](results/rolling-2026-11-02.csv) | [JSON](results/rolling-2026-11-02.json) |
| Rolling variance and paired statistics | `e881503b6baeceb2d6f6797a7dc428d3a250c3de` | [CSV](results/statistics-2026-11-02.csv) | [JSON](results/statistics-2026-11-02.json) |

The results include short windows and fallback cases where the optimized path
can cost more. The extrema metadata also records peak native memory and an
isolated control build. The [MAVP capacity model](results/mavp-capacity-2026-11-02.json)
counts raw price slots for shared and independent windows.
