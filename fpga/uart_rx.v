//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, c.fan (alvincfan@163.com)                                  
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
 * UART receiving module
 * 8 data bits (1 byte), no parity bit, 1 stop bit
 */

`include "fpga_params.v"

module uart_rx #(
      parameter   CLK_FREQ =  `FPGA_CLK_FREQUENCY,
      parameter   BAUDRATE =  `FPGA_UART_BAUDRATE
   )(
      input             clk      ,
      input             rst_n    ,
      input             rx_i     ,
      output reg  [7:0] data_o   ,
      output reg        dvalid_o    // valid data received
   );

   localparam SAMPLE_CNT_MAX     = CLK_FREQ / BAUDRATE / 16 - 1;
   localparam CNT_SAMPLE_WIDTH   = $clog2(SAMPLE_CNT_MAX);  //9 for 9600
   
   localparam CNT_1BIT_EARLY_CHECK_POINT = CLK_FREQ * 3 / BAUDRATE / 4 - 1; // early check point
   localparam CNT_1BIT_MAX       = CLK_FREQ / BAUDRATE - 1; //5207 for 9600
   localparam CNT_1BIT_REGWIDTH  = $clog2(CNT_1BIT_MAX);    // 13 for 9600
   
   reg [CNT_SAMPLE_WIDTH - 1:0]  cnt_sample;
   reg [CNT_1BIT_REGWIDTH - 1:0] cnt_1bit;
   
   localparam CNT_PROGRESS_START = 0;
   localparam CNT_PROGRESS_STOP = 9;
   localparam CNT_PROGRESS_MAX = CNT_PROGRESS_STOP;
   reg [3:0] cnt_rxprogress;
   //reg bit_transit;
   
   reg rx_r1;
   reg rx_r2;
   wire rx_negedge;
   reg guessed_start;
   reg [2:0] samples;
   reg [7:0] flying_data;
   
   localparam ST_IDLE = 2'b0;
   localparam ST_RX = 2'b1;
   localparam ST_DONE = 2'h2;
   localparam ST_INVALID = 2'h3;
   reg [1:0] st; // rx state
   
   always@(posedge clk) rx_r1 <= rx_i;
   always@(posedge clk) rx_r2 <= rx_r1;
   assign rx_negedge = rx_r2 & (~rx_r1);
   
   always@(posedge clk or negedge rst_n)
   if (!rst_n) begin
      st <= ST_IDLE;
      dvalid_o <= 1'b0;
      guessed_start <= 1'b0;
   end
   else case(st)
      ST_IDLE: begin
         if (rx_negedge) begin
            st <= ST_RX;
            guessed_start <= 1'b1;
         end
         dvalid_o <= 1'b0;
      end
      ST_RX: begin
         // not good         
         // the starting negedge may escape if take action till bit end... so below line maybe won't work
         // if (cnt_1bit == CNT_1BIT_MAX)
         // change to below, i.e. earlier state transition
         if (cnt_1bit == CNT_1BIT_EARLY_CHECK_POINT) 
            case (cnt_rxprogress)
               CNT_PROGRESS_START: if (samples[2] != 1'b0) st <= ST_INVALID;
               1: flying_data[0] <= samples[2];
               2: flying_data[1] <= samples[2];
               3: flying_data[2] <= samples[2];
               4: flying_data[3] <= samples[2];
               5: flying_data[4] <= samples[2];
               6: flying_data[5] <= samples[2];
               7: flying_data[6] <= samples[2];
               8: flying_data[7] <= samples[2];               
               CNT_PROGRESS_STOP:
                  if (samples[2] == 1'b1)
                     st <= ST_DONE;
                  else
                     st <= ST_INVALID;
            endcase
         guessed_start <= 1'b0;
      end
      ST_DONE: begin
         data_o <= flying_data;
         dvalid_o <= 1'b1;
         st <= ST_IDLE;
      end
      ST_INVALID: begin
         dvalid_o <= 1'b0;
         st <= ST_IDLE;
      end
      default: begin
         dvalid_o <= 1'b0;
         st <= ST_IDLE;
      end
   endcase
   
   always@(posedge clk or negedge rst_n) begin
      if (!rst_n)
         cnt_sample <= 0;
      else if(st == ST_RX) begin
         // if ((cnt_sample >= SAMPLE_CNT_MAX) || bit_transit || guessed_start)
         if ((cnt_sample >= SAMPLE_CNT_MAX) || guessed_start)
            cnt_sample <= 0;
         else
            cnt_sample <= cnt_sample + 1'b1;
      end
   end
   
   reg [3:0] sample_idx;
   always@(posedge clk or negedge rst_n) begin
      if (!rst_n)
         sample_idx <= 0;
      else if (cnt_1bit == CNT_1BIT_MAX) // to avoid problem caused by early check point
         sample_idx <= 0;
      else if (cnt_sample == SAMPLE_CNT_MAX) begin
         if (sample_idx < 16)
            sample_idx <= sample_idx + 1'b1;
         else
            sample_idx <= 0;
      end
   end
         
   always@(posedge clk or negedge rst_n)
   if (!rst_n)
      samples <= 0;
   else if (cnt_sample == SAMPLE_CNT_MAX)
      case (sample_idx)
         0,1,2,3,4: samples <= 0;
         5,6,7,8,9,10,11:samples <= samples + rx_i;
         default:;
      endcase
   
   always@(posedge clk or negedge rst_n) begin
      if (!rst_n)
         cnt_1bit <= 0;
      else if(st != ST_RX)
         cnt_1bit <= 0;
      else
         if (guessed_start)
            cnt_1bit <= 3; // this is to compensate for the delay @ start
         else if (cnt_1bit >= CNT_1BIT_MAX)
            cnt_1bit <= 0;
         else
            cnt_1bit <= cnt_1bit + 1'b1;
   end
         
   always@(posedge clk or negedge rst_n) begin
      if (!rst_n)
         cnt_rxprogress <= 0;
      else if(st != ST_RX)
         cnt_rxprogress <= 0;
      else
         if(cnt_1bit == CNT_1BIT_MAX) begin
            if (cnt_rxprogress >= CNT_PROGRESS_MAX)
               cnt_rxprogress <= 0;
            else
               cnt_rxprogress <= cnt_rxprogress + 1'b1;
         end
   end
   
//   always@(posedge clk or negedge rst_n)
//   if (!rst_n)
//      bit_transit <= 1'b0;
//   else if(cnt_1bit == CNT_1BIT_MAX)
//      bit_transit <= 1'b1;
//   else
//      bit_transit <= 1'b0;
   
endmodule