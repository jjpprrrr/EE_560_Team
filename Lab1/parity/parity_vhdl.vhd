
-------------------------------------------
-- -- Course: EE560 
-- -- 
-- // 
-- // Create Date:    21:43:27 05/20/2013 
-- // Design Name: 32-bit Parity Generator 
-- // Module Name:    parity 
-- // Project Name: 
-- // Target Devices: 
-- // Tool versions: 
-- // Description: 
-- //
-- // Dependencies: 
-- //
-- // Revision: 
-- // Revision 0.01 - File Created
-- // Additional Comments: 
-- //
-- //////////////////////////////////////////////////////////////////////////////////

library std, ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity parity_vhdl is
port ( in_data : IN  std_logic_vector(31 downto 0);
	   parity  : OUT std_logic
     );
end parity_vhdl;


architecture parity_beh of parity_vhdl is
signal parity_s : std_logic := '0';
begin
parity <= parity_s;
  parity_gen: process(in_data)
	variable par : std_logic;
	begin 
	  par := '0';
	  for i in 0 to 31 loop
	    par := par xor in_data(i);
	  end loop;
	  parity_s <= par;
    end process parity_gen;
end parity_beh;





