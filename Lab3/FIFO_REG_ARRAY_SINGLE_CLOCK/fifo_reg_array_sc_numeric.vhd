
-- This file, fifo_reg_array_sc_numeric.vhd, is a copy of fifo_reg_array_sc.vhd, illustrating the use of 
--  IEEE numeric-std arithmetic package (ieee.numeric_std) in place of 
--  ieee.std_logic_arith and ieee.std_logic_unsigned

-- Please see at the bottom of this file 
-- some extracts from an internet blog site on this topic of using ieee.numeric_std
-- in place of ieee.std_logic_arith and ieee.std_logic_unsigned
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
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

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
	depth <= std_logic_vector(unsigned(wrptr) - unsigned(rdptr));
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
	data_out <= Reg_Array(TO_INTEGER(unsigned(rdptr((ADDR_WIDTH -1) downto 0)))); 
-------------------------------------------------
	fifo_process:process (clk)
		begin
			if (reset = '1') then
				wrptr <= N_plus_1_zeros; -- "00000";
				rdptr <= N_plus_1_zeros; -- "00000";
			elsif(clk'event and clk = '1') then				
				if (wenq = '1') then 
					Reg_Array(TO_INTEGER(unsigned(wrptr((ADDR_WIDTH -1) downto 0)))) <= data_in; 
					wrptr <= std_logic_vector(unsigned(wrptr) + 1);
				end if;
				if (renq = '1') then
					rdptr <= std_logic_vector(unsigned(rdptr) + 1);
				end if;				
			end if;
		end process fifo_process;
-------------------------------------------------
end architecture behv_fifo;	
-------------------------------------------------------------------------------
-- http://vhdlguru.blogspot.com/2010/03/why-library-numericstd-is-preferred.html

-- Thursday, March 25, 2010
-- Why the library "numeric_std" is preferred over "std_logic_arith" and others?
   -- This article is based on an email conversion I had with one VHDL expert.
   -- If you browse through some forums about VHDL then you may see some suggestions such as , 
   -- use "numeric_std" library instead of "std_logic_arith" and "std_logic_unsigned".
   -- I had this doubt before and here is what he(unfortunately i don't know his name) told me:

    -- std_logic_arith, etc. were packages written by Synopsis and included in their tools' 
	-- version of the ieee library, without the approval of the ieee standardization body. 
	-- The LRM (Language reference manual) reserves the ieee library for officially balloted 
	-- and approved packages for the vhdl language.However, since the whole world started 
	-- using synopsys first, and everyone had started writing code dependent upon std_logic_arith 
	-- being in ieee, Synopsys refused to take it out of their implementation. And since other 
	-- tools were usually forced to work seamlessly with code that worked with Synopsys, 
	-- they followed suit. However, different vendors implemented the package slightly differently, 
	-- with some problems in compatibility. Since there is no standard governing it, it is subject 
	-- to change at any time. 

     -- So, the IEEE decided to write and approve a standard package for numerical operations on 
	 -- SL(std_logic) and BIT based vectors. Those packages are called numeric_std and numeric_bit. 
	 -- These are ieee standard packages, located in the official version of the ieee library, 
	 -- and their behavior is governed by the standard, so compatibility is assured.
  
    -- Numeric_std does not attempt to imply a numerical interpretation on SLV(std_logic_vector) , 
	-- but rather defines related types UNSIGNED and SIGNED which have both numerical and bitwise 
	-- interpretations (i.e.AND and OR are also defined for them). This avoids any confusion when 
	-- needing to use both signed and unsigned arithmetic in the same body (std_logic_arith simply 
	-- assumes all arithmetic is unsigned). Numeric_std defines arithmetic operations between various 
	-- combinations of signed, unsigned and integer operands. In all cases(?) the size of the result 
	-- is the same as the largest signed/unsigned operand. Over/underflows are truncated (rolled over). 
     -- The latest version of the vhdl standard does include a package similar in function to 
	 -- std_logic_arith, etc., named numeric_std_unsigned, which does define unsigned arithmetic 
	 -- on std_logic_vector operands. Unfortunately, I know of no tools that support it yet.
     -- Generally, if you can, create your entity interfaces using unsigned or signed (or even integer) 
	 -- if they are uniformly numerically interpreted. (i.e. a generic memory device may be able to 
	 -- store any kind of binary data, so SLV may make more sense there, but a digital filter has a 
	 -- specific definition of its input data in mind, and that can be coded by using the appropriate 
	 -- type on the port). Using the appropriate types on the ports makes it much easier to avoid 
	 -- conversions within the body.

-- For example, if you used an SLV input port, and you need to add one to it and output that on an 
-- SLV output port, you must convert it twice: 
-- output <= std_logic_vector(unsigned(input) + 1); 
-- This converts the SLV input to unsigned (so that + is defined for it), adds (integer) one to it 
-- (the result is unsigned too), then converts the result back to SLV for the output port.It would 
-- have been much easier if input and output had been declared unsigned (or signed) in the first place:  
-- output <= input + 1;

    -- At the same time you shouldn't get the idea that "don't use SLV at all".Some places SLV is 
	-- better than UNSIGNED or SIGNED data type.For example, an ALU (Arithmetic and Logic Unit) 
	-- that accepts signed or unsigned data (depending on the operation control) may always have 
	-- a numeric interpretation of the data on its ports, but since we do not have a generic numeric 
	-- signed and unsigned representation, SLV would still be appropriate for those ports.Other 
	-- examples,where SLV is  a better option are any collection of bits that does not have a 
	-- numeric meaning such as a vector of enable bits, etc...
 
-- Note :- In the earlier codes I have heavily dependent on SLV.But in the recent posts 
-- I have started using SIGNED and UNSIGNED data types more frequently.
-------------------------------------------------------------------------------
-- http://vhdlguru.blogspot.com/2010/03/migrating-from-stdlogicvector-to.html
-- Saturday, March 27, 2010
-- Migrating from std_logic_vector to UNSIGNED or SIGNED data types
     -- Some days before I wrote another article about why the library "numeric_std" is preferred 
	 -- over "std_logic_arith" and others.In that article I have mentioned that use of 
	 -- synopsis IEEE library , such as STD_LOGIC_ARITH , STD_LOGIC_UNSIGNED and the like should 
	 -- be restricted unless you really need std_logic_vector in your design.If you want to know 
	 -- more about it click here.
     -- But most of the VHDL tutorial sites have examples based on the synopsis libraries.So as far 
	 -- as a beginner is concerned it is difficult for him to migrate suddenly from std_logic_arith 
	 -- to numeric_std.This article is for them.
-- In the earlier part of this blog I have written a code for BCD to 7- segment converter using the 
-- Synopsis IEEE library such as std_logic_arith and std_logic_unsigned.That article can be read here. 
-- I have written the same code in this article using the library NUMERIC_STD.There are only minor 
-- changes applied to the code,but still I think it will really help beginners.


-- Given below is the converter code:

-- library IEEE;
-- use IEEE.STD_LOGIC_1164.ALL;
-- ---------------------------------
-- --use IEEE.STD_LOGIC_ARITH.ALL;
-- --use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- ---------------------------------
-- use IEEE.NUMERIC_STD.ALL;

-- entity test is
-- port (
         -- clk : in std_logic;
-- ------------------------------------------------------------------
-- --        bcd : in std_logic_vector(3 downto 0);  
-- --        segment7 : out std_logic_vector(6 downto 0);  
-- ------------------------------------------------------------------
        -- bcd : in UNSIGNED(3 downto 0); 
        -- segment7 : out UNSIGNED(6 downto 0) 
    -- );
-- end test;

-- architecture Behavioral of test is

-- begin

-- process (clk,bcd)
-- BEGIN
-- if (clk'event and clk='1') then 
-- case  bcd is
-- when "0000"=> segment7 <="0000001"; 
-- when "0001"=> segment7 <="1001111"; 
-- when "0010"=> segment7 <="0010010"; 
-- when "0011"=> segment7 <="0000110"; 
-- when "0100"=> segment7 <="1001100"; 
-- when "0101"=> segment7 <="0100100"; 
-- when "0110"=> segment7 <="0100000"; 
-- when "0111"=> segment7 <="0001111"; 
-- when "1000"=> segment7 <="0000000";
-- when "1001"=> segment7 <="0000100"; 
-- when others=> segment7 <="1111111";
-- end case;
-- end if;

-- end process;

-- end Behavioral;

-- The commented part of the code(shown in green colour) is from the original code given here.

-- The testbench of the above code is given below:

-- LIBRARY ieee;
-- USE ieee.std_logic_1164.ALL;
-- ---------------------------------
-- --use IEEE.STD_LOGIC_ARITH.ALL;
-- --use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- ---------------------------------
-- use IEEE.NUMERIC_STD.ALL;

-- ENTITY test_tb IS
-- END test_tb;

-- ARCHITECTURE behavior OF test_tb IS
   -- signal clk : std_logic := '0';
-- ------------------------------------------------------------------      
-- --   signal bcd : std_logic_vector(3 downto 0) := (others => '0');
-- --   signal segment7 : std_logic_vector(6 downto 0);    
-- ------------------------------------------------------------------
   -- signal bcd : UNSIGNED(3 downto 0) := (others => '0');
   -- signal segment7 : UNSIGNED(6 downto 0);
   -- constant clk_period : time := 1 ns;
-- BEGIN
   -- uut: entity work.test PORT MAP (clk,bcd,segment7);

   -- clk_process :process
   -- begin
                -- clk <= '0';
               -- wait for clk_period/2;
                -- clk <= '1';
                -- wait for clk_period/2;
   -- end process;     

   -- stim_proc: process
   -- begin   
-- ------------------------------------------------------------------      
-- --      for i in 0 to 9  loop
-- --           bcd <= conv_std_logic_vector(i,4);
-- --          wait for 2 ns;
-- --      end loop;
-- ------------------------------------------------------------------              
           -- bcd <=bcd + 1;
                -- if(bcd = "1001") then
                        -- bcd <="0000";
                -- end if;
          -- wait for 2 ns;
   -- end process;

-- END;

     -- So I hope, it is not that difficult to migrate to the official IEEE library.
	 -- You can try changing the counter code given here, your own and see the results.
	 -- If you have any difficulties doing so please contact me.
-------------------------------------------------------------------------------
