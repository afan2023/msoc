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
 * jump execution module
 */

module jmp_exe (
   input                clk         ,
   input                rst_n       ,
   // from dec, jump request pulse
   input                jump_req_i  ,   
   // from alu
   input       [31:0]   j2addr_i    ,
   // output to pc
   output reg  [31:0]   new_pc_o    ,
   output reg           change_pc_o ,
   // signal that jump execute
   output reg           jump_done_o 
   );
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         new_pc_o <= 32'b0;
         change_pc_o <= 1'b0;
         jump_done_o <= 1'b0;
      end
      else if (jump_req_i) begin
         new_pc_o <= j2addr_i;
         change_pc_o <= 1'b1;
         jump_done_o <= 1'b1;
      end
      else begin
         new_pc_o <= 32'b0;
         change_pc_o <= 1'b0;
         jump_done_o <= 1'b0;
      end      
   end

endmodule