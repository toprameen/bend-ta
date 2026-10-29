# bend-ta

This repository is a Bend 2 technical analysis library. `src/f32.bend` is the
public F32 facade; `src/core/` holds shared templates and state. Future numeric
facades must instantiate that core instead of copying indicator algorithms.

- Read `README.md` and `docs/design.md` before changing behavior.
- Pass numeric types and operations as leading `~` parameters. Keep periods,
  coefficients and input data as ordinary runtime arguments.
- Keep initialization, warm-up, output alignment and batch/stream semantics
  common across precisions. Floating-point associativity is not a valid law.
- Arrays are owned and their capacity is a power of two. Hide capacity and
  wrapping inside the rolling module; callers supply a period, not a depth.
- Add indicators only with specified initialization and reference examples.
  F64 is planned; do not invent a working F64 facade before a backend exists.
- Run `bun run test`; `bun run test:native` also compiles and executes C.
  `BEND` may name an alternate Bend executable. Tests use trailing `#|` output.
- Keep generated files and temporary probes outside the repository. Do not add
  private workspace context or absolute machine paths to tracked files.
- Leave changes uncommitted and unpushed unless the user authorizes publication.
  When committing logic and tests, put logic first in a separate commit.

In the maintainer's personal multi-repository Bend workspace, also retrieve the
canonical parent policy and `CONTEXT/` before nontrivial work. Those local notes
are not a dependency of this repository and must never be published here.
