#!/usr/bin/env sh
set -eu

# =============================================================================
# Detect Layers - Discovery Tool
# =============================================================================
# Identifies architectural layers by analyzing naming conventions.
# For detailed documentation: .github/tools/discovery/detect-layers.md
# =============================================================================

SCAN_PATH="${1:-src}"

if [ ! -d "$SCAN_PATH" ]; then
    echo "[layers] Error: Directory '$SCAN_PATH' not found"
    exit 1
fi

echo "[layers] Scanning: $SCAN_PATH"
echo "[layers] ============================================"
echo "[layers] Detected architecture layers:"
echo ""

# Presentation Layer patterns
CONTROLLER=$(find "$SCAN_PATH" -type d \( -name "*controller*" -o -name "*api*" -o -name "*rest*" -o -name "*web*" -o -name "*endpoint*" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$CONTROLLER" -gt 0 ]; then
    echo "Layer: Controller/Presentation"
    echo "  Packages: $CONTROLLER"
    find "$SCAN_PATH" -type d \( -name "*controller*" -o -name "*api*" -o -name "*rest*" -o -name "*web*" \) 2>/dev/null | sed 's/^/  - /'
    echo ""
fi

# Application Layer patterns
SERVICE=$(find "$SCAN_PATH" -type d \( -name "*service*" -o -name "*usecase*" -o -name "*application*" -o -name "*handler*" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$SERVICE" -gt 0 ]; then
    echo "Layer: Service/Application"
    echo "  Packages: $SERVICE"
    find "$SCAN_PATH" -type d \( -name "*service*" -o -name "*usecase*" -o -name "*application*" -o -name "*handler*" \) 2>/dev/null | sed 's/^/  - /'
    echo ""
fi

# Domain Layer patterns
DOMAIN=$(find "$SCAN_PATH" -type d \( -name "*domain*" -o -name "*entity*" -o -name "*model*" -o -name "*core*" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$DOMAIN" -gt 0 ]; then
    echo "Layer: Domain/Core"
    echo "  Packages: $DOMAIN"
    find "$SCAN_PATH" -type d \( -name "*domain*" -o -name "*entity*" -o -name "*model*" -o -name "*core*" \) 2>/dev/null | sed 's/^/  - /'
    echo ""
fi

# Infrastructure Layer patterns
INFRA=$(find "$SCAN_PATH" -type d \( -name "*repository*" -o -name "*persistence*" -o -name "*infrastructure*" -o -name "*adapter*" -o -name "*external*" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$INFRA" -gt 0 ]; then
    echo "Layer: Repository/Infrastructure"
    echo "  Packages: $INFRA"
    find "$SCAN_PATH" -type d \( -name "*repository*" -o -name "*persistence*" -o -name "*infrastructure*" -o -name "*adapter*" \) 2>/dev/null | sed 's/^/  - /'
    echo ""
fi

# Ports patterns (Hexagonal)
PORTS=$(find "$SCAN_PATH" -type d \( -name "*port*" -o -name "*ports*" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$PORTS" -gt 0 ]; then
    echo "Layer: Ports (Hexagonal Architecture)"
    echo "  Packages: $PORTS"
    find "$SCAN_PATH" -type d \( -name "*port*" -o -name "*ports*" \) 2>/dev/null | sed 's/^/  - /'
    echo ""
fi

# Configuration patterns
CONFIG=$(find "$SCAN_PATH" -type d \( -name "*config*" -o -name "*configuration*" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$CONFIG" -gt 0 ]; then
    echo "Layer: Configuration"
    echo "  Packages: $CONFIG"
    find "$SCAN_PATH" -type d \( -name "*config*" -o -name "*configuration*" \) 2>/dev/null | sed 's/^/  - /'
    echo ""
fi

echo "[layers] ============================================"
echo "[layers] Tip: Use 'check-layers' to validate layer dependencies"

exit 0
