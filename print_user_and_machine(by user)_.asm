.equ SEG_BASE, 0xFF200020   @ base address of the seven-segment display
.equ SWITCH_BASE, 0xFF200040 @ base address of the switches

.data
RPS:
    .word 0b01010000   @ r
    .word 0b01110011   @ P
    .word 0b01101101   @ S

.text
.global _start

_start:
    BL initialize
main_loop:
    BL read_user_input
    BL display_choices
    B main_loop

initialize:
    @ Set up initial display
    MOV r0, #0
    LDR r1, =SEG_BASE
    STR r0, [r1]              @ Clear the seven-segment
    BX lr

read_user_input:
    LDR r1, =SWITCH_BASE
    LDR r0, [r1]
    AND r0, r0, #0x7          @ Mask switches 0, 1, and 2 for user choice
    MOV r2, r0                @ Store user choice in r2
    LDR r0, [r1]
    AND r0, r0, #0x38         @ Mask switches 3, 4, and 5 for machine choice
    MOV r0, r0, LSR #3        @ Shift right to align machine choice
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
    CMP r0, #1
    BEQ display_r_machine
    CMP r0, #2
    BEQ display_P_machine
    CMP r0, #4
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
