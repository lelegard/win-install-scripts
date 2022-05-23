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
