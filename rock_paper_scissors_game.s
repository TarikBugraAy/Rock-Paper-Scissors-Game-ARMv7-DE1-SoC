.equ SEG_BASE, 0xFF200020    // base address of the seven-segment display
.equ SEG_BASE_2, 0xFF200030  // For HEX4 and HEX5
.equ SWITCH_BASE, 0xFF200040 // base address of the switches
.equ TIMER_BASE, 0xFFFEC600  // base address of the private timer and load register
.equ TIMER_VALUE, 0xFFFEC604  // timer current value
.equ TIMER_CONTROL, 0xFFFEC608 // timer control register


.data
RPS:
    .word 0b01010000   // r
    .word 0b01110011   // P
    .word 0b01101101   // S
WINNER:
    .word 0b00111110   //User wins
    .word 0b01010101   //Machine wins
HEXTABLE:
    .word 0b00111111   // 0
    .word 0b00000110   // 1
    .word 0b01011011   // 2
    .word 0b01001111   // 3
    .word 0b01100110   // 4
    .word 0b01101101   // 5
    .word 0b01111101   // 6
    .word 0b00000111   // 7
    .word 0b01111111   // 8
    .word 0b01101111   // 9

scoreuser:
    .word 0
scoremachine:
    .word 0

user_choice:
    .word 0
machine_choice:
    .word 0

.text
.global _start

_start:
    BL initialize
    BL initialize_timer
main_loop:
    BL read_user_input      // Read user input from switches
    LDR r1, =0xFF200050     // Base address for push buttons
    LDR r0, [r1]
    AND r0, r0, #0x1        // Check if push button 0 is pressed
    CMP r0, #0
    BEQ main_loop           // If push button 0 is not pressed, continue playing
    BL get_timer_value      // Get timer value to decide machine choice
    BL display_choices      // Display user and machine choices
    BL decide_winner        // Decide winner based on user and machine choices
    BL display_score        // Display user and machine scores
    BL game_winner          // Check if there is a winner
    BL wait_for_next_round  // Wait for push button 1 to continue playing or push button 2 to reset
    B main_loop             // Continue playing

initialize:
    // Set up initial display
    MOV r0, #0
    LDR r2, =HEXTABLE
    LDR r2, [r2, r0, LSL #2]
    LDR r1, =SEG_BASE_2
    ORR r0, r0, r2, LSL #8
    ORR r0, r0, r2
    STR r0, [r1]
	LDR r1, =SEG_BASE
	LDR r2, =0b00001000
	MOV r0, #0
	ORR r0,r0,r2, LSL #8
	ORR r0,r0,r2
	STR r0, [r1]
    BX lr

initialize_timer:
    LDR r1, =TIMER_BASE
    LDR r0, =0xFFFFFFFF       // Load maximum value for timer
    STR r0, [r1]
    MOV r0, #3
    LDR r1, =TIMER_CONTROL
    STR r0, [r1]              // Enable and auto-reload timer
    BX lr

read_user_input:
    PUSH {r4, lr}
    LDR r1, =SWITCH_BASE
    LDR r0, [r1]
    AND r0, r0, #0x7         // Mask switches 0, 1, and 2 for user choice
    MOV r2, r0               // Store user choice in r2
    LDR r1, =user_choice
    STR r2, [r1]             // Store user choice in memory
    POP {r4, lr}
    BX lr

get_timer_value:
    PUSH {r4, lr}
    LDR r1, =TIMER_VALUE
    LDR r0, [r1]              // Read current timer value
    AND r0, r0, #0xF          // Mask to get last four bits (values 0 to 15)
    CMP r0, #5
    BLT choose_rock
    CMP r0, #10
    BLT choose_paper
    CMP r0, #15
    BLT choose_scissors
    B get_timer_value         // Read again to avoid bias if not in range

choose_rock:
    MOV r0, #0
    LDR r1, =machine_choice
    STR r0, [r1]               // Store machine choice in memory
    POP {r4, lr}
    BX lr

choose_paper:
    MOV r0, #1
    LDR r1, =machine_choice
    STR r0, [r1]               // Store machine choice in memory
    POP {r4, lr}
    BX lr

choose_scissors:
    MOV r0, #2
    LDR r1, =machine_choice
    STR r0, [r1]               // Store machine choice in memory
    POP {r4, lr}
    BX lr

display_choices:
    PUSH {r4, r5, lr}          // Save r4, r5, and lr
    LDR r1, =user_choice
    LDR r2, [r1]               // Load user choice from memory
    LDR r3, =RPS
    // Display user choice
    CMP r2, #1
    BEQ display_r_user
    CMP r2, #2
    BEQ display_P_user
    CMP r2, #4
    BEQ display_S_user
    B clear_display_user

display_r_user:
    LDR r4, [r3]              // Load 'R' for user
    B display_machine_choice

display_P_user:
    LDR r4, [r3, #4]          // Load 'P' for user
    B display_machine_choice

display_S_user:
    LDR r4, [r3, #8]          // Load 'S' for user
    B display_machine_choice

clear_display_user:
    MOV r4, #0                // Clear display
    B display_machine_choice

display_machine_choice:
    LDR r1, =machine_choice
    LDR r0, [r1]               // Load machine choice from memory
    @ Display machine choice
    CMP r0, #0
    BEQ display_r_machine
    CMP r0, #1
    BEQ display_P_machine
    CMP r0, #2
    BEQ display_S_machine
    B clear_display_machine

display_r_machine:
    LDR r5, [r3]              // Load 'R' for machine
    B combine_and_display

display_P_machine:
    LDR r5, [r3, #4]          // Load 'P' for machine
    B combine_and_display

display_S_machine:
    LDR r5, [r3, #8]          // Load 'S' for machine
    B combine_and_display

clear_display_machine:
    MOV r5, #0                // Clear display
    B combine_and_display

combine_and_display:
    LDR r1, =SEG_BASE
    MOV r0, #0
    ORR r0, r0, r4            // Combine user choice
    ORR r0, r0, r5, LSL #8    // Combine machine choice
    STR r0, [r1]              // Write combined value to seven-segment display
    POP {r4, r5, lr}          // Restore r4, r5, and lr
    BX lr

decide_winner:
    PUSH {r4, r5, lr}     // Save r4, r5, and lr

    LDR r1, =user_choice
    LDR r2, [r1]          // Load user choice from memory
    CMP r2, #1
    BEQ user_rock         // Check user choice for rock
    CMP r2, #2
    BEQ user_paper        // Check user choice for paper
    CMP r2, #4
    BEQ user_scissors     // Check user choice for scissors
    B user_not_playing    // Next round if user does not play

user_rock:
    MOV r4, #0
    STR r4, [r1]          // Store user choice in memory
    B compare_choices     // Compare user and machine choices
user_paper:
    MOV r4, #1
    STR r4, [r1]          // Store user choice in memory
    B compare_choices     // Compare user and machine choices
user_scissors:
    MOV r4, #2
    STR r4, [r1]          // Store user choice in memory
    B compare_choices     // Compare user and machine choices

user_not_playing:
    POP {r4, r5, lr}      // Restore r4, r5, and lr
    BX lr                 // Return

compare_choices:
    LDR r1, =machine_choice
    LDR r0, [r1]            // Load machine choice from memory
    CMP r4, #0
    BEQ rock                // Check user choice for rock
    CMP r4, #1
    BEQ paper               // Check user choice for paper
    CMP r4, #2
    BEQ scissors            // Check user choice for scissors

rock:                       // User choice is rock
    CMP r0, #0
    BEQ tie                 // Check machine choice for rock
    CMP r0, #1
    BEQ machine_score       // Check machine choice for paper
    CMP r0, #2
    BEQ user_score          // Check machine choice for scissors

paper:                      // User choice is paper
    CMP r0, #0
    BEQ user_score          // Check machine choice for rock
    CMP r0, #1
    BEQ tie                 // Check machine choice for paper
    CMP r0, #2
    BEQ machine_score       // Check machine choice for scissors

scissors:                   // User choice is scissors
    CMP r0, #0
    BEQ machine_score       // Check machine choice for rock
    CMP r0, #1
    BEQ user_score          // Check machine choice for paper
    CMP r0, #2
    BEQ tie                 // Check machine choice for scissors

tie:                       // Tie
    POP {r4, r5, lr}
    BX lr

machine_score:            // Machine wins round
    LDR r1, =scoremachine
    LDR r0, [r1]
    ADD r0, r0, #1
    STR r0, [r1]
    POP {r4, r5, lr}
    BX lr

user_score:              // User wins round
    LDR r1, =scoreuser
    LDR r0, [r1]
    ADD r0, r0, #1
    STR r0, [r1]
    POP {r4, r5, lr}
    BX lr

display_score:                // Display user and machine scores
    PUSH {r4, r5, lr}

    // Select user score
    LDR r1, =scoreuser
    LDR r0, [r1]
    LDR r2, =HEXTABLE
    LDR r4, [r2, r0, LSL #2]  // Load user score from HEXTABLE

    // Select machine score
    LDR r1, =scoremachine
    LDR r0, [r1]
    LDR r2, =HEXTABLE
    LDR r5, [r2, r0, LSL #2]  // Load machine score from HEXTABLE

    // Combine and display scores
    LDR r1, =SEG_BASE_2
    MOV r0, #0
    ORR r0, r0, r4            // Combine user score
    ORR r0, r0, r5, LSL #8    // Combine machine score
    STR r0, [r1]              // Write combined value to seven-segment display

    POP {r4, r5, lr}
    BX lr                     // Return

wait_for_next_round:
    // Wait until push button 1 is pressed or reset if push button 2 is pressed
    LDR r1, =0xFF200050       // Base address for push buttons
wait_loop:
    LDR r0, [r1]
    AND r0, r0, #0x2          // Check if push button 1 is pressed
    CMP r0, #0x2
    BEQ continue_execution    // If push button 1 is pressed, continue playing
    LDR r2, [r1]
    AND r2, r2, #0x4          // Check if push button 2 is pressed
    CMP r2, #0x4
    BEQ reset_handler        // If push button 2 is pressed, reset game

    B wait_loop

continue_execution:
    BX lr                    // Return

reset_handler:

    LDR r1, =scoreuser
    MOV r0, #0
    STR r0, [r1]               // Reset user score
    LDR r1, =scoremachine
    STR r0, [r1]               // Reset machine score
    B initialize

game_winner:               // Check if there is a winner
    LDR r1, =scoreuser
    LDR r0, [r1]
    MOV r3, #3
    CMP r0, r3
    BEQ user_wins         // If user score is 3, user wins
    LDR r1, =scoremachine
    LDR r0, [r1]
    CMP r0, r3
    BEQ machine_wins      // If machine score is 3, machine wins
    B no_winner           // If no winner, continue playing

no_winner:

    BX lr                // Return

user_wins:
    LDR r1, =WINNER
    LDR r0, [r1]
    LDR r1, =SEG_BASE
    LDR r2, [r1]
    ORR r2, r2, r0, LSL #16    // Combine user wins to display
    STR r2, [r1]               // Write user wins to seven-segment display
    LDR r1, =scoreuser
    MOV r0, #0
    STR r0, [r1]               // Reset user score
    LDR r1, =scoremachine
    STR r0, [r1]               // Reset machine score
    LDR r1, =0xFF200050        // Base address for push buttons
    LDR r0, [r1]
    AND r0, r0, #0x8           // Check if push button 3 is pressed
    CMP r0, #0
    BEQ user_wins              // If push button 3 is not pressed, wait for it to be pressed

    B _start                   // Restart game

machine_wins:
    LDR r1, =WINNER
    LDR r0, [r1, #4]
    LDR r1, =SEG_BASE
    LDR r2, [r1]
    ORR r2, r2, r0, LSL #16    // Combine machine wins to display
    STR r2, [r1]               // Write machine wins to seven-segment display
    LDR r1, =scoreuser
    MOV r0, #0
    STR r0, [r1]               // Reset user score
    LDR r1, =scoremachine
    STR r0, [r1]               // Reset machine score
    LDR r1, =0xFF200050        // Base address for push buttons
    LDR r0, [r1]
    AND r0, r0, #0x8           // Check if push button 3 is pressed
    CMP r0, #0
    BEQ machine_wins          // If push button 3 is not pressed, wait for it to be pressed

    B _start                  // Restart game