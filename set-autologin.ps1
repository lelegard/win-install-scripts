#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
#
#-----------------------------------------------------------------------------

<#
 .SYNOPSIS

  Set automatic login on Windows.
  Must be run from a PowerShell window with administrator privileges.
    
 .PARAMETER User

  Specify the user name to automatically login.
  By default, use the current user.

 .PARAMETER Password

  Specify the password of the user.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$User = "",
    [parameter(mandatory=$true)][string]$Password
)

# Current user by default.
if (-not $User) {
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

# Enable autologin.
$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $RegistryPath 'AutoAdminLogon' -Value "1" -Type String 
Set-ItemProperty $RegistryPath 'DefaultUsername' -Value "$User" -type String 
Set-ItemProperty $RegistryPath 'DefaultPassword' -Value "$Password" -type String
