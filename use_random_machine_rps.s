.equ SEG_BASE, 0xFF200020    @ base address of the seven-segment display
.equ SEG_BASE_2, 0xFF200030  @ For HEX4 and HEX5
.equ SWITCH_BASE, 0xFF200040 @ base address of the switches
.equ TIMER_BASE, 0xFFFEC600  @ base address of the private timer
.equ TIMER_LOAD, 0xFFFEC604  @ timer load register
.equ TIMER_CONTROL, 0xFFFEC608 @ timer control register
.equ TIMER_INTCLR, 0xFFFEC60C @ timer interrupt clear register
.equ TIMER_VALUE, 0xFFFEC60C @ timer value register

.data
RPS:
    .word 0b01010000   @ r
    .word 0b01110011   @ P
    .word 0b01101101   @ S
WINNER:
    .word 0b00111110   @User wins
    .word 0b01010101   @Machine wins
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
.text
.global _start

_start:
    BL initialize
    BL initialize_timer
main_loop:
    BL read_user_input
    LDR r1, =0xFF200050        @ Base address for push buttons
    LDR r0, [r1]
    AND r0, r0, #0x1           @ Check if push button 0 is pressed
    CMP r0, #0
    BEQ main_loop
    BL get_timer_value
    BL display_choices
    B main_loop

initialize:
    @ Set up initial display
    MOV r0, #0
    LDR r1, =SEG_BASE
    STR r0, [r1]               @ Clear the seven-segment
    BX lr

initialize_timer:
    LDR r1, =TIMER_BASE
    LDR r0, =0xFFFFFFFF        @ Load maximum value to timer
    STR r0, [r1, #0x04]
    MOV r0, #0x7               @ Enable timer, periodic mode, and interrupt
    STR r0, [r1, #0x08]
    BX lr

read_user_input:
    LDR r1, =SWITCH_BASE
    LDR r0, [r1]
    AND r0, r0, #0x7           @ Mask switches 0, 1, and 2 for user choice
    MOV r2, r0                @ Store user choice in r2
    BX lr

get_timer_value:
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
    MOV r0, #0
    BX lr

choose_paper:
    MOV r0, #1
    BX lr

choose_scissors:
    MOV r0, #2
    BX lr

display_choices:
    PUSH {r4, r5}             @ Save r4 and r5
    LDR r3, =RPS
    @ Display user choice
    CMP r2, #1
    BEQ display_r_user
    CMP r2, #2
    BEQ display_P_user
    CMP r2, #4
    BEQ display_S_user
    B clear_display_user

display_r_user:
    LDR r4, [r3]              @ Load 'r' for user
    B display_machine_choice

display_P_user:
    LDR r4, [r3, #4]          @ Load 'P' for user
    B display_machine_choice

display_S_user:
    LDR r4, [r3, #8]          @ Load 'S' for user
    B display_machine_choice

clear_display_user:
    MOV r4, #0                @ Clear display
    B display_machine_choice

display_machine_choice:
    @ Display machine choice
    CMP r0, #0
    BEQ display_r_machine
    CMP r0, #1
    BEQ display_P_machine
    CMP r0, #2
    BEQ display_S_machine
    B clear_display_machine

display_r_machine:
    LDR r5, [r3]              @ Load 'r' for machine
    B combine_and_display

display_P_machine:
    LDR r5, [r3, #4]          @ Load 'P' for machine
    B combine_and_display

display_S_machine:
    LDR r5, [r3, #8]          @ Load 'S' for machine
    B combine_and_display

clear_display_machine:
    MOV r5, #0                @ Clear display
    B combine_and_display

combine_and_display:
    LDR r1, =SEG_BASE
    MOV r0, #0
    ORR r0, r0, r4            @ Combine user choice (low byte)
    ORR r0, r0, r5, LSL #8    @ Combine machine choice (high byte)
    STR r0, [r1]              @ Write combined value to seven-segment display
    POP {r4, r5}              @ Restore r4 and r5
    BX lr