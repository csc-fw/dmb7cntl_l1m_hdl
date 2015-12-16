`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:44:06 04/02/2015 
// Design Name: 
// Module Name:    sr16lce 
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
module sr16lce(
	input C,
	input CE,
	input CLR,
	input L,
	input SRI,
	input [15:0] D,
	output [15:0] Q
);

always @(posedge C or posedge CLR) begin
	if(CLR)
		Q <= 16'h0000;
	else
		if(L)
			Q <= D;
		else if(CE)
			Q <= {SRI,Q[15:1]};
end

endmodule
