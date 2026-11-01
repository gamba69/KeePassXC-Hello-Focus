# Code Signing

KeePassXC Hello Focus is distributed as a standalone Windows executable. GitHub Actions can build it, but **GitHub does not automatically sign executables with a publicly trusted Authenticode certificate**.

## Public signing options

- **SignPath Foundation:** free signing for eligible open-source projects. Apply at <https://signpath.org/apply>. The project must satisfy SignPath's source, licensing, maintenance, and signing policy requirements; acceptance is not guaranteed. In particular, confirm whether an AutoIt-compiled executable qualifies under its third-party component rules.
- **CA-issued OV code-signing certificate:** obtain an identity-validated Authenticode certificate from a trusted certificate authority. Private keys are commonly provided on hardware tokens or through an approved HSM-backed service. Typical ongoing fees apply.
- **Microsoft Artifact Signing:** a managed Azure service, subject to identity verification and geographic eligibility limits. Check eligibility before designing its GitHub Actions integration.

**Do not use a self-signed test certificate for a public release.** Windows does not trust it by default, and it does not establish SmartScreen publisher reputation.

## Signing with a trusted certificate

Once a trusted signing identity is available, the Windows SDK's `signtool.exe` can sign a locally built EXE. For example, when the certificate and private key are accessible through the Windows certificate store (using the certificate's actual SHA-1 thumbprint):

```cmd
signtool sign /sha1 YOUR_CERTIFICATE_THUMBPRINT /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "dist\KeePassXCHelloFocus.exe"
signtool verify /pa /v "dist\KeePassXCHelloFocus.exe"
```

The timestamp authority is a public example; follow your certificate provider's instructions. Timestamping is important so signatures can remain valid after the signing certificate expires. Never commit signing secrets or private keys to Git.

The correct release sequence is:

1. Compile and validate the unsigned executable.
2. Sign the executable using the approved certificate or managed signing service.
3. Verify the resulting Authenticode signature.
4. Package the **signed** executable, `README.md`, and `LICENSE` into `KeePassXCHelloFocus-X.Y.Z.zip`.
5. Attach that ZIP to the GitHub Release.

The existing build script currently packages immediately after compilation; it **does not** implement these signing steps. Choose the signing provider before modifying the build and release workflows. Do not sign the EXE after the ZIP has already been published without regenerating and replacing the archive.

A valid public signature identifies the publisher and protects integrity; it does not guarantee that SmartScreen immediately stops warning about a new executable.

## References

- [Microsoft: code signing options](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options)
- [Microsoft: SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [Microsoft: SmartScreen reputation](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation)
- [SignPath Foundation](https://signpath.org/)
