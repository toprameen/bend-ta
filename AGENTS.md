# bend-ta

This repository is a Bend 2 technical analysis library. `src/f32.bend` is the
public F32 facade; `src/core/` holds shared templates and state. Future numeric
facades must instantiate that core instead of copying indicator algorithms.

- Read `CONTRIBUTING.md`, `README.md` and `docs/design.md` before changing behavior.
- Follow the Bend-only source policy in `CONTRIBUTING.md`. Library code, tests,
  examples, runners and repository checks must be Bend. Do not add foreign
  implementations, another-language scripts or inline CI program logic.
- Follow the documentation policy in `CONTRIBUTING.md`. Keep the README centered
  on purpose, usage, essential contracts and reference links. Avoid progress
  reports, development-stage labels, implementation counts, temporary status
  and speculative plans. Keep changing details in their owning reference docs;
  update actual usage and limits when behavior changes.
- Keep code as the single source of truth. Almost never add code comments:
  a parallel prose description can drift from the implementation. Express intent
  through clear names, types and structure. A comment is justified only for an
  exceptionally obscure or esoteric consideration that cannot reasonably be
  made clear in the code itself. Keep that explanation brief and focused on why
  the constraint exists; never narrate operations or restate the code's behavior.
  Functional directives such as trailing `#|` test output are exempt.
- Pass numeric types and operations as leading `~` parameters. Keep periods,
  coefficients and input data as ordinary runtime arguments.
- Keep initialization, warm-up, output alignment and batch/stream semantics
  common across precisions. Floating-point associativity is not a valid law.
- Arrays are owned and their capacity is a power of two. Hide capacity and
  wrapping inside the rolling module; callers supply a period, not a depth.
- Add indicators only with specified initialization and reference examples.
  F64 is planned; do not invent a working F64 facade before a backend exists.
- Run `bend scripts/check_repo.bend` and `bend scripts/test.bend`.
  Run `bend scripts/test.bend -- --js` for native and JavaScript checks.
  `BEND` selects the compiler; `BEND_JS` selects the optional JS runtime.
  Tests use trailing `#|` output. Exercise runner/gate failures when changing them.
- Keep generated files and temporary probes outside the repository. Do not add
  private workspace context or absolute machine paths to tracked files.
- Leave changes uncommitted and unpushed unless the user authorizes publication.
  When committing logic and tests, put logic first in a separate commit.

Contributor instructions and checks must work from a normal clone without
personal workspace files, absolute machine paths or private context.
