# C#/.NET Architecture Skill

Stack: C#, .NET, ASP.NET Core
Tools: **ArchUnitNET**, **NsDepCop**

---

## Architecture Enforcement Tools

**ArchUnitNET (recommended)**
- Add `TngTech.ArchUnitNET.xUnit` or `TngTech.ArchUnitNET.NUnit` test package

**NsDepCop (alternative)**
- Add `NsDepCop.Analyzer` package

---

## Discovery Commands

```bash
# List all namespaces
grep -r "^namespace" . --include="*.cs" | sort -u

# List all projects
find . -name "*.csproj" | head -20

# Show project references
dotnet list reference

# Show package dependencies
dotnet list package

# Find class definitions
grep -r "public class\|public interface" . --include="*.cs" | head -30
```

---

## Generated Rules Template

### ArchUnitNET Tests

Create `ArchitectureTests.cs`:

```csharp
using ArchUnitNET.Domain;
using ArchUnitNET.Fluent;
using ArchUnitNET.Loader;
using ArchUnitNET.xUnit;
using static ArchUnitNET.Fluent.ArchRuleDefinition;

namespace MyApp.Tests.Architecture;

public class ArchitectureTests
{
    private static readonly Architecture Architecture =
        new ArchLoader()
            .LoadAssemblies(
                typeof(Domain.User).Assembly,
                typeof(Application.UserService).Assembly,
                typeof(Infrastructure.UserRepository).Assembly,
                typeof(Api.Controllers.UserController).Assembly
            )
            .Build();

    private readonly IObjectProvider<IType> DomainLayer =
        Types().That().ResideInNamespace("MyApp.Domain", true);

    private readonly IObjectProvider<IType> ApplicationLayer =
        Types().That().ResideInNamespace("MyApp.Application", true);

    private readonly IObjectProvider<IType> InfrastructureLayer =
        Types().That().ResideInNamespace("MyApp.Infrastructure", true);

    private readonly IObjectProvider<IType> ApiLayer =
        Types().That().ResideInNamespace("MyApp.Api", true);

    [Fact]
    public void Domain_Should_Not_Depend_On_Infrastructure()
    {
        Types()
            .That().Are(DomainLayer)
            .Should().NotDependOnAny(InfrastructureLayer)
            .Check(Architecture);
    }

    [Fact]
    public void Domain_Should_Not_Depend_On_Application()
    {
        Types()
            .That().Are(DomainLayer)
            .Should().NotDependOnAny(ApplicationLayer)
            .Check(Architecture);
    }

    [Fact]
    public void Controllers_Should_Reside_In_Api_Namespace()
    {
        Classes()
            .That().HaveNameEndingWith("Controller")
            .Should().ResideInNamespace("MyApp.Api.Controllers", true)
            .Check(Architecture);
    }

    [Fact]
    public void Interfaces_Should_Start_With_I()
    {
        Interfaces()
            .Should().HaveNameStartingWith("I")
            .Check(Architecture);
    }
}
```

### NsDepCop Configuration

Create `config.nsdepcop` in project root:

```xml
<?xml version="1.0" encoding="utf-8"?>
<NsDepCopConfig IsEnabled="true" MaxIssueCount="100">
  <Allowed From="MyApp.Api.*" To="MyApp.Application.*" />
  <Allowed From="MyApp.Application.*" To="MyApp.Domain.*" />
  <Allowed From="MyApp.Infrastructure.*" To="MyApp.Domain.*" />
  <Allowed From="MyApp.Infrastructure.*" To="MyApp.Application.*" />

  <Disallowed From="MyApp.Domain.*" To="MyApp.Infrastructure.*" />
  <Disallowed From="MyApp.Domain.*" To="MyApp.Application.*" />
  <Disallowed From="MyApp.Domain.*" To="MyApp.Api.*" />
</NsDepCopConfig>
```

---

## Run Commands

```bash
# Run architecture tests
dotnet test --filter "Category=Architecture"

# Build (NsDepCop runs during build)
dotnet build

# Run all tests
dotnet test
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain uses Entity Framework | Define repository interfaces in domain |
| Domain references HttpContext | Move to API layer |
| Circular project reference | Extract shared contracts |
| Controller has business logic | Move to Application services |

---

## Existing Tests Check

```bash
# Check for ArchUnitNET
grep -r "ArchUnitNET\|TngTech.ArchUnitNET" . --include="*.csproj"

# Check for NsDepCop
[ -f "config.nsdepcop" ] && echo "NsDepCop config found"
grep -r "NsDepCop" . --include="*.csproj"
```

---

## Recommended Solution Structure

```
MyApp/
├── MyApp.sln
├── src/
│   ├── MyApp.Domain/           # Pure business logic
│   │   ├── Entities/
│   │   ├── ValueObjects/
│   │   └── Interfaces/         # Repository interfaces
│   ├── MyApp.Application/      # Use cases
│   │   ├── Services/
│   │   ├── DTOs/
│   │   └── Interfaces/         # External service interfaces
│   ├── MyApp.Infrastructure/   # External implementations
│   │   ├── Persistence/
│   │   ├── ExternalServices/
│   │   └── DependencyInjection/
│   └── MyApp.Api/              # HTTP layer
│       ├── Controllers/
│       ├── Middleware/
│       └── Program.cs
└── tests/
    ├── MyApp.UnitTests/
    ├── MyApp.IntegrationTests/
    └── MyApp.ArchitectureTests/
```

---

## Project References

```xml
<!-- MyApp.Api.csproj -->
<ItemGroup>
  <ProjectReference Include="..\MyApp.Application\MyApp.Application.csproj" />
  <ProjectReference Include="..\MyApp.Infrastructure\MyApp.Infrastructure.csproj" />
</ItemGroup>

<!-- MyApp.Application.csproj -->
<ItemGroup>
  <ProjectReference Include="..\MyApp.Domain\MyApp.Domain.csproj" />
</ItemGroup>

<!-- MyApp.Infrastructure.csproj -->
<ItemGroup>
  <ProjectReference Include="..\MyApp.Domain\MyApp.Domain.csproj" />
  <ProjectReference Include="..\MyApp.Application\MyApp.Application.csproj" />
</ItemGroup>

<!-- MyApp.Domain.csproj - NO project references! -->
```

---

## Additional Tools

### dotnet-outdated
```bash
dotnet tool install --global dotnet-outdated-tool
dotnet outdated
```

### Security scanning
```bash
dotnet list package --vulnerable
```
