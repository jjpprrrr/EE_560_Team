-------------------------------------------------------------------------------
--
-- Design       : FIFO 
-- Project      : FIFO with BRAM 
-- Author       : Pritish Malavade 
-- Company      : University of Southern California 
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity fifo_en is
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
end fifo_en ; 
architecture behavefifo of fifo_en is 
component dpram
   port (
       clka          : in  std_logic; 
      addr_a        : in  std_logic_vector(3 downto 0);
      data_in_a     : in  std_logic_vector(15 downto 0);
      wea           : in std_logic;
      ena           : in  std_logic;
      data_out_a    : out std_logic_vector(15 downto 0);

      clkb          : in  std_logic; 
      addr_b        : in  std_logic_vector(3 downto 0);
      data_in_b     : in  std_logic_vector(15 downto 0);
      web           : in std_logic;      
      enb           : in  std_logic;
      data_out_b    : out std_logic_vector(15 downto 0)
	  );
END component;

signal rdptr 				: std_logic_vector(4 downto 0); -- read pointer in binary
signal wrptr 				: std_logic_vector(4 downto 0); -- write pointer in binary
signal rdptr_ss				: std_logic_vector(4 downto 0); -- double synchronized binary read pointer
signal wrptr_ss				: std_logic_vector(4 downto 0); -- double synchronized binary write pointer
signal rdptr_gray 			: std_logic_vector(4 downto 0); -- read pointer in gray
signal wrptr_gray 			: std_logic_vector(4 downto 0); 
signal rdptr_gray_s 		: std_logic_vector(4 downto 0); -- synchronized gray read pointer
signal wrptr_gray_s		    : std_logic_vector(4 downto 0);
signal rdptr_gray_ss 		: std_logic_vector(4 downto 0); -- double sync gray read pointer
signal wrptr_gray_ss 		: std_logic_vector(4 downto 0);
signal gnd,pwr          	: std_logic;
signal gnd_bus 				: std_logic_vector(15 downto 0);

signal depth_rd				: std_logic_vector(4 downto 0); -- On reader side
signal depth_wr				: std_logic_vector(4 downto 0); -- On writer side
signal wenq					    : std_logic;
signal renq					    : std_logic;
signal full_int					: std_logic;
signal empty_int					: std_logic;

begin
-------------------------------------------------------------------------------------
 gnd_bus <= "0000000000000000";
   gnd <= '0';
   pwr <= '1';

bram1: dpram port map (clka => rclk, addr_a => rdptr(3 downto 0),data_in_a => gnd_bus, wea => gnd,ena =>renq , data_out_a => data_out,
						clkb => wclk, addr_b => wrptr(3 downto 0),data_in_b => data_in,web => '1', enb => wenq);
------------------------------------------------------------------------------------------
-- Task 1: Convert the double synchronized gray pointer to binary
------------------------------------------------------------------------------------------
-- with wrptr_gray_ss select
	-- wrptr_ss <= "00001" when "00001",
				-- "00010" when "00011",
				-- "00011" when "00010",
				-- "00100" when "00110",
				-- "00101" when "00111",
				-- "00110" when "00101",
				-- "00111" when "00100",
				-- "01000" when "01100",
				-- "01001" when "01101",
				-- "01010" when "01111",
				-- "01011" when "01110",
				-- "01100" when "01010",
				-- "01101" when "01011",
				-- "01110" when "01001",
				-- "01111" when "01000",
				-- "10000" when "11000",
				-- "10001" when "11001",
				-- "10010" when "11011",
				-- "10011" when "11010",
				-- "10100" when "11110",
				-- "10101" when "11111",
				-- "10110" when "11101",
				-- "10111" when "11100",
				-- "11000" when "10100",
				-- "11001" when "10101",
				-- "11010" when "10111",
				-- "11011" when "10110",
				-- "11100" when "10010",
				-- "11101" when "10011",
				-- "11110" when "10001",
				-- "11111" when "10000",
				-- "00000" when others;
				
wrptr_ss(4) <= wrptr_gray_ss(4);
wrptr_ss(3) <= wrptr_ss(4) xor wrptr_gray_ss(3);
wrptr_ss(2) <= wrptr_ss(3) xor wrptr_gray_ss(2);
wrptr_ss(1) <= wrptr_ss(2) xor wrptr_gray_ss(1);
wrptr_ss(0) <= wrptr_ss(1) xor wrptr_gray_ss(0);

-- with rdptr_gray_ss select
	-- rdptr_ss <= "00001" when "00001",
				-- "00010" when "00011",
				-- "00011" when "00010",
				-- "00100" when "00110",
				-- "00101" when "00111",
				-- "00110" when "00101",
				-- "00111" when "00100",
				-- "01000" when "01100",
				-- "01001" when "01101",
				-- "01010" when "01111",
				-- "01011" when "01110",
				-- "01100" when "01010",
				-- "01101" when "01011",
				-- "01110" when "01001",
				-- "01111" when "01000",
				-- "10000" when "11000",
				-- "10001" when "11001",
				-- "10010" when "11011",
				-- "10011" when "11010",
				-- "10100" when "11110",
				-- "10101" when "11111",
				-- "10110" when "11101",
				-- "10111" when "11100",
				-- "11000" when "10100",
				-- "11001" when "10101",
				-- "11010" when "10111",
				-- "11011" when "10110",
				-- "11100" when "10010",
				-- "11101" when "10011",
				-- "11110" when "10001",
				-- "11111" when "10000",
				-- "00000" when others;
				
rdptr_ss(4) <= rdptr_gray_ss(4);
rdptr_ss(3) <= rdptr_ss(4) xor rdptr_gray_ss(3);
rdptr_ss(2) <= rdptr_ss(3) xor rdptr_gray_ss(2);
rdptr_ss(1) <= rdptr_ss(2) xor rdptr_gray_ss(1);
rdptr_ss(0) <= rdptr_ss(1) xor rdptr_gray_ss(0);	
				-----------------------------------
----------------------------------------------------------------------------
-- Task 2: 	Generate the depth in each domain.
--  		Generate the empty and full signals
--			Generate the write and read enables
----------------------------------------------------------------------------						

depth_rd <= unsigned(wrptr_ss) - unsigned(rdptr);
depth_wr <= unsigned(wrptr) - unsigned(rdptr_ss);

Full_Check: process (depth_wr)
	begin
		if (depth_wr = "10000") then 
		full_int <= '1' ; 
		else 
		full_int <= '0' ;
		end if;
	end process Full_Check;
	
full <= full_int ;
wenq <= (not full_int) and wen;


Empty_Check: process (depth_rd)
	begin
		if (depth_rd = "00000") then
			empty_int <= '1';
		else
			empty_int <= '0';
		end if;
	
	end process Empty_Check;
	
empty <= empty_int;
renq <= (not empty_int) and ren;


----------------------------------------------------------------------------
-- Task 3: 	Complete the clocked processes
----------------------------------------------------------------------------				
a:process (wclk)
variable next_wrptr_var : std_logic_vector(4 downto 0);
begin
	if (reset = '0') then
	wrptr <= "00000";
	wrptr_gray <= "00000";
	rdptr_gray_s <= "00000";
	rdptr_gray_ss <= "00000";
	elsif(wclk'event and wclk = '1') then
		if (wen = '1') then
		  	if (full_int /= '1') then
		  	    wrptr <= unsigned(wrptr) + 1;
				next_wrptr_var := unsigned(wrptr) + 1;
			end if;
		else
			next_wrptr_var := (wrptr);
		end if;
		wrptr_gray(0) <= next_wrptr_var(0) xor next_wrptr_var(1);
		wrptr_gray(1) <= next_wrptr_var(1) xor next_wrptr_var(2);
		wrptr_gray(2) <= next_wrptr_var(2) xor next_wrptr_var(3);
		wrptr_gray(3) <= next_wrptr_var(3) xor next_wrptr_var(4);
		wrptr_gray(4) <= next_wrptr_var(4);
		
		rdptr_gray_s <= rdptr_gray;
		rdptr_gray_ss <= rdptr_gray_s;
	end if;
end process;
b: process (rclk)
variable next_rdptr_var : std_logic_vector(4 downto 0);
begin
	if (reset = '0') then
	rdptr <= "00000";
	rdptr_gray <= "00000";
	wrptr_gray_s <= "00000";
	wrptr_gray_ss <= "00000";

	elsif(rclk'event and rclk = '1') then
		if (ren = '1') then
		  	if (empty_int /= '1') then
		  	    rdptr <= unsigned(rdptr) + 1;
				next_rdptr_var := unsigned(rdptr) + 1;
			end if;
			next_rdptr_var := (rdptr);
		end if;
		rdptr_gray(0) <=  next_rdptr_var(0) xor next_rdptr_var(1);
		rdptr_gray(1) <=  next_rdptr_var(1) xor next_rdptr_var(2);
		rdptr_gray(2) <=  next_rdptr_var(2) xor next_rdptr_var(3);
		rdptr_gray(3) <=  next_rdptr_var(3) xor next_rdptr_var(4);
		rdptr_gray(4) <=  next_rdptr_var(4);
		
		wrptr_gray_s <= wrptr_gray;
		wrptr_gray_ss <= wrptr_gray_s;

	end if;
end process;

end behavefifo;	