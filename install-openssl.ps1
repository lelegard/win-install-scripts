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

# A bit of history: Where to load OpenSSL binaries from?
#
# The packages are built by "slproweb". The binaries are downloadable from
# their Web page at: http://slproweb.com/products/Win32OpenSSL.html
#
# Initially, the HTML for this page was built on server-side. This script
# grabbed the URL content, parse the HTML and extracted the URL of the
# binaries for the latest OpenSSL packages from the "href" of the links.
#
# At some point in 2024, the site changed policy. The Web page is no longer
# built on server-side, but on client-side. The downloaded HTML contains some
# JavaScript which dynamically builds the URL of the binaries for the latest
# OpenSSL binaries. The previous method now finds no valid package URL from
# the downloaded page (a full browser is needed to execute the JavaScript).
# The JavaScript downloads a JSON file which contains all references to
# the OpenSSL binaries. This script now uses the same method: download that
# JSON file and parse it.

$response = Get-HTML "https://github.com/slproweb/opensslhashes/raw/master/win32_openssl_hashes.json"
$config = ConvertFrom-Json $response.Content

# Download and install MSI packages for 32 and 64 bit.
foreach ($bits in @(32, 64)) {

    # Get the URL of the MSI installer from the JSON config.
    $Url = $config.files | Get-Member | ForEach-Object {
        $name = $_.name
        $info = $config.files.$($_.name)
        if (-not $info.light -and $info.installer -like "msi" -and $info.bits -eq $bits -and $info.arch -like "intel") {
            $info.url
        }
    } | Select-Object -Last 1

    if (-not $Url) {
        Exit-Script "#### No MSI installer found for Win${bits}"
    }
    else {
        Install-Msi $Url
    }
}

Exit-Script
