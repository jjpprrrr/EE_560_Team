-------------------------------------------------------------------------------
--
-- Design   : DIVIDE WITH CACHE
-- Project  : DIVIDE WITH CACHE
-- Author: Srinivas, Phil, Gandhi Puvvada
-- Company  : University of Southern California 
--
-------------------------------------------------------------------------------
-- File         : divider_with_cache.vhd
-- Author: Srinivas, Phil, Gandhi Puvvada
-- Date: June 2008, 6/29/2009, 6/13/2010

-- Details of the revision in Summer 2010:
-- Like in the divider_virtual_io design with multi-stepping, we wish to have
-- multi-stepping. In Summer 2008 and Summer 2009, we did not have multi-stepping
-- in this design. We had four states at that time: 
-- type state_type is (INITIAL_STATE, COMPUTE_STATE, DONE_CALC_STATE, DONE_CACHE_HIT_STATE);
-- Now (in Summer 2010) we added a state, CACHE_CHECK_STATE, in which we check cache for HIT.
-- type state_type is (INITIAL_STATE, CACHE_CHECK_STATE, COMPUTE_STATE, DONE_CALC_STATE, DONE_CACHE_HIT_STATE);
-- It is important to note that we should not be spuriously updating LRU stack. 
-- You notice the following lines in sub modules:
-- update_lru_stack_sig <= we or hit_true_sig; -- in cache design
-- This design produces  "rd" and "we" as single-clock wide pulses. 
--  "rd" means read enable which means check cache to see if it is a hit.
--  "we" means write enable which means write the tag and data in the cache and update lru stack.
-- If we produce "rd" and "we" in such a way that they are active for more than 1 clock, will it hurt?
-- Consider other approximate algorithms besides our perfect LRU algorithm, when you think about "rd".
-- To continue to produce "rd" and "we" as single-clock wide pulses while using multi-stepping using MCEN,
-- we have split the earlier COMPUTE_STATE into two states CACHE_CHECK_STATE and COMPUTE_STATE.
-- However, we made sure that we did not waste any clocks. We started computation 
-- even while checking for hit in the CACHE_CHECK_STATE.
-- We also added a port signal, called clocks_taken, which will be 1 if we get a cache hit or
-- may be 1 or more (note: it is "1 or more", not "2 or more") if we have to calculate.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries and use clauses

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-----------------------------------
entity divider_with_cache is

port	(
	xin, yin: IN std_logic_vector(7 downto 0); 
	start, ack: IN  std_logic;
	clk, resetb, MCEN: IN  std_logic;  -- <== MCEN added
	q, r, clocks_taken: OUT std_logic_vector(7 downto 0); 
	INITIAL_ST, CACHE_CHECK_ST, COMPUTE_ST, DONE_CALC_ST, DONE_CACHE_HIT_ST : OUT std_logic; -- State outputs
	done: OUT std_logic
	);
end divider_with_cache ;

------------------------------------------------------------------------------

architecture divider_with_cache_RTL of divider_with_cache   is

-- Type declarations

  type state_type is (INITIAL_STATE, CACHE_CHECK_STATE, COMPUTE_STATE, DONE_CALC_STATE, DONE_CACHE_HIT_STATE);

  signal state          : state_type;
  signal x, y           : std_logic_vector(7 downto 0);
  -- internal signal for the output ports
  signal q_int, rem_int, clocks_taken_int : std_logic_vector(7 downto 0); 

  signal rd       : std_logic; -- read
  signal we       : std_logic; -- write (write enable)
  signal hit_true : std_logic;
  signal tag_in   : std_logic_vector(15 downto 0);
  signal data_in  : std_logic_vector(15 downto 0);
  signal data_out : std_logic_vector(15 downto 0);

-- Component declarations
  component cache
    generic (
      WIDTH     : integer := 8;
      DEPTH     : integer := 8;
      LOG_DEPTH : integer := 3
      );
    port (
      -- global signals
      clk   : in std_logic;
      resetb : in std_logic;
	  
      rd       : in  std_logic;  -- read
      tag_in   : in  std_logic_vector(WIDTH-1 downto 0);
      we       : in  std_logic;  -- write enable
      data_in  : in  std_logic_vector(WIDTH-1 downto 0);
      data_out : out std_logic_vector(WIDTH-1 downto 0);
      hit_true : out std_logic
      ) ;
  end component;

begin

  cache_inst : cache
    generic map (
      WIDTH     => 16,
      DEPTH     => 8,
      LOG_DEPTH => 3
      )
    port map (
      clk   => clk,
      resetb => resetb,
	  
      rd       => rd,
      tag_in   => tag_in,
      we       => we,
      data_in  => data_in,
      data_out => data_out,
      hit_true => hit_true
      ) ;

  q       <= q_int;
  r       <= rem_int;
  tag_in  <= x & y;
  data_in <= q_int & rem_int;
  clocks_taken <= clocks_taken_int;
   
  INITIAL_ST <= '1' when (state = INITIAL_STATE) else '0'; 
  CACHE_CHECK_ST <= '1' when (state = CACHE_CHECK_STATE) else '0'; 
  COMPUTE_ST <= '1' when (state = COMPUTE_STATE) else '0'; 
  DONE_CALC_ST <= '1' when (state = DONE_CALC_STATE) else '0'; 
  DONE_CACHE_HIT_ST <= '1' when (state = DONE_CACHE_HIT_STATE) else '0'; 

  CU_DPU : process (clk, resetb)
    variable q_int_temp : std_logic_vector(7 downto 0);
    variable rem_temp     : std_logic_vector(7 downto 0);

  begin

    if (resetb = '0') then

      state   <= INITIAL_STATE;
      x       <= (others => '-');
      y       <= (others => '-');
      q_int   <= (others => '-');
      rem_int <= (others => '-');
	  clocks_taken_int <= (others => '-');
      done    <= '0';
      rd      <= '0';
      we      <= '0';
    elsif (clk'event and clk = '1') then

      rd   <= '0';
      we   <= '0';
      done <= '0';

      case (state) is
        when INITIAL_STATE =>
          if (start = '1') then
            state <= CACHE_CHECK_STATE;
            rd    <= '1';
          end if;
          x       <= xin;
          y       <= yin;
          q_int   <= (others => '0');
          rem_int <= xin; 
		  clocks_taken_int <= (others => '0');
		  -- Note: we do not change x by doing x <= x -y 
			-- as x is part of the tag-in (tag_in  <= x & y;)
			-- If we have a cache miss, we need to deposit the tag 
			-- into the CAM and the data (q & r) into the DATA RAM.

        when CACHE_CHECK_STATE =>
			-- Start computation anyways
			  rem_temp     := rem_int;
			  q_int_temp := q_int;
			  clocks_taken_int <= clocks_taken_int + 1;
			  
			  if (rem_temp >= y) then
				rem_temp     := rem_temp - y;
				q_int_temp := q_int_temp + '1';
			  end if;

			  rem_int <= rem_temp;
			  q_int   <= q_int_temp;
			-- one iteration of the computation is ended here
			
			-- Simultaneously check the cache
			  if hit_true = '1' then
				state   <= DONE_CACHE_HIT_STATE;
				q_int   <= data_out(15 downto 8);
				rem_int <= data_out(7 downto 0);
				done    <= '1';
			  elsif (rem_int <= y) then
				state <= DONE_CALC_STATE;
				we    <= '1';  -- Notice that these (we and done) are registered outputs
				done  <= '1';  -- The registering process is initiated slightly in advance so that 
								-- they go active at the right time.
			  else -- if more computation is needed
				state <= COMPUTE_STATE;
			  end if;
			-- What if we rewrite the above single "if" statement as shown below as two "if" statements?
				-- What if we are trying to divide 5 by 7 where, in the very first clock itself the division 
				-- is complete and cache search is still not complete. Well, cache serach is combinational
				-- and, hence, will be done by the end of the clock anyways. So, at the end of the first clock
				-- it is possible that both cache and calculation are complete. Then you need to give preference
				-- to one of them (figure-out which one) so that you do not save multiple copies of the same
				-- division in the cache. Why would we save multiple copies?
						  -- if hit_true = '1' then
							-- state   <= DONE_CACHE_HIT_STATE;
							-- q_int   <= data_out(15 downto 8);
							-- rem_int <= data_out(7 downto 0);
							-- done    <= '1';
						  -- end if;

						  -- if (rem_int <= y) then
							-- state <= DONE_CALC_STATE;
							-- we    <= '1';  
							-- done  <= '1';
						  -- else -- if more computation is needed
							-- state <= COMPUTE_STATE;
						  -- end if;		
			-- Does it help (either partially or completely), if we write the above two separate 
			-- "if" statements in the reverse order?
	
        when COMPUTE_STATE =>  -- continue computation
		  if (MCEN = '1') then   -- notice the MCEN control
			  rem_temp     := rem_int;
			  q_int_temp := q_int;
			  clocks_taken_int <= clocks_taken_int + 1;
			  
			  if (rem_temp >= y) then
				rem_temp     := rem_temp - y;
				q_int_temp := q_int_temp + '1';
			  end if;

			  rem_int <= rem_temp;
			  q_int   <= q_int_temp;

			  if (rem_int <= y) then
				state <= DONE_CALC_STATE;
				we    <= '1';  -- Notice that these (we and done) are registered outputs
				done  <= '1';  -- The registering process is initiated slightly in advance so that 
								-- they go active at the right time.
			  end if;
		  end if;  -- matching "end if" for the "if (MCEN = '1') then" 

		when DONE_CACHE_HIT_STATE =>
          done <= '1';
          if (ack = '1') then
            state <= INITIAL_STATE;
          end if;
          
        when DONE_CALC_STATE =>
          done <= '1';
          if (ack = '1') then
            state <= INITIAL_STATE;
          end if;
      end case;
      
    end if;

  end process CU_DPU;

end divider_with_cache_RTL;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
