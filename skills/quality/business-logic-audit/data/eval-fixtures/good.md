# Eval Fixture — good.md

# Expected: PASS — every BR-* in rules.md has matching code path; config keys aligned

**Skill:** `quality/business-logic-audit`
**Scenario:** All 5 audit categories pass for a synthetic `attendance` domain.
**Which check fires:** none (clean baseline)

---

## Setup (synthetic; do not run against real codebase)

Imagine a `documents/01-business/attendance/` folder containing:

```
attendance/
├── rules.md         # BR-ATT-001 .. BR-ATT-007 + 4 config keys
├── use-cases.md     # UC-ATT-001 .. UC-ATT-005, every error path documented
└── api-contract.md  # 4 endpoints, error codes mapped
```

### Sample rules.md content (synthetic)

```markdown
- **BR-ATT-001** Attendance status must be one of: PRESENT, LATE, ABSENT, EXCUSED.
- **BR-ATT-002** Late threshold: configurable via `app.attendance.late-threshold-minutes` (default 10).
- **BR-ATT-003** Bulk attendance update may not exceed `app.attendance.bulk-max` rows (default 200).
```

### Sample application.yml content (synthetic)

```yaml
app:
  attendance:
    late-threshold-minutes: 10
    bulk-max: 200
```

### Sample Java code (synthetic)

```java
public enum AttendanceStatus { PRESENT, LATE, ABSENT, EXCUSED } // BR-ATT-001 ✓

@Value("${app.attendance.late-threshold-minutes}")
private int lateThresholdMinutes; // BR-ATT-002 ✓

@PostMapping("/bulk")
public Result bulk(@RequestBody @Size(max = ${app.attendance.bulk-max}) List<AttendanceRow> rows) { ... } // BR-ATT-003 ✓
```

---

## Expected audit-report excerpt

```
## Category 1: Rule Coverage           20/20
## Category 2: Config Accuracy          20/20
## Category 3: Edge Case Tests          20/20
## Category 4: Cross-Domain Consistency 20/20
## Category 5: Stakeholder Alignment    20/20  (manual sign-off recorded)
Total: 100/100  Grade: A
```

No gaps filed. Domain ready for GA.

---

## How to use this fixture

When extending `business-logic-audit` skill, run logic against this fixture
to confirm a passing scenario stays passing. If your change breaks this
fixture, you've introduced a false positive — investigate before merging.
