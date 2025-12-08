#!/usr/bin/env sh
set -eu

# =============================================================================
# Java ArchUnit - Stack Tool
# =============================================================================
# Runs ArchUnit architecture tests for Java/Kotlin projects.
# For detailed documentation: .github/tools/stack/java/archunit.md
# =============================================================================

PATTERN="${1:-*Arch*,*Architecture*}"

echo "[archunit] Running ArchUnit tests..."
echo "[archunit] ============================================"
echo "[archunit] Pattern: $PATTERN"
echo ""

FAILURES=0

# Detect build tool
if [ -f "pom.xml" ]; then
    echo "[archunit] Build tool: Maven"
    
    # Check if ArchUnit is configured
    if grep -q "archunit" pom.xml 2>/dev/null; then
        echo "[archunit] ArchUnit dependency found"
        echo ""
        
        # Run tests matching pattern
        mvn test -Dtest="$PATTERN" -DfailIfNoTests=false || FAILURES=1
    else
        echo "[archunit] Warning: ArchUnit not found in pom.xml"
        echo "[archunit] Add this dependency to use ArchUnit:"
        echo ""
        echo "<dependency>"
        echo "    <groupId>com.tngtech.archunit</groupId>"
        echo "    <artifactId>archunit-junit5</artifactId>"
        echo "    <version>1.2.1</version>"
        echo "    <scope>test</scope>"
        echo "</dependency>"
        FAILURES=1
    fi
    
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "[archunit] Build tool: Gradle"
    
    # Check if ArchUnit is configured
    if grep -q "archunit" build.gradle* 2>/dev/null; then
        echo "[archunit] ArchUnit dependency found"
        echo ""
        
        # Run tests matching pattern
        ./gradlew test --tests "$PATTERN" || FAILURES=1
    else
        echo "[archunit] Warning: ArchUnit not found in build.gradle"
        echo "[archunit] Add this dependency to use ArchUnit:"
        echo ""
        echo "testImplementation(\"com.tngtech.archunit:archunit-junit5:1.2.1\")"
        FAILURES=1
    fi
else
    echo "[archunit] Error: No Maven or Gradle project found"
    FAILURES=1
fi

echo ""
echo "[archunit] ============================================"
if [ $FAILURES -eq 0 ]; then
    echo "[archunit] All architecture tests passed ✓"
else
    echo "[archunit] Tests FAILED or not configured"
fi

exit $FAILURES
