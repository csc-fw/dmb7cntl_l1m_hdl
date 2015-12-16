`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:41:37 01/28/2015 
// Design Name: 
// Module Name:    srl_nxm 
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
module srl_16dxm #(
	parameter Width = 16
)(
	input CLK,
	input CE,
	input [3:0] A, //Address is 1 less than depth, ie. for 5 clocks A is 4
	input [Width-1:0] I,
	output [Width-1:0] O,
	output [Width-1:0] Q15
);

(* syn_srlstyle = "select_srl" *)
   reg [15:0] sr [Width-1:0];

genvar i;
generate
	for (i=0; i < Width; i=i+1) 
	begin: bus_srl_dyn
		always @(posedge CLK)
			if (CE)
				sr[i] <= {sr[i][14:0], I[i]};

		assign O[i] = sr[i][A];
		assign Q15[i] = sr[i][15];
	end
endgenerate

//genvar i;
//generate
//	for (i=0; i < Width; i=i+1) 
//	begin: srl_bit
//		SRLC16E #(
//			.INIT(16'h0000) // Initial Value of Shift Register
//		) SRLC16E_inst (
//			.Q(O[i]),       // SRL data output
//			.Q15(Q15[i]),   // Carry output (connect to next SRL)
//			.A0(A[0]),     // Select[0] input
//			.A1(A[1]),     // Select[1] input
//			.A2(A[2]),     // Select[2] input
//			.A3(A[3]),     // Select[3] input
//			.CE(CE),     // Clock enable input
//			.CLK(CLK),   // Clock input
//			.D(I[i])        // SRL data input
//		);
//	end
//endgenerate

endmodule
