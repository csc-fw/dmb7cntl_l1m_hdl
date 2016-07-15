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
	input LAT_12_5US,
	input MTCH_3BX,
	input USE_CLCT,
	input [3:0] CLCT_ADJ,
	input [2:0] OPT_COP,
	input [5:0] DELAY,
	input [1:0] XL1ADLY,
	input [3:0] L1FD,
	output DOUT,
	output L1A_MATCH
);

	(* syn_keep = "true" *)    wire [26:0] fdly;
	(* syn_keep = "true" *)    wire [3:0] xdly;
	(* syn_keep = "true" *)     reg xdly_in;
	(* syn_preserve = "true" *) reg dmid;
	(* syn_keep = "true" *)    wire dmida;
	(* syn_keep = "true" *)    wire dmidb;
	(* syn_preserve = "true" *) reg dmidc;
	(* syn_keep = "true" *)    wire dmidd;
	(* syn_preserve = "true" *) reg dmidx;
	(* syn_keep = "true" *)    wire tdly;
	(* syn_keep = "true" *)    wire cdly;
	(* syn_keep = "true" *)    wire fx2in;

	(* syn_keep = "true" *)    wire p1;
	(* syn_preserve = "true" *) reg p0;
	(* syn_preserve = "true" *) reg m1;
	(* syn_preserve = "true" *) reg m2;
	(* syn_preserve = "true" *) reg m3;
	
	
	(* syn_preserve = "true" *) reg d_out;

	(* syn_keep = "true" *)     reg pre_l1a_match;

assign DOUT = d_out;

always @*
begin
	if(MTCH_3BX)
		pre_l1a_match = L1A & (p1 | p0 | m1);            // Symmetric 3bx match (plus/minus 1)
	else
		pre_l1a_match = L1A & (p1 | p0 | m1 | m2 | m3);  // Asymmetric 5bx match (plus 1 minus 3)
end

assign fx2in = USE_CLCT ? cdly : fdly[0];

//
// CLCT Delay
//
//srl_16dx1 clctdelay_1 (.CLK(CLK), .CE(1'b1),.A(CLCT_ADJ),.I(CLCT),.O(cdly),.Q15()); // 16 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) clctdelay_1 (.CLK(CLK),.A3(CLCT_ADJ[3]),.A2(CLCT_ADJ[2]),.A1(CLCT_ADJ[1]),.A0(CLCT_ADJ[0]),.D(CLCT),.Q(cdly));

//
// Fixed Delays
//
//srl_16dx1 fixdelay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(PLCT),   .O(fdly[0]),.Q15()); // 16 clocks
//srl_16dx1 fixdelay_2 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(fx2in),  .O(fdly[1]),.Q15()); // 16 clocks
//srl_16dx1 fixdelay_3 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(fdly[1]),.O(fdly[2]),.Q15()); // 16 clocks
//srl_16dx1 fixdelay_4 (.CLK(CLK), .CE(1'b1),.A(4'hE),.I(fdly[2]),.O(fdly[3]),.Q15()); // 15 clocks (set .A to 14 for 3bx and asymmetric 5bx matching, set to 13 for sym. 5bx, and set to 12 for sym 7bx)
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_1 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(PLCT),   .Q(fdly[0]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_2 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fx2in),  .Q(fdly[1]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_3 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[1]),.Q(fdly[2]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_4 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b0),.D(fdly[2]),.Q(fdly[3]));
//
// for 12.5us latence add in 368 clocks of delay
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_5 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[3]),.Q(fdly[4]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_6 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[4]),.Q(fdly[5]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_7 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[5]),.Q(fdly[6]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_8 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[6]),.Q(fdly[7]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_9 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[7]),.Q(fdly[8]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_10 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[8]),.Q(fdly[9]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_11 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[9]),.Q(fdly[10]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_12 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[10]),.Q(fdly[11]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_13 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[11]),.Q(fdly[12]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_14 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[12]),.Q(fdly[13]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_15 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[13]),.Q(fdly[14]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_16 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[14]),.Q(fdly[15]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_17 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[15]),.Q(fdly[16]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_18 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[16]),.Q(fdly[17]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_19 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[17]),.Q(fdly[18]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_20 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[18]),.Q(fdly[19]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_21 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[19]),.Q(fdly[20]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_22 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[20]),.Q(fdly[21]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_23 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[21]),.Q(fdly[22]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_24 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[22]),.Q(fdly[23]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_25 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[23]),.Q(fdly[24]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_26 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[24]),.Q(fdly[25]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) fixdelay_27 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(fdly[25]),.Q(fdly[26]));

always @*
begin
	if(LAT_12_5US)
		xdly_in = fdly[26]; // for 12.5us L1A latency
	else
		xdly_in = fdly[3];  // for 3.2us L1A latency
end

//
// Reverse Fine Delay
//
//srl_16dx1 revfdelay_i (.CLK(CLK), .CE(1'b1),.A(~L1FD),.I(xdly_in),.O(xdly[0]),.Q15()); // (15-L1FineDelay) + 1  clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) revfdelay_i (.CLK(CLK),.A3(~L1FD[3]),.A2(~L1FD[2]),.A1(~L1FD[1]),.A0(~L1FD[0]),.D(xdly_in),.Q(xdly[0]));

//
// Extra L1A Delay 
//
//srl_16dx1 xl1delay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(xdly[0]),.O(xdly[1]),.Q15()); // 16 clocks
//srl_16dx1 xl1delay_2 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(xdly[1]),.O(xdly[2]),.Q15()); // 16 clocks
//srl_16dx1 xl1delay_3 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(xdly[2]),.O(xdly[3]),.Q15()); // 16 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) xl1delay_1 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(xdly[0]),.Q(xdly[1]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) xl1delay_2 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(xdly[1]),.Q(xdly[2]));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) xl1delay_3 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(xdly[2]),.Q(xdly[3]));

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
//srl_16dx1 optcopdelay_i (.CLK(CLK), .CE(1'b1),.A({1'b0,OPT_COP}),.I(dmid),.O(dmida),.Q15()); // opt_cop + 1 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) optcopdelay_i (.CLK(CLK),.A3(1'b0),.A2(OPT_COP[2]),.A1(OPT_COP[1]),.A0(OPT_COP[0]),.D(dmid),.Q(dmida));

//
// L1A Latency Delay 
//
//srl_16dx1 latdelay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(dmida),.O(tdly), .Q15());  // 16 clocks
//srl_16dx1 latdelay_2 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(tdly), .O(dmidb),.Q15()); // 16 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) latdelay_1 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(dmida),.Q(tdly));
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) latdelay_2 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(tdly), .Q(dmidb));

always @(posedge CLK)
begin
	dmidc <= DELAY[5] ? dmidb : dmida; // + 1 clock
	dmidx <= DELAY[4] ? dmidd : dmidc; // + 1 clock
end

//srl_16dx1 latdelay_3 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(dmidc),.O(dmidd),.Q15()); // 16 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) latdelay_3 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(dmidc), .Q(dmidd));

//srl_16dx1 latdelay_4 (.CLK(CLK), .CE(1'b1),.A(DELAY[3:0]),.I(dmidx),.O(p1),.Q15()); // L1Latency + 1 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) latdelay_4 (.CLK(CLK),.A3(DELAY[3]),.A2(DELAY[2]),.A1(DELAY[1]),.A0(DELAY[0]),.D(dmidx), .Q(p1));

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
//srl_16dx1 finedelay_i (.CLK(CLK), .CE(1'b1),.A(L1FD),.I(pre_l1a_match),.O(L1A_MATCH),.Q15()); // L1A Fine Delay + 1 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) finedelay_i (.CLK(CLK),.A3(L1FD[3]),.A2(L1FD[2]),.A1(L1FD[1]),.A0(L1FD[0]),.D(pre_l1a_match),.Q(L1A_MATCH));

always @(posedge CLK)
begin
	d_out <= p0;
end

endmodule
