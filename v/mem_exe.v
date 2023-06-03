/**
 * memory access instruction execution
 */

`include "instructions.v"

module mem_exe (
   input                clk         ,
   input                rst_n       ,
   
   // from dec 
   input    [5:0]       opcode_i    ,
   input                signed_i    ,
   // from op_gen 
   input    [31:0]      wdata_i     ,
   // from alu 
   input    [31:0]      addr_i      ,   
   
   // external
   output reg [31:0]    mem_addr_o  ,
   output reg [31:0]    mem_wdata_o ,
   output reg           mem_en_o    ,
   output reg           mem_wr_o    ,
   output reg [1:0]     mem_wscope_o, // mem write scope: word(2'b11), half word(2'b01), byte(2'b00)
   
   // to mem rx
   output reg           ren_o       , // reading?
   output reg [1:0]     scope_o     , // word(2'b11), half word(2'b01), or byte(2'b00)?
   output reg [1:0]     signed_o    ,
   output reg [1:0]     addr_lsb2_o   // least 2 bits of the address
   );
   
   // should i use comb-logic here?
   // the mem-cache itself will cost at least 1 cycle.
   
   // -> read : combinational logic to send address / read signal to mem-cache
   //             check received data AND MAYBE EXCEPTIONAL SIGNALS on rising edge
   // -> write : both combinatorial or sequential logic are ok, don't need care once written (handled to external circuit)
     
   
   wire  [3:0] opcat;
   assign opcat = opcode_i[5:2];
   reg   init;
   
   always @(*) begin
      if (init) begin
         mem_en_o = 1'b0;
         mem_wr_o = 1'b0;
         mem_wscope_o = 2'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_LD : begin
            mem_en_o = 1'b1;
            mem_wr_o = 1'b0;
            mem_wscope_o = 2'b00;
         end
         `INSTR_OPCAT_ST : begin
            mem_en_o = 1'b1;
            mem_wr_o = 1'b1;
            mem_wscope_o = opcode_i[1:0];
         end
         default: begin
            mem_en_o = 1'b0;
            mem_wr_o = 1'b0;
         end
      endcase
   end

//   // don't need such logic, the mem-cache is to take care
//   always @(*) begin
//      case (opcat)
//         `INSTR_OPCAT_LD : begin
//            mem_addr_o = {addr_i[31:2],2'b0};
//            mem_wdata_o = 32'b0;
//         end
//         `INSTR_OPCAT_ST : begin
//            case (opcode_i[1:0])
//               2'b00 : begin
//                  mem_addr_o = addr_i;
//                  mem_wdata_o = {24'b0, wdata_i[7:0]};
//               end
//               2'b01 : begin
//                  mem_addr_o = {addr_i[31:1], 1'b0};
//                  mem_wdata_o = {16'b0, wdata_i[15:0]};
//               end
//               2'b11 : begin
//                  mem_addr_o = {addr_i[31:2], 2'b0};
//                  mem_wdata_o = wdata_i;
//               end
//               default : begin
//                  mem_addr_o = addr_i;
//                  mem_wdata_o = wdata_i;
//               end
//            endcase            
//         end
//         default : begin
//            mem_addr_o = addr_i;
//            mem_wdata_o = 32'b0;
//         end
//      endcase
//   end

   always @(*) begin
      if (init) begin
         mem_addr_o = 32'b0;
         mem_wdata_o = 32'b0;
      end
      else case (opcat)
         `INSTR_OPCAT_LD : begin
            mem_addr_o = addr_i;
            mem_wdata_o = 32'b0;
         end         
         `INSTR_OPCAT_ST : begin
            mem_addr_o = addr_i;
            mem_wdata_o = wdata_i;
         end
         default: begin
            mem_addr_o = 32'b0;
            mem_wdata_o = 32'b0;
         end
      endcase
   end
   
   // wait for mem - cache to give result
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         ren_o <= 1'b0;     
         scope_o <= 2'b11;   
         signed_o <= 1'b0;
         addr_lsb2_o <= 2'b00;
         init <= 1'b1;
      end
      else begin
         case (opcat)
            `INSTR_OPCAT_LD : begin
               ren_o <= 1'b1;
               scope_o <= opcode_i[1:0];
               signed_o <= signed_i;
               addr_lsb2_o <= addr_i[1:0];
            end
            default: begin
               ren_o <= 1'b0;     
               scope_o <= 2'b11;   
               signed_o <= 1'b0;
               addr_lsb2_o <= 2'b00;
            end
         endcase
         init <= 1'b0;
      end
   end

endmodule
