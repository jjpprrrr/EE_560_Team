-------------------------------------------------------------------------------
--
-- Design       : dpram 
-- Project      : Digilent Terminal 
-- Author       : Srinivas Vaduvatha, Prasanjeet 
-- Company      : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : dmem_regarray.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description  : Single port memory, comprising of register arrays
--                asynchronous reads and synchronous writes 
--
-------------------------------------------------------------------------------

-- libraries and use clauses
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity data_mem_dp is 
generic (
         DATA_WIDTH     : integer := 32; 
         ADDR_WIDTH     : integer := 5
        );
port ( 
      addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      mem_write     : in  std_logic; 
      data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	  mem_read		: in  std_logic;	
	  clka          : in  std_logic
     ); 
end data_mem_dp ; 

architecture inferrable of data_mem_dp is 

-- type declarations
type mem_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector((DATA_WIDTH-1) downto 0); 

-- signals declarations.
signal addr_reg		:std_logic_vector(ADDR_WIDTH-1 downto 0);
shared variable mem : mem_type := (X"00000000", X"00000001", X"00000002", X"00000003",X"00000004", X"00000005",X"00000006", X"00000007", X"00000008", X"00000009", X"0000000A", X"0000000B", X"0000000C", X"0000000D", X"0000000E",X"0000000F",
                                   X"00000010", X"00000011", X"00000012", X"00000013",X"00000014", X"00000015",X"00000016", X"00000017", X"00000018", X"00000019", X"0000001A", X"0000001B", X"0000001C", X"0000001D", X"0000001E",X"0000001F") ;
 

begin 


-- previous asynchronous operation resulting in 8224 single-bit latches.
---------------------------------------------------------------
-- We know that "missing an else statement" causes latch inference.
-- The following asynchronous memory produced 8192 (256x32 = 8K) single-bit latches
-- Besides this, 32 single-bit latches were inferred by the mem_read operation.
-- So 8192+32 = 8224 latches were reported on lines [259:8482] (inclusive) in the synthesis report.
-- porta_oper : process (wea, ena, addr_a) 
-- begin 
        -- if (wea = '1' and ena='1') then 
            -- mem(CONV_INTEGER(addr_a))     := data_in_a; 
        -- end if;
		  -- if( ena='1')then
			-- data_out_a          <= mem(CONV_INTEGER(addr_a));
		  -- end if;	
-- end process; 
---------------------------------------------------------------
-- Let us try to make the memory an array of registers instead of latches.
-- If possible, try to reduce the memory to 32x32 or at most 64x32 (in place of the current 256x32).

porta_write_oper : process (clka) 
begin 
	if (clka'event and clka ='1') then
        if (mem_write = '1') then 
            mem(CONV_INTEGER(addr_a))     := data_in_a; 
        end if;
	end if;
end process;


porta_read_oper: process (mem_read, addr_a) 
begin 
		if (mem_read='1')then
			data_out_a          <= mem(CONV_INTEGER(addr_a));
		else
			data_out_a          <= X"F0F0F0F0";
		end if;	
end process;

-- The above read process can be replaced by the following but 
-- if we/the students made a mistake in producing mem_read signal, 
-- this might prevent the design from producing the right results.
---------------------------------------------------------------


-- dummy operation just to be consistent with port list
-- mem_addr_reg: process (clka)--add clk 
-- begin 
  -- if (clka = '1' and clka'event) then
		-- if(ena = '1') then    -- creating a latch
        -- addr_reg          <= addr_a ; 
		-- end if;		  
  -- end if;
-- end process; 

end inferrable ;
