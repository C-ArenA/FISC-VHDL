LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.FISC_DEFINES.all;

ENTITY ALU IS
	PORT(
		clk    : in  std_logic;
		opA    : in  std_logic_vector(FISC_INTEGER_SZ-1 downto 0);
		opB    : in  std_logic_vector(FISC_INTEGER_SZ-1 downto 0);
		func   : in  std_logic_vector(3 downto 0);
		result : out std_logic_vector(FISC_INTEGER_SZ-1 downto 0) := (others => '0');
		neg    : out std_logic := '0'; 
		zero   : out std_logic := '0';
		overf  : out std_logic := '0';
		carry  : out std_logic := '0'
	);
END;

ARCHITECTURE RTL OF ALU IS
	signal result_reg     : std_logic_vector(FISC_INTEGER_SZ-1 downto 0) := (others => '0');
	signal result_reg_ext : std_logic_vector(FISC_INTEGER_SZ downto 0)   := (others => '0');
	signal opA_ext : std_logic_vector(FISC_INTEGER_SZ downto 0)          := (others => '0');
	signal opB_ext : std_logic_vector(FISC_INTEGER_SZ downto 0)          := (others => '0');
	-- These signals are used for division calculation:
	signal sdivisor_operand : integer;
	signal udivisor_operand : integer;
BEGIN
	sdivisor_operand <= to_integer(signed(opB_ext))   WHEN signed(opB_ext) > 0 ELSE 1; -- TODO: Enter Exception Mode on Else
	udivisor_operand <= to_integer(unsigned(opB_ext)) WHEN signed(opB_ext) > 0 ELSE 1; -- TODO: Enter Exception Mode on Else
	
	result_reg <= result_reg_ext(FISC_INTEGER_SZ-1 downto 0);
	
	opA_ext <= opA(FISC_INTEGER_SZ-1) & opA;
	opB_ext <= opB(FISC_INTEGER_SZ-1) & opB;
	
	result_reg_ext <= 
		opA_ext and opB_ext WHEN func = "0000" ELSE -- AND
		opA_ext or opB_ext  WHEN func = "0001" ELSE -- ORR
		opA_ext xor opB_ext WHEN func = "0011" ELSE -- EOR
		opA_ext + opB_ext   WHEN func = "0010" ELSE -- ADD
		opA_ext - opB_ext   WHEN func = "0110" ELSE -- SUB
		(not opB_ext) + "1" WHEN func = "1000" ELSE -- NEG
		not opB_ext         WHEN func = "1001" ELSE -- NOT
		std_logic_vector(to_signed(to_integer(signed(opA_ext)) * to_integer(signed(opB_ext)), FISC_INTEGER_SZ + 1))       WHEN func = "1010" ELSE -- SMUL
		std_logic_vector(to_unsigned(to_integer(unsigned(opA_ext)) * to_integer(unsigned(opB_ext)), FISC_INTEGER_SZ + 1)) WHEN func = "1011" ELSE -- UMUL
		std_logic_vector(to_signed(to_integer(signed(opA_ext)) / sdivisor_operand, FISC_INTEGER_SZ + 1))                  WHEN func = "1100" ELSE -- SDIV
		std_logic_vector(to_unsigned(to_integer(unsigned(opA_ext)) / udivisor_operand, FISC_INTEGER_SZ + 1))              WHEN func = "1101" ELSE -- UDIV
		opB_ext                                                                                                           WHEN func = "0111" ELSE -- pass operand B
		to_stdlogicvector(to_bitvector(opA_ext) sll to_integer(unsigned(opB_ext)))                                        WHEN func = "1110" ELSE -- LSL
		to_stdlogicvector(to_bitvector(opA_ext) srl to_integer(unsigned(opB_ext)))                                        WHEN func = "1111";     -- LSR
	
	neg    <= '1' WHEN signed(result_reg) < 0 ELSE '0';
	zero   <= '1' WHEN result_reg_ext(FISC_INTEGER_SZ-1 downto 0) = (FISC_INTEGER_SZ-1 downto 0 => '0') ELSE '0';
	overf  <= '1' WHEN unsigned(result_reg) < 0 ELSE '0';
	carry  <= result_reg_ext(FISC_INTEGER_SZ);
	
	----------------
	-- Behaviour: --
	----------------
	main_proc: process(result_reg_ext)
	begin
	   if result_reg_ext(FISC_INTEGER_SZ) /= result_reg_ext(FISC_INTEGER_SZ-1) then
	      if result_reg_ext(FISC_INTEGER_SZ) = '1' then
	         result <= ('1', others => '0');
	      else
	         result <= ('0', others => '1');
	      end if;
	   else
	      result <= result_reg_ext(FISC_INTEGER_SZ-1 downto 0);
	   end if;
	end process;
END ARCHITECTURE RTL;