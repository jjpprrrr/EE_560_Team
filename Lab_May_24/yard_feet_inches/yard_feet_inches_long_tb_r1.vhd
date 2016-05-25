------------------------------------------------------------------------------
--	A vhdl testbench to test the yard_feet_inches
--	
--	Written by Ammar Sheikh  Date: 5/22/2011

--	File name: yard_feet_inches_long_tb.vhd  
------------------------------------------------------------------------------
-- Compile in modelsim and simulate for 108 us.
------------------------------------------------------------------------------
-- Libraries and use clauses

library std, ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;
------------------------------------------------------------------------------
entity yard_feet_inches_tb is
end yard_feet_inches_tb;

------------------------------------------------------------------------------

architecture yard_feet_inches_RTL_tb of yard_feet_inches_tb is
	
	-- clock period
	
		constant clk_period: time := 20 ns;
		---------------
	-- local signals
	-- names may be chosen as <design_signal_name>_tb
		---------------
		signal Inches_in_tb: std_logic_vector(7 downto 0);
		signal start_tb, ack_tb: std_logic;
		signal clk_tb, resetb_tb: std_logic;
		signal Inches_out_tb, Feet_out_tb, Yards_out_tb: std_logic_vector(7 downto 0);
		signal done_tb: std_logic;
	
		signal clock_count: integer range 0 to 9999;
		---------------
	-- component declarations
		---------------
	component yard_feet_inches is
	--	Definition of incoming and outgoing signals.
	port	(
		Inches_in: IN std_logic_vector(7 downto 0);
		start, ack: IN  std_logic;
		clk, resetb: IN  std_logic;
		Inches_out, Feet_out, Yards_out: OUT std_logic_vector(7 downto 0);
		done: OUT std_logic
		);
	end  component ;
		---------------

begin -- start of the body of the architecture

  -- component instantiations 
  -- instantiate the UUT (Unit Under Test), also called DUT (Design Under Test),
  --  and optionally any other components

  UUT: yard_feet_inches
	  port map(
		Inches_in => Inches_in_tb,
		start     => start_tb,
		ack		  => ack_tb,
		clk       => clk_tb,
		resetb	  => resetb_tb,
		Inches_out => Inches_out_tb,
		Feet_out   => Feet_out_tb,
		Yards_out  => Yards_out_tb,
		done	   => done_tb
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
	stim_yard_feet_inches: process
		---------------	
		variable error_count : natural;
		
		-- file output : text open write_mode is "std_output"; -- predclared file in std_textio package
		file my_infile  : text open read_mode  is "yard_feet_inches_input_operands.txt";
		file my_outfile : text open write_mode is "yard_feet_inches_output_results.txt";
		variable my_inline, my_outline : line;
		variable integer_inches_in, integer_inches_out, integer_feet_out, integer_yards_out : natural;
		variable integer_Inches_out_tb, integer_Feet_out_tb, integer_Yards_out_tb :  natural;
		variable outmsg12 : string(1 to 13) := (others => ' ');
		variable outmsg14 : string(1 to 15) := (others => ' ');
		
	--  declaration of functions and procedures
		---------------
	-- stimulus application procedure:
		procedure compute_with_this_operand  (inches_in: in natural) is
			variable inches, feet, yards : natural;
			
		begin 
			  wait until (clk_tb'event and clk_tb = '1'); -- wait for the edge
			  -- The above line helps to see that we do not accumulate delays such as (clk_period * 0.1)
			  -- when this procedure is called repetitively.
			  wait for (clk_period * 0.1); -- wait a little
			  Inches_in_tb <= CONV_STD_LOGIC_VECTOR(inches_in, 8);
		
			  start_tb <=  '1' after (clk_period * 1.1), 
						 '0' after (clk_period * 2.1);
			  wait until (done_tb'event and done_tb = '1');
			  -- let us independently compute the results
			  inches := inches_in; feet := 0; yards := 0;
			  while (inches >= 12) loop
				inches := inches - 12;
				feet   := feet   + 1;
				while (feet >= 3) loop
					feet  := feet  - 3;
					yards := yards + 1;
				end loop;
			  end loop;

			  integer_Inches_out_tb := CONV_INTEGER (UNSIGNED(Inches_out_tb));
			  integer_Feet_out_tb   := CONV_INTEGER (UNSIGNED(Feet_out_tb));
			  integer_Yards_out_tb   := CONV_INTEGER (UNSIGNED(Yards_out_tb));
			  -- We can avoid the conversion function CONV_STD_LOGIC_VECTOR
			  -- below as we have integer versions of Inches_out_tb.
			  -- I just wanted to show that we can convert either way.
			  assert (Inches_out_tb = CONV_STD_LOGIC_VECTOR(inches, 8))
				 report "Inches out error!"
				 severity note;
			  assert (integer_Feet_out_tb = feet)
				 report "Feet out error!"
				 severity note;
			  assert (integer_Yards_out_tb = yards)
				 report "yards out error!"
				 severity note;
			  if ( (integer_Inches_out_tb /= inches) or 
			       (integer_Feet_out_tb   /= feet)   or
				   (integer_Yards_out_tb  /= yards)) then
					error_count := error_count  + 1;
			  end if;
			  wait until (clk_tb'event and clk_tb = '1'); -- wait for the edge
			  wait for (clk_period * 0.1); -- wait a little
			  ack_tb <= '1', '0' after (clk_period * 1.1);
			  
		end procedure compute_with_this_operand;
		---------------

	begin
	  
	  -- Stimulus set #1 beginning ---------------
	  Inches_in_tb <= CONV_STD_LOGIC_VECTOR(13, 8);
     -- see in
     -- file: /usr/usc/synopsys/default/packages/IEEE/src/std_logic_arith.vhd
     --    function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER)
	  wait until (clk_tb'event and clk_tb = '1'); -- wait for the edge
	  start_tb <=  '0', '1' after (clk_period * 2.1), 
			    '0' after (clk_period * 3.1);
	  ack_tb <= '0';

	  wait until (done_tb'event and done_tb = '1');
	  wait for (clk_period * 1.1); 
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  -- Stimulus set #1 ending ------------------
	  
	  -- Stimulus set #2 beginning ---------------
	  Inches_in_tb <= CONV_STD_LOGIC_VECTOR(62, 8);
	  wait until (clk_tb'event and clk_tb = '1'); -- wait for the edge
	  start_tb <=  '1' after (clk_period * 1.1), 
			    '0' after (clk_period * 2.1);
	  wait until (done_tb'event and done_tb = '1');
	  wait for (clk_period * 1.1); 
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  -- Stimulus set #2 ending ------------------
	  
	  -- Stimulus set #3 beginning ---------------
	  Inches_in_tb <= CONV_STD_LOGIC_VECTOR(36, 8);
	  wait until (clk_tb'event and clk_tb = '1'); -- wait for the edge
	  start_tb <=  '1' after (clk_period * 1.1), 
			    '0' after (clk_period * 2.1);
	  wait until (done_tb'event and done_tb = '1');
	  wait for (clk_period * 1.1); 
	  ack_tb <= '1', '0' after (clk_period * 1.1);
	  -- Stimulus set #3 ending ------------------

	  -- it would be better, if we used a stimulus procedure for the above 7 
	  -- lines, and invoked the procedure as shown below.
	  compute_with_this_operand (12);
	  
	  -- To test this divider exhaustively we can invoke the procedure in a loop
	  error_count := 0;
	  outer_compute_loop: for my_inches in 0 to 127 loop

			compute_with_this_operand (my_inches);

	  end loop outer_compute_loop;
	  
	  if (error_count /= 0) then
	    assert false
	     report ("Exhaustive testing completed, but there were " & integer'image(error_count) & " errors!")
		  severity note;
	  else
	    assert false
	     report ("Exhaustive testing completed! Congratulations! No errors! error count is " & integer'image(error_count))
		  severity note;
	  end if;
	  
	  -- To show text_i/o, we will perform a few more tests. 
	  -- We will read the input operands from a file named "divider_input_operands.txt" 
	  -- and write results to a file named "divider_output_results.txt".
	  -- We can also display the results to the simulation window (std_output with logical name output) 
	  my_textio_loop: while not endfile (my_infile) loop

		  readline (my_infile, my_inline);
		  read (my_inline, integer_inches_in);

		  compute_with_this_operand (integer_inches_in);

		  outmsg12 := " Inches In = ";
						--	123456789012
		  write (my_outline, outmsg12);
		  write (my_outline, integer_inches_in, right, 2); -- right justified, 2 character wide
		  -- outmsg12 := "; Inches Out = ";
						--	123456789012
		  -- write (my_outline, outmsg12);
		  -- another way of writing the above two commented-out lines using a single line is shown below. 
		  -- This method makes it easy as we need not count the exact number of characters.
		  write (my_outline, string'("; Inches Out = "));
		  write (my_outline, integer_Inches_out_tb, right, 2); -- right justified, 2 character wide
		  outmsg14 := "; Feet Out   = ";
						--	12345678901234
		  write (my_outline, outmsg14);
		  write (my_outline, integer_Feet_out_tb, right, 2); -- right justified, 2 character wide
		  outmsg14 := "; Yards Out  = ";
						--	12345678901234
		  write (my_outline, outmsg14);
		  write (my_outline, integer_Yards_out_tb, right, 2); -- right justified, 2 character wide
		  writeline (my_outfile, my_outline); 
			-- In VHDL the line becomes empty after it is used to write into a file.
			-- You need to reconstruct the line again if you want to send it to another file
			-- The above is a formatted text with right-justfied numbers with field width of 2. 
			-- The one below is not formatted (not alligned).
		  outmsg12 := " Inches In = ";
						--	123456789012
		  write (my_outline, outmsg12);
		  write (my_outline, integer_inches_in);
		  write (my_outline, string'("; Inches Out = "));
						--	123456789012
		  write (my_outline, integer_Inches_out_tb);
		  outmsg14 := "; Feet Out   = ";
						--	12345678901234
		  write (my_outline, outmsg14);
		  write (my_outline, integer_Feet_out_tb);
		  outmsg14 := "; Yards Out  = ";
						--	12345678901234
		  write (my_outline, outmsg14);
		  write (my_outline, integer_Yards_out_tb);
		  writeline (output, my_outline); -- write to std_output (i.e. the simulation window)
	  
	  end loop my_textio_loop;
	  
	  write (my_outline, string'("All testing completed.")); 
	  writeline (output, my_outline); -- write to std_output (i.e. the simulation window)
	  write (my_outline, string'("Suspending testing by waiting indefinitely!"));
	  writeline (output, my_outline); -- write to std_output (i.e. the simulation window)
	  wait; -- suspend testing by waiting indefinitely

	end process stim_yard_feet_inches;

end yard_feet_inches_RTL_tb;

------------------------------------------------------------------------------