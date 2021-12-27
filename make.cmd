@echo off
setlocal

if "%1" == "dev" (
    kacc -v src\lib\jitasm.y -o src\lib\Jitasm.kx
    kip devinst
)
kacc -l -v src\lib\jitasm.y -o src\lib\Jitasm.kx

endlocal
