@echo off
pushd %~dp0 2>NUL

for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName ^| find "ProductName"') DO set WIN_VER=%%i %%j
if not "%WIN_VER:~0,19%"=="Windows XP" (
	echo.
	echo only Windows XP is supported. This is %win_ver%.
	echo.
	pause
	exit
)

rem export registry keys
reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" temp.reg

rem install wincdemu drivers and mount image
PortableWinCDEmu-4.0.exe /install
PortableWinCDEmu-4.0.exe winxpsp3.iso rem mount

rem get drive letter and edit registry
PortableWinCDEmu-4.0.exe /check winxpsp3.iso
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v SourcePath /d %=exitcodeascii%: /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v ServicePackSourcePath /d %=exitcodeascii%: /f

rem start the scan process
sfc /scannow
ping localhost -n 1 > nul rem delay for one second for the process to show up in tasklist

title xpSFC watcher

rem winlogon.exe if it is there
rem INFO: No tasks running with the specified critera.

:loop
tasklist /fi "WINDOWTITLE eq windows file protection" | find /i "winlogon" > nul
if ERRORLEVEL 1 (
	rem this is what happens when it is not running
	rem echo not running?
	rem echo %errorlevel%
	goto continue
) else (
	rem this is what happens when it is running
	cls
	echo.
	echo DO NOT CLOSE THIS WINDOW
	echo its still running...
	rem er0
	rem echo %errorlevel%
	ping localhost -n 5 > nul
	goto loop
)

:continue
rem this is what happens after it runs
rem restore the registry key we exported at the begining
reg import temp.reg
PortableWinCDEmu-4.0.exe /unmountall
pause rem debug pause