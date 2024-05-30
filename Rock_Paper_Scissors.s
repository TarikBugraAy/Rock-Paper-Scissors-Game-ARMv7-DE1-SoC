.equ SEG_BASE, 0xFF200020    @ base address of the seven-segment display
.equ SWITCH_BASE, 0xFF200040 @ base address of the switches
.equ TIMER_BASE, 0xFFFEC600  @ base address of the private timer
.equ TIMER_LOAD, 0xFFFEC604  @ timer load register
.equ TIMER_CONTROL, 0xFFFEC608 @ timer control register
.equ TIMER_INTCLR, 0xFFFEC60C @ timer interrupt clear register
.equ TIMER_VALUE, 0xFFFEC60C @ timer value register
.equ BUTTON_BASE, 0xFF200050 @ base address of the push buttons

.data
RPS:
    .word 0b01010000   @ r
    .word 0b01110011   @ P
    .word 0b01101101   @ S

.text
.global _start

_start:
    BL initialize
    BL initialize_timer
main_loop:
    BL read_user_input
    LDR r1, =BUTTON_BASE        @ Base address for push buttons
    LDR r0, [r1]
    AND r0, r0, #0x1           @ Check if push button 0 is pressed
    CMP r0, #0
    BEQ check_next_round
    BL get_timer_value
    BL display_choices
    BL update_scores
    B main_loop

check_next_round:
    LDR r1, =BUTTON_BASE
    LDR r0, [r1]
    AND r0, r0, #0x2           @ Check if push button 1 is pressed
    CMP r0, #0
    BEQ check_restart
    BL read_user_input
    BL display_choices
    B main_loop

check_restart:
    LDR r1, =BUTTON_BASE
    LDR r0, [r1]
    AND r0, r0, #0x4           @ Check if push button 2 is pressed
    CMP r0, #0
    BEQ main_loop
    BL restart_game
    B main_loop

initialize:
    @ Set up initial display and initialize scores
    PUSH {r4, r5, r6, lr}
    MOV r0, #0
    LDR r1, =SEG_BASE
    STR r0, [r1]               @ Clear the seven-segment display
    MOV r2, #0                 @ Initialize user score
    MOV r3, #0                 @ Initialize machine score
    POP {r4, r5, r6, lr}
    BX lr

initialize_timer:
    PUSH {r4, lr}
    LDR r1, =TIMER_BASE
    LDR r0, =0xFFFFFFFF        @ Load maximum value to timer
    STR r0, [r1, #0x04]
    MOV r0, #0x7               @ Enable timer, periodic mode, and interrupt
    STR r0, [r1, #0x08]
    POP {r4, lr}
    BX lr

read_user_input:
    PUSH {r4, lr}
    LDR r1, =SWITCH_BASE
    LDR r0, [r1]
    AND r0, r0, #0x7           @ Mask switches 0, 1, and 2 for user choice
    MOV r4, r0                @ Store user choice in r4
    POP {r4, lr}
    BX lr

get_timer_value:
    PUSH {r4, lr}
    LDR r1, =TIMER_VALUE
    LDR r0, [r1]               @ Read current timer value
    AND r0, r0, #0xF           @ Mask to get last four bits (values 0 to 15)
    CMP r0, #5
    BLT choose_rock
    CMP r0, #10
    BLT choose_paper
    CMP r0, #15
    BLT choose_scissors
    B get_timer_value          @ Read again to avoid bias if not in range

choose_rock:
    MOV r5, #0                 @ Machine chooses rock
    POP {r4, lr}
    BX lr

choose_paper:
    MOV r5, #1                 @ Machine chooses paper
    POP {r4, lr}
    BX lr

choose_scissors:
    MOV r5, #2                 @ Machine chooses scissors
    POP {r4, lr}
    BX lr

display_choices:
    PUSH {r4, r5, r6, r7, lr}  @ Save registers
    LDR r3, =RPS
    @ Display user choice
    CMP r4, #1
    BEQ display_r_user
    CMP r4, #2
    BEQ display_P_user
    CMP r4, #4
    BEQ display_S_user
    B clear_display_user

display_r_user:
    LDR r6, [r3]              @ Load 'r' for user
    B display_machine_choice

display_P_user:
    LDR r6, [r3, #4]          @ Load 'P' for user
    B display_machine_choice

display_S_user:
    LDR r6, [r3, #8]          @ Load 'S' for user
    B display_machine_choice

clear_display_user:
    MOV r6, #0                @ Clear display
    B display_machine_choice

display_machine_choice:
    @ Display machine choice
    CMP r5, #0
    BEQ display_r_machine
    CMP r5, #1
    BEQ display_P_machine
    CMP r5, #2
    BEQ display_S_machine
    B clear_display_machine

display_r_machine:
    LDR r7, [r3]              @ Load 'r' for machine
    B combine_and_display

display_P_machine:
    LDR r7, [r3, #4]          @ Load 'P' for machine
    B combine_and_display

display_S_machine:
    LDR r7, [r3, #8]          @ Load 'S' for machine
    B combine_and_display

clear_display_machine:
    MOV r7, #0                @ Clear display
    B combine_and_display

combine_and_display:
    LDR r1, =SEG_BASE
    MOV r0, #0
    ORR r0, r0, r6            @ Combine user choice (low byte)
    ORR r0, r0, r7, LSL #8    @ Combine machine choice (high byte)
    STR r0, [r1]              @ Write combined value to seven-segment display
    POP {r4, r5, r6, r7, lr}  @ Restore registers
    BX lr

update_scores:
    PUSH {r4, r5, r6, lr}     @ Save registers
    @ Update the scores based on user and machine choices
    CMP r4, r5                @ Compare choices
    BEQ no_score              @ If equal, no score update
    CMP r4, #1                @ User chose rock
    BEQ user_rock
    CMP r4, #2                @ User chose paper
    BEQ user_paper
    CMP r4, #4                @ User chose scissors
    BEQ user_scissors
    B no_score

user_rock:
    CMP r5, #1                @ Machine chose paper
    BEQ machine_wins
    CMP r5, #2                @ Machine chose scissors
    BEQ user_wins
    B no_score

user_paper:
    CMP r5, #0                @ Machine chose rock
    BEQ user_wins
    CMP r5, #2                @ Machine chose scissors
    BEQ machine_wins
    B no_score

user_scissors:
    CMP r5, #0                @ Machine chose rock
    BEQ machine_wins
    CMP r5, #1                @ Machine chose paper
    BEQ user_wins
    B no_score

user_wins:
    ADD r2, r2, #1            @ Increment user score
    BL display_scores
    B no_score

machine_wins:
    ADD r3, r3, #1            @ Increment machine score
    BL display_scores
    B no_score

display_scores:
    PUSH {r0, r1, r2, r3}     @ Save registers
    LDR r1, =SEG_BASE
    MOV r0, #0
    ORR r0, r0, r2, LSL #16   @ User score in HEX2 and HEX3
    ORR r0, r0, r3, LSL #24   @ Machine score in HEX4 and HEX5
    STR r0, [r1, #0x04]       @ Write scores to seven-segment display
    POP {r0, r1, r2, r3}      @ Restore registers
    POP {r4, r5, r6, lr}
    BX lr

no_score:
    POP {r4, r5, r6, lr}
    BX lr

restart_game:
    PUSH {r4, r5, r6, lr}
    @ Clear scores and reset display
    MOV r2, #0                @ Clear user score
    MOV r3, #0                @ Clear machine score
    BL display_scores         @ Update display with cleared scores
    POP {r4, r5, r6, lr}
    BX lr
