#-----------------------------------------------------------------------------
#
#  Copyright (c) 2021, Thierry Lelegard
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#  THE POSSIBILITY OF SUCH DAMAGE.
#
#-----------------------------------------------------------------------------

<#
 .SYNOPSIS

  Download and install the libusb library for Windows.

 .PARAMETER Destination

  Specify a local directory where the package will be downloaded.
  By default, use the downloads folder for the current user.

 .PARAMETER ForceDownload

  Force a download even if the package is already downloaded.

 .PARAMETER GitHubActions

  When used in a GitHub Action workflow, make sure that the required
  environment variables are propagated to subsequent jobs.

 .PARAMETER NoInstall

  Do not install the package. By default, the package is installed.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
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

# A function to exit this script.
function Exit-Script([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Output "ERROR: $Message"
        $Code = 1
    }
    if (-not $NoPause) {
        pause
    }
    exit $Code
}

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
    [System.Environment]::SetEnvironmentVariable("LIBUSB", $InstallDir, [System.EnvironmentVariableTarget]::Machine)
    Exit-Script
}

Write-Output "==== libusb download and installation procedure"

# Without this, Invoke-WebRequest is awfully slow.
$ProgressPreference = 'SilentlyContinue'

# Get the 20 latest releases. Keep the first one which is not a prerelease.
$AllReleases = Invoke-RestMethod "https://api.github.com/repos/libusb/libusb/releases?per_page=20"
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

# Create the directory for external products or use default.
if (-not $Destination) {
    $Destination = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
}
else {
    [void](New-Item -Path $Destination -ItemType Directory -Force)
}

# Local installer file.
$SourceName = "libusb-${Version}.tgz"
$SourcePath = "$Destination\$SourceName"
$InstallerName = (Split-Path -Leaf $BinaryURL)
$InstallerPath = "$Destination\$InstallerName"

# Download installer and source archive.
if (-not $ForceDownload -and (Test-Path $InstallerPath)) {
    Write-Output "$InstallerName already downloaded, use -ForceDownload to download again"
}
else {
    Write-Output "Downloading $BinaryURL ..."
    Invoke-WebRequest $BinaryURL.ToString() -UseBasicParsing -UserAgent Download -OutFile $InstallerPath
    if (-not (Test-Path $InstallerPath)) {
        Exit-Script "$BinaryURL download failed"
    }
}
if (-not $ForceDownload -and (Test-Path $SourcePath)) {
    Write-Output "$SourceName already downloaded, use -ForceDownload to download again"
}
else {
    Write-Output "Downloading $SourceURL ..."
    Invoke-WebRequest $SourceURL.ToString() -UseBasicParsing -UserAgent Download -OutFile $SourcePath
    if (-not (Test-Path $SourcePath)) {
        Exit-Script "$SourceURL download failed"
    }
}

# A function to search 7zip command line.
function Search-7z()
{
    return (Get-ChildItem -Recurse -Path @("C:\Program Files\7-zip","C:\Program Files (x86)\7-zip") -Include 7z.exe -ErrorAction Ignore | Select-Object -First 1)
}

# Locate 7zip and, if not found, try to install it.
$7z = Search-7z
if (-not $7z) {
    Write-Output "7-zip not found, trying to install it first"
    $Install7Zip = (Join-Path $PSScriptRoot "install-7zip.ps1")
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
    $cmd = "& '" + $PSCommandPath + "' -Install -7z '" + $7z + "' -SourceArchive '" + $SourcePath + "' -BinArchive '" + $InstallerPath + "'"
    if ($NoPause) {
        $cmd += " -NoPause"
    }
    Start-Process -Wait -Verb runas -FilePath PowerShell.exe -ArgumentList @("-ExecutionPolicy", "RemoteSigned", "-Command", $cmd)
}

# Propagate LIBUSB in next jobs for GitHub Actions.
if ($GitHubActions) {
    $libusb = [System.Environment]::GetEnvironmentVariable("LIBUSB","Machine")
    Write-Output "LIBUSB=$libusb" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
}

Exit-Script
