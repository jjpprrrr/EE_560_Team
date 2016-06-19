------------------------------------------------------------------------------
--	A vhdl module for the number lock design (combined CU and DPU)

--	File name: number_lock.vhd
------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-----------------------------------
entity number_lock is

port(
	clk, resetb : IN  std_logic;
	u, z : IN  std_logic;
	unlock : OUT std_logic
	);
end number_lock ;

------------------------------------------------------------------------------

architecture behave of number_lock is

type state_type is (INITIAL, G1GET, G1, G10GET, G10, G101GET, G101, G1011GET, G1011, OPENING, BAD) ;
 
signal state        : state_type;
signal u_bar        : std_logic;
signal z_bar        : std_logic;
signal timer_out    : std_logic_vector(3 downto 0);

begin

-- concurrent signal assignment statements

    unlock <= '1' when (state = OPENING) else '0';
    u_bar  <= not u ;
    z_bar  <= not z ;

	CU_DPU: process (clk, resetb)
	begin

	  if (resetb = '0') then
	    state       <= INITIAL;
        timer_out   <= (others => '0');
	  elsif (clk'event and clk = '1') then
	    case (state) is
	      when INITIAL =>
				if (u = '1' and z = '0' and z_bar = '1') then
				  state <= G1GET;
				end if;
                timer_out <= (others => '0');
	      when G1GET =>
				if (u = '0') then
				  state <= G1;
				end if;
	      when G1 =>
				if (u = '0' and z = '1') then
				  state <= G10GET;
                elsif (u = '1' and (z = '1' or z_bar = '1')) then
				  state <= BAD;
                end if;
	      when G10GET =>
				if (z = '0' and (u = '0' or u ='1')) then
				  state <= G10;
                end if;
	      when G10 =>
				if (u = '1' and z = '0') then
				  state <= G101GET;
                elsif (z = '1') then
				  state <= BAD;
                end if;
	      when G101GET =>
				if (u = '0') then
				  state <= G101;
                end if;
	      when G101 =>
				if (u = '1' and z = '0' and z_bar = '1') then
				  state <= G1011GET;
                elsif (z = '1') then
				  state <= BAD;
                end if;
	      when G1011GET =>
				if (u = '0') then
				  state <= G1011;
                end if;
	      when G1011 =>
				  state <= OPENING;
	      when OPENING =>
              if timer_out = 15 then
				  state <= INITIAL;
              end if; 
              timer_out <= timer_out + 1 ;
          when BAD  =>
              state <= INITIAL;
		 end case;
		
	  end if;

	end process CU_DPU;
end behave ;
------------------------------------------------------------------------------
