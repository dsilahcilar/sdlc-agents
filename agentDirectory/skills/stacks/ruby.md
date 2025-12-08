# Ruby Architecture Skill

Stack: Ruby, Rails
Tool: **Packwerk**

---

## Architecture Enforcement Tool

**Packwerk** - Enforce boundaries in Rails applications.

```ruby
# Gemfile
gem 'packwerk', group: [:development, :test]
```

```bash
bundle install
bin/packwerk init
```

---

## Discovery Commands

```bash
# List all modules/classes
find app lib -name "*.rb" | xargs grep -h "^class\|^module" | sort -u | head -30

# Find requires
grep -r "require\|require_relative" app lib --include="*.rb" | head -30

# List Rails models
ls app/models/*.rb 2>/dev/null | head -20

# List controllers
ls app/controllers/**/*.rb 2>/dev/null | head -20

# Find cross-references
grep -r "class.*<\|include\|extend" app --include="*.rb" | head -30
```

---

## Generated Rules Template

### Initialize Packwerk

```bash
bin/packwerk init
```

### Create Package Structure

For each bounded context, create `package.yml`:

```yaml
# app/packages/users/package.yml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - '.'  # Root package only, no other features
```

```yaml
# app/packages/orders/package.yml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - '.'
  - 'users'  # Can depend on users package
```

### Root Package

```yaml
# package.yml (root)
enforce_dependencies: true
enforce_privacy: false
```

### Packwerk Config

```yaml
# packwerk.yml
include:
  - "**/*.rb"
exclude:
  - "vendor/**"
  - "tmp/**"
  - "log/**"
  - "node_modules/**"
package_paths:
  - "."
  - "app/packages/*"
```

---

## Run Commands

```bash
# Check for violations
bin/packwerk check

# Update cache
bin/packwerk update-todo

# Validate configuration
bin/packwerk validate
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Cross-package reference | Add to dependencies or use public API |
| Private constant access | Expose via public interface |
| Circular dependency | Extract shared code or use events |
| Direct model access | Use service object or repository |

---

## Existing Tests Check

```bash
# Check for Packwerk
[ -f "packwerk.yml" ] && echo "Packwerk config found"
grep -q "packwerk" Gemfile && echo "Packwerk in Gemfile"

# Check for package.yml files
find . -name "package.yml" | head -10
```

---

## Recommended Rails Structure

### Traditional (Monolith)
```
app/
├── controllers/
├── models/
├── services/          # Application layer
├── repositories/      # Data access abstraction
└── lib/
    └── domain/        # Pure business logic
```

### Packwerk-based (Modular Monolith)
```
app/
├── packages/
│   ├── users/
│   │   ├── package.yml
│   │   ├── app/
│   │   │   ├── controllers/
│   │   │   ├── models/
│   │   │   └── services/
│   │   └── public/      # Public API
│   │       └── user_api.rb
│   ├── orders/
│   │   ├── package.yml
│   │   ├── app/
│   │   └── public/
│   └── payments/
├── controllers/         # Shared/legacy
└── models/              # Shared/legacy
```

---

## Public API Pattern

```ruby
# app/packages/users/public/user_api.rb
module Users
  class Api
    def self.find_user(id)
      User.find(id)
    end

    def self.create_user(params)
      UserService.new.create(params)
    end
  end
end

# Other packages use the public API
Users::Api.find_user(123)
# NOT: Users::User.find(123)  # This would be a violation
```

---

## Additional Tools

### Rubocop (linting)
```ruby
# Gemfile
gem 'rubocop', require: false
gem 'rubocop-rails', require: false
```

### Rails Best Practices
```bash
gem install rails_best_practices
rails_best_practices .
```

### Reek (code smells)
```bash
gem install reek
reek app/
```

---

## Rails-Specific Patterns

### Service Objects
```ruby
# app/services/users/create_user.rb
module Users
  class CreateUser
    def initialize(repository: UserRepository.new)
      @repository = repository
    end

    def call(params)
      user = User.new(params)
      @repository.save(user)
    end
  end
end
```

### Repository Pattern
```ruby
# app/repositories/user_repository.rb
class UserRepository
  def find(id)
    User.find(id)
  end

  def save(user)
    user.save!
    user
  end
end
```
