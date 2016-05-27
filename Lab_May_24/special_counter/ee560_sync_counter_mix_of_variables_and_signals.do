# ee560_sync_counter_mix_of_variables_and_signals.do

vlib work
vcom  "ee560_sync_counter_mix_of_variables_and_signals.vhd"  
# vlog  "ee201L_sync_counter_mix_of_blocking_and_non_blocking_tb.v" 
vcom "ee560_sync_counter_mix_of_variables_and_signals_structured_tb.vhd"
# vsim -novopt -t 1ps -lib work ee201L_sync_counter_with_jump_tb
vsim -novopt -t 1ps -lib work ee560_sync_counter_mix_of_variables_and_signals_structured_tb
view wave
view structure
view signals
# do {ee201L_sync_counter_mix_of_blocking_and_non_blocking_wave.do}
do {ee560_sync_counter_mix_of_variables_and_signals_wave.do}
log -r *

run 2500ns



