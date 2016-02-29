`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:59:27 11/06/2015 
// Design Name: 
// Module Name:    serfmem 
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
module serfmem #(
	parameter TMR = 0
)
(
	input CLKCMS,
	input RAW_CLKCMS,
	input RST,
	input DCFEB_IN_USE_JT,
	input TCKSFM,
	input TDISFM,
	input TESTSFMIN,
	input SFMIN,
	input [2:0] OPT_COP_ADJ_JT,
	input [1:0] XL1AIN,
	input [10:0] SERFM,
	input [7:0] CBLDSET,
	input [4:0] FEBCLKDLYIN,
	input [6:0] CRTIDIN,
	input [3:0] L1FDLYIN,
	input [2:0] SETKILLIN,
	output reg SFMSCK,
	output SFMWP_B,
	output SFMRST_B,
	output SFMCS_B,
	output reg SFMOUT,
	output TDOSFM,
	output TRGDLY0,
	output reg FEBDLYAE,
	output FEBDLYCLK,
	output FEBDLYIN,
	output FEBLOADDLY,
	output reg DCFEB_IN_USE_FM,
	output reg [2:0] OPT_COP_ADJ_FM,
	output reg [1:0] XL1AOUT,
	output reg [7:0] CABLEDLY,
	output reg [6:0] CRATEID,
	output reg [3:0] L1FDLYOUT,
	output reg [2:0] KILLINPUT,
	output [7:0] SFMDIAG,
	output [34:0] SFMDOUT
);

wire clkenain;
wire clkena;
//wire clksfm;
//reg  cksfm;
wire clka;
wire tclka;
wire preclk;
reg dv2clk;
//wire clka_c;
wire cken_a;
wire cken_a_c;
wire cken_sfm;
reg  sfmdata;
reg  sfmdata_mon;
reg rst_1;
reg rst1;
reg rst2;
reg [34:0] dout;
wire selshift;
wire shiftin;
wire shift34in;
reg [4:0] febclkdly;
reg [1:0] dummy;
reg readshft;
reg loopshft;
wire [7:0] paddr;
wire [7:0] raddr;

wire loadfinedly;
wire loadid;
wire loadfebdly;
wire program;
wire loadinx;
wire init;
wire regtrgdly;
wire loaddly;
wire loadwp;
wire sfmrst;

reg program_1;
reg loadwp_1;

reg  ready;
reg  ready_1;
reg  loadfinedly_1;
reg  loadid_1;
reg  loadfebdly_1;
reg  le_loadfinedly;
reg  le_loadid;
reg  le_loadfebdly;
reg  setid;
reg  setfdly;
reg  setfebdly;
reg  setfebdly_1;

reg clkprog;
reg [7:0] prgfebclk;
reg [2:0] prgcnt;
reg loaddly_1;
reg preprog;
reg delayprog; 
reg rstprog; 
wire clr_raddr;
wire clr_paddr;
reg raddr_done;
reg paddr_done;
reg rchipen;
reg rclken;
reg [3:0] rdlycnt;
reg pchipen;
wire chipen;

wire rd_hdr_vt;
wire prg_hdr_vt;

reg  tog_wp_b;
reg  testsfm_1;
reg  testsfm_2;
wire testsfm;
wire testsfmcs;

assign SFMDOUT  = {DCFEB_IN_USE_FM,OPT_COP_ADJ_FM,KILLINPUT,L1FDLYOUT,XL1AOUT,febclkdly,CRATEID,CABLEDLY,dummy[1:0]};
assign SFMCS_B  = ~(rchipen | chipen | testsfmcs);
assign SFMRST_B = ~sfmrst;
assign TDOSFM   = testsfm & SFMIN;
assign SFMWP_B  = tog_wp_b | TESTSFMIN;
assign SFMDIAG  = {3'b000,febclkdly};

assign testsfmcs = testsfm_1 & TESTSFMIN;
assign testsfm   = testsfm_2 & TESTSFMIN;

assign clkena   = rclken | paddr[6] | paddr[7];
assign clkenain = clkena | loadid | loadfinedly | loadfebdly;
assign clka     = clkena & dv2clk;
assign tclka    = testsfm & TCKSFM;
assign preclk   = clka | tclka;
assign cken_sfm = clkenain & dv2clk;
assign cken_a   = ~clka;
assign cken_a_c = ~clka | testsfm;


assign loadfinedly = SERFM[0];  //JTAG instruction 21 (0x15)
assign loadid      = SERFM[1];  //JTAG instruction 22 (0x16)
assign loadfebdly  = SERFM[2];  //JTAG instruction 23 (0x17)
assign program     = SERFM[3];  //JTAG instruction 24 (0x18)
assign loadinx     = SERFM[4];  //JTAG instruction 25 (0x19) reserved for future use
assign init        = SERFM[5];  //JTAG instruction 26 (0x1a) not used
assign regtrgdly   = SERFM[6];  //JTAG instruction 27 (0x1b) not used
assign loaddly     = SERFM[8];  //JTAG instruction 29 (0x1d)
assign loadwp      = SERFM[9];  //JTAG instruction 30 (0x1e)
assign sfmrst      = SERFM[10]; //JTAG instruction 31 (0x1f)

assign FEBDLYCLK   = ~clkprog;
assign FEBDLYIN    = prgfebclk[7];
assign FEBLOADDLY  = loaddly;
assign TRGDLY0     = !(((febclkdly >= 5'd2) && (febclkdly <= 5'd14)) || (febclkdly >= 5'd27));

assign selshift = readshft | paddr[7];
assign shiftin  = loopshft | (readshft & SFMIN);
//srl_nx1 #(.Depth(28)) sfm_in_srl_i (.CLK(clksfm), .CE(1'b1),.I(shiftin),.O(shift34in));
srl_nx1 #(.Depth(28)) sfm_in_srl_i (.CLK(CLKCMS), .CE(cken_a),.I(shiftin),.O(shift34in));
assign clr_raddr = rst1 | raddr_done;
assign clr_paddr = rst1 | paddr_done;

always @*
begin
	casex({testsfm,paddr[7:6],rclken,raddr[7:6]})
		6'b1xxxxx : sfmdata = TDISFM;
		6'b01xxxx : sfmdata = dout[0];
		6'b001xxx : sfmdata = prg_hdr_vt;
		6'b000100 : sfmdata = rd_hdr_vt;
		default   : sfmdata = 1'b0;
	endcase
end

//
// Clocks
//
//BUFG BUFG_clksfm_i (.O(clksfm),.I(cksfm));

always @(posedge CLKCMS)
begin
	if(!clkenain)
		dv2clk <= 1'b0;
	else
		dv2clk <= ~dv2clk;
end
//always @(posedge CLKCMS)
//begin
//	cksfm <= clkenain & dv2clk;
//end

(* IOB = "TREUE" *)
always @(posedge CLKCMS)
begin
	SFMSCK <= preclk;
end

//BUFGMUX SFMout_ck_i (.O(clka_c),.I0(clka),.I1(RAW_CLKCMS),.S(testsfm));

//always @(posedge clka_c)
//begin
//	sfmdata_mon <= sfmdata;
//end
//
//(* IOB = "TREUE" *)
//always @(posedge clka_c)
//begin
//	SFMOUT <= sfmdata;
//end

always @(posedge CLKCMS)
begin
	if(cken_a_c) sfmdata_mon <= sfmdata;
end

(* IOB = "TREUE" *)
always @(posedge CLKCMS)
begin
	if(cken_a_c) SFMOUT <= sfmdata;
end

//
//
//
always @(posedge CLKCMS)
begin
	readshft  <= raddr[7];
	loopshft  <= dout[0] & paddr[7];
	loaddly_1 <= loaddly;
	rst_1     <= RST;
	rst1      <= RST & !rst_1;
	rst2      <= rst1;
	ready     <= raddr_done;
	ready_1   <= ready;
	program_1 <= program;
	loadwp_1  <= loadwp;
end

always @(posedge CLKCMS or posedge rst1)
begin
	if(rst1)
		begin
			loadid_1       <= 1'b0;
			loadfinedly_1  <= 1'b0;
			loadfebdly_1   <= 1'b0;
			le_loadid      <= 1'b0;
			le_loadfinedly <= 1'b0;
			le_loadfebdly  <= 1'b0;
			setid          <= 1'b0;
			setfdly        <= 1'b0;
			setfebdly      <= 1'b0;
			setfebdly_1    <= 1'b0;
			raddr_done     <= 1'b0;
			paddr_done     <= 1'b0;
		end
	else
		begin
			loadid_1       <= loadid;
			loadfinedly_1  <= loadfinedly;
			loadfebdly_1   <= loadfebdly;
			le_loadid      <= loadid      & !loadid_1;
			le_loadfinedly <= loadfinedly & !loadfinedly_1;
			le_loadfebdly  <= loadfebdly  & !loadfebdly_1;
			setid          <= le_loadid;
			setfdly        <= le_loadfinedly;
			setfebdly      <= le_loadfebdly;
			setfebdly_1    <= setfebdly;
			raddr_done     <= (raddr == 8'hFF);
			paddr_done     <= (paddr == 8'hFF);
		end
end

//always @(posedge clksfm)
//begin
//	if(selshift)
//		dout <= {shift34in,dout[34:1]};
//	else 
//		begin
//			if(loadfebdly)
//				dout[34:17] <= {DCFEB_IN_USE_JT,OPT_COP_ADJ_JT,SETKILLIN,L1FDLYIN,XL1AIN,FEBCLKDLYIN};
//			if(loadid)
//				dout[16:10] <= CRTIDIN;
//			if(loadfinedly)
//				dout[9:0] <= {~CBLDSET,CBLDSET[7],1'b0};
//		end
//end
always @(posedge CLKCMS)
begin
	if(cken_sfm)
		if(selshift)
			dout <= {shift34in,dout[34:1]};
		else 
			begin
				if(loadfebdly)
					dout[34:17] <= {DCFEB_IN_USE_JT,OPT_COP_ADJ_JT,SETKILLIN,L1FDLYIN,XL1AIN,FEBCLKDLYIN};
				if(loadid)
					dout[16:10] <= CRTIDIN;
				if(loadfinedly)
					dout[9:0] <= {~CBLDSET,CBLDSET[7],1'b0};
			end
end

always @(posedge CLKCMS)
begin
	if(ready)
		begin
			DCFEB_IN_USE_FM <= dout[34];
			OPT_COP_ADJ_FM  <= dout[33:31];
			KILLINPUT       <= dout[30:28];
			L1FDLYOUT       <= dout[27:24];
			XL1AOUT         <= dout[23:22];
			febclkdly       <= dout[21:17];
			CRATEID         <= dout[16:10];
			CABLEDLY        <= ~dout[9:2];
			dummy[1:0]      <= dout[1:0];
		end
	else 
		begin
			if(setfebdly)
				begin
					DCFEB_IN_USE_FM <= dout[34];
					OPT_COP_ADJ_FM  <= dout[33:31];
					KILLINPUT       <= dout[30:28];
					L1FDLYOUT       <= dout[27:24];
					XL1AOUT         <= dout[23:22];
					febclkdly       <= dout[21:17];
				end
			if(setid)
				CRATEID         <= dout[16:10];
			if(setfdly)
				begin
					CABLEDLY        <= ~dout[9:2];
					dummy[1:0]      <= dout[1:0];
				end
		end
end

//
// Program CFEB clock delay chip on DMB
//
always @(posedge CLKCMS)
begin
	if(ready_1 || setfebdly_1)
		prgfebclk <= {1'b0,febclkdly,2'b00};
	else if(FEBDLYAE && !clkprog)
		prgfebclk <= {prgfebclk[6:0],prgfebclk[7]};
end
always @(posedge CLKCMS)
begin
	clkprog <= ~clkprog;
end
always @(posedge CLKCMS or posedge rstprog)
begin
	if(rstprog)
		begin
			preprog   <= 1'b0;
			delayprog <= 1'b0;
			FEBDLYAE  <= 1'b0;
			prgcnt    <= 3'b000;
			rstprog   <= 1'b0;
		end
	else
		if(!clkprog)
			begin
				if(ready_1 || (loaddly_1 && !loaddly)) preprog <= 1'b1;
				delayprog <= preprog;
				FEBDLYAE  <= delayprog;
				if(FEBDLYAE) prgcnt <= prgcnt + 1;
				rstprog   <= (prgcnt == 3'd7);
			end
end

//
// 
always @(posedge CLKCMS or posedge clr_raddr)
begin
	if(clr_raddr)
		begin
			rchipen <= 1'b0;
			rdlycnt <= 4'h0;
			rclken  <= 1'b0;
		end
	else
		begin
			if(rst2)	           rchipen <= 1'b1;
			if(rchipen)         rdlycnt <= rdlycnt + 1;
			if(rdlycnt == 4'hE) rclken  <= 1'b1;
		end
end

always @(posedge CLKCMS or posedge clr_paddr)
begin
	if(clr_paddr)
		pchipen <= 1'b0;
	else
		if(program && !program_1)
			pchipen <= 1'b1;
end


cbnce #(
	.Width(8),
	.TMR(TMR)
)
raddr_cntr_i (
	.CLK(CLKCMS),
	.RST(clr_raddr),
	.CE(rclken),
	.Q(raddr)
);

cbnce #(
	.Width(8),
	.TMR(TMR)
)
paddr_cntr_i (
	.CLK(CLKCMS),
	.RST(clr_paddr),
	.CE(pchipen),
	.Q(paddr)
);

generate
if(TMR==1) 
begin : serfmem_rom_hdrs_TMR

	(* syn_keep = "true" *) wire rd_hdr_a;
	(* syn_keep = "true" *) wire rd_hdr_b;
	(* syn_keep = "true" *) wire rd_hdr_c;
	(* syn_keep = "true" *) wire prg_hdr_a;
	(* syn_keep = "true" *) wire prg_hdr_b;
	(* syn_keep = "true" *) wire prg_hdr_c;

	
	ROM32X1 #(.INIT(32'hA050004A)) SFM_rd_a  (.O(rd_hdr_a), .A0(raddr[1]),.A1(raddr[2]),.A2(raddr[3]),.A3(raddr[4]),.A4(raddr[5]));
	ROM32X1 #(.INIT(32'hA050004A)) SFM_rd_b  (.O(rd_hdr_b), .A0(raddr[1]),.A1(raddr[2]),.A2(raddr[3]),.A3(raddr[4]),.A4(raddr[5]));
	ROM32X1 #(.INIT(32'hA050004A)) SFM_rd_c  (.O(rd_hdr_c), .A0(raddr[1]),.A1(raddr[2]),.A2(raddr[3]),.A3(raddr[4]),.A4(raddr[5]));
	vote rd_hdr_vt_i    (.A(rd_hdr_a),.B(rd_hdr_b),.C(rd_hdr_c),.V(rd_hdr_vt));
//	assign rd_hdr_vt = (rd_hdr_a & rd_hdr_b) | (rd_hdr_b & rd_hdr_c) | (rd_hdr_a & rd_hdr_c); // Majority logic
	
	ROM32X1 #(.INIT(32'hA0500041)) SFM_prg_a (.O(prg_hdr_a),.A0(paddr[1]),.A1(paddr[2]),.A2(paddr[3]),.A3(paddr[4]),.A4(paddr[5]));
	ROM32X1 #(.INIT(32'hA0500041)) SFM_prg_b (.O(prg_hdr_b),.A0(paddr[1]),.A1(paddr[2]),.A2(paddr[3]),.A3(paddr[4]),.A4(paddr[5]));
	ROM32X1 #(.INIT(32'hA0500041)) SFM_prg_c (.O(prg_hdr_c),.A0(paddr[1]),.A1(paddr[2]),.A2(paddr[3]),.A3(paddr[4]),.A4(paddr[5]));
	vote prg_hdr_vt_i   (.A(prg_hdr_a),.B(prg_hdr_b),.C(prg_hdr_c),.V(prg_hdr_vt));
//	assign prg_hdr_vt = (prg_hdr_a & prg_hdr_b) | (prg_hdr_b & prg_hdr_c) | (prg_hdr_a & prg_hdr_c); // Majority logic
	
end
else 
begin : serfmem_rom_hdrs_no_TMR
	
	ROM32X1 #(.INIT(32'hA050004A)) SFM_rd_a  (.O(rd_hdr_vt), .A0(raddr[1]),.A1(raddr[2]),.A2(raddr[3]),.A3(raddr[4]),.A4(raddr[5]));
	ROM32X1 #(.INIT(32'hA0500041)) SFM_prg_a (.O(prg_hdr_vt),.A0(paddr[1]),.A1(paddr[2]),.A2(paddr[3]),.A3(paddr[4]),.A4(paddr[5]));
end
endgenerate

srl_16dx1 cs_delay_i (.CLK(CLKCMS), .CE(1'b1),.A(4'hF),.I((rchipen | pchipen)),.O(chipen),.Q15()); // 16 clocks


always @(posedge CLKCMS or posedge RST)
begin
	if(RST)
		tog_wp_b <= 1'b0;
	else
		if(loadwp && !loadwp_1)
			tog_wp_b <= ~tog_wp_b;
end

always @(negedge TCKSFM or negedge TESTSFMIN)
begin
	if(!TESTSFMIN)
		begin
			testsfm_1 <= 1'b0;
			testsfm_2 <= 1'b0;
		end
	else
		begin
			testsfm_1 <= TESTSFMIN;
			testsfm_2 <= testsfm_1;
		end
end

endmodule
