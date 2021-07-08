`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:15:34 02/17/2016
// Design Name:   control
// Module Name:   C:/Users/bylsma/Projects/DMB/Firmware/ISE_14.7/dmb7cntl_l1a_match_hdl/control_tf.v
// Project Name:  dmb7cntl_l1a_match_hdl
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: control
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module control_tf;

	// Inputs
	reg CLKCMS;
	reg CLKDDU;
	reg RST;
	reg L1ARST;
	reg FIFOMRST;
	wire GEMPTY_B;
	reg GIGAEN;
	reg RDFFNXT;
	reg DCFEB_IN_USE;
	reg [5:1] DAVENBL;
	reg [11:0] DAQMBID;
	reg [3:0] CFEBBX;
	reg [11:0] BXN;
	reg [17:0] DATAIN;
	reg [16:0] DAVACT;
	wire [7:1] FFOR_B;
	reg [7:0] JOEF;
	reg [2:0] KILLINPUT;
	reg [47:0] STATUS;

	// Outputs
	wire DAV;
	wire POPBRAM;
	wire OEOVLP;
	wire [7:1] RENFIFO_B;
	wire [7:1] OEFIFO_B;
	wire [15:0] DOUT;
	
	// internal
	reg [2:0] gadd;
	reg [11:0] t4add;
	reg [11:0] t5add;
	reg start;
	reg[17:0] dmbf4data[809:0];
	reg[17:0] dmbf5data[809:0];

	// Instantiate the Unit Under Test (UUT)
	control #(
		.TMR(1)
	)
	uut (
		.CLKCMS(CLKCMS), 
		.CLKDDU(CLKDDU), 
		.RST(RST), 
		.L1ARST(L1ARST), 
		.FIFOMRST(FIFOMRST), 
		.GEMPTY_B(GEMPTY_B), 
		.GIGAEN(GIGAEN), 
		.RDFFNXT(RDFFNXT), 
		.DCFEB_IN_USE(DCFEB_IN_USE),
		.DAVENBL(DAVENBL), 
		.DAQMBID(DAQMBID), 
		.CFEBBX(CFEBBX), 
		.BXN(BXN), 
		.DATAIN(DATAIN), 
		.DAVACT(DAVACT), 
		.FFOR_B(FFOR_B), 
		.JOEF(JOEF), 
		.KILLINPUT(KILLINPUT), 
		.STATUS(STATUS), 
		.DAV(DAV), 
		.POPBRAM(POPBRAM), 
		.OEOVLP(OEOVLP), 
		.RENFIFO_B(RENFIFO_B), 
		.OEFIFO_B(OEFIFO_B), 
		.DOUT(DOUT)
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
	initial begin  // CMS clock 
		CLKDDU = 1;  // start high
      forever begin
         #(PERIOD/4) begin
				CLKDDU = ~CLKDDU;  //Toggle
			end
		end
	end
	
	initial begin
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo4_evt_214.dat", dmbf4data, 0, 809);
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo5_evt_214.dat", dmbf5data, 0, 809);
	end

	initial begin
		// Initialize Inputs
		RST = 0;
		L1ARST = 0;
		FIFOMRST = 0;
		GIGAEN = 1;
		RDFFNXT = 0;
		DCFEB_IN_USE = 1'b1;
		DAVENBL = 5'b11111;
		DAQMBID = 12'h36d;
		CFEBBX = 4'h0;
		BXN = 12'h000;
		DAVACT = 17'h00000;
		JOEF = 8'h00;
		KILLINPUT = 3'h0;
		STATUS = 48'h000000000000;
		gadd = 3'h7;
		start = 1'b0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		#(25*PERIOD);
		RST = 1'b1;
		#(5*PERIOD);
		RST = 1'b0;
		#(40*PERIOD);
		L1ARST = 1'b1;
		FIFOMRST = 1'b1;
		#(5*PERIOD);
		L1ARST = 1'b0;
		FIFOMRST = 1'b0;
		#(40*PERIOD);
		start = 1'b1;
		#(1*PERIOD);
		start = 1'b0;

	end

always @(posedge CLKCMS) begin
	CFEBBX <= CFEBBX + 1;
	BXN    <= BXN + 1;
end

always @(posedge CLKCMS or posedge RST) begin
	if(RST)
		gadd <= 3'h7;
	else
		if(POPBRAM || start)
			gadd <= gadd + 1;
end

assign GEMPTY_B = (gadd == 3'h0) || (gadd == 3'h1);

always @*
begin
	case (gadd)
		3'h0: DAVACT = 17'h00000;
		3'h1: DAVACT = 17'h00030;
		3'h2: DAVACT = 17'h00000;
		3'h3: DAVACT = 17'h00000;
		3'h4: DAVACT = 17'h00000;
		3'h5: DAVACT = 17'h00000;
		3'h6: DAVACT = 17'h00000;
		3'h7: DAVACT = 17'h00000;
		default: DAVACT = 17'h00000;
	endcase
end

always @(negedge CLKDDU or posedge RST) begin
	if(RST)
		t4add <= 12'h00;
	else
		if(RENFIFO_B[4] == 1'b0)
			t4add <= t4add + 1;
	if(RST)
		t5add <= 12'h00;
	else
		if(RENFIFO_B[5] == 1'b0)
			t5add <= t5add + 1;
end
always @*
begin
	casex(OEFIFO_B)
      7'bxxx0111: DATAIN = dmbf4data[t4add];
      7'bxx01111: DATAIN = dmbf5data[t5add];
		default: DATAIN = 18'h3bad3;
	endcase
end
assign FFOR_B = {2'b11,~(|(~dmbf5data[t5add])),~(|(~dmbf4data[t4add])),3'b111};

endmodule

