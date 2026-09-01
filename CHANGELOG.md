# Changelog

All notable changes to the `red-team` Spec Kit extension are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.3] — 2026-09-01

### Fixed

- **Gate accepted any file matching the findings glob** — `speckit.red-team.gate` treated the findings-report requirement as satisfied when a file matching `specs/<feature-id>/red-team-findings-*.md` merely existed. An empty stub, or a report whose resolution walk was abandoned mid-way, silently passed a mandatory governance gate. The gate now validates minimum structure with four deterministic, grep-level checks (V1 session/target identity, V2 at least one severity-ranked finding, V3 disposition evidence, V4 no declared non-zero `unresolved` counter) before returning `SATISFIED`, and emits a distinct `BLOCKED (findings report present but invalid)` decision naming the failed checks otherwise. Calibrated against a 50-report production fleet: 49 pass unchanged; the one now blocked declares `unresolved: 27` — the exact failure class the check exists for.
- **Gate/run-list deadlock on demandable-but-unschedulable trigger categories** — the mandatory gate can demand a red team for any of the six trigger categories, but `speckit.red-team.run` refused to run when no catalog lens covered a matched category (`ERROR: lens catalog has no lens covering the matched triggers`) — leaving the gate permanently unsatisfiable. The shipped `config-template.yml` itself under-covered (no lens for `ai_llm` or `immutability_audit`), so a fresh install could deadlock on its first AI or audit-trail spec. Three-part fix: (1) `speckit.red-team.run` now validates the catalog at config load — unknown `trigger_match` values and uncovered categories are hard errors with the remediation named; (2) the run command's trigger-keyword table is now identical to the gate's (the previous drift meant e.g. a spec whose only money term was `IRR` tripped the gate but matched nothing in the run command), with agent judgement made additive-only so a keyword-matched category can never be dropped below what the gate will demand; (3) `config-template.yml` ships four example lenses covering all six categories.
- **Documented gate waiver was unreachable when hook-invoked** — the gate read the `--skip-red-team-gate: <reason>` opt-out from `$ARGUMENTS`, but the spec-kit `before_plan` hook mechanism invokes hook commands by name only (`EXECUTE_COMMAND: {command}`) and never forwards `/speckit.plan`'s arguments, so `$ARGUMENTS` arrived empty (or as the uninterpolated literal) and the documented waiver could never fire. The gate now resolves *effective arguments*: interpolated `$ARGUMENTS` on direct invocation, else the arguments the user passed to the triggering `/speckit.plan` invocation visible in the session; a literal `$ARGUMENTS` string is treated as empty. The documented waiver UX is unchanged — it now actually works.

### Added

- Test suite at `tests/run-tests.sh` (plain bash + grep, no framework) with fixture reports: the reference implementation of gate checks V1-V4, a gate/run trigger-keyword-table parity check, a `config-template.yml` six-category coverage check, and a version-consistency check. Wired into CI via `.github/workflows/tests.yml`.

### Compatibility

- No interface changes: command names, hook name, findings glob, report path convention, and waiver syntax are all unchanged. Two behaviours are intentionally stricter: (1) a stub or unresolved findings report now blocks instead of passing — governance working as designed; (2) `speckit.red-team.run` refuses catalogs that do not cover all six trigger categories — previously such catalogs appeared to work until the day they deadlocked the gate. Projects with an under-covered catalog should add lenses for the uncovered categories (the updated template has ready examples).

## [1.0.2] — 2026-04-22

### Added

- New command `speckit.red-team.gate` — a deterministic Principle VIII gate that scans the current feature spec for the six red team trigger categories (`money_path`, `regulatory_path`, `ai_llm`, `immutability_audit`, `multi_party`, `contracts`) and blocks `/speckit.plan` if a qualifying spec has no findings report on record.
- The gate is wired as a **mandatory `before_plan` hook** (new `hooks.before_plan` block in `extension.yml`). Once installed, `/speckit.plan` will auto-invoke the gate on every run; non-qualifying specs return `PROCEED` silently, qualifying specs with a findings report on file return `SATISFIED` with the report path, and qualifying specs without a report return `HALT` with explicit remediation options (run `/speckit.red-team.run`, or opt out with `--skip-red-team-gate: <reason>` which the plan records as an Accepted Risk tagged `[red-team-skipped]`).
- Gate findings-report discovery supports the canonical `specs/<feature-id>/red-team-findings-*.md` path plus a post-graduation `99_Archive/red-team/<feature-id>/` fallback. Projects MAY override via an optional `config.findings_glob` entry (v1.1 — not required in v1.0.2).

### Rationale

Prior to v1.0.2, enforcement of Principle VIII was hybrid: the constitution declared the rule, the maintainer remembered to invoke the red team. In practice this relies on human memory at exactly the workflow transition where the protocol matters most. v1.0.2 closes the gap by making the gate a mandatory pre-plan hook — the mechanism the `/speckit.plan` skill already understands. A project that installs this extension gets the gate for free; projects that do not install the extension are unaffected.

## [1.0.1] — 2026-04-22

### Changed

- Lowered `requires.speckit_version` from `>=0.7.0` to `>=0.1.0`. The v1.0.0 requirement was overly conservative and blocked installation on common spec-kit versions (0.6.x) in the field. The extension uses no 0.7.x-specific APIs; matching the community norm (`>=0.1.0` — same as reconcile, refine, and other catalog entries) permits broad adoption. No functional change.

## [1.0.0] — 2026-04-22

### Added

- Initial release of the `red-team` Spec Kit extension.
- Command `speckit.red-team.run` — attacks a functional spec with 3–5 parallel adversarial lens agents before `/speckit.plan` locks in architecture.
- Six default trigger categories (OR-combined): `money_path`, `regulatory_path`, `ai_llm`, `immutability_audit`, `multi_party`, `contracts`. A spec matching ≥1 category qualifies for red team.
- Project-specific lens catalog at `.specify/extensions/red-team/red-team-lenses.yml` (scaffolded from `config-template.yml`). Each lens declares description, core attack questions, trigger match, severity weight, finding bound.
- Propose-and-confirm UX when more than 5 lenses match (ranked by overlap count primary + severity weight tie-break; `--yes` auto-accepts).
- Structured findings report at `specs/<feature-id>/red-team-findings-<YYYY-MM-DD>[-NN].md` with session metadata, findings table, resolutions log, and optional dogfood validation decision.
- Four resolution categories for every finding: **spec-fix** / **new-OQ** / **accepted-risk** / **out-of-scope**. Extension never auto-applies spec changes — every resolution requires maintainer authorisation.
- Hard-and-fast rule: resolution edits MUST land in forward-facing canonical locations. Historical SpecKit working records in `specs/<feature-id>/` (spec.md, plan.md, tasks.md, research.md, data-model.md, contracts/, quickstart.md, checklists/) MUST NOT be rewritten during resolution — they are immutable audit records.
- `config-template.yml` with two example lenses (Regulatory Adversary, Trust-Boundary Adversary) and inline schema documentation. Projects customise for their own domain.

### Validated

Real-world dogfood against a 500-line, 27-FR functional spec in a private project: 5 adversary agents dispatched in parallel returned 25 findings in ~1.5 min wall-clock (well under the 30-min SC-002 target). 19 of 25 findings met the "meaningful finding" bar (severity ≥ HIGH AND represents an adversarial scenario `/speckit.clarify` and `/speckit.analyze` structurally cannot catch). One finding caught a cross-spec identifier-type drift between two halves of the same interface contract that had been introduced by a separate commit 1 hour earlier — a class of issue single-spec tools cannot surface.

[Unreleased]: https://github.com/ashbrener/spec-kit-red-team/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.3
[1.0.2]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.2
[1.0.1]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.1
[1.0.0]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.0
