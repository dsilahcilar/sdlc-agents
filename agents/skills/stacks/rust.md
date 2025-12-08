# Rust Architecture Skill

Stack: Rust
Tools: **cargo-modules**, **clippy**

---

## Architecture Enforcement Tools

### cargo-modules (structure visualization)
```bash
cargo install cargo-modules
```

### clippy (linting)
```bash
# Built-in with rustup
rustup component add clippy
```

---

## Discovery Commands

```bash
# Show module structure
cargo modules structure

# Show module dependencies
cargo modules dependencies

# Check for cycles
cargo modules dependencies --lib 2>&1 | grep -i "cycle"

# Show dependency tree
cargo tree

# Find all modules
find src -name "*.rs" | head -30

# List public items
cargo doc --document-private-items 2>&1 | head -50
```

---

## Generated Rules Template

Rust enforces architecture through module visibility. Use `Cargo.toml` workspace and module structure:

### Workspace Layout (for larger projects)
```toml
# Cargo.toml (workspace root)
[workspace]
members = [
    "crates/domain",
    "crates/application",
    "crates/infrastructure",
    "crates/api",
]

# Dependency rules via workspace dependencies
[workspace.dependencies]
domain = { path = "crates/domain" }
application = { path = "crates/application" }
infrastructure = { path = "crates/infrastructure" }
```

### Domain Crate (pure, no external deps)
```toml
# crates/domain/Cargo.toml
[package]
name = "domain"

[dependencies]
# Only standard library, no external crates
```

### Application Crate
```toml
# crates/application/Cargo.toml
[package]
name = "application"

[dependencies]
domain = { workspace = true }
# No infrastructure dependencies!
```

### Infrastructure Crate
```toml
# crates/infrastructure/Cargo.toml
[package]
name = "infrastructure"

[dependencies]
domain = { workspace = true }
application = { workspace = true }
sqlx = "0.7"  # External deps OK here
```

---

## Module Visibility Rules

```rust
// src/lib.rs - Control what's exposed

// Public to other crates
pub mod domain;

// Private to this crate
mod internal_utils;

// Re-export specific items
pub use domain::User;

// Restrict visibility
pub(crate) mod crate_internal;
pub(super) mod parent_only;
```

---

## Run Commands

```bash
# Check compilation (catches most issues)
cargo check

# Run clippy with strict settings
cargo clippy -- -D warnings -D clippy::all

# Visualize modules
cargo modules structure --lib

# Check dependencies
cargo modules dependencies --lib

# Full test suite
cargo test
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain uses external crate | Move to infrastructure or use traits |
| Circular mod dependency | Extract to separate module |
| Public internals | Use `pub(crate)` or `pub(super)` |
| Leaky abstraction | Use trait objects or generics |

---

## Existing Tests Check

```bash
# Check for workspace structure
grep -q "\[workspace\]" Cargo.toml && echo "Workspace found"

# Check clippy configuration
[ -f ".clippy.toml" ] && echo "Clippy config found"
[ -f "clippy.toml" ] && echo "Clippy config found"

# Check for deny.toml (cargo-deny)
[ -f "deny.toml" ] && echo "cargo-deny config found"
```

---

## Recommended Project Structure

```
myapp/
├── Cargo.toml              # Workspace definition
├── crates/
│   ├── domain/             # Pure business logic
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── entities/
│   │       └── value_objects/
│   ├── application/        # Use cases
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       └── services/
│   ├── infrastructure/     # External concerns
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── postgres/
│   │       └── redis/
│   └── api/                # HTTP handlers
│       ├── Cargo.toml
│       └── src/
│           └── main.rs
└── tests/                  # Integration tests
```

---

## Additional Tools

### cargo-deny (dependency auditing)
```bash
cargo install cargo-deny
cargo deny check
```

### cargo-audit (security)
```bash
cargo install cargo-audit
cargo audit
```

---

## Rust-Specific Patterns

### Trait-based Abstraction
```rust
// domain/src/lib.rs
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: Uuid) -> Result<User, Error>;
}

// infrastructure/src/postgres.rs
pub struct PostgresUserRepo { pool: PgPool }

impl UserRepository for PostgresUserRepo {
    async fn find_by_id(&self, id: Uuid) -> Result<User, Error> {
        // Implementation
    }
}
```

### Error Handling Layers
```rust
// domain errors
#[derive(Debug, thiserror::Error)]
pub enum DomainError { ... }

// infrastructure converts to domain errors
impl From<sqlx::Error> for DomainError { ... }
```
