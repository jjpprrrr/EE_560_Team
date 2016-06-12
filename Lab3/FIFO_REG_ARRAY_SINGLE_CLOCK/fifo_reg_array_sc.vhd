-------------------------------------------------------------------------------
-- File name: 	: fifo_reg_array_sc.vhd (sc = single clock)
-- Design       : fifo_reg_array_sc 
-- Project      : FIFO using register array(single clock)
-- Author       : Pritish Malavade and Gandhi Puvvada
-- Company      : University of Southern California 
-- Date			: 6/19/2010
-------------------------------------------------------------------------------
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

	signal rdptr 		: std_logic_vector(ADDR_WIDTH downto 0); -- read pointer in binary
	signal wrptr 		: std_logic_vector(ADDR_WIDTH downto 0); -- write pointer in binary

	signal depth		: std_logic_vector(ADDR_WIDTH downto 0); 
	signal wenq			: std_logic;
	signal renq			: std_logic;
	signal full_int		: std_logic;
	signal empty_int	: std_logic;

	type Reg_Array_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector((DATA_WIDTH-1) downto 0); 
	signal Reg_Array : Reg_Array_type;
	constant N_plus_1_zeros : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
	-- constant A_1_and_N_zeros : std_logic_vector(ADDR_WIDTH downto 0) := (ADDR_WIDTH => '1', others => '0');
	-- The above line is OK, but causes a compile-time warning. So we have the following two lines:
	constant N_zeros : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	constant A_1_and_N_zeros : std_logic_vector(ADDR_WIDTH downto 0) := ('1' & N_zeros);
-------------------------------------------------------------------------------
begin
-------------------------------------------------
	depth <= wrptr - rdptr;
	---------------------------------
	empty <= empty_int;
	full <= full_int;
	empty_full_check_process : process (depth)
		begin
			empty_int <= '0' ;
			full_int <= '0';
			if (depth = N_plus_1_zeros) then -- if (depth = "00000") then 
				empty_int <= '1' ; 
			end if;
			if (depth = A_1_and_N_zeros) then -- if (depth = "10000") then
				full_int <= '1' ;
			end if;			
		end process empty_full_check_process;
	---------------------------------
	wenq <= (not full_int) and wen;
	renq <= (not empty_int) and ren;
	---------------------------------
	data_out <= Reg_Array(CONV_INTEGER(rdptr((ADDR_WIDTH -1) downto 0))); 
-------------------------------------------------
	fifo_process:process (clk)
		begin
			if (reset = '1') then
				wrptr <= N_plus_1_zeros; -- "00000";
				rdptr <= N_plus_1_zeros; -- "00000";
			elsif(clk'event and clk = '1') then				
				if (wenq = '1') then 
					Reg_Array(CONV_INTEGER(wrptr((ADDR_WIDTH -1) downto 0))) <= data_in; 
					wrptr <= wrptr + 1;
				end if;
				if (renq = '1') then
					rdptr <= rdptr + 1;
				end if;				
			end if;
		end process fifo_process;
-------------------------------------------------
end architecture behv_fifo;	