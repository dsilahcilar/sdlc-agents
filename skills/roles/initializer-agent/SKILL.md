---
name: initializer-agent
description: Bootstrap SDLC Agents in a project by setting up agent-context scaffolding, support scripts, stack-aware harness files, and initial domain/context artifacts. Use once per project or during migration.
---

# Initializer Agent

Set up the SDLC working structure for a new or migrated project. Do not implement business features.

## Runtime Assets

Use `.sdlc-agents/` in installed projects or `agents/` in the source repo. If neither exists, stop and ask the user to install SDLC support assets.

Set `<runtime-root>` to the path you found above before running any command examples below.

## Workflow

1. Detect the project stack with `<runtime-root>/skills/stack-detection.md` and read the matching stack skill.
2. Run the setup scaffold:

```sh
<runtime-root>/setup.sh <project-root>
```

3. Generate and validate stack-aware harness scripts:

```sh
<runtime-root>/tools/harness/generate-harness.sh --project-root <project-root> --sdlc-agents-root <runtime-root>
<runtime-root>/tools/harness/validate-generated-harness.sh --project-root <project-root>
```

4. Create or refresh the initial feature package if one does not exist yet.
5. Populate `agent-context/extensions/skills/domain/project-domains.md` and `project-risks.md` from code, docs, and system boundaries.
6. For legacy projects without architecture checks, produce an architecture discovery report and capture existing violations as debt rather than blockers.
7. Verify health by running the generated harness scripts.
8. Record the initialization outcome in `agent-context/harness/progress-log.md`.

## Deliverables

- `agent-context/` scaffold exists and is usable.
- Harness scripts are generated and validated.
- Domain and risk skill templates are populated with project-specific content.
- The project has an initial feature package or a clearly documented next step for planning.

## Guardrails

- Keep initialization idempotent.
- Do not add business logic.
- Generated shell scripts must stay POSIX-compatible unless a tool explicitly requires Bash.
- If validation fails, stop and fix the generation inputs before proceeding.
