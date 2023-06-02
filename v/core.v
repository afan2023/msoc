
module core 
   #( parameter ICACHE_LINE_SIZE    =  64,
      parameter ICACHE_DEPTH        =  128,
      parameter DCACHE_LINE_SIZE    =  64,
      parameter DCACHE_DEPTH        =  128
   )(
      input             clk      ,
      input             rst_n    ,
      
      // unified mem access interface
      input    [31:0]   rdata_o  ,
      output   [31:0]   addr_o   ,
      output   [31:0]   wdata_o
   );
   
   hvcore u_hvcore (
      
      
   );
   
//   icache u_icache ();
//   
//   dcache u_dcache ();

endmodule