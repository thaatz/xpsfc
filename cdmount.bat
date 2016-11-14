@echo off
pushd %~dp0 2>NUL
rem need to install drivers first
batchmnt /install

rem http://wincdemu.sysprogs.org/tutorials/cmdline/
batchmnt winxpsp3.iso

rem check drive letter, return as errorlevel
batchmnt /check winxpsp3.iso
rem http://www.dostips.com/forum/viewtopic.php?t=2610
echo %=exitcodeascii%

rem unmount
batchmnt /unmountall

rem uninstall drivers too?
rem dont uninstall because sometimes it can fuck up if we didnt unmount
pause