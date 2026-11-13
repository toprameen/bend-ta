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
source, version, parameters, and tolerance.

Review dependencies, workflow steps, and gate changes for embedded logic.

## Local checks

On macOS or Linux, use Git, Clang, `find`, `mktemp`, `rm`, and the Bend version
pinned in [CI](.github/workflows/ci.yml). Run these from the repository root:

```sh
bend scripts/check_repo.bend
bend PROOF.bend --verdict
bend scripts/test.bend
bend scripts/test.bend -- --js
```

For `--verdict`, install the Lean version pinned in CI through elan or put
`lean` and `leanc` on `PATH`. For `--js`, install Node or Bun. Use
`bend scripts/test.bend -- --help` for runner options.

Use Bend assertions in tests. Give failures a label that identifies the case.

## Laws and proofs

Define applicable contracts in [LAWS.bend](LAWS.bend) before implementation
when feasible. Complete them in [PROOF.bend](PROOF.bend) with shared lemmas
from `proofs/`. Keep runtime imports independent of the proof entry point.
Changes to accepted statements, reference predicates, or preconditions
require a maintainer decision.

Use universal inputs and explicit configuration and reachability assumptions.
The laws treat Base F32 operations as opaque. Use reference fixtures for
numerical behavior, backend tests for compiled behavior, and benchmarks for
performance.

## Documentation and code comments

We actively avoid adding documentation and code comments. In the agentic era,
AI agents can read the code directly. A second description of the same
behavior can fall out of sync and mislead people and agents alike.
We keep the implementation as the single source of truth for behavior.

Add a code comment **only when absolutely necessary** to explain the
rationale for an obscure constraint or a non-obvious design decision. In the
pull request, explain why that rationale cannot be inferred from the code.
Reviewers should remove comments that fail to meet this standard.

Put necessary documentation in existing files. Keep the project purpose,
getting-started instructions, and essential usage constraints in
`README.md`. Keep contributor setup and checks in `CONTRIBUTING.md` and
benchmark procedures and results in `benchmarks/`. Avoid standalone guides
and hand-maintained catalogs.

## Changes and review

Keep algorithms in `src/core/` and bind concrete operations in the facade.
Use the same state transitions for batch and streaming. Add applicable laws and
independent reference fixtures before extending the public interface.

Run the policy gate, independent proofs, and both test backends before opening
a pull request. For changes to contracts, the runner, or the gate, use a
temporary copy outside the checkout to verify that a relevant defect is rejected.
Preserve existing assertions and justify arithmetic assumptions.

Maintainers should require the `Bend-only and tests` check through branch
protection and review changes to the workflow, policy, agent instructions,
tooling, and proof contracts.

Policy changes require a maintainer decision. Keep instructions usable from a
normal clone.
