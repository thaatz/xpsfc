@echo off
pushd %~dp0 2>NUL
rem http://www.nirsoft.net/utils/nircmd.html
nircmd.exe regedit "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup"
pause