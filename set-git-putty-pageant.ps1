#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Define environment variable so that git uses Putty Pageant as SSH agent.
#
#-----------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$NoPause = $false)

Write-Output "==== Git will now use Putty Pageant as SSH agent"

. "$PSScriptRoot\install-common.ps1"
Define-UserEnvironment "GIT_SSH" "C:\Program Files\PuTTY\plink.exe"
Send-SettingChange
Exit-Script
