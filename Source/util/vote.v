`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:22:00 01/22/2015 
// Design Name: 
// Module Name:    vote 
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
module vote #(
	parameter Width = 1
)(
    input [Width-1:0] A,
    input [Width-1:0] B,
    input [Width-1:0] C,
    output [Width-1:0] V
);
genvar i;
generate
	for (i=0; i < Width; i=i+1) 
		begin: bt
			BUFT vt_a (.I(B[i]),.T(A[i]),.O(V[i]));
			BUFT vt_b (.I(C[i]),.T(B[i]),.O(V[i]));
			BUFT vt_c (.I(A[i]),.T(C[i]),.O(V[i]));
			PULLUP vt_p (.O(V[i]));
		end
endgenerate

endmodule
