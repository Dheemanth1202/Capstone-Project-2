# =============================================================================
# run.do — ModelSim / QuestaSim simulation script
# Waveform layout matches: clk | rst_n | start | A[7:0] | B[7:0] | P[15:0] | valid
# Usage: vsim -do sim/run.do
# =============================================================================

set RTL_DIR ../rtl
set TB_DIR  ../tb
set SIM_DIR ../sim

# ---- Clean and create work library ----
if {[file exists work]} { vdel -all }
vlib work
vmap work work

# ---- Compile RTL (leaf-first) ----
vlog "$RTL_DIR/half_adder.v"
vlog "$RTL_DIR/full_adder.v"
vlog "$RTL_DIR/register.v"
vlog "$RTL_DIR/mux.v"
vlog "$RTL_DIR/processing_element.v"
vlog "$RTL_DIR/control_unit.v"
vlog "$RTL_DIR/systolic_array.v"
vlog "$RTL_DIR/systolic_top.v"

# ---- Compile Testbench ----
vlog "$TB_DIR/systolic_tb.v"

# ---- Simulate ----
vsim -t 1ns -novopt work.systolic_tb

# =========================================================
#   WAVE WINDOW — Styled to match sample waveform image
# =========================================================

# ---- Clock / Reset ----
add wave -divider "CLOCK  /  RESET"
add wave -color Cyan    -label "clk"   sim:/systolic_tb/clk
add wave -color Orange  -label "rst_n" sim:/systolic_tb/rst_n

# ---- Control ----
add wave -divider "CONTROL"
add wave -color Yellow  -label "start" sim:/systolic_tb/start
add wave -color Green   -label "valid" sim:/systolic_tb/valid
add wave -color Red     -label "busy"  sim:/systolic_tb/busy

# ---- Data buses (hex, unsigned) ----
add wave -divider "DATA BUSES"
add wave -color Cyan    -label "A\[7:0\]"  -radix hexadecimal sim:/systolic_tb/A
add wave -color Magenta -label "B\[7:0\]"  -radix hexadecimal sim:/systolic_tb/B
add wave -color Green   -label "P\[15:0\]" -radix hexadecimal sim:/systolic_tb/P

# ---- Internal state ----
add wave -divider "FSM STATE"
add wave -color Yellow  -radix decimal -label "state"     sim:/systolic_tb/DUT/CU/state
add wave -color White   -radix decimal -label "cycle_cnt" sim:/systolic_tb/DUT/CU/cycle_cnt

# ---- Run and save ----
run -all

echo ""
echo "=============================================="
echo "  Simulation complete. Check transcript."
echo "  VCD saved to: sim/waveform.vcd"
echo "=============================================="
