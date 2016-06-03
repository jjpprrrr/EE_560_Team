# ee201L_sync_counter_mix_of_blocking_and_non_blocking_wave.do
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/clk
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/clr
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/load
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/jump
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/en
add wave -noupdate -radix unsigned /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/BA
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/Control
add wave -noupdate -radix ascii /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/Operation
add wave -noupdate -radix unsigned /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/COUNT_BLOCK/Q_next
add wave -noupdate -radix unsigned /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/COUNT_BLOCK/diff
add wave -noupdate -radix unsigned /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/UUT/Q
add wave -noupdate /ee560_sync_counter_mix_of_variables_and_signals_structured_tb/Clk_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 62
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2500000 ps}
