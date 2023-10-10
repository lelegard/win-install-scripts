#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install GIMP for Windows.
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

Write-Output "==== GIMP download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

Install-Standard-Exe `
    "https://www.gimp.org/downloads/" `
    "*/gimp-*-setup*.exe" `
    "https://download.gimp.org/mirror/pub/gimp/v2.10/windows/gimp-2.10.32-setup-1.exe" `
    @("/verysilent", "/suppressmsgboxes", "/norestart", "/allusers")

Install-Standard-Exe `
    "https://www.gimp.org/downloads/" `
    "*/gimp-help-*-en-setup*.exe" `
    "https://download.gimp.org/mirror/pub/gimp/help/windows/2.10/gimp-help-2.10.0-en-setup.exe" `
    @("/verysilent", "/suppressmsgboxes", "/norestart", "/allusers")

Exit-Script
