----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:12:11 04/04/2014 
-- Design Name: 
-- Module Name:    DMA - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


entity MD_cont is port (
		  CLK : in std_logic;
		  reset: in std_logic;
		  Bus_Frame: in std_logic; -- indica que el master quiere más datos
		  Bus_WE: in std_logic;
		  Bus_RE: in std_logic;
		  Bus_AD : in std_logic_vector (31 downto 0); --Direcciones y datos 
		  MD_Bus_DEVsel: out std_logic; -- para avisar de que se ha reconocido que la dirección pertenece a este módulo
		  MD_Bus_TRDY: out std_logic; -- para avisar de que se va a realizar la operación solicitada en el ciclo actual
		  MD_send_data: out std_logic; -- para enviar los datos al bus
        MD_Dout : out std_logic_vector (31 downto 0)		  -- salida de datos
		  );
end MD_cont;

architecture Behavioral of MD_cont is

component counter is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           count_enable : in  STD_LOGIC;
           load : in  STD_LOGIC;
           D_in  : in  STD_LOGIC_VECTOR (7 downto 0);
		   count : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

-- misma memoria que en el proyecto anterior
component RAM_128_32 is port (
		  CLK : in std_logic;
		  enable: in std_logic; --solo se lee o escribe si enable está activado
		  ADDR : in std_logic_vector (31 downto 0); --Dir 
          Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
          WE : in std_logic;		-- write enable	
		  RE : in std_logic;		-- read enable		  
		  Dout : out std_logic_vector (31 downto 0));
end component;

component reg7 is
    Port ( Din : in  STD_LOGIC_VECTOR (6 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (6 downto 0));
end component;

signal MEM_WE, contar_palabras, resetear_cuenta,MD_enable, memoria_preparada, contar_retardos, direccion_distinta, fin_cuenta, reset_retardo, load_addr, Addr_in_range: std_logic;
signal addr_frame, last_addr:  STD_LOGIC_VECTOR (6 downto 0);
signal cuenta_palabras, cuenta_retardos:  STD_LOGIC_VECTOR (7 downto 0);
signal MD_addr: STD_LOGIC_VECTOR (31 downto 0);
type state_type is (Inicio, Espera, Transferencia, Detectado); 
signal state, next_state : state_type; 
begin
---------------------------------------------------------------------------
-- Decodificador: identifica cuando la dirección pertenece a la MD: (X"00000000"-X"000001FF")
---------------------------------------------------------------------------

Addr_in_range <= '1' when (Bus_AD(31 downto 9) = "00000000000000000000000") AND (Bus_Frame='1') else '0'; 

---------------------------------------------------------------------------
-- HW para introducir retardos:
-- Con un contador y una sencilla máquina de estados introducimos un retardo en la memoria de forma articial. 
-- Cuando se pide una dirección nueva manda la primera palabra en 4 ciclos y el resto cada dos
-- Si se accede dos veces a la misma dirección la segunda vez no hay retardo inicial
---------------------------------------------------------------------------

cont_retardos: counter port map (clk => clk, reset => reset, count_enable => contar_retardos , load=> reset_retardo, D_in => "00000000", count => cuenta_retardos);

-- este registro almacena la ultima dirección accedida. Cada vez que cambia la dirección se resetea el contador de retaros
-- La idea es simular que cuando accedes a una dirección nueva tarda más. Si siempre accedes a la misma no introducirá retardos adicionales
reg_last_addr: reg7 PORT MAP(Din => Bus_AD(8 downto 2), CLK => CLK, reset => reset, load => load_addr, Dout => last_addr);
direccion_distinta <= '0' when (last_addr= Bus_AD(8 downto 2)) else '1';
--introducimos un retardo en la memoria de forma articial. Manda la primera palabra en el cuarto ciclo y el resto cada dos ciclos
-- Pero si los accesos son a direcciones repetidas el retardo inicial desaparece

memoria_preparada <= '0' when (cuenta_retardos < "00000011" or cuenta_retardos(0) = '1') else '1';
---------------------------------------------------------------------------
-- Máquina de estados para introducir retardos
---------------------------------------------------------------------------

SYNC_PROC: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            state <= Inicio;
         else
            state <= next_state;
         end if;        
      end if;
   end process;
   
 --MEALY State-Machine - Outputs based on state and inputs
   OUTPUT_DECODE: process (state, direccion_distinta, Addr_in_range, fin_cuenta, memoria_preparada, Bus_Frame)
   begin
		-- valores por defecto, si no se asigna otro valor en un estado valdrán lo que se asigna aquí
		contar_retardos <= '0';
		reset_retardo <= '0';
		load_addr <= '0';
		next_state <= Inicio;
		MD_Bus_DEVsel <= '0';
		MD_Bus_TRDY <= '0'; 
		MD_send_data <= '0';
		MEM_WE <= '0';
		MD_enable <= '0';
		contar_palabras <= '0';
		-- Estado Inicio: se llega sólo con el reset. Sirve para que al acceder a la dirección 0 tras un reset introduzca los retardos         
      if (state = Inicio and Addr_in_range= '0') then -- si no piden nada no hacemos nada
			next_state <= Inicio;
		elsif 	(state = Inicio and Addr_in_range= '1') then -- Si piden algo tras un reset reseteamos el contador de retardos y vamos a Evianado
			next_state <= Detectado;
			reset_retardo <= '1';
			load_addr <= '1'; --cargamos  la dirección 
		-- Estado Espera   
		elsif (state = Espera and Addr_in_range= '0') then -- si no piden nada no hacemos nada
			next_state <= Espera;
      elsif (state = Espera and Addr_in_range= '1') then -- si detectamos que la dirección nos pertenece vamos al estado de transferencia
         next_state <= Detectado;
         IF (direccion_distinta ='1') then
					reset_retardo <= '1'; -- si se repite la dirección no metemos los retardos iniciales
					load_addr <= '1'; --cargamos  la dirección 
			end if;	
   	    -- Estado Detectado: sirve para informar de que hemos visto que la dirección es nuestra y de que vamos a empezar a leer/escribir datos 
      elsif (state = Detectado and Bus_Frame = '1') then
			next_state <= Transferencia;
			MD_Bus_DEVsel <= '1'; -- avisamos de que hemos visto que la dirección es nuestra
		  -- No empezamos a leer/escribir por si acaso no mandan los datos hasta el ciclo siguiente
		elsif (state = Detectado and Bus_Frame = '0') then 	--Cuando Bus_Frame es 0 es que hemos terminado. No debería pasar porque todavía no hemos hecho nada
			next_state <= Espera;
		  -- Estado Transferencia
		elsif (state = Transferencia and Bus_Frame = '1') then -- si estamos en una transferencia seguimos enviando/recibiendo datos hasta que el master diga que no quiere más
        	next_state <= Transferencia;
			MD_Bus_DEVsel <= '1'; -- avisamos de que hemos visto que la dirección es nuestra
			MD_enable <= '1'; --habilitamos la MD para leer o escribir
         contar_retardos <= '1'; 
			MD_Bus_TRDY <= memoria_preparada;
			contar_palabras <= memoria_preparada; -- cada vez que mandamos una palabra se incrementa el contador
			MEM_WE <= Bus_WE and memoria_preparada; --evitamos escribir varias veces
			MD_send_data <= Bus_RE AND memoria_preparada; -- si la dirección está en rango y es una lectura se carga el dato de MD en el bus
      elsif (state = Transferencia and Bus_Frame = '0') then 	--Cuando Bus_Frame es 0 es que hemos terminado
        	next_state <= Espera;
      end if;	
	end process;

---------------------------------------------------------------------------
-- calculo direcciones 
-- el contador cuenta mientras frame esté activo, la dirección pertenezca a la memoria y la memoria esté preparada para realizar la operación actual. 
---------------------------------------------------------------------------

--Si se desactiva la señal de Frame la cuenta vuelve a 0 al ciclo siguiente. Para que este esquema funcione Frame debe estar un ciclo a 0 entre dos ráfagas. En este sistema esto siempre se cumple.
resetear_cuenta <= '1' when (Bus_Frame='0') else '0';
cont_palabras: counter port map (clk => clk, reset => reset, count_enable => contar_palabras , load=> resetear_cuenta, D_in => "00000000", count => cuenta_palabras);
-- La dirección se calcula sumando la cuenta de palabras a la dirección inicial almacenada en el registro last_addr
addr_Frame <= 	last_addr + cuenta_palabras(6 downto 0);
-- sólo asignamos los bits que se usan. El resto se quedan a 0.
MD_addr(8 downto 2) <= 	addr_Frame; 
MD_addr(1 downto 0) <= "00";
MD_addr(31 downto 9) <= "00000000000000000000000";

---------------------------------------------------------------------------
-- Memoria de datos original 
---------------------------------------------------------------------------


MD: RAM_128_32 PORT MAP (CLK => CLK, enable => MD_enable, ADDR => MD_addr, Din => Bus_AD, WE =>  MEM_WE, RE => Bus_RE, Dout => MD_Dout);


end Behavioral;

