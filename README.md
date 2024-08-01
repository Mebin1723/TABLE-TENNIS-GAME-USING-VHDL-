# TABLE-TENNIS-GAME-USING-VHDL-
This project aims at implementing the concept of the classic 2D arcade games to develop a  simple Table tennis game on cyclone IV FPGA DE2 115 Board using VHDL, aiming to study the  VGA interface for designing the game graphic output.  
This project aims at implementing the concept of the classic 2D arcade games to develop a 
simple Table tennis game on cyclone IV FPGA DE2 115 Board using VHDL, aiming to study the VGA interface for designing the game graphic output.  
Table tennis or ping-pong as it is called, is a sport where two or four players hit a ball back and forth across a table using small rackets. 
The game takes places on a table divided by a net. 
The player tries to bounce the ball back to its opponent and a score is made when the opponent misses the ball. 
We aim at replicating this game on the VGA monitor using two rectangular bars as rackets for the two players on each end of the display and a square ball that bounces between them. 
Similar to a regular table tennis game, a score is registered for the opponent when a player misses the ball. 
The first player to achieve a score of 16 is declared a winner.  
We are using an FPGA for our project because it is a high-speed, cost-efficient device that can be used to implement a system that is easily modifiable as and when necessary. 
Several aspects of the board like memory, arithmetic operations, counter, clock, pll etc. are used to drive this game on a VGA monitor. 
The 7-segment LED display on the board are utilized to display the scores. 
The 4 push buttons (2 for each player) on the board control the movement of the paddle vertically and the player is free to reset the game at any time. 
The switch on the board is used to select the game mode. 
