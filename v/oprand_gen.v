/**
 * oprands generation
 */

`include "instructions.v"

module oprand_gen (
   input                clk         ,
   input                rst_n       ,
   
   // from instr_dec
   input                ren_a_i     ,   
   input                ren_b_i     ,
   input                imm_valid_i ,
   input    [19:0]      imm_raw_i   ,
   input    [2:0]       imm_rule_i  ,
   
   // from gp_regs
   input    [31:0]      ra_value_i  ,
   input    [31:0]      rb_value_i  ,
   
   // output data as oprands
   output reg [31:0]    oprand_a_o  ,
   output reg [31:0]    oprand_b_o  
   );
   
   localparam OPRAND_DEFAULT_VAL = 32'b0;
   
   always @(posedge clk) begin
   if (ren_a_i)
      oprand_a_o <= ra_value_i;
   else
      oprand_a_o <= OPRAND_DEFAULT_VAL;
   end
   
   always @(posedge clk) begin
   if (ren_b_i)
      oprand_b_o <= rb_value_i;
   else if (imm_valid_i) begin
      case (imm_rule_i)
         `IMM_RULE_I16  :
            oprand_b_o <= {{16{imm_raw_i[15]}}, imm_raw_i[15:0]};
         `IMM_RULE_I5   :
            oprand_b_o <= {27'b0, imm_raw_i[4:0]};
         `IMM_RULE_I12S4   :
            oprand_b_o <= {{20{imm_raw_i[11]}}, imm_raw_i[11:0]} << imm_raw_i[15:12];
         `IMM_RULE_I16S4S2 :
            oprand_b_o <= ({{16{imm_raw_i[15]}}, imm_raw_i[15:0]} << imm_raw_i[19:16]) << 2;
         `IMM_RULE_I16S2   :
            oprand_b_o <= {{16{imm_raw_i[15]}}, imm_raw_i[15:0]} << 2'h2;
         default:
            oprand_b_o <= {{16{imm_raw_i[15]}}, imm_raw_i[15:0]};
      endcase
   end
   else
      oprand_b_o <= OPRAND_DEFAULT_VAL;
   end

endmodule