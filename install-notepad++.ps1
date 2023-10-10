#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install Notepad++.
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

Write-Output "==== Notepad++ download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Web page for the latest releases.
$ReleasePage = "https://notepad-plus-plus.org/downloads/"
$FallbackURL = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.2.1/npp.8.2.1.Installer.x64.exe"

# Get the HTML page for downloads.
$Url = $null
$response = Get-HTML $ReleasePage
if ($response -ne $null) {
    foreach ($link in $response.Links.href) {
        # Build the absolute URL's from base URL (the download page) and href links.
        $link = New-Object -TypeName 'System.Uri' -ArgumentList ([System.Uri]$ReleasePage, $link)
        # Is this a link to a "vNNN" subdirectory?
        if ($link.ToString() -match "${ReleasePage}v[\.0-9]*/") {
            # Locate installer in that subdirectory.
            $page = Get-HTML $link
            if ($page -ne $null) {
                $ref = $page.Links.href | Where-Object { $_ -like "*npp.*.Installer.x64.exe*" } | Select-Object -First 1
                if (-not -not $ref) {
                    # Build the absolute URL's from base URL.
                    $Url = New-Object -TypeName 'System.Uri' -ArgumentList ($link, $ref)
                    break
                }
            }
        }
    }
}
if (-not $Url) {
    # Could not find a reference to installer.
    $Url = [System.Uri]$FallbackURL
}

# Local installer file.
$InstallerName = Get-URL-Local $Url
$InstallerPath = "$Destination\$InstallerName"
Download-Package $Url $InstallerPath

# Install package.
if (-not $NoInstall) {
    Write-Output "Installing $InstallerName"
    Start-Process -Wait -FilePath $InstallerPath -ArgumentList @("/S")
}

Exit-Script
