# Security and Privacy

KeePassXC Hello Focus is a **window focus helper**, not an authentication provider. It does not interact with password databases, browser credential stores, Windows credential APIs, PINs, keys, or keystrokes.

## Security properties

- No network, telemetry, automatic updates, or external service calls.
- No credential inspection, injection, input automation, or secret logging.
- No administrator privileges requested by the executable manifest.
- No bypass of secure desktop, User Account Control, or protected Windows dialogs.
- No persistent configuration or user data storage.
- The compiled tray icon is extracted temporarily for display and removed on normal exit.

## Limitations

The Windows window manager may refuse z-order or activation requests, particularly for protected or elevated prompts. The application should not be used as a security boundary or as a guarantee that a prompt is authentic. Users should verify unexpected authentication prompts before proceeding.

## Responsible reports

For a public repository, configure private vulnerability reporting in GitHub Security settings. Do not post passwords, authentication secrets, KeePassXC database files, or screenshots containing credentials in public issues.
