# TypeScript Stack

Stack: TypeScript, JavaScript, Node.js, React, Vue, Angular
Package Managers: npm, yarn, pnpm

---

## Detection

| File | Indicator |
|------|-----------|
| `package.json` | Node.js project |
| `tsconfig.json` | TypeScript project |
| `*.ts` or `*.tsx` files | TypeScript code |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | npm | `npm test` | `scripts.test` in package.json |
| test | Jest | `npx jest` | `jest.config.*` exists |
| test | Vitest | `npx vitest run` | `vitest.config.*` exists |
| lint | ESLint | `npm run lint` or `npx eslint .` | `.eslintrc.*` exists |
| lint | Biome | `npx biome check .` | `biome.json` exists |
| coverage | Jest | `npx jest --coverage` | jest in dependencies |
| coverage | Vitest | `npx vitest run --coverage` | vitest in dependencies |
| coverage | nyc | `npx nyc npm test` | nyc in dependencies |
| security | npm audit | `npm audit --audit-level=moderate` | Always available |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| dependency-cruiser | `npx depcruise src --config` | `.dependency-cruiser.*` exists |
| madge | `npx madge --circular --extensions ts,tsx,js,jsx src/` | Always works |

**Fallback:** Use madge for circular dependency detection (no config needed).

### Feature Runner

```sh
npm test
# or with pattern
npm test -- --testPathPattern="$FEATURE_ID"
```

### Init Project

```sh
npm install
# or
yarn install
# or
pnpm install
```

---

## Architecture Enforcement: Dependency Cruiser

**Setup:**
```bash
npm install --save-dev dependency-cruiser
npx depcruise --init
```

---

## Rule Template

Create `.dependency-cruiser.js`:

```javascript
module.exports = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      from: {},
      to: { circular: true }
    },
    {
      name: 'no-domain-to-infrastructure',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/infrastructure' }
    },
    {
      name: 'no-domain-to-presentation',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/(components|pages|views|ui)' }
    },
    {
      name: 'no-cross-feature-imports',
      severity: 'warn',
      from: { path: '^src/features/([^/]+)/' },
      to: {
        path: '^src/features/([^/]+)/',
        pathNot: '^src/features/$1/'
      }
    }
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' }
  }
};
```

---

## ESLint Import Rules

```javascript
// .eslintrc.js
module.exports = {
  plugins: ['import'],
  rules: {
    'import/no-cycle': 'error',
    'import/no-restricted-paths': ['error', {
      zones: [
        { target: './src/domain', from: './src/infrastructure' },
        { target: './src/domain', from: './src/components' }
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
| Component imports API | Add service layer |

---

## Existing Tests Check

```bash
[ -f ".dependency-cruiser.js" ] && echo "Found dependency-cruiser"
grep -r "import/no-cycle" .eslintrc* package.json 2>/dev/null
```
