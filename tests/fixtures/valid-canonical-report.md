# Red Team Findings — 001-example-feature

**Session**: `RT-001-example-feature-2026-01-15-01`
**Target**: `specs/001-example-feature/spec.md`
**Date**: 2026-01-15
**Maintainer**: Example Maintainer
**Lenses**: Regulatory Adversary, Trust-Boundary Adversary
**Selection method**: auto

## 1. Session Summary

Two lenses, four findings, all dispositioned.

## 2. Findings

| ID | Lens | Severity | Location | Finding | Suggested Resolution | Status |
|---|---|---|---|---|---|---|
| F-RT-001-001 | Regulatory Adversary | HIGH | FR-003 | Disclosure timing is undefined. | Define the disclosure window. | spec-fix |
| F-RT-001-002 | Regulatory Adversary | MEDIUM | §4 | Evidence chain gap. | Add audit event. | new-OQ |
| F-RT-001-003 | Trust-Boundary Adversary | CRITICAL | FR-007 | Self-approval possible. | Require second approver. | spec-fix |
| F-RT-001-004 | Trust-Boundary Adversary | LOW | §6 | Stale role cache. | Document TTL. | accepted-risk |

## 3. Resolutions Log

- F-RT-001-001 — spec-fix — applied 2026-01-15 — downstream_ref: 04_Functional_Specs/Example_FS_v0.2.md
- F-RT-001-002 — new-OQ — OQ-001-01
- F-RT-001-003 — spec-fix — applied 2026-01-15
- F-RT-001-004 — accepted-risk — AR-001

## 5. Session Metadata

```yaml
session_id: RT-001-example-feature-2026-01-15-01
findings: 4
spec_fix: 2
new_oq: 1
accepted_risk: 1
out_of_scope: 0
unresolved: 0
```
