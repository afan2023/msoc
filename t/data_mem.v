
module data_mem(
	input					clk,		// clock
	input					en,		// enable
	input		[31:0]	addr,		// address
	input					wr,		// 1: write, 0: read enable
   input    [1:0]    wscope,  // 2'b11: word, 2'b01: half word, 2'b00: byte
	input		[31:0]	wdata,	// data to write
	output	[31:0]	rdata		// data been read out
	
);

reg	[7:0]		data_mem [8095:0]; // 8k bytes
reg	[31:0]	rdata_r;

always @(posedge clk)
if (!en) begin
end
else if (wr) begin
   case (wscope)
      2'b11 : begin
         // big endian
         // force aligned
         data_mem[{addr[31:2],2'h0}] <= wdata[31:24];
         data_mem[{addr[31:2],2'h1}] <= wdata[23:16];
         data_mem[{addr[31:2],2'h2}] <= wdata[15:8];
         data_mem[{addr[31:2],2'h3}] <= wdata[7:0];
      end
      2'b01 : begin
         data_mem[{addr[31:1],1'h0}] <= wdata[15:8];
         data_mem[{addr[31:1],1'h1}] <= wdata[7:0];
      end
      2'b00 : begin
         data_mem[addr] <= wdata[7:0];
      end
   endcase
end

always @(posedge clk) 
if (!en || wr) begin
	rdata_r <= 32'h0;
end else begin
	// big endian
	// force aligned
	rdata_r <= {data_mem[{addr[31:2],2'h0}],
					data_mem[{addr[31:2],2'h1}],
					data_mem[{addr[31:2],2'h2}],
					data_mem[{addr[31:2],2'h3}]};
end

assign rdata = rdata_r;

endmodule