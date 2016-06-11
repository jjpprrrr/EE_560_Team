------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_SIGNED.ALL;

------------------------------------------------------------------------------
entity cpu_tb is
end cpu_tb;

------------------------------------------------------------------------------

architecture cpu_behv_tb of cpu_tb is

-- clock period
	constant clk_period: time := 80 ns;

-- local signals
	signal		reset_b_tb               	: std_logic;
	signal		clk_tb                   	: std_logic;
	signal		in_reg_addr_tb             : std_logic_vector(4 downto 0); -- input ID for the register we want to see
	signal		out_reg_data_tb          	: std_logic_vector(31 downto 0); -- output data given by the register
 	
-- component declarations
component cpu_1 is
    Port ( 
			reset_b               	: in std_logic;
			in_reg_addr             : in std_logic_vector(4 downto 0); -- input ID for the register we want to see
			out_reg_data          	: out std_logic_vector(31 downto 0); -- output data given by the register
			clk                   	: in std_logic
			);
end component;


begin
    
  UUT: cpu_1
	  port map(reset_b_tb, in_reg_addr_tb, out_reg_data_tb, clk_tb);
	      
	clock_generate: process
	begin
	  clk_tb <= '0', '1' after (clk_period/2);
	  wait for clk_period;
	end process clock_generate;
	
	reset_generate: process
	begin
	  reset_b_tb <= '0', '1' after (clk_period * 2.1);
	  wait; -- wait forever
	end process reset_generate;
	
	STIMULUS: process
	begin
	  wait for (50 * clk_period);
	  for i in 0 to 31 loop 
			in_reg_addr_tb <= conv_std_logic_vector(i, 5);
			wait for clk_period;
	  end loop;
	end process STIMULUS;

end cpu_behv_tb;

------------------------------------------------------------------------------
