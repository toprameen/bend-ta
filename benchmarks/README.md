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

Shapes are deterministic varied prices (0), ascending prices (1), constant
prices (2), and alternating prices (3). Bar fields are generated consistently
from each price. The varied sequence uses wrapping U32 arithmetic and prices
on a bounded grid; these synthetic workloads do not represent every market
series.

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
checksums as well as timing. Keep builds, tests and other benchmarks idle during
measurement. Report the compiler, runtime, hardware, repetitions and timing
spread. Performance measurements are manual evidence, not CI timing thresholds.

## Recorded comparison

The [2026-11-01 measurements](results/rolling-2026-11-01.csv) compare baseline
`7c66197abf62448439874f64924b5f3afd57cc68` with monotonic extrema queues
and mean-only EMV/Rogers–Satchell calculations.
[Metadata](results/rolling-2026-11-01.json) pins the implementation source hashes
and environment. Native and JS use different sample counts where recorded;
each before/after pair uses identical arguments and consumes identical results.

Representative medians in milliseconds (shape 0):

| Backend | Indicator | Period | Samples | Before | After |
|---|---|---:|---:|---:|---:|
| native | MINMAXINDEX | 256 | 100000 | 917 | 11 |
| native | DONCHIAN | 4096 | 100000 | 14352 | 11 |
| native | STOCHF | 256 | 100000 | 1028 | 40 |
| native | EMV | 511 | 40000 | 1307 | 694 |
| js | MINMAXINDEX | 256 | 50000 | 551 | 16 |
| js | DONCHIAN | 4096 | 25000 | 2989 | 20 |
| js | STOCHF | 256 | 50000 | 561 | 59 |
| js | ROGERSSATCHELL | 511 | 20000 | 773 | 375 |

The comparison covers 68 cases and 504 process measurements across varied,
rising, constant and alternating inputs, including short histories and scan
controls. The CSV summarizes medians, repetitions and min/max spread. The tested
environment was an Apple M3 Max with 64 GiB RAM, macOS 27.0.1, Bend 2.0.39 and
Node 25.8.2.

Queued extrema retain only candidates that can still become the window's low
or high. Each observation enters once and leaves at most once per queue. The
amortized update cost is constant, with a possible O(period) prune burst on one
observation. Two owned power-of-two buffers retain O(period) storage. Their
payload is larger than the former single scalar window: the F32 pair stores
32 bytes per physical capacity slot, versus 4 bytes for the former scalar
buffer in the tested native backend. This trades storage for update speed.

At period 100000 and 100003 observations, native peak process RSS was 5.64 to
7.64 MiB for MINMAXINDEX, and 7.14 to 7.64 MiB for DONCHIAN. These are medians
of three alternating-order pairs on rising and constant inputs, measured with
macOS `time -l`; they include the runtime, allocator and both histories.
Short-history startup also costs more: at period 100000 with only 1000 samples,
JS took 3 ms after versus 0–1 ms before. See the CSV for individual timings;
ratios at this clock resolution are not meaningful.

Equal-value selection remains indicator-specific. Indexed extrema and momentum
windows choose the latest equal low/high; channels and midpoint calculations
retain the latest equal low and earliest equal high, including signed zero.
Cyclic slot tags avoid introducing a new stream-length limit for nonindexed
indicators. The existing indexed-extrema U32 horizon remains unchanged.

Mean-only calculations remove a discarded variance pass while retaining the
same centered mean arithmetic. General window traversal is unchanged. Other
mean, variance, regression, weighted and order-statistic windows retain their
documented scan/sort costs.
These measurements establish no general speedup or GPU performance guarantee.

The combined native benchmark's unchanged WMA and MA-SMA controls were about
7–8% slower; JS controls were approximately unchanged. A restricted control
build checks whether this is tied to the combined program rather than the
unchanged traversal source: its medians differed by less than 1%, with
overlapping ranges. Results are recorded in the metadata. Compiler
specialization/dispatch ordering differs between generated programs, so these
measurements do not establish a general slowdown for either library function.
The combined-program regression remains part of the reported results.

A scan-cursor variant gave no established benefit and was excluded; general
Window traversal matches the baseline. A split-array queue layout halved F32
payload but was slower in its coarse screen; the retained entry layout favors
update speed. These rejected variants are outside the measured implementation.
