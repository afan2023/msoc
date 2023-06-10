`timescale 1ns/100ps

module vcpu2_tb;
   
   reg clk;
   reg rst_n;
   wire [31:0] instr;
   wire [31:0]	instr_addr;
   wire imem_en;
   
   wire [31:0]	mem_rdata;
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
      .dmem_rdata_valid_i  (1'b1),
      
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
      
      .rdata   (mem_rdata)
      
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
      #10800;
      $stop;
   end

endmodule