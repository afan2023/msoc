/**
 * write back mux
 * -- combination logic version (instant data selection)
 *
 * the logic here is quite straight forward with very simple circuit
 */ 

`include "instructions.v"

module wb_sel (
   input                clk         ,
   input                rst_n       ,
   
   input    [31:0]      pc_i        ,  // from pc
   input    [5:0]       opcode_i    ,  // from dec
   input    [31:0]      opgen_i     ,
   input    [31:0]      alu_i       ,  // from alu execution
   input    [31:0]      mem_i       ,  // from data memory (dcache)
   
   output   [31:0]      wrdata_o    ,

   output   [31:0]      new_pc_o     
   );
   
   reg   [31:0]   wrdata_o_r;
   reg   [31:0]   new_pc_r;
   wire  [3:0]    opcat;
   assign opcat = opcode_i[5:2];
   
   always @(*) begin
      if (!rst_n)
         wrdata_o_r = 32'b0;
      else case (opcat)
         `INSTR_OPCAT_ADDSUB, `INSTR_OPCAT_LOGIC, `INSTR_OPCAT_SHIFT :
            wrdata_o_r = alu_i;
         `INSTR_OPCAT_MOVE :
            wrdata_o_r = opgen_i;
         `INSTR_OPCAT_LD, `INSTR_OPCAT_ST :
            wrdata_o_r = mem_i;
         `INSTR_OPCAT_J : // jump & link
            wrdata_o_r = pc_i;
         default: 
            wrdata_o_r = 32'b0;
      endcase
   end
   
   assign wrdata_o = wrdata_o_r;

endmodule
