@echo off
rem http://www.dostips.com/forum/viewtopic.php?t=772
for %%a in (d e f g h i j k) do (
   if exist %%a:\setup.exe (
      set cddrive=%%a
      goto :continue
   )
)
:continue
if not defined cddrive echo No cd drive found.&&goto :eof
echo cd drive letter = %cddrive%
pause

rem this part is nircmd changing the reg keys
rem i need to figure out out to make a backup of the registry keys first
reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" temp.reg

rem http://nircmd.nirsoft.net/regsetval.html
REM nircmd regsetval sz "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" SourcePath
REM ServicePackSourcePath

reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v SourcePath /d %cddrive%: /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v ServicePackSourcePath /d %cddrive%: /f