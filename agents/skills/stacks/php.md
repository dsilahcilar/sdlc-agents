# PHP Stack

Stack: PHP, Laravel, Symfony
Package Manager: Composer

---

## Detection

| File | Indicator |
|------|-----------|
| `composer.json` | PHP project |
| `artisan` | Laravel project |
| `bin/console` | Symfony project |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | PHPUnit | `./vendor/bin/phpunit` | `phpunit.xml` exists |
| test | Pest | `./vendor/bin/pest` | `pest` in composer.json |
| lint | PHP_CodeSniffer | `./vendor/bin/phpcs` | `phpcs.xml` exists |
| lint | PHP-CS-Fixer | `./vendor/bin/php-cs-fixer fix --dry-run` | `.php-cs-fixer.php` exists |
| lint | PHPStan | `./vendor/bin/phpstan analyse` | `phpstan.neon` exists |
| lint | Psalm | `./vendor/bin/psalm` | `psalm.xml` exists |
| coverage | PHPUnit | `./vendor/bin/phpunit --coverage-text` | Xdebug/PCOV installed |
| security | Composer | `composer audit` | Always available (Composer 2.4+) |
| security | Local PHP Security | `./vendor/bin/local-php-security-checker` | Tool installed |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| Deptrac | `./vendor/bin/deptrac analyse` | `deptrac.yaml` exists |

**Fallback:** Skip with message suggesting Deptrac.

### Feature Runner

```sh
./vendor/bin/phpunit
```

### Init Project

```sh
composer install
```

---

## Architecture Enforcement: Deptrac

**Setup:**
```bash
composer require --dev qossmic/deptrac-shim
```

---

## Rule Template

Create `deptrac.yaml`:

```yaml
deptrac:
  paths:
    - ./src

  layers:
    - name: Controller
      collectors:
        - type: classLike
          value: App\\Controller\\.*
    - name: Service
      collectors:
        - type: classLike
          value: App\\Service\\.*
    - name: Domain
      collectors:
        - type: classLike
          value: App\\Domain\\.*
    - name: Repository
      collectors:
        - type: classLike
          value: App\\Repository\\.*

  ruleset:
    Controller:
      - Service
    Service:
      - Domain
      - Repository
    Repository:
      - Domain
    Domain: []  # No dependencies allowed
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain uses Doctrine | Use repository interface |
| Controller accesses repository | Add service layer |
| Circular dependency | Extract interface |
| Feature imports feature | Use events or shared service |

---

## Existing Tests Check

```bash
[ -f "deptrac.yaml" ] && echo "Found Deptrac"
[ -f "deptrac.yml" ] && echo "Found Deptrac"
```
