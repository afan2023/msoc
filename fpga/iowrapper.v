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
 * simply wrap up some IO devices for the time being
 * in future it's preferable to have kind of IO bus
 */

`include "fpga_params.v"

module iowrapper (
   input                clk            ,
   input                rst_n          ,
   // unified inputs    
   input    [31:0]      addr_i         ,
   input                en_i           ,
   input                wr_i           ,
   input    [31:0]      wdata_i        ,
   // interface with different IO devices
   // uart  
   output reg           uart_cs_o      ,
   output reg  [7:0]    uart_reg_addr_o,
   output reg           uart_wr_o      ,  // write or read
   output reg  [7:0]    uart_din_o     ,  // data to write
   input       [7:0]    uart_dout_i    ,  // data read from uart
   // unified output
   output reg  [31:0]   rdata_o        ,  // data feedback
   output reg           io_valid_o        // valid or illegal data
   );
   
   parameter   SEL_ADDR_UART  =  24'hffff01;
   
   wire  addr_hit_uart  = &(addr_i[31:8] ~^ SEL_ADDR_UART);
   
   wire  [`FPGA_MAX_NUM_DEVICE-1:0] devsel_map;
   assign devsel_map[`FPGA_MAX_NUM_DEVICE-1:1]  = 0;
   assign devsel_map[0] = addr_hit_uart;
   
   localparam  DEVSEL_MAP_UART   =  `FPGA_MAX_NUM_DEVICE'b1 << 0;
   
   reg   init;
   reg   [`FPGA_MAX_NUM_DEVICE-1:0] devsel_map_r1;
   
   always @(*) begin
      if (addr_hit_uart & en_i & (~init)) begin
         uart_cs_o      = 1'b1;
         uart_reg_addr_o= addr_i[7:0];
         uart_wr_o      = wr_i;
         uart_din_o     = wdata_i[7:0];
      end
      else begin
         uart_cs_o      = 1'b0;
         uart_reg_addr_o= 8'b0;
         uart_wr_o      = 1'b0;
         uart_din_o     = 8'b0;
      end
   end
   
   reg   en_ir, wr_ir;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         init <= 1'b1;
         devsel_map_r1 <= `FPGA_MAX_NUM_DEVICE'b0;
         en_ir <= 1'b0;
         wr_ir <= 1'b0;
      end
      else begin
         init <= 1'b0;
         devsel_map_r1 <= devsel_map;
         en_ir <= en_i;
         wr_ir <= wr_i;
      end
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         io_valid_o  <= 1'b0;
      end
      else if (!en_i) begin
         io_valid_o  <= 1'b0;
      end
      else case(devsel_map)
         DEVSEL_MAP_UART : begin 
            // this uart's status is provided in its status register,
            // always say that the IO is valid once UART is selected
            io_valid_o <= 1'b1;
         end
         default : begin
            io_valid_o <= 1'b0;
         end
      endcase
   end
   
   //always @(posedge clk) begin
   //   if (en_i & (~wr_i)) case (devsel_map)
   always @(*) begin
     if (en_ir & (~wr_ir)) case (devsel_map_r1)
         DEVSEL_MAP_UART : begin 
            // this uart output data at (immediately after) next rising edge of clock
            //rdata_o = {24'b0, uart_dout_i};
            rdata_o = {uart_dout_i, 24'b0}; // load instruction always assume a word from mem/io, & big endian
         end
         default: begin
            rdata_o = 32'b0;
         end
      endcase
      else begin
         rdata_o = 32'b0;
      end
   end

endmodule