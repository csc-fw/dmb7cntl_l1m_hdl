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
module trig_dav_sim #(
	parameter TMR = 0
)
(
	// clocks
	input clkcms,
	input clk80,
	input fpgaready,
	// trigger
	input [5:0] RAWLCT,
	input L1ACC,
	input ALCTDAV,
	input TMBDAV,
	input [5:1] FEBDAV,
	input [5:1] MOLAP,
	input [2:0] CCBCAL,
	output SCPSYN,
	output reg [5:1] L1M_LCT,
	output reg L1A_CFEB,
	output INJ_PULSE,
	output EXT_PULSE,
	//
	// CCB
	input [5:0] CCBCMD,
	input CCBCMDSTRB,
	input [7:0] CCBDATA,
	input CCBDATASTRB,
	input BX0IN,
	input BXRSTIN,
	input L1ARSTIN,
	input RESETIN,
	input CLKENAIN,
	output L1ASRST,
	output PREL1RLS_B,
	output reg FEB_GRST,
	output reg CTRLREADY
);


wire rst;
reg  rst_1;
wire le_rst;
wire febrst;
reg  rst_plsinj;


reg  fpgaready_1;
reg  fpgaready_2;
wire le_fpgaready;
reg  fpgarst;
wire clr_fpgarst;
wire [3:0] fpgarst_cnt;
wire dv128clk;

reg  ce_crdy_cnt;
wire clr_crdy_cnt;
wire [15:0] crdy_cnt;

wire calgtrg;
reg  cal_mode;
wire caltrgsel;
wire enacfeb;
wire dcfeb_in_use_fm;
wire [2:0] opt_cop_adj_fm;
wire [5:0] callct;
wire [3:0] l1fndlym;
wire [5:0] l1latency;
wire [4:0] gpushdly;
wire [7:0] cabledly;
wire [1:0] xl1a2cal;
wire [2:0] killinput;

wire [3:0] jtrgen;
wire [4:0] tmbdavdly;
wire [4:0] alctdavdly;
wire [4:0] febdavdly;
wire [4:0] injdly;
wire [4:0] extdly;
wire [4:0] calgdly;
wire [3:0] callctdly;

wire l1acfeb;
wire gfpush;
wire errorlct;
wire [5:1] l1a_match;
wire [5:0] ostrip;
wire [5:0] lct;

reg mirrclk;
reg rstmirr;
reg  trgdly0;
wire outen;
wire clr0;
reg  pwr_on_hold_off;
wire release_poh;
wire [7:0] pwr_on_cnt;

wire [31:0] tmcount;
wire [7:0] lct2l1a;
wire [7:0] cdavtime;
wire [7:0] tmbdavtime;
wire [2:0] davmon;
reg jreadout;
wire dpush;
wire [4:0] cdavscope;
wire [4:0] tmbdavscope;
wire [4:0] affscope;

wire clkena;
wire tmdavrst;
wire pop;
wire bc0;
wire bx0;
wire bxrst;
wire l1arst;
wire [5:1] davenbl;
wire [31:0] tmdav;
wire [3:0] cfebbx;
wire [11:0] gbxn;

wire gtrgfifoerr;
wire gempty_b;
wire [7:1] monitor;
wire [16:0] davact;
wire [15:0] gtrgdiag;


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

reg jrst;
wire inject;
wire pulse;
wire prel1rls;
wire [2:0] ttcdcal;


initial
begin
	jreadout = 0;
	fpgarst = 0;
	jrst = 0;
	trgdly0 = 1'b0;
end

assign caltrgsel         = 1'b0;
assign dcfeb_in_use_fm   = 1'b1;
assign opt_cop_adj_fm    = 3'b000;
assign callct            = 6'h00;
assign jtrgen            = 4'h0;
assign l1fndlym          = 4'h8;
assign l1latency         = 6'h18;
assign gpushdly          = 5'h1E;
assign cabledly          = 8'h00;
assign xl1a2cal          = 2'b01;
assign killinput         = 3'b000;

assign tmbdavdly         = 5'h1C;
assign alctdavdly        = 5'h00;
assign febdavdly         = 5'h16;
assign injdly            = 5'h00;
assign extdly            = 5'h00;
assign calgdly           = 5'h15;
assign callctdly         = 4'h8;

assign rst  = (RESETIN | jrst | fpgarst | L1ASRST);
assign tmdavrst = rst;
assign pop = 0;

assign lct2l1a      = tmcount[7:0];
assign cdavtime     = tmcount[15:8];
assign tmbdavtime   = tmcount[23:16];
assign cdavscope    = tmdav[4:0];
assign tmbdavscope  = tmdav[9:5];
assign affscope     = tmdav[24:20];


//
// CLKGEN2 clock sources 
//

assign dv128clk = clkcms;

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
assign febrst       = cabledly[0] ? rst_1 : rst;
assign le_fpgaready = fpgaready & ~fpgaready_2;
assign clr_fpgarst  = (fpgarst_cnt == 4'hF);
assign clr_crdy_cnt = (crdy_cnt == 4'hF);


(* IOB = "TRUE" *)
always @(posedge clkcms)
begin
	FEB_GRST <= febrst;
end

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
	.EAFEB(1'b0),
	.DCFEB_IN_USE(dcfeb_in_use_fm),
	.OPT_COP_ADJ(opt_cop_adj_fm),
	.CSTRIP(callct),
	.BSTRIP(RAWLCT),
	.L1FINEDELAY(l1fndlym),
	.L1LATNCY(l1latency),
	.GPUSHDLY(gpushdly),
	.CABLEDLY(cabledly),
	.XL1ADLY(xl1a2cal),
	.KILLINPUT(killinput),
	.JTRGEN(jtrgen),
	// Outputs 
	.L1ACFEB(l1acfeb),
	.GFPUSH(gfpush),
	.LCTERR(errorlct),
	.L1A_MATCH(l1a_match),
	.OSTRIP(ostrip),
	.BOSTRIP(lct)
);

assign outen = mirrclk ^ trgdly0;
assign clr0 = 1'b0;

(* IOB = "TRUE" *)
always @(posedge clk80 or posedge rst)
begin
	if(rst) begin
		L1M_LCT  <= 5'b00000;
		L1A_CFEB <= 1'b0;
	end
	else
		if(outen) begin
			L1M_LCT <= l1a_match;
			L1A_CFEB <= l1acfeb;
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

assign release_poh = (pwr_on_cnt == 8'hFF); //210ms holdoff.

always @(posedge clkcms or posedge clr0)
begin
	if(clr0)
		pwr_on_hold_off <= 1'b0;
	else
		pwr_on_hold_off <= !release_poh & (fpgarst | pwr_on_hold_off);
end

cbnce #(
	.Width(8),
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
	.TMR(TMR)
)
LCT_to_L1A_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(lct[0]),
	.STOP(gfpush),
	.TIME(tmcount[7:0])
);

// CFEB DAV to FIFO push timer
trg_timer #(
	.TMR(TMR)
)
CFEB_DAV_to_push_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(davmon[0]),
	.STOP(dpush),
	.TIME(tmcount[15:8])
);

// TMB DAV to FIFO push timer
trg_timer #(
	.TMR(TMR)
)
TMB_DAV_to_push_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(davmon[1]),
	.STOP(dpush),
	.TIME(tmcount[23:16])
);

// ALCT DAV to FIFO push timer
trg_timer #(
	.TMR(TMR)
)
ALCT_DAV_to_push_timer_i (
	.CLK(clkcms),
	.HOLDOFF(pwr_on_hold_off),
	.CLR(jreadout),
	.START(davmon[2]),
	.STOP(dpush),
	.TIME(tmcount[31:24])
);

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
	.STRIP(ostrip),
	.DAV(FEBDAV),
	.L1FINEDELAY(l1fndlym),
	.FEBDAVDLY(febdavdly),
	.TMBDAVDLY(tmbdavdly),
	.GPUSHDLY(gpushdly),
	.ALCTDAVDLY(alctdavdly),
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
// JTAGCOM -- JTAG Communications to/from VME FPGA
//


assign PREL1RLS_B = ~prel1rls;
assign INJ_PULSE  = inject;
assign EXT_PULSE  = pulse;
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
reg ccbcal_dly;
wire clr_ccbcal;
wire [7:0] calcnt;
assign clr_ccbcal   = fpgarst | ccbcal_dly;

always @(posedge clkcms)
begin
	ccbcal_dly      <= (calcnt == 8'hFF);
end

always @(posedge clkcms or posedge clr_ccbcal)
begin
	if(clr_ccbcal)
		cal_mode <= 1'b0;
	else
		if(ccbped || ccbinj || ccbpls)
			cal_mode <= 1'b1;
end

cbnce #(
	.Width(8),
	.TMR(TMR)
)
ccbcal_cntr_i (
	.CLK(clkcms),
	.RST(clr_ccbcal),
	.CE(cal_mode),
	.Q(calcnt)
);


//
// Calibration Trigger Control
//
calib_trig #(.TMR(TMR))
calib_trig_i(
	.CLKCMS(clkcms),
	.CLK80(clk80),
	.RST(rst),
	.FINJ(1'b0),
	.FPLS(1'b0),
	.FPED(1'b0),
	.CCBINJ(ccbinj),
	.CCBPLS(ccbpls),
	.PLSINJEN(plsinjen),
	.PRELCT(1'b0),
	.PREGTRG(1'b0),
	.RNDMGTRG(1'b0),
	.INJDLY(injdly),
	.EXTDLY(extdly),
	.CALLCTDLY(callctdly),
	.CALGDLY(calgdly),
	.XL1ADLY(xl1a2cal),
	
	.PEDESTAL(pedestal),
	.CAL_GTRG(calgtrg),
	.CALLCT_1(callct_1),
	.INJECT(inject),
	.PULSE(pulse),
	.SCPSYN(SCPSYN),
	.SYNCIP(scope),
	.LCTRQST(prelctrqst),
	.INJPLS(injplsmon)
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


assign monitor[1] = l1acfeb;



endmodule
