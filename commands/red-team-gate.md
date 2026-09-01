---
description: "Principle VIII gate — check whether the current feature spec qualifies for red team, and block /speckit.plan if a qualifying spec has no findings report on record."
# No MCP tools required — the gate is a deterministic keyword-and-filesystem
# check performed by the host AI agent directly.
---

## User Input

```text
$ARGUMENTS
```

## Purpose

This command is a **gate**, not a workflow. It runs automatically as the
`before_plan` hook of the `red-team` extension and is invoked by
`/speckit.plan` before any planning work begins.

The gate enforces the constitutional rule that functional specs matching one
or more red team Trigger Criteria MUST have a red team findings report on
record before `/speckit.plan` proceeds. See your project's constitution
(Principle VIII — Red Team Qualifying Specs Before Plan — if adopted) or the
canonical protocol reference at
`https://github.com/ashbrener/spec-kit-red-team/blob/main/docs/protocol.md`.

## Outline

1. **Read the effective arguments**.
   The `before_plan` hook mechanism invokes this command **by name only — it
   never forwards the arguments the user passed to `/speckit.plan`**. When
   hook-invoked, the User Input block above is therefore empty or still
   contains the literal, uninterpolated string `$ARGUMENTS`. Determine the
   *effective arguments* as follows:
   - If the User Input block contains interpolated text (direct invocation of
     this command), that text is the effective arguments.
   - Otherwise (empty, or the literal string `$ARGUMENTS`), the effective
     arguments are the arguments the user passed to the `/speckit.plan`
     invocation that triggered this hook — visible earlier in the current
     session. If no such invocation is visible, the effective arguments are
     empty.

   Every reference to `$ARGUMENTS` below means these *effective arguments*.

2. **Resolve the spec under consideration**.
   - If the effective arguments contain a path to a spec file, use that.
   - Else, attempt to determine the current feature from the working branch
     via the `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`
     helper. Parse `FEATURE_SPEC` from its output.
   - If neither resolves, print `Red-Team Gate: SKIPPED (no spec in context)`
     and return `PROCEED`.

3. **Scan the spec for Red Team Trigger Criteria**.
   Read the spec file. For each of the six categories below, mark it as
   triggered if ANY listed keyword (case-insensitive, word-boundary) appears
   in the spec body. Record which categories matched — this becomes part of
   the gate output for transparency.

   | Category | Example keyword hits (not exhaustive) |
   |---|---|
   | `money_path` | `fee`, `fees`, `amount`, `allocation`, `carry`, `carried interest`, `preferred return`, `management fee`, `waterfall`, `price`, `currency`, `invoice`, `AUM`, `IRR`, `MOIC`, `valuation` |
   | `regulatory_path` | `KYC`, `AML`, `GDPR`, `SEC`, `FCA`, `AIFMD`, `Reg S-P`, `compliance`, `regulator`, `audit report`, `investor disclosure`, `lawful basis`, `subject rights` |
   | `ai_llm` | `LLM`, `Claude`, `GPT`, `prompt`, `inference`, `classification`, `extraction`, `summarisation`, `summarization`, `scoring`, `model output`, `AI-generated`, `AI-assisted` |
   | `immutability_audit` | `immutable`, `append-only`, `permanent`, `never deleted`, `audit log`, `audit trail`, `tamper`, `hash chain`, `version chain`, `previous_.*_id` |
   | `multi_party` | `approval`, `approve`, `IC`, `Investment Committee`, `two-person`, `partner approval`, `override`, `sign-off`, `sign off`, `role-based`, `permission gate` |
   | `contracts` | `contract`, `interface`, `handoff`, `hand-off`, `upstream`, `downstream`, `API boundary`, `envelope`, `payload`, `request shape`, `response shape`, `schema` |

   Keyword matching is intentionally liberal — a false positive on the gate
   just means a spec that did not need red team is still offered the choice.
   A false negative silently waives a required gate, which is the failure
   mode the gate exists to prevent.

4. **Check for a findings report**.
   - Glob `specs/<feature-id>/red-team-findings-*.md` in the repo root.
   - Also check `99_Archive/red-team/<feature-id>/` in case the spec has
     already graduated and the findings were archived.
   - If the project uses a different path convention, honour its
     `extension.yml` `config.findings_glob` override (if set). Otherwise
     use the default above.

5. **Validate the findings report — existence is not enough**.
   A file that merely matches the glob does NOT satisfy the gate. For each
   candidate file (newest first), run the four deterministic checks below —
   plain `grep`-level pattern checks, case-insensitive unless stated, no
   semantic judgement. The report is **valid** only if all four pass:

   | # | Check | Rule |
   |---|---|---|
   | V1 | Session/target identity | File contains a session ID matching `RT-[A-Za-z0-9._-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}` **or** a header field line matching `\*\*(Session|Target|Spec under attack)\*\*\s*:` |
   | V2 | Findings present | File contains at least one severity token: `CRITICAL`, `HIGH`, `MEDIUM`, or `LOW` (uppercase, as the findings schema requires) |
   | V3 | Dispositions present | File contains at least one disposition marker: `resolution`, `disposition`, `dismissed`, `unresolved`, `spec-fix`, `new-OQ`, `accepted-risk`, or `out-of-scope` |
   | V4 | Zero undispositioned | File contains NO explicit non-zero unresolved counter — i.e. no match for `unresolved[^0-9]{0,3}[1-9]` (an `unresolved: 0` declaration passes; `unresolved: 27` fails) |

   - If **any** candidate passes all four checks, the gate is satisfied by
     that file.
   - If files matched the glob but **none** passed, the gate is NOT
     satisfied. Record, per file, which checks failed — this feeds the
     BLOCKED (invalid report) decision below.
   - These checks are an anti-sloppiness floor, not tamper-proofing: they
     stop an empty/stub file or an abandoned resolution walk from silently
     satisfying a mandatory gate. They deliberately stay cheap and
     deterministic (grep-able markers, no LLM judgement).

6. **Emit the gate decision**.

   - **No category matched** →
     ```
     Red-Team Gate: NOT REQUIRED
     Triggers matched: none
     Outcome: PROCEED
     ```
     Return `PROCEED`.

   - **At least one category matched AND a findings report exists AND it
     passes the §5 validation checks** →
     ```
     Red-Team Gate: SATISFIED
     Triggers matched: <comma-separated list>
     Findings report: <path> (validated: V1-V4 pass)
     Outcome: PROCEED
     ```
     Return `PROCEED`.

   - **At least one category matched AND file(s) match the glob BUT none
     passes the §5 validation checks** →
     ```
     Red-Team Gate: BLOCKED (findings report present but invalid — Constitution Principle VIII)

     Triggers matched: <comma-separated list>
     Candidate report(s): <path> — failed checks: <e.g. V2 (no findings), V4 (unresolved: 27)>

     A findings report satisfies the gate only when it records real findings
     and a completed disposition walk. Options:

       1. If the resolution walk was left unfinished, finish it and set the
          session metadata to `unresolved: 0`.
       2. If the file is a stub, run the red team properly:
            /speckit.red-team.run specs/<feature-id>/spec.md
       3. Explicit opt-out: re-run /speckit.plan with the argument
            --skip-red-team-gate: <reason>

     Outcome: HALT
     ```
     Return `HALT`.

   - **At least one category matched AND no findings report exists** →
     ```
     Red-Team Gate: BLOCKED (Constitution Principle VIII — qualifying spec without findings on record)

     Triggers matched: <comma-separated list>
     Expected: specs/<feature-id>/red-team-findings-*.md (or 99_Archive/red-team/<feature-id>/)
     Found: (none)

     Options:

       1. Run the red team now:
            /speckit.red-team.run specs/<feature-id>/spec.md
          Community extension — `specify extension add red-team` if not already installed.

       2. Explicit opt-out: re-run /speckit.plan with the argument
            --skip-red-team-gate: <reason>
          The reason is recorded verbatim in the plan's Constitution Check section
          as an Accepted Risk tagged [red-team-skipped]. A waived gate is itself
          an Accepted Risk and will be surfaced to the user in the plan summary.

     Outcome: HALT
     ```
     Return `HALT`. `/speckit.plan` MUST NOT proceed to its Outline step.

7. **Respect an explicit opt-out**.
   If the *effective arguments* (per step 1 — for a hook invocation this
   means the arguments the user passed to `/speckit.plan`, because the hook
   mechanism never forwards them into this command's `$ARGUMENTS`) contain
   the token `--skip-red-team-gate:` followed by a non-empty reason, emit:
   ```
   Red-Team Gate: WAIVED
   Triggers matched: <list>
   Reason: <verbatim>
   Outcome: PROCEED (record as Accepted Risk in plan Constitution Check, tagged [red-team-skipped])
   ```
   Return `PROCEED`. The caller is responsible for carrying the
   `[red-team-skipped]` marker into the plan artefact's Constitution Check
   section.

## Non-Goals

- The gate does NOT run the red team itself. That is `/speckit.red-team.run`.
- The gate does NOT modify any file. It emits a decision and returns control.
- The gate does NOT interpret `condition` expressions on itself — it is a
  pass-through gate invoked by the `before_plan` hook mechanism.
- The gate is idempotent: running it twice on the same spec produces the
  same decision.

## Implementation Notes

- Keyword scans are **simple substring / word-boundary checks**. Do NOT
  attempt semantic understanding of the spec — the scan is deliberately
  over-broad so that the only false outcome is "run a red team you didn't
  strictly need to," never "skip a red team you did need."
- Keyword lists above are starting defaults. Projects customising their
  `red-team-lenses.yml` MAY add their own trigger keywords via the
  `trigger_keywords` block in that file (v1.1 feature). For v1.0.2 the
  gate uses the built-in defaults.
- The gate runs against the spec file only. It does NOT walk the full
  documentation tree. This keeps runtime in the single-digit-milliseconds
  range — the gate is free, invoked on every `/speckit.plan`.
- Findings-report validation (step 5) is the same class of check: four
  deterministic pattern checks, no file writes, no LLM judgement. The
  reference implementation of V1-V4 lives in `tests/run-tests.sh` in the
  extension repository and is exercised against fixture reports in CI.
- Argument plumbing: the `before_plan` hook executor emits
  `EXECUTE_COMMAND: {command}` with the command name only. `$ARGUMENTS` is
  interpolated ONLY on direct invocation of `/speckit.red-team.gate`. A
  hook-invoked gate MUST source the waiver token and any spec path from the
  user's `/speckit.plan` invocation in the current session (step 1). Treat a
  User Input block still containing the literal string `$ARGUMENTS` as
  empty.
