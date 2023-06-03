MOVIH R1 #0
MOVIL R1 #100 @ base address 0x00000100
MOVIH R5 #123
MOVIL R5 #789 @ data value
STW R5 [R1] #0<<0
MOVIH R5 #789
MOVIL R5 #123
STW R5 [R1] #1<<2
LDW R6 [R1] #0<<2
ADD R7 R5 R6 @ add the two numbers
STW R7 [R1] #2<<2 @ store
NOP
MOV R12 R1
ADDI R1 R1 #100
STB R6 [R1] #0<<2    @ R6 = 0x01230789, @200 <= 89
STHW R6 [R1] #1<<2   @ @204,205 <= 0789
STW R6 [R1] #2<<2    @ @208,209,20a,20b <= 01230789
LDW R8 [R1] #0<<2    @ R8 <= 89xxxxxx
LDHWU R9 [R1] #1<<2  @ R9 <= 0789
LDBU R10 [R1] #2<<2  @ R10 <= 01
NOP
LDB R0 [R12] #0<<0 @ load mem to have a look, mem@100=0x01230789
LDB R1 [R12] #3<<0   @ mem@100=0x01230789, R1<=ffffff89
LDHW R2 [R12] #4<<0  @ mem@104=0x07890123, R2<=00000789
LDW R3 [R12] #8<<0   @ mem@108=0x08ac08ac, R3<=08ac08ac
NOP