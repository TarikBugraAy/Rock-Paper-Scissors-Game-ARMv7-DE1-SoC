.equ SEG_BASE, 0xFF200020        // Base address of the seven-segment display for HEX0, HEX1, HEX2, and HEX3
.equ SEG_BASE_2, 0xFF200030      // Base address of the seven-segment display for HEX4 and HEX5
.equ SWITCH_BASE, 0xFF200040     // Base address of the switches for user input
.equ TIMER_BASE, 0xFFFEC600      // Base address of the Cortext A9 private timer and it's load register
.equ TIMER_VALUE, 0xFFFEC604     // Address of the timer counter register
.equ TIMER_CONTROL, 0xFFFEC608   // Address of the timer control register
.equ PUSH_BUTTONS, 0xFF200050    // Base address of the push buttons for user input


.data                            // Data section starts here

RPS:                             // Table of values for rock, paper, and scissors for seven-segment display
    .word 0b01010000             // R
    .word 0b01110011             // P
    .word 0b01101101             // S

WINNER:                          // Table of values for displaying winner on seven-segment display
    .word 0b00111110             // User wins "U"
    .word 0b01010101             // Machine wins  "M"

HEXTABLE:                        // Table of values for displaying numbers on seven-segment display
    .word 0b00111111             // 0
    .word 0b00000110             // 1
    .word 0b01011011             // 2
    .word 0b01001111             // 3
    .word 0b01100110             // 4
    .word 0b01101101             // 5
    .word 0b01111101             // 6
    .word 0b00000111             // 7
    .word 0b01111111             // 8
    .word 0b01101111             // 9

scoreuser:                       // For saving user score in memory
    .word 0
scoremachine:                    // For saving machine score in memory
    .word 0

user_choice:                     // For saving user choice in memory
    .word 0
machine_choice:                  // For saving machine choice in memory
    .word 0

.text                            // Code section starts here
.global _start

_start:
    BL initialize                // Initialize seven-segment display
    BL initialize_timer          // Initialize timer for machine choice selection
main_loop:                       // Main loop for the game
    BL read_user_input           // Read user input from switches to get user choice
    LDR r1, =PUSH_BUTTONS        // Base address for push buttons to check if push button 0 is pressed
    LDR r0, [r1]                 // Read the value of the push buttons
    AND r0, r0, #0x1             // Check if push button 0 is pressed
    CMP r0, #0                   // If push button 0 isn't pressed, wait for it to be pressed
    BEQ main_loop                // If push button 0 is not pressed, continue playing
    BL get_timer_value           // Get timer value to decide machine choice
    BL display_choices           // Display user and machine choices
    BL decide_winner             // Decide winner of the round based on user and machine choices
    BL display_score             // Display user and machine scores on seven-segment display
    BL game_winner               // Check if there is a winner of the game and display it
    BL wait_for_next_round       // Wait for push button 1 to continue playing or push button 2 to reset game
    B main_loop                  // Continue playing

initialize:
    // Set up initial display
    MOV r0, #0
    LDR r2, =HEXTABLE            // Load the HEXTABLE values from memory
    LDR r2, [r2, r0, LSL #2]     // Load the value for 0
    LDR r1, =SEG_BASE_2          // Load the base address of the seven-segment display for HEX4 and HEX5
    ORR r0, r0, r2, LSL #8       // Combine the values for HEX4 and HEX5
    ORR r0, r0, r2
    STR r0, [r1]                 // Write the combined value to the seven-segment display for HEX4 and HEX5 to initialize scores on the display
	LDR r1, =SEG_BASE            // Load the base address of the seven-segment display for HEX0, HEX1, HEX2, and HEX3
	LDR r2, =0b00001000          //Underline the place where the user and machine choice will be displayed on the seven-segment display
	MOV r0, #0
	ORR r0,r0,r2, LSL #8         // Combine the values for HEX0 and HEX1
	ORR r0,r0,r2
	STR r0, [r1]                 // Write the combined value to the seven-segment display for HEX0 and HEX1
    BX lr                        // Return

initialize_timer:                // Initialize the timer
    LDR r1, =TIMER_BASE          // Load the base address of the private timer and it's load register
    LDR r0, =0xFFFFFFFF          // Load maximum value for timer
    STR r0, [r1]                 // Set the timer load register to the maximum value
    MOV r0, #3                   // Value for the timer control register to enable and auto-reload
    LDR r1, =TIMER_CONTROL       // Load the base address of the timer control register
    STR r0, [r1]                 // Set the timer control register to enable and auto-reload
    BX lr                        // Return

read_user_input:                 // Read user input from switches
    PUSH {r4, lr}                // Save r4 and lr to the stack
    LDR r1, =SWITCH_BASE         // Load the base address of the switches
    LDR r0, [r1]                 // Read the value of the switches
    AND r0, r0, #0x7             // Mask switches 0, 1, and 2 for user choice
    MOV r2, r0                   // Store user choice in r2
    LDR r1, =user_choice         // Load the address of the user choice memory location
    STR r2, [r1]                 // Store user choice in memory
    POP {r4, lr}                 // Restore r4 and lr from the stack
    BX lr                        // Return

get_timer_value:                 // Get the current value of the timer to decide machine choice
    PUSH {r4, lr}                // Save r4 and lr to the stack
    LDR r1, =TIMER_VALUE         // Load the timer counter register address
    LDR r0, [r1]                 // Read current timer value
    AND r0, r0, #0xF             // Mask to get values 0 to 15 for machine choice selection
    CMP r0, #5                   // Check if the value is less than 5
    BLT choose_rock              // If less than 5, choose rock
    CMP r0, #10                  // Check if the value is less than 10
    BLT choose_paper             // If between 5 and 10, choose paper
    CMP r0, #15                  // Check if the value is less than 15
    BLT choose_scissors          // If between 10 and 15, choose scissors
    B get_timer_value            // Read again to avoid bias if not in range

choose_rock:                     // Machine chooses rock
    MOV r0, #0                   // Choose value that represents rock (0) in the RPS array
    LDR r1, =machine_choice      // Load the address of the machine choice memory location
    STR r0, [r1]                 // Store machine choice in memory
    POP {r4, lr}                 // Restore r4 and lr from the stack
    BX lr                        // Return

choose_paper:                    // Machine chooses paper
    MOV r0, #1                   // Choose value that represents paper (1) in the RPS array
    LDR r1, =machine_choice      // Load the address of the machine choice memory location
    STR r0, [r1]                 // Store machine choice in memory
    POP {r4, lr}                 // Restore r4 and lr from the stack
    BX lr                        // Return

choose_scissors:                 // Machine chooses scissors
    MOV r0, #2                   // Choose value that represents scissors (2) in the RPS array
    LDR r1, =machine_choice      // Load the address of the machine choice memory location
    STR r0, [r1]                 // Store machine choice in memory
    POP {r4, lr}                 // Restore r4 and lr from the stack
    BX lr                        // Return

display_choices:                 // Display user and machine choices on the seven-segment display
    PUSH {r4, r5, lr}            // Save r4, r5, and lr to the stack
    LDR r1, =user_choice         // Load the address of the user choice memory location
    LDR r2, [r1]                 // Load user choice from memory
    LDR r3, =RPS                 // Load the base address of the RPS array for user and machine choices
                                 // Display user choice on the seven-segment display
    CMP r2, #1                   // Check user choice for rock, 1 (2^0) because switch 0 is rock
    BEQ display_r_user           // If usesr choice is rock, display rock
    CMP r2, #2                   // Check user choice for paper, 2 (2^1) because switch 1 is paper
    BEQ display_P_user           // If user choice is paper, display paper
    CMP r2, #4                   // Check user choice for scissors, 4 (2^2) because switch 2 is scissors
    BEQ display_S_user           // If user choice is scissors, display scissors
    B move_to_the_next_round     // If user choice is not valid go to next round

display_r_user:                  // Choose rock for user from RPS array to display
    LDR r4, [r3]                 // Load 'R' for user from RPS array
    B display_machine_choice     // Select machine choice from RPS array

display_P_user:                  // Choose paper for user from RPS array to display
    LDR r4, [r3, #4]             // Load 'P' for user from RPS array
    B display_machine_choice     // Select machine choice from RPS array

display_S_user:                  // Choose scissors for user from RPS array to display
    LDR r4, [r3, #8]             // Load 'S' for user from RPS array
    B display_machine_choice     // Select machine choice from RPS array

move_to_the_next_round:          // Move to the next round if user choice is not valid (push button 1 for next round or push button 2 to reset game)
    POP {r4, r5, lr}             // Restore r4, r5, and lr
    BX lr                        // Return to the main loop

display_machine_choice:          // Choose machine choice from RPS array to display
    LDR r1, =machine_choice      // Load the address of the machine choice memory location
    LDR r0, [r1]                 // Load machine choice from memory
    CMP r0, #0                   // Check machine choice for rock
    BEQ display_r_machine        // If machine choice is rock, display rock
    CMP r0, #1                   // Check machine choice for paper
    BEQ display_P_machine        // If machine choice is paper, display paper
    CMP r0, #2                   // Check machine choice for scissors
    BEQ display_S_machine        // If machine choice is scissors, display scissors
    B clear_display_machine      // If machine choice is not valid, clear display

display_r_machine:               // Choose rock for machine from RPS array to display
    LDR r5, [r3]                 // Load 'R' for machine from RPS array
    B combine_and_display        // Combine and display user and machine choices

display_P_machine:               // Choose paper for machine from RPS array to display
    LDR r5, [r3, #4]             // Load 'P' for machine from RPS array
    B combine_and_display        // Combine and display user and machine choices

display_S_machine:               // Choose scissors for machine from RPS array to display
    LDR r5, [r3, #8]             // Load 'S' for machine from RPS array
    B combine_and_display        // Combine and display user and machine choices

clear_display_machine:           // Clear the display if machine choice is not valid
    MOV r5, #0                   // Choose blank value to clear the display
    B combine_and_display        // Combine and display user and machine choices

combine_and_display:             // Combine and display user and machine choices on the seven-segment display
    LDR r1, =SEG_BASE            // Load the base address of the seven-segment display for HEX0, HEX1, HEX2, and HEX3
    MOV r0, #0                   // Clear the r0 register to combine user and machine choices
    ORR r0, r0, r4               // Add user choice to r0's 0-7 bits
    ORR r0, r0, r5, LSL #8       // Add machine choice to r0's 8-15 bits
    STR r0, [r1]                 // Write combined value to seven-segment display
    POP {r4, r5, lr}             // Restore r4, r5, and lr from the stack
    BX lr                        // Return to the main loop

decide_winner:                   // Decide the winner of the round based on user and machine choices
    PUSH {r4, r5, lr}            // Save r4, r5, and lr to the stack to be restored later

    LDR r1, =user_choice         // Load the address of the user choice memory location
    LDR r2, [r1]                 // Load user choice from memory
    CMP r2, #1                   // Check user choice for rock
    BEQ user_rock                // If user choice is rock, go to user_rock
    CMP r2, #2                   // Check user choice for paper
    BEQ user_paper               // If user choice is paper, go to user_paper
    CMP r2, #4                   // Check user choice for scissors
    BEQ user_scissors            // If user choice is scissors, go to user_scissors
    B user_not_playing           // If user choice is not valid, go to user_not_playing

// user_rock, user_paper, and user_scissors are for turning values of user choice to be able to compare it with machine choice(1, 2, 4 to 0, 1, 2)
user_rock:                       // User choice is rock
    MOV r4, #0                   // Turn the value of user for rock, from 1 to 0 to be able to compare it with machine choice.
    STR r4, [r1]                 // Store the reassigned value of user choice in memory
    B compare_choices            // Compare user and machine choices to decide the winner of the round

user_paper:                      // User choice is paper
    MOV r4, #1                   // Turn the value of user for paper, from 2 to 1 to be able to compare it with machine choice.
    STR r4, [r1]                 // Store the reassigned value of user choice in memory
    B compare_choices            // Compare user and machine choices to decide the winner of the round

user_scissors:                   // User choice is scissors
    MOV r4, #2                   // Turn the value of user for scissors, from 4 to 2 to be able to compare it with machine choice.
    STR r4, [r1]                 // Store the reassigned value of user choice in memory
    B compare_choices            // Compare user and machine choices to decide the winner of the round

user_not_playing:                // User is choose for the round
    POP {r4, r5, lr}             // Restore r4, r5, and lr from the stack
    BX lr                        // Return to the main loop

compare_choices:                 // Compare user and machine choices to decide the winner of the round
    LDR r1, =machine_choice      // Load the address of the machine choice memory location
    LDR r0, [r1]                 // Load machine choice from memory
    CMP r4, #0                   // Check user choice for rock
    BEQ rock                     // If user choice is rock, go to rock
    CMP r4, #1                   // Check user choice for paper
    BEQ paper                    // If user choice is paper, go to paper
    CMP r4, #2                   // Check user choice for scissors
    BEQ scissors                 // If user choice is scissors, go to scissors

rock:                            // Compeare machine choice for user choice rock to determine the winner of the round
    CMP r0, #0                   // Check machine choice for rock
    BEQ tie                      // If machine choice is rock, go to tie
    CMP r0, #1                   // Check machine choice for paper
    BEQ machine_score            // If machine choice is paper, go to machine_score
    CMP r0, #2                   // Check machine choice for scissors
    BEQ user_score               // If machine choice is scissors, go to user_score

paper:                           // Compeare machine choice for user choice paper to determine the winner of the round
    CMP r0, #0                   // Check machine choice for rock
    BEQ user_score               // If machine choice is rock, go to user_score
    CMP r0, #1                   // Check machine choice for paper
    BEQ tie                      // If machine choice is paper, go to tie
    CMP r0, #2                   // Check machine choice for scissors
    BEQ machine_score            // If machine choice is scissors, go to machine_score

scissors:                        // Compeare machine choice for user choice scissors to determine the winner of the round
    CMP r0, #0                   // Check machine choice for rock
    BEQ machine_score            // If machine choice is rock, go to machine_score
    CMP r0, #1                   // Check machine choice for paper
    BEQ user_score               // If machine choice is paper, go to user_score
    CMP r0, #2                   // Check machine choice for scissors
    BEQ tie                      // If machine choice is scissors, go to tie

tie:                             // Round is a tie neither user nor machine wins
    POP {r4, r5, lr}             // Restore r4, r5, and lr from the stack
    BX lr                        // Return to the main loop

machine_score:                   // Machine wins round, increment machine score
    LDR r1, =scoremachine        // Load the address of the machine score memory location
    LDR r0, [r1]                 // Load machine score from memory
    ADD r0, r0, #1               // Increment machine score
    STR r0, [r1]                 // Store the new machine score in memory
    POP {r4, r5, lr}             // Restore r4, r5, and lr from the stack
    BX lr                        // Return to the main loop

user_score:                      // User wins round, increment user score
    LDR r1, =scoreuser           // Load the address of the user score memory location
    LDR r0, [r1]                 // Load user score from memory
    ADD r0, r0, #1               // Increment user score
    STR r0, [r1]                 // Store the new user score in memory
    POP {r4, r5, lr}             // Restore r4, r5, and lr from the stack
    BX lr                        // Return to the main loop

display_score:                   // Display user and machine scores on the seven-segment display

    PUSH {r4, r5, lr}            // Save r4, r5, and lr to the stack

    LDR r1, =scoreuser           // Load the address of the user score memory location
    LDR r0, [r1]                 // Load user score from memory
    LDR r2, =HEXTABLE            // Load the base address of the HEXTABLE for displaying numbers on the seven-segment display
    LDR r4, [r2, r0, LSL #2]     // Load user score from HEXTABLE

    LDR r1, =scoremachine        // Load the address of the machine score memory location
    LDR r0, [r1]                 // Load machine score from memory
    LDR r2, =HEXTABLE            // Load the base address of the HEXTABLE for displaying numbers on the seven-segment display
    LDR r5, [r2, r0, LSL #2]     // Load machine score from HEXTABLE

    LDR r1, =SEG_BASE_2          // Load the base address of the seven-segment display for HEX4 and HEX5
    MOV r0, #0                   // Clear the r0 register to combine user and machine scores
    ORR r0, r0, r4               // Add user score to r0's 0-7 bits
    ORR r0, r0, r5, LSL #8       // Add machine score to r0's 8-15 bits
    STR r0, [r1]                 // Load combined value to seven-segment display

    POP {r4, r5, lr}             // Restore r4, r5, and lr from the stack
    BX lr                        // Return to the main loop

wait_for_next_round:             // Wait for push button 1 to continue playing or push button 2 to reset game
    LDR r1, =PUSH_BUTTONS        // Base address for push buttons to check if push buttons

wait_loop:                       // Wait loop to poll push buttons for user input to continue playing or reset game
    LDR r0, [r1]                 // Read the value of the push buttons to check if push button 1 or 2 is pressed
    AND r0, r0, #0x2             // Use AND to check the value of push buttons
    CMP r0, #0x2                 // Compare the value of push buttons to check if push button 1 is pressed
    BEQ continue_execution       // If push button 1 is pressed, continue playing the game without resetting
    LDR r2, [r1]                 // Read the value of the push buttons
    AND r2, r2, #0x4             // Use AND to check the value of push buttons
    CMP r2, #0x4                 // Compare the value of push buttons to check if push button 2 is pressed
    BEQ reset_handler            // If push button 2 is pressed, reset the game and start over

    B wait_loop                  // If push button 1 or 2 is not pressed, wait for it to be pressed

continue_execution:              // Continue playing the game without resetting
    BX lr                        // Return to the main loop to continue playing

reset_handler:                   // Reset the game and start over by clearing user and machine scores

    LDR r1, =scoreuser           // Load the address of the user score memory location
    MOV r0, #0                   // Move 0 to r0 register to reset user and machine scores
    STR r0, [r1]                 // Store the new user score in memory
    LDR r1, =scoremachine        // Load the address of the machine score memory location
    STR r0, [r1]                 // Store the new machine score in memory
    B initialize                 // Branch to initialize to clear the display and than branch back to the main loop to start over

game_winner:                     // Check if there is a winner of the game and display it
    LDR r1, =scoreuser           // Load the address of the user score memory location
    LDR r0, [r1]                 // Load user score from memory
    MOV r3, #3                   // Set the value of 3 to check if user score or machine score is 3
    CMP r0, r3                   // Compare user score to 3
    BEQ user_wins                // If user score is 3, branch to user_wins
    LDR r1, =scoremachine        // Load the address of the machine score memory location
    LDR r0, [r1]                 // Load machine score from memory
    CMP r0, r3                   // Compare machine score to 3
    BEQ machine_wins             // If machine score is 3, branch to machine_wins
    B no_winner                  // If no player has reached 3 points, branch to no_winner

no_winner:                       // If no player has reached 3 points, continue playing

    BX lr                        // Return to the main loop to continue playing

user_wins:                       // If user score is 3, user wins the game and display it on the seven-segment display and reset the game
    LDR r1, =WINNER              // Load the address of the WINNER memory location to display user wins
    LDR r0, [r1]                 // Load user wins from memory
    LDR r1, =SEG_BASE            // Load the base address of the seven-segment display for HEX0, HEX1, HEX2, and HEX3
    LDR r2, [r1]                 // Load the current value of the seven-segment display
    ORR r2, r2, r0, LSL #16      // Combine user wins to display with the current value of the seven-segment display, shifting left by 16 bits to HEX2
    STR r2, [r1]                 // Write the combined value to the seven-segment display

    // Reset user and machine scores and wait for push button 3 to restart the game than branch to _start to restart the game
    LDR r1, =scoreuser           // Load the address of the user score memory location
    MOV r0, #0                   // Move 0 to r0 register to reset user and machine score
    STR r0, [r1]                 // Reset user score
    LDR r1, =scoremachine        // Load the address of the machine score memory location
    STR r0, [r1]                 // Reset machine score
    LDR r1, =PUSH_BUTTONS        // Base address for push buttons
    LDR r0, [r1]                 // Read the value of the push buttons
    AND r0, r0, #0x8             // Use AND to check the value of push buttons
    CMP r0, #0                   // Compare the value of push buttons to check if push button 3 is pressed
    BEQ user_wins                // If push button 3 is not pressed, wait for it to be pressed

    B _start                     // If push button 3 is pressed, restart the game

machine_wins:                    // If machine score is 3, machine wins the game and display it on the seven-segment display and reset the game
    LDR r1, =WINNER              // Load the address of the WINNER memory location to display machine wins
    LDR r0, [r1, #4]             // Load machine wins from memory
    LDR r1, =SEG_BASE            // Load the base address of the seven-segment display for HEX0, HEX1, HEX2, and HEX3
    LDR r2, [r1]                 // Load the current value of the seven-segment display
    ORR r2, r2, r0, LSL #16      // Combine machine wins to display with the current value of the seven-segment display, shifting left by 16 bits to HEX2
    STR r2, [r1]                 // Write the combined value to the seven-segment display

    // Reset user and machine scores and wait for push button 3 to restart the game than branch to _start to restart the game
    LDR r1, =scoreuser           // Load the address of the user score memory location
    MOV r0, #0                   // Move 0 to r0 register to reset user and machine score
    STR r0, [r1]                 // Reset user score
    LDR r1, =scoremachine        // Load the address of the machine score memory location
    STR r0, [r1]                 // Reset machine score
    LDR r1, =PUSH_BUTTONS        // Base address for push buttons
    LDR r0, [r1]                 // Read the value of the push buttons
    AND r0, r0, #0x8             // Use AND to check the value of push buttons
    CMP r0, #0                   // Compare the value of push buttons to check if push button 3 is pressed
    BEQ machine_wins             // If push button 3 is not pressed, wait for it to be pressed

    B _start                     // If push button 3 is pressed, restart the game