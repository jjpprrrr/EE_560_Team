-------------------------------------------------------------------------------
-- File name: 	: fifo_reg_array_sc_n_bit_pointers.vhd (sc = single clock)
-- Design       : fifo_reg_array_sc 
-- Project      : FIFO using register array(single clock)
-- Author       : Gandhi Puvvada
-- Company      : University of Southern California 
-- Date			: 6/19/2010
-- Here, we use only n-bit pointers for wrptr and rdptr, instead of (n+1) bit pointers.
-- So, we need to record if most recently, we have seenteh fifo running almost_empty
--   or almost_full, so that when the two pointers meet, we know, if the fifo is actually
--   full or empty. This is possible only if we have a single clock fifo.
-- To make it generic, yet be able to have meaningfull thresholds, I have assumed that the 
-- FIFO is 16-locations or more deep. N = ADDR_WIDTH shall be 4 or more for this code.
-- I thought this assumption is necessary so as to make the following line good:
-- constant N_minus_2_zeros : std_logic_vector(ADDR_WIDTH-3 downto 0) := (others => '0'); 
-- However, even with N = 2 teh design simulates well, though we can not write (-1 downto 0) !
-------------------------------------------------------------------------------
-- let us keep the name of the entity same so that we can use the same testbench
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity fifo_reg_array_sc is
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
end fifo_reg_array_sc ; 
-------------------------------------------------------------------------------
architecture behv_fifo of fifo_reg_array_sc is 

	signal rdptr 		: std_logic_vector(ADDR_WIDTH-1 downto 0); -- read pointer in binary
							-- previously it was (ADDR_WIDTH downto 0)
	signal wrptr 		: std_logic_vector(ADDR_WIDTH-1 downto 0); -- write pointer in binary
							-- previously it was (ADDR_WIDTH downto 0)

	signal depth		: std_logic_vector(ADDR_WIDTH-1 downto 0); 
							-- previously it was (ADDR_WIDTH downto 0)
	signal wenq			: std_logic;
	signal renq			: std_logic;
	signal full_int		: std_logic;
	signal empty_int	: std_logic;

	type Reg_Array_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector((DATA_WIDTH-1) downto 0); 
	signal Reg_Array : Reg_Array_type;

	signal AE_AF_flag 		: std_logic; -- zero means almost emplty (AE) and one means almost full (AF)
	signal raw_almost_empty	: std_logic;
	signal raw_almost_full 	: std_logic;
	constant N_minus_2_zeros : std_logic_vector(ADDR_WIDTH-3 downto 0) := (others => '0'); 
	constant N_minus_2_ones  : std_logic_vector(ADDR_WIDTH-3 downto 0) := (others => '1');
	constant lower_of_lower_two_thresholds  : std_logic_vector(ADDR_WIDTH-1 downto 0) := ('0' & '1' & N_minus_2_zeros); 
	constant upper_of_lower_two_thresholds  : std_logic_vector(ADDR_WIDTH-1 downto 0) := ('0' & '1' & N_minus_2_ones); 
	constant lower_of_higher_two_thresholds : std_logic_vector(ADDR_WIDTH-1 downto 0) := ('1' & '0' & N_minus_2_zeros); 
	constant upper_of_higher_two_thresholds : std_logic_vector(ADDR_WIDTH-1 downto 0) := ('1' & '0' & N_minus_2_ones); 
	constant N_zeros : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0'); 
	-------------------------------------------------------------------------------
begin
-------------------------------------------------
	empty <= empty_int;
	full <= full_int;
	depth <= (wrptr) - (rdptr);
	
-------------------------------------------------
	-- Task #1: Write two concurrent statements to generate raw_almost_empty and raw_almost_full signals
	-- Hint: You should use the four thresholds constants defined above 
	raw_almost_empty <= '1' when (depth >= lower_of_lower_two_thresholds) and (depth <= upper_of_lower_two_thresholds) else '0';--
	raw_almost_full  <= '1' when (depth >= lower_of_higher_two_thresholds) and (depth <= upper_of_higher_two_thresholds) else '0';--
	
-------------------------------------------------
	-- Task #2: Complete the following process which responsible for setting and resetting the AE_AF_flag
	-- Hint: At the reset the flag should indicate that the FIFO is empty
	-- Question: Is it necessary that we use a clk process for AE_AF_process or it could be pure combinational?
	AE_AF_process:process (reset,clk)
		begin
		-- Add your Code
		if (reset = '1') then 
			AE_AF_flag <= '0';
		elsif (clk'event and clk = '1') then
			if (raw_almost_empty = '1') then
				AE_AF_flag <= '0';
			elsif (raw_almost_full = '1') then
				AE_AF_flag <= '1';
			end if;
		end if;
		end process AE_AF_process;
		
-------------------------------------------------
	-- Task #3: Complete the following process which responsible for generating empty_int and full_int signals
	-- Hint: Make sure that both signals are set to '0' when the FIFO is neither empty nor full and they should not
	--       retain their old values
	empty_full_check_process : process (depth, AE_AF_flag)
		begin
		-- Add your Code
		if (depth = "0000") then
			if (AE_AF_flag = '0') then
				empty_int <= '1';
				full_int <= '0';
			else
				empty_int <= '0';
				full_int <= '1';
			end if;
		end if;
		end process empty_full_check_process;

-------------------------------------------------
	wenq <= (not full_int) and wen;
	renq <= (not empty_int) and ren;
	data_out <= Reg_Array(CONV_INTEGER(rdptr((ADDR_WIDTH -1) downto 0))); 
	
-------------------------------------------------
	fifo_process:process (reset,clk)
		begin
			if (reset = '1') then
				wrptr <= N_zeros;
				rdptr <= N_zeros;
			elsif(clk'event and clk = '1') then				
				if (wenq = '1') then 
					Reg_Array(CONV_INTEGER(wrptr((ADDR_WIDTH -1) downto 0))) <= data_in; 
					wrptr <= (wrptr) + 1;
				end if;
				if (renq = '1') then
					rdptr <= (rdptr) + 1;
				end if;				
			end if;
		end process fifo_process;
-------------------------------------------------
end architecture behv_fifo;	