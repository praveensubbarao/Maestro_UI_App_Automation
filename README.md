## Maestro UI App Automation

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

Mobile UI test automation for iOS and Android using [Maestro](https://maestro.mobile.dev) — a declarative YAML-based testing framework.

---

## Prerequisites

- **Maestro CLI** v2.4.0+
  ```sh
  curl -Ls "https://get.maestro.mobile.dev" | bash
  ```
- **iOS**: Xcode with at least one Simulator configured
- **Android**: Android Studio with an AVD Emulator configured
- **MCP (optional)**: MCP-compatible IDE (VSCode, Cursor, Windsurf) for AI-assisted test authoring

### Useful Links
- [Quickstart (Android)](https://docs.maestro.dev/get-started/quickstart#android)
- [Commands Reference](https://docs.maestro.dev/reference/commands-available)
- [Test Architecture Guide](https://docs.maestro.dev/maestro-flows/workspace-management/design-your-test-architecture)
- [Best Practices](https://maestro.dev/blog/maestro-best-practices-structuring-your-test-suite)

---

## Project Structure

```
Maestro_UI_App_Automation/
├── CLAUDE.md                     # Claude Code project rules (auto-loaded every session)
├── config.yaml                   # Workspace config — registers all test suites
├── start_maestro_mcp.sh          # Startup script for Maestro MCP server
├── .claude/
│   ├── settings.json             # Permissions + PostToolUse validation hook
│   ├── commands/
│   │   ├── new-ios-flow.md       # /new-ios-flow slash command
│   │   └── validate-flows.md     # /validate-flows slash command
│   └── hooks/
│       └── validate_ios_flow.sh  # Hook script — validates iOS YAML on every write
├── .vscode/
│   └── mcp.json                  # VSCode MCP server config (points to start script)
├── iOS_tests/                    # iOS test flows (iPhone Simulator)
│   ├── _resetToHome_ios.yaml     # Shared setup helper — referenced by all iOS flows
│   ├── LaunchContacts_ios.yaml
│   ├── SearchContacts_ios.yaml
│   ├── SearchPartialMatch_ios.yaml
│   ├── SearchNoResults_ios.yaml
│   ├── ViewContactDetail_ios.yaml
│   ├── EditContact_ios.yaml
│   ├── NavigateListsPanel_ios.yaml
│   ├── NavigateFriendsList_ios.yaml
│   ├── EmptyListState_ios.yaml
│   └── AddList_ios.yaml
└── Andtroid_tests/               # Android test flows (Emulator)
    └── LaunchContacts_android.yaml
```

---

## Config

### `config.yaml`
Maestro workspace configuration. Registers both test suites so all flows are discovered when running `maestro test` from the project root.
```yaml
flows:
  - Andtroid_tests/*.yaml
  - iOS_tests/*.yaml
```

---

## MCP Server

### `start_maestro_mcp.sh`
Startup script for the [Maestro MCP server](https://docs.maestro.dev/get-started/maestro-mcp). Ensures `~/.maestro/bin` is on the PATH before starting `maestro mcp`, which exposes Maestro device and automation commands as MCP tools to AI agents.

Run directly:
```sh
./start_maestro_mcp.sh
```

### `.vscode/mcp.json`
Wires the MCP server into VSCode so it auto-starts when the workspace opens. Uses `${workspaceFolder}/start_maestro_mcp.sh` as the command so the PATH is always correct.

**Available MCP tools (13):** `start_device`, `list_devices`, `launch_app`, `stop_app`, `tap_on`, `input_text`, `back`, `run_flow`, `run_flow_files`, `take_screenshot`, `inspect_view_hierarchy`, `check_flow_syntax`, `query_docs`

---

## Claude Code Setup

Claude Code is configured at the project level via `.claude/` to enforce test-writing conventions, reduce repetitive prompting, and catch mistakes automatically.

### `CLAUDE.md`
Loaded automatically at the start of every Claude Code session. Documents all iOS/Android test rules, naming conventions, the Maestro Cloud constraint, and common mistakes so Claude has full context without needing to be told again.

### Slash Commands

#### `/new-ios-flow`
Scaffolds a new iOS test flow. Prompts for test name, tags, and scenario, then generates `iOS_tests/<TestName>_ios.yaml` with all constraints pre-applied:
- Correct `appId` and `tags` header
- `- runFlow: _resetToHome_ios.yaml` as the first command
- Back navigation using the `optional: true` pair
- JS timestamp screenshot
- `- stopApp` at the end

Also appends a one-line entry to the README iOS Tests section automatically.

#### `/validate-flows`
Audits all YAML files in `iOS_tests/` and `Andtroid_tests/` and reports violations in a table:

| Check | What it catches |
|---|---|
| `runFlow: _resetToHome_ios.yaml` present | Flow missing shared setup |
| `clearState: true` absent | Forbidden on iOS system apps |
| `point:` coordinates absent | Should use text labels + `optional: true` |
| `stopApp` at end | Missing teardown |
| JS timestamp in screenshot | `MAESTRO_DEVICE_UDID` resolves to `undefined` |

### Hook — PostToolUse validation

Defined in `.claude/settings.json`, runs `.claude/hooks/validate_ios_flow.sh` automatically after every file write or edit. For any iOS test YAML (excluding `_resetToHome_ios.yaml`), it checks:

- Missing `- runFlow: _resetToHome_ios.yaml`
- `clearState: true` present (forbidden)
- `point:` coordinates used for back navigation
- Missing `- stopApp`
- `MAESTRO_DEVICE_UDID` used in screenshot names

Violations are printed inline as warnings immediately after the file is saved — no need to run tests to discover structural errors.

### Permissions

Pre-approved in `.claude/settings.json` so Claude can run these without prompting:

```
maestro test *
maestro list-devices
maestro list-cloud-devices
maestro --version
maestro --udid *
maestro cloud *
```

---

## iOS Tests

Target app: `com.apple.MobileAddressBook` (iOS Contacts)
Device: iPhone Simulator (tested on iPhone 17 Pro — iOS 26.4)

Every flow starts with a reference to the shared reset helper:
```yaml
- runFlow: _resetToHome_ios.yaml
```

`_resetToHome_ios.yaml` kills any running instance, cold-starts the app without clearing data, and navigates back to the `All iPhone` contacts list regardless of where the app was left by the previous test:
```yaml
- stopApp
- launchApp:
    clearState: false
- repeat:
    times: 5
    while:
      notVisible:
        text: "All iPhone"
    commands:
      - tapOn:
          text: "Back"
          optional: true
      - tapOn:
          text: "Lists"
          optional: true
      - waitForAnimationToEnd
```

---

### `LaunchContacts_ios.yaml`
**Tags:** `smokeTest`
Add a new contact with a faker-generated first and last name, take a screenshot, then delete the contact and assert the list view is restored. Covers the full add → verify → delete lifecycle.

### `SearchContacts_ios.yaml`
**Tags:** `search`
Search for `Taylor` by exact name, assert the result is visible, and take a screenshot. Covers the happy-path search flow.

### `SearchPartialMatch_ios.yaml`
**Tags:** `search`
Type a partial name (`Kate`) and assert the `Top Name Matches` section header and `Kate Bell` result appear. Verifies the search ranking UI.

### `SearchNoResults_ios.yaml`
**Tags:** `search`
Search for a guaranteed non-existent string (`ZZZNORESULT`) and assert the `No Results for` message and `Check the spelling or try a new search.` subtitle are shown. Covers the empty-results state.

### `ViewContactDetail_ios.yaml`
**Tags:** `detail`
Open `John Appleseed`, assert key fields (`mobile`, phone number, `Edit` button), scroll to the actions section, and assert `Send Message`, `Share Contact`, `Add to Favorites`, `Add to List`, and `Block Contact` are all present.

### `EditContact_ios.yaml`
**Tags:** `edit`
Open `Kate Bell`, tap `Edit`, and assert the edit form loads with the correct name fields (`Kate`, `Bell`) and the `add phone` / `add email` controls visible. Cancels without saving.

### `NavigateListsPanel_ios.yaml`
**Tags:** `navigation`
Navigate back to the Lists panel and assert all four entries are visible: `All Contacts`, `All iPhone`, `Friends`, `Work`, plus the `Add List` button.

### `NavigateFriendsList_ios.yaml`
**Tags:** `navigation`
Navigate to the `Friends` list and assert `Daniel Higgins Jr.` is the sole contact in that list.

### `EmptyListState_ios.yaml`
**Tags:** `navigation`
Navigate to the `Work` list (0 contacts) and assert the empty state: `No Contacts` heading, `Contacts you've added will appear here.` subtitle, and `Add Contacts` CTA.

### `AddList_ios.yaml`
**Tags:** `lists`
From the Lists panel, tap `Add List`, type `Maestro Test List`, confirm with Return, and assert the new list appears in the panel. Covers the end-to-end list creation flow.

---

## Android Tests

Target app: `com.google.android.contacts` (Google Contacts)
Device: Android Emulator

### `LaunchContacts_android.yaml`
**Tags:** `smokeTest`
Launch the app with `clearState: true` (full reinstall, safe on Android), tap the FAB to open the new-contact form, fill first and last name with faker data, save, take a screenshot, then delete the contact. Mirrors the iOS smoke test on Android.

---

## AI Prompts (Maestro MCP)

When the Maestro MCP server is running and connected to your IDE, use these prompts to drive the AI directly against the live device.

Start the server first:
```sh
./start_maestro_mcp.sh
```

### Device & App Control
| Prompt | MCP Tool |
|---|---|
| `List all available simulators/emulators` | `list_devices` |
| `Start an iPhone 15 simulator` | `start_device` |
| `Launch app com.apple.MobileAddressBook` | `launch_app` |
| `Stop the Contacts app` | `stop_app` |

### UI Interaction
| Prompt | MCP Tool |
|---|---|
| `Tap on the Search button` | `tap_on` |
| `Type 'Taylor' into the search field` | `input_text` |
| `Press the back button` | `back` |

### Inspection & Analysis
| Prompt | MCP Tool |
|---|---|
| `Take a screenshot of the current screen` | `take_screenshot` |
| `Show me the view hierarchy of the current screen` | `inspect_view_hierarchy` |

### Flow Execution
| Prompt | MCP Tool |
|---|---|
| `Run the SearchContacts_ios.yaml flow` | `run_flow_files` |
| `Check the syntax of SearchContacts_ios.yaml` | `check_flow_syntax` |

### Power prompt — inspect then generate
```
Take a screenshot and inspect the view hierarchy, then write a Maestro
flow to tap the Add button and fill in the first name field.
```
This causes the AI to observe the live app state first, then generate a flow grounded in the actual UI rather than guessing element names.

---

## Running Tests

### Run a single flow
```sh
maestro test iOS_tests/SearchContacts_ios.yaml
```

### Run the full iOS suite
```sh
maestro test iOS_tests/
```

### Run the full workspace (iOS + Android)
```sh
maestro test --config config.yaml
```

### Run with a specific device
```sh
maestro --udid <device-id> test iOS_tests/
```

### List available devices
```sh
maestro list-devices
```

---

## Learnings

### Maestro Cloud — do not select an App binary for system apps
When running a Cloud Run in the Maestro UI, the **App** dropdown defaults to a recently-used value. If `com.apple.MobileAddressBook` (or any system app) is selected, Maestro Cloud attempts to install that binary onto the cloud device — which iOS rejects:
```
Rejecting downgrade of system/internal app com.apple.MobileAddressBook
Unable to Install "Contacts"
```
**Fix:** Leave the App field empty in the Cloud Run dialog. The `appId: com.apple.MobileAddressBook` in the YAML is sufficient — it tells Maestro which app to interact with. The App field is only for custom `.ipa` binaries that need to be installed; system apps are already present on the device.

If the UI does not allow clearing the selection, use the CLI instead and omit `--app-file`:
```sh
maestro test iOS_tests/SearchContacts_ios.yaml
```

### iOS system apps cannot be reinstalled
`clearState: true` works by uninstalling and reinstalling the app. iOS Simulators block uninstallation of core system apps like Contacts (`Uninstall prohibited — error code 22`). Always use `clearState: false` for `com.apple.MobileAddressBook`. Kill and relaunch with `stopApp` + `launchApp` instead to reset navigation state without touching data.

### App resumes in last-visited screen
The Contacts app remembers its last navigation state across launches. Always add a `repeat/while/notVisible` guard after `launchApp` to navigate back to a known baseline screen (`All iPhone`) before test steps begin.

### `while` is not a standalone command
Maestro has no standalone `while:` command. Conditional looping requires `repeat:` with a nested `while:` condition:
```yaml
- repeat:
    times: 5          # safety cap — prevents infinite loops
    while:
      notVisible:
        text: "All iPhone"
    commands:
      - tapOn:
          text: "Back"
          optional: true
      - tapOn:
          text: "Lists"
          optional: true
      - waitForAnimationToEnd
```

### Navigation back-button label changes by context
The back button accessibility label is not always `"Back"`. From the `All iPhone` contacts list it is `"Lists"` (the parent screen name). From the `Work` or `Friends` list it is `"Back"`. Use `optional: true` on both labels so whichever is present gets tapped and the other is silently skipped:
```yaml
- tapOn:
    text: "Back"
    optional: true
- tapOn:
    text: "Lists"
    optional: true
- waitForAnimationToEnd
```

### `clearText` and `pressKey: Delete` are invalid
Neither `clearText` nor `pressKey: Delete` exist in Maestro. To clear a search field, tap the `Clear text` button that appears in the search bar:
```yaml
- tapOn:
    text: "Clear text"
```

### `+` is a regex special character in `tapOn`
Tapping elements by text that contain `+` fails because Maestro treats the value as a regex. Use `point:` coordinates for the add button instead:
```yaml
- tapOn:
    point: "93%, 95%"   # bottom-right + button
```

### Screenshots use JS timestamp for uniqueness
`MAESTRO_DEVICE_UDID` resolves to `undefined` in some environments. Use a JavaScript date expression for guaranteed unique filenames:
```yaml
- takeScreenshot: "MyFlow-${new Date().toISOString().replace(/[:.]/g, '-')}.png"
```
Screenshots are saved to `.maestro/screenshots/`.

### YAML syntax rules

- Every command after `---` must start with a `-` (dash).
- `repeat:`, `commands:`, and other block keys require a colon and correct indentation.
- Quote text values that contain spaces or special characters: `text: "All iPhone"`.
- `stopApp` takes no parameters — no colon needed when used standalone.

---

## License

[MIT](LICENSE) © 2026 Praveen Subbarao
