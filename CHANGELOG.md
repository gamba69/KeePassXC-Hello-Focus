# Changelog

This project uses `MAJOR.MINOR.PATCH` release versions. The executable stores the same version as `MAJOR.MINOR.PATCH.0` in its Windows file metadata.

## Unreleased

## [0.1.1] - 2026-11-01

### Fixed
- Rework immutable GitHub Releases: manually build and upload ZIP plus SHA-256 to a **Draft Release** before publication, never after. Refuse uploads to published releases; the user publishes manually.
- Verify both release assets are present in the draft before declaring success, and prevent concurrent uploads for the same tag.
- Bump the executable and package version from 0.1.0 to 0.1.1. The `0.1.0` release cannot be recreated under an immutable previously used tag.

### Changed
- Publish a `.zip.sha256` checksum next to the final versioned ZIP in local `dist/`, GitHub Actions Artifacts, and GitHub Releases; verify the checksum before CI publication.
- Document SHA-256 download verification and Windows SmartScreen/Mark-of-the-Web behavior without disabling Windows security features.
- Download test-build Artifacts as a single versioned distribution ZIP using `actions/upload-artifact@v7` with `archive: false` (no nested ZIP).
- Document public Authenticode signing options and the sign-before-package requirement; signing is not enabled until a verified identity is selected.
- Name distribution ZIPs and GitHub Actions artifacts `KeePassXCHelloFocus-X.Y.Z` using the version already declared in the AutoIt source. Release assets retain the matching versioned filename.
- Publish test-build ZIPs as GitHub Actions artifacts on push, pull requests, and manual `Run workflow` (14-day retention).
- Build and attach ZIP plus SHA-256 to an existing Draft Release on explicit manual request, before the user publishes it.
- Document how to test builds before publishing and where to find successful ZIPs and failure logs.
- License the project-owned source code and documentation under MIT; add the root `LICENSE` file to every distribution and remove the release license blocker.
- Always download and verify the latest stable portable AutoIt **on every build**, even when AutoIt is installed or a previous portable download exists.
- Never use `AUT2EXE_PATH`, installed tools, or an earlier cached compiler; fail the build if a fresh download is unavailable.
- Apply the same toolchain policy to local builds and GitHub Actions; update the README, specification, and build guide.

### Previous source refresh changes
- Keep `dist/` limited to end-user distribution files (`.exe`, `README.md`, `LICENSE`, and the ZIP).
- Move build diagnostics to `.build/logs/` and update GitHub Actions diagnostic artifact paths.
- Package the flat `dist/` file set directly, without a temporary staging directory; `Compile.cmd` now creates the ZIP by default.

### Other fixes
- Accept release tags with or without a `v` prefix and allow manual retry of failed **draft** Release asset builds before publication.
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
