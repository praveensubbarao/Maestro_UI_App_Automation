Create a new iOS Maestro test flow for the Contacts app.

Ask the user for:
1. **Test name** — PascalCase, describes what is being tested (e.g. `SearchByPhone`, `DeleteContact`)
2. **Tags** — pick relevant ones: `smokeTest`, `search`, `detail`, `edit`, `navigation`, `lists`
3. **Scenario** — what the test should do (one sentence is enough)

Then create `iOS_tests/<TestName>_ios.yaml` using this exact structure:

```yaml
appId: com.apple.MobileAddressBook
tags:
  - contacts
  - ios
  - <chosen tags>
---
- runFlow: _resetToHome_ios.yaml
# implement test steps here
- takeScreenshot: "<TestName>-${new Date().toISOString().replace(/[:.]/g, '-')}.png"
- stopApp
```

Rules to enforce automatically (from CLAUDE.md):
- Always start with `- runFlow: _resetToHome_ios.yaml` — never inline the stopApp/launchApp/repeat block
- Never use `clearState: true`
- Back navigation always uses the optional pair: `tapOn: "Back" optional: true` + `tapOn: "Lists" optional: true` + `waitForAnimationToEnd`
- Always end with `- stopApp`
- Screenshot filename uses JS Date timestamp — never `MAESTRO_DEVICE_UDID`

After creating the file, add a one-line entry to the **iOS Tests** section of `README.md` with the test name, tags, and what it covers.
