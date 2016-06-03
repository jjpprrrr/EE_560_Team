------------------------------------------------------------------------------
--	File name: divider_with_cache_top.vhd (based on my earlier divider_virtual_io_top.vhd)
--  Gandhi Puvvada, Da Cheng, Fangzhou Wang
--  Date:  6/11/2010, 5/27/2012, 5/30/2014
------------------------------------------------------------------------------
-- This file is basically a copy of the earlier divider_virtual_io_top.vhd
-- However, to allow multi-stepping, we used part of the divider_virtual_io_multi_step_top_r1.vhd
-- Like in divider_virtual_io_multi_step_top_r1.vhd, we combined START and ACK under BtnL
-- so that BtnU can be used for multi-stepping.
-- Nothing special needs to be done in this top design because of cache, as cache is hidden inside the divider.
------------------------------------------------------------------------------
--  Here, the Dividend and the Divisor are conveyed through the Virtual I/O 
--  (I/O Ex tab) in the Adept 2.x GUI.
-- 16-bit output is sent from the dwOut(15 downto 0) from the Virtual I/O to form 8-bit Xin and 8-bit Yin
-- dwOut(7 downto 0)   0x09    Out 8 Bits in an output double word
-- dwOut(15 downto 8)  0x0a    Out 8 Bits in an output double word

-- 32-bit input to the the Virtual I/O  from the Nexys-3 board into dwIn is treated as four 8-bit items (xin, yin, q, r):
-- dwIn(7 downto 0)    0x0d    In  8 Bits in an input double word -- r
-- dwIn(15 downto 8)   0x0e    In  8 Bits in an input double word -- q
-- dwIn(23 downto 16)  0x0f    In  8 Bits in an input double word --  yin
-- dwIn(31 downto 24)  0x10    In  8 Bits in an input double word  -- xin

-- The lower right five buttons (in the lower row of the two rows of buttons) on the Virtual I/O  
--  replicate the operation of the five buttons on the Nexys-3 board.
-- Btn(7 downto 0)     0x07    In  8 Buttons, bottom row on the PC I/O Ex GUI
-- The  8 LEDs  on the Virtual I/O  display same as the 8 LEDs on the Nexys-3 board
-- Led(7 downto 0)     0x01    In  8 virtual LEDs on the PC I/O Ex GUI
------------------------------------------------------------------------------
--  Here the switches on the Nexys-3 board are  not used.

-- Press "BtnU" for multi-stepping in compute state.
-- Press "BtnL" for both "start" and "ack". 
-- "BtnR"is used to select the display on SSDs (either X and Y or Q and R).
-- "BtnC" is  used for reset.

-- Multi-stepping using BtnU 
--  	We will use (BtnU or Btn(1)) to produce MCEN and use it for multi-stepping the compute state.
--	This MCEN is the new MCEN, which is contnuoulsy active (like CCEN) after 8 discrete MCEN pulses.

-- Start and Ack
-- 	Earlier (in divider_virtual_io_top.vhd) we were using explicit buttons  (BtnU and BtnL) to produce Start and 
--	Ack signals. In divider_top_with_debounce.vhd, we used only one button (BtnL) to produce both Start and Ack.
--	In divider_top_with_debounce.vhd, we had to use the ee560_debounce_DPB_SCEN_CCEN_MCEN module and produce a single-clock-wide 
--	pulse (SCEN), one per depresion. If we did not do so, the first depression of BtnL will be viewed as both Start 
--	and Ack by the hardware. Here, since we multi-step the compute state, this will not happen. However, for the 
-- 	sake of exercise, we want to use the ee560_debounce_DPB_SCEN_CCEN_MCEN module and produce single-clock-wide pulses 
-- 	(one pulse per depression)  and provide them as Start and Ack.

--  The 8-bit dividend and the 8-bit divisor is displayed on the 4 SSDs by default.
-- When BtnR is pressed, the 8-bit quotient and the 8-bit remainder are displayed instead.

-- LD0 are lit when DONE is true.
-- LD2, LD1, are operated by the BtnU and BtnL
--  LD3 is lit by BtnR.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.VComponents.all; -- Xilinx primitive BUFGP

entity divider_with_cache_top is

port	(ClkPort:  in std_logic;
	    sw0, sw1, sw2, sw3, sw4, sw5, sw6, sw7: in std_logic;
	    BtnC: in std_logic; -- RESET button
	    BtnR: in std_logic; -- used to step through the display on SSDs
	    BtnU, BtnL  : in std_logic; -- BtnU = multi-step, BtnL = start as well as ack 
		BtnD : in std_logic; -- BtnD not used but is listed here for uniformity in our top entities
	    LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0: out std_logic;
	    ca, cb, cc, cd, ce, cf, cg, dp: out std_logic;
	    AN0, AN1, AN2, AN3, AN4, AN5, AN6, AN7: out std_logic;
		rxd_pin:  in std_logic;
		txd_pin:  out std_logic
		);
end  divider_with_cache_top ;
------------------------------------------------------------------------------
architecture divider_with_cache_top_arc of divider_with_cache_top   is
	------------
	signal display_digit, display_digit_xy, display_digit_qr:   std_logic_vector (3 downto 0); -- hex digit to be sent to 7-seg
	signal SSD: std_logic_vector (6 downto 0); -- Seven Segment Display Digit
	
	signal RESET: std_logic; 
	signal BCLK: std_logic; -- buffered clock
	signal divclk: std_logic_vector(24 downto 0); -- divided clocks used internally
	signal clk : std_logic; -- same as BCLK
	signal MCEN : std_logic; -- clock enable pulse sequence
	
	signal sev_seg_clk: std_logic_vector (2 downto 0); -- for scan control of the 7-seg. displays
	
	signal xin, yin, q, r, clocks_taken:    std_logic_vector(7 downto 0);
	signal start, ack, done, resetb :        std_logic;
	signal start_ack_SCEN:        std_logic; -- produced by the debouncer  
	signal LD_int:    std_logic_vector(7 downto 0);
	signal BtnL_combined, BtnU_combined, BtnR_combined: std_logic;
	signal INITIAL_ST, CACHE_CHECK_ST, COMPUTE_ST, DONE_CALC_ST, DONE_CACHE_HIT_ST: std_logic;
	------------	
	--component declarations done here
	------------	
	--bufgp for clock

   component BUFGP

         port (I: in std_logic; O: out std_logic);

   end component;
   ------------
	component divider_with_cache 
	  port (
		xin, yin: IN std_logic_vector(7 downto 0); -- dividend, divisor
		start, ack: IN  std_logic;
		clk, resetb, MCEN: IN  std_logic;   -- <== MCEN added
		q, r, clocks_taken: OUT std_logic_vector(7 downto 0);
		INITIAL_ST, CACHE_CHECK_ST, COMPUTE_ST, DONE_CALC_ST, DONE_CACHE_HIT_ST : OUT std_logic;
		done: OUT std_logic
		);
	
	end component;
	------------	
component IOExpansion is

    Port (
-- uart-like bus signals
		clk_pin	: in  std_logic;
		rst_pin	: in  std_logic;
		rxd_pin	: in  std_logic;
		txd_pin	: out  std_logic;
-- user extended signals 
		Led  : in std_logic_vector(7 downto 0);   -- 0x01     8 virtual LEDs on the PC I/O Ex GUI
		LBar : in std_logic_vector(23 downto 0);  -- 0x02..4  24 lights on the PC I/O Ex GUI light bar
		Sw   : out std_logic_vector(15 downto 0);  -- 0x05..6  16 switches, bottom row on the PC I/O Ex GUI
		Btn  : out std_logic_vector(15 downto 0);  -- 0x07..8  16 Buttons, bottom row on the PC I/O Ex GUI
		dwOut: out std_logic_vector(31 downto 0); -- 0x09..b  32 Bits user output
		dwIn : in std_logic_vector(31 downto 0)   -- 0x0d..10 32 Bits user input
         );

end component IOExpansion;
	------------	
component ee560_debounce_DPB_SCEN_CCEN_MCEN is	       
generic  (N_dc: 		positive := 25);
port     (CLK, RESETB	:in  std_logic; -- CLK = 100 MHz
		  PB		:in  std_logic; -- push button
	 	  DPB, SCEN, MCEN, CCEN	:out std_logic -- debounced PB, single_CEN, multi_CEN, continuous CEN 
		 );
end  component ee560_debounce_DPB_SCEN_CCEN_MCEN ;
	------------	
-- additional signal to tie-up the virtual I/O interface

-- uart-like bus signals <= these are port pins tied to the USB controller

-- user extended signals 
    signal   Led  :  std_logic_vector(7 downto 0);   -- 0x01     8 virtual LEDs on the PC I/O Ex GUI
    signal   LBar :  std_logic_vector(23 downto 0);  -- 0x02..4  24 lights on the PC I/O Ex GUI light bar
    signal   Sw   : std_logic_vector(15 downto 0);  -- 0x05..6  16 switches, bottom row on the PC I/O Ex GUI
    signal   Btn  : std_logic_vector(15 downto 0);  -- 0x07..8  16 Buttons, bottom row on the PC I/O Ex GUI
    signal   dwOut: std_logic_vector(31 downto 0); -- 0x09..b  32 Bits user output
    signal   dwIn :  std_logic_vector(31 downto 0);   -- 0x0d..10 32 Bits user input
	  
begin
	------------
	------------
	--concurrent assignments
	
	-- Disable the memories so that they do not interfere with the rest of the design.
--	MemOE <= '1';  RamCS <= '1';  
--	MemWR <= '1';  FlashCS <= '1';  QuadSpiFlashCS <= '1'; 
	------------


	BUF_GP_1:   BUFGP   port map (I => ClkPort, O => BCLK); 
	
	RESET <= BtnC;		 -- You reset by pushing BtnC or Btn(0) on the VIO
	
	resetb <= not (RESET); -- low active reset for the core design
	
	------------
	-- The BtnL is debounced here and whenever it is depressed, a single-clock-wide SCEN pulse is produced to enable the clock.
	BtnL_combined <= BtnL or btn(2);
	
	BtnL_debouncer: ee560_debounce_DPB_SCEN_CCEN_MCEN  
		generic map (N_dc => 23)
		port  map   (clk => clk, resetb => resetb,  -- CLK = 100 MHz
		  PB => BtnL_combined, -- push button
	 	  DPB => open, SCEN => start_ack_SCEN, MCEN => open, CCEN => open -- debounced PB, single_CEN, multi_CEN, continuous CEN 
		 );
	------------
	start <= start_ack_SCEN; ack <= start_ack_SCEN;
	------------
	-- The BtnR is debounced here and whenever it is depressed, a single-clock-wide SCEN pulse is produced to step the display pointer.
	BtnR_combined <= BtnR or btn(0);
	------------
	xin <= dwOut (15 downto 8);
	yin <= dwOut (7 downto 0);
	dwIn (31 downto 24) <= xin;
	dwIn (23 downto 16) <= yin;
	dwIn (15 downto 8) <= q;
	dwIn (7 downto 0) <= r;
	
	------------
		-- The BtnU is debounced here and whenever it is depressed, a multi-cycle pulse sequence MCEN is produced to enable the clock.
	BtnU_combined <= BtnU or btn(1);
	
	BtnU_debouncer: ee560_debounce_DPB_SCEN_CCEN_MCEN  
		generic map (N_dc => 28) -- Note: we used N_dc of 28 for multi-stepping so that it is slow enough for us to read the numbers as they change
		port  map   (clk => clk, resetb => resetb,  -- CLK = 100 MHz
		  PB => BtnU_combined, -- push button
	 	  DPB => open, SCEN => open, MCEN => MCEN, CCEN => open -- debounced PB, single_CEN, multi_CEN, continuous CEN 
		 );
	------------
	
	divider_with_cache_1:divider_with_cache
		port map (
					 xin, yin,
					 start, ack,
					 clk, resetb, MCEN,
					 q, r, clocks_taken,
					 INITIAL_ST, CACHE_CHECK_ST, COMPUTE_ST, DONE_CALC_ST, DONE_CACHE_HIT_ST,
					 done
					);
	
	------------        
	
	IOExpansion_1: IOExpansion

		port map (
			-- uart-like bus signals
			clk,
			resetb,
			rxd_pin,
			txd_pin,
			-- user extended signals
			Led (7 downto 0),
			LBar (23 downto 0),
			Sw (15 downto 0),
			Btn (15 downto 0),
			dwOut (31 downto 0),
			dwIn (31 downto 0)
			);
	------------ 
	LD_int (7) <= INITIAL_ST;  
	LD_int (6) <= CACHE_CHECK_ST; 
	LD_int (5) <= COMPUTE_ST;   
	LD_int (4) <= DONE_CALC_ST; 	
	LD_int (3) <= DONE_CACHE_HIT_ST;
	LD_int (2) <= BtnL_combined;
	LD_int (1) <= BtnU_combined; 
	LD_int (0) <= BtnR_combined;

	Led <= LD_int ; -- make LEDs on the virtual I/O display the same as board LEDs
	(LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0)  <= LD_int; 
	------------	
	dp <= '0'; -- for instructor's design, the dot point glows steadily and does not flash
	-- dp <= divclk(24);
	-- dot points flash when downloading is successful for students' design
	------------	
	------------	
	-- we left the info provided by the lower row of switches { sw(7 downto 0) } unused.
	LBar(7 downto 0) <= clocks_taken; -- Sw(15 downto 8);  -- looping back
	LBar(23 downto 8) <= btn(15 downto 0); -- looping back

	------------
	--Clock Divider derives slower clocks from the 100 MHz clock on s2 board
	CLOCK_DIVIDER1: process (BCLK, RESET)
						 begin
							 if (RESET = '1') then
								 divclk <= (others => '0');
							 elsif (BCLK'event and BCLK = '1') then
								 divclk <= divclk + '1';
							 end if;
						 end process CLOCK_DIVIDER1;
	------------
	clk <= BCLK; -- Usually we let students work at a low frequency
	             -- But here we are giving the high-speed 100 MHz clock to user design 
	
	-- need a scan clk for the seven segment display 
	-- 191Hz (100 MHz / 2^19) works well	
	sev_seg_clk  <= divclk(19 downto 17); -- 7 segment display scanning 	
	------------
		process (sev_seg_clk)
		 begin
			AN0 <= '1'; AN1 <= '1'; AN2 <= '1'; AN3 <= '1'; AN4 <= '1'; AN5 <= '1'; AN6 <= '1'; AN7 <= '1'; 
			-- Note: This is different from other S2 boards
			case sev_seg_clk  is
					 when "000" => AN0 <= '0'; -- SSD0 right-most
					 when "001" => AN1 <= '0'; -- SSD1
					 when "010" => AN2 <= '0'; -- SSD2
					 when "011" => AN3 <= '0'; -- SSD3 left-most
					 
					 when "100" => AN4 <= '0'; -- SSD0 right-most
					 when "101" => AN5 <= '0'; -- SSD1
					 when "110" => AN6 <= '0'; -- SSD2
					 when "111" => AN7 <= '0'; -- SSD3 left-most
					 when others => null;
			 end case;
		 end process;
	------------
	with sev_seg_clk  select
			display_digit_xy <=   q (7 downto 4)      when "111",    -- SSD3  left-most
								  q (3 downto 0)      when "110",    -- SSD2
								  r (7 downto 4)      when "101",    -- SSD1
								  r (3 downto 0)      when "100",  -- SSD0 right-most
								  xin (7 downto 4)    when "011",    -- SSD3  left-most
								  xin (3 downto 0)    when "010",    -- SSD2
								  yin (7 downto 4)    when "001",    -- SSD1
								  yin (3 downto 0)    when others;  -- SSD0 right-most
	with sev_seg_clk  select
			display_digit_qr <=   
								  xin (7 downto 4)    when "111",    -- SSD3  left-most
								  xin (3 downto 0)    when "110",    -- SSD2
								  yin (7 downto 4)    when "101",    -- SSD1
								  yin (3 downto 0)    when "100",  -- SSD0 right-most
								  q (7 downto 4)      when "011",    -- SSD3  left-most
								  q (3 downto 0)      when "010",    -- SSD2
								  r (7 downto 4)      when "001",    -- SSD1
								  r (3 downto 0)      when others;  -- SSD0 right-most
	display_digit <=  	display_digit_qr;
	-- when ( 
												-- ((BtnR_combined = '1') and ((INITIAL_ST = '1') or (CACHE_CHECK_ST = '1'))) 
												-- or 
												-- ((BtnR_combined = '0') and ((INITIAL_ST = '0') and (CACHE_CHECK_ST = '0')))
											  -- ) else 
						-- display_digit_xy;  
						-- By default display X and Y in INITIAL_STATE or CACHE_CHECK_STATE,  and  Q and R in other states. But if BtnR_combined is pressed display the other.
	------------
	with display_digit select
	  SSD <= 	 "1001111" when "0001",  --1
					 "0010010" when "0010",  --2
					 "0000110" when "0011",  --3
					 "1001100" when "0100",  --4
					 "0100100" when "0101",  --5
					 "0100000" when "0110",  --6
					 "0001111" when "0111",  --7
					 "0000000" when "1000",  --8
					 "0000100" when "1001",  --9
					 "0001000" when "1010",  --A
					 "1100000" when "1011",  --b
					 "0110001" when "1100",  --C
					 "1000010" when "1101",  --d
					 "0110000" when "1110",  --E
					 "0111000" when "1111",  --F
					 "0000001" when others;  --0
	
	(ca,cb,cc,cd,ce,cf,cg) <= SSD;
    --ca<= '1';
	 -- cb<= '1';
	 -- cc<= '1';
	 -- cd<= '1';
	 -- ce<= '1';
	 -- cf <= '1';
	 -- cg <= '1';
	------------

	------------
end divider_with_cache_top_arc ;
------------------------------------------------------------------------------
