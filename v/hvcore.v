`include "instructions.v"

module hvcore (
   input             clk               ,
   input             rst_n             ,
   
   // instruction interface
   input    [31:0]   instr_i           , // instruction got
   input             instr_valid_i     , // is the instruction access valid (cache hit?)
   output   [31:0]   instr_addr_o      , // instruction address
   output            imem_en_o         ,
   
   // data interface
   input    [31:0]   dmem_rdata_i      , // 
   input             dmem_rdata_valid_i, // read data valid
   output   [31:0]   dmem_addr_o       ,
   output   [31:0]   dmem_wdata_o      ,
   output            dmem_en_o         ,
   output            dmem_wr_o         
   );
   
   //wire [31:0] pc_i_addr_o;
   //wire        pc_i_fetch_en_o;
   wire [31:0] pc_new_pc_i;
   wire        pc_change_pc_i;
   wire        pc_halt_i;
   assign pc_halt_i = 1'b0;
   pc u_pc (
      .clk            (clk),
      .rst_n          (rst_n),
      .i_addr_o       (instr_addr_o),
      .i_fetch_en_o   (imem_en_o),
      .new_pc_i       (pc_new_pc_i),
      .change_pc_i    (pc_change_pc_i),
      .halt_i         (pc_halt_i)
   );
   
   // output for oprands generation
   wire           instr_dec_ren_a_o     ;
   wire [3:0]     instr_dec_reg_a_idx_o ;
   wire           instr_dec_ren_b_o     ;
   wire [3:0]     instr_dec_reg_b_idx_o ;
   wire           instr_dec_imm_valid_o ;
   wire [19:0]    instr_dec_imm_raw_o   ;
   wire [2:0]     instr_dec_imm_rule_o  ;
   
   // output for execution code
   wire [5:0]     instr_dec_opcode_o    ;
   wire           instr_dec_signed_o    ;
   
   // output for writing back register
   wire           instr_dec_wen_d_o     ;
   wire [3:0]     instr_dec_reg_d_idx_o ; 
   wire [1:0]     instr_dec_wrd_scope_o ; // scope of write (bit 1: high half, bit 0: low half)
   
   // output to pipeline control
   wire           instr_dec_stall_o     ;  
   
   instr_dec u_instr_dec (
      .clk         (clk) ,
      .rst_n       (rst_n) ,
      
      .instr_i     (instr_i) , 
      
      .ren_a_o     (instr_dec_ren_a_o) ,
      .reg_a_idx_o (instr_dec_reg_a_idx_o) ,
      .ren_b_o     (instr_dec_ren_b_o) ,
      .reg_b_idx_o (instr_dec_reg_b_idx_o) ,
      
      .imm_valid_o (instr_dec_imm_valid_o) ,
      .imm_raw_o   (instr_dec_imm_raw_o) ,
      .imm_rule_o  (instr_dec_imm_rule_o) ,
      
      .opcode_o    (instr_dec_opcode_o) ,
      .signed_o    (instr_dec_signed_o) ,
      
      // output for writing back register
      .wen_d_o     (instr_dec_wen_d_o) ,
      .reg_d_idx_o (instr_dec_reg_d_idx_o) , 
      .wrd_scope_o (instr_dec_wrd_scope_o) , // scope of write (bit 1: high half, bit 0: low half)
      
      .stall_o     (instr_dec_stall_o) 
   );
   
   wire    [3:0]       gpr_reg_w_idx_i ; // index of reg to write
   wire    [31:0]      gpr_wdata_i     ; // data to write into reg d
   wire                gpr_wen_i       ; // write enable
   wire    [1:0]       gpr_wr_scope_i  ; // scope of write (bit 1: high half, bit 0: low half)

   wire [31:0]    gpr_rvalue_a_o  ; // data value of reg a read
   wire [31:0]    gpr_rvalue_b_o  ; // data value of reg b read
   
   gp_regs u_gp_regs (
      .clk         (clk) , 
      .rst_n       (rst_n) , 
      
      .reg_w_idx_i (gpr_reg_w_idx_i) , 
      .wdata_i     (gpr_wdata_i) , 
      .wen_i       (gpr_wen_i) , 
      .wr_scope_i  (gpr_wr_scope_i) , 
      
      .ra_index_i  (instr_dec_reg_a_idx_o) , 
      .ren_a_i     (instr_dec_ren_a_o) , 
      .rb_index_i  (instr_dec_reg_b_idx_o) , 
      .ren_b_i     (instr_dec_ren_b_o) , 
      
      .rvalue_a_o  (gpr_rvalue_a_o) , 
      .rvalue_b_o  (gpr_rvalue_b_o)   
   );
   
   // output data as oprands;
   wire    [31:0]      opgen_oprand_a_o  ;
   wire    [31:0]      opgen_oprand_b_o  ;  
   
   oprand_gen u_oprand_gen (
      .clk         (clk) ,
      .rst_n       (rst_n) ,
      
      .ren_a_i     (instr_dec_ren_a_o) ,   
      .ren_b_i     (instr_dec_ren_b_o) ,
      .imm_valid_i (instr_dec_imm_valid_o) ,
      .imm_raw_i   (instr_dec_imm_raw_o) ,
      .imm_rule_i  (instr_dec_imm_rule_o) ,
      
      .ra_value_i  (gpr_rvalue_a_o) ,
      .rb_value_i  (gpr_rvalue_b_o) ,
      
      .oprand_a_o  (opgen_oprand_a_o) ,
      .oprand_b_o  (opgen_oprand_b_o) 
   );
   
   // from instr_dec
   wire    [5:0]       alu_opcode_i    ;
   wire                alu_signed_i    ;
   
   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP)
   ) up_dec2alu_opcode_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_opcode_o) ,
      .dout_o  (alu_opcode_i)
   );
   
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0)
   ) up_dec2alu_signed_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_signed_o) ,
      .dout_o  (alu_signed_i)
   );
   
   // output
   wire [31:0]    alu_result_o    ;
   wire [31:0]    alu_flags_o     ;     
   
   alu u_alu (
      .clk         (clk) ,
      .rst_n       (rst_n) ,
      
      .opcode_i    (alu_opcode_i) ,
      .signed_i    (alu_signed_i) ,
      
      .oprand_a_i  (opgen_oprand_a_o) ,
      .oprand_b_i  (opgen_oprand_b_o) ,
      
      .result_o    (alu_result_o) ,
      .flags_o     (alu_flags_o)       
   );
   

   wire     [31:0]      wb_pc_i        ;  // from pc
   wire     [5:0]       wb_opcode_i    ;  // from dec
   wire     [31:0]      wb_opgen_i     ;
   wire     [31:0]      wb_alu_i       ;
   wire     [31:0]      wb_mem_i       ;  // from data memory (dcache)

   wire     [31:0]      wb_wrdata_o    ;
   wire     [31:0]      wb_new_pc_o    ;
     
   qieman #(
      .DW      (32),
      .DEFAULT (32'b0)
   ) up_alu2wb_result_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (alu_result_o) ,
      .dout_o  (wb_alu_i)
   );
   
   wb_sel u_wb_sel ( // now use this version instead
   // wr_back u_wr_back ( // the wr_back verion need another cycle delay (e.g. need change the up_dec2gpr_... qiemans)
      .clk         (clk) ,
      .rst_n       (rst_n) ,
      
      .pc_i        (wb_pc_i) ,      // from pc
      .opcode_i    (wb_opcode_i) ,  // from dec
      .opgen_i     (wb_opgen_i) ,
      .alu_i       (wb_alu_i) , // from alu execution
      .mem_i       (wb_mem_i) ,     // from data memory (dcache)
      
      .wrdata_o    (wb_wrdata_o) ,
      .new_pc_o    (wb_new_pc_o)    
   );
   

   qieman #(
      .DW      (4),
      .DEFAULT (4'b0),
      .CYCLES  (3)
   ) up_dec2gpr_reg_w_idx_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_reg_d_idx_o) ,
      .dout_o  (gpr_reg_w_idx_i)
   );
   
   assign gpr_wdata_i = wb_wrdata_o;
   
   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (3)
   ) up_dec2gpr_opcode_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_opcode_o) ,
      .dout_o  (wb_opcode_i)
   );
   
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0),
      .CYCLES  (3)
   ) up_dec2gpr_wen_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_wen_d_o) ,
      .dout_o  (gpr_wen_i)
   );   

   qieman #(
      .DW      (2),
      .DEFAULT (2'b0),
      .CYCLES  (3)
   ) up_dec2gpr_wr_scope_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_wrd_scope_o) ,
      .dout_o  (gpr_wr_scope_i)
   );   
   /*
   ppl_ctl u_ppl_ctl();
   
   dmem_acc u_dmem_acc();
   */
   
   
   
endmodule