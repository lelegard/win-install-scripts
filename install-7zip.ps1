#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install 7zip for Windows.
#  See parameters documentation in install-common.ps1.
#
#-----------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "",
    [switch]$ForceDownload = $false,
    [switch]$GitHubActions = $false,
    [switch]$NoInstall = $false,
    [switch]$NoPause = $false
)

Write-Output "==== 7zip download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

Install-Standard-Exe `
    "https://www.7-zip.org/download.html" `
    "*/7z*-x64.exe" `
    "https://www.7-zip.org/a/7z1900-x64.exe" `
    @("/S")

Exit-Script
