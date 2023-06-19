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
 
module data_mem(
   input             clk   ,  // clock
   input             en    ,  // enable
   input    [31:0]   addr  ,  // address
   input             wr    ,  // 1: write, 0: read enable
   input    [1:0]    wscope,  // 2'b11: word, 2'b01: half word, 2'b00: byte
   input    [31:0]   wdata ,  // data to write
   output   [31:0]   rdata ,  // data been read out
   output            valid_o  // valid or not (e.g. mem out of range, cache miss)
   );
   
   reg   [7:0]    data_mem [8095:0]; // 8k bytes
   reg   [31:0]   rdata_r;

   always @(posedge clk)
   if (!en) begin
   end
   else if (wr) begin
      case (wscope)
         2'b11 : begin
            // big endian
            // force aligned
            data_mem[{addr[31:2],2'h0}] <= wdata[31:24];
            data_mem[{addr[31:2],2'h1}] <= wdata[23:16];
            data_mem[{addr[31:2],2'h2}] <= wdata[15:8];
            data_mem[{addr[31:2],2'h3}] <= wdata[7:0];
         end
         2'b01 : begin
            data_mem[{addr[31:1],1'h0}] <= wdata[15:8];
            data_mem[{addr[31:1],1'h1}] <= wdata[7:0];
         end
         2'b00 : begin
            data_mem[addr] <= wdata[7:0];
         end
      endcase
   end

   wire addr_in_danger = ((addr >= 'h00000110) && (addr < 'h00000120))
                        || ((addr >= 'h00000140) && (addr < 'h00000160));
   reg   new_area_met_r;
   always @(posedge clk) begin
      if (!en || wr) begin
         new_area_met_r <= 1'b0;
      end
      //else if (addr > 'h00000110) begin // set this as dangerous area, test purpose only
      else if (addr_in_danger) begin
         new_area_met_r <= 1'b1;
      end
   end

   reg new_area_met_r1;
   always @(posedge clk) begin
      new_area_met_r1 <= new_area_met_r;
   end

   wire  first_miss; // detect the first time that doesn't hit
   assign first_miss = new_area_met_r & (~new_area_met_r1);

   // simulate that it takes 16 cycles to fill the missed cache line
   reg   [15:0]   valid_rr;
   reg   [15:0]   unavail_rr;
   integer  i;

   initial begin
      new_area_met_r = 1'b0;
      new_area_met_r1 = 1'b0;
      valid_rr = 16'hffff;
      unavail_rr = 16'h0;
   end
   always @(posedge clk) begin
      valid_rr[0] <= ~first_miss;
      unavail_rr[0]  <= first_miss;
      for (i=1; i<16; i=i+1) begin
         valid_rr[i] <= valid_rr[i-1];
         unavail_rr[i] <= unavail_rr[i-1];
      end
   //   valid_rr <= (valid_rr << 1) | (~first_miss);
   end

   wire unavailable;
   assign unavailable = (|unavail_rr) | first_miss;

   reg   valid_r;
   always @(posedge clk) begin
      if (unavailable) begin
         valid_r <= 1'b0;
      end
      else begin
         valid_r <= 1'b1;
      end
   end

   always @(posedge clk) 
   if (!en || wr) begin
      rdata_r <= 32'h0;
   end else begin
      if (unavailable) begin
         rdata_r <= 32'hffaccbad;
      end   
      else
         // big endian
         // force aligned
         rdata_r <= {data_mem[{addr[31:2],2'h0}],
                     data_mem[{addr[31:2],2'h1}],
                     data_mem[{addr[31:2],2'h2}],
                     data_mem[{addr[31:2],2'h3}]};
   end   

   assign rdata = first_miss ? 32'hffaccbad : rdata_r;
   assign valid_o = valid_r & (~first_miss);

endmodule