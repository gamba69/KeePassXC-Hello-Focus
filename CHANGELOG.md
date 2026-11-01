# Changelog

This project uses `MAJOR.MINOR.PATCH` release versions. The executable stores the same version as `MAJOR.MINOR.PATCH.0` in its Windows file metadata.

## Unreleased

### Changed
- License the project-owned source code and documentation under MIT; add the root `LICENSE` file to every distribution and remove the release license blocker.
- Always download and verify the latest stable portable AutoIt **on every build**, even when AutoIt is installed or a previous portable download exists.
- Never use `AUT2EXE_PATH`, installed tools, or an earlier cached compiler; fail the build if a fresh download is unavailable.
- Apply the same toolchain policy to local builds and GitHub Actions; update the README, specification, and build guide.

### Previous source refresh changes
- Keep `dist/` limited to end-user distribution files (`.exe`, `README.md`, `LICENSE`, and the ZIP).
- Move build diagnostics to `.build/logs/` and update GitHub Actions diagnostic artifact paths.
- Package the flat `dist/` file set directly, without a temporary staging directory; `Compile.cmd` now creates the ZIP by default.

### Fixed
- Removed conflicting `#pragma compile(Out, ...)` and `#pragma compile(Icon, ...)` directives; the build now exclusively controls the output path and executable icon with Aut2Exe command-line switches.
- Added a build-time guard against reintroducing these conflicting directives, and a diagnostic if an obsolete executable is found in the repository root.
- Corrected three invalid AutoIt line continuations in About window theme API calls (Au3Check errors at 404, 418, and 426).
- Wait for the GUI-based Aut2Exe compiler to complete before checking its exit status.
- Run Au3Check before compilation and retain compiler diagnostics under `.build/logs/`.

## [0.1.0] - 2026-11-01

### Added

- First GitHub-ready source release under the **KeePassXC Hello Focus** name.
- Version metadata for the compiled executable and a version string in About.
- English-language README, specification, build, security, and testing documents.
- One-command local build with discovery of installed/cached AutoIt and download of the latest stable portable AutoIt if needed.
- Portable compiler bootstrap shared by local builds and GitHub Actions, without system-wide installation or a pinned AutoIt version.
- Tag-based GitHub Release workflow and tag/version consistency checks.

### Preserved from the previous WindowsSecurityTopmost implementation

- Window detection and topmost activation behavior.
- Duplicate-instance prevention.
- Event-driven tray actions and a cached, quickly shown/hidden About dialog.
- Dedicated white fingerprint icons for the executable and tray.
- Windows application-theme integration and a native dark popup menu request.

### Historical distribution note

The initial source draft blocked public releases until a license was selected. MIT has now been selected and `LICENSE` is included.

### Build system correction (0.1.0 source refresh)

- Fixed portable AutoIt detection: identify compiler and runtime using the package layout rather than an individual compiler version resource.
- Prefer the x64 compiler when available.

### Build tooling change (0.1.0 source refresh)

- Replaced the fixed AutoIt version and SHA-256 pin with an installed/cached-first compiler selection policy.
- Download the current stable AutoIt portable package only when no compiler is available.
- Verify the publisher Authenticode signature for newly downloaded AutoIt runtime binaries.
- Use the same behavior for local builds and GitHub Actions; no update bot or pull requests.
