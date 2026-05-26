@echo off
:: ============================================================
:: NIOS-V_setup.bat
:: Run ONCE from the Nios V Command Shell.
:: Asks for paths and generates all project .bat scripts.
:: Build and download are handled by AshlingRiscFree IDE.
:: ============================================================

echo ============================================================
echo  Nios V Project Initializer
echo ============================================================
echo.

:: ── Auto-detect Nios V tools path ────────────────────────────
set TOOLS_PATH_DEFAULT=
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
    for %%v in (25.1std 25.1 24.1std 24.1 23.1std 23.1) do (
        if exist "%%~d\%%v\niosv\bin\niosv-bsp.exe" (
            set TOOLS_PATH_DEFAULT=%%~d\%%v\niosv\bin
            goto :tools_detected
        )
    )
)
:tools_detected

:: ── Ask for paths ─────────────────────────────────────────────
echo Enter the FULL Windows path to your .sopcinfo file:
echo (e.g. D:\MyProject\MusicPlayerQuartus\MusicPlayerPlatformDesign.sopcinfo)
set /p SOPCINFO=SOPCINFO path: 

if not exist "%SOPCINFO%" (
    echo ERROR: File not found: %SOPCINFO%
    pause
    exit /b 1
)

echo.
echo Enter the FULL Windows path to your software root directory:
echo (e.g. D:\MyProject\SoftwareDevelopment\NIOS-V)
set /p SW_ROOT=Software root path: 

echo.
echo Enter the CPU component name as it appears in Platform Designer:
echo (e.g. CPU_NIOS_V)
set CPU_NAME=CPU_NIOS_V
set /p CPU_NAME=CPU name [CPU_NIOS_V]: 
if "%CPU_NAME%"=="" set CPU_NAME=CPU_NIOS_V

echo.
echo Enter the name of the Audio IP component instance as it appears in Platform Designer:
echo (e.g. AUDIO_OUT -- check Platform Designer, it is the instance name in ALL CAPS)
set AUDIO_INST=AUDIO_OUT
set /p AUDIO_INST=Audio instance name [AUDIO_OUT]: 
if "%AUDIO_INST%"=="" set AUDIO_INST=AUDIO_OUT

echo.
echo Enter the Nios V tools bin path (niosv-bsp.exe lives here):
if not "%TOOLS_PATH_DEFAULT%"=="" (
    echo Auto-detected: %TOOLS_PATH_DEFAULT%
    set TOOLS_PATH=%TOOLS_PATH_DEFAULT%
    set /p TOOLS_PATH=Tools path [press Enter to accept]: 
    if "%TOOLS_PATH%"=="" set TOOLS_PATH=%TOOLS_PATH_DEFAULT%
) else (
    echo (e.g. C:\altera_lite\25.1std\niosv\bin)
    set /p TOOLS_PATH=Tools path: 
)

:: ── Derive SOC name and dirs ──────────────────────────────────
for %%f in ("%SOPCINFO%") do set SOC_NAME=%%~nf
for %%f in ("%SOPCINFO%") do set SOPCINFO_DIR=%%~dpf
if "%SOPCINFO_DIR:~-1%"=="\" set SOPCINFO_DIR=%SOPCINFO_DIR:~0,-1%

:: ── Confirmation ─────────────────────────────────────────────
echo.
echo ============================================================
echo  Please confirm the following settings:
echo ============================================================
echo   SOPCINFO    : %SOPCINFO%
echo   SW ROOT     : %SW_ROOT%
echo   CPU NAME    : %CPU_NAME%
echo   AUDIO INST  : %AUDIO_INST%
echo   SOC NAME    : %SOC_NAME%
echo   TOOLS       : %TOOLS_PATH%
echo ============================================================
echo.
set CONFIRM=Y
set /p CONFIRM=Are these correct? [Y/n]: 
if /i "%CONFIRM%"=="n" (
    echo Aborted. Re-run the script to try again.
    pause
    exit /b 1
)
echo.

:: ── Create directory structure ────────────────────────────────
mkdir "%SW_ROOT%\bsp" 2>nul
mkdir "%SW_ROOT%\app" 2>nul
mkdir "%SW_ROOT%\app\src" 2>nul
mkdir "%SW_ROOT%\app\lib" 2>nul
mkdir "%SW_ROOT%\app\include" 2>nul
mkdir "%SW_ROOT%\app\build" 2>nul

:: Only write main.c if NO .c files exist anywhere in app\
set FOUND_C=
for /r "%SW_ROOT%\app" %%f in (*.c) do (
    set FOUND_C=%%f
    goto :check_done
)
:check_done

if "%FOUND_C%"=="" (
    (
        echo #include ^<sys/alt_stdio.h^>
        echo.
        echo int main^(void^) {
        echo     alt_putstr^("Hello from Nios V!\n"^);
        echo     while^(1^);
        echo     return 0;
        echo }
    ) > "%SW_ROOT%\app\main.c"
    echo [OK] main.c written ^(no existing source files found^).
) else (
    echo [OK] Existing source files detected -- leaving them untouched.
    for /r "%SW_ROOT%\app" %%f in (*.c) do echo   %%f
)

echo [OK] Directory structure ready.
echo.

:: ==============================================================
:: new_project.bat
::
:: KEY FIX: niosv-bsp supports --cmd to run TCL commands DURING
:: BSP creation, BEFORE the Enhanced HAL Interrupt API validation.
::
:: set_driver AUDIO_OUT {} --> assigns NO driver to the audio
:: component, completely bypassing the Avalon_Audio_driver which
:: uses the legacy interrupt API incompatible with Nios V.
::
:: set_setting flags are applied pre-validation as well.
:: No post-processing of settings.bsp needed -- no BOM issues.
:: ==============================================================
(
echo @echo off
echo :: new_project.bat - Generated by NIOS-V_setup.bat
echo set SOPCINFO=%SOPCINFO%
echo set SW_ROOT=%SW_ROOT%
echo set CPU_NAME=%CPU_NAME%
echo set AUDIO_INST=%AUDIO_INST%
echo set BSP_DIR=%%SW_ROOT%%\bsp
echo set APP_DIR=%%SW_ROOT%%\app
echo set PATH=%%PATH%%;%TOOLS_PATH%
echo.
echo echo ============================================================
echo echo  Nios V -- BSP + CMake Generator
echo echo ============================================================
echo echo.
echo.
echo :: Collect source files
echo set SRCS=
echo for %%%%f in ^("%%APP_DIR%%\*.c"^) do call :add_src "%%%%f"
echo for %%%%f in ^("%%APP_DIR%%\src\*.c"^) do call :add_src "%%%%f"
echo for %%%%f in ^("%%APP_DIR%%\lib\*.c"^) do call :add_src "%%%%f"
echo goto :srcs_done
echo :add_src
echo if "%%SRCS%%"=="" ^(set SRCS=%%~1^) else ^(set SRCS=%%SRCS%%,%%~1^)
echo exit /b
echo :srcs_done
echo.
echo echo Sources found: %%SRCS%%
echo echo.
echo.
echo echo [1/2] Generating BSP...
echo echo Using --cmd to disable Avalon Audio legacy driver BEFORE validation.
echo niosv-bsp -c --sopcinfo="%%SOPCINFO%%" --type=hal "%%BSP_DIR%%\settings.bsp" --cmd="set_driver %%AUDIO_INST%% {}" --cmd="set_setting hal.enable_reduced_device_drivers true"
echo if errorlevel 1 ^(echo ERROR: BSP generation failed ^& pause ^& exit /b 1^)
echo.
echo echo [2/2] Generating CMake app project...
echo niosv-app --bsp-dir="%%BSP_DIR%%" --app-dir="%%APP_DIR%%" --srcs=%%SRCS%% --incs="%%APP_DIR%%\include"
echo if errorlevel 1 ^(echo ERROR: CMake app generation failed ^& pause ^& exit /b 1^)
echo.
echo echo.
echo echo ============================================================
echo echo  DONE^^! Next steps in AshlingRiscFree IDE:
echo echo    1. File ^> Import Nios V CMake project...
echo echo    2. Navigate to: %%APP_DIR%%
echo echo    3. Select Folder ^> Finish
echo echo    4. CTRL+B to build
echo echo ============================================================
echo pause
) > "%SW_ROOT%\new_project.bat"
echo [OK] new_project.bat written.

:: ==============================================================
:: rebuild_bsp.bat
:: ==============================================================
(
echo @echo off
echo :: rebuild_bsp.bat - Generated by NIOS-V_setup.bat
echo set SOPCINFO=%SOPCINFO%
echo set SW_ROOT=%SW_ROOT%
echo set CPU_NAME=%CPU_NAME%
echo set AUDIO_INST=%AUDIO_INST%
echo set BSP_DIR=%%SW_ROOT%%\bsp
echo set APP_DIR=%%SW_ROOT%%\app
echo set PATH=%%PATH%%;%TOOLS_PATH%
echo.
echo echo ============================================================
echo echo  Nios V -- Rebuild BSP
echo echo ============================================================
echo echo.
echo.
echo echo [1/3] Deleting old BSP...
echo rmdir /s /q "%%BSP_DIR%%"
echo mkdir "%%BSP_DIR%%"
echo.
echo echo [2/3] Generating new BSP...
echo niosv-bsp -c --sopcinfo="%%SOPCINFO%%" --type=hal "%%BSP_DIR%%\settings.bsp" --cmd="set_driver %%AUDIO_INST%% {}" --cmd="set_setting hal.enable_reduced_device_drivers true"
echo if errorlevel 1 ^(echo ERROR: BSP generation failed ^& pause ^& exit /b 1^)
echo.
echo echo [3/3] Regenerating CMake app project...
echo set SRCS=
echo for %%%%f in ^("%%APP_DIR%%\*.c"^) do call :add_src "%%%%f"
echo for %%%%f in ^("%%APP_DIR%%\src\*.c"^) do call :add_src "%%%%f"
echo for %%%%f in ^("%%APP_DIR%%\lib\*.c"^) do call :add_src "%%%%f"
echo goto :srcs_done
echo :add_src
echo if "%%SRCS%%"=="" ^(set SRCS=%%~1^) else ^(set SRCS=%%SRCS%%,%%~1^)
echo exit /b
echo :srcs_done
echo niosv-app --bsp-dir="%%BSP_DIR%%" --app-dir="%%APP_DIR%%" --srcs=%%SRCS%% --incs="%%APP_DIR%%\include"
echo if errorlevel 1 ^(echo ERROR: CMake app generation failed ^& pause ^& exit /b 1^)
echo.
echo echo BSP rebuilt. In RiscFree IDE: Project ^> Clean ^> CTRL+B
echo pause
) > "%SW_ROOT%\rebuild_bsp.bat"
echo [OK] rebuild_bsp.bat written.

:: ==============================================================
:: update_cmake.bat
:: ==============================================================
(
echo @echo off
echo :: update_cmake.bat - Generated by NIOS-V_setup.bat
echo set SW_ROOT=%SW_ROOT%
echo set BSP_DIR=%%SW_ROOT%%\bsp
echo set APP_DIR=%%SW_ROOT%%\app
echo set PATH=%%PATH%%;%TOOLS_PATH%
echo.
echo echo === Scanning source files ===
echo set SRCS=
echo for %%%%f in ^("%%APP_DIR%%\*.c"^) do call :add_src "%%%%f"
echo for %%%%f in ^("%%APP_DIR%%\src\*.c"^) do call :add_src "%%%%f"
echo for %%%%f in ^("%%APP_DIR%%\lib\*.c"^) do call :add_src "%%%%f"
echo goto :srcs_done
echo :add_src
echo if "%%SRCS%%"=="" ^(set SRCS=%%~1^) else ^(set SRCS=%%SRCS%%,%%~1^)
echo exit /b
echo :srcs_done
echo.
echo echo Sources found: %%SRCS%%
echo echo.
echo niosv-app --bsp-dir="%%BSP_DIR%%" --app-dir="%%APP_DIR%%" --srcs=%%SRCS%% --incs="%%APP_DIR%%\include"
echo if errorlevel 1 ^(echo ERROR: CMake regeneration failed ^& pause ^& exit /b 1^)
echo.
echo echo Done^^! In RiscFree IDE: Project ^> Clean ^> CTRL+B
echo pause
) > "%SW_ROOT%\update_cmake.bat"
echo [OK] update_cmake.bat written.

:: ==============================================================
:: terminal.bat
:: ==============================================================
(
echo @echo off
echo :: terminal.bat - Generated by NIOS-V_setup.bat
echo set PATH=%%PATH%%;%TOOLS_PATH%
echo echo === Nios V JTAG Terminal ^(CTRL+C to exit^) ===
echo juart-terminal
) > "%SW_ROOT%\terminal.bat"
echo [OK] terminal.bat written.

:: ==============================================================
:: run_sim.bat
:: ==============================================================
(
echo @echo off
echo :: run_sim.bat - Generated by NIOS-V_setup.bat
echo set SOC_NAME=%SOC_NAME%
echo set SW_ROOT=%SW_ROOT%
echo set SOPCINFO_DIR=%SOPCINFO_DIR%
echo set ELF=%%SW_ROOT%%\app\build\Default\app.elf
echo set BSP_DIR=%%SW_ROOT%%\bsp
echo set MENTOR=%%SOPCINFO_DIR%%\%%SOC_NAME%%\testbench\mentor
echo set SUBMODULES=%%SOPCINFO_DIR%%\%%SOC_NAME%%\testbench\%%SOC_NAME%%_tb\simulation\submodules
echo set PATH=%%PATH%%;%TOOLS_PATH%
echo.
echo echo ============================================================
echo echo  Nios V -- Prepare ModelSim Simulation
echo echo ============================================================
echo echo.
echo.
echo if not exist "%%ELF%%" ^(
echo     echo ERROR: ELF not found: %%ELF%%
echo     echo Build the project in AshlingRiscFree IDE first ^(CTRL+B^).
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo [1/3] Copying ELF to mentor folder...
echo mkdir "%%MENTOR%%" 2^>nul
echo copy "%%ELF%%" "%%MENTOR%%\app.elf"
echo if errorlevel 1 ^(echo ERROR: Copy failed ^& pause ^& exit /b 1^)
echo.
echo echo [2/3] Reading RAM base from bsp\system.h...
echo set RAM_BASE=
echo set RAM_SPAN=
echo for /f "tokens=3" %%%%a in ^('findstr /r "RAM.*_BASE" "%%BSP_DIR%%\system.h"'^) do set RAM_BASE=%%%%a
echo for /f "tokens=3" %%%%a in ^('findstr /r "RAM.*_SPAN" "%%BSP_DIR%%\system.h"'^) do set RAM_SPAN=%%%%a
echo if "%%RAM_BASE%%"=="" ^(echo ERROR: Could not find RAM base in system.h ^& pause ^& exit /b 1^)
echo echo   RAM_BASE = %%RAM_BASE%%
echo echo   RAM_SPAN = %%RAM_SPAN%%
echo.
echo echo [3/3] Converting ELF to HEX for ModelSim...
echo mkdir "%%SUBMODULES%%" 2^>nul
echo elf2hex --input="%%MENTOR%%\app.elf" --output="%%SUBMODULES%%\%%SOC_NAME%%_RAM.hex" --width=32 --base=%%RAM_BASE%% --end=0x7ffff
echo if errorlevel 1 ^(echo ERROR: elf2hex failed ^& pause ^& exit /b 1^)
echo.
echo echo.
echo echo ============================================================
echo echo  DONE^^! Open ModelSim and run:
echo echo ============================================================
echo echo    cd {%%MENTOR%%}
echo echo    do msim_setup.tcl
echo echo    add wave /%%SOC_NAME%%_tb/*
echo echo    ld_debug
echo echo    run 2.5ms
echo echo ============================================================
echo pause
) > "%SW_ROOT%\run_sim.bat"
echo [OK] run_sim.bat written.

:: ==============================================================
:: Summary
:: ==============================================================
echo.
echo ============================================================
echo  ALL SCRIPTS WRITTEN TO: %SW_ROOT%
echo ============================================================
echo   new_project.bat   -- generate BSP + CMake ^(run ONCE^)
echo   rebuild_bsp.bat   -- regenerate BSP after HW changes
echo   update_cmake.bat  -- rescan .c/.h, update CMakeLists.txt
echo   terminal.bat      -- open JTAG terminal ^(juart-terminal^)
echo   run_sim.bat       -- convert ELF to HEX for ModelSim
echo ============================================================
echo.
echo NOTE: Audio is accessed via MMIO ^(IOWR/IORD^) in your C code.
echo The Avalon_Audio_driver HAL is disabled ^(Nios V incompatible^).
echo Use AUDIO_OUT_BASE and AUDIO_CONFIG_BASE from system.h.
echo ============================================================
echo.
echo NEXT STEP: Run new_project.bat
echo Then import the app\ folder into AshlingRiscFree IDE.
echo ============================================================
pause