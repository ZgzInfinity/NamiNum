----------------------------------------------------------------------------------
--------------------------------------------------------
-- Johns Hopkins University - FPGA Senior Projects, R.E.Jenkins
--Floating point vhdl Package - Ryan Fay, Alex Hsieh, David Jeang
--This file contains the components and functions used for Floating point arithmetic
---------
--Copywrite Johns Hopkins University ECE department. This software may be freely
-- used and modified as long as this acknowledgement is retained.
--------------------------------------------------------
--
----------------------------------------------------------------------------------
---===============================================================
--Module for a signed floating point add - David Jeang. Thanks to Prof. Jenkins
--We presume an ADD request starts the process, and a completion signal is generated.
--Subtraction is accomplished by negating the B input, before requesting the add.
--The add can easily exceed 15 clocks, depending on the exponent difference
--   and post-normalization.

-- Modificación: la salida sólo permanece un ciclo y el sumador se resetea
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity FPP_ADD_SUB is
  port(A      : in  std_logic_vector(31 downto 0);
       B      : in  std_logic_vector(31 downto 0);
       clk    : in  std_logic;
       reset  : in  std_logic;
       go     : in  std_logic;
       done   : out std_logic;
       result : out std_logic_vector(31 downto 0)
       );
end FPP_ADD_SUB;

architecture Arch of FPP_ADD_SUB is
  type SMC is (WAITC, ALIGN, ADDC, NORMC, PAUSEC);
  signal ADD_SUB            : SMC;
  attribute INIT            : string;
  attribute INIT of ADD_SUB : signal is "WAITC";  --we  powerup in WAITC state

---signals latched from inputs
  signal A_mantissa, B_mantissa : std_logic_vector (24 downto 0);
  signal A_exp, B_exp           : std_logic_vector (8 downto 0);
  signal A_sgn, B_sgn           : std_logic;
--output signals
  signal sum                    : std_logic_vector (31 downto 0);
  signal finished					  : std_logic;
--signal F_exp: std_logic_vector (7 downto 0);
  signal mantissa_sum           : std_logic_vector (24 downto 0);

begin
  done <= finished;
  result <= sum;                        --sum is built in the state machine
--State machine to wait for request, latch inputs, align exponents, perform add, normalize result
  SM : process (clk, reset, ADD_SUB, go) is
    variable diff : signed(8 downto 0);
--variable j: integer range 0 to 31;
  begin
  
	if rising_edge(clk) then
		if(reset = '1') or (finished= '1') then
			ADD_SUB <= WAITC;                 --start in wait state
			finished    <= '0';
		else
			case ADD_SUB is
			  when WAITC =>
				 if (go = '1') then            --wait till start request goes high
					A_sgn      <= A(31);
					B_sgn      <= B(31);
					A_exp      <= '0' & A(30 downto 23);
					B_exp      <= '0' & B(30 downto 23);
					A_mantissa <= "01" & A(22 downto 0);
					B_mantissa <= "01" & B(22 downto 0);
					ADD_SUB    <= ALIGN;
				 else
					ADD_SUB <= WAITC;           --not needed, but clearer
				 end if;
			  when ALIGN =>  --exponent alignment. Always makes A_exp be final exponent
				 --Below method is like a barrel shift, but is big space hog------
				 --note that if either num is greater by 2**24, we skip the addition.
				 if unsigned(A_exp) = unsigned(B_exp) then
					ADD_SUB <= ADDC;
				 elsif unsigned(A_exp) > unsigned(B_exp) then
					diff := signed(A_exp) - signed(B_exp);  --B needs downshifting
					if diff > 23 then
					  mantissa_sum <= A_mantissa;  --B insignificant relative to A
					  sum(31)      <= A_sgn;
					  ADD_SUB      <= PAUSEC;   --go latch A as output
					else       --downshift B to equilabrate B_exp to A_exp
					  B_mantissa(24-TO_INTEGER(diff) downto 0)  <= B_mantissa(24 downto TO_INTEGER(diff));
					  B_mantissa(24 downto 25-TO_INTEGER(diff)) <= (others => '0');
					  ADD_SUB                                   <= ADDC;
					end if;
				 else                          --A_exp < B_exp. A needs downshifting
					diff := signed(B_exp) - signed(A_exp);
					if diff > 23 then
					  mantissa_sum <= B_mantissa;  --A insignificant relative to B
					  sum(31)      <= B_sgn;
					  A_exp        <= B_exp;  --this is just a hack since A_exp is used for final result
					  ADD_SUB      <= PAUSEC;   --go latch B as output
					else       --downshift A to equilabrate A_exp to B_exp
					  A_exp                                     <= B_exp;
					  A_mantissa(24-TO_INTEGER(diff) downto 0)  <= A_mantissa(24 downto TO_INTEGER(diff));
					  A_mantissa(24 downto 25-TO_INTEGER(diff)) <= (others => '0');
					  ADD_SUB                                   <= ADDC;
					end if;
				 end if;
			  ---------------------------------------
			  --This way iterates the alignment shifts, but is way too slow
			  -- If either num is greater by 2**23, we just skip the addition.
	--                              if (signed(A_exp) - signed(B_exp))> 23 then
	--                                      mantissa_sum <= std_logic_vector(unsigned(A_mantissa));
	--                                      sum(31) <= A_sgn;
	--                                      ADD_SUB <= PAUSEC;  --go latch A as output
	--                              elsif (signed(B_exp) - signed(A_exp))> 23 then
	--                                      mantissa_sum <= std_logic_vector(unsigned(B_mantissa));
	--                                      sum(31) <= B_sgn;
	--                                      A_exp <= B_exp;
	--                                      ADD_SUB <= PAUSEC;  --go latch B as output.
	--                              --otherwise we normalize the smaller exponent to the larger.
	--                              elsif(unsigned(A_exp) < unsigned(B_exp)) then
	--                                      A_mantissa <= '0' & A_mantissa(24 downto 1);
	--                                      A_exp <= std_logic_vector((unsigned(A_exp)+1));
	--                              elsif (unsigned(B_exp) < unsigned(A_exp)) then
	--                                      B_mantissa <= '0' & B_mantissa(24 downto 1);
	--                                      B_exp <= std_logic_vector((unsigned(B_exp)+1));
	--                              else
	--                                      --either way, A_exp is the final equilabrated exponent
	--                                      ADD_SUB <= ADDC;
	--                              end if;
			  -----------------------------------------
			  when ADDC =>                    --Mantissa addition
				 ADD_SUB <= NORMC;
				 if (A_sgn xor B_sgn) = '0' then  --signs are the same. Just add 'em
					mantissa_sum <= std_logic_vector((unsigned(A_mantissa) + unsigned(B_mantissa)));
					sum(31)      <= A_sgn;      --both nums have same sign
				 --otherwise subtract smaller from larger and use sign of larger
				 elsif unsigned(A_mantissa) >= unsigned(B_mantissa) then
					mantissa_sum <= std_logic_vector((unsigned(A_mantissa) - unsigned(B_mantissa)));
					sum(31)      <= A_sgn;
				 else
					mantissa_sum <= std_logic_vector((unsigned(B_mantissa) - unsigned(A_mantissa)));
					sum(31)      <= B_sgn;
				 end if;

			  when NORMC =>  --post normalization. A_exp is the exponent of the unormalized sum
				 if unsigned(mantissa_sum) = TO_UNSIGNED(0, 25) then
					mantissa_sum <= (others => '0');  --break out if a mantissa of 0
					A_exp        <= (others => '0');
					ADD_SUB      <= PAUSEC;     --
				 elsif(mantissa_sum(24) = '1') then  --if sum overflowed we downshift and are done.
					mantissa_sum <= '0' & mantissa_sum(24 downto 1);  --shift the 1 down
					A_exp        <= std_logic_vector((unsigned(A_exp)+ 1));
					ADD_SUB      <= PAUSEC;
				 elsif(mantissa_sum(23) = '0') then  --in this case we need to upshift
					--Below takes big resources to determine the normalization upshift, 
					--  but does it one step.
					for i in 22 downto 1 loop   --find position of the leading 1
					  if mantissa_sum(i) = '1' then
						 mantissa_sum(24 downto 23-i) <= mantissa_sum(i+1 downto 0);
						 mantissa_sum(22-i downto 0)  <= (others => '0');  --size of shift= 23-i
						 A_exp                        <= std_logic_vector(unsigned(A_exp)- 23 + i);
						 exit;
					  end if;
					end loop;
					ADD_SUB <= PAUSEC;          --go latch output, wait for acknowledge
														 ------------------------------
				 --This iterates the normalization shifts, thus can take many clocks.
				 --mantissa_sum <= mantissa_sum(23 downto 0) & '0';
				 --A_exp <= std_logic_vector((unsigned(A_exp)-1));
				 --ADD_SUB<= NORMC; --keep shifting till  leading 1 appears
				 ------------------------------
				 else
					ADD_SUB <= PAUSEC;  --leading 1 already there. Latch output, wait for acknowledge
				 end if;
			  when PAUSEC =>
				 sum(22 downto 0)  <= mantissa_sum(22 downto 0);
				 sum(30 downto 23) <= A_exp(7 downto 0);
				 finished              <= '1';     -- signal finished
				 if (go = '0') then            --pause till request ends
					finished    <= '0';
					ADD_SUB <= WAITC;
				 end if;
			  when others => ADD_SUB <= WAITC;      --Just in case.
			end case;
		end if;
    end if;
  end process SM;

end Arch;