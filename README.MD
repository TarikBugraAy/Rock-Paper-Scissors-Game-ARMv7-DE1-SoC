# Rock-Paper-Scissors Game for ARMv7 DE1-SoC

## Overview

This project implements a Rock-Paper-Scissors game on the ARMv7 DE1-SoC platform. The game is played against the machine, with the user making their choice using switches and starting each round with a push button. The machine's choice is determined randomly using a timer value. Scores are displayed on the seven-segment displays, and the game continues until either the user or the machine wins three rounds.

## Hardware Setup

- **Switches**: Used for user input to choose Rock, Paper, or Scissors.
- **Push Buttons**:
  - Push Button 0: Starts the round.
  - Push Button 1: Proceeds to the next round.
  - Push Button 2: Resets the game.
  - Push Button 3: Restarts the game after a winner is declared.
- **Seven-Segment Displays**:
  - HEX0: Displays the user's choice.
  - HEX1: Displays the machine's choice.
  - HEX4: Displays the user's score.
  - HEX5: Displays the machine's score.

## Memory Map

- **Seven-Segment Display Base Addresses**:
  - `SEG_BASE` - 0xFF200020
  - `SEG_BASE_2` - 0xFF200030
- **Switches Base Address**:
  - `SWITCH_BASE` - 0xFF200040
- **Timer Base Address**:
  - `TIMER_BASE` - 0xFFFEC600
  - `TIMER_VALUE` - 0xFFFEC604
  - `TIMER_CONTROL` - 0xFFFEC608

## Data Section

- **RPS**: Binary representations of Rock (r), Paper (P), and Scissors (S).
- **WINNER**: Binary representations for "User wins" and "Machine wins".
- **HEXTABLE**: Binary representations for digits 0-9 for seven-segment display.
- **Score Variables**:
  - `scoreuser`: User's score.
  - `scoremachine`: Machine's score.
- **Choice Variables**:
  - `user_choice`: User's choice.
  - `machine_choice`: Machine's choice.

## Instructions

1. **Initialize**: Set up the initial display and timer.
2. **Main Loop**:
   - Read the user's input from switches.
   - Start the round when Push Button 0 is pressed.
   - Generate the machine's choice using the timer value.
   - Display the choices on HEX0 (user) and HEX1 (machine).
   - Decide the winner of the round and update scores.
   - Display updated scores on HEX4 (user) and HEX5 (machine).
   - Check for game winner (first to score 3 wins).
   - Wait for Push Button 1 to proceed to the next round or Push Button 2 to reset.
   - Push Button 3 restarts the game after a winner is declared.
   
## Functions

### Initialization
- `initialize`: Sets up the initial display with zeros.
- `initialize_timer`: Configures the timer for random choice generation.

### User Input
- `read_user_input`: Reads the user's choice from switches.
- `get_timer_value`: Uses the timer value to generate the machine's choice.

### Display Functions
- `display_choices`: Displays the user and machine choices on HEX0 and HEX1.
- `display_score`: Displays the current scores on HEX4 and HEX5.

### Game Logic
- `decide_winner`: Determines the winner of the current round.
- `game_winner`: Checks if there's a game winner and handles the end of the game.
- `wait_for_next_round`: Waits for user input to proceed to the next round or reset the game.

### Reset and Restart
- `reset_handler`: Resets the scores and restarts the game.

## Build and Run

1. **Compile** the assembly code and load it onto the ARMv7 DE1-SoC platform.
2. **Connect** the hardware components (switches, push buttons, and seven-segment displays) as per the memory map.
3. **Start the Game**: 
   - Use switches to select Rock (0), Paper (1), or Scissors (2).
   - Press Push Button 0 to start the round.
   - Observe the choices and scores on the seven-segment displays.
   - Press Push Button 1 to proceed to the next round or Push Button 2 to reset the game.
   - The game will automatically declare a winner after either the user or the machine scores 3 points.
   - Press Push Button 3 to restart the game after a winner is declared.

