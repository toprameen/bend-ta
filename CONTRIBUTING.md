# Contributing

## Bend-only source policy

Write all maintained program logic in Bend, including the library, examples,
tests, runner, and repository checks. Keep foreign code out of imports, data
files, workflow steps, and interpreter commands.

Markdown, declarative YAML/JSON, inert CSV/TSV/text data, and Git and license
metadata are allowed. CI may install pinned tools and run Bend commands.
Use Base effects and external tools such as Git, Clang, and Node as needed.
Keep generated output outside Git.

External tools may generate reference fixtures. Commit the data with its
source, version, parameters, and tolerance. Repository checks run from the
committed fixtures.

The [policy gate](scripts/check_repo.bend) rejects unsupported file types,
`package.json`, symlinks, submodules, executable non-Bend files, and quoted
foreign imports outside strings and comments. It checks `LAWS.bend` through
the required `PROOF.bend` entry and checks other Bend files individually.
Review dependencies, workflow steps, and gate changes for embedded logic.

## Local checks

Use Bend 2.0.39, Git, Clang and the standard Unix tools `find`, `mktemp` and `rm`
on macOS or Linux. Run these from the repository root:

```sh
bend scripts/check_repo.bend
bend PROOF.bend --verdict
bend scripts/test.bend
bend scripts/test.bend -- --js
```

Only `--verdict` needs [Lean 4.34.0](https://github.com/leanprover/lean4/releases/tag/v4.34.0).
Bend finds `lean` and `leanc` on PATH or in the matching elan toolchain and
caches the kernel on the first run.

The test runner always checks native output. `--js` also checks JavaScript
and requires Node or Bun. Set `BEND` or `BEND_JS` to override the default
executables, `bend` and `node`. Each variable takes a single executable path.

Checks discover tracked and non-ignored untracked files with UTF-8 paths and
skip locally deleted files. Test and example `.bend` files are runnable
fixtures. Put expected stdout in trailing `#|` lines. Use a bare `#|` for empty
output. Comparisons normalize CRLF and trim surrounding whitespace.

Compiler errors, runtime failures, and output mismatches fail the run. Limits
are 1 MiB per source file, 4 MiB of subprocess output, and 30 seconds per
command or two minutes for fixture compilation. The runner removes temporary
builds after success and ordinary failures.

## Laws and proofs

Define applicable contracts in [LAWS.bend](LAWS.bend) before implementation
when feasible. Complete them in [PROOF.bend](PROOF.bend) with shared lemmas
from `proofs/`. Keep runtime imports independent of the proof entry point.
Changes to accepted statements, reference predicates, or preconditions
require a maintainer decision.

Use universal inputs and explicit configuration and reachability assumptions.
`--verdict` checks the translated laws with BendTT's independent kernel.
The laws cover source behavior under their stated assumptions and treat Base
F32 operations as opaque. Use reference fixtures for numerical behavior,
backend tests for compiled behavior, and benchmarks for performance.
Proofs resolve `bend-mathlib` from BendHub. Runtime code uses Base.

## Documentation

Keep one source of truth for each detail. The [F32 facade](src/f32.bend)
defines indicator names and signatures. The implementation defines behavior,
with laws for checked contracts and reference fixtures for expected results.
Link to those sources when explaining behavior.

Keep the README focused on purpose, usage, essential contracts, and links.
Describe supported behavior and leave milestone recaps to release notes.
Keep setup and check commands here.

## Changes and review

Keep algorithms in `src/core/` and bind concrete operations in the facade.
Use the same state transitions for batch and streaming. Add contracts and
independent reference examples before extending the public interface.

Run the policy gate, independent proofs, and both test backends before opening
a pull request. For changes to contracts, the runner, or the gate, use a
temporary copy outside the checkout to verify that a relevant defect is rejected.
Preserve existing assertions and justify arithmetic assumptions.

## CI and enforcement

The `Bend-only and tests` job uses checksum-pinned Bend and Lean releases and
a read-only token. It runs the policy, proofs, and both test backends on pull
requests and pushes to `main`. Maintainers should require this check through
branch protection and review changes to the workflow, policy, agent
instructions, tooling, and proof contracts.

Policy changes require a maintainer decision. Keep instructions usable from a
normal clone.
