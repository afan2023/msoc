
module data_mem(
	input					clk,		// clock
	input					en,		// enable
	input		[31:0]	addr,		// address
	input					wr,		// 1: write, 0: read enable
	input		[31:0]	wdata,	// data to write
	output	[31:0]	rdata		// data been read out
	
);

reg	[7:0]		data_mem [8095:0]; // 8k bytes
reg	[31:0]	rdata_r;

always @(posedge clk)
if (!en) begin
end
else if (wr) begin
	// big endian
	// force aligned
	data_mem[{addr[31:2],2'h0}] <= wdata[31:24];
	data_mem[{addr[31:2],2'h1}] <= wdata[23:16];
	data_mem[{addr[31:2],2'h2}] <= wdata[15:8];
	data_mem[{addr[31:2],2'h3}] <= wdata[7:0];
end

always @(*) //这个data_mem会被综合成使用LE，要想综合成BRAM，这里也需要改为时序逻辑如always@(posedge clk...)
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