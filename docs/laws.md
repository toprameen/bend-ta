# Proof contracts

`LAWS.bend` states the maintained contracts. `PROOF.bend` completes them using
the checked lemmas and reference models in `proofs/`. Runtime imports remain
independent of these files. Numerical tests and benchmarks complement the proofs.

| Contract | Meaning |
|---|---|
| Series alignment | Generic map and scan retain one output slot per observation. |
| Ordered traversal | Map preserves transformation order; scan preserves chronological updates, optional outputs and final owned state. |
| Batch and chunks | Batch agrees with the independent scan model; successive chunks agree with a continuous scan, including final state. Public SMA/EMA batch contracts bind successful initialization and their named `next` functions. |
| Window history | Histories replayed through actual initialization and pushes retain the latest period's observations; lag reads preserve state and pushes return the correct oldest eviction. |
| Clone | Arrays and shared windows preserve contents and metadata. Named EMA, SMA, VAR, CORREL and BETA clones also preserve their complete state, including scalar and paired rolling caches. |
| Preview | For the named clone families, if `next` returns a particular output, preview returns that output with the original state. |
| Configuration | SMA/EMA accept periods from 1 through 2^30, preserve the requested configuration and reject other periods. |
| Warm-up and lookback | SMA/EMA first emit after their reported initial warm-up; EMA's period-one startup and live updates return the input unchanged. |

The statements specify source-level behavior. Read their quantifiers,
preconditions and reference predicates for exact scope. A theorem about a shared
helper does not certify every facade binding automatically. Named clone/preview
coverage is explicit; other indicators retain their existing state tests.

The window history model takes observations newest first and replays the older
tail before each newer head. Its configuration requires a period from 1 through
2^30, depth below 32 and physical capacity `2^depth >= period`. These are raw
core configuration assumptions; the theorem does not prove the facade's depth
calculator satisfies that capacity condition. The internal state invariant is
proved from initialization and preserved by pushes, rather than supplied as an
unproven assumption about each update.

The ordered reference scan is a simple recursive specification. Its transition
decomposition and output projection are independent of production traversal
helpers. The chunk specification runs the actual first and second scans and
joins their chronological outputs. Length alone would not establish ordering,
correct values or correct final state.

The preview laws name the actual result of `next` through an equality premise.
That premise decomposes a total state transition; it does not assume preview
is correct. The conclusion directly specifies the original state and that output.
The SMA/EMA batch laws similarly name successful initialization and the reference
scan result. Configuration laws separately establish the accepted domain.

Warm-up proofs are generic over numeric operations and a Data-backed observation
sampler. They establish initial `None` slots followed by the first `Some`, without
requiring arithmetic identities about the returned value. They do not imply a
recursive indicator forgets earlier observations after its lookback.

Base F32 operations are opaque to Bend's checker. These laws do not establish
floating-point error bounds, TA-Lib numerical conformance, identical NaN payloads
across backends, allocation success or performance. Clone value preservation
works with Bend's affine ownership rules; it is not a separate proof of the
generated runtime's pointer behavior. Keep native/JavaScript reference tests,
edge cases and benchmarks.

The supporting list, natural-number and U32 facts come from
`bend-mathlib@0.8.1.0`. It is a proof-only dependency resolved by BendHub; the
runtime library continues to use Base directly. Repository-owned proofs and
checks are Bend.

Run these from the repository root:

```sh
bend scripts/check_repo.bend
bend PROOF.bend --verdict
bend scripts/test.bend -- --js
```

The policy gate requires both root files and checks their completed declarations
through `PROOF.bend`. It still scans `LAWS.bend` for forbidden foreign imports;
only its standalone type check is exempted. Other proof modules must be complete
and check independently. The compiler also rejects a sibling `PROOF.bend` that
does not import `LAWS.bend`.

Ordinary checking validates the Bend proof terms. `--verdict` additionally checks
their translation with BendTT's independent kernel. Its toolchain requirement is
documented in [CONTRIBUTING.md](../CONTRIBUTING.md). Kernel acceptance concerns the
translated source semantics; parser, translation and compiled backend correctness
are additional trust boundaries.

Treat law statements and their reference predicates as maintained specifications.
An implementation must satisfy them; changing their meaning or preconditions
requires an explicit maintainer decision. Check that a new law rejects a relevant
defect in a temporary copy. A passing proof establishes its statement, so review
the statement's meaning as carefully as its implementation.
