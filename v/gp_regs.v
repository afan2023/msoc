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
 *
 * general purpose registers
 */
 
module gp_regs (
   input                clk         , // clock
   input                rst_n       , // reset

   input    [3:0]       reg_w_idx_i , // index of reg to write
   input    [31:0]      wdata_i     , // data to write into reg
   input                wen_i       , // write enable
   input    [1:0]       wr_scope_i  , // scope of write (bit 1: high half, bit 0: low half)
   
   input    [3:0]       ra_index_i  , // reg a index to read
   input                ren_a_i     , // read enable reg a
   input    [3:0]       rb_index_i  , // reg b index
   input                ren_b_i     , // read enable - reg b
   input    [3:0]       rm_index_i  , // reg m index
   input                ren_m_i     , // read enable - reg m   

   output reg [31:0]    rvalue_a_o  , // data value of reg a read
   output reg [31:0]    rvalue_b_o  , // data value of reg b read
   output reg [31:0]    rvalue_m_o    // data value of reg b read
   );
   
   reg [31:0]  regs  [15:0];
   
   localparam GPR_DEFAULT_VAL = 32'b0;
   
   integer i;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         // integer i; // modelsim: Declarations not allowed in unnamed block.
         for (i = 0; i < 16; i = i+1) begin
            regs[i] <= GPR_DEFAULT_VAL;
         end
      end
      else if (wen_i) begin
         case (wr_scope_i)
            2'b01: regs[reg_w_idx_i][15:0] <= wdata_i[15:0];
            2'b10: regs[reg_w_idx_i][31:16] <= wdata_i[15:0];
            2'b11: regs[reg_w_idx_i] <= wdata_i;
            default: ; // such default case shall not happen
         endcase
      end
   end
   
   // combinational logic to make output value always aligned, & catch up with the operand generation need
   always @(*)
   if (!rst_n | !ren_a_i)
      rvalue_a_o = GPR_DEFAULT_VAL;
   else
      rvalue_a_o = regs[ra_index_i];
   
   always @(*)
   if (!rst_n | !ren_b_i)
      rvalue_b_o = GPR_DEFAULT_VAL;
   else
      rvalue_b_o = regs[rb_index_i];
   
   always @(*)
   if (!rst_n | !ren_m_i)
      rvalue_m_o = GPR_DEFAULT_VAL;
   else
      rvalue_m_o = regs[rm_index_i];   
   
endmodule