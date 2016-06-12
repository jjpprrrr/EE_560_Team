onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /fifo_reg_array_sc_tb/uut/clk
add wave -noupdate -format Logic /fifo_reg_array_sc_tb/uut/reset
add wave -noupdate -format Literal -radix hexadecimal /fifo_reg_array_sc_tb/uut/data_in
add wave -noupdate -format Literal -radix hexadecimal /fifo_reg_array_sc_tb/uut/data_out
add wave -noupdate -format Literal -radix hexadecimal /fifo_reg_array_sc_tb/uut/depth
add wave -noupdate -divider WRITES
add wave -noupdate -color Magenta -format Logic /fifo_reg_array_sc_tb/uut/wen
add wave -noupdate -color Magenta -format Logic /fifo_reg_array_sc_tb/uut/wenq
add wave -noupdate -color Magenta -format Literal -radix hexadecimal /fifo_reg_array_sc_tb/uut/wrptr
add wave -noupdate -color Magenta -format Logic /fifo_reg_array_sc_tb/uut/full
add wave -noupdate -divider READS
add wave -noupdate -color White -format Logic /fifo_reg_array_sc_tb/uut/ren
add wave -noupdate -color White -format Logic /fifo_reg_array_sc_tb/uut/renq
add wave -noupdate -color White -format Literal -radix hexadecimal /fifo_reg_array_sc_tb/uut/rdptr
add wave -noupdate -color White -format Logic /fifo_reg_array_sc_tb/uut/empty
add wave -noupdate -divider ARRAY
add wave -noupdate -format Literal -radix hexadecimal -expand /fifo_reg_array_sc_tb/uut/reg_array
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {90 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 69
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1200 ns}
