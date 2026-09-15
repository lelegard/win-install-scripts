#-----------------------------------------------------------------------------
#
#  Copyright (c) 2025, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Install WinGet package manager, if not already installed.
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

Write-Output "==== WinGet download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Install WinGet only when not found.
if (-not (Search-Command winget)) {
    if (-not $IsAdmin) {
        # Execution for non-admin user, recurse for admin part.
        Recurse-Admin
    }
    else {
        # See https://learn.microsoft.com/en-us/windows/package-manager/winget/
        # We noticed intermittent failures, retry up to 3 times.
        $retries = 3
        Write-Output "PowerShell version: $($PSVersionTable.PSVersion.ToString())"
        while (-not (Search-Command winget) -and $retries -gt 0) {
            $retries--
            if ($PSVersionTable.PSVersion.Major -lt 7) {
                Write-Output "Installing NuGet ..."
                Install-PackageProvider -Name "NuGet" -Force -ForceBootstrap
            }
            Write-Output "Installing Microsoft.WinGet.Client PowerShell module ..."
            Install-Module -Name Microsoft.WinGet.Client -AcceptLicense -Force -AllowClobber -Repository PSGallery
            Import-Module -Name Microsoft.WinGet.Client
            Write-Output "Installing WinGet ..."
            # try { Repair-WinGetPackageManager -AllUsers } catch {}
            try {
                Repair-WinGetPackageManager -AllUsers -Verbose
            } catch {
                Write-Host "::group::Repair-WinGetPackageManager failure details"
                Get-Module Microsoft.WinGet.Client | Select-Object Name, Version
                $_.Exception | Format-List * -Force
                $_.Exception.InnerException | Format-List * -Force
                Write-Host "::endgroup::"
                throw
            }
            # We noticed some spurious asynchronous activity after installation.
            # Let this background activity complete.
            $timeout = 5
            while (-not (Search-Command winget) -and $timeout -gt 0) {
                $timeout--
                Write-Output "WinGet not found, retrying in two seconds..."
                Start-Sleep -Seconds 2
            }
        }
    }
}

Write-Output "WinGet: $(Search-Command winget)"
Exit-Script
