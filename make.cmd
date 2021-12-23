@echo off

kacc -v src\lib\jitasm.y -o src\lib\Jitasm.kx
if "%1" == "dev" kip devinst
