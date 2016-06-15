-------------------------------------------------------------------------------
--
-- Design       : dpram 
-- Project      : FIFO 
-- Author       : Srinivas Vaduvatha 
-- Company      : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : dpram.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description  : Data width & Address width - Generics
--                Dual port synchronous memory. Supports Read / Write on both ports 
--                Read / Write ports can be different clocks.
--                Infers BRAM resource in Xilinx FPGAs.
--                If the width / depth specified require more bits than in a single 
--                BRAM, multiple BRAMs are automatically cascaded to form a larger 
--                memory. Memory has to be of (2**n) depth
--
-------------------------------------------------------------------------------

-- libraries and use clauses
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dpram is 
generic (
         DATA_WIDTH     : integer := 16; 
         ADDR_WIDTH     : integer := 4
        );
port (
      clka          : in  std_logic; 
      addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      wea           : in  std_logic; 
      ena           : in  std_logic;
      data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);

      clkb          : in  std_logic; 
      addr_b        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in_b     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      web           : in  std_logic; 
      enb           : in  std_logic;
      data_out_b    : out std_logic_vector(DATA_WIDTH-1 downto 0)
     ); 
end dpram ; 

architecture inferrable of dpram is 

-- type declarations
type mem_type is array ((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector((DATA_WIDTH-1) downto 0); 

-- signals declarations.
signal addr_a_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
signal addr_b_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);

shared variable mem : mem_type;  

begin 
porta_oper : process (clka) 
begin 
    if (clka = '1' and clka'event) then
      if(ena = '1') then
        if (wea = '1') then 
            mem(CONV_INTEGER(addr_a))     := data_in_a; 
        end if;
		  addr_a_reg <= addr_a;        
		  end if;
    end if;
end process; 

data_out_a          <= mem(CONV_INTEGER(addr_a_reg)); 

portb_oper : process (clkb) 
begin 
    if (clkb = '1' and clkb'event) then
      if(enb = '1') then
        if (web = '1') then 
            mem(CONV_INTEGER(addr_b))     := data_in_b; 
        end if;
		  addr_b_reg <= addr_b;        
		  end if;
    end if;
end process; 

data_out_b          <= mem(CONV_INTEGER(addr_b_reg)); 
            
end inferrable ;
