------------------------------------------------------------------------------
-- Copyright (c) 2005 by Gandhi Puvvada, EE-Systems, USC, Los Angeles, CA 90089

--	Written by Gandhi Puvvada  gandhi@usc.edu Date: 2/6/04, 6/2/05, 6/1/08, 6/10/2012

--	File name: divider_top.vhd  -- written to suit Nexys2 - 1200 used in Summer 2008
										 -- converted to suit Nexys3 - 1600 used in Summer 2012

-- Set your DIVIDEND on sw7-sw4, DIVISOR on sw3-sw0
-- Press BtnL for "start" and BtnR for "ack"

-- When you compile this file on webpack/ISE, do not forget to specify the JTAG
-- clock as the Startup clock (since we are using the JTAG programming mode) as follows:
-- Generate Programming File => Properties => Startup options => Startup clock => JTAG clock
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.VComponents.all; -- Xilinx primitive BUFGP

entity divider_top is

port	(ClkPort:  in std_logic;
	    sw0, sw1, sw2, sw3, sw4, sw5, sw6, sw7, sw8, sw9, sw10, sw11, sw12, sw13, sw14, sw15: in std_logic;
		 BtnL, BtnR, BtnC: in std_logic;	             -- the Left, Up, Right, Down, and Center buttons
	    LD15, LD14, LD13, LD12, LD11, LD10, LD9, LD8, LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0: out std_logic; -- LD(7-4) indicate the quotient, LD(3-0) indicate remainder
	    ca, cb, cc, cd, ce, cf, cg, dp: out std_logic;
	    AN0, AN1, AN2, AN3: out std_logic
	    --MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS : out std_logic -- Nexys3
		);
end  divider_top ;
------------------------------------------------------------------------------
architecture divider_top_arc of divider_top   is
	------------
	signal RESET: std_logic; -- pressing btn3 means RESET
	signal BCLK: std_logic; -- buffered clock
	signal clk : std_logic; -- divided clock
	
	signal xin, yin, q, r:    std_logic_vector(7 downto 0);
	signal start, ack, done, resetb :        std_logic;
	------------	
	--component declarations done here
	------------	
	component divider 
	
	  port (
		xin, yin: IN std_logic_vector(7 downto 0); -- dividend, divisor
		start, ack: IN  std_logic;
		clk, resetb: IN  std_logic;
		q, r: OUT std_logic_vector(7 downto 0);
		done: OUT std_logic
		);
	
	end component;
	------------	
	--bufgp for clock

   component BUFGP

         port (I: in std_logic; O: out std_logic);

   end component;
   ------------

begin
	------------
	BUF_GP_1:   BUFGP   port map (I => CLKPORT, O => BCLK); 
	
	RESET <= BtnC;		 -- You reset by pushing BtnC
	
	resetb <= not (RESET); -- low active reset for the core design
	
	-- Disable the memories so that they do not interfere with the rest of the design.
	--MemOE <= '1';  RamCS <= '1';  
	--MemWR <= '1';  FlashCS <= '1';  QuadSpiFlashCS <= '1'; 
	
	
	clk <= BCLK; -- Usually we let students work at a low frequency
	             -- But here we are giving the high-speed 100 MHz clock to user design 
	
	divider_1:divider
	
		port map (
					 xin, yin,
					 start, ack,
					 clk, resetb,
					 q, r,
					 done
					);
	------------        
	xin  <= (sw15, sw14, sw13, sw12, sw11, sw10, sw9, sw8);
	yin  <= (sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0);
	start <= BtnL; ack <= BtnR;
		LD15 <= q(7) ;
   LD14 <= q(6) ;
   LD13 <= q(5) ;
   LD12 <= q(4) ;
   LD11 <= q(3) ;
	LD10 <= q(2) ;
	LD9 <= q(1) ;
	LD8 <= q(0) ;
	LD7 <= r(7) ;
   LD6 <= r(6) ;
   LD5 <= r(5) ;
   LD4 <= r(4) ;
   LD3 <= r(3) ;
	LD2 <= r(2) ;
	LD1 <= r(1) ;
	LD0 <= r(0) ;
	------------

    -- disabling the seven segment display
    ca      <= '1' ;
    cb      <= '1' ;
    cc      <= '1' ;
    cd      <= '1' ;
    ce      <= '1' ;
    cf      <= '1' ;
    cg      <= '1' ;
    dp      <= '1' ;
    AN0     <= '1' ; 
    AN1     <= '1' ; 
    AN2     <= '1' ; 
    AN3     <= '1' ; 

end divider_top_arc ;
------------------------------------------------------------------------------
