-------------------------------------------------------------------------------
--
-- Design       : spram 
 
-- Author       : Srinivas Vaduvatha 
-- Company      : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : spram.vhd
-- Version      : 1.0
-------------------------------------------------------------------------------
--
-- Description  : Data width & Address width - Generics
--                Single port memory. (basically an array of registers). 
--                Infers Distributed RAM resource in Xilinx FPGAs.
--                Memory has to be of (2**n) depth
--
-------------------------------------------------------------------------------

-- libraries and use clauses
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity spram is
  generic (
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 4
    );
  port (
    clk      : in  std_logic;
    addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    we       : in  std_logic;
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    ); 
end spram;

architecture inferrable of spram is

-- type declarations
  type mem_type is array ((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector((DATA_WIDTH-1) downto 0);

-- signals declarations.
  signal mem : mem_type;

begin
  mem_update : process (clk)
  begin
    if (clk = '1' and clk'event) then
		if (we = '1') then
			mem(CONV_INTEGER(addr)) <= data_in;
		end if;
    end if;
  end process;

  data_out <= mem(CONV_INTEGER(addr));

end inferrable;
