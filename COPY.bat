@ECHO OFF

echo !!! YOU FORGOT TO EDIT COPY.bat !!!

REM vpk.exe is included in Portal 2 Authoring Tools, or you can use your own, IDC
SET "dest=%ProgramFiles(x86)%\Steam\steamapps\sourcemods\Portal 2 Speedrun Mod"
SET "vpk=%ProgramFiles(x86)%\Steam\steamapps\common\Portal 2\bin\vpk.exe"

REM MKDIR "%dest%"
REM xcopy /E /V /Y /I "cfg"          "%dest%\cfg"
REM xcopy /E /V /Y /I "maps"         "%dest%\maps"
REM xcopy /E /V /Y /I "resource"     "%dest%\resource"
REM xcopy /E /V /Y /I "scripts"      "%dest%\scripts"
REM xcopy /E /V /Y /I "media"        "%dest%\media"
REM copy /Y           "gameinfo.txt" "%dest%\gameinfo.txt"

REM "%vpk%" pak01_dir
REM copy /Y "pak01_dir.vpk" "%dest%\pak01_dir.vpk"
REM DEL pak01_dir.vpk

REM copy /Y "smsm\bin\smsm.dll" "%dest%\smsm.dll"
