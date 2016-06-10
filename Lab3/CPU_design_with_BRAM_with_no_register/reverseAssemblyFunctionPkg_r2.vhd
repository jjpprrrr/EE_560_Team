-- Written 7/06/2008 Nasir Mohyuddin and Gandhi Puvvada
-- file reverseAssemblyFunctionPkg_r1.vhd
-- A package file to reverse assemble a given 32-bit MIPs instruction
-- Note: For Branch and Jump instructions, 
-- the 16-bit signed word offset of the branch and the
-- 26-bit word destination address of the jump are stated in the 
-- mnemonic string form of the instructions respectively.

-- Revision #2: 7/29/09 Added MULT and DIV instructions to the reverse assembler
-- These MULT and DIV instructions are different from the real MIPs
-- MULTU and DIV instructions as these have the Rd field in bits [15:11]
-- instead of the 00000 in the MIPs.
----------------------------------------------------------
library std, ieee;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

package reverseAssemblyFunctionPkg is

function reverse_Assembly(ins: std_logic_vector)
	return string;

end package reverseAssemblyFunctionPkg;

package body reverseAssemblyFunctionPkg is


-- Functions

	function get_itypeext(ins: std_logic_vector)
	return integer is
          variable tmp: integer range -32768 to 32767;
	begin
	      tmp := conv_integer(ins(14 downto 0));
              if (ins(15)='0') then tmp := tmp;
              else tmp := tmp - 32768;
              end if;
          return tmp;
	end;

	function get_regnumstring(a: integer)
	return string is
        variable tmp: string(1 to 6) := (others => ' ');
	begin
	  case a is
		when 0 => tmp := "  $0  ";
		when 1 => tmp := "  $1  ";
		when 2 => tmp := "  $2  ";
		when 3 => tmp := "  $3  ";
		when 4 => tmp := "  $4  ";
		when 5 => tmp := "  $5  ";
		when 6 => tmp := "  $6  ";
		when 7 => tmp := "  $7  ";
		when 8 => tmp := "  $8  ";
		when 9 => tmp := "  $9  ";
		when 10 => tmp := "  $10 ";
		when 11 => tmp := "  $11 ";
		when 12 => tmp := "  $12 ";
		when 13 => tmp := "  $13 ";
		when 14 => tmp := "  $14 ";
		when 15 => tmp := "  $15 ";
		when 16 => tmp := "  $16 ";
		when 17 => tmp := "  $17 ";
		when 18 => tmp := "  $18 ";
		when 19 => tmp := "  $19 ";
		when 20 => tmp := "  $20 ";
		when 21 => tmp := "  $21 ";
		when 22 => tmp := "  $22 ";
		when 23 => tmp := "  $23 ";
		when 24 => tmp := "  $24 ";
		when 25 => tmp := "  $25 ";
		when 26 => tmp := "  $26 ";
		when 27 => tmp := "  $27 ";
		when 28 => tmp := "  $28 ";
		when 29 => tmp := "  $29 ";
		when 30 => tmp := "  $30 ";
		when 31 => tmp := "  $31 ";
		when others => tmp := "  $NO ";
	  end case;
	  return tmp;
	end;

	function get_regnumstring_para(a: integer)
	return string is
        variable tmp: string(1 to 6) := (others => ' ');
	begin
	  case a is
		when 0 => tmp := " ($0) ";
		when 1 => tmp := " ($1) ";
		when 2 => tmp := " ($2) ";
		when 3 => tmp := " ($3) ";
		when 4 => tmp := " ($4) ";
		when 5 => tmp := " ($5) ";
		when 6 => tmp := " ($6) ";
		when 7 => tmp := " ($7) ";
		when 8 => tmp := " ($8) ";
		when 9 => tmp := " ($9) ";
		when 10 => tmp := " ($10)";
		when 11 => tmp := " ($11)";
		when 12 => tmp := " ($12)";
		when 13 => tmp := " ($13)";
		when 14 => tmp := " ($14)";
		when 15 => tmp := " ($15)";
		when 16 => tmp := " ($16)";
		when 17 => tmp := " ($17)";
		when 18 => tmp := " ($18)";
		when 19 => tmp := " ($19)";
		when 20 => tmp := " ($20)";
		when 21 => tmp := " ($21)";
		when 22 => tmp := " ($22)";
		when 23 => tmp := " ($23)";
		when 24 => tmp := " ($24)";
		when 25 => tmp := " ($25)";
		when 26 => tmp := " ($26)";
		when 27 => tmp := " ($27)";
		when 28 => tmp := " ($28)";
		when 29 => tmp := " ($29)";
		when 30 => tmp := " ($30)";
		when 31 => tmp := " ($31)";
		when others => tmp := " ($NO)";
	  end case;
	  return tmp;
	end;

	function get_instrtype(op: integer; func: integer)
	return string is
        variable tmp: string(1 to 6) := (others => ' ');
	begin
	  case op is
		when 0 => if (func=32) then tmp := "ADD   ";
                  elsif (func=42)  then tmp := "SLT   ";
                  elsif (func=34)  then tmp := "SUB   ";
                  elsif (func=36)  then tmp := "AND   ";
                  elsif (func=37)  then tmp := "OR    ";
                  elsif (func=25)  then tmp := "MULT  "; -- added 7/29/2008
                  -- elsif (func=25)  then tmp : := "MULTU ";                 -- commented out 7/29/2008
				  elsif (func=16)  then tmp := "MFHI  ";
                  elsif (func=18)  then tmp := "MFLO  ";
				  elsif (func=27)  then tmp := "DIV   "; -- added 7/29/2008
                  else tmp := "ERROR ";
                  end if;
		when 35 => tmp := "LW    ";
		when 43 => tmp := "SW    ";
		when 4  => tmp := "BEQ   ";
        when 5  => tmp := "BNE   ";          
		when 2  => tmp := "J     ";
		when others => tmp := "ERROR ";
	  end case;
	  return tmp;
	end;
    
	function reverse_Assembly(ins: std_logic_vector)
	return string is
        variable outline1 : line;
        variable outline2 : line;
        variable tmpr_str : string(1 to 6) := (others => ' ');
        variable tmpi_str : string(1 to 6) := (others => ' ');
        variable tmp1 : integer range -32768 to 32767;
        variable tmp2 : integer range 0 to 67108863;
        variable rd_str : string(1 to 6) := (others => ' ');
        variable rs_str : string(1 to 6) := (others => ' ');
        variable rs_str_para : string(1 to 6) := (others => ' ');
        variable rt_str : string(1 to 6) := (others => ' ');
        variable ext_str : string(1 to 6) := (others => ' ');
        variable jadd_str : string(1 to 18) := (others => ' ');
        variable blanks_12_str : string(1 to 12) := (others => ' ');
        variable blanks_6_str  : string(1 to 6)  := (others => ' ');        
        variable outmsg : string(1 to 24) := (others => ' ');

	begin
          tmpr_str := get_instrtype(0,conv_integer(ins(5 downto 0)));
          tmpi_str := get_instrtype(conv_integer(ins(31 downto 26)),0);
          
          rd_str := get_regnumstring(conv_integer(ins(15 downto 11)));
          rs_str := get_regnumstring(conv_integer(ins(25 downto 21)));
          rs_str_para := get_regnumstring_para(conv_integer(ins(25 downto 21)));
          rt_str := get_regnumstring(conv_integer(ins(20 downto 16)));
          
          tmp1 := get_itypeext(ins(15 downto 0));  -- for beq and lw/sw
          
          write(outline1,tmp1,right,6);
                         
          read(outline1,ext_str);
          
          
          if (conv_integer(ins(31 downto 26))=0) then -- R type
            if (conv_integer(ins(5 downto 0))=16 or conv_integer(ins(5 downto 0))=18)
               then outmsg := tmpr_str & rd_str & blanks_12_str; -- mfhi of mflo
            -- elsif (conv_integer(ins(5 downto 0))=25) then                               -- commented out 7/29/2008
            --  outmsg := tmpr_str & rs_str & rt_str & blanks_6_str; -- multu     -- commented out 7/29/2008
            else
              outmsg := tmpr_str & rd_str & rs_str & rt_str;
            end if;
          elsif (conv_integer(ins(31 downto 26))=35 or conv_integer(ins(31 downto 26))=43) -- lw/sw 
             then outmsg := tmpi_str & rt_str & ext_str & rs_str_para;
          elsif (conv_integer(ins(31 downto 26))=4) -- beq 
             then outmsg := tmpi_str & rs_str & rt_str & ext_str;
          elsif (conv_integer(ins(31 downto 26))=5) -- bne 
             then outmsg := tmpi_str & rs_str & rt_str & ext_str;
          elsif (conv_integer(ins(31 downto 26))=2) then -- j 
             tmp2 := conv_integer(ins(25 downto 0));  -- for j  
			 write(outline2,tmp2,left,18);
			 read(outline2,jadd_str);
			 outmsg := tmpi_str & jadd_str;
          else outmsg := "   UNKNOWN INSTR TYPE   ";
          end if;
	  return outmsg;
	end;
  
end package body reverseAssemblyFunctionPkg;  
