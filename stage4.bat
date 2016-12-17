@echo off
:: Windows XP ISO location
set xp_iso=XP Pro SP3 (32).iso

pushd %~dp0 2>NUL

:: detect Windows Version
for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName ^| find "ProductName"') DO set WIN_VER=%%i %%j
for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion ^| FIND "CurrentVersion"') DO set WIN_VER_NUM=%%i
REM if not "%WIN_VER%"=="Microsoft Windows XP" (
	REM echo.
	REM echo only Microsoft Windows XP is supported. This is %win_ver%.
	REM echo.
	REM pause
	REM exit
REM )

:: Windows XP
if %WIN_VER_NUM% equ 5.1 goto windowsxp
:: Windows 7 and below
if %WIN_VER_NUM% leq 6.1 goto legacy
:: Windows 8 and above
if %WIN_VER_NUM% geq 6.2 goto win8

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: WINDOWS XP
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:windowsxp
:: export registry keys
echo make registry backup
reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" temp.reg >nul
echo.

:: install wincdemu drivers and mount image
echo installing drivers...
PortableWinCDEmu-4.0.exe /install
echo.
echo mounting image...
PortableWinCDEmu-4.0.exe "%xp_iso%" rem mount
:: delay for four seconds for the image to mount
ping -n 5 localhost >nul
:: close the setup window if autorun opens it
taskkill /im setup.exe /fi "WINDOWTITLE eq Welcome to Microsoft Windows XP" >nul
echo.

:: get drive letter and edit registry
PortableWinCDEmu-4.0.exe /check "%xp_iso%"
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
goto checkdisk

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: WINDOWS VISTA and WINDOWS 7
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:legacy
sfc /scannow
goto checkdisk

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: WINDOWS 8+
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:win8
dism /online /NoRestart /cleanup-image /scanhealth
if not %ERRORLEVEL%==0 (
	:: Add /LimitAccess flag to this command to prevent connecting to Windows Update for replacement files
	Dism /Online /NoRestart /Cleanup-Image /RestoreHealth
	if not %ERRORLEVEL%==0 (
		echo DISM: There was an issue with the DISM repair.
	) else (
		echo DISM: Image repaired successfully.
	)
) else (
	echo DISM: No image corruption detected.
)

sfc /scannow
if not %ERRORLEVEL%==0 (
	echo SFC: There was an issue with the SFC repair.
) else (
	echo SFC: SFC completed sucessfully.
)

goto checkdisk

:checkdisk
:: check disk
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