#-----------------------------------------------------------------------------
#
#  Copyright (c) 2021, Thierry Lelegard
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

<#
 .SYNOPSIS

  Download and install Notepad++.

 .PARAMETER Destination

  Specify a local directory where the package will be downloaded.
  By default, use the downloads folder for the current user.

 .PARAMETER ForceDownload

  Force a download even if the package is already downloaded.

 .PARAMETER GitHubActions

  When used in a GitHub Action workflow, make sure that the required
  environment variables are propagated to subsequent jobs.

 .PARAMETER NoInstall

  Do not install the package. By default, the package is installed.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "",
    [switch]$ForceDownload = $false,
    [switch]$GitHubActions = $false,
    [switch]$NoInstall = $false,
    [switch]$NoPause = $false
)

Write-Output "==== Notepad++ download and installation procedure"

# Web page for the latest releases.
$ReleasePage = "https://notepad-plus-plus.org/downloads/"
$FallbackURL = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.2.1/npp.8.2.1.Installer.x64.exe"

# A function to exit this script.
function Exit-Script([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Host "ERROR: $Message"
        $Code = 1
    }
    if (-not $NoPause) {
        pause
    }
    exit $Code
}

# Without this, Invoke-WebRequest is awfully slow.
$ProgressPreference = 'SilentlyContinue'

# This function downloads a Web page. Return $null on error.
function Get-WebPage([string]$url = "")
{
    $status = 0
    $message = ""
    try {
        $response = Invoke-WebRequest -UseBasicParsing -UserAgent Download -Uri $url
        $status = [int] [Math]::Floor($response.StatusCode / 100)
    }
    catch {
        $message = $_.Exception.Message
    }
    if ($status -ne 1 -and $status -ne 2) {
        # Error fetching download page.
        if ($message -eq "" -and (Test-Path variable:response)) {
            Write-Output "Status code $($response.StatusCode), $($response.StatusDescription)"
        }
        else {
            Write-Output "#### Error accessing ${url}: $message"
        }
        return $null
    }
    else {
        return $response
    }
}

# Get the HTML page for downloads.
$Url = $null
$response = Get-WebPage $ReleasePage
if ($response -ne $null) {
    foreach ($link in $response.Links.href) {
        # Build the absolute URL's from base URL (the download page) and href links.
        $link = New-Object -TypeName 'System.Uri' -ArgumentList ([System.Uri]$ReleasePage, $link)
        # Is this a link to a "vNNN" subdirectory?
        if ($link.ToString() -match "${ReleasePage}v[\.0-9]*/") {
            # Locate installer in that subdirectory.
            $page = Get-WebPage $link
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

# Create the directory for external products or use default.
if (-not $Destination) {
    $Destination = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
}
else {
    [void](New-Item -Path $Destination -ItemType Directory -Force)
}

# Local installer file.
$InstallerName = (Split-Path -Leaf $Url.LocalPath)
$InstallerPath = "$Destination\$InstallerName"

# Download installer
if (-not $ForceDownload -and (Test-Path $InstallerPath)) {
    Write-Output "$InstallerName already downloaded, use -ForceDownload to download again"
}
else {
    Write-Output "Downloading $Url ..."
    Invoke-WebRequest -UseBasicParsing -UserAgent Download -Uri $Url -OutFile $InstallerPath
    if (-not (Test-Path $InstallerPath)) {
        Exit-Script "$Url download failed"
    }
}

# Install package.
if (-not $NoInstall) {
    Write-Output "Installing $InstallerName"
    Start-Process -FilePath $InstallerPath -ArgumentList @("/S") -Wait
}

Exit-Script
