/*
 * pipeline control
 */
 
module pp_ctrl (
   input                clk               ,
   input                rst_n             ,
   
   // stall request on data conflict, from dec mod
   input                ddep_conflict_i   ,
   
   output               stall_dec_o       
   );
   
   reg   init_r;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         init_r <= 1'b1;
      end
      else
         init_r <= 1'b0;
   end
   
   assign stall_dec_o = init_r ? 1'b0 : ddep_conflict_i;

endmodule