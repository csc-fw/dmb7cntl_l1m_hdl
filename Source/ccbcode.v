`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:55:47 11/10/2015 
// Design Name: 
// Module Name:    ccbcode 
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
module ccbcode #(
	parameter TMR = 0
)
(
	input CLKCMS,
	input CLKENAIN,
	input L1ARSTIN,
	input BXRSTIN,
	input BX0IN,
	input CMDSTRB,
	input DATASTRB,
	input [5:0] CCBCMD,
	input [7:0] CCBDATA,
	output reg CLKENA,
	output reg BC0,
	output reg BX0,
	output reg BXRST,
	output reg L1ARST,
	output reg L1ASRST,
	output reg [2:0] TTCCAL
);

reg start_trg;
reg stop_trg;
wire ncmdstrb;
wire [5:0] ncmd;
wire ndatastrb;
wire [7:0] ndata;
wire rstdata;
wire [3:0] l1asrst_cnt;
wire clr_l1asrst;

initial
begin
	L1ASRST = 1'b0;
end

assign ncmd = ~CCBCMD;
assign ncmdstrb = ~CMDSTRB;
assign ndata = ~CCBDATA;
assign ndatastrb = ~DATASTRB;
assign rstdata = ndatastrb && ((ndata == 8'h54) || (ndata == 8'h55));

(* IOB = "TRUE" *)
always @(posedge CLKCMS)
begin
	BX0       <= ~BX0IN;
	CLKENA    <= ~CLKENAIN;
	BXRST     <= ~BXRSTIN;
	L1ARST    <= ~L1ARSTIN;
end

always @(posedge CLKCMS)
begin
	BC0       <= ncmdstrb && (ncmd == 6'h01);
	start_trg <= ncmdstrb && (ncmd == 6'h06);
	stop_trg  <= ncmdstrb && (ncmd == 6'h07);
	TTCCAL[0] <= ncmdstrb && (ncmd == 6'h14);
	TTCCAL[1] <= ncmdstrb && (ncmd == 6'h15);
	TTCCAL[2] <= ncmdstrb && (ncmd == 6'h16);
end

always @(posedge CLKCMS or posedge clr_l1asrst)
begin
	if(clr_l1asrst)
		L1ASRST <= 1'b0;
	else
		if(ncmdstrb && (ncmd == 6'h03))
			L1ASRST <= 1'b1;
end

assign clr_l1asrst = (l1asrst_cnt == 4'hF);

cbnce #(
	.Width(4),
	.TMR(TMR)
)
fpgarst_cntr_i (
	.CLK(CLKCMS),
	.RST(~L1ASRST),
	.CE(L1ASRST),
	.Q(l1asrst_cnt)
);

endmodule
