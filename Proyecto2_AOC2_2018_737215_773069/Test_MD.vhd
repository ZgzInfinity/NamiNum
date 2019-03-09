--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:10:50 05/10/2018
-- Design Name:   
-- Module Name:   D:/pruebas/MD/Test_MD.vhd
-- Project Name:  MD
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: MD_cont
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: Banco de prueba para ver cómo funciona la memoria de datos con el bus

--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY Test_MD IS
END Test_MD;
 
ARCHITECTURE behavior OF Test_MD IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT MD_cont
    PORT(
         CLK : IN  std_logic;
         reset : IN  std_logic;
         Bus_Frame : IN  std_logic;
         Bus_WE : IN  std_logic;
         Bus_RE : IN  std_logic;
         Bus_AD : IN  std_logic_vector(31 downto 0);
         MD_Bus_DEVsel : OUT  std_logic;
         MD_Bus_TDRY : OUT  std_logic;
         MD_send_data : OUT  std_logic;
         MD_Dout : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal reset : std_logic := '0';
   signal Bus_Frame : std_logic := '0';
   signal Bus_WE : std_logic := '0';
   signal Bus_RE : std_logic := '0';
   signal Bus_AD : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal MD_Bus_DEVsel : std_logic;
   signal MD_Bus_TDRY : std_logic;
   signal MD_send_data : std_logic;
   signal MD_Dout : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: MD_cont PORT MAP (
          CLK => CLK,
          reset => reset,
          Bus_Frame => Bus_Frame,
          Bus_WE => Bus_WE,
          Bus_RE => Bus_RE,
          Bus_AD => Bus_AD,
          MD_Bus_DEVsel => MD_Bus_DEVsel,
          MD_Bus_TDRY => MD_Bus_TDRY,
          MD_send_data => MD_send_data,
          MD_Dout => MD_Dout
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      reset 		<= '1';
		Bus_Frame 	<= '0';
		Bus_WE 		<= '1';
      Bus_RE 		<= '0';
      Bus_AD 		<= x"01000000";
		wait for 40 ns;	
		reset <= '0';
      wait for CLK_period*1;
		-- Petición fuera de rango no debe pasar nada
		Bus_Frame 	<= '1';
		Bus_WE 		<= '1';
      Bus_RE 		<= '0';
      wait for CLK_period*4;
		-- Petición dentro de rango de escritura
		Bus_AD 		<= X"00000100";
		wait until  MD_Bus_DEVsel = '1';
		Bus_AD 		<= x"00000001"; --ponemos el primer dato
		wait for 1 ns;
		wait until MD_Bus_TDRY ='1'; --esperamos a que nos digan que lo pueden coger
		wait until CLK'event and CLK = '1'; -- esperamos a que llegue un flanco para que lo procesen
		Bus_AD 		<= x"00000002"; --ponemos el segundo dato
		wait for 1 ns;
		wait until MD_Bus_TDRY ='1'; --esperamos a que nos digan que lo pueden coger
		wait until CLK'event and CLK = '1'; -- esperamos a que llegue un flanco para que lo procesen
		Bus_AD 		<= x"00000003"; --ponemos el tercer dato
		wait for 1 ns;
		wait until MD_Bus_TDRY ='1'; --esperamos a que nos digan que lo pueden coger
		wait until CLK'event and CLK = '1'; -- esperamos a que llegue un flanco para que lo procesen
		Bus_AD 		<= x"00000004"; --ponemos el cuarto dato
		wait for 1 ns;
		wait until MD_Bus_TDRY ='1'; --esperamos a que nos digan que lo pueden coger
		wait until CLK'event and CLK = '1'; -- esperamos a que llegue un flanco para que lo procesen
		Bus_Frame 	<= '0'; --decimos que ya hemos terminado
		Bus_AD 		<= x"00000005"; --No debería escribirse
		wait for CLK_period*4;
		-- Petición dentro de rango de lectura
		Bus_AD 		<= X"00000100";
		Bus_WE 		<= '0';
		Bus_RE 		<= '1';
		wait for CLK_period*4; -- no debe pasar nada porque el Bus-Frame no está activado
		Bus_Frame <= '1';
		wait until  MD_Bus_DEVsel = '1';
		-- la memoria debe mandar los 4 datos y luego ceros
		wait for CLK_period*30;
				

      wait;
   end process;

END;
