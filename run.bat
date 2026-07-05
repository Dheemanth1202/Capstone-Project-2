@echo off
REM =====================================================================
REM Windows Batch script to compile, run simulation, and open GTKWave
REM =====================================================================

SET IVERILOG_PATH=C:\iverilog\bin
SET GTKWAVE_PATH=C:\iverilog\gtkwave\bin

echo ===================================================
echo  1. Compiling Verilog RTL + Testbench
echo ===================================================
"%IVERILOG_PATH%\iverilog.exe" -o sim/systolic_sim.vvp rtl/half_adder.v rtl/full_adder.v rtl/register.v rtl/mux.v rtl/processing_element.v rtl/control_unit.v rtl/systolic_array.v rtl/systolic_top.v tb/systolic_tb.v
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed!
    pause
    exit /b %ERRORLEVEL%
)
echo [OK] Compilation successful.

echo ===================================================
echo  2. Running Simulation (vvp)
echo ===================================================
"%IVERILOG_PATH%\vvp.exe" sim/systolic_sim.vvp
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Simulation failed!
    pause
    exit /b %ERRORLEVEL%
)

echo ===================================================
echo  3. Launching GTKWave
echo ===================================================
start "" "%GTKWAVE_PATH%\gtkwave.exe" sim\waveform.vcd sim\waveform.gtkw
echo [OK] GTKWave launched with waveform.vcd and waveform.gtkw configuration.
pause
