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

Two independent workflows are included. Both use the same `scripts/Build.ps1 -Package` command as a local build, download the latest stable AutoIt on every run, and never use preinstalled or cached compilers.

### Test builds (`Build` workflow)

`.github/workflows/build.yml` runs automatically on pushes to `main` and pull requests. It also supports **Actions > Build > Run workflow** for manually requested builds (select the branch and click **Run workflow**).

After a **successful** run, open **Actions > Build > the completed run > Artifacts** and download the `KeePassXCHelloFocus` artifact. GitHub wraps the uploaded file in an artifact download; inside is the generated `KeePassXCHelloFocus.zip`. That ZIP contains `KeePassXCHelloFocus.exe`, `README.md`, and `LICENSE`.

Test builds **do not create or modify GitHub Releases**. Build artifacts are retained for 14 days. If compilation fails, the run is marked failed and available diagnostic logs are uploaded as the `build-diagnostics` artifact for 7 days. No successful build ZIP is generated on a failed run.

### Published releases (`Release` workflow)

`.github/workflows/release.yml` is triggered by the GitHub **Release `published`** event, not by pushing a Git tag. A draft Release does not start this workflow.

When you click **Publish release**, the workflow:

1. Checks out the selected release **tag**, not the current `main` HEAD.
2. Verifies that the tag has the form `vMAJOR.MINOR.PATCH` and that `LICENSE` is present.
3. Downloads the latest stable AutoIt and compiles the program from the tagged source.
4. Checks that the tag matches the AutoIt source version and that the compiled EXE has the required version and fingerprint icon.
5. Creates `dist/KeePassXCHelloFocus.zip` and **attaches it to the Release that was just published** using `gh release upload`.

The workflow does **not** create a second Release, overwrite release notes, or edit the title. It does not replace an existing asset with the same filename; if you already uploaded such a file, remove it before publication or the upload step will fail.

The Release becomes public immediately when published, while compilation and uploading happen afterward. The ZIP will appear under **Assets** once the workflow succeeds. Check **Actions > Release** if the asset is missing.

**Important:** GitHub requires the `release.yml` workflow to exist on the repository's default branch before a Release is published. Publish the updated source to `main` first. Workflow permissions must allow GitHub Actions to run; `release.yml` requests `contents: write` for uploading its asset.

## Publishing version 0.1.0

1. Commit the complete project to the default branch (`main`) and push it to GitHub.
2. Open **Actions > Build > Run workflow**. Download and test the ZIP from the successful run's **Artifacts** section.
3. Open **Releases > Draft a new release** (or edit an existing draft).
4. Choose or create tag `v0.1.0` pointing to the tested commit. Set the release title and description.
5. Click **Publish release**. This triggers the `Release` workflow.
6. Open **Actions > Release** to confirm success, then check that the Release contains `KeePassXCHelloFocus.zip` under **Assets**.

If the tag uses another version (for example, `v0.1.1`), update both `FileVersion` and `ProductVersion` pragmas in the `.au3` source to `0.1.1.0` before tagging. Also update the changelog and the version shown in README.

If a Release was already published *before* the new workflow was committed to the default branch, this event cannot be retroactively triggered by saving its draft or editing the text. For future releases, use the workflow above.

## Build repeatability

The build intentionally uses the latest stable upstream AutoIt at build time. The toolchain version can change when the official rolling URL is updated; binaries built at different times may differ. The toolchain version is printed in build output. The source/release version and executable icon checks are retained, but interactive GUI behavior still needs [manual testing](TESTING.md).
