#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Download and install OpenSSL for Windows.
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

Write-Output "==== OpenSSL download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Download and install the two MSI packages, 32 and 64 bits.
Install-Standard-Msi "http://slproweb.com/products/Win32OpenSSL.html" "*/Win64OpenSSL-*.msi"
Install-Standard-Msi "http://slproweb.com/products/Win32OpenSSL.html" "*/Win32OpenSSL-*.msi"
Exit-Script
