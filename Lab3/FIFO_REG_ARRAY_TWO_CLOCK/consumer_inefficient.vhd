-------------------------------------------------------------------------------
-- File name: 	: consumer_inefficient.vhd for fifo_reg_array_tc.vhd (tc = two clocks)
-- Design       : consumer for fifo_reg_array_tc 
-- Project      : FIFO using register array (two clocks)
-- Author       : Pritish Malavade and Gandhi Puvvada
-- Company      : University of Southern California 
-- Date			: 6/20/2010
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
		data_to_consume	: in	std_logic_vector(15 downto 0);
		rclk		: in 	std_logic
	);
end consumer;

architecture behv of consumer is
 type state_type is (STATE1, STATE2, STATE3);
  signal state          : state_type;

type mem_type is array (0 to 63) of std_logic_vector(15 downto 0); 
signal con_mem : mem_type;

-- signal valid			:std_logic;
-- signal valid_reg1		:std_logic;
-- signal valid_reg2		:std_logic;
signal consumeptr			:std_logic_vector(5 downto 0);
signal counter			:std_logic_vector(2 downto 0);
signal rdptr			:std_logic_vector(2 downto 0);
signal wrptr			:std_logic_vector(2 downto 0);
signal depth			:std_logic_vector(2 downto 0);
-- signal ren_int			:std_logic;
signal empty_int_fifo	:std_logic;
signal full_int_fifo	:std_logic;
-- signal empty_reg1	:std_logic;
-- signal empty_reg2	:std_logic;
signal rclk_clock_count: integer range 0 to 9999;

begin
---------------------------------------
	Clock_counting: process(rclk, reset)
	begin
		if (reset = '1') then
			rclk_clock_count <= 0;
		elsif (rclk'event and rclk = '1') then
			rclk_clock_count <= rclk_clock_count + 1;
		end if;
	end process Clock_counting;
---------------------------------------
seq: process (rclk)
file received_data_file: text open write_mode is "ee560_received_data_inefficient.txt";
file received_data_hex_alone_file: text open write_mode is "ee560_received_data_hex_alone_data_inefficient.txt";
		variable outline : line;
begin
	if(reset = '1') then
	consumeptr <= (others => '0');
	counter <= (others => '0');
	ren <= '0';
	-- ren_int <= '0';
	state <= STATE1;
	elsif(rclk'event and rclk ='1') then
	-- empty_reg1 <= empty;
	-- empty_reg2 <= empty_reg1;
	
	 case (state) is
	 
		when STATE1 =>
			if (empty = '0') then -- wait for the FIFO to gather a data item
				state <= STATE2;
				counter <= (others => '0');
			end if;		
			
		when STATE2 =>	 -- after the specified latncy consume data and activate ren to cause rdptr to increment
			if (
				(data_to_consume(2 downto 0) = "000" or data_to_consume(2 downto 0) = "001") 
				or
				(counter = data_to_consume(2 downto 0)) 
			   )  then -- consume data and activate ren to cause rdptr to increment
					con_mem(CONV_INTEGER(consumeptr))     <= data_to_consume; 
					consumeptr <= consumeptr + 1;
					hwrite( outline, data_to_consume); -- hwrite = write in hex format
					write( outline, string'(" rclk_clock_count = "));
					write( outline, rclk_clock_count);
					write( outline, character'(ht)); -- horizontal tab character
					write( outline, string'(" time = "));
					write( outline, now); -- "now" refers to the current simulation time in VHDL. 
					writeline(received_data_file, outline);
					
					hwrite( outline, data_to_consume); -- hwrite = write in hex
					writeline(received_data_hex_alone_file, outline);
					ren <= '1'; -- notice that this ineffient designer made ren a Flip-flop. He will waste one clock to set ren
					state <= STATE3; -- He need to go to a state to reset ren Flipflop. Notice that he can not go to state 1 from here.
					-- If he goes to state 1 from here, since ren is active only in state 1, he will have a false non-emptiness 
					-- even though he has just consumed the last data item in the FIFO
			else 
				counter <= counter + 1;
			end if;
			
		when STATE3 =>  -- 
			ren <= '0';
			state <= STATE1;

	 end case;	
	end if;
end process;
---------------------------------------
end behv;