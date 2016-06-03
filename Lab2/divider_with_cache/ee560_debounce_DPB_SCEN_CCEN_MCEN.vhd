------------------------------------------------------------------------------
-- File name: ee560_debounce_DPB_SCEN_CCEN_MCEN.vhd 
-- Date: 6/10/2009, 5/10/2012 
-- (C) Copyright 2009 Gandhi Puvvada 

--------------------------------------------------------------------------------
-- Description:
-- 	A VHDL design for debouncing a Push Button (PB) and producing the following: 
-- 		(1) a debounced pulse DPB (DPB = debounced PB)
--		(2) a single clock-enable pulse (SCEN) after ~0.084 sec
--			- for single-stepping the design using a push button
--		(3) a contunuous clock-enable pulse (CCEN) after another ~0.168 sec.
-- 			- for running at full-speed
--		(4) a sequence of (multiple of) clock-enable pulses (MCEN) every ~0.084 sec 
--			- after the ~0.168 sec.
-- 
-- 	Once 'PB' is pressed, after the initial bouncing finishes in the WQ (wait quarter 
--  second) state (actually 0.084 sec), the DPB is activated, and all three  pulses
--  (SCEN, CCEN, and MCEN) are produced just for *one clock* in SCEN_state. 
-- 	Then, after waiting another half second in the WH (wait half second) state 
--  (actually 0.168 sec), the MCEN goes active for 1 clock every quarter second (every
--  0.084 sec). The CCEN goes active continuously both in the MCEN_state and the CCEN_state.
--  Finally, if the PB is released, we wait in WFCR (Wait for a Complete Release) state 
--  for a quarter second (0.084 sec) and return to the INI state. 

-- 	The  additional half-second (or 0.168sec) waiting after producing the first 
--  single-clock wide pulse allows the user	to release the button in time to avoid 
--  multi-stepping or running at full-speed even if he/she has used MCEN or CCEN 
--  in his/her design.
--
--  Please see the state diagram or read the code to understand the exact behavior.
--  In fact, the code has one extra state (MCEN_cont state),
--  which is not shown in the state diagram.
--  Try to revise the state diagram with this state and figure out the state
--  transition conditions using the four-bit counter MCEN_count.

-- 	To achieve all of this and generate glitch-free outputs (though this is not necessary),
--  let us use output coding. In output coding the state memory bits are thoughtfully 
--  chosen in order to form the needed outputs directly (with no additional combinational 
--  logic).
--	   In this case, the DPB, SCEN, MCEN, and CCEN are those outputs.  
--     However, the output combinations may repeat in different states.
--	   So we need two tie-breakers (TB1 and TB2).
--
--	State Name      State      DPB SCEN MCEN CCEN TB1  TB0
--	initial         INI         0 	0    0    0    0    0
--	wait quarter    WQ          0   0    0    0    0    1
--	SCEN_state      SCEN_St     1   1    1    1    -    -
--	wait half       WH          1   0    0    0    0    0
--	MCEN_state      MCEN_St     1   0    1    1    -    0
--	CCEN_state      CCEN_St     1   0    0    1    -    -
--	MCEN_cont       MCEN_Cont   1   0    1    1    -    1  -- <==*****
--	Counter Clear   CCR         1   0    0    0    0    1
--	WFCR_state      WFCR        1   0    0    0    1    -

--	Timers (Counters to keep time):  2**20 clocks of 10ns =  
--  = approximately 10 milliseconds = accurately 10.48576 ms
--  We found by experimentation that we press and release buttons much faster than we
--	initially thought. So, instead of quarter second, let us wait for 2**23 clocks 
--  (0.084 sec.) and instead of half second, let us wait for 2**24 clocks (0.168 seconds).
--	If we use a 25-bit counter, count(24 downto 0), and start it with 0, then the first time, 
--  count(23) goes high, we know that the lower 23 bits [count(22 downto 0)] have gone through 
--  their 2**23 combinations. So count(23) is used as the 0.084 sec timer 
-- 	and the count(24) is used as the 0.168 sec timer.

--	We will use a parameter called N_dc (dc for debounce count) in place of 25. 
--  So we use (N_dc-1 downto 0) in place of (24 downto 0]), 
--  count(N_dc-2) in place of count(23) to test 0.084 sec time, and
--  count(N_dc-1) in place of count(24) to test 0.168 sec time.
--  Simulation
--  In simulation, if we use an N_dc of 4, then (N_dc-2) and (N_dc-1) will be 2 and 3.
--  This means, we wait in the WQ state in simulation for 2**2 = 4 clocks and in WH state for 2**3 = 8 clocks.
--	Note: While 1 or 2 clocks do not make much difference in 2**23 or 2**24 clocks, they make a difference
--  in 2**2 and 2**3 clocks in simulation. So estimate mentally the repetition rate of MCEN pulses 
--  when the state machine is going through MCEN_st and CCEN_st and verify if you got it right by looking 
--  at the waveforms produced during simulation.

--	As the names say, the SCEN, MCEN, and the CCEN are clock enables and are not 
--  clocks (clock pulses) by themselves. If you use SCEN (or MCEN) as a clock by itself, 
--  then you would be creating a lot of skew as these outputs of the internal
--  state machine take ordinary routes and do not get to go on the special routes 
--  used for clock distribution on the FPGA.
--  However, when they are used as clock enables, the static timing analyzer checks 
--  timing of these signals with respect to the main clock signal (100 MHz clock) properly. 
--  This results in a good timing design.  Moreover, you can use different
--	clock enables in different parts of the control unit so that the system is 
--  single-stepped in some critical areas/states and multi-stepped or made to run at full 
--  speed in others.  This will not be possible if you try to use both SCEN and MCEN as 
--  clocks (instead of clock enables) as it will be very clumsy (if not impossible) to 
--  combine these clocks based on which part of the state machine you are currently travelling at. 
   --------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ee560_debounce_DPB_SCEN_CCEN_MCEN is
generic  (N_dc: 		positive := 23);
port     (CLK, RESETB	:in  std_logic; -- CLK = 100 MHz
		  PB		:in  std_logic; -- push button
	 	  DPB, SCEN, MCEN, CCEN	:out std_logic -- debounced PB, single_CEN, multi_CEN, continuous CEN 
		 );
end  ee560_debounce_DPB_SCEN_CCEN_MCEN ;
-------------------------------------------------------------------------------
architecture debounce_RTL of ee560_debounce_DPB_SCEN_CCEN_MCEN   is

--  Note:  The most common RTL coding in VHDL is to use symbolic names for states
--  and leave it to the synthesis tool to tie these symbolic names to encoded bit combinations.
--  Designers define a suitable enumerated state type as shown below. 
--     type debounce_state_type is (INI, WQ, SCEN_St, WH, MCEN_St, CCEN_St, CCR, WFCR);
--     signal debounce_state: 	debounce_state_type;
--  However, in this design, we would like to use output coding and we want to enforce state assignments.
--  Hence, we define constants bearing the symbolic state names and initialize them to the bit 
--  combinations of our choice.

-- By default, the synthesis tool (with default XST option "auto" for FSM encoding) will extract the state machine and will perform
attribute fsm_encoding: string;  -- Refer to XST user guide -- FSM encoding

signal debounce_state: 	std_logic_vector(5 downto 0);  -- 6-bit combination
--                                                   DPB   SCEN  MCEN  CCEN TieB1  TieB0
constant INI: 	     std_logic_vector(5 downto 0) := ('0' & '0' & '0' & '0' & '0' & '0'); 
constant WQ: 	     std_logic_vector(5 downto 0) := ('0' & '0' & '0' & '0' & '0' & '1'); 
constant SCEN_St:    std_logic_vector(5 downto 0) := ('1' & '1' & '1' & '1' & '0' & '0'); 
constant WH: 	     std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '0' & '0' & '0'); 
constant MCEN_St: 	 std_logic_vector(5 downto 0) := ('1' & '0' & '1' & '1' & '0' & '0'); 
constant CCEN_St: 	 std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '1' & '0' & '0'); 
constant MCEN_Cont:  std_logic_vector(5 downto 0) := ('1' & '0' & '1' & '1' & '0' & '1'); 
constant CCR: 	     std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '0' & '0' & '1'); 
constant WFCR: 	     std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '0' & '1' & '0'); 

attribute fsm_encoding of debounce_state: signal is "user";


-- The enumerated state type allows the display of state name in  symbolic form (ASCII form) in the waveform which is easy to read.
-- So, to provide this convenience, let us define an enumerated state signal called d_state here, and later assign values to it.
type debounce_state_type is (INI_s, WQ_s, SCEN_St_s, WH_s, MCEN_St_s, CCEN_St_s, MCEN_Cont_s, CCR_s, WFCR_s);
signal d_state: 	debounce_state_type;
 
signal debounce_count: 	std_logic_vector(N_dc-1 downto 0);
signal MCEN_count: 	std_logic_vector(3 downto 0);
-- signal DPB_int, SCEN_int, MCEN_int, CCEN_int: std_logic; -- internal signals
-- signal tie-breaker1, tie-breaker0: std_logic; -- internal signals

begin

-- concurrent signal assignment statements

(DPB, SCEN, MCEN, CCEN) <= debounce_state(5 downto 2); -- this is because of output coding

-- for the purpose of displaying in the waveform
d_state <= 	INI_s when (debounce_state = INI) else
			WQ_s when (debounce_state = WQ) else
			SCEN_St_s when (debounce_state = SCEN_St) else
			WH_s when (debounce_state = WH) else
			MCEN_St_s when (debounce_state = MCEN_St) else
			CCEN_St_s when (debounce_state = CCEN_St) else
			MCEN_Cont_s when (debounce_state = MCEN_Cont) else
			CCR_s when (debounce_state = CCR) else
			WFCR_s; --  when (debounce_state = WFCR);


debounce: process (CLK, RESETB)

        begin

          if (RESETB = '0') then

            debounce_count <= (others => 'X');
			MCEN_count <= (others => 'X');
            debounce_state <= INI;

          elsif (CLK'event and CLK = '1') then

            case debounce_state is

              when INI =>
                debounce_count <= (others => '0');
				MCEN_count <=  std_logic_vector'("0000"); -- same as MCEN_count <=  (others => '0');
				-- MCEN_count <=  "0000" ; -- also works!
                if (PB = '1') then
                  debounce_state <= WQ;
 		      end if;
	     
              when WQ =>
                debounce_count <= debounce_count + 1;
                if (PB = '0') then
                  debounce_state <= INI;
                elsif (debounce_count(N_dc-2) = '1') then 
                  debounce_state <= SCEN_St;
                end if;

              when SCEN_St =>
		        debounce_count <= (others => '0');
				MCEN_count <=  MCEN_count + '1'; -- same as MCEN_count <=  MCEN_count + 1; see overloaded function definition of "+" in std_logic_arith package
                debounce_state <= WH;

              when WH =>  
                debounce_count <= debounce_count + 1;
                if (PB = '0') then
                  debounce_state <= CCR;
                elsif (debounce_count(N_dc-1) = '1') then 
                  debounce_state <= MCEN_St;
                end if;

              when MCEN_St =>
		        debounce_count <= (others => '0');
				MCEN_count <=  MCEN_count + '1';
                debounce_state <= CCEN_St;
				
              when CCEN_St =>  
                debounce_count <= debounce_count + 1;
                if (PB = '0') then
                  debounce_state <= CCR;
                elsif (debounce_count(N_dc-2) = '1') then 
					if (MCEN_count =  std_logic_vector'("1000")) then
						debounce_state <= MCEN_Cont;
					else
						debounce_state <= MCEN_St;
					end if;
                end if;

			  when MCEN_Cont =>
				if (PB = '0') then
                  debounce_state <= CCR;
				end if;
				
              when CCR =>
				debounce_count <= (others => '0');
				MCEN_count <=  (others => '0');
                debounce_state <= WFCR;

              when others =>  -- when WFCR =>  
                debounce_count <= debounce_count + 1;
                if (PB = '1') then
                  debounce_state <= WH;
                elsif (debounce_count(N_dc-2) = '1') then 
                  debounce_state <= INI;
                end if;

              end case;

          end if;

        end process debounce;
        ----------------------------

end debounce_RTL ;
