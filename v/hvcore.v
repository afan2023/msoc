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
   output            dmem_wr_o         ,
   output   [1:0]    dmem_wscope_o     
   );
   
   //wire [31:0] pc_i_addr_o;
   //wire        pc_i_fetch_en_o;
   wire [31:0] pc_new_pc_i;
   wire        pc_change_pc_i;
   wire        pc_stall_i;
   wire        pc_halt_i;
   assign pc_halt_i = 1'b0;
   pc u_pc (
      .clk            (clk),
      .rst_n          (rst_n),
      .i_addr_o       (instr_addr_o),
      .i_fetch_en_o   (imem_en_o),
      .new_pc_i       (pc_new_pc_i),
      .change_pc_i    (pc_change_pc_i),
      .stall_i        (pc_stall_i),
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
   // output for reg value to write mem
   wire           instr_dec_ren_m_o     ;
   wire [3:0]     instr_dec_reg_m_idx_o ;
   
   // output for execution code
   wire [5:0]     instr_dec_opcode_o    ;
   wire           instr_dec_signed_o    ;
   
   // output for writing back register
   wire           instr_dec_wen_d_o     ;
   wire [3:0]     instr_dec_reg_d_idx_o ; 
   wire [1:0]     instr_dec_wrd_scope_o ; // scope of write (bit 1: high half, bit 0: low half)
   
   // interface with pipeline control
   wire           instr_dec_stall_i     ;  
   wire           instr_dec_d_conflict_o;
   
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
      
      .ren_m_o     (instr_dec_ren_m_o) ,
      .reg_m_idx_o (instr_dec_reg_m_idx_o) ,
      
      .opcode_o    (instr_dec_opcode_o) ,
      .signed_o    (instr_dec_signed_o) ,
      
      // output for writing back register
      .wen_d_o     (instr_dec_wen_d_o) ,
      .reg_d_idx_o (instr_dec_reg_d_idx_o) , 
      .wrd_scope_o (instr_dec_wrd_scope_o) , // scope of write (bit 1: high half, bit 0: low half)
      
      .stall_i     (instr_dec_stall_i)     ,
      .d_conflict_o(instr_dec_d_conflict_o)
   );
   
   wire  [3:0]    gpr_reg_w_idx_i ; // index of reg to write
   wire  [31:0]   gpr_wdata_i     ; // data to write into reg d
   wire           gpr_wen_i       ; // write enable
   wire  [1:0]    gpr_wr_scope_i  ; // scope of write (bit 1: high half, bit 0: low half)

   wire  [31:0]   gpr_rvalue_a_o  ; // data value of reg a read
   wire  [31:0]   gpr_rvalue_b_o  ; // data value of reg b read
   wire  [31:0]   gpr_rvalue_m_o  ; // data value of reg m read
   
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
      .rm_index_i  (instr_dec_reg_m_idx_o) ,
      .ren_m_i     (instr_dec_ren_m_o) ,
      
      .rvalue_a_o  (gpr_rvalue_a_o) , 
      .rvalue_b_o  (gpr_rvalue_b_o) ,
      .rvalue_m_o  (gpr_rvalue_m_o) 
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
   
   // from dec 
   wire    [5:0]       memex_opcode_i;
   wire                memex_signed_i;
   // from op_gen ;
   wire    [31:0]      memex_wdata_i ;
   // from alu ;
   // wire    [31:0]      memex_addr_i  ;  
   // external;
   wire   [31:0]  memex_mem_addr_o  ;
   wire   [31:0]  memex_mem_wdata_o ;
   wire           memex_mem_en_o    ;
   wire           memex_mem_wr_o    ;  
   wire   [1:0]   memex_mem_wscope_o;
   // to mem rx;
   wire           memex_ren_o       ;// reading?
   wire [1:0]     memex_scope_o     ;// word(2'b11), half word(2'b01), or byte(2'b00)?
   wire           memex_signed_o    ;
   wire [1:0]     memex_addr_lsb2_o ;// least 2 bits of the address

   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (2)
   ) up_dec2memex_opcode_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_opcode_o) ,
      .dout_o  (memex_opcode_i)
   );
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0),
      .CYCLES  (2)
   ) up_dec2memex_signed_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_signed_o) ,
      .dout_o  (memex_signed_i)
   );   
   
   qieman #(
      .DW      (32),
      .DEFAULT (32'b0),
      .CYCLES  (2)
   ) up_decgpr2memex_rvalue_m_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (gpr_rvalue_m_o) ,
      .dout_o  (memex_wdata_i)
   );
        
   mem_exe u_mem_exe (
      .clk         (clk) ,
      .rst_n       (rst_n) ,   
      // from dec (directly) 
      .opcode_i    (memex_opcode_i) ,
      .signed_i    (memex_signed_i) ,
      // from dec (read from register) 
      .wdata_i     (memex_wdata_i) ,
      // from alu () 
      .addr_i      (alu_result_o) ,   
      // external()  
      .mem_addr_o  (memex_mem_addr_o) ,
      .mem_wdata_o (memex_mem_wdata_o) ,
      .mem_en_o    (memex_mem_en_o) ,
      .mem_wr_o    (memex_mem_wr_o) ,   
      .mem_wscope_o(memex_mem_wscope_o) ,
      // to mem rx() 
      .ren_o       (memex_ren_o) , // reading?
      .scope_o     (memex_scope_o) , // word(2'b11), half word(2'b01), or byte(2'b00)?
      .signed_o    (memex_signed_o) ,
      .addr_lsb2_o (memex_addr_lsb2_o)   // least 2 bits of the address
   );
   
   assign   dmem_addr_o  = memex_mem_addr_o  ;
   assign   dmem_wdata_o = memex_mem_wdata_o ;
   assign   dmem_en_o    = memex_mem_en_o ;
   assign   dmem_wr_o    = memex_mem_wr_o ; 
   assign   dmem_wscope_o= memex_mem_wscope_o ;
   
   wire  [31:0]   memacc_rx_rdata_i       ;      
   wire  [31:0]   memacc_rx_data_o        ;
   wire           memacc_rx_data_valid_o  ;
   // to stall the pipeline
   wire           memacc_rx_stall_req_o   ;
   
   assign memacc_rx_rdata_i = dmem_rdata_i;
   
   memacc_rx u_memacc_rx(
      .clk            (clk) ,
      .rst_n          (rst_n) ,
      .ren_i          (memex_ren_o) ,  // I'm reading the mem
      .scope_i        (memex_scope_o) ,  // are you reading word, half word, or byte?
      .signed_i       (memex_signed_o) ,  
      .addr_lsb2_i    (memex_addr_lsb2_o) ,  // least 2 bits of the address
      // from mem / cache  .
      .rdata_i        (memacc_rx_rdata_i) ,
      .rdata_miss_i   (1'b0) , // work with an always-ready never-fail mem
      // to wb.
      .data_o         (memacc_rx_data_o) ,
      .data_valid_o   (memacc_rx_data_valid_o) ,
      // to stall the pipeline
      .stall_req_o    (memacc_rx_stall_req_o)
   );

   wire     [31:0]      wb_pc_i        ;  // from pc
   wire     [5:0]       wb_opcode_i    ;  // from dec
   wire     [31:0]      wb_opgen_i     ;
   wire     [31:0]      wb_alu_i       ;
   // wire     [31:0]      wb_mem_i       ;  // from data memory (dcache)

   wire     [31:0]      wb_wrdata_o    ;
   wire                 wb_wr_allowed_o;
     
      
   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (4)
   ) up_dec2wb_opcode_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_opcode_o) ,
      .dout_o  (wb_opcode_i)
   );
   
   qieman #(
      .DW      (32),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (3)
   ) up_opgen2wb_oprand_b_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (opgen_oprand_b_o) ,
      .dout_o  (wb_opgen_i)
   );   
   
   qieman #(
      .DW      (32),
      .DEFAULT (32'b0),
      .CYCLES  (2)
   ) up_alu2wb_result_qieman (
      .clk            (clk)    ,
      .rst_n          (rst_n)  ,
      .din_i          (alu_result_o) ,
      .dout_o         (wb_alu_i)
   );
   
   wb_sel u_wb_sel ( // now use this version instead
      .clk           (clk) ,
      .rst_n         (rst_n) ,
         
      .pc_i          (wb_pc_i) ,      // from pc
      .opcode_i      (wb_opcode_i) ,  // from dec
      .opgen_i       (wb_opgen_i) ,
      .alu_i         (wb_alu_i) , // from alu execution
      .mem_i         (memacc_rx_data_o) ,     // from data memory (dcache)
      .mem_valid_i   (memacc_rx_data_valid_o) ,  // mem data valid or not
         
      .wrdata_o      (wb_wrdata_o) ,
      .wr_allowed_o  (wb_wr_allowed_o)
   );
   

   qieman #(
      .DW      (4),
      .DEFAULT (4'b0),
      .CYCLES  (4)
   ) up_dec2gpr_reg_w_idx_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_reg_d_idx_o) ,  
      .dout_o  (gpr_reg_w_idx_i)
   );
   
   assign gpr_wdata_i = wb_wrdata_o;

   wire grp_wen_decpassed;
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0),
      .CYCLES  (4)
   ) up_dec2gpr_wen_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_wen_d_o) ,   
      .dout_o  (grp_wen_decpassed)
   );   
   assign gpr_wen_i = grp_wen_decpassed & wb_wr_allowed_o;

   qieman #(
      .DW      (2),
      .DEFAULT (2'b0),
      .CYCLES  (4)
   ) up_dec2gpr_wr_scope_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .din_i   (instr_dec_wrd_scope_o) ,   
      .dout_o  (gpr_wr_scope_i)
   );   
   
   wire     pp_ctrl_stall_dec_o ;
   pp_ctrl u_pp_ctrl (
      .clk               (clk) ,
      .rst_n             (rst_n) ,
      .ddep_conflict_i   (instr_dec_d_conflict_o) ,
      .stall_dec_o       (pp_ctrl_stall_dec_o) 
   );
   
   assign instr_dec_stall_i = pp_ctrl_stall_dec_o;
   assign pc_stall_i = pp_ctrl_stall_dec_o;
   
endmodule