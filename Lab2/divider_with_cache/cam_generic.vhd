-------------------------------------------------------------------------------
--
-- Design   : CAM
-- Project  : 
-- Author   : Srinivas, Gandhi Puvvada
-- Company  : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : cam.vhd
-- Version      : 1.0
-------------------------------------------------------------------------------
--
-- Description : This cam contains just the TAG memory. The data is stored in a 
--               different memory.
-- 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity cam is
  generic (
    WIDTH     : integer := 8;
    DEPTH     : integer := 8;
    LOG_DEPTH : integer := 3
    );
  port (
    -- global signals
    clk   : in std_logic;
    resetb : in std_logic;
	
    rd             : in std_logic;
    tag_in         : in std_logic_vector(WIDTH-1 downto 0);
    we             : in std_logic;
    tag_write_addr : in std_logic_vector(DEPTH-1 downto 0);

    empty      : out std_logic_vector(DEPTH-1 downto 0);
    empty_a    : out std_logic_vector(LOG_DEPTH-1 downto 0);
    empty_true : out std_logic;

    hit      : out std_logic_vector(DEPTH-1 downto 0);
    hit_a    : out std_logic_vector(LOG_DEPTH-1 downto 0);
    hit_true : out std_logic
    ) ;
end cam;

architecture behave of cam is

  type array_depth_tag_width_bits is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  type array_depth_1_bit is array (0 to DEPTH-1) of std_logic;

  signal tag    : array_depth_tag_width_bits;
  signal valid  : array_depth_1_bit;
  signal match  : array_depth_1_bit;
  signal tag_we : array_depth_1_bit;

begin
-- comparators to check the tags
  tag_check : process (tag, valid, tag_in)
  begin
    match <= (others => '0');
    for i in 0 to (DEPTH-1) loop
      if ((tag(i) = tag_in) and (valid(i) = '1')) then
        match(i) <= '1';
      else
        match(i) <= '0';
      end if;
    end loop;
  end process tag_check;

-- storing the tag / valid / dirty in registers
  tag_registers : process (clk, resetb)
  begin
    if resetb = '0' then
		for i in 0 to (DEPTH-1) loop
			tag(i)   <= (others => '-');
			valid(i) <= '0';
		end loop;
    elsif clk'event and clk = '1' then
		for i in 0 to (DEPTH-1) loop
			if tag_we(i) = '1' then
				tag(i)   <= tag_in;
				valid(i) <= '1';
			end if;
		end loop;
    end if;
  end process tag_registers;

  hit_generation : process (match, rd)
  begin
	---------------------------------------------------------------------------
    -- task 1: signals hit_a,hit_true and hit(i) are generated.
    ---------------------------------------------------------------------------
	hit <= (others => '0');
	hit_a <= (others => '0');
	hit_true <= '0';
	for i in 0 to (DEPTH-1) loop
		if (match(i) = '1') then
			hit(i) <= '1';
			hit_true <= '1';
			hit_a <= CONV_STD_LOGIC_VECTOR(i, 3);
			exit;
		end if;
	end loop;
  end process hit_generation;

  empty_generation : process (valid, rd, we)
  begin  
	---------------------------------------------------------------------------
    -- task 2: signals empty_a,empty_true and empty(i) are generated.
    ---------------------------------------------------------------------------
	empty <= (others => '0');
	empty_a <= (others => '0');
	empty_true <= '0';
	for i in 0 to (DEPTH-1) loop
		if (valid(i) = '0') then 
			empty(i) <= '1';
			empty_a <= CONV_STD_LOGIC_VECTOR(i, 3);
			empty_true <= '1';
			exit;
		end if;
	end loop;
  end process empty_generation;

  tag_write_enable_generation : process (tag_write_addr, we)
  begin
	---------------------------------------------------------------------------
    -- task 3: signals tag_we is generated.
    ---------------------------------------------------------------------------
	tag_we <= (others => '0');
	for i in 0 to (DEPTH-1) loop
		if (tag_write_addr(i) = '1' and we = '1') then 
			tag_we(i) <= '1';
		end if;
	end loop;
  end process tag_write_enable_generation;

end behave;
