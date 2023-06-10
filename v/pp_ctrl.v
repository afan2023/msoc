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

/*
 * pipeline control
 */
 
module pp_ctrl (
   input                clk               ,  
   input                rst_n             ,  
   // stall request on data conflict, from dec mod
   input                ddep_conflict_i   ,
   // need a transit cycle between data conflict stall & jump stall
   input                need_ddep2j_transit_i   ,
   // b & j stall request
   input                bj_req_i    ,
   // b/j jump made, must be one pulse signal
   input                bj_done_i         , 
   
   // should have seperate stall signals
   output               stall_2pc_o       ,
   output               stall_2dec_o          // stall to dec               
   );
   
   reg   bj_stall_r;
   reg   init_r;
   reg   bj_done_r;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         init_r <= 1'b1;
         bj_done_r <= 1'b0;
      end
      else begin
         init_r <= 1'b0;
         bj_done_r <= bj_done_i;
      end
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         bj_stall_r <= 1'b0;
      end
      else if (bj_done_i) begin
         bj_stall_r <= 1'b0;
      end
      else if (bj_req_i) begin
         bj_stall_r <= 1'b1;
      end
   end
   
   // ignore data dependency by the JR/JLR register on jump done to go next instruction
   assign stall_2pc_o   = init_r ? 1'b0 : (ddep_conflict_i & (~bj_done_r)) | bj_req_i | bj_stall_r | need_ddep2j_transit_i;
   assign stall_2dec_o  = init_r ? 1'b0 : (ddep_conflict_i & (~bj_done_r))| bj_stall_r;

endmodule