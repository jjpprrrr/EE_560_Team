----------------------------------------------------
-- ee560_8_loc_FIFO_with_prefetch_and_overlap.vhd
-- 7/23/2015

-- This includes improvement in activating PLEASE_PRODUCE in the last clock in the PREFETCHED state. 
-- This improvement is as per the solution for Q#2.2 of the Summer 2013 final exam.
-- Previously, even with overlap (P_OVERLAP <= '1';), we were not using this opportunity.
-- Previously we were doing the following:
-- PLEASE_PRODUCE <= '0' when ((PREFETCHED = '1') or ( (full = '1') and (PRODUCED = '1') ) ) else '1'; 
-- Now, we are doing the following:
-- PLEASE_PRODUCE <= '0' when (   ((full = '1') and (PREFETCHED = '1')) or ( (full = '1') and (PRODUCED = '1') ) ) else '1'; 
-- The above can be simplified as shown below but since state diagram wise the above easily maps to 
-- the actions coming from the two states separately, we will keep the above form.
-- PLEASE_PRODUCE <= '0' when ( (full = '1') and  ((PREFETCHED = '1') or (PRODUCED = '1') ) ) else '1'; 
----------------------------------------------------
-- With the improvement, the following results were achieved.
-- # ** Note: Last Data Dispatched !!
-- #    Time: 2100 ns  Iteration: 0  Instance: /tb_interface
-- # ** Note: Last Data Received !!
-- #    Time: 2398 ns  Iteration: 0  Instance: /tb_interface

-- Before this improvement, the same results were achieved. 
-- as there wasn't any prefetch opportunity in this limited data and not too shallow a FIFO.
-- # ** Note: Last Data Dispatched !!
-- #    Time: 2100 ns  Iteration: 0  Instance: /tb_interface
-- # ** Note: Last Data Received !!
-- #    Time: 2398 ns  Iteration: 0  Instance: /tb_interface 

-- This would make a difference in the 1-location and 2-location FIFOs.
----------------------------------------------------
--  8 register INTERFACE design, treating it as a 8-location FIFO
--
--	Designed by Gandhi Puvvada	
--	Date: 7/25/2011
----------------------------------------------------
-- Previous design did not take advantage of "OVERLAP" in the producer or the consumer.
-- Now we take that advantage.
-- Notice 
--		how we derived and used "almost_empty", 
--		why the fifo needed two read ports,
-- 		how the PLEASE_PRODUCE and PLEASE_CONSUME were generated here.
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
	signal wp, wp_gray, wp_gray_s, wp_gray_ss, wp_binary_ss: std_logic_vector (1 downto 0);
	signal rp, rp_gray, rp_gray_s, rp_gray_ss, rp_binary_ss: std_logic_vector (1 downto 0);
	signal depth_w, depth_r: std_logic_vector (1 downto 0); -- for debugging purpose
	signal PREFETCHED: std_logic; -- new FF added to support prefetching 
	signal please_consume_i, C_OVERLAP_int : std_logic;
	type my_reg_array_type is array (1 downto 0) of std_logic_vector(3 downto 0);
	signal FIFO_reg_array : my_reg_array_type;
	signal w_syn_resetb, r_syn_resetb,wclk_resetb, rclk_resetb : std_logic;
	
	signal wclk_count, rclk_count: std_logic_vector(7 downto 0); -- These are for debugging purpose only

begin

	P_OVERLAP <= '1'; C_OVERLAP <= '1'; C_OVERLAP_int <= '1'; -- It is not correct to make these simply '1'
    -- to take advantage of the pipelined nature of the producer and the consumer.
	-- You need to take care to see that the PLEASE_PRODUCE and the PLEASE_CONSUME 
	-- are generated thoughtfully. 

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

----  Begin Control Signal generation ---------------------

	-- PLEASE_PRODUCE <= '1' when ( full = '0' ) else '0'; -- before prefetch operation inclusion
	-- PLEASE_PRODUCE <= '1' when (PREFETCHED = '0') else '0'; -- after prefetch operation inclusion
		-- The following includes prefetch and overlapped production operations.
	-- Before improvement	
	-- PLEASE_PRODUCE <= '0' when ((PREFETCHED = '1') or ( (full = '1') and (PRODUCED = '1') ) ) else '1'; 
	-- After improvement
	PLEASE_PRODUCE <= '0' when (   ((full = '1') and (PREFETCHED = '1')) or ( (full = '1') and (PRODUCED = '1') ) ) else '1';
	
	-- wenq <= '1' when ( ( full = '0' ) and (PRODUCED = '1') )else '0'; -- before prefetch operation inclusion
	wenq <= '1' when ( ( full = '0' ) and ((PRODUCED = '1') OR (PREFETCHED = '1') ) )  else '0'; -- after prefetch operation inclusion

	
	-- please_consume_i <= '1' when ( empty = '0' ) else '0';
	-- The following includes overlapped consumption operations.
	please_consume_i <= '0' when ( (empty = '1') or ( (almost_empty = '1') and (CONSUMED = '1') ) ) else '1';

	renq <= '1' when ( ( empty = '0' ) and (CONSUMED = '1') )else '0';

	PLEASE_CONSUME <= please_consume_i;
	
	-- Gray to Binary conversion
	
	wp_binary_ss(1)  <=                     wp_gray_ss(1); -- B3 <=        G3;
	wp_binary_ss(0)  <= wp_binary_ss(1) XOR wp_gray_ss(0); -- B2 <= B3 XOR G2;
	--wp_binary_ss(1)  <= wp_binary_ss(2) XOR wp_gray_ss(1); -- B1 <= B2 XOR G1;
	--wp_binary_ss(0)  <= wp_binary_ss(1) XOR wp_gray_ss(0); -- B0 <= B1 XOR G0;
	
	rp_binary_ss(1)  <=                     rp_gray_ss(1); -- B3 <=        G3;
	rp_binary_ss(0)  <= rp_binary_ss(1) XOR rp_gray_ss(0); -- B2 <= B3 XOR G2;
	--rp_binary_ss(1)  <= rp_binary_ss(2) XOR rp_gray_ss(1); -- B1 <= B2 XOR G1;
	--rp_binary_ss(0)  <= rp_binary_ss(1) XOR rp_gray_ss(0); -- B0 <= B1 XOR G0; 

	
	----  full, empty, almost_empty, and depth signals---------------------
	full <= '1' when ( ((wp(1) XOR rp_binary_ss(1)) = '1') and ((wp(0) XOR rp_binary_ss(0)) = '0') ) else '0';
	empty <= '1' when  ( (wp_binary_ss XOR rp) = "00") else '0';

	almost_empty <=  '1' when  ( (wp_binary_ss - rp) = "01") else '0'; -- when the depth = 1 (=> one more item is left for consumption)
	depth_w <= wp - rp_binary_ss;
	depth_r <= wp_binary_ss - rp;	
----  End Control Signal generation ---------------------
	
----  output the data ---------------------

	-- DATAOUT <= FIFO_reg_array (CONV_INTEGER(rp(2 downto 0))) when please_consume_i = '1' else (others => 'Z');
	DATAOUT <=  FIFO_reg_array (CONV_INTEGER(not rp(0))) when ((CONSUMED = '1') and (C_OVERLAP_int = '1') and (please_consume_i = '1')) else 
				-- note the FIFO here is considered to have two read ports to read the next location pointed to by 
				-- rp+1 besides the current location pointed to by rp. 
	           FIFO_reg_array (CONV_INTEGER(rp(0))) when (please_consume_i = '1') else 
			   (others => 'Z');	


	WP_and_synchronization_of_RP:process(WCLK, w_syn_resetb)
	variable wp_next_var: std_logic_vector (1 downto 0);
	begin
			if( w_syn_resetb = '0') then
				wp <= "00";
				wp_gray <= "00";
				rp_gray_s <= "00"; 
				rp_gray_ss <= "00";
				wclk_count <= "00000000";
				PREFETCHED <= '0';
			elsif( WCLK'event and WCLK = '1') then
				wclk_count <= wclk_count + 1;
				if (wenq = '1') then 
					wp_next_var := wp + 1; 
					wp <= wp_next_var;
					--wp_gray(0)  <= wp_next_var(1) XOR wp_next_var(0); -- G0 <= B1 ^ B0;
					--wp_gray(1)  <= wp_next_var(2) XOR wp_next_var(1); -- G1 <= B2 ^ B1;
					wp_gray(0)  <= wp_next_var(1) XOR wp_next_var(0); -- G2 <= B3 ^ B2;
					wp_gray(1)  <=                    wp_next_var(1); -- G3 <=      B3;
				end if;
				if ( (PREFETCHED = '0') and(PRODUCED = '1') and (full = '1')) then
					PREFETCHED <= '1';
				end if;
				if ( (PREFETCHED = '1') and (full = '0')) then
					PREFETCHED <= '0';
				end if;
				rp_gray_s <= rp_gray; 
				rp_gray_ss <= rp_gray_s;
			end if;
	end process;


	RP_and_synchronization_of_WP:process(RCLK, r_syn_resetb)
	variable rp_next_var: std_logic_vector (1 downto 0);
	begin
			if( r_syn_resetb = '0') then
				rp <= "00";
				rp_gray <= "00";
				wp_gray_s <= "00"; 
				wp_gray_ss <= "00";
				rclk_count <= "00000000";
			elsif( RCLK'event and RCLK = '1') then
				rclk_count <= rclk_count + 1;
				if (renq = '1') then 
					rp_next_var := rp + 1; 
					rp <= rp_next_var;
					--rp_gray(0)  <= rp_next_var(1) XOR rp_next_var(0); -- G0 <= B1 ^ B0;
					--rp_gray(1)  <= rp_next_var(2) XOR rp_next_var(1); -- G1 <= B2 ^ B1;
					rp_gray(0)  <= rp_next_var(1) XOR rp_next_var(0); -- G2 <= B3 ^ B2;
					rp_gray(1)  <=                    rp_next_var(1); -- G3 <=      B3;
				end if;
				wp_gray_s <= wp_gray; 
				wp_gray_ss <= wp_gray_s;
			end if;
	end process;
	

----  Data register ---------------------

	FIFO_array:process(wclk)
	begin
		if( wclk'event and wclk= '1') then
			if (wenq = '1') then
				FIFO_reg_array (CONV_INTEGER(wp(0))) <= DATAIN;
			end if;
		end if;
	end process;
	


end arc;
