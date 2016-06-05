------------------------------------------------------------------------------
--	A vhdl testbench to test the divider_timing_top design after
--	it has been synthesized/implemented (and back-annotated with timing
--  information through .sdf file during simulation).
--	Written by Gandhi Puvvada  Date: 6/1/2009

--	File name: divider_timing_top_tb.vhd  (based on divider_timing_tb.vhd and divider_mealy_tb.vhd)

--  coding plan: 
--         Basically the divider_timing_tb.vhd applies stimulus to divider_timing.vhd,
--         and divider_timing_top.vhd maps the switches, butons and LEDs to inputs and outputs
--         of the divider_timing.vhd.
--         Now, the divider_timing_top_tb.vhd does the same thing as the divider_timing_tb.vhd,
--         except that the stimulus such as "start_tb" is applied to "btn1" rather than "start".
--
------------------------------------------------------------------------------
--  Important note #1: The top instance shall be UUT only (and not divder_top_1 or any such name)
--                     as Xilinx SDF annotation assumes that we named the instance as UUT.
--
--  Important note #2: Do not compile this in modelsim separately and simulate this as we want the 
--                     timing information (.sdf file) generated by the xilinx XST.
--                     So, in Xilinx WebPACK/ISE, 
--                            1. select "Post-Route Simulation" under "Sources for"
--                            2. select divider_timing_top_tb in the Sources pane
--                            3. click on "Simulate Post-Place & Route Model" 
--                                    under "ModelSim Simulator" under "Processes" pane.
--                     This will cause generation of the .sdf file and then invoking the 
--                     ModelSim tool using a .tdo file linking the .sdf file with the simulation 
------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
------------------------------------------------------------------------------
entity divider_timing_top_tb is
end divider_timing_top_tb;

------------------------------------------------------------------------------

architecture divider_RTL_tb of divider_timing_top_tb is
	
	-- clock period
	
		constant clk_period: time := 20 ns;
		---------------
	-- local signals
	-- names may be chosen as <design_signal_name>_tb
		---------------
		signal xin_tb, yin_tb: std_logic_vector(7 downto 0);
		signal start_tb, ack_tb: std_logic;
		signal dummy_tb: std_logic;
		signal clk_tb, resetb_tb, resetb_tb_complement: std_logic;
		signal q_tb, r_tb: std_logic_vector(7 downto 0);
		-- signal done_tb: std_logic;
	
		signal clock_count: integer range 0 to 9999;
		---------------
	-- component declarations
		---------------
component divider_top is

port	(ClkPort:  in std_logic;
	    sw0, sw1, sw2, sw3, sw4, sw5, sw6, sw7, sw8, sw9, sw10, sw11, sw12, sw13, sw14, sw15: in std_logic;
		 BtnL, BtnR, BtnC: in std_logic;	             -- the Left, Up, Right, Down, and Center buttons
	    LD15, LD14, LD13, LD12, LD11, LD10, LD9, LD8, LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0: out std_logic; -- LD(7-4) indicate the quotient, LD(3-0) indicate remainder
	    ca, cb, cc, cd, ce, cf, cg, dp: out std_logic;
	    AN0, AN1, AN2, AN3: out std_logic
	    --MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS : out std_logic -- Nexys3
		);
end component divider_top ;
		---------------

begin -- start of the body of the architecture

  -- component instantiations 
  -- instantiate the UUT (Unit Under Test), also called DUT (Design Under Test),
  --  and optionally any other components

  UUT: divider_top
	  port map(
	  clkport => clk_tb, 
		sw0 => yin_tb(0),  sw1 => yin_tb(1), sw2 => yin_tb(2), sw3 => yin_tb(3), 
		sw4 => yin_tb(4),  sw5 => yin_tb(5), sw6 => yin_tb(6), sw7 => yin_tb(7),
		sw8 => xin_tb(0),  sw9 => xin_tb(1), sw10 => xin_tb(2), sw11 => xin_tb(3), 
		sw12 => xin_tb(4),  sw13 => xin_tb(5), sw14 => xin_tb(6), sw15 => xin_tb(7),		
		BtnC => resetb_tb_complement, 
		BtnL =>  start_tb, BtnR =>  ack_tb,
		LD15 => q_tb(7), LD14 => q_tb(6), LD13 => q_tb(5), LD12 => q_tb(4), 
		LD11 => q_tb(3), LD10 => q_tb(2), LD9 => q_tb(1), LD8 => q_tb(0),
		LD7 => r_tb(7), LD6 => r_tb(6), LD5 => r_tb(5), LD4 => r_tb(4), 
		LD3 => r_tb(3), LD2 => r_tb(2), LD1 => r_tb(1), LD0 => r_tb(0),
		AN0 => dummy_tb, AN1 => dummy_tb, AN2 => dummy_tb, AN3 => dummy_tb
	    --MemOE => dummy_tb, MemWR => dummy_tb, RamCS => dummy_tb, FlashCS => dummy_tb, QuadSpiFlashCS => dummy_tb
		);
	---------------
  -- concurrent statements

	-- reset generation by a simple concurrent statement
	  resetb_tb <= '0', '1' after (clk_period * 10.1); 
	  resetb_tb_complement <= not resetb_tb;
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
	  xin_tb <= CONV_STD_LOGIC_VECTOR(13, 8);
	  yin_tb <= CONV_STD_LOGIC_VECTOR(3, 8);
	  start_tb <=  '0';	  ack_tb <= '0';
     -- see in
     -- file: /usr/usc/synopsys/default/packages/IEEE/src/std_logic_arith.vhd
     --    function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER)
	 wait for (clk_period *16); -- for reset to be over in harware
	  start_tb <=  '0', '1' after (clk_period * 2.1), 
			    '0' after (clk_period * 3.1);
	  wait for (clk_period *1); -- to let the start_tb to cycle through
      -- Since "done" is not brought to the top, we replace
	  -- the following line in earlier testbench with a wait for 16 clocks
	  -- wait until (done_tb'event and done_tb = '1');  
	  wait for (clk_period * 16.1);  -- wait for the computation to finish
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  wait for (clk_period *1);  -- to let the ack-tb to cycle through
	  -- Stimulus set #1 ending ------------------
	  
	  -- Stimulus set #2 beginning ---------------
	  xin_tb <= CONV_STD_LOGIC_VECTOR(11, 8);
	  yin_tb <= CONV_STD_LOGIC_VECTOR(5, 8);

	  start_tb <=  '1', 
			    '0' after (clk_period * 1.1);
	  wait for (clk_period *1); -- to let the start_tb to cycle through
	  wait for (clk_period * 16.1); -- wait for the computation to finish
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  wait for (clk_period *1);  -- to let the ack-tb to cycle through
	  -- Stimulus set #2 ending ------------------

	  -- Stimulus set #3 beginning ---------------
	  xin_tb <= CONV_STD_LOGIC_VECTOR(7, 8);
	  yin_tb <= CONV_STD_LOGIC_VECTOR(7, 8);

	  start_tb <=  '1', 
			    '0' after (clk_period * 1.1);
	  wait for (clk_period *1); -- to let the start_tb to cycle through
	  wait for (clk_period * 16.1); -- wait for the computation to finish
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  wait for (clk_period *1);  -- to let the ack-tb to cycle through
	  -- Stimulus set #3 ending ------------------	  

	  -- Stimulus set #4 beginning ---------------
	  xin_tb <= CONV_STD_LOGIC_VECTOR(15, 8);
	  yin_tb <= CONV_STD_LOGIC_VECTOR(1, 8);

	  start_tb <=  '1', 
			    '0' after (clk_period * 1.1);
	  wait for (clk_period *1); -- to let the start_tb to cycle through
	  wait for (clk_period * 16.1); -- wait for the computation to finish
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  wait for (clk_period *1);  -- to let the ack-tb to cycle through
	  -- Stimulus set #4 ending ------------------	  
	  

	 wait; -- suspend testing by waiting indefinitely

	end process stim_divider;

end divider_RTL_tb;

------------------------------------------------------------------------------