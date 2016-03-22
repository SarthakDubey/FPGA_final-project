LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY const_clock IS
	PORT(
			clock_50MHz, reset : IN STD_LOGIC;
			clock 			   : OUT STD_LOGIC);
END const_clock;


ARCHITECTURE behav OF const_clock IS

--initalize counter
--signal counter: integer;
SIGNAL temp_clock: std_logic;

BEGIN
clock<=temp_clock;

PROCESS (clock_50MHz,reset)
	   VARIABLE counter : integer;
	   BEGIN
	   IF (reset = '0') THEN
	     temp_clock<='1';
	     counter:=0;
	     
	    ELSIF (rising_edge(clock_50MHz)) THEN
	     
	     IF(counter>250000) THEN
	         counter := 0;
				temp_clock<=not temp_clock;
	     END IF;
	     
		  counter:=counter+1;
	   END IF;
	   
	   
		END PROCESS;
	
	End behav; 