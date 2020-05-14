@ECHO OFF

SET "name=Portal 2 Speedrun Mod"
SET "dest=C:\Program Files (x86)\Steam\steamapps\sourcemods\%name%"
SET "vpk=C:\Users\Betsruner\Documents\Search\vpk.exe"

ECHO.
ECHO ====== Attempting to create directory at %dest%... ======
MKDIR "%dest%"

ECHO.
ECHO ====== Copying raw files... ======
xcopy /E /V /Y /I "cfg" "%dest%/cfg"
xcopy /E /V /Y /I "maps" "%dest%\maps"
xcopy /E /V /Y /I "resource" "%dest%\resource"
xcopy /E /V /Y /I "scripts" "%dest%\scripts"
xcopy /E /V /Y /I "media" "%dest%\media"
copy /Y "gameinfo.txt" "%dest%\gameinfo.txt"

ECHO.
ECHO ====== Packing pak01_dir... ======
"%vpk%" pak01_dir
copy /Y "pak01_dir.vpk" "%dest%\pak01_dir.vpk"
DEL pak01_dir.vpk

ECHO.
ECHO ====== Copying smsm.dll... ======
copy /Y "smsm\bin\smsm.dll" "%dest%\smsm.dll"

ECHO Done.
