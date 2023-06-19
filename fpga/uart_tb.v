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


`timescale  1ns/100ps

`include "fpga_params.v"


module uart_tb;

   reg            clk         ;
   reg            rst_n       ;
   reg   [31:0]   addr_i      ;  // register access address
   reg            wr_i        ;  // the IO is a write (1'b1) or read (1'b0)
   reg   [7:0]    din_i       ;  // write register data
   wire  [7:0]    dout_o      ;  // read register data
   wire           int_o       ;  // interrupt line
   wire           rx_line_i   ;
   wire           tx_line_o   ;
      
   uart #(
      .CLK_FREQ    (`FPGA_CLK_FREQUENCY) ,
      .BAUDRATE    (`FPGA_UART_BAUDRATE * 10)
   ) u_uart (
      .clk         (clk      ),
      .rst_n       (rst_n    ),
      .cs_i        (1'b1     ),
      .addr_i      (addr_i   ),  // register access address
      .wr_i        (wr_i     ),  // the IO is a write (1'b1) or read (1'b0)
      .din_i       (din_i    ),  // write register data
      .dout_o      (dout_o   ),  // read register data
      .int_o       (int_o    ),  // interrupt line
      .rx_line_i   (rx_line_i),
      .tx_line_o   (tx_line_o)
   );
   
   // make passthru
   assign rx_line_i = tx_line_o;
   
   initial clk = 1'b1;
   always #10 clk = ~clk;
   
   localparam ANOTHER_ADDR = 32'h18000000;
   initial begin
      rst_n = 1'b1;
      addr_i = ANOTHER_ADDR;
      wr_i = 1'b0;
      #1;
      rst_n = 1'b0;
      #30;
      rst_n = 1'b1;
      #60;
      
      addr_i = `FPGA_UART_BASE_ADDR + 'h4; // st
      wr_i = 1'b0;
      $display("dout is %x ", dout_o);
      #20; // yes, one shall need a cycle to read
      $display("st dout is %x ", dout_o);
      #20;
      addr_i = `FPGA_UART_BASE_ADDR + 'hc; // rx
      wr_i = 1'b0;
      #20;
      $display("rx dout is %x", dout_o);
      
      $display("let's send some bytes");
      addr_i = `FPGA_UART_BASE_ADDR + 'h8; // tx
      din_i = "a";
      wr_i = 1'b1;
      #20;
      din_i = "b";
      #20;
      din_i = "c";
      #20;
      din_i = "d";
      #20;
      din_i = "e";
      #20;
      
      $display("written to the buffer");

      addr_i = `FPGA_UART_BASE_ADDR + 'h4; // st
      wr_i = 1'b0;
      #100;
      $display("st dout is %x ", dout_o);
      #100;
      
      $display("need time to wait for sending done");
      #12000; // need time to wait for sending done
      addr_i = `FPGA_UART_BASE_ADDR + 'h4; // st
      wr_i = 1'b0;
      #100; // if don't read the rx data, the st rx valid bit may remain
      $display("st dout is %x ", dout_o);
      addr_i = `FPGA_UART_BASE_ADDR + 'hc; // rx
      wr_i = 1'b0;
      #20; // must give exactly 1 cycle pulse to read, otherwise it will read/move out more data
      $display("rx dout is %x", dout_o);
      addr_i = `FPGA_UART_BASE_ADDR + 'h4; // st
      wr_i = 1'b0;
      #100;
      $display("st dout is %x", dout_o);
      addr_i = `FPGA_UART_BASE_ADDR + 'hc; // rx
      wr_i = 1'b0;
      #20;
      $display("rx dout is %x", dout_o);
      addr_i = `FPGA_UART_BASE_ADDR + 'h4; // st
      wr_i = 1'b0;
      #100;
      $display("st dout is %x", dout_o);
      
      $display("wait longer for more data");
      #50000;
      repeat (5) begin
         addr_i = `FPGA_UART_BASE_ADDR + 'h4; // st
         wr_i = 1'b0;
         #100;
         $display("st dout is %x ", dout_o);
         addr_i = `FPGA_UART_BASE_ADDR + 'hc; // rx
         wr_i = 1'b0;
         #20;
         $display("rx dout is %x", dout_o);
      end   
      #100;
      $stop;
   end

endmodule