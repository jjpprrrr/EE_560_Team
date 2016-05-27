--------------------------------------------------------------------------------
-- Copyright (c) 1995-2003 Xilinx, Inc.
-- All Right Reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    Vendor: Xilinx 
-- \   \   \/     Version : 10.1.03
--  \   \         Application : ISE
--  /   /         Filename : parity_vhdl_tb.vhd
-- /___/   /\     Timestamp : Tue May 21 11:10:54 2013
-- \   \  /  \ 
--  \___\/\___\ 
--
--Command: 
--Design Name: parity_vhdl
--Device: Xilinx
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY parity_vhdl_tb_selfcheck_beh IS
END parity_vhdl_tb_selfcheck_beh;

ARCHITECTURE testbench_arch OF parity_vhdl_tb_selfcheck_beh IS
    COMPONENT parity_vhdl
        PORT (
            in_data : In std_logic_vector (31 DownTo 0);
            parity : Out std_logic
        );
    END COMPONENT;

    SIGNAL in_data : std_logic_vector (31 DownTo 0) := "00000000000000000000000000000001";
    SIGNAL parity : std_logic := 'X';

    SHARED VARIABLE TX_ERROR : INTEGER := 0;
    SHARED VARIABLE TX_OUT : LINE;

    BEGIN
        UUT : parity_vhdl
        PORT MAP (
            in_data => in_data,
            parity => parity
        );

        PROCESS
            PROCEDURE CHECK_parity(
                next_parity : std_logic;
                TX_TIME : INTEGER
            ) IS
                VARIABLE TX_STR : String(1 to 4096);
                VARIABLE TX_LOC : LINE;
                BEGIN
                IF (parity /= next_parity) THEN
                    STD.TEXTIO.write(TX_LOC, string'("Error at time="));
                    STD.TEXTIO.write(TX_LOC, TX_TIME);
                    STD.TEXTIO.write(TX_LOC, string'("ns parity="));
                    IEEE.STD_LOGIC_TEXTIO.write(TX_LOC, parity);
                    STD.TEXTIO.write(TX_LOC, string'(", Expected = "));
                    IEEE.STD_LOGIC_TEXTIO.write(TX_LOC, next_parity);
                    STD.TEXTIO.write(TX_LOC, string'(" "));
                    TX_STR(TX_LOC.all'range) := TX_LOC.all;
                    STD.TEXTIO.Deallocate(TX_LOC);
                    ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
                    TX_ERROR := TX_ERROR + 1;
                END IF;
            END;
            BEGIN
                -- -------------  Current Time:  50ns
                WAIT FOR 50 ns;
                CHECK_parity('1', 50);
                -- -------------------------------------
                -- -------------  Current Time:  100ns
                WAIT FOR 50 ns;
                in_data <= "00000000000000000000000000000010";
                -- -------------------------------------
                -- -------------  Current Time:  200ns
                WAIT FOR 100 ns;
                in_data <= "00000000000000000000000000000011";
                -- -------------------------------------
                -- -------------  Current Time:  250ns
                WAIT FOR 50 ns;
                CHECK_parity('0', 250);
                -- -------------------------------------
                -- -------------  Current Time:  300ns
                WAIT FOR 50 ns;
                in_data <= "00000000000000000000000000000100";
                -- -------------------------------------
                -- -------------  Current Time:  350ns
                WAIT FOR 50 ns;
                CHECK_parity('1', 350);
                -- -------------------------------------
                -- -------------  Current Time:  400ns
                WAIT FOR 50 ns;
                in_data <= "00000000000000000000000000000101";
                -- -------------------------------------
                -- -------------  Current Time:  450ns
                WAIT FOR 50 ns;
                CHECK_parity('0', 450);
                -- -------------------------------------
                -- -------------  Current Time:  500ns
                WAIT FOR 50 ns;
                in_data <= "00001111111111111111111111111110";
                -- -------------------------------------
                -- -------------  Current Time:  550ns
                WAIT FOR 50 ns;
                CHECK_parity('1', 550);
                -- -------------------------------------
                -- -------------  Current Time:  600ns
                WAIT FOR 50 ns;
                in_data <= "11111111111111111111111111111111";
                -- -------------------------------------
                -- -------------  Current Time:  650ns
                WAIT FOR 50 ns;
                CHECK_parity('0', 650);
                -- -------------------------------------
                WAIT FOR 350 ns;

                IF (TX_ERROR = 0) THEN
                    STD.TEXTIO.write(TX_OUT, string'("No errors or warnings"));
                    ASSERT (FALSE) REPORT
                      "Simulation successful (not a failure).  No problems detected."
                      SEVERITY FAILURE;
                ELSE
                    STD.TEXTIO.write(TX_OUT, TX_ERROR);
                    STD.TEXTIO.write(TX_OUT,
                        string'(" errors found in simulation"));
                    ASSERT (FALSE) REPORT "Errors found during simulation"
                         SEVERITY FAILURE;
                END IF;
            END PROCESS;

    END testbench_arch;

