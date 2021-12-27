@echo off
setlocal

set ARGS=-v src\lib\jitasm.y -o src\lib\Jitasm.kx
if not "%1" == "dev" set ARGS=-l %ARGS%
kacc %ARGS%
if "%1" == "dev" kip devinst

endlocal
