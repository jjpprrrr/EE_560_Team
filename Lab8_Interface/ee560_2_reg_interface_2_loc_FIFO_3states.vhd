----------------------------------------------------
-- File: ee560_1_reg_interface_1_loc_FIFO_3states.vhd (based on the earlier ee560_1_reg_interface_r1.vhd) 
--  1 register INTERFACE design, treating the single register as a single location FIFO
--
--	Designed by Gandhi Puvvada, ------	
--	Date: 7/29/2010, 7/23/2011, 7/22/2013
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity interface is 
	port( 
		RESETB, WCLK, RCLK: in std_logic;
		PRODUCED, CONSUMED: in std_logic;
		DATAIN: in std_logic_vector(3 downto 0);
		DATAOUT: out std_logic_vector( 3 downto 0);
		PLEASE_PRODUCE, PLEASE_CONSUME: out std_logic;
		P_OVERLAP, C_OVERLAP: out std_logic
	);
end interface;


architecture arc of interface is

	signal wenq, renq : std_logic;
	signal full, empty, almost_empty: std_logic;
	signal wp, wp_s, rp, rp_s, wp_gray, rp_gray, wp_gray_int, rp_gray_int, wp_gray_s, rp_gray_s: std_logic_vector(1 downto 0);
	signal please_consume_i: std_logic;
	signal a_reg, b_reg: std_logic_vector(3 downto 0);
	signal w_syn_resetb, r_syn_resetb,wclk_resetb, rclk_resetb : std_logic;

	type W_state_enum is ( QW_produce, QW_filled, QW_wait);
	type R_state_enum is ( QR_consume, QR_read, QR_wait);
	signal wstate, n_wstate : W_state_enum;
	signal rstate, n_rstate: R_state_enum;

begin

	P_OVERLAP <= '0'; C_OVERLAP <= '0'; -- simple-minded inerface design

----  Synchronous reset signal generation

	Wclk_syn_resetb:process(WCLK)
	begin
		if( WCLK'event and WCLK ='1') then
			wclk_resetb <= RESETB;
		end if;
	end process;

	w_syn_resetb <= wclk_resetb and RESETB;
	
	
	Rclk_syn_resetb:process(RCLK)
	begin
		if( RCLK'event and RCLK ='1') then
			rclk_resetb <= RESETB;
		end if;
	end process;

	r_syn_resetb <= rclk_resetb and RESETB;


----  State Control---------------------

	W_State_Ctrl: process(PRODUCED, wstate, full)
	begin
			n_wstate <= wstate;
			wenq <= '0'; -- high active
			PLEASE_PRODUCE <= '0';

			case wstate is  
				when QW_produce =>
							PLEASE_PRODUCE <= '1';
							if( PRODUCED = '1' and full = '0') then 
								n_wstate <= QW_filled;
							elsif( PRODUCED ='1' and full = '1') then
								n_wstate <= QW_wait;
							end if;
				when QW_wait =>
							if( full = '0' ) then
								n_wstate <= QW_filled; 
							end if;
				when QW_filled =>
							wenq <= '1';
							n_wstate <= QW_produce;
				when others => null;
			end case;
	end process;


	W_State_Reg:process(WCLK, w_syn_resetb)
	begin
			if( w_syn_resetb = '0') then
				wstate <= QW_produce;
				wp <= "00";
				wp_gray <= "00";
				rp_gray_s <= "00";
			elsif( WCLK'event and WCLK = '1') then
				wstate <= n_wstate;
				if (wenq = '1') then 
					wp <= wp + 1; 
					wp_gray <= wp_gray_int;
				end if;
				rp_gray_s <= rp_gray;
			end if;
	end process;


	R_State_Ctrl:process(CONSUMED, rstate, empty)
	begin
			n_rstate <= rstate;
			renq <= '0'; -- high active
			please_consume_i <= '0';
			
			case rstate is 
				when QR_wait =>
							if( empty ='0') then 
								n_rstate <= QR_consume;
							end if;
				when QR_consume=>
							please_consume_i <= '1';
							if( CONSUMED = '1') then
								n_rstate <= QR_read;
							end if;
				when QR_read =>
							renq <= '1';
							if almost_empty = '1' then
								n_rstate <= QR_wait;
							else
								n_rstate <= QR_consume;
							end if;
				when others => null;
			end case;
	end process;
	

	R_State_Reg:process(RCLK, r_syn_resetb)
	begin
			if( r_syn_resetb = '0') then
				rstate <= QR_wait;
				rp <= "00";
				rp_gray <= "00";
				wp_gray_s <= "00";
			elsif( RCLK'event and RCLK = '1') then
				rstate <= n_rstate;
				if (renq = '1') then 
					rp <= rp + 1; 
					rp_gray <= rp_gray_int;
				end if;
				wp_gray_s <= wp_gray;
			end if;
	end process;
	

----  Data register ---------------------

	Data_Reg_a:process(wclk)
	begin
		if( wclk'event and wclk= '1') then
			if (wenq = '1') then
				if wp(0) = '0' then
					a_reg <= DATAIN;
				elsif wp(0) = '1' then
					b_reg <= DATAIN;
				end if;
			end if;
		end if;
	end process;
	
----  full and empty signals---------------------
	full  <= '1' when wp - rp_s = "10" else '0';
	empty <= '1' when wp_s - rp = "00" else '0';
	almost_empty <= '1' when wp_s - rp = "01" else '0';
	
----  B TO G conversion ----
	wp_gray_int <=  "11" when wp + 1 = "10" else
					"10" when wp + 1 = "11" else
					wp + 1;
	rp_gray_int <=  "11" when rp + 1 = "10" else
					"10" when rp + 1 = "11" else
					rp + 1;

---- G TO B conversion ----
	wp_s <= "10" when wp_gray_s = "11" else
			"11" when wp_gray_s = "10" else
			wp_gray_s;
			
	rp_s <= "10" when rp_gray_s = "11" else
			"11" when rp_gray_s = "10" else
			rp_gray_s;
	
----  output signals---------------------
	
	PLEASE_CONSUME <= please_consume_i;

	DATAOUT <=  a_reg when please_consume_i = '1' and rp(0) = '0' else
				b_reg when please_consume_i = '1' and rp(0) = '1' else
				(others => 'Z');

end arc;
