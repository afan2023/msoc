/**
 *
 * general purpose registers
 */
 
module gp_regs (
   input                clk         , // clock
   input                rst_n       , // reset

   input    [3:0]       reg_w_idx_i , // index of reg to write
   input    [31:0]      wdata_i     , // data to write into reg
   input                wen_i       , // write enable
   input    [1:0]       wr_scope_i  , // scope of write (bit 1: high half, bit 0: low half)
   
   input    [3:0]       ra_index_i  , // reg a index to read
   input                ren_a_i     , // read enable reg n
   input    [3:0]       rb_index_i  , // reg b index
   input                ren_b_i     , // read enable - reg b

   output reg [31:0]    rvalue_a_o  , // data value of reg a read
   output reg [31:0]    rvalue_b_o    // data value of reg b read
   );
   
   reg [31:0]  regs  [15:0];
   
   localparam GPR_DEFAULT_VAL = 32'b0;
   
   integer i;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         // integer i; // modelsim: Declarations not allowed in unnamed block.
         for (i = 0; i < 16; i = i+1) begin
            regs[i] <= GPR_DEFAULT_VAL;
         end
      end
      else if (wen_i) begin
         case (wr_scope_i)
            2'b01: regs[reg_w_idx_i][15:0] <= wdata_i[15:0];
            2'b10: regs[reg_w_idx_i][31:16] <= wdata_i[31:16];
            2'b11: regs[reg_w_idx_i] <= wdata_i;
            default: ; // such default case shall not happen
         endcase
      end
   end
   
   // combinational logic to make output value always aligned, & catch up with the operand generation need
   always @(*)
   if (!rst_n | !ren_a_i)
      rvalue_a_o = GPR_DEFAULT_VAL;
   else
      rvalue_a_o = regs[ra_index_i];
   
   always @(*)
   if (!rst_n | !ren_b_i)
      rvalue_b_o = GPR_DEFAULT_VAL;
   else
      rvalue_b_o = regs[rb_index_i];
   
   
endmodule