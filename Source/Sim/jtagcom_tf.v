`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:07:20 02/22/2016
// Design Name:   jtagcom
// Module Name:   C:/Users/bylsma/Projects/DMB/Firmware/dmb7cntl_l1a_match_hdl/Source/Sim/jtagcom_tf.v
// Project Name:  dmb7cntl_l1a_match_hdl
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: jtagcom
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module jtagcom_tf;

	// Inputs
	reg CLKCMS;
	reg CLK80;
	reg RST;
	reg CCBPED;
	reg CCBINJ;
	reg CCBPLS;
	reg ENL1RLS;
	reg PLSINJEN;
	reg TDOSFM;
	reg [31:0] TMDAV;
	reg [31:0] TMCOUNT;
	reg [34:0] STATSFM;
	reg [47:0] STATUS;
	
	reg L1ACC;
	reg [5:0] RAWLCT;
	wire [5:0] l1latency;

	// Outputs
	wire JRST;
	wire SFMTCK;
	wire BTDI;
	wire SFMTEST;
	wire TMDAVRST;
	wire JREADOUT;
	wire ENACFEB;
	wire CAL_GTRG;
	wire SCPSYNC;
	wire GLNKRST;
	wire DCFEB_IN_USE_JT;
	wire CAL_MODE;
	wire TRGSEL;
	wire INJECT;
	wire PULSE;
	wire PREL1RLS;
	wire PEDESTAL;
	wire LCT_RQST;
	wire [15:0] TESTSTAT_MON;
	wire [9:1] MONOUT;
	wire [10:0] SERFM;
	wire [3:0] JTRGEN;
	wire [7:0] CABLEDLY;
	wire [1:0] XL1ADLY;
	wire [2:0] OPT_COP_ADJ_JT;
	wire [4:0] FEBCLKDLY;
	wire [6:0] CRATEID;
	wire [3:0] L1FNDLY;
	wire [2:0] SETKILLIN;
	wire [25:0] LOADTIME;
	wire [7:0] JOEF;
	wire [5:0] CAL_CFEB;
	
	wire l1acfeb;
	wire gfpush;
	wire errorlct;
	wire [5:1] l1a_match;
	wire [5:0] ostrip;
	wire [5:0] dly_aff;
	wire [5:0] lct;

	// Instantiate the Unit Under Test (UUT)
	jtagcom  #(
	.TMR(0),
	.SIM(1)
) uut (
		.CLKCMS(CLKCMS), 
		.CLK80(CLK80), 
		.RST(RST), 
		.CCBPED(CCBPED), 
		.CCBINJ(CCBINJ), 
		.CCBPLS(CCBPLS), 
		.ENL1RLS(ENL1RLS), 
		.PLSINJEN(PLSINJEN), 
		.TDOSFM(TDOSFM), 
		.REGXL1ADLY(XL1ADLY), 
		.TMDAV(TMDAV), 
		.TMCOUNT(TMCOUNT), 
		.STATSFM(STATSFM), 
		.STATUS(STATUS), 
		.JRST(JRST), 
		.SFMTCK(SFMTCK), 
		.BTDI(BTDI), 
		.SFMTEST(SFMTEST), 
		.TMDAVRST(TMDAVRST), 
		.JREADOUT(JREADOUT), 
		.ENACFEB(ENACFEB), 
		.CAL_GTRG(CAL_GTRG), 
		.SCPSYNC(SCPSYNC), 
		.GLNKRST(GLNKRST), 
		.DCFEB_IN_USE_JT(DCFEB_IN_USE_JT), 
		.CAL_MODE(CAL_MODE), 
		.TRGSEL(TRGSEL), 
		.INJECT(INJECT), 
		.PULSE(PULSE), 
		.PREL1RLS(PREL1RLS), 
		.PEDESTAL(PEDESTAL), 
		.LCT_RQST(LCT_RQST), 
		.TESTSTAT_MON(TESTSTAT_MON), 
		.MONOUT(MONOUT), 
		.SERFM(SERFM), 
		.JTRGEN(JTRGEN), 
		.CABLEDLY(CABLEDLY), 
		.XL1ADLY(XL1ADLY), 
		.OPT_COP_ADJ_JT(OPT_COP_ADJ_JT), 
		.FEBCLKDLY(FEBCLKDLY), 
		.CRATEID(CRATEID), 
		.L1FNDLY(L1FNDLY), 
		.SETKILLIN(SETKILLIN), 
		.LOADTIME(LOADTIME), 
		.JOEF(JOEF), 
		.CAL_CFEB(CAL_CFEB)
	);


//
// TRGCNTRL Trigger Control
//

assign l1latency = LOADTIME[20:15];

trgcntrl 
trgcntrl_i (
	// Inputs 
	.CLK(CLKCMS),
	.CGTRG(CAL_GTRG),
	.BGTRG(L1ACC),
	.CMODE(CAL_MODE),
	.CALTRGSEL(TRGSEL),
	.EAFEB(ENACFEB),
	.DCFEB_IN_USE(DCFEB_IN_USE_JT),
	.OPT_COP_ADJ(OPT_COP_ADJ_JT),
	.CSTRIP(CAL_CFEB),
	.BSTRIP(RAWLCT),
	.L1FINEDELAY(L1FNDLY),
	.L1LATNCY(l1latency),
	.GPUSHDLY(LOADTIME[14:10]),
	.CABLEDLY(CABLEDLY),
	.XL1ADLY(XL1ADLY),
	.KILLINPUT(SETKILLIN),
	.JTRGEN(JTRGEN),
	// Outputs 
	.L1ACFEB(l1acfeb),
	.GFPUSH(gfpush),
	.LCTERR(errorlct),
	.L1A_MATCH(l1a_match),
	.OSTRIP(ostrip),
	.DLY_AFF(dly_aff),
	.BOSTRIP(lct)
);
	
   parameter PERIOD = 24;  // CMS clock period (40MHz)
	parameter JPERIOD = 100;
	parameter ir_width = 10;
	parameter max_width = 300;
	integer i;

//JTAG
	reg TMS,TDI,TCK;
	reg [7:0] jrst;
	reg [3:0] sir_hdr;
	reg [3:0] sdr_hdr;
	reg [2:0] trl;
	reg [ir_width-1:0] usr1;
	reg [ir_width-1:0] usr2;
	reg [ir_width-1:0] usr3;
	reg [ir_width-1:0] usr4;
	reg [ir_width-1:0] byps;
	reg [191:0] trgset;
	reg [17:0] trates;


reg rst_1;
reg rst_plsinj;
wire le_rst;
	
	initial begin  // CMS clock from QPLL 40 MHz
		CLKCMS = 1;  // start high
      forever begin
         #(PERIOD/2) begin
				CLKCMS = ~CLKCMS;  //Toggle
			end
		end
	end
	initial begin  //  80 MHz clock from QPLL
		CLK80 = 1;  // start high
      forever begin
         #(PERIOD/4) begin
				CLK80 = ~CLK80;  //Toggle
			end
		end
	end

	initial begin
		// Initialize Inputs
		RST = 0;
		CCBPED = 0;
		CCBINJ = 0;
		CCBPLS = 0;
		ENL1RLS = 0;
		TDOSFM = 0;
		TMDAV = 32'h00000000;
		TMCOUNT = 32'h00000000;
		STATSFM = 35'h000000000;
		STATUS = 48'h000000000000;
		trgset = 192'heaeaeaeaeaeaeae8eaeaeaeaeaeaeae8eaeaeaeaeaeaeae8;
		trates = 18'h36000;
		
		L1ACC = 1;
		RAWLCT = 6'h00;

		TMS = 1'b1;
		TDI = 1'b0;
		TCK = 1'b0;
      jrst = 8'b00111111;
      sir_hdr = 4'b0011;
      sdr_hdr = 4'b0010;
		trl = 3'b001;
		usr1 = 10'h3c2; // usr1 instruction
		usr2 = 10'h3c3; // usr2 instruction
		usr3 = 10'h3e2; // usr3 instruction
		usr4 = 10'h3e3; // usr4 instruction
		byps = 10'h3ff; // bypass instruction

		// Wait 100 ns for global reset to finish
		#101;
		RST = 1;
		#(5*PERIOD);
		RST = 0;
		#(5*PERIOD);
		JTAG_reset;
		Set_Func(8'h02);           // reset default values in JTAG registers
		#(5*PERIOD);
		Set_Func(8'h11);           // CAL_DELAY
		Set_User(usr2);            // User 2 for User Reg access
		Shift_Data(19,{5'd15,5'd13,5'd11,4'd8});  // shift zeros {Inject_delay,Extpls_delay,Cal_L1A_delay,Cal_LCT_Delay}
		#(5*PERIOD);
		Set_Func(8'h00);           // NoOp
		Set_User(byps);            // bypass
		#(5*PERIOD);
//		Set_Func(8'h06);           // LOAD_TRIG
//		Set_User(usr2);            // User 2 for User Reg access
//		Shift_Data(192,trgset);     // shift data
//		#(5*PERIOD);
//		Set_Func(8'h09);           // LOAD_STR
//		Set_User(usr2);            // User 2 for User Reg access
//		Shift_Data(5,5'h1F);       // shift data
//		#(5*PERIOD);
//		Set_User(byps);            // bypass
//		#(25*PERIOD);
//		Set_Func(8'h07);           // CYCLE_TRIG
//		Set_User(byps);            // bypass
//		Set_User(usr2);            // User 2 for User Reg access
//		Set_Func(8'h00);           // NoOp
//		Set_User(byps);            // bypass
        
		Set_Func(8'd19);           // TRG_RATE
		Set_User(usr2);            // User 2 for User Reg access
		Shift_Data(18,trates);     // shift data
		#(5*PERIOD);
		Set_Func(8'h00);           // NoOp
		Set_User(byps);            // bypass
		#(5*PERIOD);
		Set_Func(8'd20);           // RTRG_TGL
		Set_User(usr2);            // User 2 for User Reg access
		#(5*PERIOD);
		Set_Func(8'h00);           // NoOp
		Set_User(byps);            // bypass
		#(200*PERIOD);
		Set_Func(8'd20);           // RTRG_TGL
		Set_User(usr2);            // User 2 for User Reg access
		#(5*PERIOD);
		Set_Func(8'h00);           // NoOp
		Set_User(byps);            // bypass
		#(50*PERIOD);
		Set_Func(8'd32);           // Burst_triggers
		Set_User(usr2);            // User 2 for User Reg access
		#(5*PERIOD);
		Set_Func(8'h00);           // NoOp
		Set_User(byps);            // bypass
		#(50*PERIOD);
		// Add stimulus here

	end


   // JTAG_SIM_VIRTEX6: JTAG Interface Simulation Model
   //                   Virtex-6
   // Xilinx HDL Language Template, version 12.4
   
   JTAG_SIM_VIRTEX6 #(
      .PART_NAME("LX130T") // Specify target V6 device.  Possible values are:
                          // "CX130T","CX195T","CX240T","CX75T","HX250T","HX255T","HX380T","HX45T","HX565T",
                          // "LX115T","LX130T","LX130TL","LX195T","LX195TL","LX240T","LX240TL","LX365T","LX365TL",
                          // "LX40T","LX550T","LX550TL","LX75T","LX760","SX315T","SX475T" 
   ) JTAG_SIM_VIRTEX6_inst (
      .TDO(TDO), // 1-bit JTAG data output
      .TCK(TCK), // 1-bit Clock input
      .TDI(TDI), // 1-bit JTAG data input
      .TMS(TMS)  // 1-bit JTAG command input
   );

always @(posedge CLKCMS)
begin
	rst_1       <= RST;
	rst_plsinj  <= le_rst;
end

assign le_rst   = RST & ~rst_1;

always @(posedge CLKCMS or posedge rst_plsinj) 
begin
	if(rst_plsinj)
		PLSINJEN <= 1'b0;
	else
		PLSINJEN <= ~PLSINJEN;
end
	
task JTAG_reset;
begin
	// JTAG reset
	TMS = 1'b1;
	TDI = 1'b0;
	for(i=0;i<8;i=i+1) begin
		TMS = jrst[i];
		TCK = 1'b0;
		#(JPERIOD/2) TCK = 1'b1;
		#(JPERIOD/2);
	end
end
endtask

task Set_Func;
input [7:0] func;
begin
	Set_User(usr1);       // User 1 for instruction decode
	Shift_Data(8,func);   // Shift function code
end
endtask


task Set_User;
input [ir_width-1:0] usr;
begin
	// go to sir
	TDI = 1'b0;
	for(i=0;i<4;i=i+1) begin
		TMS = sir_hdr[i];
		TCK = 1'b0;
		#(JPERIOD/2) TCK = 1'b1;
		#(JPERIOD/2);
	end
	// shift instruction
	TMS = 1'b0;
	for(i=0;i<ir_width;i=i+1) begin
		if(i==ir_width-1)TMS = 1'b1;
		TDI = usr[i];       // User 1, 2, 3, or 4 instruction
		TCK = 1'b0;
		#(JPERIOD/2) TCK = 1'b1;
		#(JPERIOD/2);
	end
	// go to rti
	TDI = 1'b0;
	for(i=0;i<3;i=i+1) begin
		TMS = trl[i];
		TCK = 1'b0;
		#(JPERIOD/2) TCK = 1'b1;
		#(JPERIOD/2);
	end
end
endtask


task Shift_Data;
input integer width;
input [max_width-1:0] d;
begin
		// go to sdr
		TDI = 1'b0;
		for(i=0;i<4;i=i+1) begin
		   TMS = sdr_hdr[i];
			TCK = 1'b0;
			#(JPERIOD/2) TCK = 1'b1;
			#(JPERIOD/2);
		end
		// shift function data 
		TMS = 1'b0;
		for(i=0;i<width;i=i+1) begin
		   if(i==(width-1))TMS = 1'b1;
			TDI = d[i];
			TCK = 1'b0;
			#(JPERIOD/2) TCK = 1'b1;
			#(JPERIOD/2);
		end
		// go to rti
		TDI = 1'b0;
		for(i=0;i<3;i=i+1) begin
		   TMS = trl[i];
			TCK = 1'b0;
			#(JPERIOD/2) TCK = 1'b1;
			#(JPERIOD/2);
		end
end

endtask

      
endmodule

