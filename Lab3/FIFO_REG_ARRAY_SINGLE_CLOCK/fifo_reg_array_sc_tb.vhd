-------------------------------------------------------------------------------
-- File name: 	: fifo_reg_array_sc_tb.vhd (sc = single clock)
-- Design       : fifo_reg_array_sc_tb 
-- Project      : testbench for a FIFO using register array(single clock)
-- Author       : Pritish Malavade and Gandhi Puvvada
-- Company      : University of Southern California 
-- Date			: 6/19/2010
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Libraries and use clauses
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_SIGNED.ALL;
------------------------------------------------------------------------------
entity fifo_reg_array_sc_tb is
end fifo_reg_array_sc_tb;
------------------------------------------------------------------------------
architecture behv_tb of fifo_reg_array_sc_tb is
---------------------------------------
-- clock period
	constant clk_period: time := 20 ns;
----------------------------------------	
-- local signals
	signal		reset_tb               		: std_logic;
	signal		data_in_tb             		: std_logic_vector(15 downto 0); 
	signal		data_out_tb         		: std_logic_vector(15 downto 0);
	signal		put_tb,get_tb       	    : std_logic; 
	signal		empty_tb, full_tb	        : std_logic; 
	signal		clk_tb,clk_tb_int             : std_logic;
	signal      count						: std_logic_vector(15 downto 0) := "0000000000000000";
----------------------------------------	
-- component declarations
component fifo_reg_array_sc is
generic (
         DATA_WIDTH     : integer := 16; 
         ADDR_WIDTH     : integer := 4
        );
port ( 
		clk      		: in std_logic;
		reset			: in std_logic;
		data_in   	    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		wen             : in  std_logic;
		ren             : in  std_logic;
		data_out    	: out std_logic_vector(DATA_WIDTH-1 downto 0);
		empty		    : out  std_logic;
		full		    : out  std_logic
	  ); 
end component;
--------------------------------------------------------------------------------		
begin
----------------------------------------	
 UUT: fifo_reg_array_sc
	  port map(clk_tb, reset_tb, data_in_tb, put_tb, get_tb, data_out_tb, empty_tb, full_tb);
----------------------------------------	
-- main clock of the fifo		  
	clock_generate: process
	begin
	  clk_tb <= '0', '1' after (clk_period/2);
	  wait for clk_period;
	end process clock_generate;
----------------------------------------	
-- slightly shifted clock for providing the data	
	clock_int_generate: process
	begin
	     wait for clk_period * 0.2;
	  	  clk_tb_int <= clk_tb;
	end process clock_int_generate;
----------------------------------------	
	reset_generate: process
	begin
	  reset_tb <= '1', '0' after (clk_period * 2);
	  wait; -- wait forever
	end process reset_generate;
----------------------------------------	
	put_get_process: process
	begin
	  wait for (clk_period * 2);
	  put_tb <= '0', '1' after (clk_period * 2);
	  get_tb <= '0', '1' after (clk_period * 2);
	  wait for (clk_period * 6);
	  put_tb <= '0';
	  wait for (clk_period * 12);
	  get_tb <= '0';
	  wait for (clk_period * 30);
	  put_tb <= '1';
	  wait for (clk_period * 30);
	  put_tb <= '0';
	  wait for (clk_period * 6);
	  get_tb <= '1';
	  wait for (clk_period * 18);
	  put_tb <= '1';
	  wait for (clk_period * 6);
	  get_tb <= '0';
	  wait for (clk_period * 18);
	  get_tb <= '1';
	  put_tb <= '1';
	  wait for (clk_period * 4);
	  put_tb <= '0';
	  wait for (clk_period * 16);
	  get_tb <= '0';
	  -- wait; -- wait forever
	end process put_get_process;
----------------------------------------	
	data_geration_process : process (clk_tb_int) -- note clk_tb_int
	begin
	  if (reset_tb = '1') then
	    data_in_tb 	<= "0000000000000000"; -- (others => '0')
		count		<= (others => '0'); -- "0000000000000000";  
	  elsif(clk_tb_int'event and clk_tb_int = '0') then -- on negative edge of this shifted clock 	 		
		if (full_tb = '0' and put_tb = '1') then 
			count <= count + 1;
			data_in_tb <= count;	
		end if;
	  end if;
	end process;
----------------------------------------	
end behv_tb;
------------------------------------------------------------------------------
