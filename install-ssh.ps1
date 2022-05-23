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

  Install and configure the integrated OpenSSH client and server on Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$NoPause = $false,
    # Internal parameters for recursion as administrator:
    [switch]$Install = $false
)

Write-Output "==== Windows integrated OpenSSH installation procedure"

$UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# A function to exit this script.
function Exit-Script([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Output "ERROR: $Message"
        $Code = 1
    }
    if (-not $NoPause) {
        pause
    }
    exit $Code
}

# Make sure that a file exists, at least empty.
function Enforce-File([string]$path)
{
    $dir = (Split-Path $path -Parent)
    if (-not (Test-Path $dir -PathType Container)) {
        Write-Output "Creating directory $dir ..."
        [void](New-Item $dir -ItemType Directory -Force)
    }
    if (-not (Test-Path $path -PathType Leaf)) {
        Write-Output "Creating file $path ..."
        [void](New-Item $path -ItemType File -Force)
    }
}

# If not administrator, recurse.
if (-not $IsAdmin) {
    # Execution for non-admin user, recurse for admin part.
    Write-Output "Must be administrator to continue, trying to restart as administrator ..."
    $cmd = "& '" + $PSCommandPath + "' -Install"
    if ($NoPause) {
        $cmd += " -NoPause"
    }
    Start-Process -Wait -Verb runas -FilePath PowerShell.exe -ArgumentList @("-ExecutionPolicy", "RemoteSigned", "-Command", $cmd)
}
else {
    # Executed as administrator.

    # Install OpenSSH client and server.
    foreach ($name in @("OpenSSH.Client", "OpenSSH.Server")) {
        $product = (Get-WindowsCapability -Online | Where-Object Name -like "${name}*" | Select-Object -First 1)
        if ($product -eq $null) {
            Write-Output "$name not found"
        }
        elseif ($product.State -like "Installed") {
            Write-Output "$($product.Name) already installed"
        }
        else {
            Write-Output "Installing $($product.Name) ..."
            [void](Add-WindowsCapability -Online -Name $product.Name)
        }
    }

    # Start and enable the SSH server service.
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'

    # Check and create firewall rule for SSH server.
    $rule =(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP")
    if ($rule -eq $null) {
        Write-Output "Adding firewall rule for SSH server ..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    }

    # Set PowerShell as default login shell for SSH sessions.
    Write-Output "Setting PowerShell as default shell for SSH sessions ..."
    [void](New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force)

    # Make sure that administrators_authorized_keys file exists.
    $akeys = "${env:ProgramData}\ssh\administrators_authorized_keys"
    Enforce-File $akeys

    Write-Output "Adjusting security of $akeys ..."
    $acl = Get-Acl $akeys
    $acl.SetAccessRuleProtection($true, $false)
    $rule1 = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators", "FullControl", "Allow")
    $rule2 = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM", "FullControl", "Allow")
    $acl.SetAccessRule($rule1)
    $acl.SetAccessRule($rule2)
    $acl | Set-Acl

    # Make sure that the authorized_keys file exists for the current user.
    $akeys = "${env:HOMEDRIVE}${env:HOMEPATH}\.ssh\authorized_keys"
    Enforce-File $akeys

    Write-Output "Adjusting security of $akeys ..."
    $acl = Get-Acl $akeys
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object system.security.accesscontrol.filesystemaccessrule($UserName, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $acl | Set-Acl
}

Exit-Script
