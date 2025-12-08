# Go Architecture Skill

Stack: Go
Tool: **go-arch-lint**

---

## Architecture Enforcement Tool

**go-arch-lint** - Static analysis tool for Go architecture.

```bash
go install github.com/fe3dback/go-arch-lint@latest
```

---

## Discovery Commands

```bash
# List all packages
go list ./...

# Show module dependencies
go mod graph

# Find import cycles (built-in)
go build ./... 2>&1 | grep "import cycle"

# Visualize dependencies
go mod graph | grep -v "@" | head -30

# List internal packages
find . -type d -name "internal" -o -name "pkg" | head -20

# Find imports in a package
go list -f '{{range .Imports}}{{.}}{{"\n"}}{{end}}' ./internal/domain
```

---

## Generated Rules Template

Create `.go-arch-lint.yaml`:

```yaml
version: 3
workdir: .

allow:
  depOnAnyVendor: false

components:
  # Domain layer - pure business logic
  domain:
    in: internal/domain/**

  # Application layer - use cases
  application:
    in: internal/application/**

  # Infrastructure layer - external concerns
  infrastructure:
    in: internal/infrastructure/**

  # Presentation layer - HTTP, gRPC, CLI
  presentation:
    in: internal/api/**
    in: internal/handlers/**
    in: cmd/**

  # Shared utilities
  shared:
    in: pkg/**

commonComponents:
  - shared

deps:
  # Domain depends on nothing
  domain:
    canDependOn: []

  # Application depends only on domain
  application:
    canDependOn:
      - domain

  # Infrastructure can depend on domain and application
  infrastructure:
    canDependOn:
      - domain
      - application

  # Presentation can depend on application
  presentation:
    canDependOn:
      - application
      - domain

commonVendors:
  - context
  - errors
  - fmt
  - strings
  - time
```

---

## Run Commands

```bash
# Run architecture check
go-arch-lint check

# Check with verbose output
go-arch-lint check --verbose

# Check specific component
go-arch-lint check --project-path ./internal/domain

# Visualize architecture
go-arch-lint graph
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain imports `database/sql` | Use repository interface |
| Domain imports `net/http` | Move to presentation layer |
| Import cycle detected | Use dependency injection |
| Package imports sibling | Extract to shared package or interface |

---

## Existing Tests Check

```bash
# Check for go-arch-lint config
[ -f ".go-arch-lint.yaml" ] && echo "Found"

# Check if tool is installed
command -v go-arch-lint >/dev/null && echo "go-arch-lint installed"
```

---

## Standard Go Project Layout

```
myapp/
├── cmd/                    # Application entrypoints
│   └── api/
│       └── main.go
├── internal/               # Private application code
│   ├── domain/             # Business entities
│   │   ├── user.go
│   │   └── order.go
│   ├── application/        # Use cases
│   │   └── services/
│   ├── infrastructure/     # External implementations
│   │   ├── postgres/
│   │   └── redis/
│   └── api/                # HTTP handlers
│       └── handlers/
├── pkg/                    # Public libraries
└── go.mod
```

---

## Additional Tools

### govulncheck (security)
```bash
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```

### golangci-lint (comprehensive linting)
```bash
golangci-lint run
```

### goimports (import organization)
```bash
goimports -w .
```

---

## Go-Specific Patterns

### Dependency Injection
```go
// Domain defines interface
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// Infrastructure implements
type PostgresUserRepo struct { db *sql.DB }

// Application uses interface
type UserService struct {
    repo UserRepository  // Interface, not concrete type
}
```

### Package Naming
- `internal/` - Private to module
- `pkg/` - Public, reusable
- Avoid `util`, `common`, `misc`
