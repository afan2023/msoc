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
 * simulate a mem access for the time being,
 * the access will be changed to an data cache plus a memory interface
 */

module base_mem #(
      parameter   AW    =  10    ,
      parameter   SIZE  =  1 << AW  
   )(
      input		   			clk      ,	// clock
      input		   			cs_i     ,	// enable
      input		   [AW-1:0]	addr_i   ,	// address
      input		   			wr_i     ,	// 1: write, 0: read enable
      input		   [7:0]    wdata_i  ,	// data to write
      output reg  [7:0]    rdata_o   	// data been read out
   );
   
   reg   [7:0]    mem [SIZE-1:0];
   
   always @(posedge clk) begin
      if (cs_i & (~wr_i)) begin
         rdata_o <= mem[addr_i];
      end
   end
   
   always @(posedge clk) begin
      if (cs_i & wr_i) begin
         mem[addr_i] <= wdata_i;
      end
   end   

endmodule
 
module fpga_mem #(   // word mem
      parameter   DEPTH =  1024  // size = depth * 4
   )(
      input					clk      ,	// clock
      input					en_i     ,	// enable
      input		[31:0]	addr_i   ,	// address
      input					wr_i     ,	// 1: write, 0: read enable
      input    [1:0]    wscope_i ,  // 2'b11: word, 2'b01: half word, 2'b00: byte
      input		[31:0]   wdata_i  ,	// data to write
      output	[31:0]   rdata_o  ,	// data been read out
      output            valid_o     // valid or not (e.g. mem out of range, cache miss)
   );
   
   wire  [7:0] dout_mem0,  dout_mem1,  dout_mem2,  dout_mem3;
   reg   [7:0] din_mem0,   din_mem1,   din_mem2,   din_mem3 ;
   reg         cs_mem0,    cs_mem1,    cs_mem2,    cs_mem3  ;
   reg         wr_mem0,    wr_mem1,    wr_mem2,    wr_mem3  ;
   
   localparam  BASE_ADDR_WIDTH   =  $clog2(DEPTH);
   wire  [BASE_ADDR_WIDTH-1:0]   addr_base   =  addr_i[BASE_ADDR_WIDTH+1:2];
   
   reg            reading_r1;
   reg   [31:0]   rdata_r;
   
   always @(*) begin
      if (en_i && wr_i) case (wscope_i)   // write
         2'b11 : begin // word
            din_mem0 = wdata_i[31:24];
            din_mem1 = wdata_i[23:16];
            din_mem2 = wdata_i[15:8];
            din_mem3 = wdata_i[7:0];
            cs_mem0  = 1'b1;
            cs_mem1  = 1'b1;
            cs_mem2  = 1'b1;
            cs_mem3  = 1'b1;
            wr_mem0  = 1'b1;
            wr_mem1  = 1'b1;
            wr_mem2  = 1'b1;
            wr_mem3  = 1'b1;
         end
         2'b01 : begin  // half word
            if (addr_i[0]) begin
               din_mem2 = wdata_i[15:8];
               din_mem3 = wdata_i[7:0];
               cs_mem2  = 1'b1;
               cs_mem3  = 1'b1;
               wr_mem2  = 1'b1;
               wr_mem3  = 1'b1;
               
               din_mem0 = 8'b0;
               din_mem1 = 8'b0;
               cs_mem0  = 1'b0;
               cs_mem1  = 1'b0;
               wr_mem0  = 1'b0;
               wr_mem1  = 1'b0;
            end
            else begin
               din_mem0 = wdata_i[15:8];
               din_mem1 = wdata_i[7:0];
               cs_mem0  = 1'b1;
               cs_mem1  = 1'b1;
               wr_mem0  = 1'b1;
               wr_mem1  = 1'b1;
               
               din_mem2 = 8'b0;
               din_mem3 = 8'b0;
               cs_mem2  = 1'b0;
               cs_mem3  = 1'b0;
               wr_mem2  = 1'b0;
               wr_mem3  = 1'b0;
            end
         end
         2'b00 : begin // byte
            case (addr_i[1:0])
               2'b00 : begin
                  din_mem0 = wdata_i[7:0];
                  cs_mem0  = 1'b1;
                  wr_mem0  = 1'b1;
                  
                  din_mem1 = 8'b0;
                  cs_mem1  = 1'b0;
                  wr_mem1  = 1'b0;
                  
                  din_mem2 = 8'b0;
                  cs_mem2  = 1'b0;
                  wr_mem2  = 1'b0;
                  
                  din_mem3 = 8'b0;
                  cs_mem3  = 1'b0;
                  wr_mem3  = 1'b0;
               end
               2'b01 : begin
                  din_mem1 = wdata_i[7:0];
                  cs_mem1  = 1'b1;
                  wr_mem1  = 1'b1;
                  
                  din_mem0 = 8'b0;
                  cs_mem0  = 1'b0;
                  wr_mem0  = 1'b0;
                  
                  din_mem2 = 8'b0;
                  cs_mem2  = 1'b0;
                  wr_mem2  = 1'b0;
                  
                  din_mem3 = 8'b0;
                  cs_mem3  = 1'b0;
                  wr_mem3  = 1'b0;
               end
               2'b10 : begin
                  din_mem2 = wdata_i[7:0];
                  cs_mem2  = 1'b1;
                  wr_mem2  = 1'b1;
                  
                  din_mem0 = 8'b0;
                  cs_mem0  = 1'b0;
                  wr_mem0  = 1'b0;
                  
                  din_mem1 = 8'b0;
                  cs_mem1  = 1'b0;
                  wr_mem1  = 1'b0;
                  
                  din_mem3 = 8'b0;
                  cs_mem3  = 1'b0;
                  wr_mem3  = 1'b0;
               end
               2'b11 : begin
                  din_mem3 = wdata_i[7:0];
                  cs_mem3  = 1'b1;
                  wr_mem3  = 1'b1;
                  
                  din_mem0 = 8'b0;
                  cs_mem0  = 1'b0;
                  wr_mem0  = 1'b0;
                  
                  din_mem1 = 8'b0;
                  cs_mem1  = 1'b0;
                  wr_mem1  = 1'b0;
                  
                  din_mem2 = 8'b0;
                  cs_mem2  = 1'b0;
                  wr_mem2  = 1'b0;
               end
            endcase
         end
         default : begin // won't happen
            din_mem0 = 8'b0;
            cs_mem0  = 1'b0;
            wr_mem0  = 1'b0;
            
            din_mem1 = 8'b0;
            cs_mem1  = 1'b0;
            wr_mem1  = 1'b0;
            
            din_mem2 = 8'b0;
            cs_mem2  = 1'b0;
            wr_mem2  = 1'b0;
            
            din_mem3 = 8'b0;
            cs_mem3  = 1'b0;
            wr_mem3  = 1'b0;
         end
      endcase
      else if (en_i && !wr_i) begin // read
         din_mem0 = 8'b0;
         din_mem1 = 8'b0;
         din_mem2 = 8'b0;
         din_mem3 = 8'b0;
         cs_mem0  = 1'b1;
         cs_mem1  = 1'b1;
         cs_mem2  = 1'b1;
         cs_mem3  = 1'b1;
         wr_mem0  = 1'b0;
         wr_mem1  = 1'b0;
         wr_mem2  = 1'b0;
         wr_mem3  = 1'b0;
      end
      else begin
         cs_mem0  = 1'b0;
         cs_mem1  = 1'b0;
         cs_mem2  = 1'b0;
         cs_mem3  = 1'b0;
         wr_mem0  = 1'b0;
         wr_mem1  = 1'b0;
         wr_mem2  = 1'b0;
         wr_mem3  = 1'b0;
         din_mem0 = 8'b0;
         din_mem1 = 8'b0;
         din_mem2 = 8'b0;
         din_mem3 = 8'b0;
      end
   end
   
   always @(posedge clk) begin
      if (en_i && !wr_i) begin
         reading_r1 = 1'b1;
      end
      else begin
         reading_r1 = 1'b0;
      end
   end
   
   always @(*) begin
      if (reading_r1) begin
         rdata_r = {dout_mem0, dout_mem1, dout_mem2, dout_mem3};
      end
      else begin
         rdata_r = 32'b0;
      end
   end
   
   
   base_mem #(
      .AW   (BASE_ADDR_WIDTH  ),
      .SIZE (DEPTH            )
   ) u_mem0 (
      .clk      (clk        ),	// clock
      .cs_i     (cs_mem0    ),	// enable
      .addr_i   (addr_base  ),	// address
      .wr_i     (wr_mem0    ),	// 1: write, 0: read enable
      .wdata_i  (din_mem0   ),	// data to write
      .rdata_o  (dout_mem0  )	// data been read out
   );
   base_mem #(
      .AW   (BASE_ADDR_WIDTH  ),
      .SIZE (DEPTH            )
   ) u_mem1 (
      .clk      (clk        ),	// clock
      .cs_i     (cs_mem1    ),	// enable
      .addr_i   (addr_base  ),	// address
      .wr_i     (wr_mem1    ),	// 1: write, 0: read enable
      .wdata_i  (din_mem1   ),	// data to write
      .rdata_o  (dout_mem1  )	// data been read out
   );
   base_mem #(
      .AW   (BASE_ADDR_WIDTH  ),
      .SIZE (DEPTH            )
   ) u_mem2 (
      .clk      (clk        ),	// clock
      .cs_i     (cs_mem2    ),	// enable
      .addr_i   (addr_base  ),	// address
      .wr_i     (wr_mem2    ),	// 1: write, 0: read enable
      .wdata_i  (din_mem2   ),	// data to write
      .rdata_o  (dout_mem2  )	// data been read out
   );
   base_mem #(
      .AW   (BASE_ADDR_WIDTH  ),
      .SIZE (DEPTH            )
   ) u_mem3 (
      .clk      (clk        ),	// clock
      .cs_i     (cs_mem3    ),	// enable
      .addr_i   (addr_base  ),	// address
      .wr_i     (wr_mem3    ),	// 1: write, 0: read enable
      .wdata_i  (din_mem3   ),	// data to write
      .rdata_o  (dout_mem3  )	// data been read out
   );
      
   assign rdata_o = rdata_r;
   assign valid_o = 1'b1;  // TODO

endmodule

