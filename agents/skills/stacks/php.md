# PHP Architecture Skill

Stack: PHP, Laravel, Symfony
Tool: **Deptrac**

---

## Architecture Enforcement Tool

**Deptrac** - Static code analysis for PHP architecture.

```bash
composer require --dev qossmic/deptrac-shim
```

---

## Discovery Commands

```bash
# List all namespaces
grep -r "^namespace" src --include="*.php" | sort -u

# Find use statements
grep -r "^use " src --include="*.php" | sort | uniq -c | sort -rn | head -30

# List classes
grep -r "^class\|^interface\|^trait" src --include="*.php" | head -30

# Find controller classes
find . -path "*/Controller/*.php" -o -path "*/Controllers/*.php" | head -20

# Find dependencies
grep -r "new \|::" src --include="*.php" | head -30
```

---

## Generated Rules Template

Create `deptrac.yaml`:

```yaml
deptrac:
  paths:
    - ./src

  exclude_files:
    - '#.*test.*#i'

  layers:
    - name: Controller
      collectors:
        - type: className
          regex: .*Controller$
        - type: directory
          regex: src/Controller/.*

    - name: Service
      collectors:
        - type: directory
          regex: src/Service/.*
        - type: directory
          regex: src/Application/.*

    - name: Domain
      collectors:
        - type: directory
          regex: src/Domain/.*
        - type: directory
          regex: src/Entity/.*

    - name: Infrastructure
      collectors:
        - type: directory
          regex: src/Infrastructure/.*
        - type: directory
          regex: src/Repository/.*

  ruleset:
    Controller:
      - Service
      - Domain

    Service:
      - Domain
      - Infrastructure

    Domain: ~  # Cannot depend on anything

    Infrastructure:
      - Domain

  skip_violations:
    # Temporarily skip known violations
    # App\Domain\User:
    #   - App\Infrastructure\Doctrine\UserRepository
```

---

## Run Commands

```bash
# Run analysis
./vendor/bin/deptrac analyse

# With specific config
./vendor/bin/deptrac analyse --config-file=deptrac.yaml

# Generate baseline (for legacy code)
./vendor/bin/deptrac analyse --formatter=baseline > deptrac.baseline.yaml

# Output as graph
./vendor/bin/deptrac analyse --formatter=graphviz-image --output=deps.png
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain uses Doctrine | Define repository interfaces in domain |
| Entity uses HttpFoundation | Move HTTP logic to controller |
| Circular dependency | Use interfaces or events |
| Controller has business logic | Extract to service class |

---

## Existing Tests Check

```bash
# Check for Deptrac
[ -f "deptrac.yaml" ] && echo "Deptrac config found"
[ -f "deptrac.yml" ] && echo "Deptrac config found"
grep -q "deptrac" composer.json && echo "Deptrac in composer.json"
```

---

## Framework-Specific Structures

### Symfony
```
src/
├── Controller/          # Presentation
├── Service/             # Application
├── Domain/              # Business logic
│   ├── Entity/
│   ├── ValueObject/
│   └── Repository/      # Interfaces only
├── Infrastructure/      # Implementations
│   ├── Doctrine/
│   └── ExternalApi/
└── EventSubscriber/
```

### Laravel
```
app/
├── Http/
│   └── Controllers/     # Presentation
├── Services/            # Application
├── Domain/              # Business logic
│   ├── Models/
│   └── ValueObjects/
├── Repositories/        # Data access
│   ├── Contracts/       # Interfaces
│   └── Eloquent/        # Implementations
└── Providers/
```

---

## Deptrac for Laravel

```yaml
deptrac:
  paths:
    - ./app

  layers:
    - name: Controller
      collectors:
        - type: directory
          regex: app/Http/Controllers/.*

    - name: Service
      collectors:
        - type: directory
          regex: app/Services/.*

    - name: Domain
      collectors:
        - type: directory
          regex: app/Domain/.*

    - name: Repository
      collectors:
        - type: directory
          regex: app/Repositories/.*

    - name: Model
      collectors:
        - type: directory
          regex: app/Models/.*

  ruleset:
    Controller:
      - Service
      - Model

    Service:
      - Domain
      - Repository
      - Model

    Domain: ~

    Repository:
      - Model
      - Domain

    Model:
      - Domain
```

---

## Additional Tools

### PHPStan (static analysis)
```bash
composer require --dev phpstan/phpstan
./vendor/bin/phpstan analyse src
```

### Psalm (type checking)
```bash
composer require --dev vimeo/psalm
./vendor/bin/psalm
```

### PHP_CodeSniffer
```bash
composer require --dev squizlabs/php_codesniffer
./vendor/bin/phpcs src
```

---

## PHP-Specific Patterns

### Interface-based Abstraction
```php
// src/Domain/Repository/UserRepositoryInterface.php
namespace App\Domain\Repository;

interface UserRepositoryInterface
{
    public function find(int $id): ?User;
    public function save(User $user): void;
}

// src/Infrastructure/Doctrine/UserRepository.php
namespace App\Infrastructure\Doctrine;

class UserRepository implements UserRepositoryInterface
{
    public function __construct(private EntityManagerInterface $em) {}

    public function find(int $id): ?User
    {
        return $this->em->find(User::class, $id);
    }
}
```

### Service Layer
```php
// src/Service/UserService.php
namespace App\Service;

class UserService
{
    public function __construct(
        private UserRepositoryInterface $userRepository
    ) {}

    public function createUser(array $data): User
    {
        $user = new User($data);
        $this->userRepository->save($user);
        return $user;
    }
}
```
