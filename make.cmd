@echo off
setlocal

set ARGS=-v src\lib\jitasm.y -o src\lib\Jitasm.kx
if "%1" == "dev" (
    kacc %ARGS%
    kip devinst
)
kacc -l %ARGS%

endlocal
