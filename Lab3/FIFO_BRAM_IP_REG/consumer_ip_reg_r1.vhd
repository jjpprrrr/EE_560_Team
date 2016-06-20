
-------------------------------------------------------------------------------
-- consumer_ip_reg_r1.vhd 
-- revised to create two files in place of one file  so that
-- received times (besides received data) can be verfied.
-- This is inline with consumer.vhd of FIFO_REG_ARRAY_TWO_CLOCK
-- Gandhi Puvvada 6/17/2016

-- Design       : FIFO consumer
-- Author       : Pritish Malavade 
-- Company      : University of Southern California 
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;
entity consumer is
port (
		reset	: in    std_logic;  -- note low-active reset
		empty 	: in 	std_logic;
		ren		: out 	std_logic;
		data_in	: in	std_logic_vector(15 downto 0);
		clk		: in 	std_logic
	);
end consumer;

architecture inferable of consumer is



type mem_type is array (31 downto 0) of std_logic_vector(15 downto 0); 
signal mem : mem_type;
type mem_type2 is array (3 downto 0) of std_logic_vector(15 downto 0); 
signal mem_fifo :mem_type2;
type mem_type3 is array (3 downto 0) of std_logic_vector(2 downto 0); 
signal latency :mem_type3;

signal valid			:std_logic;
signal valid_reg1		:std_logic;
signal valid_reg2		:std_logic;
signal consumerptr		:std_logic_vector(4 downto 0);
signal counter			:std_logic_vector(2 downto 0);
signal rclk_clock_count: integer range 0 to 9999;
signal rdptr_int_fifo			:std_logic_vector(2 downto 0); -- read pointer for the internal fifo
signal wrptr_int_fifo			:std_logic_vector(2 downto 0); -- write pointer fot the internal fifo
signal depth_int_fifo			:std_logic_vector(2 downto 0); -- depth of internal fifo
signal ren_int			:std_logic;
signal empty_int_fifo	:std_logic;
signal full_int_fifo	:std_logic;
---------------------------------
begin
---------------------------------
	Clock_counting: process(clk, reset)
	begin
		if (reset = '0') then -- low-active reset
			rclk_clock_count <= 0;
		elsif (clk'event and clk = '1') then
			rclk_clock_count <= rclk_clock_count + 1;
		end if;
	end process Clock_counting;
---------------------------------------
depth_int_fifo <= unsigned(wrptr_int_fifo) - unsigned(rdptr_int_fifo);
comb1 : process(depth_int_fifo)
begin
	if (depth_int_fifo = "000") then 
		empty_int_fifo <= '1' ;
	else 
		empty_int_fifo <= '0' ;
	end if;
	if (depth_int_fifo = "100") then 
		full_int_fifo <= '1' ;
	else 
		full_int_fifo <= '0' ;
	end if;
end process;
----------------------------------------------------
-- The data coming from the fifo is validated and 
--  pipelined appropriately
---------------------------------------------------
comb2 :process (ren_int, empty)
begin
	if(( ren_int = '1') and( empty = '0')) then
			valid <= '1';
	else valid <= '0';
	end if;
	
end process;
-------------------------------------------------------------
-- REN generation
-- If the main fifo is not empty and if the internal fifo has
-- more than one empty location, then enable read.
-------------------------------------------------------------



-- TASK 1: Change the combinational logic in comb3: to ensure that the all the locations of internal fifo are used efficiently. 
-- we want to fill all the locations of internal fifo if the consumer has long latency. For this we will have to check how 
-- many reads from the main fifo are in pipeline. This can be determined by checking the pipelined Valid bit/bits.   
comb3 : process (depth_int_fifo, empty, valid_reg1)
begin
		
		if ((depth_int_fifo = "000" or depth_int_fifo = "001" or depth_int_fifo = "010") and empty = '0') then
			ren <= '1';
			ren_int <= '1';
		elsif (depth_int_fifo = "011" and empty = '0') then
			if (valid_reg1 = '0') then
				ren <= '1';
				ren_int <= '1';
			else
				ren <= '0';
				ren_int <= '0';
			end if;
		else
			ren <= '0';
			ren_int <= '0';
		end if;
end process;

-------------------------------------------------------------
-- Change the file path appropriately
-- The working of consumer can be explained as follows:
-- We have a 4 location fifo internal to the consumer. 
-- If the main fifo is not empty and if the internal fifo has
-- more than one empty location then we enable read. 
-- If the internal fifo is empty and if the incoming data
-- can be can consumed in one clock then they are stored in 
-- memory 'mem' and written to the file "ee560_received_data_hex_alone.txt".
-- Otherwise, the incoming data is stored in the internal fifo.
-- We look at the lower 3 bits of the incoming data to determine
-- latency of consumption in our model of consumer. 
seq: process (clk)
file received_data_hex_alone_file: text open write_mode is "ee560_received_data_hex_alone.txt";
file received_data_file: text open write_mode is "ee560_received_data.txt";
		variable outline : line;
		-- variable inline : line;
begin
	if(reset = '0') then
	valid_reg1 <= '0';
	valid_reg2 <= '0'; -- in case of the fifo with only an input register, valid uses only one pipeline register; two in case of
						-- fifo with both input and output register.
	
	consumerptr <= (others => '0');
	counter <= (others => '0');
	rdptr_int_fifo <= (others => '0');
	wrptr_int_fifo <= (others => '0');
	elsif(clk'event and clk ='1') then
	
	
-- TASK 2: Keep a track of the read requests by using pipelined flipflops.
		valid_reg1 <= valid;

--SUB TASK 2.1: Complete the IF statements.
-- When the requested data arrives consume it.		
		if(	valid_reg1 = '1'	) then		-- When does the requested data arrives ??
			if(data_in(2 downto 0) = "000") then -- or data_in(2 downto 0) = "001") then
			
--SUB TASK 2.2: Complete the IF statements.
				if(	empty_int_fifo = '1') then  	-- Consume the newly arrived data if nothing from previous reads is pending.
				-- Consume if lower 3 bits are 000 and if internal fifo is empty 
				-- First Word fall through.
					mem(CONV_INTEGER(consumerptr))     <= data_in; 
					consumerptr <= unsigned(consumerptr) + 1;
					
					hwrite( outline, data_in); -- hwrite = write in hex format
					write( outline, string'(" rclk_clock_count = "));
					write( outline, rclk_clock_count);
					write( outline, character'(ht)); -- horizontal tab character
					write( outline, string'(" time = "));
					write( outline, now); -- "now" refers to the current simulation time in VHDL. 
					writeline(received_data_file, outline);
					
					hwrite( outline, data_in);
					writeline(received_data_hex_alone_file, outline);
				else 							--  otherwise store in the internal fifo
					mem_fifo(CONV_INTEGER(wrptr_int_fifo(1 downto 0)))	<= data_in;
					latency(CONV_INTEGER(wrptr_int_fifo(1 downto 0)))	<= data_in(2 downto 0);
					wrptr_int_fifo <= unsigned(wrptr_int_fifo) + 1;
				end if;
			else
				
				mem_fifo(CONV_INTEGER(wrptr_int_fifo(1 downto 0)))	<= data_in;
				latency(CONV_INTEGER(wrptr_int_fifo(1 downto 0)))	<= data_in(2 downto 0);
				wrptr_int_fifo <= unsigned(wrptr_int_fifo) + 1;
				
				
			end if;
		end if;
-- TASK 3:	
-- Whether you got some new data or not, the old data which is sitting in the internal fifo needs to be consumed according to the posted latency.

-- fill in the condition		
		if(	empty_int_fifo = '0') then -- if the internal fifo is not empty check the latency 
										-- and consume after appropriate number of clocks
	
			counter <= unsigned(counter) + 1; 
			
-- Which Data I should be looking at.
-- fill in the appropiate index
			if(counter = (latency(CONV_INTEGER(	rdptr_int_fifo(1 downto 0))))) then
					mem(CONV_INTEGER(consumerptr))     <= 	mem_fifo(CONV_INTEGER(rdptr_int_fifo(1 downto 0)				));
					
					hwrite( outline, mem_fifo(CONV_INTEGER(        rdptr_int_fifo(1 downto 0)         ))); -- hwrite = write in hex format
					write( outline, string'(" rclk_clock_count = "));
					write( outline, rclk_clock_count);
					write( outline, character'(ht)); -- horizontal tab character
					write( outline, string'(" time = "));
					write( outline, now); -- "now" refers to the current simulation time in VHDL. 
					writeline(received_data_file, outline);
					
					hwrite( outline, mem_fifo(CONV_INTEGER(	rdptr_int_fifo(1 downto 0)			)));
					writeline(received_data_hex_alone_file, outline);					
					consumerptr <= unsigned(consumerptr) + 1;
					rdptr_int_fifo <= unsigned(rdptr_int_fifo) + 1; -- read pointer for the internal fifo
					counter <= (others => '0');
			end if;
		end if;
		
	end if;
end process;
end inferable;