/**
 * instruction data dependency detection
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
   output            conflict_o        
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
   
endmodule