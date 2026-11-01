# Build and Release Guide

## Prerequisites

- Windows 10/11 x64 for local builds.
- PowerShell 5.1 or newer.
- **Internet access for every build**, to download the current stable AutoIt package.
- GitHub Actions enabled for hosted builds.

Neither a system-wide AutoIt installation nor administrator privileges are required.
`scripts/Get-AutoIt.ps1` always downloads the **latest stable portable AutoIt** from the official rolling URL:

`https://www.autoitscript.com/files/autoit3/autoit-v3.zip`

Every build downloads, extracts, and verifies a new package. Installed AutoIt, a previous download in `.tools/`, and the `AUT2EXE_PATH` environment variable are **ignored**. The previous local toolchain is replaced only after the new one is verified. The resulting toolchain remains under `.tools/AutoIt/current/` for inspection but is never used as a fallback.

Validation requires the signed AutoIt runtime to have a valid Authenticode signature from AutoIt Consulting, and requires both `Aut2Exe` and `Au3Check` in the downloaded package. A fixed SHA-256 would prevent automatic adoption of future releases, so the official HTTPS download and Authenticode publisher verification are used instead.

**Failure policy:** if the official site cannot be reached, the package is incomplete, or signature verification fails, the build **fails**. It does not silently compile with an installed or cached version. The compiler version is printed in the build output; upstream updates can change the output of later builds.

## Local build

From the repository root:

```cmd
Compile.cmd
```

Or compile and create the runtime archive:

```powershell
.\scripts\Build.ps1 -Package
```

`dist/` is the clean, flat distribution directory. Both local `Compile.cmd` and
CI builds produce these outputs:

- `KeePassXCHelloFocus.exe` — standalone 64-bit Windows application.
- `README.md` — end-user information.
- `LICENSE` — MIT license; always included.
- `KeePassXCHelloFocus.zip` — archive of the above distribution files, without including itself.

The lower-level `scripts/Build.ps1` command without `-Package` prepares the
same flat distribution files but does not create the ZIP. `Compile.cmd`
requests the ZIP by default. The destination is cleared before each build,
so stale files from previous builds do not remain in `dist/`. ICO files are
compiled into the executable and do not need to be shipped separately.

Before compilation, `Au3Check.exe` validates the script syntax. `Aut2Exe` is launched with `Start-Process -Wait -PassThru` to wait for the GUI-based compiler and obtain a reliable exit code. Compiler and syntax-checker output is saved **outside** the distribution
directory in `.build/logs/` as `au3check.stdout.log`,
`au3check.stderr.log`, `aut2exe.stdout.log`, and `aut2exe.stderr.log`.
Nonempty logs are also printed to the console. Logs are ignored by Git and
can be downloaded from failed CI runs as build diagnostics. The build never
places log files in `dist/` or in the release ZIP.

The build fails with a nonzero exit code when compiler resolution, syntax checking, compilation, version metadata validation, or icon verification fails. An `Aut2Exe` exit code of zero is not sufficient on its own: the expected EXE must also exist and pass validation. The build does not prompt for input in CI under normal conditions; an error dialog from an installed compiler may still require attention.

The explicit `/out` option controls the output directory (`dist/`), and `/icon` selects the fingerprint icon. The source intentionally does **not** declare `#pragma compile(Out, ...)` or `#pragma compile(Icon, ...)`, as duplicating these options can produce an EXE in a different directory than the build expects. `/nopack` avoids UPX compression and `/x64` produces an x64 application. The build rejects source-level `Out` and `Icon` pragmas to prevent regression.

If a previous build left a `KeePassXCHelloFocus.exe` in the repository root, do not treat it as the latest build. The supported output is `dist/KeePassXCHelloFocus.exe`. The build checks that exact destination.

## GitHub Actions

`.github/workflows/build.yml` runs on pushes to `main`, pull requests, and manual dispatch. It downloads a fresh stable AutoIt package on a Windows runner, then uploads the packaged ZIP as a CI artifact. **No Release is published by the build workflow.**

`.github/workflows/release.yml` runs for pushed tags matching `v*`. It:

1. Verifies the MIT `LICENSE` file is present.
2. Downloads the latest stable portable AutoIt, regardless of installed or cached copies.
3. Compiles the source, checking that the Git tag matches the source's `FileVersion` declaration.
4. Checks the compiled Windows version metadata and embedded fingerprint icon.
5. Packages `KeePassXCHelloFocus.zip`.
6. Publishes a GitHub Release with the ZIP and release notes.

Every local and CI build fetches the stable package anew, including when a Windows runner has AutoIt installed. No version pinning, auto-update bot, pull request, or cache-based fallback is used. This deliberately sacrifices byte-for-byte reproducibility across future upstream AutoIt releases; run manual GUI tests before publishing.

The repository includes the **MIT License**, so public releases are enabled once the repository and tags are published. See [LICENSING.md](LICENSING.md) for the distinction between project assets and third-party tooling.

## Publishing version 0.1.0

After reviewing and testing the code:

```bash
git add .
git commit -m "Prepare v0.1.0"
git push origin main
git tag -a v0.1.0 -m "KeePassXC Hello Focus v0.1.0"
git push origin v0.1.0
```

A tag `v0.1.1` will be rejected unless the source version metadata is updated to `0.1.1.0` in **both** `FileVersion` and `ProductVersion` pragmas. Update the changelog and README release label when incrementing the version.

## Build repeatability

The build intentionally uses the latest stable upstream AutoIt at build time. The toolchain version can change when the official rolling URL is updated; binaries built at different times may differ. The toolchain version is printed in build output. The source/release version and executable icon checks are retained, but interactive GUI behavior still needs [manual testing](TESTING.md).
