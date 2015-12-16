`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:25:35 11/10/2015 
// Design Name: 
// Module Name:    frontmon 
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
module frontmon #(
	parameter TMR = 0
)
(
	input INJECT,
	input PULSE,
	input OEOVLP,
	input [7:1] RENFFMON_B,
	input [7:1] OEFFMON_B,
	input [7:1] FIFOEMPT_B,
	input [7:1] FIFOFULL_B,
	input [7:1] FIFOHALF_B,
	input [7:1] FIFOPAE_B,
	input [7:1] MONITOR,
	input [4:1] MODECODE,
	input [9:1] AUXOUT,
	input [15:0] TESTSTAT_MON,
	input [5:0] LCT,
	input [9:1] MONOUT,
	input [16:1] DIAGIN,
	input [8:1] MULTIN,
	output OUTPUTENL_B,
	output OUTPUTENH_B,
	output reg [16:1] MULTOUT,
	output [8:1] EXTIN
);

wire outputenl;

assign outputenl = ((MODECODE > 4'd0) && (MODECODE < 4'd8)) || (MODECODE == 4'd11) || (MODECODE == 4'd14);
assign OUTPUTENL_B = ~outputenl;
assign OUTPUTENH_B = ~((MODECODE == 4'd9) | outputenl);

assign EXTIN = MULTIN;

always @*
begin
	case(MODECODE)
		4'd1    : MULTOUT = {  1'b0,FIFOFULL_B,  1'b0,  FIFOEMPT_B};
		4'd2    : MULTOUT = {  1'b0,FIFOHALF_B,  1'b0,   FIFOPAE_B};
		4'd3    : MULTOUT = {OEOVLP, OEFFMON_B,OEOVLP,RENFFMON_B};
		4'd4    : MULTOUT = {  MONITOR, PULSE, INJECT, FIFOEMPT_B};
		4'd5    : MULTOUT = {  MONOUT,   FIFOPAE_B};
		4'd6    : MULTOUT = {  MONITOR, PULSE, INJECT, RENFFMON_B};
		4'd7    : MULTOUT = DIAGIN;
		4'd9    : MULTOUT = {DIAGIN[16:9],8'h00};
		4'd11   : MULTOUT = {AUXOUT,LCT[0],MONITOR[1],LCT[5:1]};
		4'd14   : MULTOUT = TESTSTAT_MON;
		default : MULTOUT = 16'h0000;
	endcase
end

endmodule
