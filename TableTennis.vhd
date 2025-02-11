library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TableTennis is
    Port (
		clk : in STD_LOGIC;
		hsync_out : out STD_LOGIC;
		vsync_out : out STD_LOGIC;
		vga_clk : out STD_LOGIC;
		red_out : out STD_LOGIC;
		green_out : out STD_LOGIC;
		blue_out : out STD_LOGIC;
      leftPlayerInput : in STD_LOGIC;
      rightPlayerInput : in STD_LOGIC;
		soundPin : buffer STD_LOGIC := '0';
		kb_clk : in STD_LOGIC;
		kb_data : in STD_LOGIC
	);
end TableTennis;

architecture Behavioral of TableTennis is

component KeyboardController is
    Port ( Clock : in STD_LOGIC;
	        KeyboardClock : in  STD_LOGIC;
           KeyboardData : in  STD_LOGIC;
           LeftPaddleDirection : out  integer;
           RightPaddleDirection : out  integer
			  
	);
	
end component;

signal halfClock : STD_LOGIC;
signal horizontalPosition : integer range 0 to 800 := 0;
signal verticalPosition : integer range 0 to 521 := 0;
signal hsyncEnable : STD_LOGIC;
signal vsyncEnable : STD_LOGIC;

signal photonX : integer range 0 to 640 := 10;
signal photonY : integer range 0 to 480 := 10;

constant leftPaddleX : integer := 25;
signal leftPaddleY : integer range 0 to 480 := 240;
constant rightPaddleX : integer := 615;
signal rightPaddleY : integer range 0 to 480 := 240;
signal rightPaddleDirection : integer := 0;
signal leftPaddleDirection : integer := 0;

signal paddleHalfHeight : integer range 0 to 50 := 25;
constant paddleHalfWidth : integer := 3;

constant leftPaddleBackX : integer := leftPaddleX-paddleHalfWidth;
constant leftPaddleFrontX : integer := leftPaddleX+paddleHalfWidth;
constant rightPaddleFrontX : integer := rightPaddleX-paddleHalfWidth;
constant rightPaddleBackX : integer := rightPaddleX+paddleHalfWidth;
constant paddleBottomLimit : integer := 474;
constant paddleTopLimit : integer := 4;

signal color : STD_LOGIC_VECTOR (2 downto 0) := "000";

signal ballMovementClockCounter : integer range 0 to 1000000 := 0;
signal ballMovementClock : STD_LOGIC := '0';
signal paddleMovementClockCounter : integer range 0 to 1000000 := 0;
signal paddleMovementClock : STD_LOGIC := '0';

constant ballMaxSpeed : integer := 8;
signal ballX : integer range -100 to 640 := 320;
signal ballY : integer range -100 to 480 := 240;
signal ballSpeedX : integer range -100 to 100 := 1;
signal ballSpeedY : integer range -100 to 100 := 1;

constant maxLeftLifes : integer := 5;
constant maxRightLifes : integer := 5;

signal leftLifes : integer range 0 to 5 := maxLeftLifes;
signal rightLifes : integer range 0 to 5 := maxRightLifes;
signal gameOver : STD_LOGIC := '0';

constant leftLifePosition : integer := 179;
constant rightLifePosition : integer := 359;
constant lifeBarWidth : integer := 100;
constant lifeBarHeight : integer := 3;

signal resetBall : STD_LOGIC := '0';
signal resetCounter : integer range 0 to 101 := 0;

signal soundCounter : integer range 0 to 1000000 := 0;
signal soundClock : STD_LOGIC := '0';

signal soundPlingCounter : integer range 0 to 100000000 := 0;
signal soundEnable : STD_LOGIC := '0';
signal playSound : STD_LOGIC := '0';



begin

	kbController : KeyboardController port map ( clk, kb_clk, kb_data, leftPaddleDirection, rightPaddleDirection );

	soundScaler : process(clk)
	begin
		if clk'event and clk='1' then
			if soundCounter = 100000 then --adjust for length of beep
				soundCounter <= 0;
				soundClock <= not soundClock;
			else
				soundCounter <= soundCounter + 1;
			end if;
		end if;
	end process soundScaler;

	sound : process(soundClock)
	begin
		if soundClock'event and soundClock = '1' then
			if soundEnable = '1' then
				soundPin <= not soundPin;
			else
				soundPin <= '0';
			end if;
		end if;
	end process sound;

	soundPling : process(playSound, soundClock)
	begin
		if soundClock'event and soundClock = '1' then
			if playSound='1' then
				if soundPlingCounter >=	0 and soundPlingCounter < 20 then
					soundEnable <= '1';
					soundPlingCounter <= soundPlingCounter + 1;
				else
					soundEnable <= '0';
				end if;
			else
				soundEnable <= '0';
				soundPlingCounter <= 0;
			end if;
		end if;
	end process soundPling;

	-- Half the clock
	clockScaler : process(clk)
	begin
		if clk'event and clk = '1' then
			halfClock <= not halfClock;
		end if;
	end process clockScaler;
	
	vga_clk<=halfClock; -- output VGA Clk
------------------------------------------------------------------------
ballMovementClockScaler : process(clk,gameOver)
	begin
		if clk'event and clk = '1' then
			ballMovementClockCounter <= ballMovementClockCounter + 1;

			if (ballMovementClockCounter = 500000) then
				ballMovementClock <= not ballMovementClock;
				ballMovementClockCounter <= 0;
			end if;
		end if;
	end process ballMovementClockScaler;



-------------------------------------------------------------------------
	paddleMovementClockScaler : process(clk)
	begin
		if clk'event and clk = '1' then
			paddleMovementClockCounter <= paddleMovementClockCounter + 1;

			if (paddleMovementClockCounter = 100000) then
				paddleMovementClock <= not paddleMovementClock;
				paddleMovementClockCounter <= 0;
			end if;
		end if;
	end process paddleMovementClockScaler;
--------------------------------------------------------------------------
	signalTiming : process(halfClock)
	begin
		if halfClock'event and halfClock = '1' then
			if horizontalPosition = 800 then
				horizontalPosition <= 0;
				verticalPosition <= verticalPosition + 1;

				if verticalPosition = 521 then
					verticalPosition <= 0;
				else
					verticalPosition <= verticalPosition + 1;
				end if;
			else
				horizontalPosition <= horizontalPosition + 1;
			end if;
		end if;
	end process signalTiming;
----------------------------------------------------------------------------
	vgaSync : process(halfClock, horizontalPosition, verticalPosition)
	begin
		if halfClock'event and halfClock = '1' then
			if horizontalPosition > 0 and horizontalPosition < 97 then
				hsyncEnable <= '0';
			else
				hsyncEnable <= '1';
			end if;

			if verticalPosition > 0 and verticalPosition < 3 then
				vsyncEnable <= '0';
			else
				vsyncEnable <= '1';
			end if;
		end if;
	end process vgaSync;
---------------------------------------------------------------------
	coordinates : process(horizontalPosition, verticalPosition)
	begin
		photonX <= horizontalPosition - 144;
		photonY <= verticalPosition - 31;
	end process coordinates;
-------------------------------------------------------------------
finishGame : process(leftLifes, rightLifes)
begin
    if leftLifes = 0 or rightLifes = 0 then
        gameOver <= '1'; -- Game over
    else
        gameOver <= '0'; -- Continue the game
    end if;
end process finishGame;




------------------------------------------------------------------------------------------

--colorsetter-----------------------------------------------------------------------------

	colorSetter : process(photonX, photonY, halfClock)
	begin
	
-- Paddle handling
		if gameOver = '1' then
-- next section produces GAME OVER ON SCREEN----------------------------------------------
			-- G
			if photonX >= 20 and photonX <= 80 and photonY >= 180 and photonY <= 190 then
				color <= "100";
			elsif photonX >= 20 and photonX <= 30 and photonY >= 190 and photonY <= 300 then
				color <= "100";
			elsif photonX >= 20 and photonX <= 80 and photonY >= 290 and photonY <= 300 then
				color <= "100";
			elsif photonX >= 70 and photonX <= 80 and photonY >= 240 and photonY <= 300 then
				color <= "100";
			elsif photonX >= 50 and photonX <= 80 and photonY >= 240 and photonY <= 250 then
				color <= "100";

			-- A
			elsif photonX >= 90 and photonX <= 150 and photonY >= 180 and photonY <= 190 then
				color <= "100";
			elsif photonX >= 90 and photonX <= 100 and photonY >= 190 and photonY <= 300 then
				color <= "100";
			elsif photonX >= 140 and photonX <= 150 and photonY >= 190 and photonY <= 300 then
				color <= "100";
			elsif photonX >= 90 and photonX <= 150 and photonY >= 240 and photonY <= 250 then
				color <= "100";

			-- M
			elsif ((photonX >= 160 and photonX <= 170 and photonY >= 180 and photonY <= 300) or 
					(photonX >= 170 and photonX <= 220 and photonY >= 190 and photonY <= 200) or
					(photonX >= 210 and photonX <= 220 and photonY >= 190 and photonY <= 300) or
					(photonX >= 185 and photonX <= 195 and photonY >= 190 and photonY <= 300)) then
				color <= "100";

			-- first E
			elsif photonX >= 230 and photonX <= 290 and photonY >= 180 and photonY <= 190 then
				color <= "100";
			elsif photonX >= 230 and photonX <= 290 and photonY >= 235 and photonY <= 245 then
				color <= "100";
			elsif photonX >= 230 and photonX <= 290 and photonY >= 290 and photonY <= 300 then
				color <= "100";
			elsif photonX >= 230 and photonX <= 240 and photonY >= 180 and photonY <= 300 then
				color <= "100";

			-- O
			elsif photonX >= 348 and photonX <= 408 and photonY >= 180 and photonY <= 190 then
				color <= "110";
			elsif photonX >= 348 and photonX <= 358 and photonY >= 190 and photonY <= 290 then
				color <= "110";
			elsif photonX >= 398 and photonX <= 408 and photonY >= 190 and photonY <= 290 then
				color <= "110";
			elsif photonX >= 348 and photonX <= 408 and photonY >= 290 and photonY <= 300 then
				color <= "110";

			-- V
			elsif photonX >= 418 and photonX <= 448  and photonY >= 270 and photonY <= 300 then
				if (photonX - 418) = (photonY - 270) or
					(photonX - 419) = (photonY - 270) or
					(photonX - 420) = (photonY - 270) or
					(photonX - 421) = (photonY - 270) or
					(photonX - 422) = (photonY - 270) or
					(photonX - 423) = (photonY - 270) or
					(photonX - 424) = (photonY - 270) or
					(photonX - 425) = (photonY - 270) or
					(photonX - 426) = (photonY - 270) or
					(photonX - 427) = (photonY - 270) or
					(photonX - 428) = (photonY - 270) then
					color <= "000";
				else
					color <= "001";
				end if;

			elsif photonX >= 449 and photonX <= 478  and photonY >= 270 and photonY <= 300 then
				if (478 - photonX) = (photonY - 270) or
					(477 - photonX) = (photonY - 270) or
					(476 - photonX) = (photonY - 270) or
					(475 - photonX) = (photonY - 270) or
					(474 - photonX) = (photonY - 270) or
					(473 - photonX) = (photonY - 270) or
					(472 - photonX) = (photonY - 270) or
					(471 - photonX) = (photonY - 270) or
					(470 - photonX) = (photonY - 270) or
					(469 - photonX) = (photonY - 270) or
					(468 - photonX) = (photonY - 270) then
					color <= "000";
				else
					color <= "010";
				end if;

			elsif (photonX >= 418 and photonX <= 428 and photonY >= 180 and photonY <= 270) or
					(photonX >= 468 and photonX <= 478 and photonY >= 180 and photonY <= 270) then
				color <= "110";

			-- second E
			elsif photonX >= 488 and photonX <= 548 and photonY >= 180 and photonY <= 190 then
				color <= "110";
			elsif photonX >= 488 and photonX <= 548 and photonY >= 235 and photonY <= 245 then
				color <= "110";
			elsif photonX >= 488 and photonX <= 548 and photonY >= 290 and photonY <= 300 then
				color <= "110";
			elsif photonX >= 488 and photonX <= 498 and photonY >= 180 and photonY <= 300 then
				color <= "110";

			-- R
			elsif photonX >= 558 and photonX <= 618 and photonY >= 180 and photonY <= 190 then
				color <= "110";
			elsif photonX >= 558 and photonX <= 568 and photonY >= 190 and photonY <= 300 then
				color <= "110";
			elsif photonX >= 608 and photonX <= 618 and photonY >= 190 and photonY <= 250 then
				color <= "110";
			elsif photonX >= 558 and photonX <= 618 and photonY >= 245 and photonY <= 255 then
				color <= "110";
			elsif photonX >= 568 and photonX <= 618  and photonY >= 245 and photonY <= 300 then
				if (photonX - 568) = (photonY - 255) or
					(photonX - 567) = (photonY - 255) or
					(photonX - 566) = (photonY - 255) or
					(photonX - 565) = (photonY - 255) or
					(photonX - 564) = (photonY - 255) or
					(photonX - 563) = (photonY - 255) or
					(photonX - 562) = (photonY - 255) or
					(photonX - 561) = (photonY - 255) or
					(photonX - 569) = (photonY - 255) or
					(photonX - 570) = (photonY - 255) or
					(photonX - 571) = (photonY - 255) or
					(photonX - 572) = (photonY - 255) or
					(photonX - 573) = (photonY - 255) or
					(photonX - 574) = (photonY - 255) then
					color <= "110";
				else
					color <= "000";
				end if;
			else
				color <= "000";
			end if;
-- end of GAME OVER definition----------------------------------------------------------------------------------
--Paddle color---------------------------------------------------------------------------------------------------

		elsif ((photonX >= leftPaddleBackX) and (photonX <= leftPaddleFrontX)
			and (photonY >= leftPaddleY - paddleHalfHeight) and (photonY <= leftPaddleY + paddleHalfHeight))or
			((photonX >= rightPaddleFrontX) and (photonX <= rightPaddleBackX)
			and (photonY >= rightPaddleY - paddleHalfHeight) and (photonY <= rightPaddleY + paddleHalfHeight)) then
			color <= "100";
			
-- Dashed Line----------------------------------------------------------------------------------------------------
		
		
		elsif (photonX >= 319 and photonX <= 321 and photonY mod 16 <= 10) then
      color <= "111";
		
-- right Dashline
		elsif (photonX >= 635 and photonX <= 640 and photonY mod 15 <= 20) then
    color <= "111";
	 
--left Dashline
    elsif (photonX >= 0 and photonX <= 5 and photonY mod 16 <= 20) then
    color <= "111";
	 
--Horizontal Dashline---------------------------------------------------------

--Middle	
	elsif (photonY >= 240 and photonY <= 242 and photonX mod 16 <= 20) then
    color <= "111";
	 
--Top	
	elsif (photonY >= 475 and photonY <= 480 and photonX mod 16 <= 20) then
    color <= "111";
	 
--bottam
		elsif (photonY >= 0 and photonY <= 5 and photonX mod 16 <= 20) then
    color <= "111";
-- Ball-------------------------------------------------------------------------------------------------------------
		elsif (photonY >= ballY - 2 and photonY <= ballY + 2) and (photonX >= ballX - 2 and photonX <= ballX + 2) then
			color <= "110";
		elsif (photonY >= ballY - 3 and photonY <= ballY + 3) and (photonX >= ballX - 1 and photonX <= ballX + 1) then
			color <= "110";
		elsif (photonY >= ballY - 1 and photonY <= ballY + 1) and (photonX >= ballX - 3 and photonX <= ballX + 3) then
			color <= "110";
---------------------------------------------------------------------------------------------------------------------
--Lifebars-----------------------------------------------------------------------------------------------------------
-- green lifebar
		elsif (photonX>=leftLifePosition and photonX<leftLifePosition+(leftLifes*20) and photonY>=30 and photonY<=30+lifeBarHeight) or
			(photonX>=rightLifePosition and photonX<rightLifePosition+(rightLifes*20) and photonY>=30 and photonY<=30+lifeBarHeight) then
			color <= "010";			

-- red lifebar

		elsif (photonX >= (leftLifePosition+(leftLifes*20)) and photonX <= (leftLifePosition+(20*maxLeftLifes))
	        	and photonY>=30 and photonY<=(30+lifeBarHeight)) or
			(photonX>=(rightLifePosition+(rightLifes*20)) and photonX<= (rightLifePosition+(20*maxRightLifes))
			and photonY>=30 and photonY<=(30+lifeBarHeight)) then
			color <= "100";			
-- Display Player P1--------------------------------------------------------------------------------------------------------
elsif (photonX >= 130 and photonX <= 135 and photonY >= 20 and photonY <= 47) or
       (photonX >= 135 and photonX <= 143 and photonY >= 20 and photonY <= 25) or
       (photonX >= 143 and photonX <= 147 and photonY >= 20 and photonY <= 33) or
       (photonX >= 135 and photonX <= 147 and photonY >= 33 and photonY <= 38) or
       (photonX >= 153 and photonX <= 158 and photonY >= 20 and photonY <= 46) then
    color <= "011";
-- Display Player P2--------------------------------------------------------------------------------------------------------
elsif (photonX >= 515 and photonX <= 520 and photonY >= 20 and photonY <= 47) or
       (photonX >= 520 and photonX <= 528 and photonY >= 20 and photonY <= 25) or
       (photonX >= 528 and photonX <= 532 and photonY >= 20 and photonY <= 33) or
       (photonX >= 520 and photonX <= 532 and photonY >= 33 and photonY <= 38) or
       (photonX >= 538 and photonX <= 543 and photonY >= 20 and photonY <= 46) or
       (photonX >= 549 and photonX <= 554 and photonY >= 20 and photonY <= 46) then
    color <= "011";
----------------------------------------------------------------------------------------------------------------------------
		
-- background---------------------------------------------------------------------------------------------------------------
		else
			color <= "001";
		end if;
	end process colorSetter;
----------------------------------------------------------------------------------------------------------------------------

--PaddleMovement-------------------------------------------------------------------------------------------------------------

	leftPaddleMovement : process(paddleMovementClock)
	begin
		if paddleMovementClock'event and paddleMovementClock = '1' then
			if leftPaddleY + leftPaddleDirection < paddleBottomLimit - paddleHalfHeight 
				and leftPaddleY + leftPaddleDirection > paddleTopLimit + paddleHalfHeight then
				leftPaddleY <= leftPaddleY + leftPaddleDirection;
			end if;
		end if;
	end process leftPaddleMovement;
---------------------------------------------------------------------------------------------

	rightPaddleMovement : process(paddleMovementClock)
	begin
		if paddleMovementClock'event and paddleMovementClock = '1' then
			if rightPaddleY + rightPaddleDirection < paddleBottomLimit - paddleHalfHeight 
				and rightPaddleY + rightPaddleDirection > paddleTopLimit + paddleHalfHeight then
				rightPaddleY <= rightPaddleY + rightPaddleDirection;
			end if;
		end if;
	end process rightPaddleMovement;
--------------------------------------------------------------------------------------------------------------------------------

--Ball Movement-----------------------------------------------------------------------------------------------------------------

ballMovement : process(ballMovementClock, gameOver)
begin
    if soundPlingCounter >= 10 then
        playSound <= '0';
    elsif ballMovementClock'event and ballMovementClock = '1' then
        if resetBall = '1' then
            if resetCounter = 100 then
                resetCounter <= 0;
                ballX <= 319;
                ballY <= 239;
                resetBall <= '0';
            else
                resetCounter <= resetCounter + 1;
            end if;
        else
            if ballX + 4 > rightPaddleFrontX and ballX < rightPaddleBackX 
               and ballY + 4 > rightPaddleY - paddleHalfHeight and ballY - 4 < rightPaddleY + paddleHalfHeight then
                ballX <= rightPaddleFrontX - 4;
                ballSpeedY <= (ballY - rightPaddleY) / 8;
                ballSpeedX <= -ballMaxSpeed + ballSpeedY;
                playSound  <= '1';
            elsif ballX - 4 < leftPaddleFrontX and ballX > leftPaddleBackX
               and ballY + 4 > leftPaddleY - paddleHalfHeight and ballY - 4 < leftPaddleY + paddleHalfHeight then
                ballX <= leftPaddleFrontX + 4;
                ballSpeedY <= (ballY - leftPaddleY) / 8;
                ballSpeedX <= ballMaxSpeed - ballSpeedY;
                playSound  <= '1';
            elsif ballX + ballSpeedX < 4 then
                leftLifes <= leftLifes - 1;
                ballX <= -20;
                ballY <= -20;
                resetBall <= '1';
            elsif ballX + ballSpeedX > 635 then
                rightLifes <= rightLifes - 1;
                ballX <= -20;
                ballY <= -20;
                resetBall <= '1';
            else
                ballX <= ballX + ballSpeedX;
            end if;

            if ballY > 470 then
                ballY <= 470;
                ballSpeedY <= -ballSpeedY;
                playSound  <= '1';
            elsif ballY < 10 then
                ballY <= 10;
                ballSpeedY <= -ballSpeedY;
                playSound  <= '1';
            else
                ballY <= ballY + ballSpeedY;
            end if;
        end if;
    end if;
end process ballMovement;
------------------------------------------------------------------------------------------------------------------------
	draw : process(photonX, photonY, halfClock)
	begin
		if halfClock'event and halfClock = '1' then
			hsync_out <= hsyncEnable;
			vsync_out <= vsyncEnable;

			if (photonX < 640 and photonY < 480) then
				red_out <= color(2);
				green_out <= color(1);
				blue_out <= color(0);
			else
				red_out <= '0';
				green_out <= '0';
				blue_out <= '0';
			end if;
		end if;
	end process draw;

end Behavioral;