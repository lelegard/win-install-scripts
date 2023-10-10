#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install the libusb library for Windows.
#  The script install-7zip.ps1 is required if 7z is not installed.
#  See parameters documentation in install-common.ps1.
#
#-----------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "",
    [switch]$ForceDownload = $false,
    [switch]$GitHubActions = $false,
    [switch]$NoInstall = $false,
    [switch]$NoPause = $false,
    # Internal parameters for recursion as administrator:
    [switch]$Install = $false,
    [string]$7z = "",
    [string]$SourceArchive = "",
    [string]$BinArchive = ""
)

Write-Output "==== libusb download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Recursion as administrator
if ($Install) {
    # Expand binary 7z into Program Files\libusb.
    $InstallDir = (Join-Path $env:ProgramFiles "libusb")
    Remove-Item -Recurse -Force -ErrorAction Ignore $InstallDir
    [void](New-Item -Path $InstallDir -ItemType Directory -Force)
    . "$7z" x -y "-o$InstallDir" "$BinArchive"

    # Copy source archive in subdirectory "source".
    $SourceDir = (Join-Path $InstallDir "source")
    [void](New-Item -Path $SourceDir -ItemType Directory -Force)
    Copy-Item -Path $SourceArchive -Destination $SourceDir

    # Define system-wide environment variable.
    Define-Environment "LIBUSB" $InstallDir
    Exit-Script
}

# Get the 20 latest releases. Keep the first one which is not a prerelease.
$AllReleases = (Get-Releases-In-GitHub "libusb/libusb")
$Release = $AllReleases | Where-Object prerelease -eq $false | Select-Object -First 1
$Version = $Release.tag_name -replace '^v',''
$SourceURL = $Release.tarball_url
$BinaryURL = $Release.assets | ForEach-Object { $_.browser_download_url } | Select-String @("/*.7z$") | Select-Object -First 1

if (-not $BinaryURL) {
    Exit-Script "Could not find a libusb installer on GitHub"
}
if (-not $SourceURL) {
    Exit-Script "Could not find a libusb source archive on GitHub"
}

# Local installer file.
$SourceName = "libusb-${Version}.tgz"
$SourcePath = "$Destination\$SourceName"
$InstallerName = Get-URL-Local $BinaryURL
$InstallerPath = "$Destination\$InstallerName"

# Download installer and source archive.
Download-Package $BinaryURL $InstallerPath
Download-Package $SourceURL $SourcePath

# A function to search 7zip command line.
function Search-7z()
{
    return (Get-ChildItem -Recurse -Path @("C:\Program Files\7-zip","C:\Program Files (x86)\7-zip") -Include 7z.exe -ErrorAction Ignore | Select-Object -First 1)
}

# Locate 7zip and, if not found, try to install it.
$7z = Search-7z
if (-not $7z) {
    Write-Output "7-zip not found, trying to install it first"
    $Install7Zip = "$PSScriptRoot\install-7zip.ps1"
    if (-not (Test-Path $Install7Zip)) {
        Exit-Script "$Install7Zip not found, manually install 7-zip and retry"
    }
    & $Install7Zip -NoPause
    $7z = Search-7z
    if (-not $7z) {
        Exit-Script "7-zip still not found, manually install it and retry"
    }
}

# Install package (recurse same script in administrator mode).
if (-not $NoInstall) {
    Write-Output "Installing $InstallerName"
    Recurse-Admin "-Install -7z '$7z' -SourceArchive '$SourcePath' -BinArchive '$InstallerPath'"
}

# Propagate LIBUSB in next jobs for GitHub Actions.
Propagate-Environment "LIBUSB"

Exit-Script
