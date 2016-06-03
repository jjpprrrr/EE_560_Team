onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {CLK and RESET}
add wave -noupdate -radix unsigned -radixshowbase 1 /yard_feet_inches_tb/resetb_tb
add wave -noupdate -radix unsigned -radixshowbase 1 /yard_feet_inches_tb/clk_tb
add wave -noupdate -divider Inputs
add wave -noupdate -radix unsigned -radixshowbase 1 /yard_feet_inches_tb/start_tb
add wave -noupdate -radix unsigned -radixshowbase 0 /yard_feet_inches_tb/Inches_in_tb
add wave -noupdate -radix unsigned -radixshowbase 1 /yard_feet_inches_tb/ack_tb
add wave -noupdate -divider Outputs
add wave -noupdate -radix unsigned -radixshowbase 0 /yard_feet_inches_tb/Inches_out_tb
add wave -noupdate -radix unsigned -radixshowbase 0 /yard_feet_inches_tb/Feet_out_tb
add wave -noupdate -radix unsigned -radixshowbase 0 /yard_feet_inches_tb/Yards_out_tb
add wave -noupdate -radix unsigned -radixshowbase 1 /yard_feet_inches_tb/done_tb
add wave -noupdate -divider Internal
add wave -noupdate /yard_feet_inches_tb/UUT/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {89 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 254
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ns} {412 ns}
