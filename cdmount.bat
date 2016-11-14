@echo off
pushd %~dp0 2>NUL
rem http://wincdemu.sysprogs.org/tutorials/cmdline/
batchmnt winxpsp3.iso

rem check drive letter, return as errorlevel?
batchmnt /check winxpsp3.iso

rem unmount
batchmnt /unmountall
pause