#-----------------------------------------------------------------------------
#
#  Copyright (c) 2022, Thierry Lelegard
#  BSD-2-Clause license, see LICENSE.txt file
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
