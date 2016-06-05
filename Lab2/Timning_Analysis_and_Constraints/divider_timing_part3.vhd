------------------------------------------------------------------------------
--	A vhdl module for a divider (combined CU and DPU)

--	Written by Gandhi Puvvada  Date: 6/14/99, 12/4/99, 2/20/04, 6/3/05, 6/2/08

--	File name: divider_mealy_combined_CU_DPU.vhd
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
	xin, yin: IN std_logic_vector(7 downto 0); -- dividend, divisor
	start, ack: IN  std_logic;
	clk, resetb: IN  std_logic;
	q, r: OUT std_logic_vector(7 downto 0);
	done: OUT std_logic
	);
end divider ;

------------------------------------------------------------------------------

architecture divider_RTL of divider   is

-- Type declarations

type state_type is (INITIAL_STATE, COMPUTE_STATE, DONE_STATE);
 
-- Local (internal to the model) signals declarations.

signal state: state_type;
signal x, y: std_logic_vector(7 downto 0);
signal q_int: std_logic_vector(7 downto 0);

-- Component declarations

begin

-- concurrent signal assignment statements

  done <= '1' when (state = DONE_STATE) else '0';
  q <= q_int;
  r <= x;

-- Component instantiations

-- processes

-- Note #1: Most designs (like this one) have a few control registers (state
-- register here) and several data registers (z, y, and q_int registers here).
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
-- divider_mealy_separate_CU_DU.vhd. The CU process uses aynchronous reset.
-- 		 	CU: process (clk, resetb)
-- The DPU process does not use reset at all.
--				DPU: process (clk)

-- While the above works, it appears that there is too much of repetition
-- of code. Also if we combine both CU and DPU in process, it may be
-- more readable.

-- The following CU_DPU process, combining the Control Unit and 
--	Data Path unit together under one clocked process, uses a simple
-- trick to avoid the unwanted recirculating multiplexers by initializing
-- the data registers to don't-cares (others => 'X').
-- Please see that the three lines of code marked with Note #1 below.

--	  if (resetb = '0') then
--	    state <= INITIAL_STATE;
--		 x <= (others => 'X');   -- <== Note #1
--	    y <= (others => 'X');   -- <== Note #1
--	    q_int <= (others => 'X');   -- <== Note #1

-- These lines tell the synthesis tools that there is no need to recirculate
-- the current values of x, y, q_int during active reset period as we do not
-- care about their contents anyway. 

-- It is a common mistake not to talk about these registers under reset
-- as that results in the recirculating muxes controlled by resetb acting 
-- as data enable. This mistake goes un-noticed as the design behaves 
-- correctly anyway, even in the presence of the muxes.

-- We tried synthesizing this design with the three lines marked with
-- "Note #1" commented out. Both, the Synopsys Design Compiler (DC in short) 
-- and the Xilinx Synthesis tool (XST in short), have created 
-- a Data Enable for each of these registers (by placing a recirculating mux 
-- infront of each of them and having the resetb control the selection of the data). 
-- i.e. If resetb = '0', then it results in recirculating current values.
-- This is not our intent. Extra area is used for this unnecessary logic.
-- Extra delay is created because of this recirculating mux.


	CU_DPU: process (clk, resetb)
	variable x_temp : std_logic_vector(7 downto 0);
	variable q_int_temp : std_logic_vector(7 downto 0);
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
				q_int <= "00000000";
				x_temp := x;
				q_int_temp := q_int;

	      when COMPUTE_STATE =>
		      -- DPU RTL
				for i in 0 to 5 loop
					if (x_temp >= y) then
					  -- state <= COMPUTE_STATE; 
					  -- The above statement is not necessary
					  -- but may be included for better readability
					  x_temp := x_temp - y;
					  q_int_temp := q_int_temp + '1'; -- overloaded definition of +
						-- function "+"(L: STD_LOGIC_VECTOR; R: STD_LOGIC) return 
						-- STD_LOGIC_VECTOR. Please refer to  the package 
						-- std_logic_unsigned.vhd for this function.
						-- file: /usr/usc/synopsys/default/packages/IEEE/src/std_logic_unsigned.vhd
						-- file: /usr/usc/modelsim/default/modeltech/vhdl_src/synopsys/mti_std_logic_unsigned.vhd
						-- file: /usr/usc/
						-- file: C:\<Xilinx_Installation_Directory_such_as_Xilinx91i>\vhdl\src\ieee\std_logic_unsigned.vhd
						-- file: C:\Modeltech_xe_starter\xilinx\vhdl\src\ieee\std_logic_unsigned.vhd
					-- CU state transitions
					else
					  state <= DONE_STATE;
					end if; 
				end loop;
				x <= x_temp;
				q_int <= q_int_temp;
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
