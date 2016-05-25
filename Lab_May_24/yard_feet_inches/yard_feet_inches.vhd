------------------------------------------------------------------------------
--	A vhdl module for a divider (combined CU and DPU)

--	Written by Gandhi Puvvada  Date: 6/14/99, 12/4/99, 2/20/04, 6/3/05, 6/2/08, 6/12/09, 5/20/2012

--	File name: divider_mealy.vhd (also called divider_mealy_combined_CU_DPU.vhd)
------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-----------------------------------
entity yard_feet_inches is

--	Definition of incoming and outgoing signals.

port	(
	Inches_in: IN std_logic_vector(7 downto 0); -- initial inches
	start, ack: IN  std_logic;
	clk, resetb: IN  std_logic;
	done: OUT std_logic;
	Inches_out, Feet_out, Yards_out: OUT std_logic_vector(7 downto 0) -- quotient, remainder
	--Qi, Qc_feet, Qu_feet, Qc_yard, Qu_yard, Qd: OUT std_logic -- One-hot state bits
	);

end  yard_feet_inches ;

------------------------------------------------------------------------------

architecture yard_feet_inches_RTL of yard_feet_inches   is

-- Type declarations

type state_type is (I_STATE, C_FEET_STATE, U_FEET_STATE, C_YARD_STATE, U_YARD_STATE, DONE_STATE);
 
-- Local (internal to the model) signals declarations.

signal state: state_type;
signal Inches, Feet, Yards: std_logic_vector(7 downto 0);
--signal q_int: std_logic_vector(3 downto 0);

-- Component declarations

begin

-- concurrent signal assignment statements

  done <= '1' when (state = DONE_STATE) else '0';
  Inches_out <= Inches;
  Feet_out <= Feet;
  Yards_out <= Yards;
  -- Qi <= '1' when (state = I_STATE) else '0'; 
  -- Qc_feet <= '1' when (state = C_FEET_STATE) else '0';
  -- Qu_feet <= '1' when (state = U_FEET_STATE) else '0';
  -- Qc_yard <= '1' when (state = C_YARD_STATE) else '0';
  -- Qu_yard <= '1' when (state = U_YARD_STATE) else '0';
  -- Qd <= '1' when (state = DONE_STATE) else '0';
  -- Note that the following line causes type mismatch because the RHS is of boolean type
  -- Qd <= (state = DONE_STATE);
  
-- Component instantiations

-- processes

-- Note #1: Most designs (like this one) have a few control registers (state
-- register here) and several data registers (x, y, and q_int registers here).
-- The control registers need to be initialized during system reset to bring 
-- them to a "known desired initial state" (INITIAL_STATE here).
-- The data registers do not require any initialization using asynchronous reset.
-- For example, the general purpose registers in a CPU come up with random data.
-- Since they are never read before they are assigned to, there is no need to
-- initialize them.

-- VHDL allows modeling registers with asynchronous reset as well as
-- register with no reset at all.

-- One way to code RTL is to have two separate clocked processes,
-- CU (control unit) and DPU (data path unit) as shown in a separate file
-- divider_mealy_separate_CU_DU.vhd. The CU process uses asynchronous reset.
-- 		 	CU: process (clk, resetb)
-- The DPU process does not use reset at all.
--				DPU: process (clk)

-- While the above works, it appears that there is too much of repetition
-- of code. Also if we combine both CU and DPU in process, it may be
-- more readable.

-- The following CU_DPU process, combining the Control Unit and 
-- Data Path unit together under one clocked process, uses a simple
-- trick to avoid the unwanted recirculating multiplexers by initializing
-- the data registers to don't-cares (others => 'X').
-- Please see that the three lines of code marked with Note #1 below.

--	  if (resetb = '0') then
--	    state <= INITIAL_STATE;
--		 x <= (others => 'X');   -- <== Note #1
--		 y <= (others => 'X');   -- <== Note #1
--		 q_int <= (others => 'X');   -- <== Note #1

-- These lines tell the synthesis tools that there is no need to recirculate
-- the current values of x, y, q_int during active reset period as we do not
-- care about their contents anyway. 

-- It is a common mistake not to talk about these registers under reset
-- as that results in recirculating muxes controlled by resetb acting 
-- as data enable. Perhaps, the recirculating muxes are needed otherwise also.
-- The select line control of these muxes will be under the control of resetb and others.
-- It means that you are using extra area and also causing extra delay.
-- This mistake often goes unnoticed as the design behaves 
-- correctly anyway, even in the presence of the muxes/extra mux control.

-- The above is verified on both, the Synopsys Design Compiler (DC in short) 
-- and the Xilinx Synthesis tool (XST in short).


	CU_DPU: process (clk, resetb)

	begin

	  if (resetb = '0') then

	    state <= I_STATE;
		Inches <= (others => 'X');   -- <== Note #1
	    Feet <= (others => 'X');   -- <== Note #1
	    Yards <= (others => 'X');   -- <== Note #1
	    
	  elsif (clk'event and clk = '1') then

	    case (state) is

	      when I_STATE =>
				-- CU state transitions
				if (start = '1') then
				  state <= C_FEET_STATE;
				end if;
		      -- DPU RTL
				Inches <= Inches_in;
				Feet <= (others => '0');
				Yards <= (others => '0');

	      when C_FEET_STATE =>
				-- CU state transitions
				if (Inches < "00001100") then
					state <= U_FEET_STATE;
				elsif (Inches = "00001100") then
					if (Feet < "00000010") then
						state <= DONE_STATE;
					else
						state <= C_YARD_STATE;
					end if;
				end if;
		      -- DPU RTL
				Inches <= Inches - "00001100";
				Feet <= Feet + '1';
	      when U_FEET_STATE =>
				-- CU state transitions
				if (Feet < "00000100") then
					state <= DONE_STATE;
				else
					state <= C_YARD_STATE;
				end if; 
				-- DPU RTL
				Inches <= Inches + "00001100";
				Feet <= Feet - '1';
			when C_YARD_STATE =>
				-- CU state transitions
				if (Feet < "00000010") then
					state <= U_YARD_STATE;
				else
					state <= DONE_STATE;
				end if;
				-- DPU RTL
				Feet <= Feet - "00000011";
				Yards <= Yards + '1';
			when U_YARD_STATE =>
				-- CU state transitions
				state <= DONE_STATE;
				-- DPU RTL
				Feet <= Feet + "00000011";
				Yards <= Yards - '1';
			when DONE_STATE =>
				-- CU state transitions
				if (ack = '1') then
					state <= I_STATE;
				end if;
		 end case;
		
	  end if;

	end process CU_DPU;


end yard_feet_inches_RTL ;

------------------------------------------------------------------------------