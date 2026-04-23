#!/bin/bash
# PostToolUse hook — runs after Write or Edit on any file.
# Validates iOS test flows for required patterns.

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null)

# Only check iOS test YAML files — skip the shared helper itself
if [[ "$FILE" == *"iOS_tests"* && "$FILE" == *".yaml" && "$FILE" != *"_reset"* ]]; then
    ISSUES=""

    if ! grep -q "runFlow: _resetToHome_ios.yaml" "$FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  • Missing: - runFlow: _resetToHome_ios.yaml (first command)"
    fi

    if grep -q "clearState: true" "$FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  • Error: clearState: true is not allowed for iOS system apps — use clearState: false"
    fi

    if grep -qP "point:\s+\"" "$FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  • Warning: point: coordinates detected — prefer tapOn with text + optional: true for back navigation"
    fi

    if ! grep -q "stopApp" "$FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  • Missing: - stopApp at end of flow"
    fi

    if grep -q "MAESTRO_DEVICE_UDID" "$FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  • Warning: MAESTRO_DEVICE_UDID in screenshot name — use JS timestamp instead: \${new Date().toISOString().replace(/[:.]/g, '-')}"
    fi

    if [ -n "$ISSUES" ]; then
        echo ""
        echo "Flow validation — $(basename "$FILE"):$ISSUES"
        echo ""
    fi
fi
