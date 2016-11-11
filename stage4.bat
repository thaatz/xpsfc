@echo off
sfc /scannow
ping localhost -n 1 > nul

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
echo thing
pause