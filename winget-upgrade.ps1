#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Upgrade all installed winget packages.
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

Write-Output "==== Upgrade all installed winget packages"

. "$PSScriptRoot\install-common.ps1"

if ($NoInstall) {
    Write-Output "Winget procedure, nothing to do"
}
elseif (-not $IsAdmin) {
    # Execution for non-admin user, recurse for admin part.
    Recurse-Admin
}
else {
    winget upgrade --all --disable-interactivity --accept-package-agreements --accept-source-agreements
}

Exit-Script
