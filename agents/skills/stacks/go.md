# Go Stack

Stack: Go
Build Tool: go modules

---

## Detection

| File | Indicator |
|------|-----------|
| `go.mod` | Go module |
| `*.go` files | Go source code |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | go test | `go test ./...` | Always available |
| lint | golangci-lint | `golangci-lint run` | `.golangci.yml` or `.golangci.yaml` |
| lint | go vet | `go vet ./...` | Always available |
| lint | staticcheck | `staticcheck ./...` | `staticcheck` installed |
| coverage | go test | `go test -cover ./...` | Always available |
| coverage | go test (report) | `go test -coverprofile=coverage.out ./...` | Always available |
| security | govulncheck | `govulncheck ./...` | `govulncheck` installed |
| security | gosec | `gosec ./...` | `gosec` installed |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| go-arch-lint | `go-arch-lint check` | `.go-arch-lint.yaml` exists |
| go build | `go build ./... 2>&1 \| grep "import cycle"` | Always available (basic) |

**Fallback:** Use `go build` for basic cycle detection.

### Feature Runner

```sh
# With module specified
go test "./$FEATURE_MODULE/..."

# Without module
go test ./...
```

### Init Project

```sh
go build ./...
```

---

## Architecture Enforcement: go-arch-lint

**Setup:**
```bash
go install github.com/fe3dback/go-arch-lint@latest
```

---

## Rule Template

Create `.go-arch-lint.yaml`:

```yaml
version: 3
workdir: .

components:
  domain:
    in: internal/domain/**
  application:
    in: internal/application/**
  infrastructure:
    in: internal/infrastructure/**
  presentation:
    in: internal/api/**

deps:
  domain:
    mayDependOn: []
  application:
    mayDependOn:
      - domain
  infrastructure:
    mayDependOn:
      - domain
  presentation:
    mayDependOn:
      - application
      - domain

commonComponents:
  - internal/pkg/**
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Import cycle | Introduce interface in shared package |
| Domain imports database | Use repository interface |
| Handler imports repository | Add service layer |
| Package imports itself | Restructure package |

---

## Existing Tests Check

```bash
[ -f ".go-arch-lint.yaml" ] && echo "Found go-arch-lint config"
[ -f ".go-arch-lint.yml" ] && echo "Found go-arch-lint config"
```
