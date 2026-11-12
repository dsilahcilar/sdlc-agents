# Rust Stack

Stack: Rust
Build Tool: Cargo

---

## Detection

| File | Indicator |
|------|-----------|
| `Cargo.toml` | Rust project |
| `*.rs` files | Rust source code |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | cargo test | `cargo test` | Always available |
| lint | clippy | `cargo clippy -- -D warnings` | Always available |
| lint | rustfmt | `cargo fmt --check` | Always available |
| coverage | tarpaulin | `cargo tarpaulin` | `cargo-tarpaulin` installed |
| coverage | grcov | `grcov . -o coverage/` | `grcov` installed |
| security | cargo-audit | `cargo audit` | `cargo-audit` installed |
| security | cargo-deny | `cargo deny check` | `deny.toml` exists |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| cargo check | `cargo check 2>&1 \| grep -i "cycle"` | Always available |
| clippy | `cargo clippy` | Always available |

**Note:** Rust's module system inherently prevents many architectural violations. Clippy catches the rest.

### Feature Runner

```sh
cargo test
```

### Init Project

```sh
cargo build --quiet
```

---

## Architecture Enforcement

Rust's module system enforces visibility rules:
- `pub` controls what's exported
- `pub(crate)` for crate-internal visibility
- `pub(super)` for parent module visibility

---

## Project Structure Template

```
src/
├── lib.rs           # Library root
├── main.rs          # Binary entry (optional)
├── domain/
│   ├── mod.rs       # pub(crate) exports
│   └── entities.rs
├── application/
│   ├── mod.rs
│   └── services.rs
├── infrastructure/
│   ├── mod.rs
│   └── repositories.rs
└── api/
    ├── mod.rs
    └── handlers.rs
```

---

## Visibility Rules

```rust
// In domain/mod.rs
pub mod entities;  // Only export what other modules need

// In domain/entities.rs
pub struct User { /* fields */ }  // Public to crate

// Keep implementation details private
struct UserValidator { /* fields */ }  // Private to module
```

---

## Clippy Configuration

Create `clippy.toml`:

```toml
avoid-breaking-exported-api = false
cognitive-complexity-threshold = 15
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
cognitive_complexity = "warn"
too_many_arguments = "warn"
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Cycle detected | Restructure modules, use traits |
| Too public | Reduce visibility with `pub(crate)` |
| Leaky abstraction | Hide implementation behind trait |
| High complexity | Split into smaller functions |

---

## Existing Tests Check

```bash
[ -f "clippy.toml" ] && echo "Found clippy config"
grep -q "\[lints.clippy\]" Cargo.toml 2>/dev/null && echo "Found clippy in Cargo.toml"
```
