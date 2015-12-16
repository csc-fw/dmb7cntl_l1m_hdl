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
module srl_nx1
#(
	parameter Depth = 16
)(
	input CLK,
	input CE,
	input I,
	output O
);

(* syn_srlstyle = "select_srl" *)
	reg [Depth-1:0] sr;
	initial sr = 0;

   always @(posedge CLK)
      if (CE)begin
         sr <= {sr[Depth-2:0], I};
		end
   assign O = sr[Depth-1];

endmodule
