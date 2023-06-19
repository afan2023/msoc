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
 * uart interface
 */

`include "fpga_params.v"

// registers
// configuration 
//    reserved for later (to have interrupt enable/mask)
// status
//    bit 4: tx status
//       1'b0 not able to accept data to transmit, 
//       1'b1 can accept data to transmit.
//    bit 0: rx data valid status
//       1'b0 no valid data
//       1'b1 valid data received & ready to read out
//       a read of the rx data register will clear this bit
// rx data
// tx data
// transmission reg
// 

module uart #(
      parameter   CLK_FREQ    =  `FPGA_CLK_FREQUENCY,
      parameter   BAUDRATE    =  `FPGA_UART_BAUDRATE,
      parameter   BASE_ADDR   =  8'h0
   )(
      input                clk         ,
      input                rst_n       ,
      
      input                cs_i        ,
      
      input       [7:0]    addr_i      ,  // register access address
      input                wr_i        ,  // the IO is a write (1'b1) or read (1'b0)
      input       [7:0]    din_i       ,  // write register data
      output reg  [7:0]    dout_o      ,  // read register data
//      output reg           do_valid_o  ,
//      output reg           illegal_o   ,
      output               int_o       ,  // interrupt line
         
      input                rx_line_i   ,
      output               tx_line_o   
   );
   
   localparam  OFFSET_CFG  =  8'h0;
   localparam  OFFSET_ST   =  8'h4;
   localparam  OFFSET_TX   =  8'h8;
   localparam  OFFSET_RX   =  8'hc;
   reg   [7:0] reg_cfg     ;
   reg   [7:0] reg_status  ;
   reg   [7:0] reg_rx      ;
   reg         reg_rx_valid;
   wire        tx_writable ;
   
   localparam  REG_ADDR_CFG   =  BASE_ADDR + OFFSET_CFG;
   localparam  REG_ADDR_ST    =  BASE_ADDR + OFFSET_ST;
   localparam  REG_ADDR_TX    =  BASE_ADDR + OFFSET_TX;
   localparam  REG_ADDR_RX    =  BASE_ADDR + OFFSET_RX;   

   wire  reg_access_cfg ;
   wire  reg_access_st  ;
   wire  reg_access_tx  ;
   wire  reg_access_rx  ;
   assign reg_access_cfg   = (&(addr_i ~^ REG_ADDR_CFG  ))&cs_i;
   assign reg_access_st    = (&(addr_i ~^ REG_ADDR_ST   ))&cs_i;
   assign reg_access_tx    = (&(addr_i ~^ REG_ADDR_TX   ))&cs_i;
   assign reg_access_rx    = (&(addr_i ~^ REG_ADDR_RX   ))&cs_i;
   
	reg   [7:0] txfifo_data_i ;
	reg         txfifo_rdreq_i;
	reg         txfifo_sclr_i ;
	reg         txfifo_wrreq_i;
	wire	      txfifo_empty_o;
	wire	      txfifo_full_o ;
	wire  [7:0] txfifo_q_o    ;
	wire  [3:0] txfifo_usedw_o;   
   uart_fifo u_tx_fifo (
      .clock   (clk  ) ,
      .data    (txfifo_data_i  ) ,
      .rdreq   (txfifo_rdreq_i  ) ,
      .sclr    (txfifo_sclr_i  ) ,
      .wrreq   (txfifo_wrreq_i  ) ,
      .empty   (txfifo_empty_o  ) ,
      .full    (txfifo_full_o  ) ,
      .q       (txfifo_q_o  ) ,
      .usedw   (txfifo_usedw_o  ) 
   );
   
   reg   [7:0] tx_data_i;
   reg         tx_en_i  ;
   wire        tx_done_o;
   uart_tx #(
      .CLK_FREQ (CLK_FREQ),
      .BAUDRATE (BAUDRATE)
   ) u_tx (
      .clk        (clk  )  ,
      .rst_n      (rst_n  )  ,
      .data_i     (tx_data_i  )  , // data to transmit
      .en_i       (tx_en_i  )  , // enable
      .tx_o       (tx_line_o  )  , // the tx line output
      .tx_done_o  (tx_done_o  )    // tx done pulse signal
   );
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         txfifo_sclr_i <= 1'b1;
      end
      else begin
         txfifo_sclr_i <= 1'b0;
      end
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         reg_cfg <= 8'b0;
      end
      else if (wr_i && reg_access_cfg) begin
         reg_cfg <= din_i;
      end
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         txfifo_wrreq_i <= 1'b0;
         txfifo_data_i <= 8'b0;
      end
      else if (wr_i && reg_access_tx && (~txfifo_full_o)) begin
         txfifo_wrreq_i <= 1'b1;
         txfifo_data_i <= din_i;
      end
      else begin
         txfifo_wrreq_i <= 1'b0;
         txfifo_data_i <= 8'b0;
      end
   end
   
   localparam  TX_ST_IDLE     =  2'h0;
   localparam  TX_ST_RDFIFO1  =  2'h1;
   localparam  TX_ST_RDFIFO2  =  2'h2;
   localparam  TX_ST_SEND     =  2'h3;
   reg   [2:0] tx_st;
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         tx_st <= TX_ST_IDLE;
         txfifo_rdreq_i <= 1'b0;
         tx_en_i <= 1'b0;
         tx_data_i <= 8'b0;
      end
      else case (tx_st)
         TX_ST_IDLE  : begin
            if (!txfifo_empty_o) begin
               txfifo_rdreq_i <= 1'b1;
               tx_st <= TX_ST_RDFIFO1;
            end
            else begin
               txfifo_rdreq_i <= 1'b0;
            end            
            tx_en_i <= 1'b0;
         end
         TX_ST_RDFIFO1   : begin // still need another cycle to get data
            txfifo_rdreq_i <= 1'b0;
            tx_st <= TX_ST_RDFIFO2;
         end
         TX_ST_RDFIFO2   : begin
            txfifo_rdreq_i <= 1'b0;
            tx_data_i <= txfifo_q_o;
            tx_en_i <= 1'b1;
            tx_st <= TX_ST_SEND;
         end
         TX_ST_SEND  : begin
            if (tx_done_o) begin
               tx_en_i <= 1'b0;
               tx_st <= TX_ST_IDLE;
            end
            else begin
               tx_en_i <= 1'b1;
               tx_st <= TX_ST_SEND;
            end
         end
         default: begin // should not happen
            tx_st <= TX_ST_IDLE;
            txfifo_rdreq_i <= 1'b0;
            tx_en_i <= 1'b0;
            tx_data_i <= 8'b0;         
         end
      endcase
   end
   
   reg   [7:0] rxfifo_data_i ;
	reg         rxfifo_rdreq_i;
	reg         rxfifo_sclr_i ;
	reg         rxfifo_wrreq_i;
	wire	      rxfifo_empty_o;
	wire	      rxfifo_full_o ;
	wire  [7:0] rxfifo_q_o    ;
	wire  [3:0] rxfifo_usedw_o;   
   uart_fifo u_rx_fifo (
      .clock   (clk  ) ,
      .data    (rxfifo_data_i  ) ,
      .rdreq   (rxfifo_rdreq_i  ) ,
      .sclr    (rxfifo_sclr_i  ) ,
      .wrreq   (rxfifo_wrreq_i  ) ,
      .empty   (rxfifo_empty_o  ) ,
      .full    (rxfifo_full_o  ) ,
      .q       (rxfifo_q_o  ) ,
      .usedw   (rxfifo_usedw_o  ) 
   );
   
   wire  [7:0] rx_data_o   ;
   wire        rx_dvalid_o ;  // valid data received
   uart_rx #(
      .CLK_FREQ (CLK_FREQ),
      .BAUDRATE (BAUDRATE)
   ) u_rx (
      .clk      (clk )  ,
      .rst_n    (rst_n )  ,
      .rx_i     (rx_line_i )  ,
      .data_o   (rx_data_o )  ,
      .dvalid_o (rx_dvalid_o )     // valid data received
   );
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         rxfifo_sclr_i <= 1'b1;
      end
      else begin
         rxfifo_sclr_i <= 1'b0;
      end
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         rxfifo_wrreq_i <= 1'b0;
      end
      else if (rx_dvalid_o & (~rxfifo_full_o)) begin
         rxfifo_wrreq_i <= 1'b1;
         rxfifo_data_i <= rx_data_o;
      end
      else begin
         rxfifo_wrreq_i <= 1'b0;
      end
   end   
   
   localparam  RX_EXPORT_ST_IDLE = 2'h0;
   localparam  RX_EXPORT_ST_READ1= 2'h1;
   localparam  RX_EXPORT_ST_READ2= 2'h2;
   reg   [1:0] rx_export_st;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         reg_rx_valid <= 1'b0;
         reg_rx <= 8'b0;
         rxfifo_rdreq_i <= 1'b0;
         rx_export_st <= RX_EXPORT_ST_IDLE;
      end
      else case (rx_export_st)
         RX_EXPORT_ST_IDLE  : begin
            if ((!rxfifo_empty_o) && (!reg_rx_valid)) begin
               rxfifo_rdreq_i <= 1'b1;
               rx_export_st <= RX_EXPORT_ST_READ1;
            end
            if ((!wr_i) && reg_access_rx && reg_rx_valid) begin
               reg_rx_valid <= 1'b0;
            end
         end
         RX_EXPORT_ST_READ1  : begin // still need another cycle to get the data
            rxfifo_rdreq_i <= 1'b0;
            rx_export_st <= RX_EXPORT_ST_READ2;
         end
         RX_EXPORT_ST_READ2  : begin
            reg_rx_valid <= 1'b1;
            reg_rx <= rxfifo_q_o;
            rxfifo_rdreq_i <= 1'b0;
            rx_export_st <= RX_EXPORT_ST_IDLE;
         end
         default  : begin // should not happen
            reg_rx_valid <= 1'b0;
            reg_rx <= 8'b0;
            rxfifo_rdreq_i <= 1'b0;
            rx_export_st <= RX_EXPORT_ST_IDLE;
         end
      endcase   
   end
   
   assign tx_writable = ~txfifo_full_o;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         reg_status <= 8'b0;
      end
      else begin
         reg_status[0] <= reg_rx_valid  ;  // readable
         reg_status[4] <= tx_writable   ;  // writable
      end
   end    
      
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         dout_o <= 8'b0;
      end
      else if (~wr_i) begin
         case ({reg_access_cfg, reg_access_st, reg_access_rx})
            3'b100   :  
               dout_o <= reg_cfg;
            3'b010   :  
               dout_o <= reg_status;
            3'b001   :  
               dout_o <= reg_rx;
         endcase
      end
   end   

   assign int_o = 1'b0; // interrupt to be implemented later
   
endmodule