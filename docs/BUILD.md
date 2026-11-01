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
- `KeePassXCHelloFocus-X.Y.Z.zip` — versioned archive of the above distribution files, without including itself. The version is taken from the AutoIt source metadata.
- `KeePassXCHelloFocus-X.Y.Z.zip.sha256` — SHA-256 of the **final ZIP**, outside that ZIP; one lowercase hexadecimal digest and filename, compatible with `sha256sum -c`.

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

Two independent workflows are included. Both use the same `scripts/Build.ps1 -Package` command as a local build, download the latest stable AutoIt on every run, and never use preinstalled or cached compilers.

### Test builds (`Build` workflow)

`.github/workflows/build.yml` runs automatically on pushes to `main` and pull requests. It also supports **Actions > Build > Run workflow** for manually requested builds (select the branch and click **Run workflow**).

After a **successful** run, open **Actions > Build > the completed run > Artifacts** and download **both** `KeePassXCHelloFocus-X.Y.Z.zip` and `KeePassXCHelloFocus-X.Y.Z.zip.sha256`. Each is a separate artifact without an extra ZIP wrapper. `actions/upload-artifact@v7` with `archive: false` only supports one file per upload. The ZIP contains `KeePassXCHelloFocus.exe`, `README.md`, and `LICENSE`; the checksum is generated and verified against its final bytes before upload.

Test builds **do not create or modify GitHub Releases**. Build artifacts are retained for 14 days. If compilation fails, the run is marked failed and available diagnostic logs are uploaded as the `build-diagnostics` artifact for 7 days. No successful build ZIP is generated on a failed run.

### Published releases (`Release` workflow)

`.github/workflows/release.yml` is triggered by the GitHub **Release `published`** event, not by pushing a Git tag. A draft Release does not start this workflow.

When you click **Publish release**, the workflow:

1. Checks out the selected release **tag**, not the current `main` HEAD.
2. Verifies that the tag has the form `vMAJOR.MINOR.PATCH` and that `LICENSE` is present.
3. Downloads the latest stable AutoIt and compiles the program from the tagged source.
4. Checks that the tag matches the AutoIt source version and that the compiled EXE has the required version and fingerprint icon.
5. Creates `dist/KeePassXCHelloFocus-X.Y.Z.zip`, computes and verifies `dist/KeePassXCHelloFocus-X.Y.Z.zip.sha256`, and **attaches both files to the Release that was just published** using `gh release upload`.

The workflow does **not** create a second Release, overwrite release notes, or edit the title. It does not replace an existing asset with the same filename; if you already uploaded such a file, remove it before publication or the upload step will fail.

The Release becomes public immediately when published, while compilation and uploading happen afterward. The ZIP and `.zip.sha256` file will appear under **Assets** once the workflow succeeds. Check **Actions > Release** if either file is missing.

**Important:** GitHub requires the `release.yml` workflow to exist on the repository's default branch before a Release is published. Publish the updated source to `main` first. Workflow permissions must allow GitHub Actions to run; `release.yml` requests `contents: write` for uploading its asset.

## Publishing version 0.1.0

1. Commit the complete project to the default branch (`main`) and push it to GitHub.
2. Open **Actions > Build > Run workflow**. Download and test the ZIP from the successful run's **Artifacts** section.
3. Open **Releases > Draft a new release** (or edit an existing draft).
4. Choose or create tag `v0.1.0` pointing to the tested commit. Set the release title and description.
5. Click **Publish release**. This triggers the `Release` workflow.
6. Open **Actions > Release** to confirm success, then check that the Release contains `KeePassXCHelloFocus-0.1.0.zip` **and** `KeePassXCHelloFocus-0.1.0.zip.sha256` under **Assets** (or the matching version for another release).

If the tag uses another version (for example, `v0.1.1`), update both `FileVersion` and `ProductVersion` pragmas in the `.au3` source to `0.1.1.0` before tagging. Also update the changelog and the version shown in README.

If a Release was already published *before* the new workflow was committed to the default branch, this event cannot be retroactively triggered by saving its draft or editing the text. For future releases, use the workflow above.

## SHA-256 release integrity

The build calculates SHA-256 only after creating the complete versioned ZIP. It writes `KeePassXCHelloFocus-X.Y.Z.zip.sha256` in GNU `sha256sum` format, **outside** the ZIP, and verifies the digest again in GitHub Actions before publishing. Rebuilding the same source later may produce different bytes because the latest stable AutoIt is downloaded for every build; each published checksum corresponds to the **specific uploaded archive**, not to all releases sharing a version string.

On Windows, use the PowerShell verification commands in [README.md](../README.md#download-verification-and-windows-smartscreen). On Linux/macOS with GNU coreutils, use `sha256sum -c KeePassXCHelloFocus-X.Y.Z.zip.sha256`. Download the ZIP and checksum from the same build or Release. Checksums detect unexpected file changes but do not authenticate the publisher when obtained from the same website; a trusted Authenticode signature is a separate mechanism.

## Code signing

The current workflow does not sign the executable. A GitHub-hosted build does not automatically produce a publicly trusted Authenticode signature. Before adding signing, the project maintainer must obtain a signing identity and choose a compatible service or certificate. Signing must happen **after compilation but before packaging**; do not modify the EXE after signing.

See [Code signing](SIGNING.md) for options and commands. An untrusted self-signed certificate is unsuitable for public SmartScreen reputation.

## Build repeatability

The build intentionally uses the latest stable upstream AutoIt at build time. The toolchain version can change when the official rolling URL is updated; binaries built at different times may differ. The toolchain version is printed in build output. The source/release version and executable icon checks are retained, but interactive GUI behavior still needs [manual testing](TESTING.md).
