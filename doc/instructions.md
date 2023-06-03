

### Basic instructions to implement

##### Arithmetic

###### ADD

syntax: ADD Rd Ra Rb

description: 

​	$Rd <= Ra + Rb$

###### ADDI

syntax: ADDI Rd Ra #Imm

description:

​	$R_d <= R_a + Imm$

###### SUB

syntax: SUB Rd Ra Rb

description: 

​	$R_d <= R_a - R_b$

###### SUBI

syntax: SUB Rd Ra #Imm

description: 

​	$R_d <= R_a - Imm$



##### Logic

###### AND

syntax: AND Rd Ra Rb

description:

​	$R_d <= R_a \& R_b$

###### ANDI

syntax: AND Rd Ra #Imm

description:

​	$R_d <= R_a \& Imm$

###### OR

syntax: AND Rd Ra Rb

description:

​	$R_d <= R_a | R_b$

###### ORI

syntax: AND Rd Ra #Imm

description:

​	$R_d <= R_a | Imm$

###### XOR

syntax: XOR Rd Ra Rb

description:

​	$R_d <= R_a \text{^} R_b$

###### XORI

syntax: XOR Rd Ra #Imm

description:

​	$R_d <= R_a \text{^} Imm$

###### NOT

Bitwise NOT operation is equivalent to XORI operation with 0.

So, it can be a pseudo instruction.

syntax: NOT Rd Ra

description:

​	$R_d <= \text{~} R_a$

but actually, it's alias to XORI Rd Ra #0 .



##### Shift

###### SL

syntax: SL Rd Ra Rb

description:

​	$R_d <= R_a << R_b$

###### SLI

syntax: SLI Rd Ra #Imm

description:

​	$R_d <= R_a << Imm$

###### SL

syntax: SL Rd Ra Rb

description:

​	$R_d <= R_a << R_b$

###### SLI

syntax: SLI Rd Ra #Imm

description:

​	$R_d <= R_a << Imm$

###### SR

syntax: SR Rd Ra Rb

description:

​	$R_d <= R_a >> R_b$

###### SRI

syntax: SRI Rd Ra #Imm

description:

​	$R_d <= R_a >> Imm$

###### SRA

syntax: SR Rd Ra Rb

description:

​	$R_d <= R_a >> R_b$

###### SRAI

syntax: SRAI Rd Ra #Imm

description:

​	$R_d <= R_a >> Imm$





##### Memory

Byte addressed, word accesses aligned on 4-byte boundaries, and half word accesses aligned on 2-byte boundaries.

Big endian.

###### LDW

syntax: LDW Rv [Ra] \#Imm << shift

description: 

​	$R_v <= word@[Ra + Imm<<shift]$

###### LDHW

syntax: LDW Rv [Ra] \#Imm << shift

description:

​	$R_v <= signExt(half word@[Ra + Imm<<shift])$

###### LDHWU

syntax: LDW Rv [Ra] \#Imm << shift

description:

​	$R_v <= \{16'b0,half word@[Ra + Imm<<shift]\}$

###### LDB

syntax: LDW Rv [Ra] \#Imm << shift

description:

​	$R_v <= signExt(byte@[Ra + Imm<<shift])$

###### LDBU

syntax: LDW Rv [Ra] \#Imm << shift

description:

​	$R_v <= \{24'b0,byte@[Ra + Imm<<shift]\}$



###### STW

syntax: STW Rv [Ra] #Imm << shift

description: $R_v => [Ra + Imm << shift]$

###### STHW

syntax: STW Rv [Ra] #Imm << shift

description: $R_v[15:0] => [Ra + Imm << shift]$

###### STB

syntax: STW Rv [Ra] #Imm << shift

description: $R_v[7:0] => [Ra + Imm << shift]$



##### Move

###### MOV

syntax: MOV Rd Rb

description:

​	$R_d <= R_b$

###### MOVIL

syntax: MOVIL Rd #Imm

description:

​	$R_d[15:0] <= Imm$

###### MOVIH

syntax: MOVIH Rd #Imm

description:

​	$R_d[31:16] <= Imm$



##### Branch & jump

###### BEQ

syntax: BEQ where

description:

​	$if\ (equal)\ then\\ PC <= PC + offset$

###### BNE

syntax: BNE where

description:

​	$if\ (not\ equal)\ then\\ PC <= PC + offset$

###### BGE

syntax: BGE where

description:

​	$if\ (greater\ or \ equal)\ then\\ PC <= PC + offset$

###### BLT

syntax: BLT where

description:

​	$if\ (less\ than)\ then\\ PC <= PC + offset$

###### J

syntax: J where

description:

​	$PC <= PC + offset$

###### JR

syntax: JR Ra

description:

​	$PC <= PC + R_a$

###### JL

syntax: JL Rd where

description:

​	$PC <= PC + offset \\ R_d <= PC + 4$

###### JLR

syntax: JLR Rd Ra #Imm

description:

​	$PC <= R_a + Imm \\ R_d <= PC + 4$

Note: in case the offset might be too large to be accommodated by an immediate number in the instruction, the compiler may insert a JR or JLR to relay... (to think over)



##### Misc.

###### NOP

syntax: NOP

description: no operation

###### HALT

syntax: HALT

description: halt the processor



### Encoding



##### Arithmetic operations with registers

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 4   | 3 - 0 |
| ------- | ------- | ------- | ------- | -------- | ----- |
| opcode  | $R_d$   | $R_a$   | ext     | reserved | $R_b$ |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| ADD   | 0100 00        | 10            |
| ADDU  | 0100 00        | 00            |
| SUB   | 0100 01        | 10            |
| SUBU  | 0100 01        | 00            |

ADD & ADDU give the same binary result output, however the flags (overflow, negative) are different.

SUB & SUBU case is similar.



##### Logical operations with registers

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 4   | 3 - 0 |
| ------- | ------- | ------- | ------- | -------- | ----- |
| opcode  | $R_d$   | $R_a$   | ext     | reserved | $R_b$ |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| AND   | 0101 00        | 00            |
| OR    | 0101 01        | 00            |
| XOR   | 0101 10        | 00            |



##### Shift operations with registers

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 4   | 3 - 0 |
| ------- | ------- | ------- | ------- | -------- | ----- |
| opcode  | $R_d$   | $R_a$   | ext     | reserved | $R_b$ |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| SL    | 0110 00        | 00            |
| SR    | 0110 01        | 00            |
| SRA   | 0110 01        | 10            |





##### Arithmetic operations with immediate

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 0 |
| ------- | ------- | ------- | ------- | ------ |
| opcode  | $R_d$   | $R_a$   | ext     | Imm    |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| ADDI  | 0100 00        | 11            |
| SUBI  | 0100 01        | 11            |



##### Logical operations with immediate

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 0 |
| ------- | ------- | ------- | ------- | ------ |
| opcode  | $R_d$   | $R_a$   | ext     | Imm    |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| ANDI  | 0101 00        | 01            |
| ORI   | 0101 01        | 01            |
| XORI  | 0101 10        | 01            |



##### Shift operations with immediate

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 5           | 4 - 0 |
| ------- | ------- | ------- | ------- | ---------------- | ----- |
| opcode  | $R_d$   | $R_a$   | ext     | 11'b0 (reserved) | Imm   |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| SLI   | 0110 00        | 01            |
| SRI   | 0110 01        | 01            |
| SRAI  | 0110 01        | 11            |
|       |                |               |



##### Move register

| 31 - 26 | 25 - 22 | 21 - 18        | 17 - 16 | 15 - 4          | 3 - 0 |
| ------- | ------- | -------------- | ------- | --------------- | ----- |
| opcode  | $R_d$   | reserved(4'b0) | ext     | reserved(12'b0) | $R_b$ |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| MOV   | 0001 11        | 00            |



##### Move immediate

| 31 - 26 | 25 - 22 | 21 - 18         | 17 - 16 | 15 - 0 |
| ------- | ------- | --------------- | ------- | ------ |
| opcode  | $R_d$   | reserved (4'b0) | ext     | Imm    |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| MOVIL | 0001 01        | 01            |
| MOVIH | 0001 10        | 01            |



##### Memory (load & store)

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 12 | 11 - 0 |
| ------- | ------- | ------- | ------- | ------- | ------ |
| opcode  | $R_v$   | $R_a$   | ext     | shift   | Imm    |



| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| LDBU  | 0010 00        | 01            |
| LDHWU | 0010 01        | 01            |
| LDW   | 0010 11        | 11            |
| LDB   | 0010 00        | 11            |
| LDHW  | 0010 01        | 11            |
| STB   | 0011 00        | 01            |
| STHW  | 0011 01        | 01            |
| STW   | 0011 11        | 01            |



###### op ext field

- ext[1] (bit 17): 1'b1 sign extend for half word/byte load; 1'b0 zero extend; set to 0 for other memory instructions

- ext[0] (bit 16):  set to 1'b1, reserved for future



##### Branch

| 31 - 26 | 25 - 22  | 21 - 18  | 17 - 16 | 15- 0 |
| ------- | -------- | -------- | ------- | ----- |
| opcode  | reserved | reserved | ext     | Imm   |

$offset = Imm << 2$

| instr | opcode 31 - 26 | op ext 17 -16 |
| ----- | -------------- | ------------- |
| BEQ   | 1001 00        | 11            |
| BNE   | 1001 11        | 11            |
| BGE   | 1001 10        | 11            |
| BLT   | 1001 01        | 11            |



##### Jump



###### J

| 31 - 26 | 25 - 22         | 21 - 18   | 17 - 16 | 15- 0 |
| ------- | --------------- | --------- | ------- | ----- |
| 1000 00 | reserved (4'b0) | Imm shift | 11      | Imm   |

$offset = Imm << shift << 2$



###### JR

| 31 - 26 | 25 - 22         | 21 - 18 | 17 - 16 | 15- 0            |
| ------- | --------------- | ------- | ------- | ---------------- |
| 1000 01 | reserved (4'b0) | $R_a$   | 10      | reserved (16'b0) |



###### JL

| 31 - 26 | 25 - 22 | 21 - 18   | 17 - 16 | 15- 0 |
| ------- | ------- | --------- | ------- | ----- |
| 1000 10 | $R_d$   | Imm shift | 11      | Imm   |

$offset = Imm << shift << 2$



###### JLR

| 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15- 0 |
| ------- | ------- | ------- | ------- | ----- |
| 1000 11 | $R_d$   | $R_a$   | 11      | Imm   |

$offset = Imm << 2$



##### Format sum up



|      | 31 - 26 | 25 - 22  | 21 - 18         | 17 - 16 | 15- 0    | Instructions                |
| ---- | ------- | -------- | --------------- | ------- | -------- | --------------------------- |
| RRI  | opcode  | $R_d$    | $R_a$           | op ext  | Imm      | ADDI, SUBI, ANDI, ORI, XORI |
| RR_  | opcode  | $R_d$    | $R_a$           | op ext  | reserved | legacy MOV, no more used    |
| R_I  | opcode  | $R_d$    | reserved (4'b0) | op ext  | Imm      | MOVIL, MOVIH                |
| _RI  | opcode  | reserved | $R_a$           | op ext  | reserved | JR                          |
| __I  | opcode  | reserved | reserved        | op ext  | Imm      | BEQ, BNE, BGE, BLT          |
| RSI  | opcode  | $R_d$    | shift           | op ext. | Imm      | J, JL                       |

##### 

|      | 31 - 26 | 25 - 22 | 21 - 18        | 17 - 16 | 15 - 4          | 3 - 0 | Instructions                              |
| ---- | ------- | ------- | -------------- | ------- | --------------- | ----- | ----------------------------------------- |
| RRR  | opcode  | $R_d$   | $R_a$          | ext     | reserved        | $R_b$ | ADD(U), SUB(U), AND, OR, XOR, SL, SR, SRA |
| R_R  | opcode  | $R_d$   | reserved(4'b0) | ext     | reserved(12'b0) | $R_b$ | MOV                                       |

|      | 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 5   | 4 - 0 | Instructions   |
| ---- | ------- | ------- | ------- | ------- | -------- | ----- | -------------- |
| RR_i | opcode  | $R_d$   | $R_a$   | opext   | reserved | Imm   | SLI, SRI, SRAI |

##### 

|      | 31 - 26 | 25 - 22 | 21 - 18 | 17 - 16 | 15 - 12 | 11 - 0 | Instructions                         |
| ---- | ------- | ------- | ------- | ------- | ------- | ------ | ------------------------------------ |
| RRSI | opcode  | $R_v$   | $R_a$   | opext   | shift   | Imm    | LDW, LDHW(U), LDB(U), STW, STHW, STB |

