#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
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
    $Url = Get-URL-In-GitHub 'lucasg/Dependencies' '/Dependencies_x64_Release.zip$'
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
