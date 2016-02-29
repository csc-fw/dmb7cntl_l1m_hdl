`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:04:35 11/23/2015 
// Design Name: 
// Module Name:    lfsr_2tap 
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
module lfsr_2tap #(
	parameter N = 3,
	parameter FB_tap = 2,
	parameter TAP_A = 2,
	parameter TAP_B = 2,
	parameter TAP_C = 2,
	parameter TAP_D = 2,
	parameter TAP_E = 2,
	parameter TAP_F = 2,
	parameter TAP_G = 2,
	parameter TAP_H = 2,
	parameter TAP_I = 2
)(
	input CLK,
	output [8:0] OUT
);

reg [N:1] lfsr;
wire feedback;

initial begin
	lfsr = 0;
end

assign feedback = lfsr[N] ~^ lfsr[FB_tap];
assign OUT = {lfsr[TAP_I],lfsr[TAP_H],lfsr[TAP_G],lfsr[TAP_F],lfsr[TAP_E],lfsr[TAP_D],lfsr[TAP_C],lfsr[TAP_B],lfsr[TAP_A]};

always @(posedge CLK)
begin
	lfsr <= {lfsr[N-1:1],feedback};
end

endmodule
