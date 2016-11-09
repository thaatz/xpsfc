@echo off
sfc /scannow
ping localhost -n 1 > nul

rem winlogon.exe if it is there
rem INFO: No tasks running with the specified critera.

:loop
tasklist /fi "WINDOWTITLE eq windows file protection" | find /i "winlogon" > nul
if ERRORLEVEL 1 (
	echo not running?
	echo %errorlevel%
	goto continue
) else (
	echo its still running...
	rem er0
	echo %errorlevel%
	ping localhost -n 5 > nul
	goto loop
)

:continue
echo thing
pause