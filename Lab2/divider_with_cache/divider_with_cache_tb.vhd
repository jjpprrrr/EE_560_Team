------------------------------------------------------------------------------
--      A vhdl testbench to test the divider_timing
--      
--      File name: divider_with_cache_tb.vhd  
--      June 2008 -- Designed by Srinivas Vaduvatha
-- 		6/12/2010 -- modified by Gandhi Puvvada to include 
--						MCEN (multi-stepping)
--						a procedure for conductin tests repetitively
-- 						text I/O to report of clocks_taken 
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use STD.textio.all;
------------------------------------------------------------------------------
entity divider_with_cache_tb is
end divider_with_cache_tb;

------------------------------------------------------------------------------

architecture divider_with_cache_RTL_tb of divider_with_cache_tb is

  -- clock period
  
  constant clk_period        : time := 20 ns;
  ---------------
  -- local signals
  -- names may be chosen as <design_signal_name>_tb
  ---------------
  signal   xin_tb, yin_tb    : std_logic_vector(7 downto 0);
  signal   start_tb, ack_tb  : std_logic;
  signal   clk_tb, resetb_tb, MCEN_tb : std_logic; -- MCEN = multi-step clock enable
  signal   q_tb, r_tb, clocks_taken_tb   : std_logic_vector(7 downto 0);
  signal   INITIAL_ST_tb, CACHE_CHECK_ST_tb, COMPUTE_ST_tb, DONE_CALC_ST_tb, DONE_CACHE_HIT_ST_tb : std_logic;
  signal   done_tb           : std_logic;

  signal clock_count : integer range 0 to 9999;
  signal test_num: integer range 0 to 100;
  ---------------
  -- component declarations
  ---------------
  component divider_with_cache
    
    port(
      xin, yin    : in  std_logic_vector(7 downto 0);
      start, ack  : in  std_logic;
      clk, resetb, MCEN : in  std_logic;
      q, r, clocks_taken  : out std_logic_vector(7 downto 0);
	  INITIAL_ST, CACHE_CHECK_ST, COMPUTE_ST, DONE_CALC_ST, DONE_CACHE_HIT_ST : OUT std_logic;
      done        : out std_logic
      );

  end component;
  ---------------

begin  -- start of the body of the architecture

  -- component instantiations 
  -- instantiate the UUT (Unit Under Test), also called DUT (Design Under Test),
  --  and optionally any other components

  UUT : divider_with_cache
    port map(
      xin_tb, yin_tb,
      start_tb, ack_tb,
      clk_tb, resetb_tb, MCEN_tb,
      q_tb, r_tb, clocks_taken_tb,
	  INITIAL_ST_tb, CACHE_CHECK_ST_tb, COMPUTE_ST_tb, DONE_CALC_ST_tb, DONE_CACHE_HIT_ST_tb,
      done_tb
      );
  ---------------
  -- concurrent statements

  MCEN_tb  <= '1'; -- for simulation, the MCEN_tb (multi-step clock enable) is active all the time
  
  -- reset generation by a simple concurrent statement
  resetb_tb <= '0', '1' after (clk_period * 1.1);
  ---------------
  -- processes
  ---------------
  clock_generate : process
  begin
    clk_tb <= '0', '1' after (clk_period/2);
    wait for clk_period;
  end process clock_generate;
  ---------------
  clock_counting : process (clk_tb, resetb_tb)
  begin
    if (resetb_tb = '0') then
      clock_count <= 0;
    elsif clk_tb'event and clk_tb = '1' then
      clock_count <= clock_count + 1;
    end if;
  end process clock_counting;
  
  	-- process to apply the stimulus to the UUT (Unit Under Test)
	Stim_divider_with_cache: process
		file out_file : TEXT open WRITE_MODE is "divider_with_cache_output_results.txt" ;
		variable out_line: line;
		
		-- procedure to apply the input values and write the output results in a file.
		procedure apply_test (constant xin_value, yin_value: in integer) is
			begin
				xin_tb <= CONV_STD_LOGIC_VECTOR(xin_value, 8); --convert the integer value to STD_LOGIC_VECTOR type
				yin_tb <= CONV_STD_LOGIC_VECTOR(yin_value, 8); --convert the integer value to STD_LOGIC_VECTOR type
				test_num <= test_num + 1;
				wait until clk_tb'event and clk_tb = '1';
				wait for 3 ns; -- wait for a little after the clock edge
				start_tb <=  '1',  '0' after (clk_period * 1);
				wait until clk_tb'event and clk_tb = '1';
				wait for 1 ns; -- wait for a little after the clock edge
				wait until (done_tb'event and done_tb = '1'); -- wait for the state machine to produce DONE 
				wait for 1 ns; -- wait for a little after the clock edge
				wait until clk_tb'event and clk_tb = '1';
				wait for 3 ns; -- wait for a little after the clock edge	  

				-- Series of statements to write the output result in a file

				WRITE(out_line, string'("Test #"));
				WRITE(out_line, test_num);
				WRITELINE(out_file, out_line);
				
				if (DONE_CALC_ST_tb = '1') then
				WRITE(out_line, string'("Cache Miss occured."));
				elsif (DONE_CACHE_HIT_ST_tb = '1') then
				WRITE(out_line, string'("Cache Hit occured."));
				else
				WRITE(out_line, string'("Divider seems to have rerached an unknown state."));
				end if;
				WRITELINE(out_file, out_line);
				
				WRITE(out_line, string'("xin = "));
				WRITE(out_line, xin_value);
				WRITE(out_line, string'(", yin = "));
				WRITE(out_line, yin_value);
				WRITE(out_line, string'(", quotient = "));
				WRITE(out_line, CONV_INTEGER(unsigned(q_tb)));
				WRITE(out_line, string'(", remainder = "));
				WRITE(out_line, CONV_INTEGER(unsigned(r_tb)));
				WRITELINE(out_file, out_line);

				WRITE(out_line, string'("Number of Clocks taken = "));
				WRITE(out_line, CONV_INTEGER(unsigned(clocks_taken_tb)));
				WRITELINE(out_file, out_line);
				WRITE(out_line , ' '); -- blank line
				WRITELINE(out_file, out_line);
				ack_tb <= '1', '0' after (clk_period * 1); -- apply acknowledge signal
				wait for (clk_period *1);
		end procedure apply_test;
	begin
		-- initial values
		xin_tb <= CONV_STD_LOGIC_VECTOR(1, 8);
		yin_tb <= CONV_STD_LOGIC_VECTOR(1, 8);
		start_tb <=  '0';
		ack_tb <= '0';
		test_num <= 0;
		
		wait for (clk_period *2); -- waiting for reset to be applied
		
		apply_test ( 88,  8); -- Test #1
		apply_test ( 40,  4); -- Test #2
		apply_test (255, 64); -- Test #3
		apply_test (254, 64); -- Test #4
		apply_test (253, 64); -- Test #5
		apply_test (252, 64); -- Test #6
		apply_test ( 40,  4); -- Test #7 -- <== results in a hit
		apply_test (251, 64); -- Test #8
		apply_test (250, 64); -- Test #9 -- <== after this cache is full 
		apply_test (128, 32); -- Test #10 -- <== replaces the LRU entry ( 88,  8)
		apply_test ( 88,  8); -- Test #11 -- <== replaces the LRU entry (255, 64)
		apply_test (255, 64); -- Test #12 -- <== results in a hit
		apply_test ( 88,  8); -- Test #11 -- <== results in a hit
		
		WRITE(out_line , string'("All tests concluded."));
		WRITELINE(out_file, out_line);
		WRITE(out_line , string'("All tests concluded. Inspect your divider_with_cache_output_results.txt"));
		WRITELINE(output, out_line); -- to standard output (simulation console window)
		
		wait;
	
	end process Stim_divider_with_cache;

  ---------------       

end divider_with_cache_RTL_tb;

------------------------------------------------------------------------------
