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
 * memory access instruction execution
 */

`include "instructions.v"

module mem_exe (
   input                clk         ,
   input                rst_n       ,
   
   // from dec 
   input    [5:0]       opcode_i    ,
   input                signed_i    ,
   // from op_gen 
   input    [31:0]      wdata_i     ,
   // from alu 
   input    [31:0]      addr_i      ,   
   
   // external
   output reg [31:0]    mem_addr_o  ,
   output reg [31:0]    mem_wdata_o ,
   output reg           mem_en_o    ,
   output reg           mem_wr_o    ,
   output reg [1:0]     mem_wscope_o, // mem write scope: word(2'b11), half word(2'b01), byte(2'b00)
   
   // to mem rx
   output reg           ren_o       , // reading?
   output reg [1:0]     scope_o     , // word(2'b11), half word(2'b01), or byte(2'b00)?
   output reg           signed_o    ,
   output reg [1:0]     addr_lsb2_o   // least 2 bits of the address
   );
    
   wire  [3:0] opcat;
   assign opcat = opcode_i[5:2];
   reg   init;
   
   always @(*) begin
      if (init) begin
         mem_en_o = 1'b0;
         mem_wr_o = 1'b0;
         mem_wscope_o = 2'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_LD : begin
            mem_en_o = 1'b1;
            mem_wr_o = 1'b0;
            mem_wscope_o = 2'b00;
         end
         `INSTR_OPCAT_ST : begin
            mem_en_o = 1'b1;
            mem_wr_o = 1'b1;
            mem_wscope_o = opcode_i[1:0];
         end
         default: begin
            mem_en_o = 1'b0;
            mem_wr_o = 1'b0;
            mem_wscope_o = 2'b0;
         end
      endcase
   end

   always @(*) begin
      if (init) begin
         mem_addr_o = 32'b0;
         mem_wdata_o = 32'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_LD : begin
            mem_addr_o = addr_i;
            mem_wdata_o = 32'b0;
         end         
         `INSTR_OPCAT_ST : begin
            mem_addr_o = addr_i;
            mem_wdata_o = wdata_i;
         end
         default: begin
            mem_addr_o = 32'b0;
            mem_wdata_o = 32'b0;
         end
      endcase
   end
   
   // wait for mem - cache to give result
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         ren_o <= 1'b0;     
         scope_o <= 2'b11;   
         signed_o <= 1'b0;
         addr_lsb2_o <= 2'b00;
         init <= 1'b1;
      end
      else begin
         case (opcat)
            `INSTR_OPCAT_LD : begin
               ren_o <= 1'b1;
               scope_o <= opcode_i[1:0];
               signed_o <= signed_i;
               addr_lsb2_o <= addr_i[1:0];
            end
            default: begin
               ren_o <= 1'b0;     
               scope_o <= 2'b11;   
               signed_o <= 1'b0;
               addr_lsb2_o <= 2'b00;
            end
         endcase
         init <= 1'b0;
      end
   end

endmodule
