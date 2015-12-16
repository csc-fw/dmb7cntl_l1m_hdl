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
module srl_nxm #(
	parameter Depth = 16,
	parameter Width = 16
)(

    input CLK,
    input CE,
    input [Width-1:0] I,
    output [Width-1:0] O
    );

(* syn_srlstyle = "select_srl" *)
   reg [Depth-1:0] sr [Width-1:0];

genvar i;
generate
	for (i=0; i < Width; i=i+1) 
	begin: bus_srl
		always @(posedge CLK)
			if (CE)
				sr[i] <= {sr[i][Depth-2:0], I[i]};

		assign O[i] = sr[i][Depth-1];
	end
endgenerate

endmodule
