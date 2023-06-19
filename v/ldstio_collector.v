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
 * load store io collector to provide a single interface
 * maybe merge into memacc
 */
 
 
module ldstio_collector (
   input       [1:0]    en_i           ,  // which one? 2'b10 mem, 2'b01 io
   input       [31:0]   mem_rdata_i    ,
   input                mem_dmiss_i    ,
   input       [31:0]   io_rdata_i     ,
   input                io_valid_i     ,
   // unified data
   output reg  [31:0]   rdata_o        ,
   output reg           data_miss_o    ,
   output reg           valid_o        
   );
   
   localparam  MEM_EN = 2'b10;
   localparam  IO_EN =  2'b01;
//   always @(*) begin
//      case (en_i)
//         MEM_EN : begin
//            rdata_o     =  mem_rdata_i;
//            data_miss_o =  mem_dmiss_i;
//            valid_o     =  1'b1;
//         end
//         IO_EN : begin
//            rdata_o     =  io_rdata_i;
//            data_miss_o =  1'b0;
//            valid_o     =  io_valid_i;
//         end
//         default : begin
//            rdata_o     =  32'b0;
//            data_miss_o =  1'b0;
//            valid_o     =  1'b0;
//         end
//      endcase
//   end 
   
   always @(*) begin
      if (en_i[1]) begin
         rdata_o     =  mem_rdata_i;
         data_miss_o =  mem_dmiss_i;
         valid_o     =  1'b1;
      end
      else if (en_i[0]) begin
         rdata_o     =  io_rdata_i;
         data_miss_o =  1'b0;
         valid_o     =  io_valid_i;
      end
      else begin
         rdata_o     =  32'b0;
         data_miss_o =  1'b0;
         valid_o     =  1'b0;
      end
   end 
   
endmodule 
