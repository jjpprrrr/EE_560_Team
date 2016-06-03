-------------------------------------------------------------------------------
--
-- Design   : LRU
-- Project  : 
-- Author   : Srinivas, Gandhi Puvvada
-- Company  : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : lru.vhd
-- Version      : 1.0
-------------------------------------------------------------------------------
--
-- Description : The lru generates the pointer to the least recently used location
-- 
-- 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity lru is
  generic (
    DEPTH     : integer := 8;
    LOG_DEPTH : integer := 3
    );
  port (
    -- global signals
    clk : in std_logic;
    update_lru_stack : in  std_logic;
    accessed_block   : in  std_logic_vector(DEPTH-1 downto 0);
    victim           : out std_logic_vector(DEPTH-1 downto 0);
    victim_a         : out std_logic_vector(LOG_DEPTH-1 downto 0)
    ) ;
end lru;

architecture behave of lru is

  type array_depth_depth_bits is array (0 to DEPTH-1) of std_logic_vector(DEPTH-1 downto 0);
  type array_depth_1_bit is array (0 to DEPTH-1) of std_logic;

  signal sloc        : array_depth_depth_bits;
  signal update_sloc : array_depth_1_bit;
  signal sloc_eq     : array_depth_1_bit;

begin

-- shift registers
  shift_registers : process (clk)
  begin
    if clk = '1' and clk'event then
			if update_sloc(0) = '1' then
				sloc(0) <= accessed_block;
			end if;
			for i in 1 to (DEPTH-1) loop
				if update_sloc(i) = '1' then
					sloc(i) <= sloc(i-1);
				end if;
			end loop;
    end if;
  end process shift_registers;

-- comparators to check the location of the accessed location in the LRU
  slot_loc_check : process (sloc, accessed_block)
  begin
    sloc_eq <= (others => '0');
    for i in 0 to (DEPTH-1) loop
      if sloc(i) = accessed_block then
        sloc_eq(i) <= '1';
      else
        sloc_eq(i) <= '0';
      end if;
    end loop;
  end process slot_loc_check;

-- 
  update_generation : process (sloc_eq, update_sloc, update_lru_stack)
  begin
  -----------------------------------------------------------------------------
  -- task 4: signal update_sloc is generated.
  -----------------------------------------------------------------------------

  update_sloc <= (others => '0'); 
  if (update_lru_stack = '1') then 
  for i in 0 to (DEPTH-1) loop -- going through all LRU entries
   if sloc_eq(i) = '0' then    -- I don't have the entry
     update_sloc(i) <= '1';    -- promote me to top (and shift others down) 
   elsif sloc_eq(i) = '1' then -- I have the entry
     update_sloc(i) <= '1';    -- Will be used in clocked process to promote accordingly
	 exit;
   end if;
  end loop;
  end if;
  end process update_generation;

  -----------------------------------------------------------------------------
  -- task 5	: signal victim is generated.
  -- hint	: no processes needed.	 
  -----------------------------------------------------------------------------
  victim <= sloc(DEPTH-1); --always provide lowest entry; CAM will decide to use it or not
  victim_address_gen : process (sloc)
  begin
    victim_a <= (others => '0');
    for i in 0 to (DEPTH-1) loop
      if sloc(DEPTH-1)(i) = '1' then
        victim_a <= conv_std_logic_vector(i, LOG_DEPTH);
      end if;
    end loop;
  end process victim_address_gen;
end behave;
