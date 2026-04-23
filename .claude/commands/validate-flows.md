Validate all Maestro flow files in this repo for correctness and consistency.

For each YAML file in `iOS_tests/` (skip `_resetToHome_ios.yaml` itself):
1. Has `appId: com.apple.MobileAddressBook` header
2. First command is `- runFlow: _resetToHome_ios.yaml`
3. Last command is `- stopApp`
4. Does NOT use `clearState: true`
5. Does NOT use `point:` for back navigation (should use `text: "Back" optional: true` + `text: "Lists" optional: true`)
6. Screenshot name uses JS timestamp (`new Date().toISOString()`) — not `MAESTRO_DEVICE_UDID`

For each YAML file in `Andtroid_tests/`:
1. Has `appId:` header
2. Last command is `- stopApp`

Report results as a table:

| File | ✓/✗ | Issues |
|---|---|---|

After the table, offer to fix any violations automatically.
