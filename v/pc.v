
module pc (
   input                clk            ,
   input                rst_n          ,
   
   output      [31:0]   i_addr_o       ,
   output               i_fetch_en_o   ,
   
   // interface for branch
   input       [31:0]   new_pc_i       ,
   input                change_pc_i    ,
   
   // halt
   input                halt_i         
   );
   
   reg [31:0]  pc_r;
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
      else if(!halt_i)
         pc_r <= pc_r + 32'h4;
   end

   assign i_addr_o = pc_r;
   assign i_fetch_en_o = en_r;
   
   
   
endmodule