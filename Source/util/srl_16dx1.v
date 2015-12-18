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

(* syn_srlstyle = "select_srl" *)
(* INIT = "16'h0000" *)
   reg [15:0] sr;
	initial begin
		sr = 16'h0000;
	end
   always @(posedge CLK)begin
      if (CE)
         sr <= {sr[14:0], I};
	end
   assign O = sr[A];
	assign Q15 = sr[15];

endmodule
