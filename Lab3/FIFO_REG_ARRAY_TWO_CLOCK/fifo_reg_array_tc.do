
# fifo_reg_array_tc.do

vlib work
vcom "fifo_reg_array_tc.vhd"
vcom "producer.vhd"
vcom "consumer.vhd"
vcom  "fifo_reg_array_tc_tb.vhd"
vsim -t 1ps -lib work fifo_tb
do {fifo_reg_array_tc_wave.do}
view wave
view structure
view signals
log -r *
run 11us
#update
WaveRestoreZoom {0 ns} {1200 ns}