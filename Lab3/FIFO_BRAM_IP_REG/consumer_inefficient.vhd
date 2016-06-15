-------------------------------------------------------------------------------
--
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
		reset	: in    std_logic;
		empty 	: in 	std_logic;
		ren		: out 	std_logic;
		data_in	: in	std_logic_vector(15 downto 0);
		clk		: in 	std_logic
	);
end consumer;

architecture inferable of consumer is
 type state_type is (STATE1, STATE2, STATE3, STATE4, STATE5);
  signal state          : state_type;

type mem_type is array (31 downto 0) of std_logic_vector(15 downto 0); 
signal mem : mem_type;

signal count			:std_logic_vector(4 downto 0);
signal counter			:std_logic_vector(2 downto 0);
signal ren_int			:std_logic;

begin

seq: process (clk)
file received_data: text open write_mode is "E:\FIFO\FIFO_Su2010\FIFO_BRAM_IP_OP_REG\ee560_received_data.txt";
		variable outline : line;
		variable inline : line;
begin
	if(reset = '0') then
	count <= (others => '0');
	counter <= (others => '0');
	ren <= '0';
	ren_int <= '0';
	state <= STATE1;
	elsif(clk'event and clk ='1') then

	    case (state) is
        when STATE1 =>
			if(empty = '0' ) then
				ren <= '1';
				ren_int <= '1';
				if (ren_int = '1') then
					ren <= '0';
				end if;
				state <= STATE2;			
			else 
				ren <= '0';
			end if;
			
		when STATE2 =>
			ren <= '0';
			ren_int <= '0';
			state <= STATE3;
			counter <= (others => '0');
			
		when STATE3 =>
			ren <= '0';
			state <= STATE4;
		when STATE4 =>
			if(data_in(2 downto 0) = "000" or data_in(2 downto 0) = "001") then
				mem(CONV_INTEGER(count))     <= data_in; 
				count <= unsigned(count) + 1;
				write( outline, data_in);
				writeline(received_data, outline);
				
				if (empty = '0') then
					ren <= '1';
					state <= STATE2;
				else state <= STATE1;
				end if;
			else 
				state <= STATE5;
				counter <= counter + 1;
			end if;
		when STATE5 => 	
			counter <= counter + 1;
			if (counter = data_in(2 downto 0)) then
				mem(CONV_INTEGER(count))     <= data_in; 
				count <= unsigned(count) + 1;
				write( outline, data_in);
				writeline(received_data, outline);
				if (empty = '0') then
					ren <= '1';
					state <= STATE2;
				else state <= STATE1;
				end if;
			end if;
		end case;	
		
	end if;
end process;
end inferable;