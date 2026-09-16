#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install OptiPNG, command line tool to optimize PNG files.
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

Write-Output "==== OptiPNG download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# There is no Arm64 binary, use the x64 one in all cases.
$DownloadPage = "https://optipng.sourceforge.net/"
$DownloadPattern = "*/optipng-*-win64.zip?download"

# Actions to execute in admin mode.
function Admin-Stuff([string]$Dir)
{
    # Install files.
    $TargetDir = Join-Path ([Environment]::GetFolderPath('ProgramFiles')) (Get-Item $Dir).BaseName
    Write-Output "Installing $Dir into $TargetDir"
    Remove-Item $TargetDir -Force -Recurse -ErrorAction Ignore
    Move-Item $Dir $TargetDir

    # Add OptiPNG to the system Path.
    Add-Directory-To-Path $TargetDir
}

if ($AdminStuff -ne "") {
    # Process recursion in admin mode.
    Admin-Stuff $AdminStuff 
}
else {
    # Direct invocation.
    $Url = Get-URL-In-HTML $DownloadPage $DownloadPattern
    $InstallerName = Get-URL-Local $Url
    $InstallerPath = "$Destination\$InstallerName"
    Download-Package $Url $InstallerPath

    # Expand archive in directory OptiPNG.
    Write-Output "Expanding $InstallerName"
    $ExpandDir = "$Destination\OptiPNG"
    Remove-Item $ExpandDir -Force -Recurse -ErrorAction Ignore
    [void](New-Item $ExpandDir -ItemType Directory)
    Expand-Archive $InstallerPath -DestinationPath $ExpandDir
    Get-ChildItem $ExpandDir -Directory | ForEach-Object {
        Move-Item "$($_.FullName)\*" $ExpandDir
        Remove-Item $_.FullName -Force -Recurse -ErrorAction Ignore
    }

    # Install in "Program Files in admin mode.
    if (-not $NoInstall) {
        if ($IsAdmin) {
            Admin-Stuff $ExpandDir
        }
        else {
            Recurse-Admin "-AdminStuff `"$ExpandDir`""
        }
        Propagate-Environment "Path"
    }
}

Exit-Script
