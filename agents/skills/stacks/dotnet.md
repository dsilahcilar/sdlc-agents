# .NET Stack

Stack: C#, F#, .NET
Build Tool: dotnet CLI, MSBuild

---

## Detection

| File | Indicator |
|------|-----------|
| `*.csproj` | C# project |
| `*.fsproj` | F# project |
| `*.sln` | Solution file |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | dotnet test | `dotnet test` | `*.csproj` with test references |
| lint | dotnet format | `dotnet format --verify-no-changes` | Always available |
| lint | StyleCop | `dotnet build /p:TreatWarningsAsErrors=true` | StyleCop.Analyzers in csproj |
| coverage | coverlet | `dotnet test --collect:"XPlat Code Coverage"` | coverlet in test project |
| security | dotnet list | `dotnet list package --vulnerable` | Always available |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| ArchUnitNET | `dotnet test --filter "Category=Architecture"` | ArchUnitNET in test project |
| NetArchTest | `dotnet test --filter "FullyQualifiedName~Architecture"` | NetArchTest.Rules in test project |

**Fallback:** Skip with message suggesting ArchUnitNET.

### Feature Runner

```sh
dotnet test
```

### Init Project

```sh
dotnet build
```

---

## Architecture Enforcement: ArchUnitNET

**Setup:**
```xml
<PackageReference Include="ArchUnitNET.xUnit" Version="0.10.6" />
```

---

## Rule Template

Create `ArchitectureTests.cs`:

```csharp
using ArchUnitNET.Fluent;
using ArchUnitNET.Loader;
using ArchUnitNET.xUnit;
using static ArchUnitNET.Fluent.ArchRuleDefinition;

[Trait("Category", "Architecture")]
public class ArchitectureTests
{
    private static readonly Architecture Architecture =
        new ArchLoader().LoadAssemblies(typeof(Program).Assembly).Build();

    [Fact]
    public void DomainShouldNotDependOnInfrastructure()
    {
        Types().That().ResideInNamespace("Domain")
            .Should().NotDependOnAny(
                Types().That().ResideInNamespace("Infrastructure"))
            .Check(Architecture);
    }

    [Fact]
    public void ServicesShouldHaveServiceSuffix()
    {
        Classes().That().ResideInNamespace("Application.Services")
            .Should().HaveNameEndingWith("Service")
            .Check(Architecture);
    }
}
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain references EF Core | Use repository interfaces |
| Controller accesses DbContext | Add service layer |
| Circular reference | Extract shared interface project |
| Missing suffix | Rename class |

---

## Existing Tests Check

```bash
grep -r "ArchUnitNET\|NetArchTest" *.csproj 2>/dev/null
```
