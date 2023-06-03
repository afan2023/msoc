/**
 * ALU
 */
 
`include "instructions.v"
 
module alu (
   input                clk         ,
   input                rst_n       ,
   
   // from instr_dec
   input    [5:0]       opcode_i    ,
//   input    [1:0]       opext_i     ,
   input                signed_i    ,
   
   // from oprand_gen
   input    [31:0]      oprand_a_i  ,
   input    [31:0]      oprand_b_i  ,
   
   // output
   output reg [31:0]    result_o    ,
   output reg [31:0]    flags_o        
   
   );
   
   wire  [3:0] opcat;
   assign opcat = opcode_i[5:2];
   
   reg   [31:0]   adder_b_i_r;
   reg   adder_c_i_r;
   wire  [31:0]   adder_s_o;
   wire  adder_c_o;
   adder32 u_adder32 (
      .a     (oprand_a_i) ,
      .b     (adder_b_i_r) ,
      .c_i   (adder_c_i_r) ,
      .s     (adder_s_o) ,
      .c_o   (adder_c_o) 
   );
      
   always @(*) begin
      case (opcode_i)
         `OPCODE_ADD :  begin
            adder_b_i_r = oprand_b_i;
            adder_c_i_r = 1'b0;
          end
         `OPCODE_SUB :  begin
            adder_b_i_r = ~ oprand_b_i;
            adder_c_i_r = 1'b1;
         end
         default:  begin // the mem operations (LD/ST) also covered here
            adder_b_i_r = oprand_b_i;
            adder_c_i_r = 1'b0;
         end
      endcase
   end
   
   reg   arithm_flag_ov;
   wire  arithm_flag_neg, arithm_flag_zero;
   wire  arithm_signed;
//   assign arithm_signed = opext_i[1];
   assign arithm_signed = signed_i;
   always @(*) begin
      case (opcode_i)
         `OPCODE_ADD : begin
            if (arithm_signed)
               arithm_flag_ov = (oprand_a_i[31] ~^ oprand_b_i[31]) & (oprand_a_i[31] ^ adder_s_o[31]);
            else
               arithm_flag_ov = adder_c_o;
         end
         `OPCODE_SUB : begin
            arithm_flag_ov = (oprand_a_i[31] & (~ oprand_b_i[31]) & (~ adder_s_o[31])) 
                              | ((~oprand_a_i[31]) & oprand_b_i[31] & adder_s_o[31]);
         end
         default: begin
            arithm_flag_ov = 1'b0;
         end
      endcase
   end
   
   assign arithm_flag_neg = arithm_signed ? (~adder_s_o[31]) : 1'b0;
   assign arithm_flag_zero = ~(|adder_s_o);
   
   reg   [31:0]   logic_out_r;
   always @(*) begin
      case (opcode_i)
         `OPCODE_AND : 
            logic_out_r = oprand_a_i & oprand_b_i;
         `OPCODE_OR : 
            logic_out_r = oprand_a_i | oprand_b_i;
         `OPCODE_XOR : 
            logic_out_r = oprand_a_i ^ oprand_b_i;
         default: 
            logic_out_r = 32'b0;
      endcase
   end
   
   reg   [31:0]   shift_out_r;
   always @(*) begin
      case (opcode_i)
         `OPCODE_SL : 
            shift_out_r = oprand_a_i << oprand_b_i[4:0];
         `OPCODE_SR : 
            shift_out_r = oprand_a_i >> oprand_b_i[4:0];
         `OPCODE_SRA : 
            shift_out_r = $signed(oprand_a_i) >>> oprand_b_i[4:0];
         default: 
            shift_out_r = 32'b0;
      endcase
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         result_o <= 32'b0;
      end
      else begin 
         case (opcat)
            `INSTR_OPCAT_ADDSUB, `INSTR_OPCAT_LD, `INSTR_OPCAT_ST :
               result_o <= adder_s_o;
            `INSTR_OPCAT_LOGIC :
               result_o <= logic_out_r;
            `INSTR_OPCAT_SHIFT :
               result_o <= shift_out_r;
            default: ;
         endcase
      end
   end
   

endmodule

