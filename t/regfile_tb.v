`timescale 1ns/100ps

module regfile_tb;

   reg   clk, rst_n;
   
   reg   [3:0]       reg_w_idx_i ; // index of reg to write
   reg   [31:0]      wdata_i     ; // data to write into reg
   reg               wen_i       ; // write enable
   reg   [1:0]       wr_scope_i  ; // scope of write (bit 1: high half, bit 0: low half)
   
   reg   [3:0]       ra_index_i  ; // reg a index to read
   reg               ren_a_i     ; // read enable reg n
   reg   [3:0]       rb_index_i  ; // reg b index
   reg               ren_b_i     ; // read enable - reg b

   wire  [31:0]      rvalue_a_o  ; // data value of reg a read
   wire  [31:0]      rvalue_b_o  ; // data value of reg b read   
   
   gp_regs u_regfile (
      .clk         (clk        ) , // clock
      .rst_n       (rst_n      ) , // reset
      
      .reg_w_idx_i (reg_w_idx_i) , // index of reg to write
      .wdata_i     (wdata_i    ) , // data to write into reg
      .wen_i       (wen_i      ) , // write enable
      .wr_scope_i  (wr_scope_i ) , // scope of write (bit 1: high half, bit 0: low half)
      
      .ra_index_i  (ra_index_i ) , // reg a index to read
      .ren_a_i     (ren_a_i    ) , // read enable reg n
      .rb_index_i  (rb_index_i ) , // reg b index
      .ren_b_i     (ren_b_i    ) , // read enable - reg b
      
      .rvalue_a_o  (rvalue_a_o ) , // data value of reg a read
      .rvalue_b_o  (rvalue_b_o )   // data value of reg b read
   );
   
   initial clk = 1'b1;
	always #10 clk = ~clk;
   
   initial begin
      rst_n = 1'b0;
      wen_i = 1'b0;
      wr_scope_i = 2'b11;
      ren_a_i = 1'b0;
      ren_b_i = 1'b0;
      #20;
      rst_n = 1'b1;      
      
      reg_w_idx_i = 4'h5;
      
      ra_index_i = 4'h5;
      rb_index_i = 4'h6;
      
      #20;
      ren_a_i = 1'b1;
      ren_b_i = 1'b1;
      #20;
      ren_a_i = 1'b0;
      ren_b_i = 1'b0;
      
      #20;
      wdata_i = 'h101;
      wen_i = 1'b1;
      ren_a_i = 1'b1;
      ren_b_i = 1'b1;
      #20;
      wen_i = 1'b0;
      #20;
      ren_a_i = 1'b0;
      ren_b_i = 1'b0;
      #20;
      ren_a_i = 1'b1;
      ren_b_i = 1'b1;
      wdata_i = 'h202;
      wen_i = 1'b1;
      #20;
      wen_i = 1'b0;
      #20;
      ren_a_i = 1'b0;
      ren_b_i = 1'b0;
      
      $stop;
   end

endmodule