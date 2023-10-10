#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install the meson build system for Windows.
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

Write-Output "==== PuTTY download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

Install-Standard-Msi "https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html" "*/putty-64bit-*-installer.msi"
Propagate-Environment "Path"
Exit-Script
