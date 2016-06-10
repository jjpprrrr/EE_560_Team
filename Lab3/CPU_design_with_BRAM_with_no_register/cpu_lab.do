# cpu_lab.do

vlib work
vcom "ALU.vhd"
vcom "dmem_NOREG_r1.vhd"
vcom "i_fetch_test_stream_1.vhd"  
vcom "Imem_NOREG.vhd"
vcom "reg_file.vhd"
vcom "reverseAssemblyFunctionPkg_r2.vhd"
vcom "cpu_5stage_NOREG.vhd"
vcom "cpu_tb.vhd"

vsim -novopt -t 1ps -lib work cpu_tb

run 60ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_initial_1.txt
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_initial_1.txt

run 2000ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_final_1.txt	
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_final_1.txt
		
quit -sim

vlib work
vcom "i_fetch_test_stream_2.vhd"  
vcom "ALU.vhd"
vcom "dmem_NOREG_r1.vhd"
vcom "Imem_NOREG.vhd"
vcom "reg_file.vhd"
vcom "reverseAssemblyFunctionPkg_r2.vhd"
vcom "cpu_5stage_NOREG.vhd"
vcom "cpu_tb.vhd"

vsim -novopt -t 1ps -lib work cpu_tb

run 60ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_initial_2.txt
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_initial_2.txt

run 2000ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_final_2.txt	
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_final_2.txt
		
quit -sim

vlib work
vcom "i_fetch_test_stream_3_forwarding.vhd"  
vcom "ALU.vhd"
vcom "dmem_NOREG_r1.vhd"
vcom "Imem_NOREG.vhd"
vcom "reg_file.vhd"
vcom "reverseAssemblyFunctionPkg_r2.vhd"
vcom "cpu_5stage_NOREG.vhd"
vcom "cpu_tb.vhd"

vsim -novopt -t 1ps -lib work cpu_tb

run 60ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_initial_3.txt
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_initial_3.txt

run 2000ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_final_3.txt	
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_final_3.txt
		
quit -sim

vlib work
vcom "i_fetch_test_stream_4_forwarding_branch.vhd"  
vcom "ALU.vhd"
vcom "dmem_NOREG_r1.vhd"
vcom "Imem_NOREG.vhd"
vcom "reg_file.vhd"
vcom "reverseAssemblyFunctionPkg_r2.vhd"
vcom "cpu_5stage_NOREG.vhd"
vcom "cpu_tb.vhd"

vsim -novopt -t 1ps -lib work cpu_tb

run 60ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_initial_4.txt
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_initial_4.txt

run 2000ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_final_4.txt	
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_final_4.txt
		
quit -sim

vlib work
vcom "i_fetch_test_stream_5_stall.vhd"  
vcom "ALU.vhd"
vcom "dmem_NOREG_r1.vhd"
vcom "Imem_NOREG.vhd"
vcom "reg_file.vhd"
vcom "reverseAssemblyFunctionPkg_r2.vhd"
vcom "cpu_5stage_NOREG.vhd"
vcom "cpu_tb.vhd"

vsim -novopt -t 1ps -lib work cpu_tb

run 60ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_initial_5.txt
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_initial_5.txt

run 2000ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_final_5.txt	
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_final_5.txt
		
quit -sim

vlib work
vcom "i_fetch_test_stream_6_sw_lw.vhd"  
vcom "ALU.vhd"
vcom "dmem_NOREG_r1.vhd"
vcom "Imem_NOREG.vhd"
vcom "reg_file.vhd"
vcom "reverseAssemblyFunctionPkg_r2.vhd"
vcom "cpu_5stage_NOREG.vhd"
vcom "cpu_tb.vhd"

vsim -novopt -t 1ps -lib work cpu_tb

run 60ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_initial_6.txt
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_initial_6.txt

run 2000ns

mem save UUT/RegFile/register_r -format hex -wordsperline 8 -outfile RegFile_final_6.txt	
mem save UUT/DataMem/mem -format hex -wordsperline 8 -outfile DataMem_final_6.txt
		
quit -sim