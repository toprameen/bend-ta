# Contributing

## Bend-only source policy

All project-maintained program logic must be written in Bend. This includes
the library, tests, examples, test runner and repository checks. Do not add
TypeScript, JavaScript, Python, C, shell scripts or other-language implementations,
or quoted foreign-code imports inside Bend source. Do not hide such logic in a
data file, an inline workflow program or an interpreter command.

Markdown documentation, declarative YAML/JSON configuration, CSV/TSV/text test
data and ordinary Git/license metadata are allowed. Data must remain inert.
CI bootstrap may install pinned tools and invoke Bend commands; it must not
implement test or application logic. External tools such as Git, Clang, Unix
filesystem utilities and an optional JavaScript runtime are toolchain dependencies,
not project-owned implementations. The Bend compiler's standard Base effects and
generated native/JS runtime are allowed; generated output is not committed.

External numerical tools may generate reference fixtures. Commit the data with
its source, version, parameters and comparison tolerance, rather than committing
another-language generator or requiring it to run this repository's checks.

The policy gate allows `.bend`, `.md`, `.yml`, `.yaml`, `.json`, `.csv`, `.tsv`
and `.txt` files plus named Git/license metadata. It rejects npm's `package.json`,
symlinks, Git submodules and executable non-Bend files. It checks quoted foreign
imports outside strings/comments and asks Bend to type-check every source entry.
The root `LAWS.bend` is checked through the required `PROOF.bend` entry point,
which completes its declarations; other source files are checked individually.
The gate is not a proof that allowed data/configuration cannot conceal code:
maintainers must review new dependencies, workflow bodies and changes to the gate.

## Local checks

Use Bend 2.0.39, Git, Clang and the standard Unix tools `find`, `mktemp` and `rm`
on macOS or Linux. Run these from the repository root:

```sh
bend scripts/check_repo.bend
bend PROOF.bend --verdict
bend scripts/test.bend
bend scripts/test.bend -- --js
```

Independent proof verification requires Lean 4.34.0, including `lean` and `leanc`,
on PATH or in its matching elan toolchain. Bend builds and caches its kernel on
the first `--verdict` run. Use the [pinned Lean release](https://github.com/leanprover/lean4/releases/tag/v4.34.0).
The ordinary policy gate checks proofs without requiring Lean.

The last command also requires Node or Bun; `BEND_JS` selects the executable and
defaults to `node`. `BEND` selects the compiler executable for subprocesses.
Both variables hold one executable path, not a command with shell arguments.
There is no npm install step. The runner always tests native output and adds
the JS backend only with `--js`; a missing requested runtime is a failure.

Checks discover tracked and non-ignored untracked files through Git, excluding
tracked files deleted in the working tree. Use normal UTF-8 paths. All test/example
`.bend` files must be runnable fixtures with trailing `#|` expected stdout.
Comparisons normalize CRLF and trim surrounding whitespace. Empty expected output
still needs a `#|` marker. Compiler/runtime failures and output mismatches fail
the run. Source reads are limited to 1 MiB; subprocess output is limited to 4 MiB
and commands have a 30-second timeout, with two minutes allowed for fixture
compilation. Generated files are held in a unique
OS temporary directory and removed after normal test failures as well as success.

## Laws and proofs

State important behavioral contracts in `LAWS.bend` before implementing changes
when feasible. Keep its statements and reference predicates under maintainer
review. Implement proofs in `PROOF.bend`, using completed shared lemmas in
`proofs/`; runtime modules must not import the proof entry point. Changes to an
accepted law's meaning or preconditions require an explicit maintainer decision.
Never weaken a law or introduce an unproven arithmetic assumption to obtain a pass.

Use universal inputs for general promises, state configuration/reachability
requirements explicitly, and reuse shared proofs. Keep literal numerical examples
in tests. Base F32 arithmetic is opaque to the checker; structural laws over F32
values do not establish numerical error bounds or TA-Lib conformance. See the
[proof contracts](docs/laws.md) for exact coverage and assumptions.

Run the proof entry point after relevant source changes. For a new contract or
proof-enforcement change, demonstrate rejection of a small relevant defect in a
temporary copy outside the checkout. Keep numerical reference tests, native/JS
checks and performance benchmarks: they establish different properties.

## Documentation

Write documentation around supported behavior and the reader's task. Keep the
README focused on purpose, a usable example, essential contracts and links to
reference material. Avoid development-stage labels, milestone recaps,
implementation totals, temporary repository status and speculative plans.

Keep evolving inventories, parameter tables and toolchain details in their
owning reference documents; link to them instead of repeating them. Keep usage,
precision and numerical limits accurate as behavior changes. Durability comes
from choosing the right level of detail, not from omitting useful constraints.

## Changes and review

Keep numeric algorithms in `src/core/` and bind concrete operations in the typed
facade. Add indicator contracts and independent reference examples before extending
the public interface. State seed, warm-up, alignment and numerical limits explicitly.
Use the same state transitions for batch and streaming calculations.

Run the policy gate, independent proof check and both backend checks before opening a pull request. For
runner or gate changes, also demonstrate failure on an incorrect result or a
policy violation. Keep temporary mutation probes and generated files outside Git.
Do not weaken existing assertions merely to make a check pass.

## CI and enforcement

The `Bend-only and tests` job runs on pull requests, main pushes and merge groups
with a read-only repository token. It installs a checksum-pinned Bend release
and a checksum-pinned Lean toolchain, then runs the same policy, proof and test
commands contributors use locally. Its small shell
bootstrap only downloads, verifies and installs tools.

Maintainers should require this status check for `main` through GitHub branch
protection and review changes to the workflow, policy, agent instructions,
tooling and proof contracts through the usual pull request process.

Changes to this policy require an explicit maintainer decision. Contributor and
agent instructions must be usable without the maintainer's private workspace.
