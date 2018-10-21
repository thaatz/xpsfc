@echo off
pushd %~dp0 2>NUL
net start wuauserv rem start the windows update service if it isn't already running
wuauclt /detectnow /updatenow >>%tronlog%
ping localhost -n 15 >nul rem wait 15 seconds
echo Windows Update finished >>%tronlog%
echo Windows Update finished