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

`include "instructions.v"

module hvcore (
   input             clk               ,
   input             rst_n             ,
   
   // instruction interface
   input    [31:0]   instr_i           , // instruction got
   input             instr_valid_i     , // is the instruction access valid (cache hit?)
   output   [31:0]   instr_addr_o      , // instruction address
   output            imem_en_o         ,
   
   // mem interface
   input    [31:0]   dmem_rdata_i      , // 
   input             dmem_rdata_valid_i, // read data valid
   output   [31:0]   dmem_addr_o       ,
   output   [31:0]   dmem_wdata_o      ,
   output            dmem_en_o         ,
   output            dmem_wr_o         ,
   output   [1:0]    dmem_wscope_o     ,
   // IO interface
   input    [31:0]   io_rdata_i        ,
   input             io_valid_i        ,   
   output   [31:0]   io_addr_o         ,
   output            io_en_o           ,
   output            io_wr_o           ,
   output   [31:0]   io_wdata_o        
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
   
   // interface with csreg 
   wire  [31:0]   instr_dec_csreg_i           ;
   wire           instr_dec_aluflags_pending_i;
   wire           instr_dec_aluflags_ahead_o  ;
   
   // output for execution code
   wire [5:0]     instr_dec_opcode_o    ;
   wire           instr_dec_signed_o    ;
   
   // output for writing back register
   wire           instr_dec_wen_d_o     ;
   wire [3:0]     instr_dec_reg_d_idx_o ; 
   wire [1:0]     instr_dec_wrd_scope_o ; // scope of write (bit 1: high half, bit 0: low half)
   
   // interface with jump & pipeline control
   wire           instr_dec_stall_i       ; 
   wire           instr_dec_asif_nop_i    ;
   wire           instr_dec_d_conflict_o  ;
   wire           instr_dec_need_ddep2j_transit_o;
   wire           instr_dec_will_jump_o   ;
   wire           instr_dec_pc_based_jmp_o;
   wire           instr_dec_jump_req_o    ; // stall request pulse   
   wire           instr_dec_jump_exe_i    ; 
   
   // assign   instr_dec_jump_exe_i = jmpex_jump_done_o;
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
      
      // interface with csreg 
      .csreg_i             (instr_dec_csreg_i), 
      .aluflags_pending_i  (instr_dec_aluflags_pending_i),
      .aluflags_ahead_o    (instr_dec_aluflags_ahead_o),
      
      .opcode_o    (instr_dec_opcode_o) ,
      .signed_o    (instr_dec_signed_o) ,
      
      // output for writing back register
      .wen_d_o     (instr_dec_wen_d_o) ,
      .reg_d_idx_o (instr_dec_reg_d_idx_o) , 
      .wrd_scope_o (instr_dec_wrd_scope_o) , // scope of write (bit 1: high half, bit 0: low half)
      
      .stall_i       (instr_dec_stall_i)        ,
      .asif_nop_i    (instr_dec_asif_nop_i)     ,
      .d_conflict_o  (instr_dec_d_conflict_o)   ,
      .need_ddep2j_transit_o  (instr_dec_need_ddep2j_transit_o),
      .will_jump_o   (instr_dec_will_jump_o)    ,
      .pc_based_jmp_o(instr_dec_pc_based_jmp_o) ,
      .jump_req_o    (instr_dec_jump_req_o)     , // stall request pulse
      .jump_exe_i    (instr_dec_jump_exe_i)
   );
   
   wire  [3:0]    gpr_reg_w_idx_i; // index of reg to write
   wire  [31:0]   gpr_wdata_i    ; // data to write into reg d
   wire           gpr_wen_i      ; // write enable
   wire  [1:0]    gpr_wr_scope_i ; // scope of write (bit 1: high half, bit 0: low half)
   
   wire  [3:0]    gpr_ra_index_i ; // reg a index to read
   wire           gpr_ren_a_i    ; // read enable reg a
   wire  [3:0]    gpr_rb_index_i ; // reg b index
   wire           gpr_ren_b_i    ; // read enable - reg b
   wire  [3:0]    gpr_rm_index_i ; // reg m index
   wire           gpr_ren_m_i    ; // read enable - reg m   
   
   wire  [31:0]   gpr_rvalue_a_o ; // data value of reg a read
   wire  [31:0]   gpr_rvalue_b_o ; // data value of reg b read
   wire  [31:0]   gpr_rvalue_m_o ; // data value of reg m read
   
   wire           hold2grp_i     ;
   connect #( .DW(4) ) uconn_dec2gpr_reg_a_idx (
      .clk     (clk        ),
      .hold_i  (hold2grp_i ),
      .din_i   (instr_dec_reg_a_idx_o  ),
      .dout_o  (gpr_ra_index_i         )
   );
   connect uconn_dec2gpr_ren_a (
      .clk     (clk        ),
      .hold_i  (hold2grp_i ),
      .din_i   (instr_dec_ren_a_o   ),
      .dout_o  (gpr_ren_a_i         )
   );
   connect #( .DW(4) ) uconn_dec2gpr_reg_b_idx (
      .clk     (clk        ),
      .hold_i  (hold2grp_i ),
      .din_i   (instr_dec_reg_b_idx_o  ),
      .dout_o  (gpr_rb_index_i         )
   );
   connect uconn_dec2gpr_ren_b (
      .clk     (clk        ),
      .hold_i  (hold2grp_i ),
      .din_i   (instr_dec_ren_b_o   ),
      .dout_o  (gpr_ren_b_i         )
   );     
   connect #( .DW(4) ) uconn_dec2gpr_reg_m_idx (
      .clk     (clk        ),
      .hold_i  (hold2grp_i ),
      .din_i   (instr_dec_reg_m_idx_o  ),
      .dout_o  (gpr_rm_index_i         )
   );
   connect uconn_dec2gpr_ren_m (
      .clk     (clk        ),
      .hold_i  (hold2grp_i ),
      .din_i   (instr_dec_ren_m_o   ),
      .dout_o  (gpr_ren_m_i         )
   );     
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
   
   // from instr_dec
   wire              opgen_ren_a_i     ;   
   wire              opgen_ren_b_i     ;
   wire              opgen_imm_valid_i ;
   wire  [19:0]      opgen_imm_raw_i   ;
   wire  [2:0]       opgen_imm_rule_i  ;
   wire  [31:0]      opgen_ra_value_i  ;
   wire  [31:0]      opgen_rb_value_i  ;
   // B&J type instruction should compute pc + offset as new pc
   wire              opgen_pc_based_jump_i   ;   
   // current instruction address
   wire  [31:0]      opgen_i_addr_i    ;
   // output data as oprands;
   wire  [31:0]      opgen_oprand_a_o  ;
   wire  [31:0]      opgen_oprand_b_o  ;  
   
   // hold on signal
   wire              hold2opgen_i      ;
   
   connect uconn_dec2opgen_ren_a (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (instr_dec_ren_a_o   ),
      .dout_o  (opgen_ren_a_i       )
   );  
   connect uconn_dec2opgen_ren_b (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (instr_dec_ren_b_o   ),
      .dout_o  (opgen_ren_b_i       )
   ); 
   connect uconn_dec2opgen_imm_valid (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (instr_dec_imm_valid_o  ),
      .dout_o  (opgen_imm_valid_i      )
   ); 
   connect #( .DW(20) ) uconn_dec2opgen_imm_raw (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (instr_dec_imm_raw_o    ),
      .dout_o  (opgen_imm_raw_i        )
   );
   connect #( .DW(3) ) uconn_dec2opgen_imm_rule (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (instr_dec_imm_rule_o   ),
      .dout_o  (opgen_imm_rule_i       )
   );
   connect uconn_dec2opgen_pc_based_jump (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (instr_dec_pc_based_jmp_o  ),
      .dout_o  (opgen_pc_based_jump_i     )
   );
   connect #( .DW(32) ) uconn_gpr2opgen_ra_value (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (gpr_rvalue_a_o   ),
      .dout_o  (opgen_ra_value_i )
   );
   connect #( .DW(32) ) uconn_gpr2opgen_rb_value (
      .clk     (clk           ),
      .hold_i  (hold2opgen_i  ),
      .din_i   (gpr_rvalue_b_o   ),
      .dout_o  (opgen_rb_value_i )
   );
   // of course it's OK to pass the pc value thru the pipeline, 
   // but when will execute jumping, the PC shall be stalled,
   //    so PC mod output keep being the B & J instruction address
   assign   opgen_i_addr_i =  instr_addr_o;  
   oprand_gen u_oprand_gen (
      .clk              (clk) ,
      .rst_n            (rst_n) ,
            
      .ren_a_i          (opgen_ren_a_i) ,   
      .ren_b_i          (opgen_ren_b_i) ,
      .imm_valid_i      (opgen_imm_valid_i) ,
      .imm_raw_i        (opgen_imm_raw_i) ,
      .imm_rule_i       (opgen_imm_rule_i) ,
      
      .pc_based_jump_i  (opgen_pc_based_jump_i) ,
      
      .ra_value_i       (opgen_ra_value_i) ,
      .rb_value_i       (opgen_rb_value_i) ,
            
      .i_addr_i         (opgen_i_addr_i) ,
            
      .oprand_a_o       (opgen_oprand_a_o) ,
      .oprand_b_o       (opgen_oprand_b_o) 
   );
   
   // from instr_dec to alu
   wire  [5:0]       alu_opcode_i   ;
   wire              alu_signed_i   ;
   // from opgen to alu
   wire  [31:0]      alu_oprand_a_i ;
   wire  [31:0]      alu_oprand_b_i ;
   
   wire              hold2alu_i     ;
   
   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP)
   ) up_dec2alu_opcode_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .hold_i  (hold2alu_i ),
      .din_i   (instr_dec_opcode_o  ),
      .dout_o  (alu_opcode_i        )
   );
   
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0)
   ) up_dec2alu_signed_qieman (
      .clk     (clk)    ,
      .rst_n   (rst_n)  ,
      .hold_i  (hold2alu_i ),
      .din_i   (instr_dec_signed_o  ),
      .dout_o  (alu_signed_i        )
   );
   
   connect #( .DW(32) ) uconn_opgen2alu_oprand_a (
      .clk     (clk        ),
      .hold_i  (hold2alu_i ),
      .din_i   (opgen_oprand_a_o ),
      .dout_o  (alu_oprand_a_i   )
   );
   connect #( .DW(32) ) uconn_opgen2alu_oprand_b (
      .clk     (clk        ),
      .hold_i  (hold2alu_i ),
      .din_i   (opgen_oprand_b_o ),
      .dout_o  (alu_oprand_b_i   )
   );
   
   // alu output
   wire  [31:0]   alu_result_o   ;
   wire           alu_flags_chg_o;
   wire  [3:0]    alu_flags_o    ;     
   // stall signal to alu
   wire           alu_stall_i    ;
   
   alu u_alu (
      .clk           (clk) ,
      .rst_n         (rst_n) ,
         
      .opcode_i      (alu_opcode_i) ,
      .signed_i      (alu_signed_i) ,
         
      .oprand_a_i    (alu_oprand_a_i) ,
      .oprand_b_i    (alu_oprand_b_i) ,
         
      .result_o      (alu_result_o  ) ,
      .flags_chg_o   (alu_flags_chg_o) ,
      .flags_o       (alu_flags_o   ) ,      
     
      .stall_i       (alu_stall_i)
   );


   // from dec (one pulse per one case)
   wire           csreg_aluflags_ahead_i  ;
   // the current reg value;
   wire  [31:0]   csreg_csreg_o           ;
   wire           csreg_aluflags_pending_o; 
   // once stalled, dec will not generate aluflags_ahead signal
   // once stalled, alu shall not generate flags_chg signal as well
   // as such, the csreg doesn't need another stall input
   csreg u_csreg(
      .clk                 (clk     ),
      .rst_n               (rst_n   ),
      .aluflags_ahead_i    (instr_dec_aluflags_ahead_o  )  , // one pulse per one case
      .aluflags_wen_i      (alu_flags_chg_o  )  , // one pulse per one case
      .aluflags_i          (alu_flags_o  )  ,
      .csreg_o             (csreg_csreg_o  )  ,
      .aluflags_pending_o  (csreg_aluflags_pending_o  )
      
   );
   assign   instr_dec_csreg_i =  csreg_csreg_o;
   assign   instr_dec_aluflags_pending_i  =  csreg_aluflags_pending_o;
   
   // from dec 
   wire    [5:0]       memex_opcode_i;
   wire                memex_signed_i;
   // from op_gen ;
   wire    [31:0]      memex_wdata_i ;
   // from alu ;
   wire    [31:0]      memex_addr_i  ;  
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

   wire     hold2memex_i;
   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (2)
   ) up_dec2memex_opcode_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2memex_i  ),
      .din_i   (instr_dec_opcode_o  ),
      .dout_o  (memex_opcode_i      )
   );
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0),
      .CYCLES  (2)
   ) up_dec2memex_signed_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2memex_i  ),
      .din_i   (instr_dec_signed_o  ),
      .dout_o  (memex_signed_i      )
   );   
   
   qieman #(
      .DW      (32),
      .DEFAULT (32'b0),
      .CYCLES  (2)
   ) up_decgpr2memex_rvalue_m_qieman (
      .clk     (clk  )  ,
      .rst_n   (rst_n)  ,
      .hold_i  (hold2memex_i  ),
      .din_i   (gpr_rvalue_m_o),
      .dout_o  (memex_wdata_i )
   );
   
   connect #(  .DW(32)  ) uconn_alu2memexe_addr (
      .clk     (clk           ),
      .hold_i  (hold2memex_i  ),
      .din_i   (alu_result_o  ),
      .dout_o  (memex_addr_i  )
   );
   mem_exe u_mem_exe (
      .clk         (clk) ,
      .rst_n       (rst_n) ,   
      // from dec (directly) 
      .opcode_i    (memex_opcode_i) ,
      .signed_i    (memex_signed_i) ,
      // from dec (read from register) 
      .wdata_i     (memex_wdata_i) ,
      // from alu 
      .addr_i      (memex_addr_i) ,   
      // external
      .mem_addr_o  (memex_mem_addr_o) ,
      .mem_wdata_o (memex_mem_wdata_o) ,
      .mem_en_o    (memex_mem_en_o) ,
      .mem_wr_o    (memex_mem_wr_o) ,   
      .mem_wscope_o(memex_mem_wscope_o) ,
      // to mem rx
      .ren_o       (memex_ren_o) , // reading?
      .scope_o     (memex_scope_o) , // word(2'b11), half word(2'b01), or byte(2'b00)?
      .signed_o    (memex_signed_o) ,
      .addr_lsb2_o (memex_addr_lsb2_o)   // least 2 bits of the address
   );
   
   wire           hold2memio_i         ;
   
   wire  [31:0]   dispatch_addr_i      ;
   wire           dispatch_en_i        ;
   wire           dispatch_wr_i        ;
   wire  [31:0]   dispatch_wdata_i     ;
   wire  [1:0]    dispatch_wscope_i    ;
   // output for memory interface
   wire  [31:0]   dispatch_mem_addr_o  ;
   wire           dispatch_mem_en_o    ;
   wire           dispatch_mem_wr_o    ;
   wire  [31:0]   dispatch_mem_wdata_o ;
   wire  [1:0]    dispatch_mem_wscope_o; 
   // output for IO
   wire  [31:0]   dispatch_io_addr_o   ;
   wire           dispatch_io_en_o     ;
   wire           dispatch_io_wr_o     ;
   wire  [31:0]   dispatch_io_wdata_o  ;  
   
   connect #(  .DW(32)  ) uconn_memexe2mem_addr (
      .clk     (clk           ),
      .hold_i  (hold2memio_i  ),
      .din_i   (memex_mem_addr_o ),
      .dout_o  (dispatch_addr_i  )
   );   
   connect #(  .DW(32)  ) uconn_memexe2mem_wdata (
      .clk     (clk           ),
      .hold_i  (hold2memio_i  ),
      .din_i   (memex_mem_wdata_o),
      .dout_o  (dispatch_wdata_i )
   );
   connect uconn_memexe2mem_en (
      .clk     (clk           ),
      .hold_i  (hold2memio_i  ),
      .din_i   (memex_mem_en_o),
      .dout_o  (dispatch_en_i )
   );
   connect uconn_memexe2mem_wr (
      .clk     (clk           ),
      .hold_i  (hold2memio_i  ),
      .din_i   (memex_mem_wr_o),
      .dout_o  (dispatch_wr_i )
   );
   connect #( .DW(2) ) uconn_memexe2mem_wscope (
      .clk     (clk           ),
      .hold_i  (hold2memio_i  ),
      .din_i   (memex_mem_wscope_o  ),
      .dout_o  (dispatch_wscope_i   )
   );
   
   ldstio_dispatcher u_dispatch(
      // unified load store interface  
      .addr_i      (dispatch_addr_i      ),
      .en_i        (dispatch_en_i        ),
      .wr_i        (dispatch_wr_i        ),
      .wdata_i     (dispatch_wdata_i     ),
      .wscope_i    (dispatch_wscope_i    ),
      // output for memory interface
      .mem_addr_o  (dispatch_mem_addr_o  ),
      .mem_en_o    (dispatch_mem_en_o    ),
      .mem_wr_o    (dispatch_mem_wr_o    ),
      .mem_wdata_o (dispatch_mem_wdata_o ),
      .mem_wscope_o(dispatch_mem_wscope_o), 
      // output for IO
      .io_addr_o   (dispatch_io_addr_o   ),
      .io_en_o     (dispatch_io_en_o     ),
      .io_wr_o     (dispatch_io_wr_o     ),
      .io_wdata_o  (dispatch_io_wdata_o  )
   );
   assign   dmem_addr_o  = dispatch_mem_addr_o  ;
   assign   dmem_en_o    = dispatch_mem_en_o    ;
   assign   dmem_wr_o    = dispatch_mem_wr_o    ;
   assign   dmem_wdata_o = dispatch_mem_wdata_o ;  
   assign   dmem_wscope_o= dispatch_mem_wscope_o;
//   connect #(  .DW(32)  ) uconn_memexe2mem_addr (
//      .clk     (clk           ),
//      .hold_i  (hold2memex_i  ),
//      .din_i   (memex_mem_addr_o ),
//      .dout_o  (dmem_addr_o      )
//   );   
//   connect #(  .DW(32)  ) uconn_memexe2mem_wdata (
//      .clk     (clk           ),
//      .hold_i  (hold2memex_i  ),
//      .din_i   (memex_mem_wdata_o),
//      .dout_o  (dmem_wdata_o     )
//   );
//   connect uconn_memexe2mem_en (
//      .clk     (clk           ),
//      .hold_i  (hold2memex_i  ),
//      .din_i   (memex_mem_en_o),
//      .dout_o  (dmem_en_o     )
//   );
//   connect uconn_memexe2mem_wr (
//      .clk     (clk           ),
//      .hold_i  (hold2memex_i  ),
//      .din_i   (memex_mem_wr_o),
//      .dout_o  (dmem_wr_o     )
//   );
//   connect #( .DW(2) ) uconn_memexe2mem_wscope (
//      .clk     (clk           ),
//      .hold_i  (hold2memex_i  ),
//      .din_i   (memex_mem_wscope_o  ),
//      .dout_o  (dmem_wscope_o       )
//   );
   
   assign   io_addr_o   =  dispatch_io_addr_o   ;
   assign   io_en_o     =  dispatch_io_en_o     ;
   assign   io_wr_o     =  dispatch_io_wr_o     ;
   assign   io_wdata_o  =  dispatch_io_wdata_o  ;
   
   wire  [1:0]    collect_en_i         ;
   wire  [31:0]   collect_mem_rdata_i  ;
   wire           collect_mem_dmiss_i  ;
   wire  [31:0]   collect_io_rdata_i   ;
   wire           collect_io_valid_i   ;
   wire  [31:0]   collect_rdata_o      ;
   wire           collect_data_miss_o  ;
   wire           collect_valid_o      ;
   
   wire  [1:0] dispatch2collect_enbitmap  ;
   assign      dispatch2collect_enbitmap  =  {dispatch_mem_en_o, dispatch_io_en_o};
   qieman #(
      .DW      (2),
      .DEFAULT (2'b0)
   ) up_memexe2memacc_enbitmap_qieman (
      .clk     (clk  )  ,
      .rst_n   (rst_n)  ,
      .hold_i  (hold2memio_i  ),
      .din_i   (dispatch2collect_enbitmap ),
      .dout_o  (collect_en_i              )
   );
   assign   collect_io_rdata_i   =  io_rdata_i  ;
   assign   collect_io_valid_i   =  io_valid_i  ;
   assign   collect_mem_rdata_i  =  dmem_rdata_i;
   assign   collect_mem_dmiss_i  =  ~dmem_rdata_valid_i;
   
   ldstio_collector u_collect (
      .en_i           (collect_en_i         ),  // which one? 2'b10 mem, 2'b01 io
      .mem_rdata_i    (collect_mem_rdata_i  ),
      .mem_dmiss_i    (collect_mem_dmiss_i  ),
      .io_rdata_i     (collect_io_rdata_i   ),
      .io_valid_i     (collect_io_valid_i   ),
      // unified data
      .rdata_o        (collect_rdata_o      ),
      .data_miss_o    (collect_data_miss_o  ),
      .valid_o        (collect_valid_o      )
   );
   
   // input shall be from mem-exe
   wire           memacc_rx_ren_i         ;  // I'm reading the mem
   wire  [1:0]    memacc_rx_scope_i       ;  // are you reading word, half word, or byte?
   wire           memacc_rx_signed_i      ;  
   wire  [1:0]    memacc_rx_addr_lsb2_i   ;  // least 2 bits of the address
   // input shall be from mem
   wire  [31:0]   memacc_rx_rdata_i       ; 
   wire           memacc_data_miss_i      ;
   wire  [31:0]   memacc_rx_data_o        ;
   wire           memacc_rx_data_valid_o  ;
   // to stall the pipeline
   //wire           memacc_rx_stall_req_o   ;
   wire           memacc_rx_dmiss_req_o   ;
   
   wire           holdmemex2acc_i;
//   assign memacc_rx_ren_i        =  memex_ren_o    ;
//   assign memacc_rx_scope_i      =  memex_scope_o  ;
//   assign memacc_rx_signed_i     =  memex_signed_o ;
//   assign memacc_rx_addr_lsb2_i  =  memex_addr_lsb2_o ;  
   // the following connection won't help to hold,
   // because it will take values of previous cycle 
   // (this part from memexe to memacc is one cycle later than the part from memexe to mem)
   connect uconn_memexe2memacc_ren (
      .clk     (clk              ),
      .hold_i  (holdmemex2acc_i  ),
      .din_i   (memex_ren_o      ),
      .dout_o  (memacc_rx_ren_i  )
   );
   connect #( .DW(2) ) uconn_memexe2memacc_scope (
      .clk     (clk              ),
      .hold_i  (holdmemex2acc_i  ),
      .din_i   (memex_scope_o    ),
      .dout_o  (memacc_rx_scope_i)
   );
   connect uconn_memexe2memacc_signed (
      .clk     (clk              ),
      .hold_i  (holdmemex2acc_i  ),
      .din_i   (memex_signed_o      ),
      .dout_o  (memacc_rx_signed_i  )
   );
   connect #( .DW(2) ) uconn_memexe2memacc_addr_lsb2 (
      .clk     (clk              ),
      .hold_i  (holdmemex2acc_i  ),
      .din_i   (memex_addr_lsb2_o      ),
      .dout_o  (memacc_rx_addr_lsb2_i  )
   );
   // however you must monitor the real time data from mem, don't use hold on data
   assign memacc_rx_rdata_i   = collect_rdata_o    ;
   assign memacc_data_miss_i  = collect_data_miss_o;
   
   memacc_rx u_memacc_rx(
      .clk           (clk) ,
      .rst_n         (rst_n) ,
      .ren_i         (memacc_rx_ren_i) ,  // I'm reading the mem
      .scope_i       (memacc_rx_scope_i) ,  // are you reading word, half word, or byte?
      .signed_i      (memacc_rx_signed_i) ,  
      .addr_lsb2_i   (memacc_rx_addr_lsb2_i) ,  // least 2 bits of the address
      // from mem / cache  .
      .rdata_i       (memacc_rx_rdata_i) ,
      // .rdata_miss_i   (1'b0) , // work with an always-ready never-fail mem
      .data_miss_i   (memacc_data_miss_i),
      // to wb.
      .data_o        (memacc_rx_data_o) ,
      .data_valid_o  (memacc_rx_data_valid_o) ,
      // access was invalid
      //.stall_req_o   (memacc_rx_stall_req_o)
      .dmiss_req_o   (memacc_rx_dmiss_req_o) 
   );

   wire     [31:0]      wb_pc_i        ;  // from pc
   wire     [5:0]       wb_opcode_i    ;  // from dec
   wire     [31:0]      wb_opgen_i     ;
   wire     [31:0]      wb_alu_i       ;
   // wire     [31:0]      wb_mem_i       ;  // from data memory (dcache)

   wire     [31:0]      wb_wrdata_o    ;
   wire                 wb_wr_allowed_o;     
   
   wire                 hold2wb_i      ;
   
   qieman #(
      .DW      (32),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (5)
   ) up_pc2wb_pc_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (instr_addr_o+4),
      .dout_o  (wb_pc_i       )
   );
   
   qieman #(
      .DW      (6),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (4)
   ) up_dec2wb_opcode_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (instr_dec_opcode_o  ),
      .dout_o  (wb_opcode_i         )
   );
   
   qieman #(
      .DW      (32),
      .DEFAULT (`OPCODE_NOP),
      .CYCLES  (3)
   ) up_opgen2wb_oprand_b_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (opgen_oprand_b_o ),
      .dout_o  (wb_opgen_i       )
   );   
   
   qieman #(
      .DW      (32),
      .DEFAULT (32'b0),
      .CYCLES  (2)
   ) up_alu2wb_result_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (alu_result_o  ),
      .dout_o  (wb_alu_i      )
   );
   
   wb_sel u_wb_sel ( 
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
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (instr_dec_reg_d_idx_o  ),  
      .dout_o  (gpr_reg_w_idx_i        )
   );
   
   assign gpr_wdata_i = wb_wrdata_o;

   wire gpr_wen_decpassed;
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0),
      .CYCLES  (4)
   ) up_dec2gpr_wen_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (instr_dec_wen_d_o   ),   
      .dout_o  (gpr_wen_decpassed   )
   );   
   assign gpr_wen_i = gpr_wen_decpassed & wb_wr_allowed_o;

   qieman #(
      .DW      (2),
      .DEFAULT (2'b0),
      .CYCLES  (4)
   ) up_dec2gpr_wr_scope_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2wb_i  ),
      .din_i   (instr_dec_wrd_scope_o  ),   
      .dout_o  (gpr_wr_scope_i         )
   );   
   
   // from dec, jump request pulse
   wire           jmpex_jump_req_i  ;  
   wire  [31:0]   jmpex_j2addr_i    ;
   // output to pc;
   wire  [31:0]   jmpex_new_pc_o    ;
   wire           jmpex_change_pc_o ;
   // signal that jump made;
   wire           jmpex_jump_done_o ;  
   
   wire           hold2jmpexe_i     ;
   
   qieman #(
      .DW      (1),
      .DEFAULT (1'b0),
      .CYCLES  (2)
   ) up_dec2jmpexe_wr_scope_qieman (
      .clk     (clk  ),
      .rst_n   (rst_n),
      .hold_i  (hold2jmpexe_i ),
      .din_i   (instr_dec_jump_req_o),   
      .dout_o  (jmpex_jump_req_i    )
   );   
   connect #(  .DW(32)  ) uconn_alu2jmpexe_j2addr (
      .clk     (clk           ),
      .hold_i  (hold2jmpexe_i ),
      .din_i   (alu_result_o  ),
      .dout_o  (jmpex_j2addr_i)
   );
   jmp_exe u_jmp_exe(
      .clk         (clk) ,
      .rst_n       (rst_n) ,
      // from dec, jump request pulse 
      .jump_req_i  (jmpex_jump_req_i) ,   
      // from alu 
      .j2addr_i    (alu_result_o) ,
      // output to pc
      .new_pc_o    (jmpex_new_pc_o) ,
      .change_pc_o (jmpex_change_pc_o) ,
      // signal that jump execute
      .jump_done_o (jmpex_jump_done_o) 
   );
   assign   instr_dec_jump_exe_i = jmpex_jump_done_o;
   
   assign   pc_new_pc_i    =  jmpex_new_pc_o;
   assign   pc_change_pc_i =  jmpex_change_pc_o;
   
   wire  pp_ctrl_mem_dmiss_i  ;
   wire  pp_ctrl_stall_2pc_o  ;
   wire  pp_ctrl_stall_2dec_o ;   
   wire  pp_ctrl_stall_2alu_o ;
   wire  pp_ctrl_asif_nop_2dec_o ;
   wire  pp_ctrl_hold_by_mem_o;
   
   //assign pp_ctrl_mem_dmiss_i = ~dmem_rdata_valid_i;
   assign pp_ctrl_mem_dmiss_i = memacc_rx_dmiss_req_o;
   pp_ctrl u_pp_ctrl (
      .clk                 (clk) ,
      .rst_n               (rst_n) ,
      // data (GPR) dependency
      .ddep_conflict_i     (instr_dec_d_conflict_o) ,
      // ddep stall to jmp stall transit
      .need_ddep2j_transit_i  (instr_dec_need_ddep2j_transit_o),
      // b & j stall request
      .bj_req_i            (instr_dec_jump_req_o) ,
      // b/j jump made, must be one pulse signal
      .bj_done_i           (jmpex_jump_done_o) , 
      // from mem, data miss & need wait to load data
      .mem_dmiss_i         (pp_ctrl_mem_dmiss_i),
   
      // should have seperate stall signals
      .stall_2pc_o         (pp_ctrl_stall_2pc_o) ,
      .stall_2dec_o        (pp_ctrl_stall_2dec_o),
      .stall_2alu_o        (pp_ctrl_stall_2alu_o),
      //
      .asif_nop_2dec_o     (pp_ctrl_asif_nop_2dec_o),
      .hold_all_by_mem_o   (pp_ctrl_hold_by_mem_o)
   );
   
   assign pc_stall_i = pp_ctrl_stall_2pc_o;
   assign instr_dec_stall_i = pp_ctrl_stall_2dec_o;
   assign instr_dec_asif_nop_i = pp_ctrl_asif_nop_2dec_o;
   assign alu_stall_i = pp_ctrl_stall_2alu_o;
   
   assign hold2grp_i       =  (1'b0 | pp_ctrl_hold_by_mem_o);
   assign hold2opgen_i     =  (1'b0 | pp_ctrl_hold_by_mem_o);
   assign hold2alu_i       =  (1'b0 | pp_ctrl_hold_by_mem_o);
   assign hold2memex_i     =  (1'b0 | pp_ctrl_hold_by_mem_o);
   assign hold2memio_i     =  (1'b0 | pp_ctrl_hold_by_mem_o);
   // assign holdmemex2acc_i  =  (1'b0 | pp_ctrl_hold_by_mem_o); // you should not do this!!!
   assign holdmemex2acc_i  =  (1'b0);
   assign hold2wb_i        =  (1'b0 | pp_ctrl_hold_by_mem_o); // maybe don't need hold on everything, but at least need holds on signals passed from early stage such as wen from dec
   assign hold2jmpexe_i    =  (1'b0 | pp_ctrl_hold_by_mem_o);
   
endmodule