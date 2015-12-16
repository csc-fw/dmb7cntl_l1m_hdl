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
module srl_nx1_noparm(
	input CLK,
	input CE,
	input [3:0] A, //Address is 1 less than depth, ie. for 5 clocks A is 4
	input I,
	output O
);

(* syn_srlstyle = "select_srl" *)
   reg [15:0] sr;

   always @(posedge CLK)
      if (CE)begin
         sr <= {sr[14:0], I};
      end
   assign O = sr[A];

endmodule
