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
 * data dependency detection
 * - general purpose register
 */
 
module ddep_detect (
   input             clk         ,
   input             rst_n       ,
   
   // reg indice from dec
   input    [3:0]    reg_w_idx_i , 
   input             wen_i       ,
   input    [3:0]    reg_a_idx_i , 
   input             ren_a_i     ,
   input    [3:0]    reg_b_idx_i ,
   input             ren_b_i     ,
   input    [3:0]    reg_m_idx_i ,
   input             ren_m_i     ,
   // from write back, once write back remove that recorded reg index
   //    don't need, because on the time when the reg write back, the regs2wr_r happens to shift out that index
   // input    [3:0]    regwb_idx_i , // write back reg index
   
   // detected conflict
   output            conflict_o  ,
   
   // fast check interface, 
   // use this to check for just one register conflict
   // against yet to complete previous instructions, 
   // use this before dec phase!
   // todo for future, maybe all change to fast to save resource, now just fix up the need.
   input    [3:0]    fast_read_reg_idx_i ,
   output            fast_conflict_o      
   );
   
   localparam  PPGAP_DEC2WB = 4;
   reg   [4:0] regs2wr_r   [PPGAP_DEC2WB-1:0];
   localparam  INVALID_REGW_INDEX = 5'b00101;
   
   integer i;
   // record received reg_w_idx_i
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         for (i=0; i<PPGAP_DEC2WB; i=i+1) begin
            regs2wr_r[i] <= INVALID_REGW_INDEX;
         end
      end
      else begin
         // regs2wr_r[0] <= {wen_i,reg_w_idx_i};
         // the dec module shall output wen_i = 0, but i cannot use that as input, 
         // because i have to keep detecting the conflict to know when it disappear,
         // now the record shall no more take in, though that stalled input regw_index will be used in comb-logic to keep detecting
         if (conflict_o)
            regs2wr_r[0] <= INVALID_REGW_INDEX;
         else
            regs2wr_r[0] <= {wen_i,reg_w_idx_i};         
         for (i=1; i<PPGAP_DEC2WB; i=i+1) begin
            regs2wr_r[i] <= regs2wr_r[i-1];
         end
      end
   end

   reg [PPGAP_DEC2WB-1:0] conflict_bitmap_r;
   always @(*) begin
      for (i=0; i<PPGAP_DEC2WB; i=i+1) begin
         if (regs2wr_r[i][4] & (ren_a_i | ren_b_i))
            conflict_bitmap_r[i] = ~( (|(regs2wr_r[i] ^ {ren_a_i, reg_a_idx_i})) 
                                    & (|(regs2wr_r[i] ^ {ren_b_i, reg_b_idx_i})) 
                                    & (|(regs2wr_r[i] ^ {ren_m_i, reg_m_idx_i})) );
         else
            conflict_bitmap_r[i] = 1'b0;
      end 
   end
   assign conflict_o = | conflict_bitmap_r;
   
   reg [PPGAP_DEC2WB-1:0] fast_conflict_r;
   always @(*) begin
      for (i=0; i<PPGAP_DEC2WB; i=i+1) begin
         fast_conflict_r[i] = &(regs2wr_r[i] ~^ {1'b1, fast_read_reg_idx_i});
      end
   end
   assign fast_conflict_o = |fast_conflict_r;
   
endmodule