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
	reg [3:0] gadd;
	reg [8:0] t1add;
	reg [8:0] t2add;
//	reg [8:0] t3add;
	reg [8:0] t4add;
	reg [8:0] t5add;
	reg [8:0] t6add;
	reg [8:0] t7add;
	reg start;
	reg en_fifo;
//	reg[17:0] dmbf1data[511:0];
	reg[17:0] dmbf2data[511:0];
//	reg[17:0] dmbf3data[511:0];
	reg[17:0] dmbf4data[511:0];
	reg[17:0] dmbf5data[511:0];
	reg[17:0] tmbdata[63:0];
	reg[17:0] alctdata[63:0];

	// Instantiate the Unit Under Test (UUT)
	control #(
		.TMR(0),
		.STMO(9'd40)
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
//	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo1_evts.dat", dmbf1data, 0, 511);
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo2_evts.dat", dmbf2data, 0, 255);
//	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo3_evts.dat", dmbf3data, 0, 511);
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo4_evts.dat", dmbf4data, 0, 511);
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/fifo5_evts.dat", dmbf5data, 0, 511);
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/tmb_evts.dat", tmbdata, 0, 63);
	   $readmemh ("../../dmb7cntl_l1m_hdl/Source/Sim/alct_evts.dat", alctdata, 0, 63);
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
		gadd = 4'hf;
		en_fifo = 1'b0;
		start = 1'b0;
		//FFOR_B = 7'b0000101;

		// Wait 96 ns for global reset to finish
		#96;
        
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
		/*
		#7;
		#(60*PERIOD);
		#(43*PERIOD);
		FFOR_B = 7'b0000111;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000101;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000111;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000101;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000111;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000101;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000111;
		#(1*PERIOD/2);
		FFOR_B = 7'b0000101;
		#(1*PERIOD/2);
		*/
			

	end

always @(posedge CLKCMS) begin
	CFEBBX <= CFEBBX + 1;
	BXN    <= BXN + 1;
end

always @(posedge CLKCMS or posedge RST) begin
	if(RST)
		gadd <= 4'h0;
	else
		if(POPBRAM)
			gadd <= gadd + 1;
end
always @(posedge CLKCMS or posedge RST) begin
	if(RST)
		en_fifo <= 1'b0;
	else
		if(start)
			en_fifo <= 1'b1;
end

assign GEMPTY_B = en_fifo && (gadd != 4'ha);

//assign davs = {alct_dav_scope[1],lct_5bx_or,cfeb_md_davs,tmb_dav_scope[1]};
//assign lct_5bx_or = {|{lct5_m,lct5_p1}, |{lct4_m,lct4_p1}, |{lct3_m,lct3_p1}, |{lct2_m,lct2_p1}, |{lct1_m,lct1_p1}};
//assign {lct5_p1,lct4_p1,lct3_p1,lct2_p1,lct1_p1,lct0_p1} = PSH_AFF;
//		cfeb_md_davs <= {dly_cfeb_mov,dly_cfeb_dav};

// DAVACT = {ALCT_DAV, (5BX OR of AFF)[5:1], multi-overlap_events[5:1], CFEB_DAVs[5:1], TMB_DAV}
always @*
begin
	case (gadd)
		4'h0: DAVACT = 17'h15015; //17'b1_0101_0000_0001_0101
		4'h1: DAVACT = 17'h15015; //17'b1_0101_0000_0001_0101
		4'h2: DAVACT = 17'h18020; //17'b1_1000_0000_0010_0000
		4'h3: DAVACT = 17'h00000;
		4'h4: DAVACT = 17'h08021; //17'b0_1000_0000_0010_0001
		4'h5: DAVACT = 17'h00000;
		4'h6: DAVACT = 17'h04010; //17'b0_0100_0000_0001_0000 
		4'h7: DAVACT = 17'h00000; 
		4'h8: DAVACT = 17'h08020; //17'b0_1000_0000_0010_0000
		4'h9: DAVACT = 17'h00000;
		4'ha: DAVACT = 17'h00000;
		4'hb: DAVACT = 17'h00000;
		4'hc: DAVACT = 17'h00000;
		4'hd: DAVACT = 17'h00000;
		4'he: DAVACT = 17'h00000;
		4'hf: DAVACT = 17'h00000;
		default: DAVACT = 17'h00000;
	endcase
end

always @(negedge CLKDDU or posedge RST) begin
	if(RST) begin
		t1add <= 9'h00;
		t2add <= 9'h00;
//		t3add <= 9'h00;
		t4add <= 9'h00;
		t5add <= 9'h00;
		t6add <= 9'h00;
		t7add <= 9'h00;
	end
	else begin
		if(RENFIFO_B[1] == 1'b0) t1add <= t1add + 1;
		if(RENFIFO_B[2] == 1'b0 && !FFOR_B[2]) t2add <= t2add + 1;
//		if(RENFIFO_B[3] == 1'b0) t3add <= t3add + 1;
		if(RENFIFO_B[4] == 1'b0) t4add <= t4add + 1;
		if(RENFIFO_B[5] == 1'b0) t5add <= t5add + 1;
		if(RENFIFO_B[6] == 1'b0) t6add <= t6add + 1;
		if(RENFIFO_B[7] == 1'b0) t7add <= t7add + 1;
	end
end


always @*
begin
	casex(OEFIFO_B)
//      7'b1111110: DATAIN = dmbf1data[t1add];
      7'b1111101: DATAIN = FFOR_B[2] ? 18'hxxxxx : dmbf2data[t2add];
//      7'b1111011: DATAIN = dmbf3data[t3add];
      7'b1110111: DATAIN = dmbf4data[t4add];
      7'b1101111: DATAIN = dmbf5data[t5add];
      7'b1011111: DATAIN = tmbdata[t6add];
      7'b0111111: DATAIN = alctdata[t7add];
		default: DATAIN = 18'hzzzzz;
		// default: DATAIN = 18'h3bad3;
	endcase
end
//assign FFOR_B = {2'b11,~(|(dmbf5data[t5add])),~(|(dmbf4data[t4add])),~(|(dmbf3data[t3add])),~(|(dmbf2data[t2add])),~(|(dmbf1data[t1add]))};
//assign FFOR_B = {2'b11,~(|(dmbf5data[t5add])),~(|(dmbf4data[t4add])),3'b111};
assign FFOR_B = {(t7add >= 9'd48),(t6add >= 9'd48),(t5add >= 9'd348),(t4add >= 9'd348),1'b1,(t2add >= 9'd232),1'b1};
//assign FFOR_B = {2'b11,~(|(~dmbf5data[t5add])),~(|(~dmbf4data[t4add])),3'b111};

endmodule

