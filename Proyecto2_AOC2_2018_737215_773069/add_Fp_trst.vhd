-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  ENTITY testfp IS
  END testfp;

  ARCHITECTURE behavior OF testfp IS 

  component FPP_ADD_SUB is
  port(A      : in  std_logic_vector(31 downto 0);
       B      : in  std_logic_vector(31 downto 0);
       clk    : in  std_logic;
       reset  : in  std_logic;
       go     : in  std_logic;
       done   : out std_logic;
       result : out std_logic_vector(31 downto 0)
       );
end component;
  -- Clock period definitions
   constant CLK_period : time := 10 ns;
  signal A,B,result: STD_LOGIC_VECTOR (31 downto 0);
  signal clk,go, done, reset : std_logic;
  BEGIN

  addfp: FPP_ADD_SUB port map (a,b,clk,reset, go, done, result);

-- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process; 

 --  Test Bench Statements
     tb : PROCESS
     BEGIN
		   reset <= '1';
			go <= '0';	
			A <= x"3e4ccccd";-- 3e4ccccd = 0,2
			B <= x"3e4ccccd";			
         wait for CLK_period*10; -- wait until global set/reset completes
			reset <= '0';
			go <= '1';
			wait until (done'event and done='1'); -- wai
			B(31) <= '1';
		  wait until (done'event and done='1'); -- wai
        -- Add user defined stimulus here
        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;
