#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install draw.io for Windows.
#  See parameters documentation in install-common.ps1.
#
#  When used as command line to convert file, use start-process:
#  Start-Process -Wait -FilePath "C:\Program Files (x86)\draw.io\draw.io.exe"
#      -ArgumentList @("-x", "file.drawio", "-o", "file.png")
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

Write-Output "==== Draw.io download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

Install-WinGet JGraph.Draw

Exit-Script
