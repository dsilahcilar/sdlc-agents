# TypeScript/JavaScript Architecture Skill

Stack: TypeScript, JavaScript, Node.js, React, Vue, Angular
Tools: **Dependency Cruiser**, **Madge**, **ESLint**

---

## Architecture Enforcement Tools

**Primary: Dependency Cruiser**
```bash
npm install --save-dev dependency-cruiser
npx depcruise --init
```

**Secondary: Madge** (circular dependency detection)
```bash
npx madge --circular --extensions ts,tsx,js,jsx src/
```

**Tertiary: ESLint import rules**
- Add `eslint-plugin-import` as dev dependency

---

## Available Tools

> **Progressive Disclosure:** Use these tools instead of embedding scripts.
> See each tool's `.md` file for detailed usage before executing.

### Discovery Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `.github/tools/discovery/list-packages.sh` | List directories | Initial analysis |
| `.github/tools/discovery/find-imports.sh` | Find import statements | Mapping dependencies |
| `.github/tools/discovery/detect-layers.sh` | Identify layers | Before rule generation |
| `.github/tools/discovery/count-files.sh` | Count files per dir | Understanding scale |

### Validation Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `.github/tools/stack/ts/depcruise.sh` | Run Dependency Cruiser | After code changes |
| `.github/tools/stack/ts/madge.sh` | Detect circular deps | Quick cycle check |
| `.github/tools/validation/check-layers.sh` | Layer validation | Before full validation |
| `.github/tools/validation/check-circular.sh` | Generic circular check | Any stack |

---

## Quick Commands

For immediate execution without reading tool docs:

```bash
# Run Dependency Cruiser
.github/tools/stack/ts/depcruise.sh src

# Check circular dependencies
.github/tools/stack/ts/madge.sh src
```

---

## Generated Rules Template

Create `.dependency-cruiser.js`:

```javascript
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    // No circular dependencies
    {
      name: 'no-circular',
      severity: 'error',
      comment: 'Circular dependencies cause tight coupling',
      from: {},
      to: { circular: true }
    },

    // Domain cannot depend on infrastructure
    {
      name: 'no-domain-to-infrastructure',
      severity: 'error',
      comment: 'Domain layer must be pure',
      from: { path: '^src/domain' },
      to: { path: '^src/infrastructure' }
    },

    // Domain cannot depend on presentation
    {
      name: 'no-domain-to-presentation',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/(components|pages|views|ui)' }
    },

    // Features should not depend on each other directly
    {
      name: 'no-cross-feature-imports',
      severity: 'warn',
      comment: 'Features should communicate through shared modules',
      from: { path: '^src/features/([^/]+)/' },
      to: {
        path: '^src/features/([^/]+)/',
        pathNot: '^src/features/$1/'
      }
    },

    // No orphan modules
    {
      name: 'no-orphans',
      severity: 'warn',
      from: { orphan: true, pathNot: '\\.d\\.ts$' },
      to: {}
    }
  ],

  options: {
    doNotFollow: {
      path: 'node_modules'
    },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' },
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default']
    }
  }
};
```

---

## ESLint Configuration

Add to `.eslintrc.js`:

```javascript
module.exports = {
  plugins: ['import'],
  rules: {
    'import/no-cycle': 'error',
    'import/no-restricted-paths': ['error', {
      zones: [
        // Domain cannot import infrastructure
        {
          target: './src/domain',
          from: './src/infrastructure',
          message: 'Domain layer cannot depend on infrastructure'
        },
        // Domain cannot import UI
        {
          target: './src/domain',
          from: './src/components',
          message: 'Domain layer cannot depend on UI'
        }
      ]
    }]
  }
};
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Circular dependency | Extract shared code to separate module |
| Domain imports React | Move UI logic to components |
| Feature imports feature | Use shared module or events |
| Component imports API directly | Add service layer |

---

## Existing Tests Check

```bash
# Check for existing config
[ -f ".dependency-cruiser.js" ] && echo "Found dependency-cruiser config"

# Check for ESLint import rules
grep -r "import/no-cycle" .eslintrc* package.json 2>/dev/null
```

---

## Framework-Specific Notes

### React
- Components in `src/components`
- Pages/Routes in `src/pages`
- State management in `src/store`

### Angular
- Use `ng lint` with custom rules
- Consider `@nrwl/nx` for monorepo boundaries

### Vue
- Similar structure to React
- Consider `eslint-plugin-vue`

### Node.js/Express
- Controllers in `src/controllers`
- Services in `src/services`
- Models in `src/models`
