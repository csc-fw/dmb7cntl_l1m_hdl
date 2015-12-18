`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:56:27 01/22/2015 
// Design Name: 
// Module Name:    srl_nx1 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module srl_16dx1(
	input CLK,
	input CE,
	input [3:0] A, //Address is 1 less than depth, ie. for 5 clocks A is 4
	input I,
	output O,
	output Q15
);

   
   SRLC16E #(
      .INIT(16'h0000) // Initial Value of Shift Register
   ) SRLC16E_inst (
      .Q(O),       // SRL data output
      .Q15(Q15),   // Carry output (connect to next SRL)
      .A0(A[0]),     // Select[0] input
      .A1(A[1]),     // Select[1] input
      .A2(A[2]),     // Select[2] input
      .A3(A[3]),     // Select[3] input
      .CE(CE),     // Clock enable input
      .CLK(CLK),   // Clock input
      .D(I)        // SRL data input
   );

//(* syn_srlstyle = "select_srl" *)
//(* INIT = "16'h0000" *)
//   reg [15:0] sr;
//	initial begin
//		sr = 16'h0000;
//	end
//   always @(posedge CLK)begin
//      if (CE)
//         sr <= {sr[14:0], I};
//	end
//   assign O = sr[A];
//	assign Q15 = sr[15];

endmodule
