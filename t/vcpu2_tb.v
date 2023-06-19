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

module vcpu2_tb;
   
   reg clk;
   reg rst_n;
   wire [31:0] instr;
   wire [31:0]	instr_addr;
   wire imem_en;
   
   wire [31:0]	mem_rdata;
   wire        mem_rdata_valid;
   wire [31:0] mem_addr;
   wire [31:0] mem_wdata;
   wire mem_en;
   wire mem_wr;
   wire [1:0]  mem_wscope;
   
   hvcore u_hvcore (
      .clk                 (clk),
      .rst_n               (rst_n),
      
      .instr_i             (instr),
      .instr_valid_i       (1'b1),
      
      .instr_addr_o        (instr_addr),
      .imem_en_o           (imem_en),
      
      .dmem_rdata_i        (mem_rdata),
      .dmem_rdata_valid_i  (mem_rdata_valid),
      
      .dmem_addr_o         (mem_addr),
      .dmem_wdata_o        (mem_wdata),
      .dmem_en_o           (mem_en),
      .dmem_wr_o           (mem_wr),
      .dmem_wscope_o       (mem_wscope)
   );
   
   instr_rom_t u_rom(
      .en				(imem_en),
      .addr				(instr_addr),
      
      .instruction	(instr)
   );
   
   data_mem u_data_mem(
      .clk     (clk),
      .en      (mem_en),
      .addr    (mem_addr),		// address
      .wr      (mem_wr),
      .wscope  (mem_wscope),
      .wdata   (mem_wdata),
      
      .rdata   (mem_rdata),
      .valid_o (mem_rdata_valid)
   );
   
   
   initial clk = 1'b1;
   always #10 clk = ~clk;
   
   initial begin
      rst_n = 1'b1;
      #1;
      rst_n = 1'b0;
      #51;
      rst_n = 1'b1;
      // #300;
      // #1200;
      // #10800;
      #20000;
      $stop;
   end

endmodule