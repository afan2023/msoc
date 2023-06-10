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


module carry_lookahead_adder4(
   input    [3:0]    a     ,
   input    [3:0]    b     ,
   input             c_i   , // carry input (i.e. from lower adder)
	
   output   [3:0]    s     ,
   output            c_o     // carry output
);

	wire [3:0] p;
	wire [3:0] g;
	wire [3:0] c;
	
	assign g = a & b;
	assign p = a | b;
	
	assign c[0] = c_i;
	assign c[1] = g[0] | ( p[0] & c[0] );
	// c[2] = g[1] | ( p[1] & c[1] ) = g[1] | ( p[1] & ( g[0] | ( p[0] & c[0] ) ) );
	assign c[2] = g[1] | ( p[1] & g[0] ) | ( p[1] & p[0] & c[0] );
	// c[3] = g[2] | ( p[2] & c[2] ) = g[2] | ( g[1] | ( p[1] & ( g[0] | ( p[0] & c[0] ) ) ) );
	assign c[3] = g[2] | ( p[2] & g[1] ) | ( p[2] & p[1] & g[0] ) | ( p[2] & p[1] & p[0] & c[0] );
	// c[4] = g[3] | ( p[3] & c[3] ) = g[3] | ( g[2] | ( g[1] | ( p[1] & ( g[0] | ( p[0] & c[0] ) ) ) ) );
	assign c_o = g[3] | ( p[3] & g[2] ) | ( p[3] & p[2] & g[1] ) | ( p[3] & p[2] & p[1] & g[0] ) | ( p[3] & p[2] & p[1] & p[0] & c[0] );

	assign s = a^b^c;
	
endmodule

module adder32(
   input    [31:0]   a     ,
   input    [31:0]   b     ,
   input             c_i   ,
	
   output   [31:0]   s     ,
   output            c_o
);

	wire [6:0] c;
	
	carry_lookahead_adder4 u0_cal_adder4(
		.a(a[3:0]),
		.b(b[3:0]),
		.c_i(c_i),
		.s(s[3:0]),
		.c_o(c[0])
	);
	
	carry_lookahead_adder4 u1_cal_adder4(
		.a(a[7:4]),
		.b(b[7:4]),
		.c_i(c[0]),
		.s(s[7:4]),
		.c_o(c[1])
	);
	
	carry_lookahead_adder4 u2_cal_adder4(
		.a(a[11:8]),
		.b(b[11:8]),
		.c_i(c[1]),
		.s(s[11:8]),
		.c_o(c[2])
	);
	
	carry_lookahead_adder4 u3_cal_adder4(
		.a(a[15:12]),
		.b(b[15:12]),
		.c_i(c[2]),
		.s(s[15:12]),
		.c_o(c[3])
	);

	carry_lookahead_adder4 u4_cal_adder4(
		.a(a[19:16]),
		.b(b[19:16]),
		.c_i(c[3]),
		.s(s[19:16]),
		.c_o(c[4])
	);
	
	carry_lookahead_adder4 u5_cal_adder4(
		.a(a[23:20]),
		.b(b[23:20]),
		.c_i(c[4]),
		.s(s[23:20]),
		.c_o(c[5])
	);
	
	carry_lookahead_adder4 u6_cal_adder4(
		.a(a[27:24]),
		.b(b[27:24]),
		.c_i(c[5]),
		.s(s[27:24]),
		.c_o(c[6])
	);
	
	carry_lookahead_adder4 u7_cal_adder4(
		.a(a[31:28]),
		.b(b[31:28]),
		.c_i(c[6]),
		.s(s[31:28]),
		.c_o(c_o)
	);	

endmodule