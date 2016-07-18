----------------------------------------------------
-- File: ee560_2_reg_interface_r1.vhd 
--  1 register INTERFACE design
--
--	Designed by Gandhi Puvvada and Lung-Sheng Chen	
--	Date:12/1/99, 7/20/2006 (file name added), 7/21/2011 (a_write and a_read are made active-high)
----------------------------------------------------

----------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

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

	signal a_write, a_read, please_consume_i: std_logic;
	signal a_reg: std_logic_vector(3 downto 0);
	signal g_a_rclk, g_a_wclk, a_filled, a_filled_s, a_empty, a_empty_s: std_logic;
	signal w_syn_resetb, r_syn_resetb,wclk_resetb, rclk_resetb : std_logic;
	signal ae_presetb, ae_s_presetb, af_presetb: std_logic;
	
	signal b_write, b_read: std_logic;
	signal b_reg: std_logic_vector(3 downto 0);
	signal g_b_rclk, g_b_wclk, b_filled, b_filled_s, b_empty, b_empty_s: std_logic;
	signal be_presetb, be_s_presetb, bf_presetb: std_logic;
	
	signal ppp_r, ppp_w: std_logic;

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

	W_State_Ctrl: process(PRODUCED, wstate, a_filled_s, b_filled_s)
	begin
			n_wstate <= wstate;
			a_write <= '0'; -- high-active signal inactivated by default
			b_write <= '0';
			PLEASE_PRODUCE <= '0';

			case wstate is  
				when QW_produce =>
							PLEASE_PRODUCE <= '1';
							if( PRODUCED = '1' and (a_filled_s = '0' or b_filled_s = '0')) then 
								n_wstate <= QW_filled;
							elsif( PRODUCED ='1' and a_filled_s = '1' and b_filled_s = '1') then
								n_wstate <= QW_wait;
							end if;
				when QW_wait =>
							if( a_filled_s = '0' or b_filled_s = '0') then
								n_wstate <= QW_filled; 
							end if;
				when QW_filled =>
							if ppp_w = '0' then
								a_write <= '1';
							else
								b_write <= '1';
							end if;
							n_wstate <= QW_produce;
				when others => null;
			end case;
	end process;


	W_State_Reg:process(WCLK, w_syn_resetb)
	begin
			if( w_syn_resetb = '0') then
				wstate <= QW_produce;
				ppp_w <= '0';
			elsif( WCLK'event and WCLK = '1') then
				wstate <= n_wstate;
				if wstate = QW_filled then
					ppp_w <= not ppp_w;
				end if;
			end if;
	end process;


	R_State_Ctrl:process(CONSUMED, rstate, a_empty_s, b_empty_s)
	begin
			n_rstate <= rstate;
			a_read <= '0'; -- high-active signal inactivated by default
			b_read <= '0';
			please_consume_i <= '0';
			
			case rstate is 
				when QR_wait =>
							if( a_empty_s ='0' or b_empty_s = '0') then 
								n_rstate <= QR_consume;
							end if;
				when QR_consume=>
							please_consume_i <= '1';
							if( CONSUMED = '1') then
								n_rstate <= QR_read;
							end if;
				when QR_read =>
							if ppp_r = '0' then
								a_read <= '1';
							else
								b_read <= '1';
							end if;
							if a_empty_s = '1' and b_empty_s = '1' then
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
				ppp_r <= '0';
			elsif( RCLK'event and RCLK = '1') then
				rstate <= n_rstate;
				if rstate = QR_read then
					ppp_r <= not ppp_r;
				end if;
			end if;
	end process;
	

----  Gated Clock---------------------
	
	g_a_wclk <= not ( a_write and (not WCLK) );
	g_a_rclk <= not ( a_read  and (not RCLK) );
	
	g_b_wclk <= not ( b_write and (not WCLK) );
	g_b_rclk <= not ( b_read  and (not RCLK) );
	
----  Data registers---------------------

	Data_Reg_a:process(g_a_wclk)
	begin
		if( g_a_wclk'event and g_a_wclk= '1') then
			a_reg <= DATAIN;
		end if;
	end process;
	
	Data_Reg_b:process(g_b_wclk)
	begin
		if( g_b_wclk'event and g_b_wclk= '1') then
			b_reg <= DATAIN;
		end if;
	end process;

----EMPTY CONTROLS----

	-----EMPTY INDICATIONS A----
	-----INPUT TO THE A EMPTY SYNC-----
	ae_presetb <= g_a_rclk and w_syn_resetb;
	A_empty_reg:process(g_a_wclk, ae_presetb)
	begin
			if( ae_presetb = '0') then
				a_empty <= '1';
			elsif( g_a_wclk'event and g_a_wclk= '1') then
				a_empty <= '0';
			end if;
	end process;
	
	-----EMPTY INDICATIONS B----
	be_presetb <= g_b_rclk and w_syn_resetb;
	B_empty_reg:process(g_b_wclk, be_presetb)
	begin
			if( be_presetb = '0') then
				b_empty <= '1';
			elsif( g_b_wclk'event and g_b_wclk= '1') then
				b_empty <= '0';
			end if;
	end process;
	
	
	-----EMPTY SYNCHRONIZERS-----
	-----PRESET OF SYNC A-----
	ae_s_presetb <= g_a_rclk and r_syn_resetb;
	A_empty_s_reg:process(RCLK, ae_s_presetb)
	begin
			if( ae_s_presetb = '0') then
				 a_empty_s <= '1';
			elsif( RCLK'event and RCLK= '1') then
				 a_empty_s <= a_empty;
			end if;
	end process;
	
	-----PRESET OF SYNC B-----
	be_s_presetb <= g_b_rclk and r_syn_resetb;
	B_empty_s_reg:process(RCLK, be_s_presetb)
	begin
			if( be_s_presetb = '0') then
				 b_empty_s <= '1';
			elsif( RCLK'event and RCLK= '1') then
				 b_empty_s <= b_empty;
			end if;
	end process;

----FILLED CONTROLS----
	
	-----FILLED INDICATIONS A-----
	-----INPUT TO THE A FILLED SYNC-----
	af_presetb <= g_a_wclk;
	A_filled_reg:process(g_a_rclk, af_presetb, r_syn_resetb)
	begin
			if( r_syn_resetb = '0') then
				a_filled <= '0';	
			elsif( af_presetb = '0') then
				 a_filled <= '1';
			elsif( g_a_rclk'event and g_a_rclk= '1') then
				a_filled <= '0';
			end if;
	end process;
	
	
	-----FILLED INDICATIONS B-----
	-----INPUT TO THE B FILLED SYNC-----
	bf_presetb <= g_b_wclk;
	B_filled_reg:process(g_b_rclk, bf_presetb, r_syn_resetb)
	begin
			if( r_syn_resetb = '0') then
				b_filled <= '0';	
			elsif( bf_presetb = '0') then
				 b_filled <= '1';
			elsif( g_b_rclk'event and g_b_rclk= '1') then
				b_filled <= '0';
			end if;
	end process;
	
	
	-----FILLED SYNCHRONIZERS-----
	-----PRESET OF FILLED SYNC A-----
	A_filled_s_reg:process(WCLK, af_presetb, w_syn_resetb)
	begin
			if( w_syn_resetb = '0') then
				a_filled_s <= '0';	
			elsif( af_presetb = '0') then
				a_filled_s <= '1';
			elsif( WCLK'event and WCLK= '1') then
				 a_filled_s <= a_filled;
			end if;
	end process;
	
	-----PRESET OF FILLED SYNC B-----
	B_filled_s_reg:process(WCLK, bf_presetb, w_syn_resetb)
	begin
			if( w_syn_resetb = '0') then
				b_filled_s <= '0';	
			elsif( bf_presetb = '0') then
				b_filled_s <= '1';
			elsif( WCLK'event and WCLK= '1') then
				 b_filled_s <= b_filled;
			end if;
	end process;

----  output signals---------------------
	
	PLEASE_CONSUME <= please_consume_i;

	DATAOUT <=  a_reg when please_consume_i = '1' and ppp_r = '0' else
				b_reg when please_consume_i = '1' and ppp_r = '1' else
				(others => 'Z');

end arc;
