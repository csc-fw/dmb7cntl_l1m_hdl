`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:13:40 12/11/2015
// Design Name:   serfmem
// Module Name:   C:/Users/bylsma/Projects/DMB/Firmware/dmb7cntl_l1a_match_hdl/Source/Sim/serfmem_tf.v
// Project Name:  dmb7cntl_l1a_match_hdl
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: serfmem
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module serfmem_tf;

	// Inputs
	reg CLKCMS;
	wire RAW_CLKCMS;
	reg RST;
	reg DCFEB_IN_USE_JT;
	reg TCKSFM;
	reg TDISFM;
	reg TESTSFMIN;
	reg SFMIN;
	reg [2:0] OPT_COP_ADJ_JT;
	reg [1:0] XL1AIN;
	reg [10:0] SERFM;
	reg [7:0] CBLDSET;
	reg [4:0] FEBCLKDLYIN;
	reg [6:0] CRTIDIN;
	reg [3:0] L1FDLYIN;
	reg [2:0] SETKILLIN;

	// Outputs
	wire SFMSCK;
	wire SFMWP_B;
	wire SFMRST_B;
	wire SFMCS_B;
	wire SFMOUT;
	wire TDOSFM;
	wire TRGDLY0;
	wire FEBDLYAE;
	wire FEBDLYCLK;
	wire FEBDLYIN;
	wire FEBLOADDLY;
	wire DCFEB_IN_USE_FM;
	wire [2:0] OPT_COP_ADJ_FM;
	wire [1:0] XL1AOUT;
	wire [7:0] CABLEDLY;
	wire [6:0] CRATEID;
	wire [3:0] L1FDLYOUT;
	wire [2:0] KILLINPUT;
	wire [34:0] SFMDOUT;

	// Instantiate the Unit Under Test (UUT)
	serfmem uut (
		.CLKCMS(CLKCMS), 
		.RAW_CLKCMS(RAW_CLKCMS), 
		.RST(RST), 
		.DCFEB_IN_USE_JT(DCFEB_IN_USE_JT), 
		.TCKSFM(TCKSFM), 
		.TDISFM(TDISFM), 
		.TESTSFMIN(TESTSFMIN), 
		.SFMIN(SFMIN), 
		.OPT_COP_ADJ_JT(OPT_COP_ADJ_JT), 
		.XL1AIN(XL1AIN), 
		.SERFM(SERFM), 
		.CBLDSET(CBLDSET), 
		.FEBCLKDLYIN(FEBCLKDLYIN), 
		.CRTIDIN(CRTIDIN), 
		.L1FDLYIN(L1FDLYIN), 
		.SETKILLIN(SETKILLIN), 
		.SFMSCK(SFMSCK), 
		.SFMWP_B(SFMWP_B), 
		.SFMRST_B(SFMRST_B), 
		.SFMCS_B(SFMCS_B), 
		.SFMOUT(SFMOUT), 
		.TDOSFM(TDOSFM), 
		.TRGDLY0(TRGDLY0), 
		.FEBDLYAE(FEBDLYAE), 
		.FEBDLYCLK(FEBDLYCLK), 
		.FEBDLYIN(FEBDLYIN), 
		.FEBLOADDLY(FEBLOADDLY), 
		.DCFEB_IN_USE_FM(DCFEB_IN_USE_FM), 
		.OPT_COP_ADJ_FM(OPT_COP_ADJ_FM), 
		.XL1AOUT(XL1AOUT), 
		.CABLEDLY(CABLEDLY), 
		.CRATEID(CRATEID), 
		.L1FDLYOUT(L1FDLYOUT), 
		.KILLINPUT(KILLINPUT), 
		.SFMDOUT(SFMDOUT)
	);

   parameter PERIOD = 24;  // CMS clock period (40MHz)
	
	initial begin  // CMS clock 
		CLKCMS = 1;  // start high
      forever begin
         #(PERIOD/2) begin
				CLKCMS = ~CLKCMS;  //Toggle
			end
		end
	end
	
	assign RAW_CLKCMS = CLKCMS;
	initial begin
		// Initialize Inputs
		RST = 1'b0;
		TCKSFM = 1'b0;
		TDISFM = 1'b0;
		TESTSFMIN = 1'b0;
		SERFM = 11'h000; //JTAG command inputs
		SFMIN = 1'b1;
		DCFEB_IN_USE_JT = 1'b1;
		OPT_COP_ADJ_JT = 3'b000;
		XL1AIN = 2'b01;
		CBLDSET = 8'h0A;
		FEBCLKDLYIN = 5'h1F;
		CRTIDIN = 7'h01;
		L1FDLYIN = 4'h8;
		SETKILLIN = 3'b000;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		#(25*PERIOD);
		RST = 1'b1;
		#(5*PERIOD);
		RST = 1'b0;
		#(400*PERIOD);
		SERFM = 11'h001;
		#(25*PERIOD);
		SERFM = 11'h000;
		#(25*PERIOD);
		SERFM = 11'h002;
		#(25*PERIOD);
		SERFM = 11'h000;
		#(25*PERIOD);
		SERFM = 11'h004;
		#(25*PERIOD);
		SERFM = 11'h000;
		#(25*PERIOD);
		SERFM = 11'h008;
		#(25*PERIOD);
		SERFM = 11'h000;
		#(25*PERIOD);
	end
      
endmodule

