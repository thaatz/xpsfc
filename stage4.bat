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

:: export registry keys
echo make registry backup
reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" temp.reg >nul
echo.

:: install wincdemu drivers and mount image
echo installing drivers...
PortableWinCDEmu-4.0.exe /install
echo.
echo mounting image...
PortableWinCDEmu-4.0.exe "XP Pro SP3 (32).iso" rem mount
:: delay for four seconds for the image to mount
ping -n 5 localhost >nul
:: close the setup window if autorun opens it
taskkill /im setup.exe /fi "WINDOWTITLE eq Welcome to Microsoft Windows XP" >nul
echo.

:: get drive letter and edit registry
PortableWinCDEmu-4.0.exe /check "XP Pro SP3 (32).iso"
set cddrive=%=exitcodeascii%
REM echo %=exitcodeascii%
echo updating registry
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v SourcePath /d %cddrive%:\ /f >nul
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v ServicePackSourcePath /d %cddrive%:\ /f >nul

:: start the scan process
sfc /scannow
REM ping -n 1 localhost >nul rem delay for one second for the process to show up in tasklist

title xpSFC watcher
echo.
echo DO NOT CLOSE THIS WINDOW
echo its still running...
:: winlogon.exe if it is there
:: INFO: No tasks running with the specified critera.
:: http://stackoverflow.com/questions/8177695/how-to-wait-for-a-process-to-terminate-to-execute-another-process-in-batch-file
:: http://stackoverflow.com/questions/162291/how-to-check-if-a-process-is-running-via-a-batch-script
:loop
tasklist /fi "WINDOWTITLE eq windows file protection" | find /i "winlogon" > nul
if ERRORLEVEL 1 (
	:: this is what happens when it is not running
	rem echo %errorlevel%
	REM cls
	goto continue
) else (
	:: this is what happens when it is running
	REM cls
	rem echo %errorlevel%
	ping localhost -n 5 > nul
	goto loop
)

:continue
:: this is what happens after it runs
:: restore the registry key we exported at the begining
echo.
echo updating registry...
reg import temp.reg >nul
PortableWinCDEmu-4.0.exe /unmountall
rem del temp.reg >nul

chkdsk %SystemDrive%
if /i not %ERRORLEVEL%==0 (
	echo CHKDSK: Errors found on %SystemDrive%.
	fsutil dirty set %SystemDrive%
	REM schtasks /create /tn "long-shutdown" /ru SYSTEM /sc ONSTART /tr "%cd%\task.bat" /RL HIGHEST
	REM %SystemRoot%\System32\shutdown /r /f
) else (
	echo CHKDSK: No errors found on %SystemDrive%.
	REM shutdown /r /f
)

:: send an email on completion
REM SwithMail.exe /s /x "fostatek.xml"
echo.
pause