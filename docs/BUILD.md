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

### Draft release packaging (`Release` workflow)

`.github/workflows/release.yml` runs **only** from **Actions > Release > Run workflow**. It does not run on `release: published`, tag pushes, or saving a draft. The user controls when a GitHub Release is published.

For repositories using **Immutable Releases**, every asset must be uploaded **before publication**. GitHub will reject uploads, replacements, and deletions after publishing. The workflow therefore accepts **only an existing Draft Release** and refuses to operate on an already published release. It also accepts either `X.Y.Z` or `vX.Y.Z` tags. The **Git tag must already exist on GitHub**, so the tagged commit can be checked out by Actions.

When started manually, the workflow:

1. Checks out the source from the exact existing tag, **not** the current `main` HEAD.
2. Verifies the tag format, the MIT `LICENSE`, and that a Draft Release exists for the supplied tag.
3. Downloads the latest stable AutoIt, checks source syntax, compiles the EXE, and verifies its version and icon.
4. Creates `dist/KeePassXCHelloFocus-X.Y.Z.zip` and `dist/KeePassXCHelloFocus-X.Y.Z.zip.sha256`, then checks the final ZIP hash.
5. Checks that the release is **still a draft**, uploads both assets to the draft, and confirms that both are listed in the release.

The upload uses `--clobber` to allow a failed/incomplete draft upload to be retried **while the release is still a draft**. Its title, notes, and publication state are not changed. Two runs for the same tag cannot upload concurrently. If compilation fails, the workflow leaves the draft unpublished, so the problem can be fixed safely before publication.

**Publishing is manual:** after the workflow succeeds, inspect the two assets on the draft page, then click **Publish release** yourself. Do not publish while the workflow is running. Once published, an immutable release cannot receive more assets—even via a manual rerun. If a published release is wrong or incomplete, use a **new version** and new draft, rather than attempting to repair it in place.

**Important:** commit and push the corrected `release.yml` to the default branch (`main`) **before** starting the workflow. The manual `Run workflow` control uses the workflow on the selected branch (`main`); the checked-out application source comes from the chosen tag.

## Publishing version 0.1.1

1. Apply this patch, commit it to `main`, and push. Confirm that the **Build** workflow succeeds. Download and test the ZIP and checksum from **Actions > Build > Artifacts**.
2. Make sure the tag refers to the tested commit, then push an actual Git tag **before creating a draft**:

   ```cmd
   git tag 0.1.1
   git push origin 0.1.1
   ```

   Use `v0.1.1` instead only if you consistently prefer the `v` prefix. Do not reuse `0.1.0` after deleting an immutable release with that tag.
3. Open **Releases > Draft a new release**; **choose the existing** `0.1.1` tag, fill in the title and notes, and click **Save draft** (NOT **Publish release**).
4. Open **Actions > Release > Run workflow**. Select branch `main` and enter the exact existing draft tag `0.1.1`.
5. Confirm the workflow is green. Open the draft again and check its Assets: `KeePassXCHelloFocus-0.1.1.zip` and `KeePassXCHelloFocus-0.1.1.zip.sha256` must both be present.
6. Optionally download and test the assets. Only then click **Publish release**. Publishing does not trigger any build or upload.

For future releases, change both `FileVersion` and `ProductVersion` in the AutoIt source to `X.Y.Z.0`, update README/changelog, and follow the same steps with a **new** tag. Never move or reuse tags associated with published immutable releases.

## SHA-256 release integrity

The build calculates SHA-256 only after creating the complete versioned ZIP. It writes `KeePassXCHelloFocus-X.Y.Z.zip.sha256` in GNU `sha256sum` format, **outside** the ZIP, and verifies the digest again in GitHub Actions before publishing. Rebuilding the same source later may produce different bytes because the latest stable AutoIt is downloaded for every build; each published checksum corresponds to the **specific uploaded archive**, not to all releases sharing a version string.

On Windows, use the PowerShell verification commands in [README.md](../README.md#download-verification-and-windows-smartscreen). On Linux/macOS with GNU coreutils, use `sha256sum -c KeePassXCHelloFocus-X.Y.Z.zip.sha256`. Download the ZIP and checksum from the same build or Release. Checksums detect unexpected file changes but do not authenticate the publisher when obtained from the same website; a trusted Authenticode signature is a separate mechanism.

## Code signing

The current workflow does not sign the executable. A GitHub-hosted build does not automatically produce a publicly trusted Authenticode signature. Before adding signing, the project maintainer must obtain a signing identity and choose a compatible service or certificate. Signing must happen **after compilation but before packaging**; do not modify the EXE after signing.

See [Code signing](SIGNING.md) for options and commands. An untrusted self-signed certificate is unsuitable for public SmartScreen reputation.

## Build repeatability

The build intentionally uses the latest stable upstream AutoIt at build time. The toolchain version can change when the official rolling URL is updated; binaries built at different times may differ. The toolchain version is printed in build output. The source/release version and executable icon checks are retained, but interactive GUI behavior still needs [manual testing](TESTING.md).
