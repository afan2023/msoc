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
 * instruction decoder
 */

`include "instructions.v"
 
module instr_dec (
   input                clk            ,
   input                rst_n          ,
      
   // input instruction 
   input    [31:0]      instr_i        , 
   
   // output for oprands generation
   output reg           ren_a_o        ,
   output reg [3:0]     reg_a_idx_o    ,
   output reg           ren_b_o        ,
   output reg [3:0]     reg_b_idx_o    ,
   output reg           imm_valid_o    ,
   output reg [19:0]    imm_raw_o      ,
   output reg [2:0]     imm_rule_o     ,
   // output for reg value to write to memory
   output reg           ren_m_o        ,
   output reg [3:0]     reg_m_idx_o    ,
      
   // interface with csreg 
   input    [31:0]      csreg_i           , // cs reg value
   input                aluflags_pending_i,
   output               aluflags_ahead_o  ,
   
   // output for execution code
   output reg [5:0]     opcode_o       ,
   output reg           signed_o       ,
   
   // output for writing back register
   output reg           wen_d_o        ,
   output reg [3:0]     reg_d_idx_o    , 
   output reg [1:0]     wrd_scope_o    , // scope of write (bit 1: high half, bit 0: low half)
   
   // interface with pipeline control
   input                stall_i        , // stall may be originated from dec itself:-) or mem
   output               d_conflict_o   , // data conflict
   output               need_ddep2j_transit_o   , // need a transit from data dependency to jmp stall
   // for jump
   output               will_jump_o    ,
   output               pc_based_jmp_o , // relative jump (pc <= pc + offset)
   output               jump_req_o     , // stall request pulse due to B&J instructions
   input                jump_exe_i       // jump execution mod feedback
   );
   
   // decoding result, yet to be outputed
   reg           ren_a_r     ;
   reg [3:0]     reg_a_idx_r ;
   reg           ren_b_r     ;
   reg [3:0]     reg_b_idx_r ;
   reg           imm_valid_r ;
   reg [19:0]    imm_raw_r   ;
   reg [2:0]     imm_rule_r  ;   

   reg [5:0]     opcode_r    ;
   reg           signed_r    ;
   
   reg           ren_m_r     ;
   reg [3:0]     reg_m_idx_r ;   

   reg           wen_d_r     ;
   reg [3:0]     reg_d_idx_r ; 
   reg [1:0]     wrd_scope_r ; 
   
   wire  [5:0] opcode;
   wire  [1:0] opext;
   assign opcode  = instr_i[`INSTR_FIELD_OPCODE];
   assign opext   = instr_i[`INSTR_FIELD_OPEXT];
   
   wire  gpreg_d_conflict;
   reg   bwaiting_csrflags_r;
   assign d_conflict_o = gpreg_d_conflict | bwaiting_csrflags_r;
   reg   j_valid_r; // j instruction, jump will happen
   reg   b_valid_r; // meet branch condition, will jump
   assign   will_jump_o = (j_valid_r | b_valid_r) & (~jump_exe_i); // will jump
   reg   need_ddep2jmp_transit_r;
   assign   need_ddep2j_transit_o = need_ddep2jmp_transit_r;
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         opcode_r <= 6'b0;
      end
      else begin
         opcode_r <= opcode;    
      end
   end   
   
   wire  [3:0] opcat;
   assign opcat = instr_i[`INSTR_FIELD_OPCAT];   
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         signed_r <= 1'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
            signed_r <= opext[1];
         end
         `INSTR_OPCAT_LOGIC : begin
            signed_r <= 1'b0;
         end
         `INSTR_OPCAT_SHIFT : begin
            signed_r <= opext[1];
         end
         `INSTR_OPCAT_MOVE : begin
            signed_r <= 1'b0;
         end
         `INSTR_OPCAT_LD : begin
            signed_r <= opext[1];
         end
         `INSTR_OPCAT_ST : begin
            signed_r <= 1'b0;
         end
         `INSTR_OPCAT_J, `INSTR_OPCAT_B : begin
            signed_r <= 1'b1;
         end
         default : begin
            signed_r <= 1'b0;
         end         
      endcase
   end   
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         reg_a_idx_r <= 4'b0;
         reg_b_idx_r <= 4'b0;
         reg_d_idx_r <= 4'b0;
      end
      else begin
         reg_a_idx_r <= instr_i[`INSTR_FIELD_RA];
         reg_b_idx_r <= instr_i[`INSTR_FIELD_RB];
         reg_d_idx_r <= instr_i[`INSTR_FIELD_RD];
      end
   end

   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         ren_a_r <= 1'b0;
         ren_b_r <= 1'b0;         
         wen_d_r <= 1'b0;
         wrd_scope_r <= 2'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
            ren_a_r <= 1'b1;
            ren_b_r <= opext[0] ? 1'b0 : 1'b1;
            wen_d_r <= 1'b1;
            wrd_scope_r <= 2'b11;
         end
         `INSTR_OPCAT_LOGIC : begin
            ren_a_r <= 1'b1;
            ren_b_r <= opext[0] ? 1'b0 : 1'b1;
            wen_d_r <= 1'b1;
            wrd_scope_r <= 2'b11;
         end
         `INSTR_OPCAT_SHIFT : begin
            ren_a_r <= 1'b1;
            ren_b_r <= opext[0] ? 1'b0 : 1'b1;
            wen_d_r <= 1'b1;
            wrd_scope_r <= 2'b11;
         end
         `INSTR_OPCAT_MOVE : begin
            ren_a_r <= 1'b0;
            ren_b_r <= opext[0] ? 1'b0 : 1'b1;
            wen_d_r <= 1'b1;
            wrd_scope_r <= opcode[1:0];
         end
         `INSTR_OPCAT_LD : begin
            ren_a_r <= 1'b1;
            ren_b_r <= 1'b0;
            wen_d_r <= 1'b1;
            wrd_scope_r <= 2'b11;
         end
         `INSTR_OPCAT_ST : begin
            ren_a_r <= 1'b1;
            ren_b_r <= 1'b0;
            wen_d_r <= 1'b0;
            wrd_scope_r <= 2'b00;
         end
         `INSTR_OPCAT_B : begin
            ren_a_r <= 1'b0;
            ren_b_r <= 1'b0;
            wen_d_r <= 1'b0;
            wrd_scope_r <= 2'b00;
         end
         `INSTR_OPCAT_J : begin
            ren_a_r <= opcode[0]; // JR and JLR use Ra, others (J, JL) don't use reg
            ren_b_r <= 1'b0;
            if (opcode[1]) begin // JL, JLR instruction
               wen_d_r <= 1'b1;
               wrd_scope_r <= 2'b11;
            end 
            else begin
               wen_d_r <= 1'b0;
               wrd_scope_r <= 2'b0;
            end
         end
         default : begin
            ren_a_r <= 1'b0;
            ren_b_r <= 1'b0;
            wen_d_r <= 1'b0;
            wrd_scope_r <= 2'b00;
         end
      endcase
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         ren_m_r <= 1'b0;
         reg_m_idx_r <= 4'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ST : begin
            ren_m_r <= 1'b1;
            reg_m_idx_r <= instr_i[25:22];
         end
         default: begin
            ren_m_r <= 1'b0;
            reg_m_idx_r <= 4'b0;
         end
      endcase
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         imm_valid_r <= 1'b0;
         imm_raw_r <= 20'b0;         
         imm_rule_r <= `IMM_RULE_NONE;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
            imm_valid_r <= opext[0];
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I16;
         end
         `INSTR_OPCAT_LOGIC : begin
            imm_valid_r <= opext[0];
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I16;
         end
         `INSTR_OPCAT_ADDSUB : begin
            imm_valid_r <= opext[0];
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I5;
         end
         `INSTR_OPCAT_MOVE : begin
            imm_valid_r <= opext[0];
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I16;
         end
         `INSTR_OPCAT_LD : begin
            imm_valid_r <= 1'b1;
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I12S4;
         end
         `INSTR_OPCAT_ST : begin
            imm_valid_r <= 1'b1;
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I12S4;
         end
         `INSTR_OPCAT_B : begin
            imm_valid_r <= 1'b1;
            imm_raw_r <= {4'b0, instr_i[15:0]};
            imm_rule_r <= `IMM_RULE_I16S2;
         end
         `INSTR_OPCAT_J : begin
            imm_valid_r <= opext[0];
            case (opcode[1:0])
               2'b00, 2'b10 : begin // J, JL
                  imm_raw_r <= {instr_i[21:18], instr_i[15:0]};
                  imm_rule_r <= `IMM_RULE_I16S4S2;
               end
               2'b11 : begin // JLR
                  imm_raw_r <= {4'b0, instr_i[15:0]};
                  imm_rule_r <= `IMM_RULE_I16S2;
               end
               default: begin
                  imm_raw_r <= 20'b0;         
                  imm_rule_r <= `IMM_RULE_NONE;
               end
            endcase
         end
         default : begin
            imm_valid_r <= 1'b0;
            imm_raw_r <= 20'b0;         
            imm_rule_r <= `IMM_RULE_NONE;
         end         
      endcase
   end

   // this logic has problem 
   // because for two consequtive add/sub it generates only one pulse
//   reg   aluflags_ahead_r, aluflags_ahead_r1;
//   always @(posedge clk or negedge rst_n) begin
//      if (!rst_n) begin
//         aluflags_ahead_r <= 1'b0;
//         aluflags_ahead_r1 <= 1'b0;
//      end
//      else begin
//         case (opcat)
//            `INSTR_OPCAT_ADDSUB : begin
//               aluflags_ahead_r <= 1'b1;
//            end
//            default : begin
//               aluflags_ahead_r <= 1'b0;
//            end         
//         endcase
//         aluflags_ahead_r1 <= aluflags_ahead_r;
//      end
//   end
//   assign aluflags_ahead_o = aluflags_ahead_r & (~aluflags_ahead_r1);
   
   // actually the only case to avoid is continuously generating aluflags_ahead when an add/sub is stalled
      reg   aluflags_ahead_r;
      always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         aluflags_ahead_r <= 1'b0;
      end
      else if (stall_i) begin
         aluflags_ahead_r <= 1'b0;
      end
      else begin
         case (opcat)
            `INSTR_OPCAT_ADDSUB : begin
               aluflags_ahead_r <= 1'b1;
            end
            default : begin
               aluflags_ahead_r <= 1'b0;
            end         
         endcase
      end
   end
   assign aluflags_ahead_o = aluflags_ahead_r;
   
   // in case of jump instruction based on register instead of pc, 
   // if ra doesn't conflict with previous instructions,
   // it will be read during the stall (in this case the stall is just a B&J stall)
   // (actually, the jump instruction gets to read operands just 1 cycle after decoding,
   // and contines to execute.)
   // in such case the ra should not cause a new data conflict.
   // note: ra need output for the 1st cycle of decode stage.
   wire   ra_yet2read_r;
   reg   ra_ddetect_gate_r;
   reg   j_valid_r2;
   always @(posedge clk) begin
      if (!rst_n) begin
         ra_ddetect_gate_r <= 1'b1;
         j_valid_r2 <= j_valid_r;
      end
      else begin
         if (j_valid_r & (~gpreg_d_conflict)) 
            ra_ddetect_gate_r <= 1'b0;
         else
            ra_ddetect_gate_r <= 1'b1;
      end
   end
   // assign ra_yet2read_r = ren_a_r & ra_ddetect_gate_r;
   // simply use j_valid_r2 to gate, because 
   //    j_valid_r took already gpr data conflict already,
   //    and we need one cycle for d_conflict detection
   assign ra_yet2read_r = ren_a_r & (~j_valid_r);
   
   // similarly, the rd in jump & link instructions 
   // shall not continuously get recorded during the B&J stall 
   // to block next instructions,
   // because the execution pipeline ahead is working during the B&J stall.
   // but let's don't care, 
   // because it's a bad idea for next instructions to use that rd register
   
   wire  [3:0] ra_idx_instant;
   assign      ra_idx_instant =  instr_i[`INSTR_FIELD_RA];
   wire        early_ra_conflict;
   ddep_detect u_ddep_detect (
      .clk                 (clk        )     ,
      .rst_n               (rst_n      )     ,   
      .reg_w_idx_i         (reg_d_idx_o)     , 
      .wen_i               (wen_d_o    )     ,
      .reg_a_idx_i         (reg_a_idx_r)     , 
      .ren_a_i             (ra_yet2read_r)   ,
      .reg_b_idx_i         (reg_b_idx_r)     ,
      .ren_b_i             (ren_b_r    )     ,     
      .reg_m_idx_i         (reg_m_idx_r)     ,
      .ren_m_i             (ren_m_r    )     ,       
      .conflict_o          (gpreg_d_conflict),
      .fast_read_reg_idx_i (ra_idx_instant)  ,
      .fast_conflict_o     (early_ra_conflict)    
   );
   
   wire  csr_flag_zero, csr_flag_neg;
   assign csr_flag_zero = csreg_i[1];
   assign csr_flag_neg  = csreg_i[2];
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         b_valid_r <= 1'b0;
      end
      else if (aluflags_pending_i | jump_exe_i)
         b_valid_r <=  1'b0;
      else case (opcode)
         `OPCODE_BEQ : begin              
            b_valid_r <= csr_flag_zero;   
         end
         `OPCODE_BNE : begin              
            b_valid_r <= ~csr_flag_zero;  
         end
         `OPCODE_BGE : begin              
            b_valid_r <= ~csr_flag_neg;   
         end
         `OPCODE_BLT : begin              
            b_valid_r <= csr_flag_neg;    
         end
         default : b_valid_r <= 1'b0;
      endcase
   end
   reg   need_early_ra_conflict_r;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         j_valid_r <= 1'b0;
         need_ddep2jmp_transit_r <= 1'b0;
         need_early_ra_conflict_r <= 1'b1;
      end
      else if (jump_exe_i) begin
         j_valid_r <=  1'b0;
         need_ddep2jmp_transit_r <= 1'b0;
         need_early_ra_conflict_r <= 1'b1;
      end
      else case (opcode)
         `OPCODE_J, `OPCODE_JL : begin
            j_valid_r <= 1'b1;
            need_ddep2jmp_transit_r <= 1'b0;
            need_early_ra_conflict_r <= 1'b1;
         end
         `OPCODE_JR, `OPCODE_JLR : begin
            if (early_ra_conflict & need_early_ra_conflict_r) begin
               j_valid_r <= 1'b0;
               need_ddep2jmp_transit_r <= 1'b1;
            end
            else begin
               j_valid_r <= 1'b1;
               need_ddep2jmp_transit_r <= 1'b0;
               need_early_ra_conflict_r <= 1'b0;
            end
         end
         default : begin
            j_valid_r <= 1'b0;
            need_ddep2jmp_transit_r <= 1'b0;
            need_early_ra_conflict_r <= 1'b1;
         end
      endcase
   end
   reg   relative_jmp_instr_type_r;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         bwaiting_csrflags_r <= 1'b0;
         relative_jmp_instr_type_r <= 1'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_J : begin
            bwaiting_csrflags_r <= 1'b0;
            if (opcode[0]) // JR & JLR
               relative_jmp_instr_type_r <= 1'b0;
            else // J & JL
               relative_jmp_instr_type_r <= 1'b1;
         end
         `INSTR_OPCAT_B : begin
            bwaiting_csrflags_r <= aluflags_pending_i;
            relative_jmp_instr_type_r <= 1'b1;
         end
         default : begin
            bwaiting_csrflags_r <= 1'b0;
            relative_jmp_instr_type_r <= 1'b0;
         end
      endcase
   end  
   
   reg will_jump_r1;
   always @(posedge clk)
      will_jump_r1 <= will_jump_o;
   assign jump_req_o = will_jump_o & (~will_jump_r1);
   assign pc_based_jmp_o = will_jump_o & relative_jmp_instr_type_r;
   
   always @(*) begin
      if (stall_i) begin // stalled
         ren_a_o     =  1'b0  ;
         reg_a_idx_o =  4'b0  ;
         ren_b_o     =  1'b0  ;
         reg_b_idx_o =  4'b0  ;
         imm_valid_o =  1'b0  ;
         imm_raw_o   =  20'b0 ;
         imm_rule_o  =  `IMM_RULE_NONE;
      
         opcode_o    =  `OPCODE_NOP;
         signed_o    =  1'b0  ;
         
         ren_m_o     =  1'b0  ;
         reg_m_idx_o =  4'b0  ;
         
         wen_d_o     =  1'b0  ;
         reg_d_idx_o =  4'b0  ;
         wrd_scope_o =  2'b0  ;
      end
      else begin
         ren_a_o     =  ren_a_r     ;
         reg_a_idx_o =  reg_a_idx_r ;
         ren_b_o     =  ren_b_r     ;
         reg_b_idx_o =  reg_b_idx_r ;
         imm_valid_o =  imm_valid_r ;
         imm_raw_o   =  imm_raw_r   ;
         imm_rule_o  =  imm_rule_r  ; 
         
         opcode_o    =  opcode_r    ;
         signed_o    =  signed_r    ;
         
         ren_m_o     =  ren_m_r     ;
         reg_m_idx_o =  reg_m_idx_r ;         
         
         wen_d_o     =  wen_d_r     ;
         reg_d_idx_o =  reg_d_idx_r ;  
         wrd_scope_o =  wrd_scope_r ;      
      end
   end
   
endmodule