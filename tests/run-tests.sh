#!/usr/bin/env bash
# Test suite for the red-team Spec Kit extension.
#
# No framework — plain bash + grep, matching the extension's own philosophy:
# every check the gate makes must be cheap, deterministic, and grep-able.
#
# What is covered:
#   1. Findings-report validation (V1-V4) — the reference implementation of
#      the deterministic checks documented in commands/red-team-gate.md §5,
#      exercised against fixture reports (valid canonical, valid field-style,
#      stub, abandoned-resolution, empty).
#   2. Trigger keyword-table parity — the six-category keyword table in
#      commands/red-team-gate.md and commands/red-team.md must be identical,
#      or the gate can demand a red team the run command refuses to schedule.
#   3. Lens-catalog coverage of config-template.yml — the shipped template
#      must cover all six trigger categories and use only known category
#      names, per the config-load validation in commands/red-team.md §2.6.
#   4. Version consistency — extension.yml, README.md, and CHANGELOG.md must
#      agree on the released version.
set -u
cd "$(dirname "$0")/.."

FAILURES=0
pass() { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

# ---------------------------------------------------------------------------
# 1. Findings-report validation — reference implementation of gate checks V1-V4
# ---------------------------------------------------------------------------
# Keep these four rules in lockstep with commands/red-team-gate.md §5.
validate_report() { # $1 = report path; returns 0 = valid, 1 = invalid
  local f="$1"
  # V1 — session/target identity
  grep -qE 'RT-[A-Za-z0-9._-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" \
    || grep -qiE '\*\*(Session|Target|Spec under attack)\*\*[[:space:]]*:' "$f" \
    || return 1
  # V2 — findings present (uppercase severity tokens per the findings schema)
  grep -qE '(CRITICAL|HIGH|MEDIUM|LOW)' "$f" || return 1
  # V3 — dispositions present
  grep -qiE '(resolution|disposition|dismissed|unresolved|spec-fix|new-OQ|accepted-risk|out-of-scope)' "$f" || return 1
  # V4 — zero undispositioned (no explicit non-zero unresolved counter)
  grep -qiE 'unresolved[^0-9]{0,3}[1-9]' "$f" && return 1
  return 0
}

expect_valid() {
  if validate_report "$1"; then pass "report validation: $(basename "$1") is VALID"; else fail "report validation: $(basename "$1") should be VALID"; fi
}
expect_invalid() {
  if validate_report "$1"; then fail "report validation: $(basename "$1") should be INVALID"; else pass "report validation: $(basename "$1") is INVALID"; fi
}

expect_valid   tests/fixtures/valid-canonical-report.md
expect_valid   tests/fixtures/valid-field-style-report.md
expect_invalid tests/fixtures/invalid-stub-report.md
expect_invalid tests/fixtures/invalid-unresolved-report.md
expect_invalid tests/fixtures/invalid-empty-report.md

# The gate document must actually describe each check the reference
# implementation makes (doc/impl parity).
for marker in 'V1' 'V2' 'V3' 'V4' 'RT-\[A-Za-z0-9._-\]' 'unresolved\[^0-9\]{0,3}\[1-9\]'; do
  if grep -q -- "$marker" commands/red-team-gate.md; then
    pass "gate doc documents validation marker: $marker"
  else
    fail "gate doc missing validation marker: $marker"
  fi
done

# ---------------------------------------------------------------------------
# 2. Trigger keyword-table parity between gate and run commands
# ---------------------------------------------------------------------------
extract_table() { # $1 = file
  grep -E '^[[:space:]]*\| `(money_path|regulatory_path|ai_llm|immutability_audit|multi_party|contracts)` \|' "$1" \
    | sed 's/^[[:space:]]*//'
}
gate_table=$(extract_table commands/red-team-gate.md)
run_table=$(extract_table commands/red-team.md)

if [ "$(printf '%s' "$gate_table" | grep -c '^')" -eq 6 ]; then
  pass "gate command defines all six trigger-category keyword rows"
else
  fail "gate command should define exactly six trigger-category keyword rows"
fi
if [ "$gate_table" = "$run_table" ]; then
  pass "trigger keyword tables identical between gate and run commands"
else
  fail "trigger keyword tables DIFFER between gate and run commands (deadlock risk: gate demands what run will not schedule)"
  diff <(printf '%s\n' "$gate_table") <(printf '%s\n' "$run_table") | sed 's/^/       /'
fi

# ---------------------------------------------------------------------------
# 3. config-template.yml covers all six categories with known names only
# ---------------------------------------------------------------------------
known="money_path regulatory_path ai_llm immutability_audit multi_party contracts"
declared=$(grep -E '^[[:space:]]*trigger_match:' config-template.yml \
  | sed 's/.*\[//; s/\].*//; s/,/ /g' | tr -s ' \t' '\n' | sed '/^$/d' | sort -u)

unknown=""
for cat in $declared; do
  case " $known " in *" $cat "*) ;; *) unknown="$unknown $cat";; esac
done
if [ -z "$unknown" ]; then
  pass "config-template.yml uses only known trigger categories"
else
  fail "config-template.yml declares unknown trigger categories:$unknown"
fi

uncovered=""
for cat in $known; do
  printf '%s\n' "$declared" | grep -qx "$cat" || uncovered="$uncovered $cat"
done
if [ -z "$uncovered" ]; then
  pass "config-template.yml covers all six trigger categories"
else
  fail "config-template.yml leaves categories uncovered (shipped-template gate deadlock):$uncovered"
fi

# ---------------------------------------------------------------------------
# 4. Version consistency
# ---------------------------------------------------------------------------
ext_version=$(grep -E '^  version:' extension.yml | sed 's/.*"\(.*\)".*/\1/')
readme_version=$(grep -E '^\- \*\*Version:\*\*' README.md | sed 's/.*\*\*Version:\*\* //; s/[[:space:]]*$//')
changelog_version=$(grep -Eo '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '#[] ')

if [ "$ext_version" = "$readme_version" ] && [ "$ext_version" = "$changelog_version" ]; then
  pass "version consistent across extension.yml / README.md / CHANGELOG.md ($ext_version)"
else
  fail "version drift: extension.yml=$ext_version README.md=$readme_version CHANGELOG.md=$changelog_version"
fi

# ---------------------------------------------------------------------------
printf '\n%d failure(s)\n' "$FAILURES"
[ "$FAILURES" -eq 0 ]
