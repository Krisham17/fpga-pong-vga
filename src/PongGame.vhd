----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 14:27:43 11/07/2024
-- Design Name:
-- Module Name: PongGame - Behavioral
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY PongGame IS
	PORT (
		CLK : IN STD_LOGIC;
		SW0 : IN STD_logic;
		SW1 : IN STD_logic;
		SW2 : IN std_logic;
		SW3 : IN std_logic;
		HSYNC : OUT STD_LOGIC;
		VSYNC : OUT STD_LOGIC;
		DAC_CLK : OUT STD_LOGIC;
		Bout : OUT STD_logic_vector(7 DOWNTO 0);
		Gout : OUT STD_logic_vector(7 DOWNTO 0);
		Rout : OUT STD_logic_vector(7 DOWNTO 0)
	);
END PongGame;

ARCHITECTURE Behavioral OF PongGame IS

	SIGNAL clk25 : std_logic := '0';
	CONSTANT HD : INTEGER := 640; -- 640 Horizontal Display (640)
	CONSTANT HFP : INTEGER := 16; -- 16 Right border (front porch)
	CONSTANT HSP : INTEGER := 96; -- 96 Sync pulse (Retrace)
	CONSTANT HBP : INTEGER := 48; -- 48 Left boarder (back porch)
	CONSTANT VD : INTEGER := 480; -- 480 Vertical Display (480)
	CONSTANT VFP : INTEGER := 10; -- 10 Right border (front porch)
	CONSTANT VSP : INTEGER := 2; -- 2 Sync pulse (Retrace)
	CONSTANT VBP : INTEGER := 33; -- 33 Left boarder (back porch)
	SIGNAL hPos : INTEGER := 0;
	SIGNAL vPos : INTEGER := 0;
	SIGNAL ball_pos_h1 : INTEGER := 320;
	SIGNAL ball_pos_v1 : INTEGER := 240;
	SIGNAL paddle1_pos_h1 : INTEGER := 20;
	SIGNAL paddle1_pos_v1 : INTEGER := 300;
	SIGNAL paddle1_pos_length_h : INTEGER := 10;
	SIGNAL paddle1_pos_length_v : INTEGER := 100;
	SIGNAL paddle2_pos_h1 : INTEGER := 610;
	SIGNAL paddle2_pos_v1 : INTEGER := 300;
	SIGNAL paddle2_pos_length_h : INTEGER := 10;
	SIGNAL paddle2_pos_length_v : INTEGER := 100;
	SIGNAL newframe : std_logic := '0';
	SIGNAL ballcolor : std_logic := '0';
	SIGNAL ball_speed_h : INTEGER RANGE - 3 TO 3 := 2;
	SIGNAL ball_speed_v : INTEGER RANGE - 3 TO 3 := 2;
	CONSTANT ballsize : INTEGER := 8;
	CONSTANT topborder : INTEGER := 0;
	CONSTANT topborderlength : INTEGER := 20;
	CONSTANT botborder : INTEGER := 479;
	CONSTANT botborderlength : INTEGER := 20;
	CONSTANT leftborder : INTEGER := 0;
	CONSTANT leftborderlength : INTEGER := 20;
	CONSTANT rightborder : INTEGER := 639;
	CONSTANT rightborderlength : INTEGER := 20;
	CONSTANT hole_left_v1 : INTEGER := 120;
	CONSTANT hole_left_length : INTEGER := 250;
	CONSTANT hole_right_v1 : INTEGER := 120;
	CONSTANT hole_right_length : INTEGER := 250;
	CONSTANT strip : INTEGER := 320;
	SIGNAL videoOn : std_logic := '0';
	
	 SIGNAL player1_direction : INTEGER := 1; -- 1 for down, -1 for up
    SIGNAL player2_direction : INTEGER := 1; -- 1 for down, -1 for up 
    SIGNAL player2_AI : BOOLEAN := TRUE; 
	 
	 signal CONTROL0 : STD_LOGIC_VECTOR(35 downto 0);
	 
	 signal ila_clk : std_logic;
	 signal ila_data : std_logic_vector(1 downto 0);
	 signal trig0 	: STD_LOGIC_VECTOR(0 TO 0);
	 
	 signal hsync_in :std_logic;
	 signal vsync_in :std_logic;
	 


	component icon
		PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

	end component;
	
	component ila_pong
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0));

end component;

BEGIN
sys_icon : icon
  port map (
    CONTROL0 => CONTROL0);
	 
sys_ila : ila_pong
  port map (
    CONTROL => CONTROL0,
    CLK => clk25,
    DATA => ila_data,
    TRIG0 => TRIG0);
	 
	 HSYNC <= hsync_in;
	 VSYNC <= vsync_in;
	 
	 ila_data(0) <= hsync_in;
	 ila_data(1) <= vsync_in;
	 

	 
	clk_div : PROCESS (CLK)
	BEGIN
		IF (CLK'EVENT AND CLK = '1') THEN
			clk25 <= NOT clk25;
		END IF;
	END PROCESS;
	h_pos_counter : PROCESS (clk25)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1') THEN
			IF (hPos = (HD + HFP + HSP + HBP)) THEN
				newframe <= '0';
				hPos <= 0;
				IF (vPos = (VD + VFP + VSP + VBP)) THEN
					newframe <= '1';
 
				END IF;
			ELSE
				newframe <= '0';
				hPos <= hPos + 1;
 
			END IF;
		END IF;
	END PROCESS;
	v_pos_counter : PROCESS (clk25, hPos)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1') THEN
			IF (hPos = (HD + HFP + HSP + HBP)) THEN
				IF (vPos = (VD + VFP + VSP + VBP)) THEN
 
					vPos <= 0;
				ELSE
 
					vPos <= vPos + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	Horizontal_Synchronisation : PROCESS (clk25, hPos)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1') THEN
			IF ((hPos <= (HD + HFP)) OR (hPos > HD + HFP + HSP)) THEN
 
				hsync_in <= '1';
 
			ELSE

				hsync_in <= '0';
 
			END IF;
		END IF;
	END PROCESS;
	Vertical_Synchronisation : PROCESS (clk25, vPos)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1') THEN
			IF ((vPos <= (VD + VFP)) OR (vPos > VD + VFP + VSP)) THEN

				vsync_in <= '1';
 
			ELSE
 
				vsync_in <= '0';
 
			END IF;
		END IF;
	END PROCESS;
	video_on : PROCESS (clk25, hPos, vPos)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1') THEN
			IF (hPos <= HD AND vPos <= VD) THEN
 
				videoOn <= '1';

			ELSE

				videoOn <= '0';

			END IF;
		END IF;
	END PROCESS;
	ball_move : PROCESS (clk25, newframe)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1' AND newframe = '1') THEN
 
			ballcolor <= '0';

			IF (ball_pos_v1 < topborder + topborderlength) THEN

				ball_speed_v <= ABS (ball_speed_v);

			END IF;

			IF (ball_pos_v1 + ballsize > botborder - botborderlength) THEN

				ball_speed_v <= ( - 1) * ABS(ball_speed_v);

			END IF;

			IF (ball_pos_h1 < leftborder + leftborderlength) THEN

				ball_speed_h <= ABS (ball_speed_h);

			END IF;

			IF (ball_pos_h1 + ballsize > rightborder - rightborderlength) THEN

				ball_speed_h <= ( - 1) * ABS(ball_speed_h);

			END IF;

			IF (ball_pos_h1 > paddle1_pos_h1 AND ball_pos_h1 < paddle1_pos_h1 + paddle1_pos_length_h) AND (ball_pos_v1 > paddle1_pos_v1 AND ball_pos_v1 < paddle1_pos_v1 + paddle1_pos_length_v) THEN

				ball_speed_h <= ABS(ball_speed_h);

			END IF;
 
			IF (ball_pos_h1 + ballsize > paddle2_pos_h1 AND ball_pos_h1 + ballsize < paddle2_pos_h1 + paddle2_pos_length_h) AND (ball_pos_v1 + ballsize > paddle2_pos_v1 AND ball_pos_v1 < paddle2_pos_v1 + paddle2_pos_length_v) THEN
 
				ball_speed_h <= ( - 1) * ABS(ball_speed_h);
 
			END IF;
 
			ball_pos_h1 <= ball_pos_h1 + ball_speed_h;
			ball_pos_v1 <= ball_pos_v1 + ball_speed_v;
 
			IF (ball_pos_h1 < leftborder + leftborderlength AND (ball_pos_v1 > hole_left_v1 AND ball_pos_v1 < hole_left_v1 + hole_left_length)) THEN

				ball_pos_h1 <= 320;
				ball_pos_v1 <= 240;
 
			END IF;
 
			IF (ball_pos_h1 + ballsize > rightborder - rightborderlength AND (ball_pos_v1 > hole_right_v1 AND ball_pos_v1 < hole_right_v1 + hole_right_length)) THEN
 
				ball_pos_h1 <= 320;
				ball_pos_v1 <= 240;
 
			END IF;
 
			IF (ball_pos_h1 < leftborder + leftborderlength + 1 AND (ball_pos_v1 > hole_left_v1 AND ball_pos_v1 < hole_left_v1 + hole_left_length)) THEN

				ballcolor <= '1';

			END IF;

			IF (ball_pos_h1 + ballsize > rightborder - rightborderlength - 1 AND(ball_pos_v1 > hole_right_v1 AND ball_pos_v1 < hole_right_v1 + hole_right_length)) THEN
 
				ballcolor <= '1';
 
			END IF;
 
		END IF;
	END PROCESS;
	paddle_move : PROCESS (clk25, newframe)
	BEGIN
		IF (clk25'EVENT AND clk25 = '1' AND newframe = '1') THEN
			--player 1 paddle move

			IF (SW0 = '1' AND paddle1_pos_v1 > topborder + topborderlength) THEN
				paddle1_pos_v1 <= paddle1_pos_v1 - 2;
			END IF;
 
			IF (SW1 = '1' AND paddle1_pos_v1 + paddle1_pos_length_v < 
			 botborder - botborderlength) THEN
				paddle1_pos_v1 <= paddle1_pos_v1 + 2;
			END IF;

			--player 2 paddle move
			IF (SW2 = '1' AND paddle2_pos_v1 > topborder + topborderlength) THEN
				paddle2_pos_v1 <= paddle2_pos_v1 - 2;
			END IF;
			IF (SW3 = '1' AND paddle2_pos_v1 + paddle2_pos_length_v < 
				 botborder - botborderlength) THEN
					paddle2_pos_v1 <= paddle2_pos_v1 + 2;
				END IF;
			END IF;
			END PROCESS;
			draw : PROCESS (clk25, hPos, vPos, videoOn)
			BEGIN
				IF (clk25'EVENT AND clk25 = '1') THEN
					IF (videoOn = '1') THEN
						IF (vpos < topborder + topborderlength OR vpos > 
						 botborder - botborderlength) THEN
							Rout <= "11111111";
							Gout <= "11111111";
							Bout <= "11111111";
						ELSIF (hpos < leftborder + leftborderlength AND (vpos > hole_left_v1 AND vpos < hole_left_v1 + hole_left_length)) THEN
							Rout <= "00000000";
							Gout <= "11111111";
							Bout <= "00000000";
						ELSIF (hpos > rightborder - rightborderlength AND (vpos > hole_right_v1 AND
							vpos < hole_right_v1 + hole_right_length)) THEN
							Rout <= "00000000";
							Gout <= "11111111";
							Bout <= "00000000";
						ELSIF (hpos < leftborder + leftborderlength OR hpos > 
							rightborder - rightborderlength) THEN
							Rout <= "11111111";
							Gout <= "11111111";
							Bout <= "11111111";
						ELSIF ((hpos > paddle1_pos_h1 AND hpos < paddle1_pos_h1 + 
							paddle1_pos_length_h) AND (vpos > paddle1_pos_v1 AND vpos < paddle1_pos_v1 + 
							paddle1_pos_length_v)) THEN
							Rout <= "00000000";
							Gout <= "00000000";
							Bout <= "11111111";
						ELSIF ((hpos > paddle2_pos_h1 AND hpos < paddle2_pos_h1 + 
							paddle2_pos_length_h) AND (vpos > paddle2_pos_v1 AND vpos < paddle2_pos_v1 + 
							paddle2_pos_length_v)) THEN
							Rout <= "11111111";
							Gout <= "00000000";
							Bout <= "11111111";
						ELSIF ((hpos >= ball_pos_h1 AND hpos < ball_pos_h1 + ballsize) AND
							(vpos >= ball_pos_v1 AND vpos < ball_pos_v1 + ballsize)) THEN
							IF (ballcolor = '0') THEN --Yellow
								Rout <= "11111111";
								Gout <= "11111111";
								Bout <= "00000000";
							ELSE
								Rout <= "11111111"; --Red
								Gout <= "00000000";
								Bout <= "00000000";
							END IF;
						ELSIF (hpos > strip AND hpos < strip + 3) THEN --Centre line
						IF (vpos MOD 32 < 16) THEN
							Rout <= "00000000"; --Black
							Gout <= "00000000";
							Bout <= "00000000";
						ELSE 
							Rout <= "00000000";
							Gout <= "11111111";
							Bout <= "00000000";
						END IF;
						ELSE
							Rout <= "00000000";
							Gout <= "11111111";
							Bout <= "00000000";
						END IF;
						ELSE
							Rout <= "00000000";
							Gout <= "00000000";
							Bout <= "00000000";
						END IF;
					END IF;
				END PROCESS;
				DAC_CLK <= clk25;
END Behavioral;