`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:46:19 11/13/2015 
// Design Name: 
// Module Name:    sync_in 
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
module sync_in(
	input C,
	input RST,
	input D,
	input KILL,
	output reg Q
);

reg d1;
reg en;

(* IOB = "TRUE" *)
always @(posedge C)
begin
	d1 <= D;
end

always @(posedge C or posedge RST)
begin
	if(RST)
		en <= 1'b0;
	else
		if(D & !d1) // leading edge
			en <= 1'b1;  // en is in time with d1
end

always @(posedge C or posedge RST)
begin
	if(RST)
		Q <= 1'b0;
	else
		if(en && !KILL) // self enabling (disabled after programming to mask DAV inputs from other FPGAs during hard resets)
			Q <= d1;
end

endmodule
