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
	reg [5:1] DAVENBL;
	reg [11:0] DAQMBID;
	reg [3:0] CFEBBX;
	reg [11:0] BXN;
	wire [17:0] DATAIN;
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
	wire [7:1] FEMP;
	wire [15:0] DOUT;
	
	// internal
	reg [2:0] gadd;
	reg [7:0] tadd;
	reg start;
	reg[17:0] dmbf6data[255:0];

	// Instantiate the Unit Under Test (UUT)
	control uut (
		.CLKCMS(CLKCMS), 
		.CLKDDU(CLKDDU), 
		.RST(RST), 
		.L1ARST(L1ARST), 
		.FIFOMRST(FIFOMRST), 
		.GEMPTY_B(GEMPTY_B), 
		.GIGAEN(GIGAEN), 
		.RDFFNXT(RDFFNXT), 
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
		.FEMP(FEMP), 
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
	   $readmemh ("dmb_fifo6_data", dmbf6data, 0, 255);
	end

	initial begin
		// Initialize Inputs
		RST = 0;
		L1ARST = 0;
		FIFOMRST = 0;
		GIGAEN = 1;
		RDFFNXT = 0;
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
		3'h0: DAVACT = 17'h00001;
		3'h1: DAVACT = 17'h00001;
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
		tadd <= 8'h00;
	else
		if(RENFIFO_B[6] == 1'b0)
			tadd <= tadd + 1;
end

assign DATAIN = dmbf6data[tadd];
assign FFOR_B = {1'b1,(DATAIN == 18'h00000),5'b11111};

endmodule

