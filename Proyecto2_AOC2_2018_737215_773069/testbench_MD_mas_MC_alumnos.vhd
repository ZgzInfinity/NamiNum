-- TestBench Template

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;


  ENTITY testbench_MD_mas_MC IS
  END testbench_MD_mas_MC;

  ARCHITECTURE behavior OF testbench_MD_mas_MC IS

  -- Component Declaration
  COMPONENT MD_mas_MC is port (
		  CLK : in std_logic;
		  reset: in std_logic; -- s�lo resetea el controlador de DMA
		  ADDR : in std_logic_vector (31 downto 0); --Dir
        Din : in std_logic_vector (31 downto 0);--entrada de datos desde el Mips
        WE : in std_logic;		-- write enable	del MIPS
		  RE : in std_logic;		-- read enable del MIPS
		  Mem_ready: out std_logic; -- indica si podemos hacer la operaci�n solicitada en el ciclo actual
		  Dout : out std_logic_vector (31 downto 0)); --salida que puede leer el MIPS
end COMPONENT;

          SIGNAL clk, reset, RE, WE, Mem_ready :  std_logic;
          signal ADDR, Din, Dout : std_logic_vector (31 downto 0);


  -- Clock period definitions
   constant CLK_period : time := 10 ns;
  BEGIN

  -- Component Instantiation
   uut: MD_mas_MC PORT MAP(clk=> clk, reset => reset, ADDR => ADDR, Din => Din, RE => RE, WE => WE, Mem_ready => Mem_ready, Dout => Dout);

-- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

 stim_proc: process
   begin

    	reset <= '1';
  	    addr <= conv_std_logic_vector(0, 32);--conv_std_logic_vector convierte el primer número (un 0) a un vector de tantos bits como se indiquen (en este caso 32 bits)
  	    Din <= conv_std_logic_vector(255, 32);
  	    RE <= '0';
		WE <= '0';
	  	wait for 20 ns;
	  	reset <= '0';
	  	RE <= '1';
	  	Addr <= conv_std_logic_vector(64, 32); -- Debe ser un fallo de lectura
	  	wait for 1ns;
      if Mem_ready = '0' then
			wait until Mem_ready ='1'; --Este wait espera hasta que se ponga Mem_ready a uno
	  	end if;
		wait for clk_period;
      	Addr <= conv_std_logic_vector(68, 32); --Debe ser un acierto de lectura
	  	wait for 1ns;
      if Mem_ready = '0' then
			wait until Mem_ready ='1';
	  	end if;
		wait for clk_period;
		Addr <= conv_std_logic_vector(72, 32); --Debe ser un acierto de escritura
		RE <= '0';
		WE <= '1';
		-- La idea de estos wait es esperar a que la se�al Mem_ready se active (y si ya est� activa no hacer nada)
		wait for 1ns;
        if Mem_ready = '0' then
			wait until Mem_ready ='1';
	  	end if;
	  	wait for 1ns;
        -- a veces un pulso espureo (en este caso en mem_ready) puede hacer que vuestro banco de pruebas se adelante.
        -- si esperamos un ns desaparecer� el pulso espureo, pero no el real
	  	if Mem_ready = '0' then
			wait until Mem_ready ='1';
	  	end if;
        wait for clk_period;
		-- completar: fallos y aciertos de lectura y escritura, utilizando los cuatro conjuntos y haciendo alg�n reemplazo de bloque sucio y limpio
        WE<='1';
        Din <= conv_std_logic_vector(238,32);
        Addr <= conv_std_logic_vector(0, 32); --Debe dar un fallo de escritura
        wait for 1ns;
        if Mem_ready='0' then
            wait until Mem_ready='1';
        end if;
		wait for clk_period;
        RE<='0';
        WE<='0';
        Din<=conv_std_logic_vector(0,32);
        Addr<=conv_std_logic_vector(0,32);
	  wait;
   end process;


  END;
