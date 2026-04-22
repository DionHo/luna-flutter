# Build a release Windows MSIX.
# Usage (PowerShell):  .\scripts\build_windows.ps1
#
# Requires the msix pub package and a valid Publisher certificate.
# See https://pub.dev/packages/msix for setup.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host '==> flutter build windows --release'
flutter build windows --release

Write-Host '==> Creating MSIX package'
dart run msix:create

Write-Host '==> Done: build\windows\x64\runner\Release\luna_flutter.msix'
