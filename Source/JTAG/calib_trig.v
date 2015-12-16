`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:08:26 11/19/2015 
// Design Name: 
// Module Name:    calib_trig 
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
module calib_trig #(
	parameter TMR = 0
)
(
	input CLKCMS,
	input CLK80,
	input RST,
	input FINJ,
	input FPLS,
	input FPED,
	input CCBINJ,
	input CCBPLS,
	input PLSINJEN,
	input PRELCT,
	input PREGTRG,
	input RNDMGTRG,
	input [4:0] INJDLY,
	input [4:0] EXTDLY,
	input [3:0] CALLCTDLY,
	input [4:0] CALGDLY,
	input [1:0] XL1ADLY,
	
	output reg PEDESTAL,
	output reg CAL_GTRG,
	output reg CALLCT_1,
	output INJECT,
	output PULSE,
	output reg SCPSYN,
	output SYNCIP,
	output LCTRQST,
	output reg INJPLS
);

reg  finj_1;
reg  finj_2;
wire preinj;
reg  fpls_1;
reg  fpls_2;
wire prepls;
reg  fped_1;
wire rstpls;
reg  pls_end;
reg inj_hld;
reg en_inj_hld;
reg pls_hld;
reg en_pls_hld;
wire dly_inj;
reg  dly_inj_1;
wire dly_pls;
reg  dly_pls_1;
reg  neg_inj;
reg  pos_inj;
reg  neg_pls;
reg  pos_pls;
wire [6:0] rstplscnt;
wire ce_plscnt;
wire l1arqst;
wire lctd1;
reg  lctd2;
wire lctd3;
wire [6:0] fdly;
wire [3:0] xdly;
wire gdly;
reg  l1amid;
reg  l1amid2;
wire l1adly;

assign preinj  = finj_1 & ~finj_2; // leading edge
assign prepls  = fpls_1 & ~fpls_2; // leading edge
assign le_fped = FPED   & ~fped_1; // leading edge
assign SYNCIP  = preinj | prepls;
assign rstpls  = RST | pls_end;
assign INJECT  = INJDLY[0] ? pos_inj : neg_inj; 
assign PULSE   = EXTDLY[0] ? pos_pls : neg_pls;
assign ce_plscnt = (INJECT | PULSE) & (inj_hld | pls_hld);
assign LCTRQST = INJPLS | PRELCT;
assign l1arqst = INJPLS | PREGTRG;

(* IOB = "TRUE" *)
always @(posedge CLKCMS)
begin
	SCPSYN <= SYNCIP;
end

always @(posedge CLKCMS)
begin
	if(PLSINJEN)
		begin
			finj_1 <= FINJ;
			fpls_1 <= FPLS;
		end
	fped_1 <= FPED;
	finj_2 <= finj_1;
	fpls_2 <= fpls_1;
	INJPLS <= CCBINJ | CCBPLS | SYNCIP;
	pls_end <= rstplscnt[6];
end

always @(posedge CLKCMS or posedge RST)
begin
	if(RST)
		PEDESTAL <= 1'b0;
	else
		if(le_fped)
			PEDESTAL <= ~PEDESTAL;
end

always @(posedge CLKCMS or posedge rstpls)
begin
	if(rstpls)
		begin
			inj_hld <= 1'b0;
			pls_hld <= 1'b0;
		end
	else
		begin
			if(preinj | CCBINJ)
				inj_hld <= 1'b1;
			if(prepls | CCBPLS | PRELCT)
				pls_hld <= 1'b1;
		end
end

always @(posedge CLKCMS or posedge PEDESTAL)
begin
	if(PEDESTAL)
		begin
			en_inj_hld <= 1'b0;
			en_pls_hld <= 1'b0;
		end
	else
		begin
			en_inj_hld <= inj_hld;
			en_pls_hld <= pls_hld;
		end
end

srl_16dx1 int_inject_delay_i (.CLK(CLK80), .CE(1'b1),.A(INJDLY[4:1]),.I(en_inj_hld),.O(dly_inj),.Q15());
srl_16dx1 ext_pulse_delay_i  (.CLK(CLK80), .CE(1'b1),.A(EXTDLY[4:1]),.I(en_pls_hld),.O(dly_pls),.Q15());

always @(posedge CLK80)
begin
	dly_inj_1 <= dly_inj;
	dly_pls_1 <= dly_pls;
	pos_inj   <= dly_inj_1;
	pos_pls   <= dly_pls_1;
end

always @(negedge CLK80)
begin
	neg_inj   <= dly_inj_1;
	neg_pls   <= dly_pls_1;
end


cbnce #(
	.Width(7),
	.TMR(TMR)
)
rstpls_cntr_i (
	.CLK(CLKCMS),
	.RST(rstpls),
	.CE(ce_plscnt),
	.Q(rstplscnt)
);

//
// Calibration LCT delay (from charge injection to LCT) CALLCT_1 delay: 475ns + 25ns*CALLCTDLY[3:0]
//
srl_16dx1 cfixdelay_1   (.CLK(CLKCMS), .CE(1'b1),.A(4'hF),          .I(LCTRQST),.O(lctd1),.Q15()); // 16 clocks
srl_16dx1 callctdelay_i (.CLK(CLKCMS), .CE(1'b1),.A(CALLCTDLY[3:0]),.I(lctd2),  .O(lctd3),.Q15()); // CALLCTDLY[3:0] + 1 clocks

always @(posedge CLKCMS)
begin
	lctd2    <= lctd1;
	CALLCT_1 <= lctd3;
end

//
// Calibration LLA delay (from charge injection to L1A) CAL_GTRG delay: 3050ns + 400ns*XL1ADLY[1:0] + 25ns*CALGDLY[3:0]
//

//fixed delays
srl_16dx1 cfixdelay_2   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(l1arqst),.O(fdly[0]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_3   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(fdly[0]),.O(fdly[1]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_4   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(fdly[1]),.O(fdly[2]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_5   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(fdly[2]),.O(fdly[3]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_6   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(fdly[3]),.O(fdly[4]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_7   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(fdly[4]),.O(fdly[5]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_8   (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(fdly[5]),.O(fdly[6]),.Q15()); // 16 clocks
srl_16dx1 cfixdelay_9   (.CLK(CLKCMS),.CE(1'b1),.A(4'h5),.I(fdly[6]),.O(xdly[0]),.Q15());        //  6 clocks

//extra delays
srl_16dx1 extradelay_2  (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(xdly[0]),.O(xdly[1]),.Q15()); // 16 clocks
srl_16dx1 extradelay_3  (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(xdly[1]),.O(xdly[2]),.Q15()); // 16 clocks
srl_16dx1 extradelay_4  (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(xdly[2]),.O(xdly[3]),.Q15()); // 16 clocks

always @(posedge CLKCMS) // (0, 16, 32, 48) + 1 clock
begin
	case(XL1ADLY)
		2'd0 : l1amid <= xdly[0]; 
		2'd1 : l1amid <= xdly[1]; 
		2'd2 : l1amid <= xdly[2]; 
		2'd3 : l1amid <= xdly[3]; 
		default : l1amid <= xdly[0];
	endcase
end

// L1A delay adjustment
srl_16dx1 calgdelay_1 (.CLK(CLKCMS),.CE(1'b1),.A(4'hF),.I(l1amid),.O(gdly),.Q15()); // 16 clocks

always @(posedge CLKCMS)
begin
	l1amid2 <= CALGDLY[4] ? gdly : l1amid; 
end

srl_16dx1 calgdelay_2 (.CLK(CLKCMS),.CE(1'b1),.A(CALGDLY[3:0]),.I(l1amid2),.O(l1adly),.Q15()); // CALGDLY[3:0] + 1 clocks

always @(posedge CLKCMS)
begin
	CAL_GTRG <= l1adly | RNDMGTRG; 
end

endmodule
