library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity fifo_top is
port ( 
		wclk      		: in std_logic;
		rclk      		: in std_logic;
		reset			: in std_logic;
		data_in   	    : in  std_logic_vector(15 downto 0);
		wen             : in  std_logic;  -- change wenq
		full		    : out  std_logic
	  );
end fifo_top;
architecture behave of fifo_top is
component fifo_en is
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

component consumer is
port (
		reset	: in    std_logic;
		empty 	: in 	std_logic;
		ren		: out 	std_logic;
		data_in	: in	std_logic_vector(15 downto 0);
		clk		: in 	std_logic
	);
end component;
signal ren			: std_logic;
signal empty		: std_logic;
signal data_out		: std_logic_vector(15 downto 0);
begin
fifo : fifo_en port map (	wclk => wclk, 
							rclk => rclk, 
							reset => reset,
							data_in => data_in,
							wen => wen,
							ren => ren,
							data_out => data_out,
							empty => empty,
							full => full
						);
cons :consumer port map (
							reset => reset,
							empty => empty,
							ren => ren,
							data_in => data_out,
							clk => rclk
						);
						
end behave;
			
							

