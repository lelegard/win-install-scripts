#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Enable the Administrator account and make it appear in the login page.
#  On Windows 10 Home, this is not done by default.
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

Write-Output "==== Windows Administrator account enabling procedure"

. "$PSScriptRoot\install-common.ps1"

if ($NoInstall) {
    Write-Output "Builtin Windows feature, nothing to do"
}
elseif (-not $IsAdmin) {
    # Execution for non-admin user, recurse for admin part.
    Recurse-Admin
}
else {
    Write-Output "Enabling $AdminUserName account ..."
    net user $AdminUserName /active:yes
}

Exit-Script
