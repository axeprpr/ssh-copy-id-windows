# Winget Publish Workflow

This repository keeps one canonical set of manifests in `winget-manifests/`.

Those files are not submitted to winget directly from this repository. The actual submission target is the `microsoft/winget-pkgs` repository, under:

```text
manifests/a/axeprpr/SSHCopyID/<Version>/
```

## Release Order

1. Update the app version in `main.go`.
2. Build `ssh-copy-id.exe`.
3. Publish a GitHub Release in `axeprpr/ssh-copy-id-windows`.
4. Update `winget-manifests/` so the version, release URL, and SHA256 match that GitHub Release.
5. Copy the manifest files into a fork of `microsoft/winget-pkgs`.
6. Open a Pull Request to `microsoft/winget-pkgs`.

## Local Helper Script

Use:

```powershell
.\scripts\release-and-winget.ps1 -Version 1.1.1
```

The script will:

- align the version in `main.go`
- build `ssh-copy-id.exe`
- compute the SHA256
- update the manifests in `winget-manifests/`
- stage a ready-to-submit folder under `out/winget-pkgs/manifests/a/axeprpr/SSHCopyID/<Version>/`

If `gh` is installed and authenticated, the script can also create the Git tag and GitHub Release.

## Notes

- Do not keep versioned winget submission folders like `1.1.0/` in the root of this repository.
- Treat `winget-manifests/` as the source of truth for the next submission only.
- `InstallerSha256` must match the exact binary attached to the GitHub Release.

## References

- Microsoft Learn: Windows Package Manager manifest repository
  https://learn.microsoft.com/en-us/windows/package-manager/package/repository
- Microsoft Learn: Package manifest authoring
  https://learn.microsoft.com/en-us/windows/package-manager/package/manifest
