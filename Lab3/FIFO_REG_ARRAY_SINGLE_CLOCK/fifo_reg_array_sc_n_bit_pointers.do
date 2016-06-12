
# fifo_reg_array_sc.do

vlib work
vcom "fifo_reg_array_sc_n_bit_pointers.vhd"
vcom "fifo_reg_array_sc_tb.vhd"
vsim -t 1ps -lib work fifo_reg_array_sc_tb
do {fifo_reg_array_sc_n_bit_pointers_wave.do}
view wave
view structure
view signals
log -r *
run 6us
#update
WaveRestoreZoom {0 ns} {1200 ns}