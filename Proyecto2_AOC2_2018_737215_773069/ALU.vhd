----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:10:07 04/03/2014 
-- Design Name: 
-- Module Name:    ALU - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( DA : in  STD_LOGIC_VECTOR (31 downto 0); --entrada 1
           DB : in  STD_LOGIC_VECTOR (31 downto 0); --entrada 2
           ALUctrl : in  STD_LOGIC_VECTOR (2 downto 0); -- funci�n a realizar: 0 suma, 1 resta, 2 AND, 3 OR. El resto se dejan por si queremos a�adir operaciones
           Dout : out  STD_LOGIC_VECTOR (31 downto 0)); -- salida
end ALU;

architecture Behavioral of ALU is
signal Dout_internal : STD_LOGIC_VECTOR (31 downto 0);
begin
Dout_internal <= 	DA + DB when (ALUctrl="000") 
			else DA - DB when (ALUctrl="001") 
			else DA AND DB when (ALUctrl="010")
			else DA OR DB when (ALUctrl="011")
			else "00000000000000000000000000000000";
Dout <= Dout_internal;

end Behavioral;