# Maestro UI App Automation

Maestro YAML-based UI test automation for iOS Contacts and Android Contacts apps.

## Project layout

```
iOS_tests/                    # iOS flows — com.apple.MobileAddressBook
  _resetToHome_ios.yaml       # Shared setup helper (stopApp + launchApp + navigate home)
Andtroid_tests/               # Android flows — com.google.android.contacts
config.yaml                   # Glob-discovers all YAML files in both folders
```

## iOS test rules — always enforce these

1. **Start with the shared reset helper** — never inline stopApp/launchApp/repeat:
   ```yaml
   - runFlow: _resetToHome_ios.yaml
   ```

2. **Never use `clearState: true`** — Contacts is a system app; iOS blocks reinstall. Always `clearState: false`.

3. **Back navigation — always try both labels** with `optional: true`:
   ```yaml
   - tapOn:
       text: "Back"
       optional: true
   - tapOn:
       text: "Lists"
       optional: true
   - waitForAnimationToEnd
   ```
   The back button label changes by context ("Back" vs "Lists") — using `optional: true` on both handles both cases safely.

4. **Always end flows with `- stopApp`.**

5. **Screenshots — JS timestamp only**:
   ```yaml
   - takeScreenshot: "FlowName-${new Date().toISOString().replace(/[:.]/g, '-')}.png"
   ```
   `MAESTRO_DEVICE_UDID` resolves to `undefined` in some environments — never use it in screenshot names.

6. **Never use `point:` coordinates for back navigation** — use text labels with `optional: true`.

## Android test rules

- `clearState: true` is safe (Google Contacts is not system-protected).
- Use element IDs where available (e.g., `id: floating_action_button`).
- Always end with `- stopApp`.

## File naming

- `<TestName>_ios.yaml` — iOS flows
- `<TestName>_android.yaml` — Android flows
- `_<name>.yaml` — shared helpers (leading underscore; not standalone test flows)

## Maestro Cloud constraint

**Leave the App field empty in the Cloud Run dialog for system apps.** Selecting `com.apple.MobileAddressBook` causes Maestro Cloud to try to install it — iOS rejects this with "Rejecting downgrade of system/internal app". The `appId` in the YAML is sufficient.

If the UI won't allow clearing the selection, use the CLI without `--app-file`:
```sh
maestro test iOS_tests/SearchContacts_ios.yaml
```

## Common Maestro mistakes

| Wrong | Correct |
|---|---|
| `clearState: true` on iOS | `clearState: false` |
| `pressKey: Delete` | `- tapOn:\n    text: "Clear text"` |
| `tapOn: text: "+"` | use `id:` or `point:` — `+` is a regex metacharacter |
| `- while:` standalone | wrap in `- repeat: times: N` with nested `while:` |
| `MAESTRO_DEVICE_UDID` in screenshot names | `${new Date().toISOString().replace(/[:.]/g, '-')}` |
| `tapOn: text: "Back"` alone | always pair with optional `tapOn: text: "Lists"` |

## Running tests

```sh
maestro test iOS_tests/SearchContacts_ios.yaml   # single flow
maestro test iOS_tests/                           # iOS suite
maestro test --config config.yaml                 # all platforms
maestro list-devices                              # show connected devices
```
