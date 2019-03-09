library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Unidad de anticipacion incompleta. Ahora mismo selecciona siempre la entrada 0
-- Entradas:
-- Reg_Rs_EX
-- Reg_Rt_EX
-- RegWrite_MEM
-- RW_MEM
-- RegWrite_WB
-- RW_WB
-- Salidas:
-- MUX_ctrl_A
-- MUX_ctrl_B
entity UA is
	Port(
			Reg_Rs_EX: IN  std_logic_vector(4 downto 0);
			Reg_Rt_EX: IN  std_logic_vector(4 downto 0);
			RegWrite_MEM: IN std_logic;
			RW_MEM: IN  std_logic_vector(4 downto 0);
			RegWrite_WB: IN std_logic;
			RW_WB: IN  std_logic_vector(4 downto 0);
			MUX_ctrl_A: out std_logic_vector(1 downto 0);
			MUX_ctrl_B: out std_logic_vector(1 downto 0)
		);
	end UA;

Architecture Behavioral of UA is
signal Corto_A_Mem, Corto_B_Mem, Corto_A_WB, Corto_B_WB: std_logic;
begin
-- Debeis dise�arla vosotros. Analizando las entrads debe saber si hay que hacer un corto o coger le dato del BR. Ahora mismo elije siempre la entrada 0. Es decir no hace nunca anticipaci�n
-- Adem�s deb�is conectar las salidas de este m�dulo con las entradas que lo usen. Analizar c�mo usa cada instrucci�n A y B y ver si pueden usar los cortos y c�mo.
-- entrada 00: se corresponde al dato del banco de registros
-- entrada 01: dato de la etapa Mem
-- entrada 10: dato de la etapa WB

	MUX_ctrl_A <= "10" when (RegWrite_WB ='1') and (RW_WB = Reg_Rs_EX)
	else "01" when (RegWrite_MEM ='1') and (RW_MEM = Reg_Rs_EX)
	else "00";
	MUX_ctrl_B <= "10" when (RegWrite_WB ='1') and (RW_WB = Reg_Rt_EX)
	else "01" when (RegWrite_MEM ='1') and (RW_MEM = Reg_Rt_EX)
	else "00";

	Corto_A_Mem <= '1' when (RegWrite_MEM = '1') AND (RW_MEM = Reg_Rs_EX)
	else '0';
	Corto_A_WB <= '1' when (RegWrite_WB = '1') AND (RW_WB = Reg_Rs_EX)
	else '0';

	Corto_B_Mem <= '1' when (RegWrite_MEM = '1') AND (RW_MEM = Reg_Rt_EX)
	else '0';
	Corto_B_WB <= '1' when (RegWrite_WB = '1') AND (RW_WB = Reg_Rt_EX)
	else '0';

end Behavioral;
