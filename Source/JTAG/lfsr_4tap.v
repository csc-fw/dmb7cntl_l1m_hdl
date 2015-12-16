`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:53:37 11/23/2015 
// Design Name: 
// Module Name:    lfsr_4tap 
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
module lfsr_4tap #(
	parameter N = 8,
	parameter FB_tap1 = 4,
	parameter FB_tap2 = 5,
	parameter FB_tap3 = 6
)(
	input CLK,
	output OUT
);

reg [N:1] lfsr;
wire feedback;

assign feedback = lfsr[N] ~^ lfsr[FB_tap1] ~^ lfsr[FB_tap2] ~^ lfsr[FB_tap3];
assign OUT = lfsr[N];

always @(posedge CLK)
begin
	lfsr <= {lfsr[N-1:1],feedback};
end

endmodule
