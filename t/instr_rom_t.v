module instr_rom_t(
	input en,
	input [31:0] addr,
	
	output [31:0] instruction
);
	
// 1k bytes mem
// reg [7:0] instr_mem [1023:0];
reg [31:0] instr_mem [255:0];

// simulation, load instruction mem content from file
initial $readmemh ("instr_rom_t.txt", instr_mem);

// output instruction register
reg [31:0] instr_r;

always@(*) //会被综合成使用LE，要想综合成BRAM，需要改为时序逻辑如always@(posedge clk...)
if (en)
	// big endian
	// force alignment by taking only the higher 30 bits of input address
   // instr_r <= {instr_mem[{addr[31:2],2'h0}],instr_mem[{addr[31:2],2'h1}],instr_mem[{addr[31:2],2'h2}],instr_mem[{addr[31:2],2'h3}]};
   
   // BY WORD
	instr_r <= instr_mem[{addr[31:2]}];
else
	instr_r <= 32'h0; // NOP
	
assign instruction = instr_r;
	
endmodule
