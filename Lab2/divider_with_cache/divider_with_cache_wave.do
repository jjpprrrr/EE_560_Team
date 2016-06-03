onerror {resume}
quietly WaveActivateNextPane {} 0
#####################################################################################
add wave -noupdate -group {Testbench}
add wave -noupdate -group {Testbench} -format Literal /divider_with_cache_tb/clock_count
add wave -noupdate -group {Testbench} -format Logic /divider_with_cache_tb/clk_tb
add wave -noupdate -group {Testbench} -format Logic /divider_with_cache_tb/resetb_tb
add wave -noupdate -group {Testbench} -format Logic /divider_with_cache_tb/start_tb

add wave -noupdate -group {Testbench} -format Literal -radix hexadecimal /divider_with_cache_tb/xin_tb
add wave -noupdate -group {Testbench} -format Literal -radix hexadecimal /divider_with_cache_tb/yin_tb
add wave -noupdate -group {Testbench} -format Literal -radix hexadecimal /divider_with_cache_tb/q_tb
add wave -noupdate -group {Testbench} -format Literal -radix hexadecimal /divider_with_cache_tb/r_tb

add wave -noupdate -group {Testbench} -format  Logic /divider_with_cache_tb/INITIAL_ST_tb
add wave -noupdate -group {Testbench} -format  Logic /divider_with_cache_tb/CACHE_CHECK_ST_tb
add wave -noupdate -group {Testbench} -format  Logic /divider_with_cache_tb/COMPUTE_ST_tb
add wave -noupdate -group {Testbench} -format  Logic /divider_with_cache_tb/DONE_CALC_ST_tb
add wave -noupdate -group {Testbench} -format  Logic /divider_with_cache_tb/DONE_CACHE_HIT_ST_tb
add wave -noupdate -group {Testbench} -format Literal -radix hexadecimal /divider_with_cache_tb/clocks_taken_tb

add wave -noupdate -group {Testbench} -format Logic /divider_with_cache_tb/done_tb
add wave -noupdate -group {Testbench} -format Logic /divider_with_cache_tb/ack_tb
#####################################################################################
add wave -noupdate -expand -group {Divider with cache}
# Notice that we opted "-expand" option for some groups
add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/clk
add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/resetb
add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/start

add wave -noupdate -group {Divider with cache} -format Literal /divider_with_cache_tb/uut/state
add wave -noupdate -group {Divider with cache} -format  Logic /divider_with_cache_tb/uut/INITIAL_ST
add wave -noupdate -group {Divider with cache} -format  Logic /divider_with_cache_tb/uut/CACHE_CHECK_ST
add wave -noupdate -group {Divider with cache} -format  Logic /divider_with_cache_tb/uut/COMPUTE_ST
add wave -noupdate -group {Divider with cache} -format  Logic /divider_with_cache_tb/uut/DONE_CALC_ST
add wave -noupdate -group {Divider with cache} -format  Logic /divider_with_cache_tb/uut/DONE_CACHE_HIT_ST
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/clocks_taken

add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/xin
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/yin
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/q
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/r

add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/we
add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/rd
add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/hit_true
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/tag_in
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/data_in
add wave -noupdate -group {Divider with cache} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/data_out

add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/done
add wave -noupdate -group {Divider with cache} -format Logic /divider_with_cache_tb/uut/ack
#####################################################################################
add wave -noupdate -group cache
add wave -noupdate -group cache -format Logic /divider_with_cache_tb/uut/cache_inst/rd
add wave -noupdate -group cache -format Logic /divider_with_cache_tb/uut/cache_inst/we
add wave -noupdate -group cache -format Logic -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/empty_true_sig
add wave -noupdate -group cache -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/empty_sig
add wave -noupdate -group cache -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/empty_a_sig
add wave -noupdate -group cache -format Logic -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/hit_true_sig
add wave -noupdate -group cache -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/hit_sig
add wave -noupdate -group cache -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/hit_a_sig
add wave -noupdate -group cache -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/victim_sig
add wave -noupdate -group cache -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/victim_a_sig
#####################################################################################
add wave -noupdate -expand -group CAM
add wave -noupdate -group CAM -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/tag_in
add wave -noupdate -group CAM -format Logic -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/rd
add wave -noupdate -group CAM -format Logic -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/we
add wave -noupdate -group CAM -format Literal /divider_with_cache_tb/uut/cache_inst/cam_inst/hit
add wave -noupdate -group CAM -format Logic /divider_with_cache_tb/uut/cache_inst/cam_inst/hit_true
add wave -noupdate -group CAM -format Literal /divider_with_cache_tb/uut/cache_inst/cam_inst/hit_a
add wave -noupdate -group CAM -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/tag_we
add wave -noupdate -group CAM -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/tag_write_addr
add wave -noupdate -group CAM -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/tag
add wave -noupdate -group CAM -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/cam_inst/valid
#####################################################################################
add wave -noupdate -group LRU
add wave -noupdate -group LRU -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/accessed_block
add wave -noupdate -group LRU -format Logic -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/update_lru_stack
add wave -noupdate -group LRU -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/victim
add wave -noupdate -group LRU -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/victim_a
add wave -noupdate -group LRU -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/update_sloc
add wave -noupdate -group LRU -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/sloc_eq
add wave -noupdate -group LRU -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/lru_inst/sloc
#####################################################################################
add wave -noupdate -group {Data RAM}
add wave -noupdate -group {Data RAM} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/spram_inst/addr
add wave -noupdate -group {Data RAM} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/spram_inst/data_in
add wave -noupdate -group {Data RAM} -format Logic -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/spram_inst/we
add wave -noupdate -group {Data RAM} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/spram_inst/data_out
add wave -noupdate -group {Data RAM} -format Literal -radix hexadecimal /divider_with_cache_tb/uut/cache_inst/spram_inst/mem
#####################################################################################
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1300ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 15000
configure wave -griddelta 40
configure wave -timeline 0
update
# WaveRestoreZoom {800 ns} {1600 ns}
