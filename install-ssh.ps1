#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#  Install and configure the integrated OpenSSH client and server on Windows.
#  On Windows 10 Home, this is not done by default.
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

Write-Output "==== Windows integrated OpenSSH installation procedure"

. (Join-Path $PSScriptRoot install-common.ps1)

if ($NoInstall) {
    Write-Output "Builtin Windows package, nothing to do"
}
elseif (-not $IsAdmin) {
    # Execution for non-admin user, recurse for admin part.
    Recurse-Admin
}
else {
    # Install OpenSSH client and server.
    Install-Windows-Capability "OpenSSH.Client"
    Install-Windows-Capability "OpenSSH.Server"

    # Start and enable the SSH server service.
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'

    # Check and create firewall rule for SSH server.
    $rule = (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction Ignore)
    if ($rule -eq $null) {
        Write-Output "Adding firewall rule for SSH server ..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    }

    # Set PowerShell as default login shell for SSH sessions.
    Write-Output "Setting PowerShell as default shell for SSH sessions ..."
    [void](New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force)

    # Make sure that authorized_keys files are correctly configured.
    Create-File-Set-Owner "${env:ProgramData}\ssh\administrators_authorized_keys" @("Administrators", "SYSTEM")
    Create-File-Set-Owner "${env:HOMEDRIVE}${env:HOMEPATH}\.ssh\authorized_keys"  @($CurrentUserName)
}

Exit-Script
