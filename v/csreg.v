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
//////////////////////////////////////////////////////////////////////////////////\

/**
 * register of control & status flags
 */

module csreg (
   input                clk               ,
   input                rst_n             ,
   // from dec
   input                aluflags_ahead_i  , // one pulse per one case
   // from alu
   input                aluflags_wen_i    , // one pulse per one case
   input       [3:0]    aluflags_i        ,
   // the current reg value
   output reg  [31:0]   csreg_o           ,
   output               aluflags_pending_o   
   );
   
   reg   [31:0]   csreg_r;
   reg   [2:0]    aluflags_yet2update_r;
   reg            init;
   
   always @(*) begin
      if ((!rst_n) | init)
         csreg_o = 1'b0;
      else
         csreg_o = csreg_r;
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         csreg_r <= 32'b0;
         init <= 1'b1;
      end
      else begin
         init <= 1'b0;
         if (aluflags_wen_i)
            csreg_r[3:0] <= aluflags_i;
      end
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         aluflags_yet2update_r <= 3'b0;
      end
      else begin
         case ({aluflags_ahead_i,aluflags_wen_i})
            2'b01 : 
               aluflags_yet2update_r <= aluflags_yet2update_r - 1'b1;
            2'b10 : 
               aluflags_yet2update_r <= aluflags_yet2update_r + 1'b1;
            default : begin
               // don't change
            end
         endcase
      end
   end   
   
   assign aluflags_pending_o = (|aluflags_yet2update_r) | aluflags_ahead_i;
   
endmodule
