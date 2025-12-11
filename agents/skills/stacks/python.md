# Python Architecture Skill

Stack: Python, Django, Flask, FastAPI
Tool: **Import Linter**

---

## Architecture Enforcement Tool

**Import Linter** - Enforces architectural constraints on Python imports.

**Setup:**
```bash
pip install import-linter
```

---

## Discovery Commands

```bash
# List all modules
find . -name "*.py" -not -path "./venv/*" -not -path "./.venv/*" | head -50

# Find all packages (directories with __init__.py)
find . -name "__init__.py" -not -path "./venv/*" | sed 's|/__init__.py||' | sort

# Find imports
grep -r "^import\|^from" . --include="*.py" | grep -v venv | head -50

# Check for circular imports (basic)
python -c "import myapp" 2>&1 | grep -i "circular\|cycle"

# Visualize dependencies (requires pydeps)
pip install pydeps
pydeps myapp --cluster --max-bacon=2
```

---

## Generated Rules Template

Create `.importlinter` in project root:

```ini
[importlinter]
root_package = myapp
include_external_packages = False

[importlinter:contract:layers]
name = Layered architecture
type = layers
layers =
    myapp.presentation
    myapp.application
    myapp.domain
    myapp.infrastructure
containers =
    myapp

[importlinter:contract:domain-independence]
name = Domain should not import infrastructure
type = forbidden
source_modules =
    myapp.domain
forbidden_modules =
    myapp.infrastructure
    myapp.presentation

[importlinter:contract:no-cross-feature]
name = Features should not import each other
type = independence
modules =
    myapp.features.users
    myapp.features.orders
    myapp.features.payments
```

Or in `pyproject.toml`:

```toml
[tool.importlinter]
root_package = "myapp"

[[tool.importlinter.contracts]]
name = "Layered architecture"
type = "layers"
layers = [
    "myapp.presentation",
    "myapp.application",
    "myapp.domain",
    "myapp.infrastructure",
]

[[tool.importlinter.contracts]]
name = "Domain independence"
type = "forbidden"
source_modules = ["myapp.domain"]
forbidden_modules = ["myapp.infrastructure", "myapp.presentation"]
```

---

## Run Commands

```bash
# Run import linter
lint-imports

# Or via Python
python -m importlinter

# Check specific contract
lint-imports --contract "Layered architecture"
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain imports SQLAlchemy | Use repository pattern with interfaces |
| Domain imports Flask/Django | Extract to presentation layer |
| Circular import | Use dependency injection or events |
| Feature imports feature | Use shared module or message bus |

---

## Existing Tests Check

```bash
# Check for import-linter config
[ -f ".importlinter" ] && echo "Found .importlinter"
grep -q "importlinter" pyproject.toml 2>/dev/null && echo "Found in pyproject.toml"
grep -q "importlinter" setup.cfg 2>/dev/null && echo "Found in setup.cfg"
```

---

## Framework-Specific Notes

### Django
```
myproject/
├── apps/
│   ├── users/           # Feature module
│   │   ├── models.py    # Domain
│   │   ├── views.py     # Presentation
│   │   └── services.py  # Application
│   └── orders/
├── core/                # Shared domain
└── infrastructure/      # DB, external services
```

### FastAPI
```
myapp/
├── api/                 # Presentation (routers)
├── services/            # Application
├── domain/              # Entities, value objects
├── repositories/        # Infrastructure
└── core/                # Shared config, deps
```

### Flask
```
myapp/
├── blueprints/          # Presentation
├── services/            # Application
├── models/              # Domain
└── adapters/            # Infrastructure
```

---

## Additional Tools

### pydeps (visualization)
```bash
pip install pydeps
pydeps myapp --cluster -o deps.svg
```

### pylint (import order)
```bash
pip install pylint
pylint --disable=all --enable=wrong-import-order myapp/
```
