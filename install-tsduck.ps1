#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install TSDuck for Windows.
#  See parameters documentation in install-common.ps1.
#
#  Additional parameters:
#
#  -All
#     Install all options. By default, only the tools, plugins and
#     documentation are installed. In case of upgrade over an existing
#     installation, the default is to upgrade the same options as in the
#     previous installation.
#
#-----------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$All = $false,
    [string]$Destination = "",
    [switch]$ForceDownload = $false,
    [switch]$GitHubActions = $false,
    [switch]$NoInstall = $false,
    [switch]$NoPause = $false
)

Write-Output "==== TSDuck download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Installer options.
$ArgList = @("/S")
if ($All) {
    $ArgList += "/all=true"
}

Install-Standard-Exe "https://github.com/tsduck/tsduck/releases/latest" "*/TSDuck-Win64-*.exe" "" $ArgList
Propagate-Environment "TSDUCK"
Propagate-Environment "Path"
Propagate-Environment "PYTHONPATH"
Propagate-Environment "CLASSPATH"
Exit-Script
