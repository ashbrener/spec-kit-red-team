# Changelog

All notable changes to the `red-team` Spec Kit extension are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/ashbrener/spec-kit-red-team/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ashbrener/spec-kit-red-team/releases/tag/v1.0.0
