------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.reverseAssemblyFunctionPkg.all;

------------------------------------------------------------------------------
entity cpu_1 is
    Port ( 
	   reset_b               	: in std_logic;
       in_reg_addr              : in std_logic_vector(4 downto 0); -- input ID for the register we want to see
       out_reg_data          	: out std_logic_vector(31 downto 0); -- output data given by the register
       clk                   	: in std_logic
		);
end cpu_1;

architecture behave of cpu_1 is
------------ Describe your architecture Here------------------------------------------------
	component instruction_mem
		generic (
         DATA_WIDTH     : integer := 32; 
         ADDR_WIDTH     : integer := 8
        );
		port(
				addr		: IN std_logic_VECTOR(7 downto 0);
				data_out	: OUT std_logic_VECTOR(31 downto 0);
				clka        : in std_logic
			  );
	end component;
	
	component data_mem_dp
	generic (
         DATA_WIDTH     : integer := 32; 
         ADDR_WIDTH     : integer := 5
        );
		port (
			addr_a        : in  std_logic_vector(4 downto 0);
			data_in_a     : in  std_logic_vector(31 downto 0);
			mem_write     : in  std_logic; 
			data_out_a    : out std_logic_vector(31 downto 0);
			mem_read	  : in  std_logic;
			clka          : in  std_logic
     ); 
	end component ; 

	
	component register_file
		port(
				clk_rf					: in std_logic;
				reset_rf				: in std_logic;	
				write_data_rf			: in std_logic_vector(31 downto 0);	-- write port
				wen_rf					: in std_logic;
				write_addr				: in std_logic_vector(4 downto 0);
				rsaddr_rf				: in std_logic_vector(4 downto 0); -- read port ($rs)
				rtaddr_rf				: in std_logic_vector(4 downto 0); -- read port ($rd)
				reg_read_addr			: in std_logic_vector(4 downto 0); -- read port (for debugging, used by the testbench only)
				rsdata_rf				: out std_logic_vector(31 downto 0);
				rtdata_rf				: out std_logic_vector(31 downto 0);
				reg_read_data			: out std_logic_vector(31 downto 0)
			  );
	end component;
	
	component ALU
		port (
				alu_in1		: in std_logic_vector(31 downto 0);
				alu_in2		: in std_logic_vector(31 downto 0);
				alu_op		: in std_logic_vector(2 downto 0);
				alu_out		: out std_logic_vector(31 downto 0)
				);
	end component;


	
---------------------------signal declarations--------------------------------------
	-- IF stage
	signal PCOUT												: std_logic_vector (31 downto 0); -- output of PC
	signal INS_MEM_OUT											: std_logic_vector (31 downto 0); -- output of instruction memory
	signal PC_IF_IN												: std_logic_vector (31 downto 0); -- input of PC
	signal IF_FLUSH_BR											: std_logic;					  -- 

	-- ID Stage
	signal PC_ID												: std_logic_vector (31 downto 0); -- (PC) of IF/ID 
	signal OPCODE												: std_logic_vector (5 downto 0);  -- opcode of IF/ID
	signal RS_ID,RT_ID,RD_ID									: std_logic_vector (4 downto 0);  -- rs, rt and rd of IF/ID
	signal FUNCT												: std_logic_vector (5 downto 0);  -- funct of IF/ID
	signal OFFSET16												: std_logic_vector (15 downto 0); -- lower 16 bits of the output of the instruction memory
	signal ID_FLUSH_JMP				            				: std_logic;					  -- In ee457_early_branch_block_diagram.pdf, there is only one signal named IF.Flush
																								  -- but in this code, we maintain two wristband signals, ID_FLUSH_JMP and ID_FLUSH_BR in IF/ID
																								  -- and generate ID_FLUSH_ID in ID stage
																								  -- Another difference is that ID_FLUSH_JMP and ID_FLUSH_BR are not inverted twice
																								  -- unlike in ee457_early_branch_block_diagram.pdf
	signal ID_FLUSH_BR											: std_logic;					  
	signal IF_FLUSH_ID            								: std_logic;					  -- flush signal that goes to control logic
	signal STALL_BR, STALL_LW, STALL 		   					: std_logic;					  -- signals generated from HDU
	signal J26 													: std_logic_vector (25 downto 0); -- lower 26 bits of the output of the instruction memory to compute the new PC in case of jmp
	signal EXTENDED_OFFSET_ID_OUT								: std_logic_vector (31 downto 0); 
	signal RDATA1_ID_OUT, RDATA2_ID_OUT							: std_logic_vector (31 downto 0); -- outputs of muxes in ID stage
	signal RS_DATA_ID, RT_DATA_ID								: std_logic_vector (31 downto 0); -- R1 and R2 outputs of the register file
	
	-- EX Stage
	signal MEMTOREG_EX,REGWRITE_EX,MEMWRITE_EX,MEMREAD_EX,ALUSRC_EX		: std_logic;
	signal REGDST_EX													: std_logic;	-- distinguish between lw and R-type in EX stage
	signal ALUOP_EX														: std_logic_vector (2 downto 0); -- specifies which R-type instruction
	signal RT_EX,RS_EX,RD_EX,W_ADDR_EX									: std_logic_vector (4 downto 0); -- ID/EX read register RT, RS and RD, and ID/EX write register (id of regster to be written)
	signal RDATA1_EX,RDATA2_EX,EXTENDED_OFFSET_EX,RES_EX				: std_logic_vector (31 downto 0);
	signal ALUIN1, ALUIN2, MEM_WRITE_DATA								: std_logic_vector (31 downto 0); -- ALU input 1 and 2, and store_data in EX/MEM

	-- MEM Stage	
	signal MEMTOREG_MEM,REGWRITE_MEM,MEMWRITE_MEM,MEMREAD_MEM			: std_logic;
	signal ALU_RES_MEM,MW_DATA_MEM,MEMDATA_MEM 							: std_logic_vector (31 downto 0);
	signal W_ADDR_MEM													: std_logic_vector (4 downto 0);
	
	-- WB Stage
	signal REGWRITE_WB,MEMTOREG_WB					: std_logic ;
	signal ALU_RES_WB,MEMDATA_WB,W_DATA_WB			: std_logic_vector (31 downto 0);
	signal W_ADDR_WB								: std_logic_vector (4 downto 0);
	
	-- Reverse Assembly
	signal ifetch_instruction_string_sig : string(1 to 24) := "Empty_Empty_Empty_Empty!";

	begin

	INS_MEM : instruction_mem
		port map (
				addr 				=> PCOUT(9 downto 2), -- bypass the signal before PC;
				data_out 			=> INS_MEM_OUT,
				clka                => clk);

				

	DataMem : data_mem_dp
		port map (
				addr_a 				=> ALU_RES_MEM(6 downto 2),
				data_in_a			=> MW_DATA_MEM, 
				mem_write			=> MEMWRITE_MEM,   -- bypass the signal before EX/MEM reg
				data_out_a			=> MEMDATA_MEM,
				mem_read 			=> MEMREAD_MEM,		  -- bypass the signal before EX/MEM reg
				clka                => clk
				);
	
	RegFile:	register_file
		port map(
				clk_rf				=> clk,				
				reset_rf			=> reset_b,		
				write_data_rf		=> W_DATA_WB,	
				wen_rf				=> REGWRITE_WB,	
				write_addr			=> W_ADDR_WB,	
				rsaddr_rf			=> RS_ID,	
				rtaddr_rf			=> RT_ID,
				reg_read_data		=> out_reg_data,	
				rsdata_rf			=> RS_DATA_ID,	
				rtdata_rf			=> RT_DATA_ID,	
				reg_read_addr		=> in_reg_addr
			  );
	
	Arith_Logic_Unit: ALU 
		port map(
				alu_in1				=> ALUIN1,
				alu_in2				=> ALUIN2,
				alu_op				=> ALUOP_EX,
				alu_out				=> RES_EX
				);

	ifetch_instruction_string_sig <= reverse_Assembly(INS_MEM_OUT); -- for debugging
																	-- translates the instruction from INS_MEM


	-- controls stage registers
	pipeline: process (CLK,reset_b)
	
	--IF STAGE
	variable IF_FLUSH_JMP : std_logic;
	variable MULTU,MFHI,MFLO: std_logic;
	variable REGWRITE,REGDST,MEMREAD,MEMWRITE,ALUSRC,MEMTOREG : std_logic;
	variable REGWRITE_ID,REGDST_ID,MEMREAD_ID,MEMWRITE_ID,ALUSRC_ID,MEMTOREG_ID: std_logic;
	variable ALUOP,ALUOP_ID: std_logic_vector (2 downto 0);
	variable RDATA1_ID,RDATA2_ID: std_logic_vector (31 downto 0);
	variable RES_EX_V,W_DATA_WB_V: std_logic_vector (31 downto 0);
	variable JMP_ID, BEQ, BEQ_ID : std_logic;
	variable PC_ID_OUT : std_logic_vector (31 downto 0);
	
	begin
	
	if reset_b = '0' then	--	if reset is active
        
		-- IF Stage
		PCOUT(31 downto 0) <= (others => '0');
		IF_FLUSH_JMP := '1';

		-- ID Stage
		PC_ID <= (OTHERS => '-');
		ID_FLUSH_JMP <= '1';
		ID_FLUSH_BR <= '-';
		
		-- EX Stage
		MEMTOREG_EX <= '-';
		MEMWRITE_EX <= '0';
		MEMREAD_EX <= '0';
		REGWRITE_EX <= '0';
		ALUOP_EX <= "---";
		REGDST_EX <= '-';
	
		RDATA1_EX <= (others => '-');
		RDATA2_EX <= (others => '-');
		EXTENDED_OFFSET_EX <= (others => '-');
		ALUSRC_EX <= '-';
		RT_EX <= (others => '-');
		RS_EX <= (others => '-');
		RD_EX <= (others => '-');
		
		-- MEM Stage
		MEMTOREG_MEM <= '-';
		MEMWRITE_MEM <= '0';
		MEMREAD_MEM <= '0';
		REGWRITE_MEM <= '0';
		ALU_RES_MEM <= (others => '-');
		W_ADDR_MEM <= (others => '-');
--		DATAMEM_EN <= '0';
		
		-- WB Stage
		REGWRITE_WB <= '0';
		MEMTOREG_WB <= '-';
		W_ADDR_WB <= (others => '-');
		ALU_RES_WB <= (others => '-');
		MEMDATA_WB <= (others => '-');
    
	elsif (clk'event and clk ='1') then

		--IF Stage
		if(STALL = '0')then

			PCOUT <= PC_IF_IN;
			PC_ID <= PCOUT+4;

			ID_FLUSH_BR <= IF_FLUSH_BR;  
			--ID Stage
			OPCODE <= INS_MEM_OUT ( 31 downto 26);
			FUNCT <= INS_MEM_OUT ( 5 downto 0);
			RT_ID <= INS_MEM_OUT ( 20 downto 16);
			RD_ID <= INS_MEM_OUT ( 15 downto 11);
			RS_ID <= INS_MEM_OUT ( 25 downto 21);
			OFFSET16 <= INS_MEM_OUT ( 15 downto 0);
			J26 <= INS_MEM_OUT (25 downto 0);
		else
			null;
		end if;
        
        -- -- Control Unit

		JMP_ID := '0';
		BEQ := '0';		

		if (IF_FLUSH_ID = '1') then
			MEMTOREG := '0';
			REGWRITE := '0';
			MEMWRITE := '0';
			MEMREAD := '0';
			ALUSRC := '0';
			ALUOP := "000";
			REGDST := '0';
			JMP_ID := '0';
			BEQ := '0';
		elsif (STALL = '1') then
			MEMTOREG := '0';
			REGWRITE := '0';
			MEMWRITE := '0';
			MEMREAD := '0';
			ALUSRC := '0';
			ALUOP := "000";
			REGDST := '0';
		else    
			MEMTOREG := '0';
			REGWRITE := '0';
			MEMWRITE := '0';
			MEMREAD := '0';
			ALUSRC := '0';
			ALUOP := "000";
			REGDST := '0';
			JMP_ID := '0';
			BEQ := '0';
            
			case (OPCODE) is
				when "000000" =>      -- R type
				REGWRITE := '1';
				ALUSRC := '0';
				REGDST := '1';
			
				case (FUNCT) is
					when "100000" => ALUOP := "000";
					when "100010" => ALUOP := "001";
					when "100100" => ALUOP := "010";
					when "100101" => ALUOP := "011";
					when "101010" => ALUOP := "100";
					when "011001" => MULTU := '1';
					when others => null;
				end case;
			
				when "100011" =>   -- LW
					MEMTOREG := '1';
					REGWRITE := '1';
					MEMREAD := '1';
					ALUSRC := '1';
					ALUOP := "000";
					REGDST := '0';
				
				when "101011" =>  -- SW
					MEMWRITE := '1';
					ALUSRC := '1';
					ALUOP := "000";
				
				when "000010" =>
					JMP_ID := '1';
				
				when "000100" =>
					BEQ := '1';
				
				
				when others =>
					null;
			end case;
		end if;
		
		MEMTOREG_ID := MEMTOREG;
		REGWRITE_ID := REGWRITE;
		MEMWRITE_ID := MEMWRITE;
		MEMREAD_ID := MEMREAD;
		ALUSRC_ID := ALUSRC;
		ALUOP_ID := ALUOP;
		REGDST_ID := REGDST;
        
	    IF_FLUSH_JMP := JMP_ID; 			-- IF_FLUSH_JMP is '1' if ID stage is jmp
	    ID_FLUSH_JMP <= IF_FLUSH_JMP;  -- ID_FLUSH_JMP is '1' if ID stage is jmp
	
		-- ID/EX
		
		if (STALL = '0') then
			REGWRITE_EX <= REGWRITE_ID;
			MEMWRITE_EX <= MEMWRITE_ID;
			MEMREAD_EX <= MEMREAD_ID;
		else
			REGWRITE_EX <= '0';
			MEMWRITE_EX <= '0';
			MEMREAD_EX <= '0';
		end if;
		  
	    ALUSRC_EX <= ALUSRC_ID;
	    REGDST_EX <= REGDST_ID;
	    MEMTOREG_EX <= MEMTOREG_ID;
	    ALUSRC_EX <= ALUSRC_ID;
	    ALUOP_EX <= ALUOP_ID;
	    RDATA1_EX <= RDATA1_ID_OUT;
	    RDATA2_EX <= RDATA2_ID_OUT;
	    EXTENDED_OFFSET_EX <= EXTENDED_OFFSET_ID_OUT;
	    RS_EX <= RS_ID;
	    RT_EX <= RT_ID;
	    RD_EX <= RD_ID;
	  
	    -- EX/MEM 
	    MEMTOREG_MEM <= MEMTOREG_EX;
	    REGWRITE_MEM <= REGWRITE_EX;
	    --MEMWRITE_MEM <= MEMWRITE_EX;
		
		if (reset_b = '0') then
			MEMWRITE_MEM <= '0';
			MEMREAD_MEM <= '0';
		else
			MEMWRITE_MEM <= MEMWRITE_EX;
			MEMREAD_MEM <= MEMREAD_EX;
		end if;
		
	    --MEMREAD_MEM <= MEMREAD_EX;
	    ALU_RES_MEM <= RES_EX;
  	    W_ADDR_MEM <= W_ADDR_EX;
	    MW_DATA_MEM  <= MEM_WRITE_DATA;
		--DATAMEM_EN <= MEMREAD_EX or MEMWRITE_EX;

		-- MEM/WB
	    MEMDATA_WB <= MEMDATA_MEM;
	    ALU_RES_WB <= ALU_RES_MEM;
	    MEMTOREG_WB <= MEMTOREG_MEM;
	    REGWRITE_WB <= REGWRITE_MEM;
	    W_ADDR_WB <= W_ADDR_MEM;
     
   end if;
   
   end process pipeline;

   -- Hazard Detection Unit 
   -- LW followed by an R-type instruction (STALL_FOR_LW Process)
   -- Branch followed by an R-type instruction (STALL_FOR_BR Process)
   -- LW followed by a branch instruction (STALL_FOR_BR Process)
   -- detects hazards and stall the pipeline
   -- 
   -- STALL_LW and STALL_BR are set to 0 so there are no stalls at all, but you will have to fill in thse two processes
   -- so that stalls are generated when above situations arise.

    -- HDU (Original Hazard Detection Unit in ID stage)
	STALL_FOR_LW: process (MEMREAD_EX, RS_ID, W_ADDR_EX, RT_ID, OPCODE, REGWRITE_EX, IF_FLUSH_ID)
	begin
		-- R-type in ID  lw in EX
		if (((W_ADDR_EX = RT_ID ) or (W_ADDR_EX = RS_ID))	-- and (OPCODE = "000000") 
		     and (IF_FLUSH_ID = '0') 
			 and (MEMREAD_EX = '1') and (REGWRITE_EX = '1')) then 
			STALL_LW <= '1';
		else
			STALL_LW <= '0';
		end if ;		 
	end process STALL_FOR_LW;
	
	-- HDU_Br (New Hazard Detection Unit in ID stage to serve the early branch)
	STALL_FOR_BR: process (OPCODE, REGWRITE_EX, RS_ID, W_ADDR_EX, RT_ID, MEMREAD_MEM, W_ADDR_MEM,IF_FLUSH_ID)
	begin
	    --   ID stage is beq    and  (ex is lw or R-type     or mem is lw)   and   register ID's are the same
		if ((IF_FLUSH_ID = '0')and(  ((OPCODE = "000100") and (REGWRITE_EX = '1') and ( W_ADDR_EX = RS_ID or W_ADDR_EX = RT_ID) ) 
		     or ((OPCODE = "000100") and (MEMREAD_MEM = '1') and ( W_ADDR_MEM = RS_ID or W_ADDR_MEM = RT_ID) )  )) then
			STALL_BR <= '1';
	    else
			STALL_BR <= '0';
        end if;		 
	end process;  

	STALL			<= (STALL_LW or STALL_BR); -- STALL is STALL_LW or STALL_BEQ
	IF_FLUSH_ID 		<= ID_FLUSH_JMP or (not reset_b) or ID_FLUSH_BR;
	-- if ID stage is jmp  or  reset is active  or  flush due to successful beq
	W_DATA_WB 		<= MEMDATA_WB when MEMTOREG_WB = '1' else
					 ALU_RES_WB;

   -- Forwarding Unit(Combinational) 
   -- Forwards the values from Ex, Mem, WB stages to ID and EX and MEM Stages
   -- Basically create several muxes so that it can either get values from previous stages or later stages
   -- PC_UPDATE_AND_ID_FU process takes care of forwarding to ID stage
   -- EX_MEM_FU process takes care of forwarding to EX and MEM stage
   
	PC_UPDATE_AND_ID_FU: process(OPCODE, IF_FLUSH_ID, RS_ID, RT_ID, OFFSET16, PCOUT, PC_ID, RS_DATA_ID, RT_DATA_ID, J26,
	                             REGWRITE_MEM, W_ADDR_MEM, reset_b, STALL, W_ADDR_WB, REGWRITE_WB,ALU_RES_MEM,ALU_RES_WB, W_DATA_WB, RDATA1_ID_OUT, RDATA2_ID_OUT)-- new  added ;
		
		variable RDATA1, RDATA2, EXTENDED_OFFSET_ID : std_logic_vector (31 downto 0);
		
		--for forward
		variable FW_RS, FW_RT, FW_RS_WB, FW_RT_WB  :  std_logic;
		
		begin

			RDATA1 := RS_DATA_ID;	-- R1 output of the register file
			RDATA2 := RT_DATA_ID;	-- R2 output
						
			EXTENDED_OFFSET_ID(15 downto 0) := offset16;
			  
			for i IN 31 downto 16 LOOP
				EXTENDED_OFFSET_ID(i) := offset16(15);
			end LOOP;
			
			EXTENDED_OFFSET_ID_OUT <= EXTENDED_OFFSET_ID;	-- sign extension generated from shift in IF/ID
	
		
			-----------------------------------------------------------
			-- FU_BR  
			-- Branch in ID, R-type in MEM will be detected by HDU
		   	if ((W_ADDR_MEM = RS_ID) and (REGWRITE_MEM = '1')and (W_ADDR_MEM /= "00000")) then
			   FW_RS := '1';
			else
			   FW_RS := '0';
			end if;   
			 
		    if ((W_ADDR_MEM = RT_ID) and (REGWRITE_MEM = '1') and (W_ADDR_MEM /= "00000")) then
			   FW_RT := '1';
			else 
			   FW_RT  := '0';
			end if;
			
			-- FU for MEM Hazard
			-- lw in WB stage helps ID
		   	if ((W_ADDR_WB = RS_ID) and (REGWRITE_WB = '1') and (W_ADDR_WB /= "00000")) then
			   FW_RS_WB := '1';
			else
			   FW_RS_WB := '0';
			end if;   
			 
		    if ((W_ADDR_WB = RT_ID) and (REGWRITE_WB = '1') and (W_ADDR_WB /= "00000")) then
			   FW_RT_WB := '1';
			else 
			   FW_RT_WB  := '0';
			end if;
			
			-- muxes in ID stage that get help from FU_BR
			if ( FW_RS = '1') then 			  -- forwarded from EX
			   RDATA1_ID_OUT <= ALU_RES_MEM;
			elsif ( FW_RS_WB = '1') then	  -- internally-forwarded by the register file (new value is just written to the register file by WB)
			   RDATA1_ID_OUT <= W_DATA_WB;
			else							  -- no forwarding
			   RDATA1_ID_OUT <= RDATA1;
			end if; 
			
		    if ( FW_RT = '1') then 			  -- forwarded from EX
			   RDATA2_ID_OUT <= ALU_RES_MEM;
			elsif ( FW_RT_WB = '1') then	  -- internally-forwarded by the register file (new value is just written to the register file by WB)
			   RDATA2_ID_OUT <= W_DATA_WB;
			else 							  -- no forwarding
			   RDATA2_ID_OUT <= RDATA2;
			end if; 	
			---------------------------------------------------------------
			
			-- generate new PC input and IF_FLUSH_BR
			if ((STALL = '0') and (RDATA1_ID_OUT = RDATA2_ID_OUT and (OPCODE = "000100" and IF_FLUSH_ID = '0'))) then  -- no stall  and  successful beq  and the instruction in ID is valid
				PC_IF_IN <= EXTENDED_OFFSET_ID(29 downto 0) & '0' & '0' + PC_ID;
				IF_FLUSH_BR	<= '1';
			elsif (OPCODE = "000010" and IF_FLUSH_ID = '0') then     -- jmp
				PC_IF_IN <= PC_ID(31 downto 28) & J26(25 downto 0) & '0' & '0';
				IF_FLUSH_BR	<= '0';
			elsif (STALL = '1' or reset_b = '0') then				   -- pipeline is stalled
				PC_IF_IN <= PCOUT;
				IF_FLUSH_BR	<= '0';
			else
				PC_IF_IN <= PCOUT + 4;
				IF_FLUSH_BR <= '0';
			end if;
			
	end process;
	
	-- FU for EX hazard
	EX_MEM_FU: process (REGDST_EX, RT_EX, RD_EX, RDATA1_EX, EXTENDED_OFFSET_EX, MEM_WRITE_DATA,
	                    REGWRITE_MEM, W_ADDR_MEM, REGWRITE_WB, W_ADDR_WB, W_DATA_WB, RS_EX, ALU_RES_MEM, RDATA2_EX, 
						MEMTOREG_MEM, MEMDATA_MEM, ALUSRC_EX, MEMWRITE_EX)
	
	variable FW_RT_WB, FW_RS_WB, FW_RT_MEM, FW_RS_MEM   :std_logic;
	variable rs_temp, rt_temp, rt_temp2    				:std_logic_vector (31 downto 0);
	begin
	     -- mux in EX stage governed by RegDst
	     if (REGDST_EX = '0') then  -- EX-stage is lw
          	W_ADDR_EX <= RT_EX; 	
     	 else						-- EX stage is R-type
            W_ADDR_EX <= RD_EX;
         end if;
       
		-- lw followed by any relevant instruction will be detected by HDU, so only consider R-type in MEM help EX 
		 if ((REGWRITE_MEM = '1') and (W_ADDR_MEM /= "00000") and (W_ADDR_MEM = RS_EX)) then
			FW_RS_MEM := '1';
		 else
			FW_RS_MEM := '0';
		 end if;
		 
		 if ((REGWRITE_MEM = '1') and (W_ADDR_MEM /= "00000") and (W_ADDR_MEM = RT_EX)) then
			FW_RT_MEM := '1';
		 else
			FW_RT_MEM := '0';
		 end if;
		 
		 -- lw/R-type in WB help EX
		 if ((REGWRITE_WB ='1') and (W_ADDR_WB /= "00000") and (W_ADDR_WB = RS_EX))then 
			FW_RS_WB := '1';
		 else
			FW_RS_WB := '0';
		 end if;
		 
		 if ((REGWRITE_WB ='1') and (W_ADDR_WB /= "00000") and (W_ADDR_WB = RT_EX))then 
			FW_RT_WB := '1';
		 else
			FW_RT_WB := '0';
		 end if;
		 
		-- first mux in EX, controlled by FW_RS_WB
		 if ( FW_RS_WB = '1') then 
		    rs_temp := W_DATA_WB;
		else
		    rs_temp := RDATA1_EX;
		end if;
		
		-- second mux in EX, controlled by FW_RS_MEM
		if ( FW_RS_MEM = '1') then
		   ALUIN1 <= ALU_RES_MEM;
		else
		   ALUIN1 <= rs_temp;
		 end if ;
		 
		if ( FW_RT_WB = '1') then 
		    rt_temp := W_DATA_WB;
		else
		    rt_temp := RDATA2_EX;
		end if;
		
		if ( FW_RT_MEM = '1') then
		   rt_temp2 := ALU_RES_MEM;
		else
		   rt_temp2 := rt_temp;
		end if ;
		  
		if (ALUSRC_EX = '1') then
            ALUIN2 <= EXTENDED_OFFSET_EX ;
        else
			ALUIN2 <= rt_temp2;
        end if;
		
		MEM_WRITE_DATA <= rt_temp2;
	
     end process EX_MEM_FU;
	 
end architecture behave;	  

