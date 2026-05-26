@echo off
:: ============================================================
:: NIOS-V_Shell.bat
:: Opens the Nios V Command Shell in the SAME folder
:: as this .bat file. Double-click from anywhere.
:: ============================================================

set NIOSV_SHELL=

for %%d in (
    "C:\altera_lite"
    "C:\intelFPGA_lite"
    "C:\intelFPGA"
    "C:\altera"
    "D:\altera_lite"
    "D:\intelFPGA_lite"
    "D:\intelFPGA"
    "D:\altera"
) do (
    for %%v in (25.1std 25.1 24.1std 24.1 23.1std 23.1 22.1std 22.1) do (
        for %%e in (niosv-shell.exe niosv-shell.bat) do (
            if exist "%%~d\%%v\niosv\bin\%%e" (
                set NIOSV_SHELL=%%~d\%%v\niosv\bin\%%e
                goto :found
            )
        )
    )
)

:found
if "%NIOSV_SHELL%"=="" (
    echo ERROR: Nios V Shell not found.
    echo Make sure Quartus is installed in C:\altera_lite or D:\altera_lite
    pause
    exit /b 1
)

:: cd to the folder where THIS .bat file lives
cd /d "%~dp0"

echo ============================================================
echo  Nios V Command Shell
echo  Directory: %~dp0
echo ============================================================
echo.
echo FIRST TIME? Run:
echo   NIOS-V_setup.bat
echo.
echo ALREADY SET UP? Available scripts:
echo   new_project.bat    ^<-- generate BSP + CMake (run once)
echo   rebuild_bsp.bat    ^<-- regenerate BSP after HW changes
echo   update_cmake.bat   ^<-- rescan .c/.h files
echo   run_sim.bat        ^<-- prepare ModelSim simulation
echo   terminal.bat       ^<-- open JTAG terminal
echo.
echo NOTE: Build and download are handled by AshlingRiscFree IDE.
echo ============================================================
echo.

call "%NIOSV_SHELL%"