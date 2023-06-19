@ sp
MOVIH R12 #0
MOVIL R12 #0x0200
@ a
MOVIH R8 #0
MOVIL R8 #0x100
@ b
MOVIH R9 #0
MOVIL R9 #0x120
@ c
MOVIH R10 #0
MOVIL R10 #0x140
@ s
MOVIH R11 #0
MOVIL R11 #0x158

@initialize a
MOVIH R0 #0
MOVIL R0 #0
MOVIH R4 #0
MOVIL R4 #0
MOVIH R5 #0
MOVIL R5 #5
MOV R6 R8
SUB R7 R4 R5
BEQ #0x6 @ offset = 0x6<<2 = 0x18 = 24
ADDI R0 R0 #1
STW R0 [R6] #0<<0
ADDI R6 R6 #4
ADDI R4 R4 #1
J #-0x6<<0 @ offset = -0x6<<0<<2 = - 0x18 = -24

@initialize b
MOVIH R0 #0
MOVIL R0 #0
MOVIH R4 #0
MOVIL R4 #1
MOVIH R5 #0
MOVIL R5 #5
MOV R6 R9
SUB R1 R5 R4
BLT #0x6 @ offset = 0x18 = 24
ADDI R0 R0 #2
STW R0 [R6] #0<<0
ADDI R6 R6 #4
ADDI R4 R4 #1
J #-0x6<<0

@call sum

MOV R0 R10
MOV R1 R8
MOV R2 R9
MOVIH R3 #0
MOVIL R3 #5
JL R15 #0xa<<0 @ @array addition, offset = a<<2

MOV R0 R10
MOVIH R1 #0
MOVIL R1 #5
JL R15 #0x18<<0 @sum, offset = 0x18<<2

STW R0 [R11] #0<<0
NOP
JL R15 #0x22<<0 @print char, offset = 0x22<<2
NOP

J #0<<0 @ stop!

@array addition
ADDI R12 R12 #-4
STW R0 [R12] #0<<0
MOVIH R4 #0
MOVIL R4 #0
SUB R5 R4 R3
BGE #0xa @ offset = 0xa<<2 = 0x28 = 40
LDW R6 [R1] #0<<0
ADDI R1 R1 #4
LDW R7 [R2] #0<<0
ADDI R2 R2 #4
ADD R5 R6 R7
STW R5 [R0] #0<<0
ADDI R0 R0 #4
ADDI R4 R4 #1
J #-0xa<<0 @ offset = - 0x28 = -40
LDW R0 [R12] #0<<0
ADDI R12 R12 #4
JLR R15 R15 #0

@sum
MOV R2 R0
MOVIH R0 #0
MOVIL R0 #0
MOVIH R3 #0
MOVIL R3 #0
SUB R4 R3 R1
BGE #0x6 @ offset = 0x6<<2 = 0x18 = 24
LDW R5 [R2] #0<<0
ADDI R2 R2 #4
ADD R0 R0 R5
ADDI R3 R3 #1
J #-0x6<<0 @ offset = -0x18 = -24
JLR R15 R15 #0

@print char
MOVIH R2 #0xffff
MOVIL R2 #0x0100
LDBU R1 [R2] #1<<2 @ status register
@ check writable bit
@ maybe worth creating another instruction
ANDI R1 R1 #0x10
SUBI R1 R1 #0x10
BNE #-3 @ keep check till writable
STB R0 [R2] #2<<2 @ TX register
JLR R15 R15 #0
