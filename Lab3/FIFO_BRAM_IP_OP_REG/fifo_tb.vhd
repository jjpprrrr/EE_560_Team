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
	constant wr_clk_period: time := 10 ns;
	constant rd_clk_period: time := 20 ns;

-- local signals
	
	
	signal		reset_tb               		: std_logic;
	signal		data_in_tb             		: std_logic_vector(15 downto 0); 
	signal		data_out_tb         		: std_logic_vector(15 downto 0);
	signal		put_tb,get_tb       	    : std_logic; 
	signal		empty_tb, full_tb	        : std_logic; 
	signal		wclk_tb,wclk_tb_int ,rclk_tb            : std_logic;
	signal      count						: std_logic_vector(15 downto 0) := "0000000000000000";
	signal 		empty_reg_tb				: std_logic;
	signal 		empty_reg2_tb				: std_logic;
 	
-- component declarations
component fifo_top is
port ( 
		wclk      		: in std_logic;
		rclk      		: in std_logic;
		reset			: in std_logic;
		data_in   	    : in  std_logic_vector(15 downto 0);
		wen             : in  std_logic;  -- change wenq
		full		    : out  std_logic
	  );
end component;


begin
    
  UUT: fifo_top
	  port map(wclk_tb, rclk_tb, reset_tb, data_in_tb, put_tb, full_tb);
	      
	wr_clock_generate: process
	begin
	  wclk_tb <= '0', '1' after (wr_clk_period/2);
	  wait for wr_clk_period;
	end process wr_clock_generate;
	
	rd_clock_generate: process
	begin
	  rclk_tb <= '0', '1' after (rd_clk_period/2);
	  wait for rd_clk_period;
	end process rd_clock_generate;
	
	wr_clock_int_generate: process
	begin
	     wait for wr_clk_period * 0.2;
	  	  wclk_tb_int <= wclk_tb;
	end process wr_clock_int_generate;
	
	reset_tb <= '0', '1' after (2.1)* wr_clk_period; -- 2*Tw changed to (2.1)*Tw
	

--port map(wclk_tb, rclk_tb, reset_tb, data_in_tb, put_tb, get_tb, data_out_tb, empty_tb, full_tb);
	
Sender_Ctrl: process
		file producer_data: text open read_mode is "C:\Modelsim_projects\FIFO_BRAM_IP_OP_REG\ee560_producer_data.txt";
		variable inline : line;
		variable data_send : std_logic_vector(15 downto 0);
		variable send_cycle: integer;
	begin
		wait until reset_tb ='1';

		while not endfile( producer_data) loop
		if(full_tb /= '1') then
			data_in_tb <= (others => 'Z');
			
--			wait for wr_clk_period*0.1;
						put_tb <= '0';
						
			readline(producer_data, inline);
			read(inline, send_cycle);
			read(inline, data_send);
			for i in 1 to send_cycle loop
				wait until wclk_tb'event and wclk_tb = '0';
			end loop;
			data_in_tb <= data_send;
			wait for wr_clk_period*0.4;
						put_tb <= '1';
		end if;
--		wait for wr_clk_period*1;
--						put_tb <= '0';
		wait until wclk_tb'event and wclk_tb = '1';
		wait for 1 ns;
						put_tb <= '0';
		end loop;

		put_tb <= '0';
		assert (false) report "End of Producer File"
		severity note;
		wait;
	end process;
	


end behv_tb;
