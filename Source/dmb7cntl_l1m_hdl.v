`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:19:30 11/05/2015 
// Design Name: 
// Module Name:    dmb7cntl_l1a_match_hdl 
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
module dmb7cntl_l1m_hdl #(
	parameter TMR = 0,
	parameter SIM = 0
)
(
	// clocks
	input CLK25IN,
	input CLKGIN,
	input GRXCLK,
	// trigger
	input [5:0] PRE_LCT,
	input [5:1] CLCT,
	input L1ACC,
	input ALCTDAV,
	input TMBDAV,
	input [5:1] FEBDAV,
	input [5:1] MOLAP,
	input [2:0] CCBCAL,
	output SCPSYN,
//	output reg [5:1] L1M_LCT,
//	output reg L1A_CFEB,
	output reg [5:1] TRG_ENC_B0,
	output reg [5:1] TRG_ENC_B1,
	output reg [5:1] TRG_ENC_B2,
	output INJ_PULSE,
	output EXT_PULSE,
	output LCT_RQST_OUT,
	output [2:0] SPARE,
	// Flash memory
	input SFMSOIN,
	output SFMSI,
	output SFMSCK,
	output SFMRST_B,
	output SFMCSO_B,
	output SFMWPOUT_B,
	// FEB clock phase
	output FEBDLYIN,
	output FEBDLYCLK,
	output FEBDLYAE,
	// FIFOs
	input [7:1] FIFOAE,
	input [7:1] FIFOHF,
	input [7:1] FIFOF,
	input [7:1] FFOR_B,
	input [17:0] FIFOD,
	input RDFFNXT,
	output FIFORCLK1,
	output FIFORCLK2,
	output FFMRST_B,
	output FFPRST_B,
	output  [7:1] RENFIFO_B,
	output  [7:1] OEFIFO_B,
	//
	input GIGAEN,
	input EAFEB,
	input SEL_TX_RX,
	// CCB
	input ENL1RLS,
	input [5:0] CCBCMD,
	input CCBCMDSTRB,
	input [7:0] CCBDATA,
	input CCBDATASTRB,
	input SOFTRSTIN,
	input BX0IN,
	input BXRSTIN,
	input L1ARSTIN,
	input RESETIN,
	input CLKENAIN,
	output L1ASRST,
	output PREL1RLS_B,
//	output reg FEB_GRST,
	output reg CTRLREADY,
	// Misc
	input [4:1] GA_B,
	input [4:1] FPMODE,
	inout [8:1] MULTI_IO,
	output [16:9] MULTI_OUT,
	output LOADDLY_OUT,
	output [7:0] LEDS,
	//G-Link
	input [15:0] GLRD,
	input GRXERR,
	input GRXDAV,
	output reg [15:0] GOUT,
	output reg TX_ENABLE,
	output reg TX_ERROR
);


wire rst;
reg  rst_1;
wire le_rst;
reg  rst_plsinj;

wire rxclk;
reg  rxerr;
reg  rxdav;
reg  [1:0] crxerr;
reg  [1:0] crxdav;
reg  [15:0] rxdata;
wire [15:0] dout;
wire gpush;

wire fpgaready;
reg  fpgaready_1;
reg  fpgaready_2;
wire le_fpgaready;
reg  fpgarst;
wire clr_fpgarst;
wire [3:0] fpgarst_cnt;
wire clkddu;
wire clkcms;
wire raw_clkcms;
wire clk80;
wire dv128clk;

reg  ce_crdy_cnt;
wire clr_crdy_cnt;
wire [15:0] crdy_cnt;

wire calgtrg;
wire cal_mode;
wire caltrgsel;
wire enacfeb;
wire encode_fm;
wire mtch_3bx_fm;
wire lat_12_5us_fm;
wire use_clct_fm;
wire dcfeb_in_use_fm;
wire [3:0] clct_adj_fm;
wire [2:0] opt_cop_adj_fm;
wire [5:0] callct;
wire [3:0] l1fndlym;
wire [5:0] l1latency;
wire [25:0] davdly;
wire [7:0] cabledly;
wire [1:0] xl1a2cal;
wire [2:0] killinput;

wire [3:0] jtrgen;

wire l1acfeb;
wire gfpush;
wire errorlct;
wire [5:0] l1a_match;
wire [5:0] psh_aff;
wire [5:0] dly_aff;
wire [5:0] lct;
wire [5:1] enc_bit0;
wire [5:1] enc_bit1;
wire [5:1] enc_bit2;
reg  [5:1] enc_bit0_1;
reg  [5:1] enc_bit1_1;
reg  [5:1] enc_bit2_1;
wire [5:1] c_enc_bit0;
wire [5:1] c_enc_bit1;
wire [5:1] c_enc_bit2;

reg mirrclk;
reg rstmirr;
wire trgdly0;
wire outen;
wire clr0;
reg  pwr_on_hold_off;
wire release_poh;
wire [15:0] pwr_on_cnt;

wire [31:0] tmcount;
wire [2:0] davmon;
wire jreadout;
wire dpush;

wire clkena;
wire tmdavrst;
wire pop;
wire bc0;
wire bx0;
wire bxrst;
wire l1arst;
wire gtrgfifoerr;
wire gempty_b;
wire [5:1] davenbl;
wire [31:0] tmdav;
wire [7:1] monitor;
wire [16:0] davact;
wire [3:0] cfebbx;
wire [11:0] gbxn;
wire [47:0] status;

wire sfmso;
wire sfmcs_b;
wire sfmwp_b;
wire sfmtdo;
wire encode_jt;
wire mtch_3bx_jt;
wire lat_12_5us_jt;
wire use_clct_jt;
wire dcfeb_in_use_jt;
wire sfmtck;
wire sfmtdi;
wire sfmtest;
wire [3:0] clct_adj_jt;
wire [2:0] opt_cop_adj_jt;
wire [1:0] xl1a2sfm;
wire [10:0] serfm;
wire [7:0] cbldset;
wire [4:0] febclkdly;
wire [6:0] crateidset;
wire [6:0] crateid;
wire [11:0] daqmbid;
wire [3:0] l1fndly;
wire [2:0] setkillin;
wire [47:0] statsfm;

wire ccbped;
wire ccbinjin;
wire ccbplsin;
reg  ccbinj;
reg  ccbpls;
reg  ccbinj_1;
reg  ccbpls_1;
reg  ccbpls_2;
reg  plsinjen;

wire pedestal;
wire [7:0] l1abufcnt;
wire [5:1] cfebdaverr;

wire jrst;
wire fifomrst;
wire inject;
wire pulse;
wire prel1rls;
wire [15:0] teststat_mon;
wire [9:1] monjtag;
wire [7:0] joef;
wire [2:0] ttcdcal;

wire [7:1] renff_b;
wire [7:1] oeff_b;
wire giga_en;
wire rd_ff_nxt;
wire [17:0] fifo_d;
wire [7:1] ff_or_b;

wire oeovlp;

wire [15:0] gtrgdiag;
wire [15:0] gendiag;
wire [7:0] sfmdiag;
wire [9:1] auxout;
wire [8:1] multin;
wire [8:1] fromconx;
wire [16:1] multout;
wire outputenl_b;
wire outputenh_b;
wire [16:1] diagcount;

IBUF IBUF_GIGAEN_i (.O(giga_en),.I(GIGAEN));
IBUF IBUF_RDFFNXT_i (.O(rd_ff_nxt),.I(RDFFNXT));

genvar i;
generate
begin
	for(i=1;i<8;i=i+1) begin: idx1
		OBUF  OBUF_RENFIFO_B (.O(RENFIFO_B[i]), .I(renff_b[i]));
		OBUF  OBUF_OENFIFO_B (.O(OEFIFO_B[i]),  .I(oeff_b[i]));
	end
	for(i=1;i<9;i=i+1) begin: idx2
		IOBUF  IOB_MULTI_B (.O(multin[i]), .IO(MULTI_IO[i]), .I(multout[i]), .T(outputenl_b));
	end
	for(i=0;i<18;i=i+1) begin: idx3
		IBUF IBUF_FIFOD_i (.O(fifo_d[i]),.I(FIFOD[i])); //[17:0]
	end
	for(i=1;i<8;i=i+1) begin: idx4
		IBUF IBUF_FFOR_B_i (.O(ff_or_b[i]),.I(FFOR_B[i])); //[7:1]
	end
end
endgenerate

assign rst  = (RESETIN | jrst | fpgarst | L1ASRST);
assign LEDS = {killinput,l1fndlym[2],xl1a2cal,errorlct,gfpush};
assign daqmbid = {crateid,~GA_B};
assign MULTI_OUT = outputenh_b ? 8'hzz : multout[16:9];
assign SPARE = 3'b000;

//
// Gigabit link (TLK) -- path to DDU
//
IBUFG  IBUFG_rxclk (.O(rxclk), .I(GRXCLK));
(* IOB = "TRUE" *)
always @(posedge rxclk)
begin
	rxdata <= GLRD;
	rxerr  <= GRXERR;
	rxdav  <= GRXDAV;
end

always @(posedge rxclk or posedge rst)
begin
	if(rst)
		crxerr <= 2'b00;
	else
		if(rxerr)
			crxerr <= crxerr + 1;
	if(rst)
		crxdav <= 2'b00;
	else
		if(rxdav)
			crxdav <= crxdav + 1;
end

(* IOB = "TRUE" *)
always @(posedge clkddu)
begin
	GOUT      <= dout;
	TX_ENABLE <= gpush;
	TX_ERROR  <= 1'b0;
end

//
// CLKGEN2 clock sources 
//

clkgen2 clkgen2_i(
	.CLKIN1(CLK25IN),
	.CLKIN2(CLKGIN),
	.READY(fpgaready),
	.CLKDDU(clkddu),
	.CLKCMS(clkcms),
	.RAW_CLKCMS(raw_clkcms),
	.CLK80(clk80),
	.FIFORCLK1(FIFORCLK1),
	.FIFORCLK2(FIFORCLK2),
	.DV128CLK(dv128clk)
);


//
// Resets and holdoffs 
//

always @(posedge clkcms)
begin
	fpgaready_1 <= fpgaready;
	fpgaready_2 <= fpgaready_1;
	rst_1       <= rst;
	rst_plsinj  <= le_rst;
end

assign le_rst       = rst & ~rst_1;
assign le_fpgaready = fpgaready & ~fpgaready_2;
assign clr_fpgarst  = (fpgarst_cnt == 4'hF);
assign clr_crdy_cnt = (crdy_cnt == 4'hF);


always @(posedge clkcms or posedge clr_fpgarst) // fpgarst lasts for 16 clock cycles
begin
	if(clr_fpgarst)
		fpgarst <= 1'b0;
	else
		if(le_fpgaready)
			fpgarst <= 1'b1;
end

cbnce #(
	.Width(4),
	.TMR(TMR)
)
fpgarst_cntr_i (
	.CLK(clkcms),
	.RST(~fpgaready),
	.CE(fpgarst),
	.Q(fpgarst_cnt)
);

always @(posedge clkcms or posedge rst_plsinj) 
begin
	if(rst_plsinj)
		plsinjen <= 1'b0;
	else
		plsinjen <= ~plsinjen;
end

always @(posedge clkcms or posedge clr_crdy_cnt) // fpgarst lasts for 16 clock cycles
begin
	if(clr_crdy_cnt)
		ce_crdy_cnt <= 1'b0;
	else
		if(le_fpgaready)
			ce_crdy_cnt <= 1'b1;
end

cbnce #(
	.Width(16),
	.TMR(TMR)
)
ctrlready_cntr_i (
	.CLK(clkcms),
	.RST(~fpgaready),
	.CE(ce_crdy_cnt),
	.Q(crdy_cnt)
);

(* IOB = "TRUE" *)
always @(posedge clkcms or negedge fpgaready)
begin
	if(~fpgaready)
		CTRLREADY <= 1'b0;
	else
		if(clr_crdy_cnt)
			CTRLREADY <= 1'b1;
end


//
// TRGCNTRL Trigger Control
//

assign l1latency = davdly[20:15];

trgcntrl #(
	.TMR(TMR)
)
trgcntrl_i (
	// Inputs 
	.CLK(clkcms),
	.CGTRG(calgtrg),
	.BGTRG(L1ACC),
	.CMODE(cal_mode),
	.CALTRGSEL(caltrgsel),
	.EAFEB(enacfeb),
	.LAT_12_5US(lat_12_5us_fm),
	.MTCH_3BX(mtch_3bx_fm),
	.USE_CLCT(use_clct_fm),
	.DCFEB_IN_USE(dcfeb_in_use_fm),
	.OPT_COP_ADJ(opt_cop_adj_fm),
	.CLCT_ADJ(clct_adj_fm),
	.CSTRIP(callct),
	.PRE_LCT_IN(PRE_LCT),
	.CLCT(CLCT),
	.L1FINEDELAY(l1fndlym),
	.L1LATNCY(l1latency),
	.GPUSHDLY(davdly[14:10]),
	.CABLEDLY(cabledly),
	.XL1ADLY(xl1a2cal),
	.KILLINPUT(killinput),
	.JTRGEN(jtrgen),
	// Outputs 
	.L1ACFEB(l1acfeb),
	.GFPUSH(gfpush),
	.LCTERR(errorlct),
	.L1A_MATCH(l1a_match), //[5:0]
	.PSH_AFF(psh_aff),
	.DLY_AFF(dly_aff),
	.PRE_LCT_OUT(lct)
);


//
// Trigger encoding 
//
trig_encoder
trgenc_i(
	//inputs
	.ENCODE(encode_fm),
	.DCFEB_IN_USE(dcfeb_in_use_fm),
	.RESYNC_RST(rst),
	.L1ACFEB(l1acfeb),
	.PRE_LCT_OUT(lct[5:1]), //[5:1]
	.L1A_MATCH(l1a_match[5:1]),   //[5:1]
	//outputs
	.ENC_BIT0(enc_bit0),    //[5:1]
	.ENC_BIT1(enc_bit1),    //[5:1]
	.ENC_BIT2(enc_bit2)     //[5:1]
);

assign outen = mirrclk ^ trgdly0;
assign clr0 = 1'b0;

always @(posedge clkcms)
begin
	enc_bit0_1 <= enc_bit0;
	enc_bit1_1 <= enc_bit1;
	enc_bit2_1 <= enc_bit2;
end

assign c_enc_bit0 = cabledly[0] ? enc_bit0_1 : enc_bit0;
assign c_enc_bit1 = cabledly[0] ? enc_bit1_1 : enc_bit1;
assign c_enc_bit2 = cabledly[0] ? enc_bit2_1 : enc_bit2;

//(* IOB = "TRUE" *)
//always @(posedge clkcms)
//begin
////	FEB_GRST <= febrst;
//	TRG_ENC_B2 <= {5{febrst}};
//end

(* IOB = "TRUE" *)
always @(posedge clk80 or posedge fpgarst)
begin
	if(fpgarst) begin
//		L1M_LCT  <= 5'b00000;
//		L1A_CFEB <= 1'b0;
		TRG_ENC_B0 <= 5'b00000;
		TRG_ENC_B1 <= 5'b00000;
		TRG_ENC_B2 <= 5'b00000;
	end
	else
		if(outen) begin
//			L1M_LCT <= l1a_match;
//			L1A_CFEB <= l1acfeb;
			TRG_ENC_B0 <= c_enc_bit0;
			TRG_ENC_B1 <= c_enc_bit1;
			TRG_ENC_B2 <= c_enc_bit2;
		end
end

// mirror clock

always @(posedge clkcms or posedge rstmirr)
begin
	if(rstmirr)
		mirrclk <= 1'b0;
	else
		mirrclk <= 1'b1;
end

always @(negedge clkcms or negedge mirrclk)
begin
	if(!mirrclk)
		rstmirr <= 1'b0;
	else
		rstmirr <= mirrclk;
end

// power on holdoff of 210ms for L1A and DAV timers

assign release_poh = (pwr_on_cnt == 16'hFFFF); //210ms holdoff.

always @(posedge clkcms or posedge clr0)
begin
	if(clr0)
		pwr_on_hold_off <= 1'b0;
	else
		pwr_on_hold_off <= !release_poh & (fpgarst | pwr_on_hold_off);
end

cbnce #(
	.Width(16),
	.TMR(TMR)
)
pwr_on_holdoff_i (
	.CLK(dv128clk),
	.RST(rst),
	.CE(pwr_on_hold_off),
	.Q(pwr_on_cnt)
);

// LCT to L1A timer
trg_timer #(
	.Width(10),
	.TMR(0)
)
LCT_to_L1A_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(lct[0]),
	.STOP(gfpush),
	.TIME(tmcount[9:0])
);

// CFEB DAV to FIFO push timer
trg_timer #(
	.Width(6),
	.TMR(0)
)
CFEB_DAV_to_push_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(davmon[0]),
	.STOP(dpush),
	.TIME(tmcount[15:10])
);

// TMB DAV to FIFO push timer
trg_timer #(
	.Width(6),
	.TMR(0)
)
TMB_DAV_to_push_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(davmon[1]),
	.STOP(dpush),
	.TIME(tmcount[21:16])
);

assign tmcount[23:22] = 2'b0;

// ALCT DAV to FIFO push timer
trg_timer #(
	.Width(6),
	.TMR(0)
)
ALCT_DAV_to_push_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(davmon[2]),
	.STOP(dpush),
	.TIME(tmcount[29:24])
);

assign tmcount[31:30] = 2'b0;

//
// GTRGFIFO Global Trigger FIFO Control
//

gtrgfifo #(
	.TMR(TMR)
)
gtrgfifo_i (
	// Inputs
	.CLK(clkcms),
	.RST(rst),
	.RDRST(tmdavrst),
	.PUSH(gfpush),
	.TMBDAV(TMBDAV),
	.ALCTDAV(ALCTDAV),
	.POP(pop),
	.BXRST(bxrst),
	.BC0(bc0),
	.PSH_AFF(psh_aff),
	.DAV(FEBDAV),
	.L1FINEDELAY(l1fndlym),
	.FEBDAVDLY(davdly[4:0]),
	.TMBDAVDLY(davdly[9:5]),
	.GPUSHDLY(davdly[14:10]),
	.ALCTDAVDLY(davdly[25:21]),
	.CABLEDLY(cabledly),
	.MOVLP(MOLAP),
	.KILLINPUT(killinput),
	// Outputs 
	.DPUSH(dpush),
	.GTRGFIFOERR(gtrgfifoerr),
	.EMPTY_B(gempty_b),
	.DAVEN(davenbl),
	.TMDV(tmdav),
	.MONITOR(monitor[7:2]),
	.DAVMON(davmon),
	.DAVSOUT(davact),
	.CFEBBX(cfebbx),
	.BXCOUNTOUT(gbxn),
	.UPDN(l1abufcnt),
	.GTRGDIAG(gtrgdiag),
	.DAVERROR(cfebdaverr)
);

//
// SERFMEM -- Serial Flash Memory
//

assign sfmso = SFMSOIN;
assign SFMCSO_B = sfmcs_b;
assign SFMWPOUT_B =sfmwp_b;

serfmem #(
	.TMR(TMR)
)
serfmem_i (
	// Inputs
	.CLKCMS(clkcms),
	.RAW_CLKCMS(raw_clkcms),
	.RST(fpgarst),
	.ENCODE_JT(encode_jt),
	.MTCH_3BX_JT(mtch_3bx_jt),
	.LAT_12_5US_JT(lat_12_5us_jt),
	.USE_CLCT_JT(use_clct_jt),
	.DCFEB_IN_USE_JT(dcfeb_in_use_jt),
	.TCKSFM(sfmtck),
	.TDISFM(sfmtdi),
	.TESTSFMIN(sfmtest),
	.SFMIN(sfmso),
	.CLCT_ADJ_JT(clct_adj_jt),
	.OPT_COP_ADJ_JT(opt_cop_adj_jt),
	.XL1AIN(xl1a2sfm),
	.SERFM(serfm),
	.CBLDSET(cbldset),
	.FEBCLKDLYIN(febclkdly),
	.CRTIDIN(crateidset),
	.L1FDLYIN(l1fndly),
	.SETKILLIN(setkillin),
	
	// Outputs 
	.SFMSCK(SFMSCK),
	.SFMWP_B(sfmwp_b),
	.SFMRST_B(SFMRST_B),
	.SFMCS_B(sfmcs_b),
	.SFMOUT(SFMSI),
	.TDOSFM(sfmtdo),
	.TRGDLY0(trgdly0),
	.FEBDLYAE(FEBDLYAE),
	.FEBDLYCLK(FEBDLYCLK),
	.FEBDLYIN(FEBDLYIN),
	.FEBLOADDLY(LOADDLY_OUT),
	.ENCODE_FM(encode_fm),
	.MTCH_3BX_FM(mtch_3bx_fm),
	.LAT_12_5US_FM(lat_12_5us_fm),
	.CLCT_ADJ_FM(clct_adj_fm),
	.USE_CLCT_FM(use_clct_fm),
	.DCFEB_IN_USE_FM(dcfeb_in_use_fm),
	.OPT_COP_ADJ_FM(opt_cop_adj_fm),
	.XL1AOUT(xl1a2cal),
	.CABLEDLY(cabledly),
	.CRATEID(crateid),
	.L1FDLYOUT(l1fndlym),
	.KILLINPUT(killinput),
	.SFMDIAG(sfmdiag),
	.SFMDOUT(statsfm)
);


//
// JTAGCOM -- JTAG Communications to/from VME FPGA
//

assign status = {FIFOAE[7:1],FIFOHF[7:1],FIFOF[7:1],ff_or_b[7:1],cfebdaverr[5:1],l1abufcnt[7:0],caltrgsel,pedestal,sfmwp_b,gtrgfifoerr,jtrgen[2:0]};

assign PREL1RLS_B = ~prel1rls;
assign INJ_PULSE  = inject;
assign EXT_PULSE  = pulse;
assign FFMRST_B   = ~(fifomrst | le_fpgaready);
assign FFPRST_B   = ~rst;
assign ccbped     = ~CCBCAL[2] | ttcdcal[2];
assign ccbinjin   = ~CCBCAL[1] | ttcdcal[1];
assign ccbplsin   = ~CCBCAL[0] | ttcdcal[0];

always @(posedge clkcms)
begin
	ccbinj_1 <= ccbinjin;
	ccbinj   <= ccbinj_1;
	ccbpls_1 <= ccbplsin;
	ccbpls_2 <= ccbpls_1;
	ccbpls   <= (ccbpls_1 | ccbpls_2) & (plsinjen | ~(jtrgen[1] & caltrgsel));
end

jtagcom #(
	.TMR(TMR),
	.SIM(SIM)
)
jtagcom_i (
	// Inputs
	.CLKCMS(clkcms),
	.CLK80(clk80),
	.RST(fpgarst),
	.CCBPED(ccbped),
	.CCBINJ(ccbinj),
	.CCBPLS(ccbpls),
	.ENL1RLS(ENL1RLS),
	.PLSINJEN(plsinjen),
	.TDOSFM(sfmtdo),
	.REGXL1ADLY(xl1a2cal), // 1:0
	.TMDAV(tmdav), // 31:0
	.TMCOUNT(tmcount), // 31:0
	.STATSFM(statsfm), // 47:0
	.STATUS(status), // 47:0
	// Outputs 
	.JRST(jrst),
	.SFMTCK(sfmtck),
	.BTDI(sfmtdi),
	.SFMTEST(sfmtest),
	.TMDAVRST(tmdavrst),
	.JREADOUT(jreadout),
	.ENACFEB(enacfeb),
	.CAL_GTRG(calgtrg),
	.SCPSYNC(SCPSYN),
	.GLNKRST(fifomrst),
	.ENCODE_JT(encode_jt),
	.MTCH_3BX_JT(mtch_3bx_jt),
	.LAT_12_5US_JT(lat_12_5us_jt),
	.USE_CLCT_JT(use_clct_jt),
	.DCFEB_IN_USE_JT(dcfeb_in_use_jt),
	.CAL_MODE(cal_mode),
	.TRGSEL(caltrgsel),
	.INJECT(inject),
	.PULSE(pulse),
	.PREL1RLS(prel1rls),
	.PEDESTAL(pedestal),
	.LCT_RQST(LCT_RQST_OUT),
	
	.TESTSTAT_MON(teststat_mon), // 15:0
	.MONOUT(monjtag), // 9:1
	.SERFM(serfm), //10:0
	.JTRGEN(jtrgen), // 3:0
	.CABLEDLY(cbldset), // 7:0
	.XL1ADLY(xl1a2sfm), // 1:0
	.CLCT_ADJ_JT(clct_adj_jt), // 3:0
	.OPT_COP_ADJ_JT(opt_cop_adj_jt), // 2:0
	.FEBCLKDLY(febclkdly), // 4:0
	.CRATEID(crateidset), // 6:0
	.L1FNDLY(l1fndly), // 3:0
	.SETKILLIN(setkillin), // 2:0
	.LOADTIME(davdly), // 25:0
	.JOEF(joef), // 7:0
	.CAL_CFEB(callct) // 5:0
);


//
// CCBCODE -- Communications to/from CCB
//

ccbcode #(
	.TMR(TMR)
)
ccbcode_i (
	// Inputs
	.CLKCMS(clkcms),
	.CLKENAIN(CLKENAIN),
	.L1ARSTIN(L1ARSTIN),
	.BXRSTIN(BXRSTIN),
	.BX0IN(BX0IN),
	.CMDSTRB(CCBCMDSTRB),
	.DATASTRB(CCBDATASTRB),
	.CCBCMD(CCBCMD),
	.CCBDATA(CCBDATA),
	// Outputs 
	.CLKENA(clkena),
	.BC0(bc0),
	.BX0(bx0),
	.BXRST(bxrst),
	.L1ARST(l1arst),
	.L1ASRST(L1ASRST),
	.TTCCAL(ttcdcal)
);

//
// Control -- Data Flow Control
//


control #(
	.TMR(TMR)
)
control_i (
	// Inputs
	.CLKCMS(clkcms),
	.CLKDDU(clkddu),
	.RST(rst),
	.L1ARST(l1arst),
	.FIFOMRST(fifomrst),
	.GEMPTY_B(gempty_b),
	.GIGAEN(giga_en),
	.RDFFNXT(rd_ff_nxt),
	.DAVENBL(davenbl),     //  5:1
	.DAQMBID(daqmbid),     // 11:0
	.CFEBBX(cfebbx),       //  3:0
	.BXN(gbxn),            // 11:0
	.DATAIN(fifo_d),        // 17:0
	.DAVACT(davact),       // 16:0
	.FFOR_B(ff_or_b),       //  7:1
	.JOEF(joef),           //  7:0
	.KILLINPUT(killinput), //  2:0
	.STATUS(status),       // 47:0
	// Outputs 
	.DAV(gpush),
	.POPBRAM(pop),
	.OEOVLP(oeovlp),
	.RENFIFO_B(renff_b),   //  7:1
	.OEFIFO_B(oeff_b),     //  7:1
	.DOUT(dout)           // 15:0
);

assign monitor[1] = gfpush;
assign auxout = {l1acfeb,bxrst,pop,davmon[0],gempty_b,rst,gfpush,caltrgsel,cal_mode};
assign diagcount = {caltrgsel,cal_mode,calgtrg,ccbinj,ccbinjin,plsinjen,monjtag[9:6],lct[0],jtrgen[1],jreadout,clkcms,davmon[0],gfpush};
assign gendiag   = {8'h00,outen,mirrclk,trgdly0,sfmdiag[4:0]};

//
// FRONTMON -- Output to Front Panel Connector Utility Board
//


frontmon #(
	.TMR(TMR)
)
frontmon_i (
	// Inputs
	.INJECT(inject),
	.PULSE(pulse),
	.OEOVLP(oeovlp),
	.RENFFMON_B(renff_b),    //  7:1
	.OEFFMON_B(oeff_b),      //  7:1
	.FIFOEMPT_B(status[26:20]), //  7:1
	.FIFOFULL_B(status[33:27]), //  7:1
	.FIFOHALF_B(status[40:34]), //  7:1
	.FIFOPAE_B(status[47:41]),  //  7:1
	.MONITOR(monitor),          //  7:1
	.MODECODE(FPMODE),          //  4:1
	.AUXOUT(auxout),            //  9:1
	.TESTSTAT_MON(teststat_mon),// 15:0
	.LCT(dly_aff),              //  5:0
	.MONOUT(monjtag),           //  9:1
	.DIAGIN(diagcount),         // 16:1
	.GENDIAG(gendiag),          // 15:0
	.GTRGDIAG(gtrgdiag),        // 15:0
	.MULTIN(multin),            //  8:1
	// Outputs 
	.OUTPUTENL_B(outputenl_b),
	.OUTPUTENH_B(outputenh_b),
	.MULTOUT(multout),          // 16:1
	.EXTIN(fromconx)            //  8:1
);


endmodule
