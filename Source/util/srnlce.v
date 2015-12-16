`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:44:06 04/02/2015 
// Design Name: 
// Module Name:    srnlce 
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
module srnlce #(
	parameter Width = 16,
	parameter Left = 0,
	parameter TMR = 0
)(
	input C,
	input CE,
	input CLR,
	input L,
	input SI,
	input [Width-1:0] D,
	output reg [Width-1:0] Q
);

always @(posedge C or posedge CLR) begin
	if(CLR)
		Q <= 0;
	else
		if(L)
			Q <= D;
		else if(CE)
			if(Left)
				Q <= {Q[Width-2:0],SI}; // Shift left
			else
				Q <= {SI,Q[Width-1:1]}; // Shift right
end

endmodule
