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
 * my mini soc
 */
 
`include "fpga_params.v"

module msoc(
   input                clk_line_i     ,
   input                rst_line_i     ,
   
   input                uart_rx_line_i ,
   output               uart_tx_line_o      
   );
   
   wire           clk               ;
   wire           rst_n             ;
   
   assign   clk = clk_line_i  ;
   reg      rst_n_r1, rst_n_r2;
   always @(posedge clk) begin
      rst_n_r1 <= rst_line_i;
      rst_n_r2 <= rst_n_r1;
   end
   assign rst_n = rst_n_r2;
   
   // instruction interface
   wire  [31:0]   instr             ; // instruction got
   wire           instr_valid       ; // is the instruction access valid (cache hit?)
   wire  [31:0]   instr_addr        ; // instruction address
   wire           imem_en           ;
   // mem/cache interface
   wire  [31:0]   dmem_rdata        ; // 
   wire           dmem_rdata_valid  ; // read data valid
   wire  [31:0]   dmem_addr         ;
   wire  [31:0]   dmem_wdata        ;
   wire           dmem_en           ;
   wire           dmem_wr           ;
   wire  [1:0]    dmem_wscope       ;
   // io interface
   wire  [31:0]   io_rdata          ;
   wire           io_valid          ;   
   wire  [31:0]   io_addr           ;
   wire           io_en             ;
   wire           io_wr             ;
   wire  [31:0]   io_wdata          ;        
   assign instr_valid = 1'b1;
   hvcore u_hvcore (
      .clk                 (clk              ),
      .rst_n               (rst_n            ),
   
   // instruction interface
      .instr_i             (instr            ), // instruction got
      .instr_valid_i       (instr_valid      ), // is the instruction access valid (cache hit?)
      .instr_addr_o        (instr_addr       ), // instruction address
      .imem_en_o           (imem_en          ),
   
   // data interface
      .dmem_rdata_i        (dmem_rdata       ), // 
      .dmem_rdata_valid_i  (dmem_rdata_valid ), // read data valid
      .dmem_addr_o         (dmem_addr        ),
      .dmem_wdata_o        (dmem_wdata       ),
      .dmem_en_o           (dmem_en          ),
      .dmem_wr_o           (dmem_wr          ),
      .dmem_wscope_o       (dmem_wscope      ),
   // io interface
      .io_rdata_i          (io_rdata         ),
      .io_valid_i          (io_valid         ),   
      .io_addr_o           (io_addr          ),
      .io_en_o             (io_en            ),
      .io_wr_o             (io_wr            ),
      .io_wdata_o          (io_wdata         )      
   );

   fpga_rom u_irom(
      .en_i    (imem_en    ),
      .addr_i  (instr_addr ),      
      .dout_o  (instr      )
   );
   
   fpga_mem #(.DEPTH(1024)) u_data_mem(
      .clk     (clk        ),
      .en_i    (dmem_en    ),
      .addr_i  (dmem_addr  ),		// address
      .wr_i    (dmem_wr    ),
      .wscope_i(dmem_wscope),
      .wdata_i (dmem_wdata ),      
      .rdata_o (dmem_rdata ),
      .valid_o (dmem_rdata_valid)
   );
   
   wire           uart_cs        ;
   wire  [7:0]    uart_reg_addr  ;
   wire           uart_wr        ;  // write or read
   wire  [7:0]    uart_din       ;  // data to write
   wire  [7:0]    uart_dout      ;  // data read from uart
      
   iowrapper u_iowrapper (
      .clk              (clk           ),
      .rst_n            (rst_n         ),
      // unified inputs    
      .addr_i           (io_addr       ),
      .en_i             (io_en         ),
      .wr_i             (io_wr         ),
      .wdata_i          (io_wdata      ),
      // interface with different IO devices
      // uart  
      .uart_cs_o        (uart_cs       ),
      .uart_reg_addr_o  (uart_reg_addr ),
      .uart_wr_o        (uart_wr       ),  // write or read
      .uart_din_o       (uart_din      ),  // data to write
      .uart_dout_i      (uart_dout     ),  // data read from uart
      // unified output
      .rdata_o          (io_rdata      ),  // data feedback
      .io_valid_o       (io_valid      )   // valid or illegal data
   );   
   
   wire           uart_int_o  ;  // interrupt line   
   uart #(
      .CLK_FREQ   (`FPGA_CLK_FREQUENCY ) ,
      .BAUDRATE   (`FPGA_UART_BAUDRATE )
   ) u_uart (
      .clk        (clk           ),
      .rst_n      (rst_n         ),
      .cs_i       (uart_cs       ),
      .addr_i     (uart_reg_addr ),  // register access address
      .wr_i       (uart_wr       ),  // the IO is a write (1'b1) or read (1'b0)
      .din_i      (uart_din      ),  // write register data
      .dout_o     (uart_dout     ),  // read register data
      .int_o      (uart_int_o    ),  // interrupt line
      .rx_line_i  (uart_rx_line_i),
      .tx_line_o  (uart_tx_line_o)
   );
   
endmodule