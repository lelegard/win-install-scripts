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
#  Download and install SysInternals tools suite.
#  See parameters documentation in install-common.ps1.
#
#  The SysInternals suite is an unorganized archive of .exe and .chm files.
#  Some .exe are command line tools, some are GUI's. This installation script
#  - copies all files in C:\Program Files\SysInternals
#  - adds this directory to the system Path (some command line tools)
#  - creates shortcuts in the start menu for GUI's and help file
#  - preset "license accepted" for all known tools
#
#-----------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "",
    [switch]$ForceDownload = $false,
    [switch]$GitHubActions = $false,
    [switch]$NoInstall = $false,
    [switch]$NoPause = $false,
    [string]$AdminStuff = ""
)

# There is no version in the URL, always use the same URL.
$SysInternalsUrl = "https://download.sysinternals.com/files/SysinternalsSuite.zip"

# List of SysInternal tools.
$SysInternalsTools = @(
    @{Name="Access Check";                      File="accesschk";     GUI=$false; Registry="AccessChk"},
    @{Name="Access Enum";                       File="AccessEnum";    GUI=$true;  Registry="AccessEnum"},
    @{Name="Active Directory Explorer";         File="ADExplorer";    GUI=$true;  Registry="Active Directory Explorer"},
    @{Name="Active Directory Insigth";          File="ADInsight";     GUI=$true;  Registry="ADInsight"},
    @{Name="Active Directory Restore";          File="adrestore";     GUI=$false; Registry="AdRestore"},
    @{Name="Auto Logon";                        File="Autologon";     GUI=$true;  Registry="Autologon"},
    @{Name="Autoruns";                          File="Autoruns";      GUI=$true;  Registry="Autoruns"},
    @{Name="Autoruns (command line)";           File="autorunsc";     GUI=$false; Registry="Autoruns"},
    @{Name="BGInfo";                            File="Bginfo";        GUI=$true;  Registry="BGInfo"},
    @{Name="Cache Set";                         File="Cacheset";      GUI=$true;  Registry="CacheSet"},
    @{Name="Clock Resolution";                  File="Clockres";      GUI=$false; Registry="ClockRes"},
    @{Name="Contig (defragment)";               File="Contig";        GUI=$false; Registry="Contig"},
    @{Name="Core Info";                         File="Coreinfo";      GUI=$false; Registry="Coreinfo"},
    @{Name="CPU Stress";                        File="CPUSTRES";      GUI=$true;  Registry="CPUSTRES"},
    @{Name="Ctrl2cap";                          File="ctrl2cap";      GUI=$false; Registry="Ctrl2cap"},
    @{Name="Debug Viewer";                      File="Dbgview";       GUI=$true;  Registry=""},
    @{Name="Desktops";                          File="Desktops";      GUI=$true;  Registry="Desktops"},
    @{Name="Disk to VHD";                       File="disk2vhd";      GUI=$true;  Registry="Disk2Vhd"},
    @{Name="Disk Extents";                      File="diskext";       GUI=$false; Registry="DiskExt"},
    @{Name="Disk Monitor";                      File="Diskmon";       GUI=$true;  Registry="Diskmon"},
    @{Name="Disk Viewer";                       File="DiskView";      GUI=$true;  Registry="DiskView"},
    @{Name="Disk Usage";                        File="du";            GUI=$false; Registry="Du"},
    @{Name="EFS Dump";                          File="efsdump";       GUI=$false; Registry="EFSDump"},
    @{Name="Find Links";                        File="FindLinks";     GUI=$false; Registry="FindLinks"},
    @{Name="List Handles";                      File="handle";        GUI=$false; Registry="Handle"},
    @{Name="Hex to Dec";                        File="hex2dec";       GUI=$false; Registry="Hex2Dec"},
    @{Name="Junction";                          File="junction";      GUI=$false; Registry="Junction"},
    @{Name="Logical Disk Manager Dump";         File="ldmdump";       GUI=$false; Registry="LdmDump"},
    @{Name="List DLL's";                        File="Listdlls";      GUI=$false; Registry="ListDLLs"},
    @{Name="Live KD";                           File="livekd";        GUI=$false; Registry="LiveKd"},
    @{Name="Load Order";                        File="LoadOrd";       GUI=$true;  Registry="LoadOrder"},
    @{Name="Load Order (command line)";         File="LoadOrdC";      GUI=$false; Registry="LoadOrder"},
    @{Name="Logon Sessions";                    File="logonsessions"; GUI=$false; Registry="LogonSessions"},
    @{Name="Move File";                         File="movefile";      GUI=$false; Registry="Movefile"},
    @{Name="Not My Fault";                      File="notmyfault";    GUI=$true;  Registry="NotMyFault"},
    @{Name="Not My Fault (command line)";       File="notmyfaultc";   GUI=$false; Registry="NotMyFault"},
    @{Name="NTFS Info";                         File="ntfsinfo";      GUI=$false; Registry="NTFSInfo"},
    @{Name="Pending Moves";                     File="pendmoves";     GUI=$false; Registry="PendMove"},
    @{Name="List Pipes";                        File="pipelist";      GUI=$false; Registry="PipeList"},
    @{Name="Port Monitor";                      File="portmon";       GUI=$true;  Registry="Portmon"},
    @{Name="Process Dump";                      File="procdump";      GUI=$false; Registry="ProcDump"},
    @{Name="Process Explorer";                  File="procexp";       GUI=$true;  Registry="Process Explorer"},
    @{Name="Process Monitor";                   File="Procmon";       GUI=$true;  Registry="Process Monitor"},
    @{Name="PS Remote Execute";                 File="psexec";        GUI=$false; Registry="PsExec"},
    @{Name="PS Remote List Files";              File="psfile";        GUI=$false; Registry="PsFile"},
    @{Name="SID to Name";                       File="PsGetsid";      GUI=$false; Registry="PsGetSid"},
    @{Name="PS Information";                    File="PsInfo";        GUI=$false; Registry="PsInfo"},
    @{Name="PS Kill Process";                   File="pskill";        GUI=$false; Registry="PsKill"},
    @{Name="PS List Processes";                 File="pslist";        GUI=$false; Registry="PsList"},
    @{Name="PS Logged On";                      File="PsLoggedon";    GUI=$false; Registry="PsLoggedon"},
    @{Name="PS Event Log Viewer";               File="psloglist";     GUI=$false; Registry="PsLoglist"},
    @{Name="PS Change Password";                File="pspasswd";      GUI=$false; Registry="PsPasswd"},
    @{Name="PS Ping";                           File="psping";        GUI=$false; Registry="PsPing"},
    @{Name="PS Service Configuration";          File="PsService";     GUI=$false; Registry="PsService"},
    @{Name="PS Shutdown";                       File="psshutdown";    GUI=$false; Registry="PsShutdown"},
    @{Name="PS Suspend and Resume";             File="pssuspend";     GUI=$false; Registry="PsSuspend"},
    @{Name="PS Tools";                          File="Pstools";       GUI=$false; Registry=""},
    @{Name="RAM Map";                           File="RAMMap";        GUI=$true;  Registry="RamMap"},
    @{Name="Remote Desktop Connection Manager"; File="RDCMan";        GUI=$true;  Registry=""},
    @{Name="Delete registry Keys with Nulls";   File="RegDelNull";    GUI=$false; Registry="RegDelNull"},
    @{Name="Registry Jump";                     File="regjump";       GUI=$false; Registry="Regjump"},
    @{Name="Registry Usage";                    File="ru";            GUI=$false; Registry="Regsize"},
    @{Name="Secure File Delete";                File="sdelete";       GUI=$false; Registry="SDelete"},
    @{Name="Share Enum";                        File="ShareEnum";     GUI=$true;  Registry="Share Enum"},
    @{Name="Shell Run As";                      File="ShellRunas";    GUI=$false; Registry="ShellRunas - Sysinternals: www.sysinternals.com"},
    @{Name="File Signature View";               File="sigcheck";      GUI=$false; Registry="sigcheck"},
    @{Name="Reveal NTFS alternate streams";     File="streams";       GUI=$false; Registry="Streams"},
    @{Name="Search for Strings";                File="strings";       GUI=$false; Registry="Strings"},
    @{Name="Sync Cache to Disk";                File="sync";          GUI=$false; Registry="Sync"},
    @{Name="System Activity Monitor";           File="Sysmon";        GUI=$false; Registry=""},
    @{Name="TCP View (command line)";           File="tcpvcon";       GUI=$false; Registry="TCPView"},
    @{Name="TCP View";                          File="tcpview";       GUI=$true;  Registry="TCPView"},
    @{Name="Test Windows Limits";               File="Testlimit";     GUI=$false; Registry=""},
    @{Name="VM Map";                            File="vmmap";         GUI=$true;  Registry="VMMap"},
    @{Name="Set Disk Volume Id";                File="Volumeid";      GUI=$false; Registry="VolumeID"},
    @{Name="Domain information lookup";         File="whois";         GUI=$false; Registry="Whois"},
    @{Name="List Windows Objects";              File="Winobj";        GUI=$true;  Registry="WinObj"},
    @{Name="Zom It";                            File="ZoomIt";        GUI=$true;  Registry="ZoomIt"}
)

Write-Output "==== SysInternals download and installation procedure"

. "$PSScriptRoot\install-common.ps1"

# Debug tool: display all SysInternals tools for which the license was accepted
function Display-SysInternalsEulaAccepted()
{
    Get-ChildItem HKCU:\Software\SysInternals -Recurse -Depth 0 |
        Where-Object {$_.Property -contains "EulaAccepted"} |
        ForEach-Object {Split-Path -Leaf $_.Name}
}

# Debug tool: clear all accepted license for SysInternals tools
function Clear-SysInternalsEulaAccepted()
{
    Get-ChildItem HKCU:\Software\SysInternals -Recurse -Depth 0 |
        Where-Object {$_.Property -contains "EulaAccepted"} |
        ForEach-Object {Remove-ItemProperty -Path "HKCU:\Software\SysInternals\$(Split-Path -Leaf $_.Name)" -Name "EulaAccepted"}
}

# Actions to execute in admin mode.
function Admin-Stuff([string]$Dir)
{
    # Install files.
    $TargetDir = [Environment]::GetFolderPath('ProgramFiles') + "\SysInternals"
    Write-Output "Installing $Dir into $TargetDir"
    Remove-Item $TargetDir -Force -Recurse -ErrorAction Ignore
    Move-Item $Dir $TargetDir

    # Add SysInternals to the system Path.
    Add-Directory-To-Path $TargetDir

    # Install shortcuts in the start menu for GUI applications.
    $Is64 = [Environment]::Is64BitOperatingSystem
    foreach ($tool in $SysInternalsTools) {
        $file = $tool.File
        $name = $tool.Name
        $exe = "$file.exe"
        if ($Is64 -and (Test-Path "$TargetDir\${file}64.exe")) {
            $exe = "${file}64.exe"
        }
        if ($tool.GUI) {
            Add-Start-Menu-Entry "$name" "$TargetDir\$exe" "SysInternals" $true
        }
        Add-Start-Menu-Entry "$name Help" "$TargetDir\$file.chm" "SysInternals" $true
    }
}

if ($AdminStuff -ne "") {
    # Process recursion in admin mode.
    Admin-Stuff $AdminStuff 
}
else {
    # Direct invocation.
    $InstallerName = Get-URL-Local $SysInternalsUrl
    $InstallerPath = "$Destination\$InstallerName"
    Download-Package $SysInternalsUrl $InstallerPath

    if (-not $NoInstall) {
        Write-Output "Expanding $InstallerName"
        $InstallerDir = "$Destination\$((Get-Item $InstallerPath).BaseName)"
        Remove-Item $InstallerDir -Force -Recurse -ErrorAction Ignore
        [void](New-Item $InstallerDir -ItemType Directory)
        Expand-Archive $InstallerPath -DestinationPath $InstallerDir

        if ($IsAdmin) {
            Admin-Stuff $InstallerDir
        }
        else {
            Recurse-Admin "-AdminStuff `"$InstallerDir`""
        }
        Propagate-Environment "Path"

        # Force "license accepted" on all known tools for current user.
        foreach ($tool in $SysInternalsTools) {
            if ($tool.Registry -ne "") {
                $reg = "HKCU:\Software\SysInternals\" + $tool.Registry
                [void](New-Item -Path $reg -Force -ErrorAction Ignore)
                [void](New-ItemProperty -Path $reg -Name "EulaAccepted" -Value 1 -PropertyType DWORD)
            }
        }
    }
}

Exit-Script
