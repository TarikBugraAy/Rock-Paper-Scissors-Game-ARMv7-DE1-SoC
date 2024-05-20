.equ SW_BASE, 0xFF200040       // Base address of the switches
.equ HEX_BASE, 0xFF200020      // Base address of the seven-segment display

.global _start

_start:
    // Initialize scores
    LDR R0, =UserScore
    MOV R1, #0
    STR R1, [R0]
    LDR R0, =MachineScore
    STR R1, [R0]


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

RPS:
    .word 0b01010000   // r
    .word 0b01110011   // P
    .word 0b01101101   // S

UserScore:
    .word 0

MachineScore:
    .word 0

