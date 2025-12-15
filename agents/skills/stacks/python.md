# Python Stack

Stack: Python, Django, Flask, FastAPI
Package Managers: pip, poetry, pipenv

---

## Detection

| File | Indicator |
|------|-----------|
| `pyproject.toml` | Modern Python project |
| `setup.py` | Legacy setuptools project |
| `requirements.txt` | pip dependencies |
| `Pipfile` | pipenv project |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | pytest | `pytest` | `pytest.ini` or pyproject.toml `[tool.pytest]` |
| test | unittest | `python -m unittest discover` | No pytest installed |
| lint | ruff | `ruff check .` | `ruff.toml` or pyproject.toml `[tool.ruff]` |
| lint | flake8 | `flake8` | `.flake8` or setup.cfg `[flake8]` |
| lint | pylint | `pylint src/` | `.pylintrc` or pyproject.toml |
| lint | mypy | `mypy src/` | `mypy.ini` or pyproject.toml `[tool.mypy]` |
| coverage | pytest-cov | `pytest --cov=src` | `pytest-cov` in dependencies |
| security | bandit | `bandit -r src/` | `bandit` in dependencies |
| security | safety | `safety check` | `safety` in dependencies |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| import-linter | `lint-imports` | `.importlinter` or pyproject.toml `[tool.importlinter]` |

**Fallback:** Skip with message suggesting import-linter installation.

### Feature Runner

```sh
# With module specified
pytest "src/$FEATURE_MODULE" -v

# Without module
pytest
```

### Init Project

```sh
# Poetry
poetry install

# pip with requirements.txt
pip install -r requirements.txt

# pip with pyproject.toml
pip install -e .
```

---

## Architecture Enforcement: Import Linter

**Setup:**
```bash
pip install import-linter
```

---

## Rule Template

Add to `pyproject.toml`:

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

Or `.importlinter`:

```ini
[importlinter]
root_package = myapp

[importlinter:contract:layers]
name = Layered architecture
type = layers
layers =
    myapp.presentation
    myapp.application
    myapp.domain
    myapp.infrastructure
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
[ -f ".importlinter" ] && echo "Found .importlinter"
grep -q "importlinter" pyproject.toml 2>/dev/null && echo "Found in pyproject.toml"
```
