@echo off
pushd %~dp0 2>NUL
rem need to install drivers first
PortableWinCDEmu-4.0.exe /install

rem http://wincdemu.sysprogs.org/tutorials/cmdline/
PortableWinCDEmu-4.0.exe winxpsp3.iso

rem check drive letter, return as errorlevel
PortableWinCDEmu-4.0.exe /check winxpsp3.iso
rem http://www.dostips.com/forum/viewtopic.php?t=2610
echo %=exitcodeascii%

rem unmount
PortableWinCDEmu-4.0.exe /unmountall

rem uninstall drivers too?
rem dont uninstall because sometimes it can fuck up if we didnt unmount
pause