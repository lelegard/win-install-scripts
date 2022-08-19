#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
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
#
#  Download and install Dependencies (modern version of Dependency Walker).
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
    [string]$AdminStuff = ""
)

Write-Output "==== Dependencies download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Actions to execute in admin mode.
function Admin-Stuff([string]$Dir)
{
    $TargetDir = [Environment]::GetFolderPath('ProgramFiles') + "\Dependencies"
    Write-Output "Installing $Dir into $TargetDir"
    Remove-Item $TargetDir -Force -Recurse -ErrorAction Ignore
    Move-Item $Dir $TargetDir
    Add-Start-Menu-Entry "Dependencies" "$TargetDir\DependenciesGui.exe" "" $true
}

if ($AdminStuff -ne "") {
    # Process recursion in admin mode.
    Admin-Stuff $AdminStuff 
}
else {
    # Direct invocation.
    Write-Output "==== @@@@ direct"
    $Url = Get-URL-In-HTML "https://github.com/lucasg/Dependencies/releases/latest" "*/Dependencies_x64_Release.zip"
    Write-Output "==== @@@@ URL: $Url"
    $InstallerName = Get-URL-Local $Url
    $InstallerPath = "$Destination\$InstallerName"
    Download-Package $Url $InstallerPath

    if (-not $NoInstall) {
        Write-Output "Expanding $InstallerName"
        $InstallerDir = "$Destination\$((Get-Item $InstallerPath).BaseName)"
        Remove-Item $InstallerDir -Force -Recurse -ErrorAction Ignore
        [void](New-Item $InstallerDir -ItemType Directory)
        Expand-Archive $InstallerPath -DestinationPath $InstallerDir

        if ($IsAdmin) {
            Admin-Stuff $InstallerDir
        }
        else {
            Recurse-Admin "-AdminStuff `"$InstallerDir`""
        }
    }
}

Exit-Script
