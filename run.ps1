# =====================================================================
# PowerShell script to compile, run simulation, and open GTKWave
# =====================================================================

$IverilogPath = "C:\iverilog\bin"
$GtkwavePath = "C:\iverilog\gtkwave\bin"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " 1. Compiling Verilog RTL + Testbench" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan

& "$IverilogPath\iverilog.exe" -o sim/systolic_sim.vvp rtl/half_adder.v rtl/full_adder.v rtl/register.v rtl/mux.v rtl/processing_element.v rtl/control_unit.v rtl/systolic_array.v rtl/systolic_top.v tb/systolic_tb.v 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
    return
}
Write-Host "[OK] Compilation successful." -ForegroundColor Green

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " 2. Running Simulation (vvp)" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan

& "$IverilogPath\vvp.exe" sim/systolic_sim.vvp

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Simulation failed!" -ForegroundColor Red
    return
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " 3. Launching GTKWave" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan

Start-Process "$GtkwavePath\gtkwave.exe" -ArgumentList "sim\waveform.vcd", "sim\waveform.gtkw"
Write-Host "[OK] GTKWave launched with waveform.vcd and waveform.gtkw configuration." -ForegroundColor Green
