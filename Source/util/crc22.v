`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:52:13 11/25/2015 
// Design Name: 
// Module Name:    crc22 
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
module crc22(
	input CLK,
	input CE,
	input CLR,
	input [15:0] DIN,
	output reg [23:0] REGCRC
);

wire [21:0] fb;
wire [23:0] crc;

assign fb = REGCRC[21:0];

assign crc[ 0] = fb[16];
assign crc[ 1] = fb[17];
assign crc[ 2] = fb[18];
assign crc[ 3] = fb[19];
assign crc[ 4] = fb[20];
assign crc[ 5] = DIN[ 0] ^ fb[ 0] ^ fb[21];
assign crc[ 6] = DIN[ 0] ^ DIN[ 1] ^ fb[ 0] ^ fb[ 1];
assign crc[ 7] = DIN[ 1] ^ DIN[ 2] ^ fb[ 1] ^ fb[ 2];
assign crc[ 8] = DIN[ 2] ^ DIN[ 3] ^ fb[ 2] ^ fb[ 3];
assign crc[ 9] = DIN[ 3] ^ DIN[ 4] ^ fb[ 3] ^ fb[ 4];
assign crc[10] = DIN[ 4] ^ DIN[ 5] ^ fb[ 4] ^ fb[ 5];
assign crc[11] = DIN[ 5] ^ DIN[ 6] ^ fb[ 5] ^ fb[ 6];
assign crc[12] = DIN[ 6] ^ DIN[ 7] ^ fb[ 6] ^ fb[ 7];
assign crc[13] = DIN[ 7] ^ DIN[ 8] ^ fb[ 7] ^ fb[ 8];
assign crc[14] = DIN[ 8] ^ DIN[ 9] ^ fb[ 8] ^ fb[ 9];
assign crc[15] = DIN[ 9] ^ DIN[10] ^ fb[ 9] ^ fb[10];
assign crc[16] = DIN[10] ^ DIN[11] ^ fb[10] ^ fb[11];
assign crc[17] = DIN[11] ^ DIN[12] ^ fb[11] ^ fb[12];
assign crc[18] = DIN[12] ^ DIN[13] ^ fb[12] ^ fb[13];
assign crc[19] = DIN[13] ^ DIN[14] ^ fb[13] ^ fb[14];
assign crc[20] = DIN[14] ^ DIN[15] ^ fb[14] ^ fb[15];
assign crc[21] = DIN[15] ^           fb[15];
assign crc[22] = ^crc[10:0];
assign crc[23] = ^crc[21:11];

always @(posedge CLK or posedge CLR)
begin
	if(CLR)
		REGCRC <= 24'h000000;
	else
		if(CE)
			REGCRC <= crc;
end

endmodule
