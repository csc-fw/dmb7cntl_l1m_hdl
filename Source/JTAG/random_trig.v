`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:07:11 11/20/2015 
// Design Name: 
// Module Name:    random_trig 
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
module random_trig #(
	parameter TMR = 0
)
(
	input CLK,
	input RST,
	input FTSTART,
	input FBURST,
	input ENL1RLS,
	input [3:1] GTRGSEL,
	input [3:1] LCT1SEL,
	input [3:1] LCT2SEL,
	input [3:1] LCT3SEL,
	input [3:1] LCT4SEL,
	input [3:1] LCT5SEL,
	output reg GTRGOUT,
	output reg SELRAN,
	output reg PREL1RLS,
	output [5:0] LCTOUT
);

wire [8:0] rlct1;
wire [8:0] rlct2;
wire [8:0] rlct3;
wire [8:0] rlct4;
wire [8:0] rlct5;
wire [8:0] rlcta;
wire [8:0] gtrga;
//wire [8:0] gtrgb;
wire [8:0] fba;
wire [8:0] fbb;
wire [8:0] fbc;
wire [8:0] fbd;
wire [8:0] fbe;
wire [8:0] fbf;
wire [8:0] fbg;
wire [8:0] fbh;
wire [8:0] fbp;
wire [8:0] fbq;
wire [8:0] fbr;
wire [8:0] fbs;
wire [8:0] fbt;
wire [8:0] fbu;
wire [8:0] fbv;
wire [8:0] fbw;
//wire [8:0] fbx;
wire gtrgab167;
//wire gtrgbb87;
wire rlct1b1;
wire rlct1b18;
wire rlct1b34;
wire rlct1b52;
wire rlct1b69;
wire rlct1b86;
wire rlct1b103;
wire rlct1b120;
wire rlct1b137;
wire rlct2b1;
wire rlct2b18;
wire rlct2b35;
wire rlct2b52;
wire rlct2b68;
wire rlct2b86;
wire rlct2b103;
wire rlct2b120;
wire rlct2b137;
wire rlct3b161;
wire rlct4b1;
wire rlct4b18;
wire rlct4b35;
wire rlct4b52;
wire rlct4b69;
wire rlct4b86;
wire rlct4b103;
wire rlct4b120;
wire rlct4b136;
wire rlct5b1;
wire rlct5b18;
wire rlct5b35;
wire rlct5b52;
wire rlct5b69;
wire rlct5b86;
wire rlct5b103;
wire rlct5b120;
wire rlct5b137;

wire rlctab1;
wire rlctab10;
wire rlctab27;
wire rlctab44;
wire rlctab60;
wire rlctab74;
wire rlctab75;
wire rlctab86;
wire rlctab87;

wire fbab35;
wire fbbb36;
wire fbcb39;
wire fbdb41;
wire fbeb47;
wire fbfb49;
wire fbgb52;
wire fbhb55;
wire fbpb57;
wire fbqb60;
wire fbrb63;
wire fbsb65;
wire fbtb68;
wire fbub71;
wire fbvb73;
wire fbwb79;
//wire fbxb81;

wire fbyb34;
wire fbib38;
wire fbjb44;
wire fbkb45;
wire fblb54;
wire fbmb56;
wire fbnb61;
wire fbob62;

reg  ftstart_1;
reg  fburst_1;
wire le_ftstart;
wire le_fburst;
reg  burst1000;
reg  finish1000;
wire [9:0] burst_cnt;
wire burst_rst;

wire [5:1] lct_sel_or;
wire [5:1] lct_fand;
wire lct1_fand;
wire lct2_fand;
wire lct3_fand;
wire lct4_fand;
wire lct5_fand;
wire [5:1] lct_sand;
wire lct1_sand;
wire lct2_sand;
wire lct3_sand;
wire lct4_sand;
wire lct5_sand;

reg  [5:1] lct;
reg  [5:1] lct_1;
wire [5:1] lct_rst;
wire lct_or;

wire pprel1rls;
reg  prel1rls_1;
wire l1rls_rst;

reg  gtrgout_1;
wire gtrg_rst;
wire [1:0] rule2_cnt;
wire gtrg_fand;
wire gtrg_sand;
wire gtrg_mid;
wire gtrg_dly;
wire rule2_ce;

assign {rlct1b137,rlct1b120,rlct1b103,rlct1b86,rlct1b69,rlct1b52,rlct1b34,rlct1b18,rlct1b1} = rlct1;
assign {rlct2b137,rlct2b120,rlct2b103,rlct2b86,rlct2b68,rlct2b52,rlct2b35,rlct2b18,rlct2b1} = rlct2;
assign rlct3b161 = rlct3[0];
assign {rlct4b136,rlct4b120,rlct4b103,rlct4b86,rlct4b69,rlct4b52,rlct4b35,rlct4b18,rlct4b1} = rlct4;
assign {rlct5b137,rlct5b120,rlct5b103,rlct5b86,rlct5b69,rlct5b52,rlct5b35,rlct5b18,rlct5b1} = rlct5;

assign {rlctab87,rlctab86,rlctab75,rlctab74,rlctab60,rlctab44,rlctab27,rlctab10,rlctab1} = rlcta;

assign gtrgab167 = gtrga[0];
//assign gtrgbb87 = gtrgb[0];

assign fbab35 = fba[0];
assign fbbb36 = fbb[0];
assign fbcb39 = fbc[0];
assign fbdb41 = fbd[0];
assign fbeb47 = fbe[0];
assign fbfb49 = fbf[0];
assign fbgb52 = fbg[0];
assign fbhb55 = fbh[0];
assign fbpb57 = fbp[0];
assign fbqb60 = fbq[0];
assign fbrb63 = fbr[0];
assign fbsb65 = fbs[0];
assign fbtb68 = fbt[0];
assign fbub71 = fbu[0];
assign fbvb73 = fbv[0];
assign fbwb79 = fbw[0];
//assign fbxb81 = fbx[0];


assign le_ftstart = FTSTART & ! ftstart_1;
assign le_fburst  = FBURST  & ! fburst_1;

assign lct_sel_or = {|LCT5SEL,|LCT4SEL,|LCT3SEL,|LCT2SEL,|LCT1SEL};

assign lct1_fand  = rlct1b1   & rlctab27 & rlct1b69 & rlct1b103 & rlct1b137 & rlctab60;
assign lct2_fand  = rlct2b1   & rlct2b35 & rlctab44 & rlct2b103 & rlct2b137 & rlctab60;
assign lct3_fand  = rlct3b161 & fbeb47   & fbfb49   & fbgb52    & fbhb55    & fbpb57;
assign lct4_fand  = rlct4b1   & rlct4b35 & rlct4b69 & rlct4b103 & rlctab10  & rlctab27;
assign lct5_fand  = rlct5b1   & rlct5b35 & rlct5b69 & rlct5b103 & rlct5b137 & rlctab27;

assign lct_fand   = {lct5_fand,lct4_fand,lct3_fand,lct2_fand,lct1_fand};

assign lct1_sand  = &({{4{LCT1SEL[3]}},{2{LCT1SEL[2]}},LCT1SEL[1]} | {rlct1b18, rlct1b120,rlctab10,rlct1b34, rlct1b52,rlctab44, rlct1b86});
assign lct2_sand  = &({{4{LCT2SEL[3]}},{2{LCT2SEL[2]}},LCT2SEL[1]} | {rlct2b18, rlct2b86, rlctab10,rlct2b120,rlct2b52,rlct2b68, rlctab27});
assign lct3_sand  = &({{4{LCT3SEL[3]}},{2{LCT3SEL[2]}},LCT3SEL[1]} | {fbwb79,   fbvb73,   fbub71,  fbtb68,   fbsb65,  fbrb63,   fbqb60});
assign lct4_sand  = &({{4{LCT4SEL[3]}},{2{LCT4SEL[2]}},LCT4SEL[1]} | {rlct4b136,rlct4b52, rlctab44,rlct4b86, rlct4b18,rlct4b120,rlctab60});
assign lct5_sand  = &({{4{LCT5SEL[3]}},{2{LCT5SEL[2]}},LCT5SEL[1]} | {rlct5b52, rlctab10, rlctab44,rlctab60, rlct5b18,rlct5b86, rlct5b120});

assign lct_sand   = {lct5_sand,lct4_sand,lct3_sand,lct2_sand,lct1_sand};

assign lct_rst    = lct | lct_1;
assign lct_or     = |lct;

assign burst_rst  = !FBURST || finish1000;

assign pprel1rls  = ENL1RLS & |GTRGSEL & gtrg_fand & gtrg_sand;
assign l1rls_rst  = PREL1RLS | prel1rls_1;
assign gtrg_rst   = GTRGOUT  | gtrgout_1 | rule2_cnt[1];

assign gtrg_fand  = gtrgab167 & fbab35 & fbbb36 & fbcb39 & fbdb41 & fbib38;
assign gtrg_sand  = &({{4{GTRGSEL[3]}},{2{GTRGSEL[2]}},GTRGSEL[1]} | {fbob62, fbnb61, fbmb56 ,fblb54, fbyb34, fbkb45, fbjb44});
assign rule2_ce   = GTRGOUT ^ gtrg_dly;

lfsr_2tap #(.N(161),.FB_tap(143),.TAP_A(1), .TAP_B(18),.TAP_C(34),.TAP_D(52),.TAP_E(69),.TAP_F(86),.TAP_G(103),.TAP_H(120),.TAP_I(137))
	LFSR_LCT1_i(.CLK(CLK),.OUT(rlct1));
lfsr_2tap #(.N(161),.FB_tap(143),.TAP_A(1), .TAP_B(18),.TAP_C(35),.TAP_D(52),.TAP_E(68),.TAP_F(86),.TAP_G(103),.TAP_H(120),.TAP_I(137))
	LFSR_LCT2_i(.CLK(CLK),.OUT(rlct2));
lfsr_2tap #(.N(161),.FB_tap(143),.TAP_A(161))
	LFSR_LCT3_i(.CLK(CLK),.OUT(rlct3));
lfsr_2tap #(.N(161),.FB_tap(143),.TAP_A(1), .TAP_B(18),.TAP_C(35),.TAP_D(52),.TAP_E(69),.TAP_F(86),.TAP_G(103),.TAP_H(120),.TAP_I(136))
	LFSR_LCT4_i(.CLK(CLK),.OUT(rlct4));
lfsr_2tap #(.N(161),.FB_tap(143),.TAP_A(1), .TAP_B(18),.TAP_C(35),.TAP_D(52),.TAP_E(69),.TAP_F(86),.TAP_G(103),.TAP_H(120),.TAP_I(137))
	LFSR_LCT5_i(.CLK(CLK),.OUT(rlct5));

lfsr_2tap #(.N(87),.FB_tap(74),.TAP_A(1), .TAP_B(10),.TAP_C(27),.TAP_D(44),.TAP_E(60),.TAP_F(74),.TAP_G(75),.TAP_H(86),.TAP_I(87))
	LFSR_LCT_A(.CLK(CLK),.OUT(rlcta));

lfsr_2tap #(.N(167),.FB_tap(161),.TAP_A(167))
	LFSR_GTRGA_i(.CLK(CLK),.OUT(gtrga));

//lfsr_2tap #(.N(87),.FB_tap(74),.TAP_A(87))
//	LFSR_GTRGB_i(.CLK(CLK),.OUT(gtrgb));


lfsr_2tap #(.N(35),.FB_tap(33),.TAP_A(35))
	LFSR_FBA_i(.CLK(CLK),.OUT(fba));
lfsr_2tap #(.N(36),.FB_tap(25),.TAP_A(36))
	LFSR_FBB_i(.CLK(CLK),.OUT(fbb));
lfsr_2tap #(.N(39),.FB_tap(35),.TAP_A(39))
	LFSR_FBC_i(.CLK(CLK),.OUT(fbc));
lfsr_2tap #(.N(41),.FB_tap(38),.TAP_A(41))
	LFSR_FBD_i(.CLK(CLK),.OUT(fbd));
lfsr_2tap #(.N(47),.FB_tap(42),.TAP_A(47))
	LFSR_FBE_i(.CLK(CLK),.OUT(fbe));
lfsr_2tap #(.N(49),.FB_tap(40),.TAP_A(49))
	LFSR_FBF_i(.CLK(CLK),.OUT(fbf));
lfsr_2tap #(.N(52),.FB_tap(49),.TAP_A(52))
	LFSR_FBG_i(.CLK(CLK),.OUT(fbg));
lfsr_2tap #(.N(55),.FB_tap(31),.TAP_A(55))
	LFSR_FBH_i(.CLK(CLK),.OUT(fbh));
lfsr_2tap #(.N(57),.FB_tap(50),.TAP_A(57))
	LFSR_FBP_i(.CLK(CLK),.OUT(fbp));
lfsr_2tap #(.N(60),.FB_tap(59),.TAP_A(60))
	LFSR_FBQ_i(.CLK(CLK),.OUT(fbq));
lfsr_2tap #(.N(63),.FB_tap(62),.TAP_A(63))
	LFSR_FBR_i(.CLK(CLK),.OUT(fbr));
lfsr_2tap #(.N(65),.FB_tap(47),.TAP_A(65))
	LFSR_FBS_i(.CLK(CLK),.OUT(fbs));
lfsr_2tap #(.N(68),.FB_tap(59),.TAP_A(68))
	LFSR_FBT_i(.CLK(CLK),.OUT(fbt));
lfsr_2tap #(.N(71),.FB_tap(65),.TAP_A(71))
	LFSR_FBU_i(.CLK(CLK),.OUT(fbu));
lfsr_2tap #(.N(73),.FB_tap(48),.TAP_A(73))
	LFSR_FBV_i(.CLK(CLK),.OUT(fbv));
lfsr_2tap #(.N(79),.FB_tap(70),.TAP_A(79))
	LFSR_FBW_i(.CLK(CLK),.OUT(fbw));
//lfsr_2tap #(.N(81),.FB_tap(77),.TAP_A(81))
//	LFSR_FBX_i(.CLK(CLK),.OUT(fbx));

lfsr_4tap #(.N(34),.FB_tap1(1),.FB_tap2(2),.FB_tap3(27))
	LFSR_FBY_i(.CLK(CLK),.OUT(fbyb34));
lfsr_4tap #(.N(38),.FB_tap1(1),.FB_tap2(5),.FB_tap3(6))
	LFSR_FBI_i(.CLK(CLK),.OUT(fbib38));
lfsr_4tap #(.N(44),.FB_tap1(17),.FB_tap2(18),.FB_tap3(43))
	LFSR_FBJ_i(.CLK(CLK),.OUT(fbjb44));
lfsr_4tap #(.N(45),.FB_tap1(41),.FB_tap2(42),.FB_tap3(44))
	LFSR_FBK_i(.CLK(CLK),.OUT(fbkb45));
lfsr_4tap #(.N(54),.FB_tap1(17),.FB_tap2(2),.FB_tap3(27))
	LFSR_FBL_i(.CLK(CLK),.OUT(fblb54));
lfsr_4tap #(.N(56),.FB_tap1(34),.FB_tap2(35),.FB_tap3(55))
	LFSR_FBM_i(.CLK(CLK),.OUT(fbmb56));
lfsr_4tap #(.N(61),.FB_tap1(45),.FB_tap2(46),.FB_tap3(60))
	LFSR_FBN_i(.CLK(CLK),.OUT(fbnb61));
lfsr_4tap #(.N(62),.FB_tap1(5),.FB_tap2(6),.FB_tap3(61))
	LFSR_FBO_i(.CLK(CLK),.OUT(fbob62));

always @(posedge CLK)
begin
	ftstart_1  <= FTSTART;
	fburst_1   <= FBURST;
	lct_1      <= lct;
	finish1000 <= (burst_cnt == 10'd1000);
	prel1rls_1 <= PREL1RLS;
	gtrgout_1  <= GTRGOUT;
	if(le_ftstart)
		SELRAN <= ~SELRAN;
	if(l1rls_rst)
		PREL1RLS <= pprel1rls;
end

always @(posedge CLK or posedge finish1000)
begin
	if(finish1000)
		burst1000 <= 1'b0;
	else
		if(le_fburst)
			burst1000 <= 1'b1;
end

//
// burst counter
//
cbnce #(
	.Width(10),
	.TMR(TMR)
)
burst_cntr_i (
	.CLK(CLK),
	.RST(burst_rst),
	.CE(GTRGOUT),
	.Q(burst_cnt)
);

genvar i;
generate
begin
	for(i=1;i<6;i=i+1) begin: idx1
		always @(posedge CLK)
		begin
			if(lct_rst[i])       // synchronous reset
				lct[i] <= 1'b0;
			else
				lct[i] <= SELRAN & lct_sel_or[i] & lct_fand[i] & lct_sand[i];
		end
		srl_16dx1 LCTOUT_srl_i (.CLK(CLK),.CE(1'b1),.A(4'hF),.I(lct[i]),.O(LCTOUT[i]),.Q15());
	end
end
endgenerate

srl_16dx1 LCTOUT_srl_0 (.CLK(CLK),.CE(1'b1),.A(4'hF),.I(lct_or),.O(LCTOUT[0]),.Q15());

//
// L1A trigger output
//
always @(posedge CLK)
begin
	if(gtrg_rst)
		GTRGOUT <= 1'b0;
	else
		GTRGOUT <= (SELRAN | burst1000) & |GTRGSEL & gtrg_fand & gtrg_sand;
end


srl_16dx1 gtrg_srl_0 (.CLK(CLK),.CE(1'b1),.A(4'hF),.I(GTRGOUT),.O(gtrg_mid), .Q15());

srl_16dx1 gtrg_srl_1 (.CLK(CLK),.CE(1'b1),.A(4'h8),.I(gtrg_mid),.O(gtrg_dly),.Q15());


//
// rule 2 counter
//
udl_cnt #(
	.Width(2),
	.TMR(TMR)
)
rule_2_count_i
(
	.CLK(CLK),
	.RST(RST),
	.CE(rule2_ce),
	.L(1'b0),
	.UP(GTRGOUT),
	.D(2'b00),
	.Q(rule2_cnt)
);

endmodule
