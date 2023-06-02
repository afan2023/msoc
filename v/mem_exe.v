/**
 * memory access instruction execution
 */

module mem_exe (
   input                clk      ,
   input                rst_n    ,
   
   input    [31:0]      addr_i   ,
   input    [31:0]      wdata_i  ,
   input    [1:0]       scope_i  ,
   input                en_i     ,
   input                wr_i     ,
   
   output reg [31:0]    rdata_o  
   );

endmodule
