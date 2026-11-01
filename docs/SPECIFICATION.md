# KeePassXC Hello Focus — Technical Specification

**Specification version:** 0.1.0  
**Target platform:** Windows 10/11, x64  
**Language:** AutoIt v3 (latest stable when downloaded automatically)  
**Distribution:** Portable standalone EXE

## 1. Purpose and scope

The application assists with a focus/z-order issue in which a Windows Hello or Windows Security credential prompt is visible but remains behind an ordinary application window. The utility was designed particularly for workflows using KeePassXC, but does not interface with, modify, or depend on KeePassXC.

### In scope

- Observe the presence and visibility of a supported credential dialog.
- Request topmost z-order and activation when that dialog first appears.
- Perform a short series of z-order reassertions while the dialog initializes.
- Offer tray-based information and exit controls.
- Prevent a second running instance in the same user session.
- Adapt the About dialog to the operating system's application color theme.

### Out of scope

- Authentication, credentials, passkey management, or PIN handling.
- Changes to Windows Hello, KeePassXC, or security policy.
- Automation of input or dismissal of an authentication prompt.
- Elevation to bypass desktop isolation or operating system protections.
- Network communication, telemetry, configuration, update checks, or persistent logging.

## 2. Detection

The application searches for a window using the AutoIt selector:

`[CLASS:Credential Dialog Xaml Host]`

It calls `WinGetHandle` every **200 ms**. A handle is eligible only when `WinGetState` contains `$WIN_STATE_VISIBLE`. If no matching visible window is found, the tracked handle and reassertion counter are reset.

**Limitation:** the selector corresponds to one known Windows authentication-dialog class. Other implementations or multiple simultaneous matching dialogs are not comprehensively enumerated.

## 3. Foreground state machine

| Condition | Required behavior |
| --- | --- |
| No eligible dialog | Reset tracked handle and retry counter; take no window action. |
| New visible dialog handle | Record handle; call `WinSetOnTop(..., $WINDOWS_ONTOP)` and then `WinActivate` once. |
| Same handle during initialization | Reassert topmost while retry counter is positive; do not call `WinActivate` again. |
| Same handle after retries | Continue observing without stealing focus or changing z-order. |
| Dialog disappears or becomes hidden | Reset tracking. The next visible occurrence counts as new. |

Constants in version 0.1.0:

- `POLL_INTERVAL_MS = 200`.
- `REASSERT_COUNT = 4` (the initial activation plus up to four additional topmost calls).

The utility does not check for or circumvent Windows rejection of focus or topmost requests. Failed requests remain subject to normal operating-system behavior.

## 4. Single-instance rule

The process calls `_Singleton("KeePassXCHelloFocus", 1)` **before** creating the tray icon, window, or other user interface. When an existing cooperating instance owns the named mutex, a second launch exits silently with code 0.

The guarantee applies to cooperating builds using the same mutex within the appropriate Windows session scope. Older builds using a different mutex name must be exited manually during migration.

## 5. Tray behavior

- Display a white fingerprint with simplified strokes suitable for 16×16 pixels.
- Right-click menu contains `About...`, a separator, and `Exit`.
- `About...` shows the About dialog and activates it.
- `Exit` gracefully terminates the program.
- The menu is event-driven and should not wait for the 200 ms detection loop before processing clicks.
- The native menu requests the current Windows applications color mode via UxTheme ordinals 135/136. If unsupported, the default Windows menu is allowed.

## 6. Icon storage

The source package contains `KeePassXCHelloFocus.ico` and `KeePassXCHelloFocusTray.ico`. The compiled EXE embeds the main icon as an executable resource and embeds the tray icon through `FileInstall`.

When compiled, the tray icon is extracted to an application-specific temporary filename using the process ID, loaded into the tray, and removed during normal shutdown. When run as `.au3`, the icon is loaded from the source directory. If extraction fails, the EXE icon is used as a fallback.

The compiled EXE must not require an external ICO file to run. Termination by force may leave a temporary ICO, which can be safely removed.

## 7. About window

- Window title: `About - KeePassXC Hello Focus`.
- Product label: `KeePassXC Hello Focus`.
- Version: derived from Windows EXE `FileVersion` metadata, formatted as `MAJOR.MINOR.PATCH`. An uncompiled script displays `development`.
- Language: English only.
- Content: purpose, execution model, independence from KeePassXC, privacy/scope, and OS limitations.
- The About GUI is constructed once, initially hidden, and shown/hidden without rebuilding controls.
- The dialog is modeless: the background window-detection loop continues running.
- Closing with the `Close` button or title-bar close button hides the dialog; it does not terminate the tray application.

## 8. Light/dark presentation

The About window reads `HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\AppsUseLightTheme`. Value `0` indicates dark app mode; a missing value defaults to light mode. The application updates the client background, text colors, divider, Close button theme, and DWM title-bar attribute on mode changes or before showing About.

Windows theme-change messages are handled by setting a flag and applying the UI update from the main loop. Undocumented theme functionality is best-effort. The behavior follows **Windows application theme**, not a third-party file manager's theme.

## 9. Security and privacy requirements

1. The app must not read, intercept, store, print, transmit, or log passwords, PINs, TOTP values, passkeys, recovery codes, or keystrokes.
2. The app must not request administrator privileges merely to change window focus.
3. The app must not bypass Windows secure desktop or protected prompt boundaries.
4. The app must not access KeePassXC databases, KeePassXC memory, or browser content.
5. The app must not perform network operations or require an online service.
6. Temp file use is limited to the embedded tray icon; no secret information belongs in that file.

## 10. Build and release contract

- Product name in EXE metadata: `KeePassXC Hello Focus`.
- Output name: `KeePassXCHelloFocus.exe` (no version suffix).
- Release ZIP name: `KeePassXCHelloFocus-X.Y.Z.zip`, where `X.Y.Z` is the application version from `FileVersion`/`ProductVersion` (for example, `0.1.0`).
- `FileVersion` and `ProductVersion`: `0.1.0.0` for tag `v0.1.0`.
- `#pragma compile(FileVersion, ...)` is the authoritative version declaration; runtime About reads it from the compiled EXE.
- Each build downloads and verifies a fresh copy of the latest stable portable AutoIt from the official rolling URL; installed and cached compilers are never used. Compilation uses explicit `/icon`, `/x64`, and `/nopack` arguments.
- A mismatched tag fails the release build instead of publishing inconsistent artifacts.
- CI and manual builds upload testable ZIP artifacts without publishing a GitHub Release.
- Publishing a GitHub Release triggers a separate build from the release tag and attaches the generated ZIP to that existing release. Draft releases do not initiate builds.
- Release packaging always contains the standalone EXE, README, and MIT `LICENSE`.
- Publishing must be blocked if the MIT `LICENSE` file is missing.

## 11. Acceptance criteria

The acceptance procedures in [TESTING.md](TESTING.md) are the behavioral reference. Automation checks artifact structure, version metadata, and successful compilation, but does not substitute for real Windows interactive testing.

## 12. Known constraints

- A secure desktop cannot be controlled using ordinary application z-order APIs.
- Multiple credential dialogs and alternate UI classes are not supported explicitly.
- The undocumented dark-menu API may stop working after a Windows update.
- White icons can become invisible against light backgrounds; the tray icon is optimized for the typical dark tray configuration.
- No automatic startup, configuration editor, installer, or application update mechanism is included.
