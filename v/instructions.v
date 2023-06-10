//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, c.fan                                                      
//                                                                                
// Redistribution and use in source and binary forms, with or without             
// modification, are permitted provided that the following conditions are met:    
//                                                                                
// 1. Redistributions of source code must retain the above copyright notice, this 
//    list of conditions and the following disclaimer.                            
//                                                                                
// 2. Redistributions in binary form must reproduce the above copyright notice,   
//    this list of conditions and the following disclaimer in the documentation   
//    and/or other materials provided with the distribution.                      
//                                                                                
// 3. Neither the name of the copyright holder nor the names of its               
//    contributors may be used to endorse or promote products derived from        
//    this software without specific prior written permission.                    
//                                                                                
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"    
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE      
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE   
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL     
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR     
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER     
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.           
//////////////////////////////////////////////////////////////////////////////////


/**
 * instruction format definitions
 */


`define  INSTR_FIELD_OPCODE   31:26
`define  INSTR_FIELD_OPEXT    17:16
`define  INSTR_FIELD_RD       25:22
`define  INSTR_FIELD_RA       21:18
`define  INSTR_FIELD_RB       3:0   
`define  INSTR_FIELD_OPCAT    31:28

`define  INSTR_OPCAT_ADDSUB   4'b0100
`define  INSTR_OPCAT_LOGIC    4'b0101
`define  INSTR_OPCAT_SHIFT    4'b0110
`define  INSTR_OPCAT_MOVE     4'b0001
`define  INSTR_OPCAT_LD       4'b0010
`define  INSTR_OPCAT_ST       4'b0011
`define  INSTR_OPCAT_B        4'b1001
`define  INSTR_OPCAT_J        4'b1000

 
`define  IMM_RULE_I16   3'b001  // least 16 bits, normal imm
`define  IMM_RULE_I5    3'b000  // least 5 bits, shift operation imm
`define  IMM_RULE_I12S4 3'b010  // load store offset, 4'shift - 12'imm
// `define  IMM_RULE_MOFF  3'b010  // load store offset, 4'shift - 12'imm
`define  IMM_RULE_I16S4S2  3'b111  // shifted immediate for jump/branch, 16'imm << 4'shift << 2
`define  IMM_RULE_I16S2 3'b101  // branch offset, imm << 2
`define  IMM_RULE_NONE  3'b100


`define  OPCODE_ADD     6'b010000
`define  OPCODE_SUB     6'b010001

`define  OPCODE_AND     6'b010100
`define  OPCODE_OR      6'b010101
`define  OPCODE_XOR     6'b010110

`define  OPCODE_SL      6'b011000
`define  OPCODE_SR      6'b011001
`define  OPCODE_SRA     6'b011011

`define  OPCODE_MOV     6'b000100
`define  OPCODE_MOVIL   6'b000101
`define  OPCODE_MOVIH   6'b000110

`define  OPCODE_LDBU    6'b001000
`define  OPCODE_LDHWU   6'b001001
`define  OPCODE_LDW     6'b001011
`define  OPCODE_LDB     6'b001000
`define  OPCODE_LDHW    6'b001001
`define  OPCODE_STB     6'b001100
`define  OPCODE_STHW    6'b001101
`define  OPCODE_STW     6'b001111

`define  OPCODE_BEQ     6'b100100
`define  OPCODE_BNE     6'b100111
`define  OPCODE_BGE     6'b100110
`define  OPCODE_BLT     6'b100101
`define  OPCODE_J       6'b100000
`define  OPCODE_JR      6'b100001
`define  OPCODE_JL      6'b100010
`define  OPCODE_JLR     6'b100011

`define  OPCODE_NOP     6'b000000