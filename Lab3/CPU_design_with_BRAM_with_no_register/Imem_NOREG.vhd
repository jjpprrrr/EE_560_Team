-------------------------------------------------------------------------------
--
-- Design       : sprom 
-- Project      : Digilent Terminal 
-- Author       : Srinivas Vaduvatha, Prasanjeet Das 
-- Company      : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : Imem_regarray.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description  : Data width & Address width - Generics
--                Single port synchronous memory. 
--               
--
-------------------------------------------------------------------------------

-- libraries and use clauses
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.instr_stream_pkg.all; -- instruction stream defining 

entity instruction_mem is 
generic (
         DATA_WIDTH     : integer := 32; 
         ADDR_WIDTH     : integer := 8
        );
port (
       addr          : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
       data_out      : out std_logic_vector(DATA_WIDTH-1 downto 0);
	   clka          : in  std_logic
     ); 
end instruction_mem ; 

architecture inferrable of instruction_mem is 

signal addr_reg		:std_logic_vector(ADDR_WIDTH-1 downto 0);
begin 

-- asynchronous memory read, no enable
mem_read: process (addr) 
begin 
        data_out          <= mem(CONV_INTEGER(addr)); 
end process; 

-- dummy operation just to be consistent with port list
-- mem_addr_reg: process (clka)--add clk 
-- begin 
  -- if (clka = '1' and clka'event) then
		-- if(en = '1') then    -- creating a latch
        -- addr_reg          <= addr ; 
		-- end if;		  
  -- end if;
-- end process; 

end inferrable ;
