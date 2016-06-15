-------------------------------------------------------------------------------
-- File name: 	: fifo_reg_array_tc_tb.vhd for fifo_reg_array_tc.vhd (tc = two clocks)
-- Design       : fifo_reg_array_tc 
-- Project      : FIFO using register array (two clocks)
-- Author       : Pritish Malavade and Gandhi Puvvada
-- Company      : University of Southern California 
-- Date			: 6/20/2010
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_SIGNED.ALL;

------------------------------------------------------------------------------
entity fifo_tb is
end fifo_tb;

------------------------------------------------------------------------------

architecture behv_tb of fifo_tb is

-- clock period
	constant wr_clk_period: time := 20 ns;
	constant rd_clk_period: time := 30 ns;

-- local signals
	
	signal		wclk_tb ,rclk_tb            : std_logic;	
	signal		reset_tb               		: std_logic;
	signal		data_in_tb             		: std_logic_vector(15 downto 0); 
	signal		wen_tb, ren_tb				: std_logic;
	signal		data_out_tb         		: std_logic_vector(15 downto 0);
	signal		empty_tb	        		: std_logic; 
	signal		full_tb	        			: std_logic; 
 	
-- component declarations
---------------------------------------
component fifo_reg_array_tc is
port ( 
		wclk      		: in std_logic;
		rclk      		: in std_logic;
		reset			: in std_logic;
		data_in   	    : in  std_logic_vector(15 downto 0);
		wen             : in  std_logic;  -- change wenq
		ren             : in  std_logic;  -- change to ren
		data_out    	: out std_logic_vector(15 downto 0);
		empty		    : out  std_logic;
		full		    : out  std_logic
	  ); 
end component ;
---------------------------------------
component producer is
port (
		reset			: in    std_logic;
		full 			: in 	std_logic;
		wen				: out 	std_logic;
		data_to_send	: out	std_logic_vector(15 downto 0);
		wclk			: in 	std_logic
	);
end component;
---------------------------------------
component consumer is
port (
		reset	: in    std_logic;
		empty 	: in 	std_logic;
		ren		: out 	std_logic;
		data_to_consume	: in	std_logic_vector(15 downto 0);
		rclk	: in 	std_logic
	);
end component;
---------------------------------------

begin
   
---------------------------------------
  FIFO: fifo_reg_array_tc
	port map(wclk_tb, rclk_tb, reset_tb, data_in_tb, wen_tb, ren_tb, data_out_tb, empty_tb, full_tb);

  PROD: producer
	port map(reset_tb, full_tb, wen_tb, data_in_tb, wclk_tb);
  
  CONS: consumer
	port map(reset_tb, empty_tb, ren_tb, data_out_tb, rclk_tb);
	
---------------------------------------	      
	-- wr_clock_generate: process
	-- begin
	  -- wclk_tb <= '0', '1' after (wr_clk_period/2);
	  -- wait for wr_clk_period;
	-- end process wr_clock_generate;
---------------------------------------	      
	wr_clock_generate: process
	begin
	  wclk_tb <= '0';
	  wait for wr_clk_period/2;
	  wclk_tb <= '1';
	  wait for wr_clk_period/2;
	end process wr_clock_generate;
---------------------------------------	
	-- rd_clock_generate: process
	-- begin
	  -- rclk_tb <= '0', '1' after (rd_clk_period/2);
	  -- wait for rd_clk_period;
	-- end process rd_clock_generate;
---------------------------------------		
	rd_clock_generate: process
	begin
	  rclk_tb <= '0';
	  wait for rd_clk_period/2;
	  rclk_tb <= '1';
	  wait for rd_clk_period/2;
	end process rd_clock_generate;
---------------------------------------		
	reset_tb <= '1', '0' after (2.1)* wr_clk_period; --   ----- ????? common reset for both sides?
---------------------------------------	
	
end behv_tb;
