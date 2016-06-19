vcom -cover bcesxf number_lock.vhd 
vcom -cover bcesxf number_lock_tb.vhd 
vsim -coverage -novopt work.number_lock_tb 
log -r *
run 13 us
coverage report -file report.txt -select s
