-- File: ee560_sync_counter_mix_of_variables_and_signals_structured_tb.vhd (translation into VHDL of the verilog file: ee201L_sync_counter_mix_of_blocking_and_non_blocking_structured_tb.v)
-- Written by Rahul Badghare
-- Further refined by Gandhi Puvvada  6/17/2012
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity ee560_sync_counter_mix_of_variables_and_signals_structured_tb is
end entity  ee560_sync_counter_mix_of_variables_and_signals_structured_tb;

architecture testbench of ee560_sync_counter_mix_of_variables_and_signals_structured_tb is

	signal Clk_cnt: natural range 0 to 255;
	constant CLK_PERIOD: time := 20 ns;


signal clk_tb, clr_tb, load_tb, jump_tb, en_tb: std_logic;
signal BA_tb : std_logic_vector(4 downto 0);
signal Q_tb : std_logic_vector(4 downto 0);

component ee560_sync_counter_with_jump
port (	clk, clr, load, jump, en: in std_logic;
		BA: in std_logic_vector(4 downto 0); -- Branch Address (load value)
		Q: out std_logic_vector(4 downto 0)
	 );
end component;

begin

	UUT: ee560_sync_counter_with_jump port map ( clk_tb, clr_tb, load_tb, jump_tb, en_tb, BA_tb, Q_tb);
			 

	CLK_GENERATOR :process
	   begin
		clk_tb <= '0';
		wait for CLK_PERIOD/2;
		clk_tb <= '1';
		wait for CLK_PERIOD/2;
	   end process;


	CLK_COUNTER : process (clk_tb)
	begin
	  if clk_tb'event and clk_tb = '1' then
		Clk_cnt <= Clk_cnt + 1;
	  end if;
	end process;

	STIMULUS : process
		file my_outfile : text open WRITE_MODE is "ee560_sync_counter_results.txt";
		variable my_line : line;
	begin
		-- clear the counter
		 clr_tb <= '1'; load_tb <= 'X'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "XXXXX";

		 wait for (2.1 * CLK_PERIOD);
		-- After 2 clocks (and a little after 0.1 of the clock period), confirm the superiority of clear over the rest of the controls
		 clr_tb <= '1'; load_tb <= 'X'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "XXXXX";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= '1'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "00111";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= '0'; jump_tb <= '1';  en_tb <= 'X'; BA_tb <= "XXXXX";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= '0'; jump_tb <= '0';  en_tb <= '1'; BA_tb <= "00110";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= '1'; jump_tb <= '1';  en_tb <= '1'; BA_tb <= "00110";

		-- A variety of mixed transaction (excluding jump)
		 wait for (1.0 * CLK_PERIOD); clr_tb <= '0'; load_tb <= '1'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "00101";
		 wait for (1.0 * CLK_PERIOD); clr_tb <= '1'; load_tb <= 'X'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "XXXXX";


		 wait for (3.0 * CLK_PERIOD);
		 clr_tb <= '0'; load_tb <= '1'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "00100";
		 wait for (2.0 * CLK_PERIOD);
		 clr_tb <= '0'; load_tb <= '0'; jump_tb <= '0';  en_tb <= '1'; BA_tb <= "XXXXX";
		 wait for (19.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= 'X'; jump_tb <= '0';  en_tb <= 'X'; BA_tb <= "XXXXX";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '0'; load_tb <= '1'; jump_tb <= '0';  en_tb <= 'X'; BA_tb <= "00101";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= 'X'; jump_tb <= '0';  en_tb <= 'X'; BA_tb <= "XXXXX";
		 wait for (1.0 * CLK_PERIOD);
		 clr_tb <= '0'; load_tb <= '1'; jump_tb <= '0';  en_tb <= 'X'; BA_tb <= "00100";
		 wait for (2.0 * CLK_PERIOD);
		 clr_tb <= '0'; load_tb <= '0'; jump_tb <= '0';  en_tb <= '1'; BA_tb <= "XXXXX";
		 wait for (6.0 * CLK_PERIOD);
		 clr_tb <= '1'; load_tb <= 'X'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "XXXXX";

		-- Below we are testing the "JUMP" operation by loading a test value into the counter and jumping from there.
		-- Initially we load 5'b00000 and keep jumping from there for 8 clocks (8 clocks corresponding to the 8 "=>" in line below).
		-- You see that we go from 0 => 14 => 15 => 16 => 17 => 18 => 19 => 20 => 20


		 wait for (1.0 * CLK_PERIOD);
		-- load 5'b00000
		 clr_tb <= '0'; load_tb <= '1'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= "00000";
		 wait for (1.0 * CLK_PERIOD);
		 write (my_line, string'("Loaded count = ")); -- $display ("\nLoaded count = %d \n", Q_tb);
		 write (my_line, CONV_INTEGER(Q_tb), right, 2);
		 write (my_line, string'(" "));
		 writeline (my_outfile, my_line);
		 write (my_line, string'(""));
		 writeline (my_outfile, my_line);
		-- start jumping
		 clr_tb <= '0'; load_tb <= '0'; jump_tb <= '1';  en_tb <= 'X'; BA_tb <= "XXXXX";
		 wait for (1.0 * CLK_PERIOD); write (my_line, string'("Jumped to count = ")); --$display ("Jumped to count = %d", Q_tb);
		 write (my_line, CONV_INTEGER(Q_tb));
		 writeline (my_outfile, my_line);
		 wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
		wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
		wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
		wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
		wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
		wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
		wait for (1.0 * CLK_PERIOD); write (my_line, string'("Further jumped to count = ")); --$display ("Further jumped to count = %d", Q_tb);
		write (my_line, CONV_INTEGER(Q_tb));
			 writeline (my_outfile, my_line);
			 write (my_line, string'("Initial JUMP test completed. ")); --$display ("Initial JUMP test completed. \n \n");
			 writeline (my_outfile, my_line);
			 write (my_line, string'(""));
			 writeline (my_outfile, my_line);
			 write (my_line, string'(""));
			 writeline (my_outfile, my_line);
	--       enabled counter to increment causing roll-over
			 clr_tb <= '0'; load_tb <= '0'; jump_tb <= '0';  en_tb <= '1'; BA_tb <= "XXXXX";
	--       After 3 clocks, it remains stay-put for 2 clocks
			 wait for (3.0 * CLK_PERIOD);
			 clr_tb <= '0'; load_tb <= '0'; jump_tb <= '0';  en_tb <= '0'; BA_tb <= "XXXXX";
			 wait for (2.0 * CLK_PERIOD);

		 for i in 0 to 20 loop --(i = 0; i <= 20; i = i+1)
							-- load I
							 clr_tb <= '0'; load_tb <= '1'; jump_tb <= 'X';  en_tb <= 'X'; BA_tb <= CONV_STD_LOGIC_VECTOR(I,5);
							 wait for (1.0 * CLK_PERIOD);
							 write (my_line, string'("Loaded count = "));--$write ("Loaded count = %d", Q_tb);
							 write (my_line, CONV_INTEGER(Q_tb), right, 2);
							-- jump
							 clr_tb <= '0'; load_tb <= '0'; jump_tb <= '1';  en_tb <= 'X'; BA_tb <= "XXXXX";
							 wait for (1.0 * CLK_PERIOD);
							 write (my_line, string'(".        Jumped to count = ")); --$display (".        Jumped to count = %d", Q_tb);
							 write (my_line, CONV_INTEGER(Q_tb), right, 2);
							 writeline (my_outfile, my_line);
					end loop;
			wait;
end process;
  
end architecture testbench;

------------------------------------------------------------------------------