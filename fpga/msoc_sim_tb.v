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

`timescale 1ns/100ps

module msoc_sim_tb;
   
   reg   clk            ;
   reg   rst_line_i     ;
   wire  uart_rx_line_i ;
   wire  uart_tx_line_o ; 
   msoc u_msoc (
      .clk_line_i       (clk            ),
      .rst_line_i       (rst_line_i     ),
      .uart_rx_line_i   (uart_rx_line_i ),
      .uart_tx_line_o   (uart_tx_line_o )     
   );
   
   wire        rst_n       ;
   wire        rx_line_i   ;
   wire  [7:0] rx_data_o   ;
   wire        rx_dvalid_o ;
   uart_rx u_rx (
      .clk      (clk          ),
      .rst_n    (rst_n        ),
      .rx_i     (rx_line_i    ),
      .data_o   (rx_data_o    ),
      .dvalid_o (rx_dvalid_o  )     // valid data received
   );
   reg      rst_n_r1, rst_n_r2;
   always @(posedge clk) begin
      rst_n_r1 <= rst_line_i;
      rst_n_r2 <= rst_n_r1;
   end
   assign rst_n = rst_n_r2;
   assign rx_line_i  =  uart_tx_line_o;
   
   initial clk = 1'b1;
   always #10 clk = ~clk;
   
   initial begin
      rst_line_i = 1'b1;
      #1;
      rst_line_i = 1'b0;
      #101;
      rst_line_i = 1'b1;
      #100;
      wait(rx_dvalid_o);
      $display("received data = %d\n", rx_data_o);
      #1000;
      $stop;
   end
   
endmodule