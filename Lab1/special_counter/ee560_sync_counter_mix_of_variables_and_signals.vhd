-- File: ee560_sync_counter_mix_of_variables_and_signals.vhd (based on ee201L_sync_counter_mix_of_blocking_and_non_blocking.v)
-- Gandhi Puvvada 3/10/2009, 11/22/2010, 4/10/2011, 9/4/2011, 6/17/2012

-- This code is written to show the need for variables and variable assignments in
-- producing the next count value, if this next count value is
-- rather strangely computed.
-----------------------------------------------------------------------------
-- This problem is clearly a made-up problem to make the computation of the
-- next count (Q_next) fairly complicated, necessitating the use of variable
-- assignments and progressive computation in the next-state logic (logic
-- upstream to the count register).

-- It is a truncated 5-bit UP counter. It counts from 0 to 20 and rolls back to zero.
-- It has a synchronous clear control (clr), a load control and a count-enable (en) control
-- as before. In addition, it has a special JUMP control and it is defined as follows.
-- The order of priority is clear (clr), load, jump, and finally enable.

-- Suppose clear and load are deasserted and JUMP is asserted. Then count-enable is a dont care.
-- When the JUMP is asserted, the counter should jump to the midpoint M or a little
-- beyond the midpoint M as detailed below. The midpoint M is middle point between
-- the current count and 20 (the highest value).
-- Example: current count is 12. Distance from 20 is 8. Half is 4.
-- So the midpoint M is at 16 (12+4 = 16).
-- But what if the difference is an ODD number. Then you need to jump by
-- either the "floor" or the "ceiling" of the half of the difference depending
-- on whether the difference is less than ten or more than ten respectively.
-- Mr. Bruin: What if the difference is 10?
-- Mr. Trojan: Well then the question of "floor" or "ceiling" does not arise!
-- Miss Bruin: You also said, "or a little beyond the midpoint M".
-- Mr. Trojan: Yes, yes, I was about to tell and was interrupted by Mr. Bruin.
-- After calculating the midpoint M, a bonus to the jump by a constant of 4 is allowed
-- if this bonus addition does not cause wrapping around (due to going beyond 20).

-- To do the above we need to find the difference from 20 using a variable assignment
-- so that (there is no delta-T delay and) we can use the same to find if it is ODD,
-- and if so, if it is greater than or less than 10. And also find the floor or
-- ceiling of half of the difference. We copy the current count Q into a variable Q_next
-- and apply this midpoint jump to the Q_next using variable assignments. Then we should
-- check to see that this is at least 4 or more away from 20 before applying the extra bonus of 4.
-- Finally the value gathered in Q_next shall be conveyed to Q using signal assignment.

-- JUMP has higher priority over enable (en). And suppose clear and load are inactive.
-- So if JUMP is true, and if the current count is 19,
-- it will end up remaining at 19 (because of the floor rule and no bonus rule).
-- And if JUMP is true, and if the current count is 20,
-- it will end up remaining at 20.
-----------------------------------------------------------------------------
-- Besides variable and signal assignments, we demonstrate through this example,
-- another basic fact in the sequential language portion of an HDL coding.
-- A later assignment to the same variable over-rides an earlier assignment.
-----------------------------------------------------------------------------
   -- Recommendations to remember: Use intermediate variables such as "diff" and "Q_next"
   -- to compute and further compute the needed values using variable assignments.
   -- It is not necessary to assign to the final Q only once. You can assign the most common
   -- value (the default value), and if needed over-ride this default assignment with a new
   -- assignment.
   -- All physical registers should be assigned using signal assignments only.
   -- While physical registers are inferred when a variable is accessed before it is assigned
   -- in a clocked process, we should not use this side-effect to infer registers.
-----------------------------------------------------------------------------
-- Table showing current Q and Q_next when JUMP = '1' i.e. ((en = 'X') and (jump = '1') and (load = '0') and (clr = '0')) .
	 -- Q		increase		Q_next
	 -- 0		10+4 = 14		14
	 -- 1		10+4 = 14		15
	 -- 2		 9+4 = 13		15
	 -- 3		 9+4 = 13		16
	 -- 4		 8+4 = 12		16
	 -- 5		 8+4 = 12		17
	 -- 6		 7+4 = 11		17
	 -- 7		 7+4 = 11		18
	 -- 8		 6+4 = 10		18
	 -- 9		 6+4 = 10		19
	-- 10		 5+4 =  9		19
	-- 11		 4+4 =  8		19
	-- 12		 4+4 =  8		20
	-- 13		 3+4 =  7  		20
	-- 14 		 3+0 =  3		17
	-- 15    	 2+0 =  2 		17
	-- 16		 2+0 =  2 		18
	-- 17		 1+0 =  1 		18
	-- 18 		 1+0 =  1 		19
	-- 19 		 0+0 =  0 		19
	-- 20 		 0+0 =  0 		20
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ee560_sync_counter_with_jump is
	port (	clk, clr, load, jump, en: in std_logic;
			BA: in std_logic_vector(4 downto 0); -- Branch Address (load value)
			Q: out std_logic_vector(4 downto 0)
		 );
end entity ee560_sync_counter_with_jump;

architecture RTL of ee560_sync_counter_with_jump is
-- synthesis translate_off
type Operation_type is (clear, branch, jmp, inc, stay, unkn); -- An enumerated type for displaying the on going operation in text mode in the waveform -- notice that we can not use the signal name clr for one of the enumerated type values, so we named it clear, similarly branch for load, and jmp for jump
signal Operation: Operation_type;
signal Control: std_logic_vector(3 downto 0);
-- synthesis translate_on
-- The above two special comments "synthesis translate_off" and "synthesis translate_on" hide the lines between these comments from the synthesis tool.

-- in VHDL, an output such as Q can not be read (can not appear on the RHS). So Q <= Q + 1; becomes illegal.
signal Q_internal_s: std_logic_vector(4 downto 0);  -- So we defined a local signal Q_internal_s (_s for signal)

begin

	Q <= Q_internal_s; -- transfer Q_internal_s into Q using a concurrent statement

	-- synthesis translate_off
	Control <= (clr, load, jump, en); -- aggregate notation on the right-hand side
	Operation_process: process (clr, load, jump, en)

	begin
		  if    (clr  = '1') then Operation <= clear;  -- Counter clears
		  elsif (load = '1') then Operation <= branch; -- Counter loads
		  elsif (jump = '1') then Operation <= jmp; -- Counter jumps
		  elsif (en   = '1') then Operation <= inc;  -- Counter increments
		  elsif ((clr  = '0') and (load = '0') and (jump = '0') and (en   = '0')) then Operation <= stay; -- Counter remains stayput
		  else                    Operation <= unkn; -- Unexpected Unknown operation
		  end if;
	end process Operation_process;

	-- synthesis translate_on

-----------------------------------------------------
-- Counter process
-----------------------------------------------------
counter_p: process (clk)
	variable Q_next : std_logic_vector(4 downto 0);
	variable diff   : std_logic_vector(4 downto 0);
	begin
		if (clk'event and clk = '1') then
			if (clr = '1') then
				Q_internal_s <= (others => '0');
			elsif (load = '1') then
				Q_internal_s <= BA;
			elsif (jump = '1') then
				diff := "10100" - Q_internal_s;
				if diff(0) = '0' then --number is even
			      Q_next := Q_internal_s + ('0' & diff(4 downto 1)); --find midpoint and add
				else  --number is odd
				  if (diff < "01010") then --less than 10
					Q_next := Q_internal_s + ('0' & diff(4 downto 1));
				  else --greater than 10
				    Q_next := Q_internal_s + ('0' & diff(4 downto 1)) + 1;
				  end if;
				end if;
				--check for bonus
				if (Q_next + "00100" <= "10100") then
                  Q_next := Q_next + "00100";
				end if;
				Q_internal_s <= Q_next;
			elsif (en = '1') then
				if Q_internal_s = "10100" then
					Q_internal_s <= (others => '0'); --reset when 20 is reached
				else
					Q_internal_s <= Q_internal_s + 1;
				end if;
			end if;
		end if;
	end process counter_p;

end architecture RTL;
-----------------------------------------------------------------------------
