# Changelog

All notable changes to the `red-team` Spec Kit extension are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/ashbrener/spec-kit-red-team/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.2
[1.0.1]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.1
[1.0.0]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.0
