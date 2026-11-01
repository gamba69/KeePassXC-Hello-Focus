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
2. Download `KeePassXCHelloFocus.zip` and extract it.
3. Run `KeePassXCHelloFocus.exe`.
4. Right-click its tray icon to open **About...** or select **Exit**.

The release EXE is standalone. AutoIt and Python are **not required** on the target computer. No installer or administrator privileges are requested. A second launch silently exits.

To start the utility automatically when signing in, place a shortcut to the EXE in the Windows Startup folder (`Win+R`, then `shell:startup`).

## Build from source

AutoIt does **not** need to be installed. Every run of `Compile.cmd` (and every GitHub Actions build) downloads a **fresh copy of the latest stable portable AutoIt** from the [official AutoIt website](https://www.autoitscript.com/site/autoit/downloads/). It **never** uses an installed AutoIt, a previously downloaded compiler, or `AUT2EXE_PATH`.

The downloaded AutoIt runtime's Authenticode signature is verified before compilation. The new toolchain is kept under `.tools/AutoIt/current/` for inspection, but never reused by subsequent builds. An internet connection is required **for every build**. If download or verification fails, the build stops instead of using an older compiler. No administrator privileges, installation, or Python are needed. The rolling download may change when AutoIt publishes a new stable version; see [build documentation](docs/BUILD.md).

- Run `Compile.cmd` in the repository root.
- Or run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build.ps1 -Package`.
- Find the clean distribution set (`.exe`, `README.md`, `LICENSE`) and the ZIP in `dist/`. Both `Compile.cmd` and GitHub Actions create the ZIP.

Build validation checks executable version metadata and the embedded fingerprint icon. The compiler receives explicit `/out`, `/icon`, `/x64`, and `/nopack` options. Output placement and executable icon are controlled by the build script, not duplicated with `#pragma compile(Out, ...)` or `#pragma compile(Icon, ...)`. The locally downloaded `.tools/` folder is not committed to Git.

## GitHub Actions builds

For a testable build without publishing a Release, open **Actions > Build > Run workflow**. After the run succeeds, download `KeePassXCHelloFocus` under **Artifacts**; it contains the distribution ZIP. Builds also run on pushes to `main` and pull requests. Build artifacts are retained for 14 days.

To create a public download, create a draft Release with a version tag (for example, `v0.1.0`) and then click **Publish release**. The separate `Release` workflow builds the tagged source and attaches `KeePassXCHelloFocus.zip` to that existing Release. Saving a draft does not trigger compilation; the ZIP appears under **Assets** after the published-release workflow finishes successfully. See the [build and release guide](docs/BUILD.md).

## Limitations

- The utility recognizes a specific Windows credential dialog window class. Other authentication dialogs may not be detected.
- Windows can block changes to the focus or topmost status of protected, elevated, or system-owned windows.
- Native dark menu styling uses undocumented Windows UxTheme exports and can vary by Windows build.
- The icon is white on transparent pixels; it may be hard to see against light backgrounds.
- Neither authentication success nor the security of the authentication process is changed by this application.

## Documentation

- [Technical specification](docs/SPECIFICATION.md)
- [Build and release guide](docs/BUILD.md)
- [Manual acceptance tests](docs/TESTING.md)
- [Security and scope](docs/SECURITY.md)
- [License details](docs/LICENSING.md)
- [Changelog](CHANGELOG.md)

## License

The project-owned source code and documentation are released under the **MIT License**. See [LICENSE](LICENSE) for the license text and [license details](docs/LICENSING.md) for third-party components. AutoIt, KeePassXC, and Windows are separate projects with their own terms and trademarks.
