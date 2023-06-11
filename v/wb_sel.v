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
   input    [31:0]      opgen_i     ,  // oprand_b from op_gen mod
   input    [31:0]      alu_i       ,  // from alu execution
   input    [31:0]      mem_i       ,  // from data memory access
   input                mem_valid_i ,  // mem data valid or not
   
   output   [31:0]      wrdata_o    ,
   output               wr_allowed_o
   );
   
   reg   [31:0]   wrdata_o_r;
   reg   wr_allowed_r, init;
   wire  [3:0]    opcat;
   assign opcat = opcode_i[5:2];
   
   always @(*) begin
      if (init) begin
         wrdata_o_r = 32'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB, `INSTR_OPCAT_LOGIC, `INSTR_OPCAT_SHIFT : begin
            wrdata_o_r = alu_i;
         end
         `INSTR_OPCAT_MOVE : begin
            wrdata_o_r = opgen_i;
         end
         `INSTR_OPCAT_LD : begin
            wrdata_o_r = mem_i;
         end
         `INSTR_OPCAT_J : begin // jump & link
            wrdata_o_r = pc_i;
         end
         default: begin
            wrdata_o_r = 32'b0;
         end
      endcase
   end
   
   always @(*) begin
      if (init) begin
         wr_allowed_r = 1'b0;
      end
      else case (opcat) 
         `INSTR_OPCAT_LD : wr_allowed_r = mem_valid_i;
         default : wr_allowed_r = 1'b1;
      endcase
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         init = 1'b1;
      end
      else begin
         init = 1'b0;
      end
   end
   
   assign wrdata_o = wrdata_o_r;
   assign wr_allowed_o = wr_allowed_r;

endmodule
