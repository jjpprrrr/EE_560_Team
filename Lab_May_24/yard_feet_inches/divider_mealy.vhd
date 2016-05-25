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
entity divider is

--	Definition of incoming and outgoing signals.

port	(
	xin, yin: IN std_logic_vector(3 downto 0); -- dividend, divisor
	start, ack: IN  std_logic;
	clk, resetb: IN  std_logic;
	done: OUT std_logic;
	q, r: OUT std_logic_vector(3 downto 0); -- quotient, remainder
	Qi, Qc, Qd: OUT std_logic -- One-hot state bits
	);

end  divider ;

------------------------------------------------------------------------------

architecture divider_RTL of divider   is

-- Type declarations

type state_type is (INITIAL_STATE, COMPUTE_STATE, DONE_STATE);
 
-- Local (internal to the model) signals declarations.

signal state: state_type;
signal x, y: std_logic_vector(3 downto 0);
signal q_int: std_logic_vector(3 downto 0);

-- Component declarations

begin

-- concurrent signal assignment statements

  done <= '1' when (state = DONE_STATE) else '0';
  q <= q_int;
  r <= x;
  Qi <= '1' when (state = INITIAL_STATE) else '0'; 
  Qc <= '1' when (state = COMPUTE_STATE) else '0';
  Qd <= '1' when (state = DONE_STATE) else '0';
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

	    state <= INITIAL_STATE;
		x <= (others => 'X');   -- <== Note #1
	    y <= (others => 'X');   -- <== Note #1
	    q_int <= (others => 'X');   -- <== Note #1
	    
	  elsif (clk'event and clk = '1') then

	    case (state) is

	      when INITIAL_STATE =>
				-- CU state transitions
				if (start = '1') then
				  state <= COMPUTE_STATE;
				end if;
		      -- DPU RTL
				x <= xin;
				y <= yin;
				q_int <= "0000";

	      when COMPUTE_STATE =>
		      -- DPU RTL
				if (x >= y) then
				  -- state <= COMPUTE_STATE;  -- unnecessary
				    -- The above statement is not necessary
				    -- but may be included for better readability
				  x <= x - y;
				  q_int <= q_int + '1'; -- overloaded definition of +
					-- function "+"(L: STD_LOGIC_VECTOR; R: STD_LOGIC) return 
					-- STD_LOGIC_VECTOR. Please refer to  the package 
					-- std_logic_unsigned.vhd for this function.
					-- file: /usr/usc/synopsys/default/packages/IEEE/src/std_logic_unsigned.vhd
					-- file: /usr/usc/modelsim/default/modeltech/vhdl_src/synopsys/mti_std_logic_unsigned.vhd
					-- file: C:\<Xilinx_Installation_Directory_such_as_Xilinx/10.1>\ise\vhdl\src\ieee\std_logic_unsigned.vhd
					-- file: C:\Modeltech_xe_starter\xilinx\vhdl\src\ieee\std_logic_unsigned.vhd
				-- CU state transitions
				else
				  state <= DONE_STATE;
				end if; 

	      when DONE_STATE =>
				-- CU state transitions
				if (ack = '1') then
				  state <= INITIAL_STATE;
				end if; 
		      -- DPU RTL
				-- no RTL in DONE_STATE
		 end case;
		
	  end if;

	end process CU_DPU;


end divider_RTL ;

------------------------------------------------------------------------------