
# divider_with_cache.do

vlib work
vcom "spram.vhd"
vcom "lru_generic.vhd"
vcom "cam_generic.vhd"
vcom "cache_generic.vhd"
vcom "divider_with_cache.vhd"
vcom "divider_with_cache_tb.vhd"
vsim -t 1ps -lib work divider_with_cache_tb
# view wave
view structure
view signals
do {divider_with_cache_wave.do}
# do wave.do
log -r *
run 3us
update
WaveRestoreZoom {800 ns} {1600 ns}
