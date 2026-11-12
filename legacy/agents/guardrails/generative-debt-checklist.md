# Generative & Structural Debt Checklist

## Before Writing Code

| Check | Action |
|-------|--------|
| Bypassing an abstraction layer? | Use the proper layer. |
| Coupling independent modules? | Use interface-based approach. |
| Adding framework code to domain layer? | Keep domain pure. |
| Skipping plan/design phase? | Create feature.md and tasks first. |

## While Writing Code

| Check | Action |
|-------|--------|
| Hard-coding configurable value? | Document as debt, create follow-up task. |
| Skipping error handling? | Add error handling. |
| Copying code (≥3 occurrences)? | Abstract it. |
| Adding dependency? | Check layer rules, run ArchUnit. |
| Writing code without tests? | Add tests. |

## After Writing Code

| Check | Action |
|-------|--------|
| Code quality acceptable? | Refactor before committing. |
| Saying "fix it later"? | Document what/when/how. |
| Skipped architecture tests? | Run `./harness/run-arch-tests.sh`. |
| Undocumented complexity? | Add comments or simplify. |

## Debt Documentation Format

When intentional debt is justified, document in progress log:

```markdown
- DEBT: [Description]
  - Reason: [Why shortcut was taken]
  - Follow-up: [Ticket ID]
  - Impact: [Risk assessment]
```
