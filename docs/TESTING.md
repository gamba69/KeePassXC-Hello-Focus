# Manual Acceptance Test Plan

Use Windows 10 and Windows 11 where possible. Test the actual built EXE, not only the interpreted `.au3` script. Start each test from a clean process state.

| ID | Procedure | Expected result |
| --- | --- | --- |
| T01 | Open the EXE's Properties > Details. | Product is KeePassXC Hello Focus; file/product versions are 0.1.1.0. |
| T02 | Inspect the EXE icon at multiple Explorer display sizes. | White fingerprint, not the generic AutoIt/window icon. |
| T03 | Launch the EXE and inspect the tray. | Exactly one recognizable fingerprint icon appears. |
| T04 | Launch a second EXE or a renamed copy. | The new process exits silently and no second tray icon appears. |
| T05 | Trigger a supported Windows Hello authentication dialog behind another normal window. | The prompt appears in the foreground and becomes topmost. |
| T06 | Leave the prompt open, then focus another window. | After initial reassertions, the utility does not continuously steal focus. |
| T07 | Dismiss and trigger the prompt again. | The new prompt is activated. |
| T08 | Right-click the tray icon. | Menu shows About..., separator, Exit. |
| T09 | Open and close About repeatedly. | Window appears and disappears quickly; no freeze, duplicate windows, or interruption of monitoring. |
| T10 | Switch Windows application mode light/dark with the process running. | About updates background/text/button/title bar when reopened or notified. |
| T11 | Inspect the tray menu in both modes. | Native menu follows system theme where supported; fallback is usable. |
| T12 | Choose Exit. | App terminates and tray icon disappears. |
| T13 | Launch EXE without adjacent ICO files. | Tray icon still loads (icon embedded by FileInstall). |
| T14 | Run a non-administrative Windows account. | Application starts without a UAC prompt and does not request elevation. |
| T15 | Open a protected system prompt. | No bypass of OS isolation is attempted; failure to focus is allowed. |

## Release verification

- Confirm `FileVersion` and `ProductVersion` match the Git tag.
- Confirm the release ZIP contains exactly the intended distributable files (`KeePassXCHelloFocus.exe`, `README.md`, and `LICENSE`), and that `dist/` has the same contents plus the ZIP itself. No `.log` files or build tools may appear in `dist/`.
- Confirm no compiled binary is tracked in the source repository by default.
- Confirm the application makes no unsolicited network connections during normal operation.
- Confirm no credential, KeePassXC database, or other sensitive data is recorded by the application.

## Toolchain selection and download tests

- With AutoIt installed on the machine, run `Compile.cmd` and confirm it still downloads a new stable portable package and uses its compiler.
- With `.tools/AutoIt/current/` already populated, run `Compile.cmd` again and confirm it downloads a new package rather than reusing the previous compiler.
- With the official download unavailable, confirm that the build fails rather than using installed or previously downloaded AutoIt.
- Confirm the downloaded package is validated before replacing `.tools/AutoIt/current/`, and that download staging files are removed.
- Confirm the printed compiler version corresponds to the freshly downloaded package.

## GitHub Actions acceptance tests

- Push a change to `main`; confirm the `Build` workflow runs and uploads a `KeePassXCHelloFocus-X.Y.Z` artifact containing the matching versioned ZIP.
- Manually use **Actions > Build > Run workflow**; confirm it produces the same artifact without creating a GitHub Release.
- Push an `X.Y.Z` Git tag for the tested commit and save a Draft Release using that existing tag; confirm no workflow starts automatically.
- Manually dispatch **Actions > Release > Run workflow** with the draft's tag; confirm it builds the tagged commit, verifies SHA-256, and uploads both ZIP and `.zip.sha256` to the draft, leaving title, notes, and draft status unchanged.
- Verify the workflow rejects a published release instead of attempting an immutable asset upload. After both assets are present, publish the draft manually; confirm publication triggers no build and both assets remain available.
- Confirm that a failed build uploads diagnostics under `.build/logs/` but does not upload a misleading successful distribution archive.
