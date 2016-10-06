LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE work.FISC_DEFINES.all;

ENTITY FISC IS
	PORT(
		clk : IN std_logic;
		restart_cpu : in std_logic
	);
END;

ARCHITECTURE RTL OF FISC IS
	-----------------------------------------------
	---- Stage interconnect wires declaration: ----
	-- Stage 1 - Fetch Interconnect wires --
	signal if_new_pc             : std_logic_vector(FISC_INTEGER_SZ-1 downto 0) := (others => '0');
	signal if_reset              : std_logic := '0';
	signal if_branch_flag        : std_logic := '0';
	signal if_uncond_branch_flag : std_logic := '0';
	signal if_zero_flag          : std_logic := '0';
	signal if_instruction        : std_logic_vector(FISC_INSTRUCTION_SZ-1  downto 0) := (others => '0');
	
	-- Stage 2 - Decode Interconnect wires --
	signal sos            : std_logic := '0';
	signal microcode_ctrl : std_logic_vector(MICROCODE_CTRL_WIDTH downto 0) := (others => '0');
	-----------------------------------------------
BEGIN
	---- Microarchitecture Stages Declaration: ----
	-- Stage 1: Fetch
	Stage1_Fetch1  : Stage1_Fetch  PORT MAP(clk, if_new_pc, if_reset,  microcode_ctrl(0), if_branch_flag, if_uncond_branch_flag, if_zero_flag, if_instruction);
	-- Stage 2: Decode
	Stage2_Decode1 : Stage2_Decode PORT MAP(clk, sos, microcode_ctrl, if_instruction);
	-- Stage 3: Execute
	-- TODO
	-- Stage 4: Memory Access
	-- TODO
	-- Stage 3: Writeback
	-- TODO
	--------------------------
	------- Behaviour: -------
	--------------------------
	process(clk, restart_cpu) begin
		if restart_cpu = '1' then
			sos <= '1';
		else
			if clk = '0' then
				if microcode_ctrl(0) = '1' then
					sos <= '1';
				end if;
			else
				sos <= '0';
			end if;
		end if;
	end process;
	--------------------------
END ARCHITECTURE RTL;