`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:49:46 11/09/2015 
// Design Name: 
// Module Name:    jtagcom 
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
//
// Function  Description
// ---------------------------------------
//   0     | No Op 
//   1     | JTAG System Reset
//   2     | Preset/Clear certain JTAG registers to their firmware defaults
//   3     | BUCKEYE Inject
//   4     | BUCKEYE Pulse
//   5     | Pedestal data taking
//   6     | Load Trigger Register
//   7     | Cycle Trigger Register Once
//   8     | Continuously Cycle Trigger Register
//   9     | Load CFEB selection Register
//  10     | DAQMB Status
//  11     | Trigger select in cal_mode
//  12     | FIFO manual read control
//  13     | DAV Delay Setting
//  14     | FIFO Master Reset and GLINK Reset
//  15     | Load DAQMB Crate ID
//  16     | Load CFEB Clock Delay
//  17     | Set Calibration timing (Calib Pulse Delay)
//  18     | Set Loop Back for Glink, toggling (obsolete - not connected to Glink)
//  19     | Load Random Trigger Frequency
//  20     | Toggle Random trigger start control
//  21     | Serial Flash Memory
//  22     | Serial Flash Memory
//  23     | Serial Flash Memory
//  24     | Serial Flash Memory
//  25     | Serial Flash Memory
//  26     | Serial Flash Memory
//  27     | Serial Flash Memory
//  28     | Load Cable Delay
//  29     | Serial Flash Memory
//  30     | Serial Flash Memory
//  31     | Serial Flash Memory
//  32     | Burst of 1000 (really 512+256+128) Random events (L1ACC)
//  33     | Load the LCT_request delay and control the LCT request signal
//  34     | To toggle the max BX_counter number, default to 923, toggle to 3563 (obsolete)
//  35     | Serial Flash Memory Test
//  36     | Delay Counter readout, similar to function 10, status monitor
//  37     | 
//  38     | DAV timing readout, "Scope"
//  39     | Enable All CFEB data
//  40     | Load Extra L1A latency adjustment for Calibration mode  (obsolete)
//  41     | L1A fine Delay (obsolete)
//  42     | Load (update) the xL1ALatency (work with Function 40) (obsolete)
//  43     | Load (update) the L1A Fine delay (work with Function 41) (obsolete)
//  44     | Set the Kill Input bits (obsolete -- done with instruction 16 instead)
//  45     | Load (update) the Kill Input (work with Function 44) (obsolete -- done with instruction 23 instead)
//  46     | Set DCFEB_IN_USE bit and OPT_COP_ADJ delay (1+3 bits)
//
////////////////////////////////////////////////////////////////////////////////////


module jtagcom #(
	parameter TMR = 0
)
(
	input CLKCMS,
	input CLK80,
	input RST,
	input CCBPED,
	input CCBINJ,
	input CCBPLS,
	input ENL1RLS,
	input PLSINJEN,
	input TDOSFM,
	input [1:0] REGXL1ADLY,
	input [31:0] TMDAV,
	input [31:0] TMCOUNT,
	input [34:0] STATSFM,
	input [47:0] STATUS,
	output JRST,
	output SFMTCK,
	output BTDI,
	output SFMTEST,
	output TMDAVRST,
	output JREADOUT,
	output reg ENACFEB,
	output CAL_GTRG,
	output SCPSYNC,
	output GLNKRST,
	output DCFEB_IN_USE_JT,
	output CAL_MODE,
	output reg TRGSEL,
	output INJECT,
	output PULSE,
	output PREL1RLS,
	output PEDESTAL,
	output LCT_RQST,
	output [15:0] TESTSTAT_MON,
	output [9:1] MONOUT,
	output [10:0] SERFM,
	output [3:0] JTRGEN,
	output [7:0] CABLEDLY,
	output [1:0] XL1ADLY,
	output [2:0] OPT_COP_ADJ_JT,
	output [4:0] FEBCLKDLY,
	output [6:0] CRATEID,
	output [3:0] L1FNDLY,
	output [2:0] SETKILLIN,
	output [25:0] LOADTIME,
	output reg [7:0] JOEF,
	output reg [5:0] CAL_CFEB
);

wire jrstd;
wire sel1;
wire sel2;
wire treset;
wire capture;
wire shift;
wire update;
wire tdo1;
wire tdo2;
wire rw_drck1;
wire rw_drck2;
wire drck1;
wire drck2;

wire tdocald;
wire tdofeb;
wire tdocrid;
wire tdocbl;
wire tdostat;
wire tdodav;
wire tdocfeb;
wire tdotime;
wire tdotmdav;
wire tdofifo;
wire tdodcfeb;
wire tdolctrq;
wire tdotsel;
wire tdorate;

wire [47:0] instr;

reg instr11_1;
reg instr39_1;
reg instr36_updt_1;
reg instr38_updt_1;
wire le_instr11;
wire le_instr39;
reg ccbcal;
reg ccbcal_dly;
wire clr_ccbcal;

wire [2:0] renfifo;
wire [3:0] callctdly;
wire [4:0] calgdly;
wire [4:0] extdly;
wire [4:0] injdly;
wire [4:0] alctdav;
wire [5:0] l1alat;
wire [4:0] pushd;
wire [4:0] tmbdav;
wire [4:0] febdav;
wire [5:1] cfeb_reg;
wire [5:0] rqdly;
wire [15:6] dummy;

wire prelctrqst;
wire lctrqst_d1;
wire lctrqst_d2;
reg  lctrqst_out;

wire injplsmon;
wire scope;
wire callct_1;
wire prelct;
wire pregtrg;
wire rndmgtrg;
wire randomtrg;
wire [5:0] rndmlct;
wire [2:0] grtsel;
wire [2:0] l1rtsel;
wire [2:0] l2rtsel;
wire [2:0] l3rtsel;
wire [2:0] l4rtsel;
wire [2:0] l5rtsel;
wire [7:0] calcnt;

//wire capture1;
//wire capture2;
//wire treset1;
//wire treset2;
//wire shift1;
//wire shift2;
//wire btdi1;
//wire btdi2;
//wire update1;
//wire update2;
//
//assign capture = sel1 ? capture1 : capture2;
//assign treset  = sel1 ? treset1  : treset2;
//assign shift   = sel1 ? shift1   : shift2;
//assign update  = sel1 ? update1  : update2;
//assign BTDI    = sel1 ? btdi1    : btdi2;
//
//   BSCAN_VIRTEX6 #(
//      .DISABLE_JTAG("FALSE"), // This attribute is unsupported. Please leave it at default.
//      .JTAG_CHAIN(1)          // Value for USER command. Possible values: (1,2,3 or 4).
//   )
//   BSCAN_VIRTEX6_1 (
//      .CAPTURE(capture1), // 1-bit output: CAPTURE output from TAP controller
//      .DRCK(rw_drck1),       // 1-bit output: Data register output for USER functions
//      .RESET(treset1),     // 1-bit output: Reset output for TAP controller
//      .RUNTEST(), // 1-bit output: State output asserted when TAP controller is in Run Test Idle state.
//      .SEL(sel1),         // 1-bit output: USER active output
//      .SHIFT(shift1),     // 1-bit output: SHIFT output from TAP controller
//      .TCK(),         // 1-bit output: Scan Clock output. Fabric connection to TAP Clock pin.
//      .TDI(btdi1),         // 1-bit output: TDI output from TAP controller
//      .TMS(),         // 1-bit output: Test Mode Select input. Fabric connection to TAP.
//      .UPDATE(update1),   // 1-bit output: UPDATE output from TAP controller
//      .TDO(tdo1)          // 1-bit input: Data input for USER function
//   );
//
//   BSCAN_VIRTEX6 #(
//      .DISABLE_JTAG("FALSE"), // This attribute is unsupported. Please leave it at default.
//      .JTAG_CHAIN(2)          // Value for USER command. Possible values: (1,2,3 or 4).
//   )
//   BSCAN_VIRTEX6_2 (
//      .CAPTURE(capture2), // 1-bit output: CAPTURE output from TAP controller
//      .DRCK(rw_drck2),       // 1-bit output: Data register output for USER functions
//      .RESET(treset2),     // 1-bit output: Reset output for TAP controller
//      .RUNTEST(), // 1-bit output: State output asserted when TAP controller is in Run Test Idle state.
//      .SEL(sel2),         // 1-bit output: USER active output
//      .SHIFT(shift2),     // 1-bit output: SHIFT output from TAP controller
//      .TCK(),         // 1-bit output: Scan Clock output. Fabric connection to TAP Clock pin.
//      .TDI(btdi2),         // 1-bit output: TDI output from TAP controller
//      .TMS(),         // 1-bit output: Test Mode Select input. Fabric connection to TAP.
//      .UPDATE(update2),   // 1-bit output: UPDATE output from TAP controller
//      .TDO(tdo2)          // 1-bit input: Data input for USER function
//   );
BSCAN_VIRTEX2 BSCAN_VIRTEX2_inst (
	.CAPTURE(capture), // CAPTURE output from TAP controller
	.DRCK1(rw_drck1),     // Data register output for USER1 functions
	.DRCK2(rw_drck2),     // Data register output for USER2 functions
	.RESET(treset),     // Reset output from TAP controller
	.SEL1(sel1),       // USER1 active output
	.SEL2(sel2),       // USER2 active output
	.SHIFT(shift),     // SHIFT output from TAP controller
	.TDI(BTDI),         // TDI output from TAP controller
	.UPDATE(update),   // UPDATE output from TAP controller
	.TDO1(tdo1),       // Data input for USER1 function
	.TDO2(tdo2)        // Data input for USER2 function
);

//
// Clocks
//
BUFG BUFG_drclk_1 (.O(drck1),.I(rw_drck1));
BUFG BUFG_drclk_2 (.O(drck2),.I(rw_drck2));

assign SFMTCK = drck2;

//
// 
//
assign tdo2 = |{tdocald,tdofeb,tdocrid,tdocbl,tdostat,tdodav,tdocfeb,TDOSFM,tdotime,tdotmdav,tdofifo,tdodcfeb,tdolctrq,tdotsel,tdorate};

assign JRST         = instr[1];
assign jrstd        = instr[2];
assign GLNKRST      = instr[14];
assign SFMTEST      = instr[35];
assign CAL_MODE     = |{instr[8],instr[7],instr[4],instr[3],ccbcal,randomtrg};
assign SERFM        = instr[31:21];
assign TESTSTAT_MON ={5'b00000,STATSFM[34:24]};
assign LOADTIME     ={alctdav,l1alat,pushd,tmbdav,febdav};
assign MONOUT       ={scope,pregtrg,CAL_GTRG,injplsmon,1'b0,PULSE,CAL_GTRG,callct_1,instr[4]};

assign le_instr11   =  instr[11] & ~instr11_1;      //leading edge of instruction, 1 CLKCMS wide
assign le_instr39   =  instr[39] & ~instr39_1;      //leading edge of instruction, 1 CLKCMS wide
assign JREADOUT     = ~instr[36] &  instr36_updt_1; //Trailing edge of update, 1 CLKCMS wide
assign TMDAVRST     = ~instr[38] &  instr38_updt_1; //Trailing edge of update, 1 CLKCMS wide

assign clr_ccbcal   = RST | ccbcal_dly;

always @(posedge CLKCMS)
begin
	instr11_1       <= instr[11];
	instr39_1       <= instr[39];
	instr36_updt_1  <= instr[36] & sel2 & update;
	instr38_updt_1  <= instr[38] & sel2 & update;
	ccbcal_dly      <= (calcnt == 8'hFF);
end

always @(posedge CLKCMS or posedge clr_ccbcal)
begin
	if(clr_ccbcal)
		ccbcal <= 1'b0;
	else
		if(CCBPED || CCBINJ || CCBPLS)
			ccbcal <= 1'b1;
end

cbnce #(
	.Width(8),
	.TMR(TMR)
)
ccbcal_cntr_i (
	.CLK(CLKCMS),
	.RST(clr_ccbcal),
	.CE(ccbcal),
	.Q(calcnt)
);

always @(posedge CLKCMS or posedge RST)
begin
	if(RST)
		begin
			ENACFEB <= 1'b0;
			TRGSEL  <= 1'b1;
		end
	else
		begin
			if(le_instr39)
				ENACFEB <= ~ENACFEB;
			if(le_instr11)
				TRGSEL  <= ~TRGSEL;
		end
end


//
// Instruction Decode
//
instr_dcd
instr_dcd_i(
	.CLK(CLKCMS),
	.DRCK(drck1),
	.SEL(sel1),
	.TDI(BTDI),
	.UPDATE(update),
	.SHIFT(shift),
	.RST(RST),
	.CLR(1'b0),            // clear current instruction
	.F(instr),
	.TDO(tdo1)
);

	
//
// Load FIFO (Encoded read enable for FIFOs
//

user_wr_reg #(.width(3), .def_value(3'b000), .TMR(TMR))
load_fifo(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[12]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(RST),       // Reset default state
	.PO(renfifo),    // Parallel output
	.TDO(tdofifo)    // Serial Test Data Out
);

always @* begin
	case(renfifo)
		3'b000:  JOEF = 8'b00000001;
		3'b001:  JOEF = 8'b00000010;
		3'b010:  JOEF = 8'b00000100;
		3'b011:  JOEF = 8'b00001000;
		3'b100:  JOEF = 8'b00010000;
		3'b101:  JOEF = 8'b00100000;
		3'b110:  JOEF = 8'b01000000;
		3'b111:  JOEF = 8'b10000000;
		default: JOEF = 8'b00000000;
	endcase
end
	
//
// Set FEB delays
//

user_wr_reg #(.width(14), .def_value({4'd5,3'd0,2'd1,5'd31}), .TMR(TMR))
set_feb_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[16]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),     // Reset default state
	.PO({L1FNDLY,SETKILLIN,XL1ADLY,FEBCLKDLY}),     // Parallel output
	.TDO(tdofeb)     // Serial Test Data Out
);
	
//
// Set Crate ID
//

user_wr_reg #(.width(7), .def_value(7'd25), .TMR(TMR))
set_crtid_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[15]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),     // Reset default state
	.PO(CRATEID),    // Parallel output
	.TDO(tdocrid)    // Serial Test Data Out
);
	
//
// Set Cable delay
//

user_wr_reg #(.width(8), .def_value(8'd0), .TMR(TMR))
set_cbld_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[28]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),     // Reset default state
	.PO(CABLEDLY),   // Parallel output
	.TDO(tdocbl)     // Serial Test Data Out
);
	
//
// Set Calibration Delays
//
user_wr_reg #(.width(19), .def_value({5'd0,5'd0,5'd21,4'd8}), .TMR(TMR))
set_caldly_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[17]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),     // Reset default state
	.PO({injdly,extdly,calgdly,callctdly}),   // Parallel output
	.TDO(tdocald)    // Serial Test Data Out
);
	
//
// Stat_Mon Status capture and shift
//
user_cap_reg #(.width(88))
stat_mon_i(
	.DRCK(drck2),      // Data Reg Clock
	.FSH(1'b0),        // Shift Function
	.FCAP(instr[10]),  // Capture Function
	.SEL(sel2),        // User 2 mode active
	.TDI(BTDI),        // Serial Test Data In
	.SHIFT(shift),     // Shift state
	.CAPTURE(capture), // Capture state
	.RST(RST),         // Reset default state
	.BUS({5'b00000,STATSFM,STATUS}),      // Bus to capture
	.TDO(tdostat)      // Serial Test Data Out
);
	
//
// Load DAV delays, Push delays and L1A latency
//
user_wr_reg #(.width(26), .def_value({5'd0,6'd24,5'd30,5'd28,5'd6}), .TMR(TMR))
load_time_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[13]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),     // Reset default state
	.PO({alctdav,l1alat,pushd,tmbdav,febdav}),   // Parallel output
	.TDO(tdodav)     // Serial Test Data Out
);
	
//
// Set DCFEB 
//
user_wr_reg #(.width(4), .def_value({1'b0,3'd6}), .TMR(TMR))
set_dcfeb_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[46]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),     // Reset default state
	.PO({DCFEB_IN_USE_JT,OPT_COP_ADJ_JT}),   // Parallel output
	.TDO(tdodcfeb)   // Serial Test Data Out
);
	
//
// Load CFEB 
//
user_wr_reg #(.width(5), .def_value(5'h1F), .TMR(TMR))
load_cfeb_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[9]), // Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(RST),       // Reset default state
	.PO(cfeb_reg),   // Parallel output
	.TDO(tdocfeb)    // Serial Test Data Out
);

always @(posedge CLKCMS)
begin
	CAL_CFEB <= {cfeb_reg,|cfeb_reg} & (rndmlct | {6{callct_1}});
end

	
//
// LCT Request 
//
user_wr_reg #(.width(16), .def_value(16'h9520), .TMR(TMR))
lct_reqst_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[33]), // Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(jrstd),       // Reset default state
	.PO({dummy,rqdly}),   // Parallel output
	.TDO(tdolctrq)    // Serial Test Data Out
);

srl_16dx1 lctrqst_delay_1 (.CLK(CLKCMS), .CE(1'b1),.A(rqdly[3:0]),   .I(prelctrqst),.O(lctrqst_d1),.Q15());
srl_16dx1 lctrqst_delay_2 (.CLK(CLKCMS), .CE(1'b1),.A({4{rqdly[4]}}),.I(lctrqst_d1),.O(lctrqst_d2),.Q15());


(* IOB = "TRUE" *)
always @(posedge CLKCMS)
begin
	lctrqst_out <= lctrqst_d2;
end
assign LCT_RQST = rqdly[5] ? 1'bz : lctrqst_out;
PULLDOWN PD_lctrqst (.O(LCT_RQST));

	
//
// Trigger Select
//
user_wr_reg #(.width(4), .def_value(4'hF), .TMR(TMR))
trg_sel_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[37]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(RST),       // Reset default state
	.PO(JTRGEN),     // Parallel output
	.TDO(tdotsel)    // Serial Test Data Out
);

//
// Random Trigger Rate Selection registers
//
user_wr_reg #(.width(18), .def_value(18'h00000), .TMR(TMR))
rate_sel_i(
	.CLK(CLKCMS),    // CLKCMS for update register
	.DRCK(drck2),    // Data Reg Clock
	.FSEL(instr[19]),// Function select
	.SEL(sel2),      // User 2 mode active
	.TDI(BTDI),      // Serial Test Data In
	.SHIFT(shift),   // Shift state
	.UPDATE(update), // Update state
	.RST(RST),       // Reset default state
	.PO({grtsel,l5rtsel,l4rtsel,l3rtsel,l2rtsel,l1rtsel}),     // Parallel output
	.TDO(tdorate)    // Serial Test Data Out
);

	
//
// Time_Mon LCT to L1A and DAV to Push times
//
user_cap_reg #(.width(32))
time_mon_i(
	.DRCK(drck2),      // Data Reg Clock
	.FSH(1'b0),        // Shift Function
	.FCAP(instr[36]),  // Capture Function
	.SEL(sel2),        // User 2 mode active
	.TDI(BTDI),        // Serial Test Data In
	.SHIFT(shift),     // Shift state
	.CAPTURE(capture), // Capture state
	.RST(RST),         // Reset default state
	.BUS(TMCOUNT),     // Bus to capture
	.TDO(tdotime)      // Serial Test Data Out
);
	
//
// TMDV_Mon DAV scopes
//
user_cap_reg #(.width(32))
tmdv_mon_i(
	.DRCK(drck2),      // Data Reg Clock
	.FSH(1'b0),        // Shift Function
	.FCAP(instr[38]),  // Capture Function
	.SEL(sel2),        // User 2 mode active
	.TDI(BTDI),        // Serial Test Data In
	.SHIFT(shift),     // Shift state
	.CAPTURE(capture), // Capture state
	.RST(RST),         // Reset default state
	.BUS(TMDAV),       // Bus to capture
	.TDO(tdotmdav)     // Serial Test Data Out
);

//
// Trigger Control
//
trigcon #(.TMR(TMR))
trig_con_i(
	.CLK(CLKCMS),
	.DRCK(drck2),
	.DIN(BTDI),
	.SEL(sel2),
	.FLOAD(instr[6]),
	.FCYC(instr[7]),
	.FCYCM(instr[8]),
	.SHIFT(shift),
	.RST(RST),
	.PLSINJEN(PLSINJEN),
	.CCBPED(CCBPED),
	.LCTOUT(prelct),
	.GTRGOUT(pregtrg)
);

//
// Calibration Trigger Control
//
calib_trig #(.TMR(TMR))
calib_trig_i(
	.CLKCMS(CLKCMS),
	.CLK80(CLK80),
	.RST(RST),
	.FINJ(instr[3]),
	.FPLS(instr[4]),
	.FPED(instr[5]),
	.CCBINJ(CCBINJ),
	.CCBPLS(CCBPLS),
	.PLSINJEN(PLSINJEN),
	.PRELCT(prelct),
	.PREGTRG(pregtrg),
	.RNDMGTRG(rndmgtrg),
	.INJDLY(injdly),
	.EXTDLY(extdly),
	.CALLCTDLY(callctdly),
	.CALGDLY(calgdly),
	.XL1ADLY(REGXL1ADLY),
	
	.PEDESTAL(PEDESTAL),
	.CAL_GTRG(CAL_GTRG),
	.CALLCT_1(callct_1),
	.INJECT(INJECT),
	.PULSE(PULSE),
	.SCPSYN(SCPSYNC),
	.SYNCIP(scope),
	.LCTRQST(prelctrqst),
	.INJPLS(injplsmon)
);

//
// Random Triggers
//
random_trig  #(.TMR(TMR))
random_trig_i(
	.CLK(CLKCMS),
	.RST(RST),
	.FTSTART(instr[20]),
	.FBURST(instr[32]),
	.ENL1RLS(ENL1RLS),
	.GTRGSEL(grtsel),
	.LCT1SEL(l1rtsel),
	.LCT2SEL(l2rtsel),
	.LCT3SEL(l3rtsel),
	.LCT4SEL(l4rtsel),
	.LCT5SEL(l5rtsel),
	
	.GTRGOUT(rndmgtrg),
	.SELRAN(randomtrg),
	.PREL1RLS(PREL1RLS),
	.LCTOUT(rndmlct)
);

endmodule
