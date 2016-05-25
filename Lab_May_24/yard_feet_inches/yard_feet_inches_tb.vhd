------------------------------------------------------------------------------
--	A vhdl testbench to test the divider_mealy
--	
--	Written by Gandhi Puvvada  Date: 6/14/99, 12/1/99, 2/20/04, 6/1/2008

--	File name: divider_mealy_tb.vhd  
-- See also divider_mealy_long_tb.vhd, which is a more elaborate test bench.
------------------------------------------------------------------------------
-- Compile in modelsim and simulate for about 400 ns
------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
------------------------------------------------------------------------------
entity divider_tb is
end divider_tb;

------------------------------------------------------------------------------

architecture divider_RTL_tb of divider_tb is
	
	-- clock period
	
		constant clk_period: time := 20 ns;
		---------------
	-- local signals
	-- names may be chosen as <design_signal_name>_tb
		---------------
		signal xin_tb, yin_tb: std_logic_vector(3 downto 0);
		signal start_tb, ack_tb: std_logic;
		signal clk_tb, resetb_tb: std_logic;
		signal q_tb, r_tb: std_logic_vector(3 downto 0);
		signal done_tb, Qi_tb, Qc_tb, Qd_tb: std_logic;
	
		signal clock_count: integer range 0 to 9999;
		---------------
	-- component declarations
		---------------
	component divider 
	
	port	(
		xin, yin: IN std_logic_vector(3 downto 0);
		start, ack: IN  std_logic;
		clk, resetb: IN  std_logic;
		done: OUT std_logic;
		q, r: OUT std_logic_vector(3 downto 0);
		Qi, Qc, Qd: OUT std_logic -- One-hot state bits
		);
	
	end  component ;
		---------------

begin -- start of the body of the architecture

  -- component instantiations 
  -- instantiate the UUT (Unit Under Test), also called DUT (Design Under Test),
  --  and optionally any other components

  UUT: divider
	  port map(
		xin_tb, yin_tb,
		start_tb, ack_tb,
		clk_tb, resetb_tb,
		done_tb,
		q_tb, r_tb,
		Qi_tb, Qc_tb, Qd_tb
		  );
	---------------
  -- concurrent statements

	-- reset generation by a simple concurrent statement
	  resetb_tb <= '0', '1' after (clk_period * 1.1); 
	---------------
   -- processes
   ---------------
	clock_generate: process
	begin
	  clk_tb <= '0', '1' after (clk_period/2);
	  wait for clk_period;
	end process clock_generate;
   ---------------
   clock_counting: process (clk_tb, resetb_tb)
	begin
		if (resetb_tb = '0') then
		   clock_count <= 0;
		elsif clk_tb'event and clk_tb = '1' then
		   clock_count  <=  clock_count  +  1;  
		end if;
	end process clock_counting;
   ---------------	
	stim_divider: process
		---------------	

	begin
	  
	  -- Stimulus set #1 beginning ---------------
	  xin_tb <= CONV_STD_LOGIC_VECTOR(13, 4);
	  yin_tb <= CONV_STD_LOGIC_VECTOR(3, 4);
     -- see in
     -- file: /usr/usc/synopsys/default/packages/IEEE/src/std_logic_arith.vhd
     --    function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER)
	  start_tb <=  '0', '1' after (clk_period * 2.1), 
			    '0' after (clk_period * 3.1);
	  ack_tb <= '0';

	  wait until (done_tb'event and done_tb = '1');
	  wait for (clk_period * 1.1); 
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  -- Stimulus set #1 ending ------------------
	  
	  -- Stimulus set #2 beginning ---------------
	  xin_tb <= CONV_STD_LOGIC_VECTOR(11, 4);
	  yin_tb <= CONV_STD_LOGIC_VECTOR(5, 4);

	  start_tb <=  '1' after (clk_period * 1.1), 
			    '0' after (clk_period * 2.1);
	  wait until (done_tb'event and done_tb = '1');
	  wait for (clk_period * 1.1); 
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  -- Stimulus set #2 ending ------------------
	  
	  wait; -- suspend testing by waiting indefinitely

	end process stim_divider;

end divider_RTL_tb;

------------------------------------------------------------------------------