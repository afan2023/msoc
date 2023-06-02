/**
 * instruction format definitions
 */


`define  INSTR_FIELD_OPCODE   31:26
`define  INSTR_FIELD_OPEXT    17:16
`define  INSTR_FIELD_RD       25:22
`define  INSTR_FIELD_RA       21:18
`define  INSTR_FIELD_RB       3:0   

`define  INSTR_OPCAT_ADDSUB   4'b0100
`define  INSTR_OPCAT_LOGIC    4'b0101
`define  INSTR_OPCAT_SHIFT    4'b0110
`define  INSTR_OPCAT_MOVE     4'b0001
`define  INSTR_OPCAT_LD       4'b0010
`define  INSTR_OPCAT_ST       4'b0011
`define  INSTR_OPCAT_B        4'b1000
`define  INSTR_OPCAT_J        4'b1001

 
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

`define  OPCODE_NOP     6'b000000