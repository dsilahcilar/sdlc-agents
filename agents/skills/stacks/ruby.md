# Ruby Stack

Stack: Ruby, Rails
Package Manager: Bundler

---

## Detection

| File | Indicator |
|------|-----------|
| `Gemfile` | Ruby project |
| `*.gemspec` | Ruby gem |
| `config.ru` | Rack application |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | RSpec | `bundle exec rspec` | `spec/` directory exists |
| test | Minitest | `ruby -Itest test/**/*_test.rb` | `test/` directory exists |
| lint | RuboCop | `bundle exec rubocop` | `.rubocop.yml` exists |
| lint | Standard | `bundle exec standardrb` | `standard` in Gemfile |
| coverage | SimpleCov | `COVERAGE=true bundle exec rspec` | `simplecov` in Gemfile |
| security | Brakeman | `bundle exec brakeman -q` | Rails app |
| security | Bundler Audit | `bundle exec bundle-audit check --update` | `bundler-audit` in Gemfile |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| Packwerk | `bundle exec packwerk check` | `packwerk.yml` exists |

**Fallback:** Skip with message suggesting Packwerk for Rails apps.

### Feature Runner

```sh
bundle exec rspec
# or
bundle exec rails test
```

### Init Project

```sh
bundle install
```

---

## Architecture Enforcement: Packwerk

**Setup:**
```bash
bundle add packwerk --group development
bin/packwerk init
```

---

## Project Structure (Packwerk)

```
app/
├── packages/
│   ├── users/
│   │   ├── package.yml
│   │   ├── app/
│   │   │   ├── models/
│   │   │   └── services/
│   │   └── spec/
│   └── orders/
│       ├── package.yml
│       └── app/
└── package.yml  # Root package
```

---

## Package Configuration

Create `packages/users/package.yml`:

```yaml
enforce_dependencies: true
enforce_privacy: true

dependencies:
  - .  # Root package only
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Cross-package dependency | Add to dependencies or extract shared package |
| Privacy violation | Make service public or use interface |
| Circular reference | Introduce events or shared interface |

---

## Existing Tests Check

```bash
[ -f "packwerk.yml" ] && echo "Found Packwerk"
```
