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

<#
 .SYNOPSIS

  Set the wallpaper of the current user's session.

 .PARAMETER File

  Specify the image file tu use as background image.
  The predefined wallpapers are in C:\Windows\Web\Wallpaper
 
 .PARAMETER Style

  Specify the wallpaper style.
  Must be one of Fill, Fit, Stretch, Tile, Center, Span

 .EXAMPLE

  Set the scuba diver image on Windows 10 as wallpaper:
  .\set-wallpaper.ps1 C:\Windows\Web\Wallpaper\Theme1\img2.jpg -Style Fill
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$File = "",
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')][string]$Style
)

$WallpaperTile = if ($Style -eq "Tile") {1} else {0}
$WallpaperStyle = switch ($Style) {
    "Fill"    {"10"}
    "Fit"     {"6"}
    "Stretch" {"2"}
    "Tile"    {"0"}
    "Center"  {"0"}
    "Span"    {"22"}
}

[void](New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force)
[void](New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value $WallpaperTile -Force)

Add-Type -TypeDefinition @"
using System; 
using System.Runtime.InteropServices;
public class Params
{
    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
    public static extern int SystemParametersInfo(Int32 uAction, Int32 uParam, String lpvParam, Int32 fuWinIni);
}
"@ 

$SPI_SETDESKWALLPAPER = 0x0014
$UpdateIniFile = 0x01
$SendChangeEvent = 0x02
$fWinIni = $UpdateIniFile -bor $SendChangeEvent

[void][Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $File, $fWinIni)
