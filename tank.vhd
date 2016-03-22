library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tank_parameter.all;

ENTITY tank IS 
PORT( 
 	--Inputs 
 	keyboard_clk, keyboard_data, clk 					: IN std_logic; 
 	--Outputs 
   LCD_RS, LCD_E, LCD_ON, RESET_LED, SEC_LED,light		: OUT	STD_LOGIC;
   LCD_RW												: BUFFER STD_LOGIC;
   DATA_BUS											: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
   VGA_RED, VGA_GREEN, VGA_BLUE 						: OUT std_logic_vector(9 downto 0); 
   HORIZ_SYNC, VERT_SYNC, VGA_BLANK, VGA_CLK			: OUT std_logic;
   led_show											: OUT std_logic_vector (55 downto 0)
   ); 
END ENTITY tank; 

ARCHITECTURE structural_combinational OF tank IS 

COMPONENT de2lcd IS
PORT(tie,waiting,game_over,winner,reset, clk_50Mhz		: IN	STD_LOGIC;
	LCD_RS, LCD_E, LCD_ON, RESET_LED, SEC_LED,light		: OUT	STD_LOGIC;
	LCD_RW												: BUFFER STD_LOGIC;
	DATA_BUS											: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT VGA_top_level IS
port(
	CLOCK_50 											: IN std_logic;
	RESET_N												: IN std_logic;
	P1_x,P1_y,P1B_x,P1B_y                           	: IN INTEGER;
	P2_x,P2_y,P2B_x,P2B_y                           	: IN INTEGER;
	game_over,winner,tie                            	: IN std_logic;
			--VGA 
     VGA_RED, VGA_GREEN, VGA_BLUE 						: OUT std_logic_vector(9 DOWNTO 0); 
     HORIZ_SYNC, VERT_SYNC, VGA_BLANK, VGA_CLK			: OUT std_logic
     );
END COMPONENT;

COMPONENT leddcd IS
PORT(
	data_in 	  										: IN std_logic_vector(3 DOWNTO 0);
	segments_out 										: OUT std_logic_vector(6 DOWNTO 0)
	);
END COMPONENT leddcd;	

COMPONENT ps2 IS 
PORT( 
	keyboard_clk, keyboard_data, clock_50MHz,reset 		: in std_logic;--, read : in std_logic;
	scan_code 											: out std_logic_vector( 7 downto 0 );
	scan_readyo 										: out std_logic;
	hist3 												: out std_logic_vector(7 downto 0);
	hist2 												: out std_logic_vector(7 downto 0);
	hist1 												: out std_logic_vector(7 downto 0);
	hist0 												: out std_logic_vector(7 downto 0);
	led_show											: out std_logic_vector(55 downto 0)
	);
END COMPONENT;

COMPONENT const_clock IS
PORT(
	clock_50MHz, reset 									: IN STD_LOGIC;
	clock 			   									: OUT STD_LOGIC
	);
END COMPONENT const_clock;

SIGNAL Tank1_bullet_Coordinate_X 				 		: integer;
SIGNAL Tank1_bullet_Coordinate_Y 	 					: integer;
SIGNAL Tank2_bullet_Coordinate_X 				 		: integer;
SIGNAL Tank2_bullet_Coordinate_Y 						: integer;
SIGNAL P1_x  											: integer;
SIGNAL P1_y  											: integer;
SIGNAL P2_x  											: integer;
SIGNAL P2_y  											: integer;
SIGNAL P1_speed  			     						: integer;
SIGNAL P2_speed       									: integer;
SIGNAL c_clock    										: std_logic;
SIGNAL scan_readyo    									: std_logic;
SIGNAL winner         									: std_logic;
SIGNAL game_over    			  						: std_logic;
SIGNAL done           									: std_logic;
SIGNAL activate 	  									: std_logic;
SIGNAL reset, tie	  									: std_logic;
SIGNAL Tank1_shoots, Tank1_make 						: std_logic;
SIGNAL Tank2_shoots,Tank2_make 				 			: std_logic;
SIGNAL Tank1_bullet, Tank2_hit 							: std_logic;
SIGNAL Tank2_bullet, Tank1_hit 							: std_logic;
SIGNAL init,a,b,c,d,waiting,res_lcd 					: std_logic;
SIGNAL Tank1_reverse,Tank2_reverse 						: std_logic;
SIGNAL go 												: std_logic;
SIGNAL LEDs			  									: std_logic_vector(55 downto 0);
SIGNAL temp_1 		  									: std_logic_vector(5 downto 0);
SIGNAL hist3, hist2, hist1, hist0 						: std_logic_vector(7 downto 0);
SIGNAL P1score		  									: std_logic_vector(3 downto 0);
SIGNAL P2score		  									: std_logic_vector(3 downto 0);
SIGNAL scan_code      									: std_logic_vector(7 downto 0);

BEGIN 

LCD 		: de2lcd PORT MAP (tie,waiting,game_over,winner,res_lcd,clk,LCD_RS,LCD_E, LCD_ON, RESET_LED, SEC_LED,light,LCD_RW,DATA_BUS);

keyboard_0 	: ps2 PORT MAP (keyboard_clk, keyboard_data, clk, '1', scan_code, scan_readyo, hist3, hist2, hist1, hist0, LEDs);

vga_0 		: VGA_top_level PORT MAP (clk, reset,P1_x, P1_y, Tank1_bullet_Coordinate_X, Tank1_bullet_Coordinate_Y, P2_x, P2_y, Tank2_bullet_Coordinate_X, Tank2_bullet_Coordinate_Y,  game_over, winner, tie, VGA_RED, VGA_GREEN, VGA_BLUE, HORIZ_SYNC, VERT_SYNC, VGA_BLANK, VGA_CLK);

clock_map	: const_clock PORT MAP(clock_50MHz=> clk, reset=>init, clock=>c_clock);

conv0 		: leddcd PORT MAP (P1score,led_show(48 downto 42));
conv1 		: leddcd PORT MAP (P2score,led_show(34 downto 28));
conv2 		: leddcd PORT MAP ("0000",led_show(55 downto 49));
conv3 		: leddcd PORT MAP ("0000",led_show(41 downto 35));

led_show(27 downto 0) <= LEDs(27 downto 0);

--Starting the game process, following are the different section of VHDL code that handle different elements of the game--------

game: process(reset,c_clock,done) is
variable Tank1_dir : std_logic;
variable Tank2_dir : std_logic;
variable Tank1_position_X_Coordinate : integer;
variable Tank1_position_Y_Coordinate : integer;
variable Tank2_position_X_Coordinate : integer;
variable Tank2_position_Y_Coordinate : integer;
variable P1score_int : integer;
variable P2score_int : integer;
begin

done <= '0';

if (init='0') then

done 		<= '1';
P2score 	<= "0000";
P1score 	<= "0000";
Tank1_hit 	<= '0';
P1score_int := 0;
P2score_int := 0;
Tank2_hit 	<= '0';
Tank2_make	<='0';
Tank1_make	<='0';
winner 		<= '0';
game_over 	<= '0';
tie 		<= '0';
Tank1_dir   := '1';
Tank2_dir  	:= '0';

--Initializing the Tank Position according to the 320X480 display size.-------------------------------------------------
Tank1_position_X_Coordinate  := 320-T_SIZE/2;     	   		Tank2_position_X_Coordinate := 320-T_SIZE/2;  
Tank1_position_Y_Coordinate  := 480-T_SIZE;            		Tank2_position_Y_Coordinate := 0;
Tank1_bullet 				 <= '0';           				Tank2_bullet 				<= '0';
Tank1_bullet_Coordinate_X    <= 318;              			Tank2_bullet_Coordinate_X   <= 318;
Tank1_bullet_Coordinate_Y    <= 480-T_SIZE-C_LENGTH+5;   	Tank2_bullet_Coordinate_Y   <= T_SIZE+C_LENGTH-5;


    --Control Tank 1--    
    elsif (rising_edge(c_clock)) then
	 --Tank1_position_X_Coordinate := P1_x;
	 --T1_pox_y := P1_y;
	 a	<='0';
	 b 	<='0';
	 c  	<='0';
	 d  	<='0';
	 if (Tank1_reverse='1') then
			a<='1';--done <= '1';
			Tank1_dir := not Tank1_dir;
			end if;


			if (Tank2_reverse='1') then
			b<='1';
			Tank2_dir := not Tank2_dir;
			end if;

		if (Tank1_dir='1') then  --right
        if (Tank1_position_X_Coordinate > 639-T_SIZE-P1_speed) then --if going to go past end of screen, invert direction
        Tank1_dir := '0';
        Tank1_position_X_Coordinate := 639-T_SIZE;
        else
        Tank1_position_X_Coordinate  := Tank1_position_X_Coordinate + P1_speed;
        Tank1_dir := '1';
        end if;
        
      else --going left
        if (Tank1_position_X_Coordinate < P1_speed) then --if going to go past end of screen, invert direction
        Tank1_dir := '1';
        Tank1_position_X_Coordinate := 0;
        else
        Tank1_position_X_Coordinate  := Tank1_position_X_Coordinate - P1_speed;
        Tank1_dir := '0';
        end if;
        end if;

    --Control Tank 2--


	 if (Tank2_dir='1') then  --right
        if (Tank2_position_X_Coordinate > 639-T_SIZE-P2_speed) then --if going to go past end of screen, invert direction
        Tank2_dir := '0';
        Tank2_position_X_Coordinate := 639-T_SIZE;
        else
        Tank2_position_X_Coordinate  := Tank2_position_X_Coordinate + P2_speed;
        Tank2_dir := '1';
        end if;
        
      else --going left
        if (Tank2_position_X_Coordinate < P2_speed) then --if going to go past end of screen, invert direction
        Tank2_dir := '1';
        Tank2_position_X_Coordinate := 0;
        else
        Tank2_position_X_Coordinate  := Tank2_position_X_Coordinate - P2_speed;
        Tank2_dir := '0';
        end if;
        end if;

    --Control Tank 1 Bullet--     

      if(Tank1_bullet = '1') then  -- if the bullet exists
      if((Tank1_bullet_Coordinate_Y<BULLET_TRAVEL) or (Tank2_hit='1')) then
      Tank1_bullet <= '0';
      Tank2_hit <= '0';
          Tank1_bullet_Coordinate_X <= Tank1_position_X_Coordinate+T_SIZE/2-3;   --re-hide/delete bullet
          Tank1_bullet_Coordinate_Y <= 480-T_SIZE-C_LENGTH+5;
          d <= '1';
          else
          Tank1_bullet_Coordinate_Y <= Tank1_bullet_Coordinate_Y - BULLET_TRAVEL;
          d<= '1';
          end if; 
      elsif(Tank1_shoots = '0' and Tank1_bullet = '0') then -- if no command to shoot & bullet does not exist, do not show bullet
        Tank1_bullet_Coordinate_X <= Tank1_position_X_Coordinate+T_SIZE/2-3; ---might need to get updated to get new position
        end if;

      if (Tank1_shoots = '1' and Tank1_bullet='0') then  -- if the bullet does not exist & there's a command to shoot
      Tank1_bullet <= '1';
      Tank1_make<='1';
      d <= '1';
      Tank1_bullet_Coordinate_X <= Tank1_position_X_Coordinate+T_SIZE/2-3;
      Tank1_bullet_Coordinate_Y <= Tank1_bullet_Coordinate_Y - BULLET_TRAVEL;
      end if;
      
    --Control Tank 2 Bullet--  

      if(Tank2_bullet = '1') then  -- if the bullet exists
      if((Tank2_bullet_Coordinate_Y>479-BULLET_TRAVEL) or (Tank1_hit='1')) then
      Tank2_bullet <= '0';
          Tank2_bullet_Coordinate_X <= Tank2_position_X_Coordinate+T_SIZE/2-3;   --Do not display bullet
          Tank2_bullet_Coordinate_Y <= T_SIZE+C_LENGTH-5;
          Tank1_hit <= '0';
          c <= '1';
          else
          Tank2_bullet_Coordinate_Y <= Tank2_bullet_Coordinate_Y + BULLET_TRAVEL;
          c <= '1';
          end if; 
      elsif(Tank2_shoots = '0' and Tank2_bullet = '0') then --  if no command to shoot & bullet does not exist, hide bullet in tank
        Tank2_bullet_Coordinate_X <= Tank2_position_X_Coordinate+T_SIZE/2-3; ---might need to get updated to get new position
        end if;

      if (Tank2_shoots = '1' and Tank2_bullet='0') then    --  if the bullet does not exist & there's a command to shoot
      c <= '1';
      Tank2_bullet <= '1';
      Tank2_make <= '1';
      Tank2_bullet_Coordinate_X <= Tank2_position_X_Coordinate+T_SIZE/2-3;
      Tank2_bullet_Coordinate_Y <= Tank2_bullet_Coordinate_Y + BULLET_TRAVEL;
      end if;

    --Tank Explosion Test--
    
      if((game_over='0') and (Tank2_make='1') and (Tank2_bullet_Coordinate_X >= Tank1_position_X_Coordinate) and (Tank2_bullet_Coordinate_X < Tank1_position_X_Coordinate+T_size)) then   --if in x-range
      if ((Tank2_bullet_Coordinate_Y >= Tank1_position_Y_Coordinate) and (Tank2_bullet_Coordinate_Y < Tank1_position_Y_Coordinate+T_size)) then
      Tank2_make<='0';
      P2score_int := P2score_int + 1;
      P2score <= std_logic_vector(to_signed(P2score_int,4));
      Tank1_hit <= '1';
      end if;
      end if;

      if((game_over='0') and (Tank1_make='1') and (Tank1_bullet_Coordinate_X >= Tank2_position_X_Coordinate) and (Tank1_bullet_Coordinate_X < Tank2_position_X_Coordinate+T_size)) then   --if in x-range
      if ((Tank1_bullet_Coordinate_Y >= Tank2_position_Y_Coordinate) and (Tank1_bullet_Coordinate_Y < Tank2_position_Y_Coordinate+T_size)) then
      Tank1_make <= '0';
      P1score_int := P1score_int + 1;
      P1score <= std_logic_vector(to_signed(P1score_int,4));
      Tank2_hit<='1';
      end if;
      end if;  

      if (P1score_int = 3) then
      game_over <= '1';
      winner    <= '0';
      end if;	

      if (P2score_int = 3) then
      game_over <= '1';
      winner    <= '1';
      end if;

	  if ((P2score_int = 3) and (P1score_int = 3)) then  --in the very rare case that it happens to be a tie.
	  tie <= '1';
	  end if;

  end if; -- end rising edge
	--put variables in signals
	P1_x <= Tank1_position_X_Coordinate;
	P1_y <= Tank1_position_Y_Coordinate;
	P2_x <= Tank2_position_X_Coordinate;
	P2_y <= Tank2_position_Y_Coordinate;
-------    
end process game;

-- Start the process to take input from the keyboard ---------------------------------------------------------------

key_press : process(hist0,clk,done,hist1) is --determine if there is keypress and what should happen

begin
if (rising_edge(clk)) then
res_lcd <= '1';
init 	<= '1';
waiting <= '0';

if (hist1=X"00") then
P1_speed 		<= 2;
P2_speed 		<= 2;
init 			<= '0';
waiting  		<= '1';
Tank2_shoots 	<= '0';
Tank1_shoots 	<= '0';
end if;

if (hist1/=X"F0") then
go <= '1';

elsif (hist1=X"F0" and go='1') then
go <= '0';
CASE hist0 IS

			WHEN X"16" =>					--P1 low speed (key 1)
			P1_speed <= 2;
			WHEN X"1E" =>					--P1 middle speed (key 2)
			P1_speed <= 3;
			WHEN X"26" =>					--P1 top speed (key 3)
			P1_speed <= 4;
			WHEN X"0D" =>					--P1 reverse (tab)
			Tank1_reverse <= '1';
			WHEN X"69" =>					--P2 low speed (Numpad 1)
			P2_speed <= 2;
			WHEN X"72" =>					--P2 middle speed (Numpad 2)
			P2_speed <= 3;
			WHEN X"7A" =>					--P2 top speed (Numpad 3)
			P2_speed <= 4;
			WHEN X"49" =>					--P2 reverses (Numpad .)
			Tank2_reverse <= '1';
			WHEN X"29" =>  				--P1 shoots (space)
			Tank1_shoots <= '1';
			WHEN X"70" =>  				--P2 shoots (Numpad 0)
			Tank2_shoots <= '1';
			WHEN X"66" => 					--reset button (backspace)
			init <= '0';
			res_lcd <= '0';
			P1_speed <= 2;
			P2_speed <= 2;
			WHEN others =>
			null;
			end CASE;


			end if;

			if (done='1') then
			init <= '1';
			Tank1_reverse <= '0';
			end if;

	if (a='1') then			--Tank1_reverse acknowledged?
	Tank1_reverse <= '0';
	end if;
	
	if (b='1') then			--Tank2_reverse acknowledged?
	Tank2_reverse <= '0';
	end if;
	
	if (c='1') then			--T2 shot acknowledged?
	Tank2_shoots <= '0';
	end if;
	
	if (d='1') then			--T1 shot acknowledged?
	Tank1_shoots <= '0';
	end if;
	end if;
	end process key_press;

	end architecture structural_combinational;