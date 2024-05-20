.equ SEG_BASE, 0xFF200020   @ Replace with actual base address of the seven-segment display
.equ SWITCH_BASE, 0xFF200040 @ Replace with actual base address of the switches

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
    BL display_choice
    B main_loop

initialize:
    @ Set up initial display
    MOV r0, #0
    LDR r1, =SEG_BASE
    STR r0, [r1]              @ Clear the seven-segment display
    BX lr

read_user_input:
    LDR r1, =SWITCH_BASE
    LDR r0, [r1]
    AND r0, r0, #0x7          @ Mask switches 0, 1, and 2
    BX lr

display_choice:
    LDR r1, =RPS
    CMP r0, #1
    BEQ display_r
    CMP r0, #2
    BEQ display_P
    CMP r0, #4
    BEQ display_S
    B clear_display

display_r:
    LDR r0, [r1]              @ Load 'r'
    B write_display

display_P:
    LDR r0, [r1, #4]          @ Load 'P'
    B write_display

display_S:
    LDR r0, [r1, #8]          @ Load 'S'
    B write_display

clear_display:
    MOV r0, #0                @ Clear display
    B write_display

write_display:
    LDR r1, =SEG_BASE
    STR r0, [r1]              @ Write to seven-segment display
    BX lr
