----------------------------------------------------------------------------------
--
-- Description: Este m�dulo sustituye a la memoria de datos del mips. Incluye un memoria cache que se conecta a trav�s de un bus a memoria principal
-- el interfaz a�ade una se�al nueva (Mem_ready) que indica si la MC podr� ralizar la operaci�n en el ciclo actual
----------------------------------------------------------------------------------
library IEEE;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
-- Memoria RAM de 128 palabras de 32 bits
entity MD_mas_MC is port (
		  CLK : in std_logic;
		  reset: in std_logic;
		  ADDR : in std_logic_vector (31 downto 0); --Dir solicitada por el Mips
        Din : in std_logic_vector (31 downto 0);--entrada de datos desde el Mips
        WE : in std_logic;		-- write enable	del MIPS
		  RE : in std_logic;		-- read enable del MIPS
		  Mem_ready: out std_logic; -- indica si podemos hacer la operaci�n solicitada en el ciclo actual
		  Dout : out std_logic_vector (31 downto 0) --dato que se env�a al Mips
		  ); --salida que puede leer el MIPS
end MD_mas_MC;

architecture Behavioral of MD_mas_MC is
-- Memoria de datos con su controlador de bus
component  MD_cont is port (
		  CLK : in std_logic;
		  reset: in std_logic;
		  Bus_Frame: in std_logic; -- indica que el master quiere m�s datos
		  Bus_WE: in std_logic;
		  Bus_RE: in std_logic;
		  Bus_AD : in std_logic_vector (31 downto 0); --Direcciones y datos
        MD_Bus_DEVsel: out std_logic; -- para avisar de que se ha reconocido que la direcci�n pertenece a este m�dulo
		  MD_Bus_TRDY: out std_logic; -- para avisar de que se va a realizar la operaci�n solicitada en el ciclo actual
		  MD_send_data: out std_logic; -- para enviar los datos al bus
        MD_Dout : out std_logic_vector (31 downto 0)		  -- salida de datos
		  );
end component;
-- MemoriaCache de datos
COMPONENT MC_datos is port (
				CLK : in std_logic;
				reset : in  STD_LOGIC;
				--Interfaz con el MIPS
				ADDR : in std_logic_vector (31 downto 0); --Dir
				Din : in std_logic_vector (31 downto 0);
				RE : in std_logic;		-- read enable
				WE : in  STD_LOGIC;
				ready : out  std_logic;  -- indica si podemos hacer la operaci�n solicitada en el ciclo actual
				Dout : out std_logic_vector (31 downto 0); --dato que se env�a al Mips
				--Interfaz con el bus
				MC_Bus_Din : in std_logic_vector (31 downto 0);--para leer datos del bus
				Bus_TRDY : in  STD_LOGIC; --indica que el esclavo (la memoriade datos)  no puede realizar la operaci�n solicitada en este ciclo
				Bus_DevSel: in  STD_LOGIC; --indica que la memoria ha reconocido que la direcci�n est� dentro de su rango
				MC_send_addr : out  STD_LOGIC; --ordena que se env�en la direcci�n y las se�ales de control al bus
				MC_send_data : out  STD_LOGIC; --ordena que se env�en los datos
				MC_frame : out  STD_LOGIC; --indica que la operaci�n no ha terminado
				MC_Bus_ADDR : out std_logic_vector (31 downto 0); --Dir
				MC_Bus_data_out : out std_logic_vector (31 downto 0);--para enviar datos por el bus
				MC_bus_RE : out  STD_LOGIC; --RE y WE del bus
				MC_bus_WE : out  STD_LOGIC
		  );
  END COMPONENT;

--se�ales del bus
signal Bus_AD:  std_logic_vector(31 downto 0);
signal Bus_TRDY, Bus_Devsel, Bus_RE, Bus_WE, Bus_Frame: std_logic;
--se�ales de MC
signal MC_Bus_Din, MC_Bus_ADDR, MC_Bus_data_out: std_logic_vector (31 downto 0);
signal MC_send_addr, MC_send_data, MC_frame, MC_bus_RE, MC_bus_WE: std_logic;
--se�ales de MD
signal MD_Dout:  std_logic_vector(31 downto 0);
signal MD_Bus_DEVsel, MD_send_data, MD_Bus_TRDY: std_logic;

begin
------------------------------------------------------------------------------------------------
--   MC de datos
------------------------------------------------------------------------------------------------

	MC: MC_datos PORT MAP(	clk=> clk, reset => reset, ADDR => ADDR, Din => Din, RE => RE, WE => WE, ready => Mem_ready, Dout => Dout, MC_Bus_Din => MC_Bus_Din,
									Bus_TRDY => Bus_TRDY, Bus_DevSel => Bus_DevSel, MC_send_addr => MC_send_addr, MC_send_data => MC_send_data, MC_frame => MC_frame, MC_Bus_ADDR => MC_Bus_ADDR, MC_Bus_data_out => MC_Bus_data_out, MC_bus_RE => MC_bus_RE, MC_bus_WE => MC_bus_WE);

------------------------------------------------------------------------------------------------
-- Controlador de MD
------------------------------------------------------------------------------------------------
	controlador_MD: MD_cont PORT MAP (
          CLK => CLK,
          reset => reset,
          Bus_Frame => Bus_Frame,
          Bus_WE => Bus_WE,
          Bus_RE => Bus_RE,
          Bus_AD => Bus_AD,
          MD_Bus_DEVsel => MD_Bus_DEVsel,
          MD_Bus_TRDY => MD_Bus_TRDY,
          MD_send_data => MD_send_data,
          MD_Dout => MD_Dout
        );

	MC_Bus_Din <= Bus_AD;
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
--   	BUS: l�neas compartidas y buffers triestado
------------------------------------------------------------------------------------------------
-- Bus AD: tres fuentes de datos: MC (data y addr)y MD
	Bus_AD <= MC_Bus_data_out when MC_send_data='1' 	else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	Bus_AD <= MD_Dout when MD_send_data ='1' 			else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	Bus_AD <= MC_Bus_ADDR when MC_send_addr='1' 		else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

-- control
-- Como s�lo hay un m�ster no son l�neas compartidas
	Bus_RE <= MC_bus_RE;
	Bus_WE <=  MC_bus_WE;
	Bus_Frame <= MC_frame;
	Bus_DevSel <= MD_Bus_DEVsel; --s�lo la memoria activa DevSel
	Bus_TRDY <= MD_Bus_TRDY; --s�lo la memoria activa la se�al de wait

------------------------------------------------------------------------------------------------
end Behavioral;
