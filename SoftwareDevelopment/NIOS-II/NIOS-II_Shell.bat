@echo off
:: ============================================================
:: open_shell.bat
:: Opens the Nios II Command Shell in the SAME folder
:: as this .bat file. Double-click from anywhere.
:: ============================================================

set NIOS2_SHELL=

for %%d in (
    "C:\intelFPGA_lite"
    "C:\intelFPGA"
    "C:\altera_lite"
    "C:\altera"
    "D:\intelFPGA_lite"
    "D:\intelFPGA"
    "D:\altera_lite"
    "D:\altera"
) do (
    for %%v in (22.1std 22.1 21.1std 21.1 20.1std 20.1 19.1std 19.1) do (
        if exist "%%~d\%%v\nios2eds\Nios II Command Shell.bat" (
            set NIOS2_SHELL=%%~d\%%v\nios2eds\Nios II Command Shell.bat
            goto :found
        )
    )
)

:found
if "%NIOS2_SHELL%"=="" (
    echo ERROR: Nios II Command Shell not found.
    echo Make sure Quartus is installed in C:\intelFPGA_lite or D:\intelFPGA_lite
    pause
    exit /b 1
)

:: cd to the folder where THIS .bat file lives (not cwd)
cd /d "%~dp0"

echo ============================================================
echo  Nios II Command Shell
echo  Directory: %~dp0
echo ============================================================
echo.
echo FIRST TIME? Run these commands:
echo   chmod +x *.sh
echo   dos2unix *.sh
echo   ./NIOS-II_setup.sh
echo.
echo ALREADY SET UP? Run:
echo   ./build.sh
echo   ./download.sh
echo   ./terminal.sh
echo ============================================================
echo.

call "%NIOS2_SHELL%"