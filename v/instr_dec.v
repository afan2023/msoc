/**
 * instruction decoder
 */

`include "instructions.v"
 
module instr_dec (
   input                clk         ,
   input                rst_n       ,
   
   // input instruction
   input    [31:0]      instr_i     , 
   
   // output for oprands generation
   output reg           ren_a_o     ,
   output reg [3:0]     reg_a_idx_o ,
   output reg           ren_b_o     ,
   output reg [3:0]     reg_b_idx_o ,
   output reg           imm_valid_o ,
   output reg [19:0]    imm_raw_o   ,
   output reg [2:0]     imm_rule_o  ,
   // output for reg value to write to memory
   output reg           ren_m_o     ,
   output reg [3:0]     reg_m_idx_o ,
   
   // output for execution code
   output reg [5:0]     opcode_o    ,
   output reg           signed_o    ,
   
   // output for writing back register
   output reg           wen_d_o     ,
   output reg [3:0]     reg_d_idx_o , 
   output reg [1:0]     wrd_scope_o , // scope of write (bit 1: high half, bit 0: low half)
   
   // interface with pipeline control
   input                stall_i     , // stall may be originated from dec itself:-) or mem
   output               d_conflict_o
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
   
   wire  d_conflict;
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         opcode_r <= 6'b0;
      end
      else begin
         opcode_r <= opcode;    
      end
   end   
   
   wire  [3:0] opcat;
   assign opcat = opcode[5:2];   
   
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         signed_r <= 1'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_ADDSUB : begin
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
         default : begin
            ren_a_r <= 1'b0;
            ren_b_r <= 1'b0;
            wen_d_r <= 1'b0;
            wrd_scope_r <= 2'b0;
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
         default : begin
            imm_valid_r <= 1'b0;
            imm_raw_r <= 20'b0;         
            imm_rule_r <= `IMM_RULE_NONE;
         end         
      endcase
   end
   
   ddep_detect u_ddep_detect (
      .clk               (clk        )    ,
      .rst_n             (rst_n      )    ,   
      .reg_w_idx_i       (reg_d_idx_r)    , 
      .wen_i             (wen_d_r    )    ,
      .reg_a_idx_i       (reg_a_idx_r)    , 
      .ren_a_i           (ren_a_r    )    ,
      .reg_b_idx_i       (reg_b_idx_r)    ,
      .ren_b_i           (ren_b_r    )    ,     
      .reg_m_idx_i       (reg_m_idx_r)    ,
      .ren_m_i           (ren_m_r    )    ,       
      .conflict_o        (d_conflict)
   );
   
   assign d_conflict_o = d_conflict;
   
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