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

module pc (
   input                clk            ,
   input                rst_n          ,
   
   output      [31:0]   i_addr_o       ,
   output               i_fetch_en_o   ,
   
   // interface for branch
   input       [31:0]   new_pc_i       ,
   input                change_pc_i    ,
   
   // pipeline controls
   input                stall_i        ,
   
   // halt
   input                halt_i         
   );
   
   reg [31:0]  pc_r;
   reg [31:0]  pc_r1; // old pc reg value, keep record just 1 now
   reg en_r;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n)
         en_r <= 1'b0; // don't fetch
      else if (halt_i)
         en_r <= 1'b0;
      else
         en_r <= 1'b1;
   end

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n)
         pc_r <= 0; // start from address 'h0;
      else if(!en_r) 
         pc_r <= 0;
      else if(change_pc_i)
         pc_r <= new_pc_i;
      else if(stall_i)
         pc_r <= pc_r; // keep unchanged
      else // if(!halt_i)
         pc_r <= pc_r + 32'h4;
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n)
         pc_r1 <= 0; // start from address 'h0;
      else if (!stall_i)
         pc_r1 <= pc_r;
   end

   assign i_addr_o = stall_i ? pc_r1 : pc_r;
   assign i_fetch_en_o = en_r;
   
   
   
endmodule