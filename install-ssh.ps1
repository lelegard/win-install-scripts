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
