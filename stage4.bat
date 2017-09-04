@echo off
:: ----------------------------------------------------------------------------
:: USER SETTINGS - you only need to change settings for windows xp
:: ----------------------------------------------------------------------------
:: SFC mode [iso|folder]
set sfc_mode=folder
:: Windows XP ISO location (no quotes) (set this if you set the sfc mode to iso)
set xp_iso=XP Pro SP3 (32).iso
:: Windows XP i386 folder location (no quotes) (set this if you set the sfc mode to folder) (this is the root folder, not the i386 folder itself)
set xpsource=%~dp0

:: LOGGING
:: for use with tronlite, set this to %tronlog%
set xpsfclog=%tronlog%
REM set xpsfclog=%userprofile%\desktop\xpsfc.log
:: ----------------------------------------------------------------------------
pushd %~dp0 2>NUL

echo starting xpSFC on %date% at %time%>>"%xpsfclog%"

:: detect Windows Version
for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName ^| find "ProductName"') DO set WIN_VER=%%i %%j
for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion ^| FIND "CurrentVersion"') DO set WIN_VER_NUM=%%i

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
:: we need delayed expansion so we can recall variables in the if statement
setlocal enabledelayedexpansion
if %sfc_mode%==iso (
	:: install wincdemu drivers and mount image
	echo installing drivers...
	PortableWinCDEmu-4.0.exe /install
	echo.
	echo mounting image...
	PortableWinCDEmu-4.0.exe "%xp_iso%"
	echo.
	:: we wait two seconds for the image to mount
	ping localhost -n 3 >nul
	:: get drive letter and edit registry. We put a trailing backslash 
	PortableWinCDEmu-4.0.exe /check "%xp_iso%"
	set xpsource=!=exitcodeascii!:\\
	REM echo DEBUG !xpsource!
) else if %sfc_mode%==folder (
	:: if the folder path as a trailing backslash we remove it so it doesnt apppear as an escape character
	rem http://stackoverflow.com/questions/2952401/remove-trailing-slash-from-batch-file-input
	IF %xpsource:~-1%==\ SET xpsource=%xpsource:~0,-1%
) else (
	echo .
	echo Invalid SFC mode detected ^(%sfc_mode%^). Valid options are iso or folder
	pause>nul
	goto eof
)

REM echo DEBUG %xpsource%
REM echo %xpsource:~0,-1%

:: in this loop we wait for 6 seconds to close the autorun window, otherwise we carry on
if %sfc_mode%==iso (
	echo please wait...
	set cnt2=0
	:setup_loop
	tasklist /fi "WINDOWTITLE eq Welcome to Microsoft Windows XP" 2>nul | find /i "SETUP.EXE" >nul
	if ERRORLEVEL 1 (
		:: this is what happens when it is not running
		set /a cnt2+=1
		if "%cnt2%" equ "6" goto :setup_continue
		ping localhost -n 2 >nul
		goto setup_loop
	) else (
		:: this is what happens when it is running
		goto setup_continue
	)
	:setup_continue
	:: this is what happens after it runs
	:: taskill here instead of in the loop just in case its actually open or something
	taskkill /im setup.exe /fi "WINDOWTITLE eq Welcome to Microsoft Windows XP" >nul
)

:: export registry keys
echo make registry backup
reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" temp.reg >nul
REM for /f "tokens=3" %%i IN ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v SourcePath ^| find "SourcePath"') DO set s_path="%%i"
REM for /f "tokens=3*" %%i IN ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v ServicePackSourcePath ^| find "ServicePackSourcePath"') DO set sp_path="%%i"
REM reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" autoruntemp.reg >nul
REM for /f "tokens=3*" %%i IN ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutorun ^| find "NoDriveTypeAutorun"') DO set d_auto=%%i
REM echo %s_path%
REM echo %sp_path%
REM echo %d_auto%
REM pause
echo.
echo updating registry
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /f /v SourcePath /d "%xpsource%" >nul
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /f /v ServicePackSourcePath /d "%xpsource%" >nul
endlocal

:: start the scan process
sfc /scannow

title xpSFC watcher
echo.
echo DO NOT CLOSE THIS WINDOW
echo its still running...
:: winlogon.exe if it is there
:: http://stackoverflow.com/questions/8177695/how-to-wait-for-a-process-to-terminate-to-execute-another-process-in-batch-file
:: http://stackoverflow.com/questions/162291/how-to-check-if-a-process-is-running-via-a-batch-script
:loop
tasklist /fi "WINDOWTITLE eq windows file protection" 2>nul | find /i "winlogon" > nul
if ERRORLEVEL 1 (
	:: this is what happens when it is not running
	goto continue
) else (
	:: this is what happens when it is running
	ping localhost -n 6 > nul
	goto loop
)

:continue
:: this is what happens after it runs
:: restore the registry key we exported at the begining
echo.
echo updating registry...
reg import temp.reg >nul
REM IF %s_path:~-1%==\ SET s_path=%s_path:~0,-1%
REM echo "%s_path%"
REM reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /f /v SourcePath /d "%s_path%" >nul
REM reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /f /v ServicePackSourcePath /d "%sp_path%" >nul
REM reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutorun /t REG_DWORD /d %d_auto% /f >nul

if %sfc_mode%==iso PortableWinCDEmu-4.0.exe /unmountall
echo.
del temp.reg >nul
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
REM dism /online /NoRestart /cleanup-image /scanhealth
REM if not %ERRORLEVEL%==0 (
	REM :: Add /LimitAccess flag to this command to prevent connecting to Windows Update for replacement files
	REM Dism /Online /NoRestart /Cleanup-Image /RestoreHealth
	REM if not %ERRORLEVEL%==0 (
		REM echo DISM: There was an issue with the DISM repair.
	REM ) else (
		REM echo DISM: Image repaired successfully.
	REM )
REM ) else (
	REM echo DISM: No image corruption detected.
REM )

:: use enabledelayedexpansion so that we can find the error level within the nested if statements
setlocal enabledelayedexpansion
:: use restorehealth instead since it scans and repairs whereas scanhealth only scans
:: Add /LimitAccess flag to this command to prevent connecting to Windows Update for replacement files
dism /online /NoRestart /cleanup-image /restorehealth
if not %ERRORLEVEL%==0 (
	echo DISM: There was an issue with the DISM repair. Starting DISM component cleanup.>>"%xpsfclog%"
	echo DISM: There was an issue with the DISM repair. Starting DISM component cleanup.
	:: http://www.thewindowsclub.com/dism-fails-source-files-could-not-be-found
	:: if the error was "DISM fails The source files could not be found", sometimes component cleanup can help fix the issue
	dism /online /Cleanup-Image /StartComponentCleanup
	dism /online /NoRestart /cleanup-image /restorehealth
	REM echo !errorlevel!
	if not !ERRORLEVEL!==0 (
		echo DISM: DISM repair failed again. It is recommended that you visit the following link and try running DISM manually to resolve.>>"%xpsfclog%"
		echo http://www.thewindowsclub.com/dism-fails-source-files-could-not-be-found>>"%xpsfclog%"
		echo DISM: DISM repair failed again. It is recommended that you visit the following link and try running DISM manually to resolve.
		echo http://www.thewindowsclub.com/dism-fails-source-files-could-not-be-found
	) else (
		echo DISM: Sucessful.>>"%xpsfclog%"
		echo DISM: Sucessful.
	)
) else (
	echo DISM: Sucessful.>>"%xpsfclog%"
	echo DISM: Sucessful.
)
REM debug pause
sfc /scannow
if not %ERRORLEVEL%==0 (
	echo SFC: There was an issue with the SFC repair.>>"%xpsfclog%"
	echo SFC: There was an issue with the SFC repair.
) else (
	echo SFC: SFC completed sucessfully.>>"%xpsfclog%"
	echo SFC: SFC completed sucessfully.
)
goto checkdisk

:checkdisk
:: check disk
:: set the drive as dirty and then we will run the check when we restart
echo.
fsutil dirty set %SystemDrive%
:: chkdsk %SystemDrive%
:: if /i not %ERRORLEVEL%==0 (
:: 	echo CHKDSK: Errors found on %SystemDrive%.
:: 	fsutil dirty set %SystemDrive%
:: 	REM schtasks /create /tn "long-shutdown" /ru SYSTEM /sc ONSTART /tr "%cd%\task.bat" /RL HIGHEST
:: 	REM %SystemRoot%\System32\shutdown /r /f
:: ) else (
:: 	echo CHKDSK: No errors found on %SystemDrive%.
:: 	REM shutdown /r /f
:: )

echo.
REM pause