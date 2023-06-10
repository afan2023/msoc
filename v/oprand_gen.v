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
   // B&J type instruction should compute pc + offset as new pc
   input                pc_based_jump_i,
   
   // from gp_regs
   input    [31:0]      ra_value_i  ,
   input    [31:0]      rb_value_i  ,
   // current instruction address
   input    [31:0]      i_addr_i    ,
   
   // output data as oprands
   output reg [31:0]    oprand_a_o  ,
   output reg [31:0]    oprand_b_o  
   );
   
   localparam OPRAND_DEFAULT_VAL = 32'b0;
   
   always @(posedge clk) begin
   if (pc_based_jump_i)
      oprand_a_o <= i_addr_i;
   else if (ren_a_i)
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