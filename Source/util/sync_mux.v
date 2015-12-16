`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:29:56 11/13/2015 
// Design Name: 
// Module Name:    sync_mux 
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
module sync_mux(
	input C,
	input RST,
	input D,
	input [1:0] S,
	input KILL,
	output Q,
	output ENOUT // in time with d2
);

reg df;
reg dr;
wire d1;
reg d2,d3;
reg en;

assign d1 = S[0] ? dr : df;
assign Q  = S[1] ? d3 : d2;
assign ENOUT = en & !KILL; // self enabling (disabled after programming to mask DAV inputs from other FPGAs during hard resets)

(* IOB = "TRUE" *)
always @(negedge C)
begin
	df <= D;
end

always @(posedge C)
begin
	dr <= D;
	d2 <= d1;
	d3 <= d2;
end

always @(posedge C or posedge RST)
begin
	if(RST)
		en <= 1'b0;
	else
		if(d1 & !d2) //leading edge
			en <= 1'b1;
end

endmodule
