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
 * UART transmission module
 * 8 data bits (1 byte), no parity bit, 1 bit stop
 */

`include "fpga_params.v"

module uart_tx #(
      parameter   CLK_FREQ =  `FPGA_CLK_FREQUENCY,
      parameter   BAUDRATE =  `FPGA_UART_BAUDRATE
   )(
      input             clk      ,
      input             rst_n    ,
      input    [7:0]    data_i   , // data to transmit
      input             en_i     , // enable
      output reg        tx_o     , // the tx line output
      output reg        tx_done_o  // tx done pulse signal
   );

   localparam CNT_1BIT_MAX = CLK_FREQ / BAUDRATE - 1; 
   localparam CNT_1BIT_REGWIDTH = $clog2(CNT_1BIT_MAX);
   localparam BITS_IN_1BYTE_TX = 10;   // 1 start, 8 data, 1 stop
   reg [CNT_1BIT_REGWIDTH-1:0] cnt_1bit;
   reg [4:0] cnt_tx1byte;
   
   always@(posedge clk or negedge rst_n) begin
      if(!rst_n)
         cnt_1bit <= 0;
      else if(!en_i)
         cnt_1bit <= 0;
      else if(cnt_1bit >= CNT_1BIT_MAX)
         cnt_1bit <= 0;
      else
         cnt_1bit <= cnt_1bit + 1'b1;
   end
      
   always@(posedge clk or negedge rst_n) begin
      if(!rst_n)
         cnt_tx1byte <= 0;
      else if (!en_i)
         cnt_tx1byte <= 0;
      else if(cnt_tx1byte >= BITS_IN_1BYTE_TX)
         cnt_tx1byte <= 0;
      else if(cnt_1bit == CNT_1BIT_MAX)
         cnt_tx1byte <= cnt_tx1byte + 1'b1;
   end
   
   always@(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         tx_o <= 1'b1;
         tx_done_o <= 1'b0;
      end
      else if (!en_i) begin
         tx_o <= 1'b1;
         tx_done_o <= 1'b0;
      end
      else case(cnt_tx1byte)
         0: begin
            tx_done_o <= 1'b0;
            if (! tx_done_o)  // 1 clock cycle after the tx_done_o signal
               tx_o <= 1'b0;  // start
         end
         1: tx_o <= data_i[0];
         2: tx_o <= data_i[1];
         3: tx_o <= data_i[2];
         4: tx_o <= data_i[3];
         5: tx_o <= data_i[4];
         6: tx_o <= data_i[5];
         7: tx_o <= data_i[6];
         8: tx_o <= data_i[7];
         9: begin
            tx_o <= 1'b1;     //stop
         end
         10: tx_done_o <= 1'b1;
         default: tx_o <= 1'b1; // won't happen
      endcase
   end

endmodule