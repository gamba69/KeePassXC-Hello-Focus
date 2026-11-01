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

## Download verification and Windows SmartScreen

Every packaged build has a matching `KeePassXCHelloFocus-X.Y.Z.zip.sha256` file. The value is computed from the final distribution ZIP after packaging. Follow the [verification instructions](../README.md#download-verification-and-windows-smartscreen) before running downloaded binaries. SHA-256 is a file integrity check, **not** proof that an EXE is signed or trusted.

Windows may flag unsigned, low-reputation downloads via Microsoft Defender SmartScreen. The file can carry Windows' Mark of the Web through ZIP extraction. After checking the original source and checksum, users who trust a specific downloaded ZIP may optionally run `Unblock-File` on that ZIP **before** extracting it. This is a per-download action; it does not grant a blanket exception for future versions. Never disable SmartScreen globally just to run this program.

## Responsible reports

For a public repository, configure private vulnerability reporting in GitHub Security settings. Do not post passwords, authentication secrets, KeePassXC database files, or screenshots containing credentials in public issues.
