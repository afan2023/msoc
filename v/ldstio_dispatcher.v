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
 * load store io dispatcher
 * for the time being, simply dispatch (mem - cache future, uart, & other IO devices)
 * for future, the IO is preferable to have kind of IO bus
 */
 
module ldstio_dispatcher(
   // unified load store interface  
   input       [31:0]   addr_i      ,
   input                en_i        ,
   input                wr_i        ,
   input       [31:0]   wdata_i     ,
   input       [1:0]    wscope_i    ,
   // output for memory interface
   output reg  [31:0]   mem_addr_o  ,
   output reg           mem_en_o    ,
   output reg           mem_wr_o    ,
   output reg  [31:0]   mem_wdata_o ,
   output reg  [1:0]    mem_wscope_o, 
   // output for IO
   output reg  [31:0]   io_addr_o   ,
   output reg           io_en_o     ,
   output reg           io_wr_o     ,
   output reg  [31:0]   io_wdata_o  
   );
   
   // just a simple split
   // maybe kind of configuration table later
   parameter   IO_SPACE_BEGIN    =  32'hffff0000;
   parameter   IO_SPACE_END      =  32'hffffffff;   
   parameter   MEM_SPACE0_BEGIN  =  32'h00000000;
   parameter   MEM_SPACE0_END    =  32'h00010000;
   parameter   MEM_SPACE1_BEGIN  =  32'h80000000;
   parameter   MEM_SPACE1_END    =  32'h81ffffff;
   
   always @(*) begin
      if ((addr_i >= IO_SPACE_BEGIN) && (addr_i <= IO_SPACE_END)) begin
         io_addr_o   = addr_i    ;
         io_en_o     = en_i      ;
         io_wr_o     = wr_i      ;
         io_wdata_o  = wdata_i   ; 
      end
      else begin
         io_addr_o   = 32'b0 ;
         io_en_o     = 1'b0  ;
         io_wr_o     = 1'b0  ;
         io_wdata_o  = 32'b0 ; 
      end
   end
   
   always @(*) begin
      if (((addr_i >= MEM_SPACE0_BEGIN) && (addr_i <= MEM_SPACE0_END))
         || ((addr_i >= MEM_SPACE1_BEGIN) && (addr_i <= MEM_SPACE1_END))) begin
         mem_addr_o  = addr_i    ;
         mem_en_o    = en_i      ;
         mem_wr_o    = wr_i      ;
         mem_wdata_o = wdata_i   ; 
         mem_wscope_o= wscope_i  ;
      end
      else begin
         mem_addr_o  = 32'b0 ;
         mem_en_o    = 1'b0  ;
         mem_wr_o    = 1'b0  ;
         mem_wdata_o = 32'b0 ; 
         mem_wscope_o= 2'b0  ;
      end
   end   
   
endmodule