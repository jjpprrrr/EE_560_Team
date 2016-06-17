-------------------------------------------------------------------------------
-- File name: 	: fifo_reg_array_tc.vhd (tc = two clocks)
-- Design       : fifo_reg_array_tc 
-- Project      : FIFO using register array (two clocks)
-- Author       : Pritish Malavade and Gandhi Puvvada
-- Company      : University of Southern California 
-- Date			: 6/20/2010
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity fifo_reg_array_tc is
port ( 
		wclk      		: in std_logic;
		rclk      		: in std_logic;
		reset			: in std_logic;
		data_in   	    : in  std_logic_vector(15 downto 0);
		wen             : in  std_logic; 
		ren             : in  std_logic;  
		data_out    	: out std_logic_vector(15 downto 0);
		empty		    : out  std_logic;
		full		    : out  std_logic
	  ); 
end fifo_reg_array_tc ;
 
architecture behavefifo of fifo_reg_array_tc is 
type Reg_Array_type is array (0 to 15) of std_logic_vector(15 downto 0); 
signal Reg_Array : Reg_Array_type;

signal rdptr 				: std_logic_vector(4 downto 0); -- (n+1) bit read pointer in binary
signal wrptr 				: std_logic_vector(4 downto 0); -- (n+1) bit write pointer in binary
signal rdptr_ss				: std_logic_vector(4 downto 0); -- double synchronized binary read pointer
signal wrptr_ss				: std_logic_vector(4 downto 0); -- double synchronized binary write pointer
signal rdptr_gray 			: std_logic_vector(4 downto 0); -- read pointer in gray
signal wrptr_gray 			: std_logic_vector(4 downto 0); 
signal rdptr_gray_s 		: std_logic_vector(4 downto 0); -- synchronized gray read pointer
signal wrptr_gray_s		    : std_logic_vector(4 downto 0);
signal rdptr_gray_ss 		: std_logic_vector(4 downto 0); -- double sync gray read pointer
signal wrptr_gray_ss 		: std_logic_vector(4 downto 0);

signal depth_rd				: std_logic_vector(4 downto 0); -- depth computed on reader side
signal depth_wr				: std_logic_vector(4 downto 0); -- depth computed on writer side
signal wenq					    : std_logic;
signal renq					    : std_logic;
signal full_int					: std_logic;
signal empty_int				: std_logic;

begin
-------------------------------------------------------------------------------
-- Conversion of the double synchronized gray pointer to binary.
---------------------------------------
-- Task 1: Perform the conversion more elegantly using XOR gates.
-- The code below uses selected signal assignment to perform a long table look-up. 
-- The tool may not come up with the best optimization using XOR gates. 
-- It may arrive at the best SOP or POS!
-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
-- Add your Code to Covert wrptr_gray_ss to wrptr_ss using XOR gates
-- Don't forget to comment the selected statement above
-- Hint: You don't need to use a process for that, you can use concurrent assignment statements
-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------
-- Add your Code to Covert rdptr_gray_ss to rdptr_ss using XOR gates
-- Don't forget to comment the selected statement above
-- Hint: You don't need to use a process for that, you can use concurrent assignment statements
-------------------------------------------------------------------------------
rdptr_ss(4) <= rdptr_gray_ss(4);
rdptr_ss(3) <= rdptr_ss(4) xor rdptr_gray_ss(3);
rdptr_ss(2) <= rdptr_ss(3) xor rdptr_gray_ss(2);
rdptr_ss(1) <= rdptr_ss(2) xor rdptr_gray_ss(1);
rdptr_ss(0) <= rdptr_ss(1) xor rdptr_gray_ss(0);				
-------------------------------------------------------------------------------
-- Task 2: 	Generate the depth in each domain.
-------------------------------------------------------------------------------

				depth_rd <= (wrptr_ss) - (rdptr);
				depth_wr <= (wrptr) - (rdptr_ss);
				
-------------------------------------------------------------------------------
-- Task 3: 	Generate the empty and read enable signals
-------------------------------------------------------------------------------

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
---------------------------------------

-- Add the Code to generate empty and renq signals
-- Hint: It is similar to the generation of the full and wenq /

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

-------------------------------------------------------------------------------
-- Task 4: 	Complete the read-side clocked process. It is similar to the write_side clocked process.
-------------------------------------------------------------------------------
write_side_ptr:process (reset,wclk)
variable next_wrptr_var : std_logic_vector(4 downto 0);
  begin
	if (reset = '1') then
	wrptr <= "00000";
	wrptr_gray <= "00000";
	next_wrptr_var := "00000";
	rdptr_gray_s <= "00000";
	rdptr_gray_ss <= "00000";
	elsif(wclk'event and wclk = '1') then
		
		if (wenq = '1') then 
			wrptr <= wrptr + 1;
			next_wrptr_var := wrptr + 1;
			Reg_Array(CONV_INTEGER(wrptr(3 downto 0)))  <= data_in;  
			-- notice: it is (3 downto 0); not the complete (4 downto 0)
		else
			next_wrptr_var := wrptr;
		end if;
		wrptr_gray(0) <= next_wrptr_var(0) xor next_wrptr_var(1);
		wrptr_gray(1) <= next_wrptr_var(1) xor next_wrptr_var(2);
		wrptr_gray(2) <= next_wrptr_var(2) xor next_wrptr_var(3);
		wrptr_gray(3) <= next_wrptr_var(3) xor next_wrptr_var(4);
		wrptr_gray(4) <= next_wrptr_var(4);
		rdptr_gray_s <= rdptr_gray;
		rdptr_gray_ss <= rdptr_gray_s;
	end if;
  end process write_side_ptr;
  
read_side_ptr: process (reset, rclk)
variable next_rdptr_var : std_logic_vector(4 downto 0);
	begin
		if (reset = '1') then
			rdptr <= "00000";
			rdptr_gray <= "00000";
			next_rdptr_var := "00000";
			wrptr_gray_s <= "00000";
			wrptr_gray_ss <= "00000";
		elsif (rclk'event and rclk = '1') then
			if (renq = '1') then
				rdptr <= rdptr + 1;
				next_rdptr_var := rdptr + 1;
			else
				next_rdptr_var := rdptr;
			end if;
			
			rdptr_gray(0) <= next_rdptr_var(0) xor next_rdptr_var(1);
			rdptr_gray(1) <= next_rdptr_var(1) xor next_rdptr_var(2);
			rdptr_gray(2) <= next_rdptr_var(2) xor next_rdptr_var(3);
			rdptr_gray(3) <= next_rdptr_var(3) xor next_rdptr_var(4);
			rdptr_gray(4) <= next_rdptr_var(4);
			wrptr_gray_s <= wrptr_gray;
			wrptr_gray_ss <= wrptr_gray_s;
		end if;
	end process read_side_ptr;
data_out <= Reg_Array(CONV_INTEGER(rdptr(3 downto 0)));
---------------------------------------
-- Subtask 4: One of the things a digital designer does is pushing the logic across stage registers
-- to balance the delays or sometimes to avoid combinational logic upstream of syncronizing registers.
-- The following combinational logic is like a OFL downstream of wrptr register and it is upstream of 
-- the synchronizing flip-flops wrptr_gray_ss.
-- We know that the OFL outputs can be registered if the OFL inputs come from the "desired next state"
-- rather than the "current state". We use the same technique here to create registered wrptr_gray outputs
-- by pushing wrptr_gray generation in to the clocked process and using variable next_wrptr_var rather 
-- than the signal wrptr. 
-- Reference: Question #1 of homework #1 (question #1 of Spring 1997 EE560 Fianl exam):
-- See the transfermation of the original Moore machine #I to modified Moore machine #II
-- http://www-classes.usc.edu/engr/ee-s/560/ee560_HW1/EE560_HW1.pdf
---------------------------------------
-- Complete Subtask 4 before you write the read_side clocked process
-- You need to comment the following lines and push them up inside the write_side clocked process
-- In order to do that you need to use a variable such as next_wrptr_var
---------------------------------------
		-- wrptr_gray(0) <= wrptr(0) xor wrptr(1);
		-- wrptr_gray(1) <= wrptr(1) xor wrptr(2);
		-- wrptr_gray(2) <= wrptr(2) xor wrptr(3);
		-- wrptr_gray(3) <= wrptr(3) xor wrptr(4);
		-- wrptr_gray(4) <= wrptr(4);
		
---------------------------------------

-- Add your Code to implement the read_side clocked process
-- Hint: FIFO should always output the location pointed by the rdptr 


end behavefifo;	