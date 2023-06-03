
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
      else if(!halt_i)
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