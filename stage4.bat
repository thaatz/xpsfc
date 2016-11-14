@echo off
pushd %~dp0 2>NUL

for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName ^| find "ProductName"') DO set WIN_VER=%%i %%j
if not "%WIN_VER%"=="Microsoft Windows XP" (
	echo.
	echo only Microsoft Windows XP is supported. This is %win_ver%.
	echo.
	pause
	exit
)

rem export registry keys
echo make registry backup
reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" temp.reg >nul
echo.

rem install wincdemu drivers and mount image
echo installing drivers...
PortableWinCDEmu-4.0.exe /install
echo.
echo mounting image...
PortableWinCDEmu-4.0.exe "XP Pro SP3 (32).iso" rem mount
rem delay for four seconds for the image to mount
ping -n 5 localhost >nul
echo.

rem get drive letter and edit registry
REM echo check drive assignment...
PortableWinCDEmu-4.0.exe /check "XP Pro SP3 (32).iso"
set cddrive=%=exitcodeascii%
REM echo %=exitcodeascii%
echo updating registry
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v SourcePath /d %cddrive%:\ /f >nul
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v ServicePackSourcePath /d %cddrive%:\ /f >nul
REM pause

rem start the scan process
sfc /scannow
REM ping -n 1 localhost >nul rem delay for one second for the process to show up in tasklist

title xpSFC watcher

rem winlogon.exe if it is there
rem INFO: No tasks running with the specified critera.

:loop
tasklist /fi "WINDOWTITLE eq windows file protection" | find /i "winlogon" > nul
if ERRORLEVEL 1 (
	rem this is what happens when it is not running
	rem echo not running?
	rem echo %errorlevel%
	cls
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
echo updating registry
reg import temp.reg >nul
PortableWinCDEmu-4.0.exe /unmountall

rem send an email on completion
REM SwithMail.exe /s /x "fostatek.xml"
echo.
pause