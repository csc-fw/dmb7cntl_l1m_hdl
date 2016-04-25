`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:01:53 11/12/2015 
// Design Name: 
// Module Name:    lctdly 
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
module lctdly(
    input CLK,
    input PLCT,
    input CLCT,
    input L1A,
	 input USE_CLCT,
	 input [3:0] CLCT_ADJ,
    input [2:0] OPT_COP,
    input [5:0] DELAY,
    input [1:0] XL1ADLY,
    input [3:0] L1FD,
    output reg DOUT,
    output L1A_MATCH
    );

wire [3:0] fdly;
wire [3:0] xdly;
reg  dmid;
wire dmida;
wire dmidb;
reg  dmidc;
wire dmidd;
reg  dmidx;
wire tdly;
wire cdly;
wire fx2in;

wire p1;
reg  p0;
reg  m1;
reg  m2;
reg  m3;

wire pre_l1a_match;

assign pre_l1a_match = L1A & (p1 | p0 | m1 | m2 | m3);  // Asymmetric 5bx match (plus 1 minus 3)

assign fx2in = USE_CLCT ? cdly : fdly[0];

//
// CLCT Delay
//
srl_16dx1 clctdelay_1 (.CLK(CLK), .CE(1'b1),.A(CLCT_ADJ),.I(CLCT),.O(cdly),.Q15()); // 16 clocks

//
// Fixed Delays
//
srl_16dx1 fixdelay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(PLCT),   .O(fdly[0]),.Q15()); // 16 clocks
srl_16dx1 fixdelay_2 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(fx2in),  .O(fdly[1]),.Q15()); // 16 clocks
srl_16dx1 fixdelay_3 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(fdly[1]),.O(fdly[2]),.Q15()); // 16 clocks
srl_16dx1 fixdelay_4 (.CLK(CLK), .CE(1'b1),.A(4'hE),.I(fdly[2]),.O(fdly[3]),.Q15()); // 15 clocks

//
// Reverse Fine Delay
//
srl_16dx1 revfdelay_i (.CLK(CLK), .CE(1'b1),.A(~L1FD),.I(fdly[3]),.O(xdly[0]),.Q15()); // (15-L1FineDelay) + 1  clocks

//
// Extra L1A Delay 
//
srl_16dx1 xl1delay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(xdly[0]),.O(xdly[1]),.Q15()); // 16 clocks
srl_16dx1 xl1delay_2 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(xdly[1]),.O(xdly[2]),.Q15()); // 16 clocks
srl_16dx1 xl1delay_3 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(xdly[2]),.O(xdly[3]),.Q15()); // 16 clocks

always @(posedge CLK) // (0, 16, 32, 48) + 1 clock
begin
	case(XL1ADLY)
		2'd0 : dmid <= xdly[0]; 
		2'd1 : dmid <= xdly[1]; 
		2'd2 : dmid <= xdly[2]; 
		2'd3 : dmid <= xdly[3]; 
		default : dmid <= xdly[0];
	endcase
end

//
// Optical/Copper Delay
//
srl_16dx1 optcopdelay_i (.CLK(CLK), .CE(1'b1),.A({1'b0,OPT_COP}),.I(dmid),.O(dmida),.Q15()); // opt_cop + 1 clocks

//
// L1A Latency Delay 
//
srl_16dx1 latdelay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(dmida),.O(tdly), .Q15());  // 16 clocks
srl_16dx1 latdelay_2 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(tdly), .O(dmidb),.Q15()); // 16 clocks

always @(posedge CLK)
begin
	dmidc <= DELAY[5] ? dmidb : dmida; // + 1 clock
	dmidx <= DELAY[4] ? dmidd : dmidc; // + 1 clock
end

srl_16dx1 latdelay_3 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(dmidc),.O(dmidd),.Q15()); // 16 clocks

srl_16dx1 latdelay_4 (.CLK(CLK), .CE(1'b1),.A(DELAY[3:0]),.I(dmidx),.O(p1),.Q15()); // L1Latency + 1 clocks

always @(posedge CLK)
begin
	p0 <= p1;
	m1 <= p0;
	m2 <= m1;
	m3 <= m2;
end


//
// Fine Delay on L1A_Match
//
srl_16dx1 finedelay_i (.CLK(CLK), .CE(1'b1),.A(L1FD),.I(pre_l1a_match),.O(L1A_MATCH),.Q15()); // L1A Fine Delay + 1 clocks

always @(posedge CLK)
begin
	DOUT <= p0;
end


endmodule
