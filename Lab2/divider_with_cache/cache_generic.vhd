-------------------------------------------------------------------------------
--
-- Design   : Cache
-- Project  : 
-- Author   : Srinivas, Phil, Gandhi Puvvada
-- Company  : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : cache.vhd
-- Version      : 1.1
--
-------------------------------------------------------------------------------
--
-- Description : The cache has the data memory / cam / lru instantiated 
-- Rev 1.1:  Renamed internal signals to make it clearer, removed addr_sig and
-- used only tag_write_addr_sig
-- 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity cache is
  generic (
    WIDTH     : integer := 8;
    DEPTH     : integer := 8;
    LOG_DEPTH : integer := 3
    );
  port (
    -- global signals
    clk   : in std_logic;
    resetb : in std_logic;
	
    rd       : in  std_logic;
    tag_in   : in  std_logic_vector(WIDTH-1 downto 0);
    we       : in  std_logic;
    data_in  : in  std_logic_vector(WIDTH-1 downto 0);
    data_out : out std_logic_vector(WIDTH-1 downto 0);
    hit_true : out std_logic
    ) ;
end cache;

architecture behave of cache is
  component cam
    generic (
      WIDTH     : integer := 8;
      DEPTH     : integer := 8;
      LOG_DEPTH : integer := 3
      );
    port(
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
      );
  end component;

  component lru
    generic (
      DEPTH : integer := 8
      );
    port(
      clk : in std_logic;
	  
      update_lru_stack : in  std_logic;
      accessed_block   : in  std_logic_vector(DEPTH-1 downto 0);
      victim           : out std_logic_vector(DEPTH-1 downto 0);
      victim_a         : out std_logic_vector(LOG_DEPTH-1 downto 0)
      );
  end component;

  component spram
    generic (
      DATA_WIDTH : integer := 8;
      ADDR_WIDTH : integer := 4
      );
    port(
      clk      : in  std_logic;
      addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      we       : in  std_logic;
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end component;

  signal empty_sig            : std_logic_vector (DEPTH-1 downto 0);
  signal hit_sig              : std_logic_vector (DEPTH-1 downto 0);
  signal victim_sig           : std_logic_vector (DEPTH-1 downto 0);
  signal accessed_block_sig   : std_logic_vector (DEPTH-1 downto 0);
  signal tag_write_addr_sig   : std_logic_vector(DEPTH-1 downto 0);
  signal empty_a_sig          : std_logic_vector (LOG_DEPTH-1 downto 0);
  signal hit_a_sig            : std_logic_vector (LOG_DEPTH-1 downto 0);
  signal victim_a_sig         : std_logic_vector (LOG_DEPTH-1 downto 0);
  signal tag_write_addr_a_sig : std_logic_vector (LOG_DEPTH-1 downto 0);
  signal accessed_block_a_sig : std_logic_vector (LOG_DEPTH-1 downto 0);
  signal empty_true_sig       : std_logic;
  signal hit_true_sig         : std_logic;
  signal update_lru_stack_sig : std_logic;
begin

  cam_inst : cam
    generic map (
      WIDTH     => WIDTH,
      DEPTH     => DEPTH,
      LOG_DEPTH => LOG_DEPTH
      )

    port map (
      clk   => clk,
      resetb => resetb,
	  
      rd             => rd,
      tag_in         => tag_in,
      we             => we,
      tag_write_addr => tag_write_addr_sig,

      empty      => empty_sig,
      empty_a    => empty_a_sig,
      empty_true => empty_true_sig,

      hit      => hit_sig,
      hit_a    => hit_a_sig,
      hit_true => hit_true_sig
      );

  hit_true <= hit_true_sig;

  lru_inst : lru
    generic map (
      DEPTH => DEPTH
      )

    port map (
      clk => clk,
      update_lru_stack => update_lru_stack_sig,
      accessed_block   => accessed_block_sig,
      victim           => victim_sig,
      victim_a         => victim_a_sig
      );

  spram_inst : spram
    generic map (
      DATA_WIDTH => WIDTH,
      ADDR_WIDTH => LOG_DEPTH
      )

    port map (
      clk      => clk,
      addr     => accessed_block_a_sig,
      data_in  => data_in,
      we       => we,
      data_out => data_out
      );

-- Notice the use of "conditional signal assignment" in the following
-- 4 concurrent statements to avoid rather elaborate 4 processes each 
-- to hold just one "if statement".
  tag_write_addr_a_sig <= empty_a_sig when empty_true_sig = '1' else
                          victim_a_sig;

  tag_write_addr_sig <= empty_sig when empty_true_sig = '1' else
                        victim_sig;

  accessed_block_sig <= tag_write_addr_sig when we = '1' else
                        hit_sig;

  accessed_block_a_sig <= tag_write_addr_a_sig when we = '1' else
                          hit_a_sig;

  update_lru_stack_sig <= we or hit_true_sig;

end behave;
