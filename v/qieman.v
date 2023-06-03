/**
 * wait a moment
 */

//module qieman #(
//      parameter   DW       =  1  ,
//      parameter   DEFAULT  =  1'b0
//   )(
//   input                clk      ,
//   input                rst_n    ,
//   
//   input    [DW-1:0]    din_i    ,
//   output reg [DW-1:0]  dout_o   
//   );
//   
//   always @(posedge clk or negedge rst_n) begin
//      if (!rst_n) begin
//         dout_o <= HOLDON_DATA_DEFAULT;
//      end
//      else begin
//         dout_o <= din_i;
//      end
//   end
//   
//endmodule

module qieman #(
      parameter   DW       = 32  ,
      parameter   DEFAULT  = 0   ,
      parameter   CYCLES   = 1   
   )(
      input                clk      ,
      input                rst_n    ,
      input    [DW-1:0]    din_i    ,
      
      output   [DW-1:0]    dout_o    
   );
   
   reg   [DW-1:0] dout_r[CYCLES-1:0];
   integer i;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         for (i=0; i<CYCLES; i=i+1)
            dout_r[i] <= DEFAULT;
      end
      else begin
         dout_r[0] <= din_i;
         for (i=1; i<CYCLES; i=i+1)
            dout_r[i] <= dout_r[i-1];
      end
   end
   assign dout_o = dout_r[CYCLES-1];

endmodule