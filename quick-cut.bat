@echo off
set PSScript=%~dpn0.ps1
set args=%1
powershell.exe -noexit -File %PSScript% %args%
