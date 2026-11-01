# KeePassXC Hello Focus

**Version 0.1.0** · Windows 10/11 · 64-bit · Portable

KeePassXC Hello Focus is a small, independent Windows tray utility that brings Windows Hello / Windows Security authentication prompts to the foreground when they appear behind other windows. Its primary use case is authentication prompts encountered while working with KeePassXC.

> This is an independent community utility. It is not developed, endorsed, or distributed by the KeePassXC project. It does not modify KeePassXC.

## Features

- Detects a visible window whose class is `Credential Dialog Xaml Host`.
- Activates each newly discovered prompt and requests that it remain above ordinary application windows.
- Avoids repeatedly stealing keyboard focus while a prompt remains open.
- Remains in the system tray with **About...** and **Exit** commands.
- Uses a compact white fingerprint icon in the tray and a separate high-resolution icon for the executable.
- Prevents duplicate instances within the same Windows user session.
- Supports light/dark styling for the About window and requests the native dark tray menu when supported by Windows.
- Uses no network access and does not read authentication secrets.

## Download and run

1. Open the repository's **Releases** section once the first release is published.
2. Download `KeePassXCHelloFocus-X.Y.Z.zip` (for example, `KeePassXCHelloFocus-0.1.0.zip`) and its matching `.zip.sha256` checksum file.
3. Verify the ZIP checksum (see [Download verification](#download-verification-and-windows-smartscreen)), then extract it.
4. Run `KeePassXCHelloFocus.exe`.
5. Right-click its tray icon to open **About...** or select **Exit**.

The release EXE is standalone. AutoIt and Python are **not required** on the target computer. No installer or administrator privileges are requested. A second launch silently exits.

To start the utility automatically when signing in, place a shortcut to the EXE in the Windows Startup folder (`Win+R`, then `shell:startup`).

## Build from source

AutoIt does **not** need to be installed. Every run of `Compile.cmd` (and every GitHub Actions build) downloads a **fresh copy of the latest stable portable AutoIt** from the [official AutoIt website](https://www.autoitscript.com/site/autoit/downloads/). It **never** uses an installed AutoIt, a previously downloaded compiler, or `AUT2EXE_PATH`.

The downloaded AutoIt runtime's Authenticode signature is verified before compilation. The new toolchain is kept under `.tools/AutoIt/current/` for inspection, but never reused by subsequent builds. An internet connection is required **for every build**. If download or verification fails, the build stops instead of using an older compiler. No administrator privileges, installation, or Python are needed. The rolling download may change when AutoIt publishes a new stable version; see [build documentation](docs/BUILD.md).

- Run `Compile.cmd` in the repository root.
- Or run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build.ps1 -Package`.
- Find the clean distribution set (`.exe`, `README.md`, `LICENSE`), versioned ZIP, and its `.zip.sha256` checksum in `dist/`. Both `Compile.cmd` and GitHub Actions create the ZIP and checksum.

Build validation checks executable version metadata and the embedded fingerprint icon. The compiler receives explicit `/out`, `/icon`, `/x64`, and `/nopack` options. Output placement and executable icon are controlled by the build script, not duplicated with `#pragma compile(Out, ...)` or `#pragma compile(Icon, ...)`. The locally downloaded `.tools/` folder is not committed to Git.

## GitHub Actions builds

For a testable build without publishing a Release, open **Actions > Build > Run workflow**. After the run succeeds, download **two separate files** under **Artifacts**: `KeePassXCHelloFocus-X.Y.Z.zip` and `KeePassXCHelloFocus-X.Y.Z.zip.sha256`. Neither download has an extra ZIP wrapper. Builds also run on pushes to `main` and pull requests; artifacts are retained for 14 days.

To create a public download, create a draft Release with a version tag (for example, `0.1.0` or `v0.1.0`) and then click **Publish release**. The `Release` workflow builds the tagged source, computes SHA-256 **after** creating the final ZIP, verifies the checksum, and attaches **both files** to that Release. Saving a draft does not trigger compilation. For an existing published Release whose build failed, use **Actions > Release > Run workflow** with its original tag, without deleting the Release. See the [build and release guide](docs/BUILD.md).

## Download verification and Windows SmartScreen

Check the checksum before running a downloaded build. From PowerShell in the directory containing **both** downloaded files (replace `0.1.0` with your version):

```powershell
$zip = '.\KeePassXCHelloFocus-0.1.0.zip'
$expected = ((Get-Content -LiteralPath "$zip.sha256" -Raw).Trim() -split '\s+')[0]
$actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
if ($actual -ine $expected) { throw 'SHA-256 mismatch: do not run this download.' }
'ZIP checksum verified.'
```

On macOS/Linux, run `sha256sum -c KeePassXCHelloFocus-0.1.0.zip.sha256` where available. The checksum is a file integrity check, **not a digital signature**. A checksum hosted beside the download cannot independently prove who published it.

Windows SmartScreen may warn about a newly downloaded, unsigned EXE because it has not yet established a reputation. This is not necessarily a malware finding, and checking a SHA-256 does **not** make the file trusted by SmartScreen. After confirming the source and checksum, if you choose to trust the download, Windows users can remove the Internet-origin mark from the **ZIP before extracting** it:

```powershell
Unblock-File -LiteralPath '.\KeePassXCHelloFocus-0.1.0.zip'
```

This affects only the selected local file, not other downloads or future versions; it does not disable SmartScreen globally or sign the application. Windows may still display a security warning depending on reputation and system policy. See [Security](docs/SECURITY.md) and [Code signing](docs/SIGNING.md).

## Limitations

- The utility recognizes a specific Windows credential dialog window class. Other authentication dialogs may not be detected.
- Windows can block changes to the focus or topmost status of protected, elevated, or system-owned windows.
- Native dark menu styling uses undocumented Windows UxTheme exports and can vary by Windows build.
- The icon is white on transparent pixels; it may be hard to see against light backgrounds.
- Neither authentication success nor the security of the authentication process is changed by this application.

## Documentation

- [Technical specification](docs/SPECIFICATION.md)
- [Build and release guide](docs/BUILD.md)
- [Code signing guide](docs/SIGNING.md)
- [Manual acceptance tests](docs/TESTING.md)
- [Security and scope](docs/SECURITY.md)
- [License details](docs/LICENSING.md)
- [Changelog](CHANGELOG.md)

## License

The project-owned source code and documentation are released under the **MIT License**. See [LICENSE](LICENSE) for the license text and [license details](docs/LICENSING.md) for third-party components. AutoIt, KeePassXC, and Windows are separate projects with their own terms and trademarks.
