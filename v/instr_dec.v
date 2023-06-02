/**
 * instruction decoder
 */

`include "instructions.v"
 
module instr_dec (
   input                clk         ,
   input                rst_n       ,
   
   // input instruction
   input    [31:0]      instr_i     , 
   
   // output for oprands generation
   output reg           ren_a_o     ,
   output reg [3:0]     reg_a_idx_o ,
   output reg           ren_b_o     ,
   output reg [3:0]     reg_b_idx_o ,
   output reg           imm_valid_o ,
   output reg [19:0]    imm_raw_o   ,
   output reg [2:0]     imm_rule_o  ,
   
   // output for execution code
   output reg [5:0]     opcode_o    ,
   output reg           signed_o    ,
   
   // output for writing back register
   output reg           wen_d_o     ,
   output reg [3:0]     reg_d_idx_o , 
   output reg [1:0]     wrd_scope_o , // scope of write (bit 1: high half, bit 0: low half)
   
   // output to pipeline control
   output reg           stall_o
   );
   
   wire  [5:0] opcode;
   wire  [1:0] opext;
   assign opcode  = instr_i[`INSTR_FIELD_OPCODE];
   assign opext   = instr_i[`INSTR_FIELD_OPEXT];
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         opcode_o <= 6'b0;
      end
      else begin
         opcode_o <= opcode;    
      end
   end   
   
   wire  [3:0] opcat;
   assign opcat = opcode[5:2];   
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         signed_o <= 1'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
            signed_o <= opext[1];
         end
         default : begin
            signed_o <= 1'b0;
         end         
      endcase
   end   
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         reg_a_idx_o <= 4'b0;
         reg_b_idx_o <= 4'b0;
         reg_d_idx_o <= 4'b0;
      end
      else begin
         reg_a_idx_o <= instr_i[`INSTR_FIELD_RA];
         reg_b_idx_o <= instr_i[`INSTR_FIELD_RB];
         reg_d_idx_o <= instr_i[`INSTR_FIELD_RD];
      end
   end

   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         ren_a_o <= 1'b0;
         ren_b_o <= 1'b0;         
         wen_d_o <= 1'b0;
         wrd_scope_o <= 2'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
            ren_a_o <= 1'b1;
            ren_b_o <= opext[0] ? 1'b0 : 1'b1;
            wen_d_o <= 1'b1;
            wrd_scope_o <= 2'b11;
         end
         default : begin
            ren_a_o <= 1'b0;
            ren_b_o <= 1'b0;
            wen_d_o <= 1'b0;
            wrd_scope_o <= 2'b0;
         end
      endcase
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         imm_valid_o <= 1'b0;
         imm_raw_o <= 20'b0;         
         imm_rule_o <= `IMM_RULE_NONE;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
            imm_valid_o <= opext[0];
            imm_raw_o <= {4'b0, instr_i[15:0]};
            imm_rule_o <= `IMM_RULE_I16;
         end
         default : begin
            imm_valid_o <= 1'b0;
            imm_raw_o <= 20'b0;         
            imm_rule_o <= `IMM_RULE_NONE;
         end         
      endcase
   end
   
endmodule