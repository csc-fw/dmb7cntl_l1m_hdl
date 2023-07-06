`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:26:18 11/10/2015
// Design Name: 
// Module Name:    control 
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

module control #(
	parameter TMR = 0,
	parameter STMO = 9'd448
)
(
	input CLKCMS,
	input CLKDDU,
	input RST,
	input L1ARST,
	input FIFOMRST,
	input GEMPTY_B,
	input GIGAEN,
	input RDFFNXT,
	input DCFEB_IN_USE,
	input [5:1] DAVENBL,
	input [11:0] DAQMBID,
	input [3:0] CFEBBX,
	input [11:0] BXN,
	input [17:0] DATAIN,
	input [16:0] DAVACT,
	input [7:1] FFOR_B,
	input [7:0] JOEF,
	input [2:0] KILLINPUT,
	input [47:0] STATUS,
	output DAV,
	output POPBRAM,
	output OEOVLP,
	output reg [7:1] RENFIFO_B,
	output reg [7:1] OEFIFO_B,
	output [15:0] DOUT
);

//
// nets assigned to the voted outcome of replicated registers
//
wire rstcnt;
//wire data_hldoff;
wire ovlpend;
//wire [7:1] ooe, ooe_i;
wire [7:1] ooe_i, ooe_1, ooe_2;
wire [7:1] jref;
wire rstlast;
wire [15:0] dint;
wire oeall;
wire doeall;

wire clrcrc;
wire [7:1] prio_act;

//
// Module scoped nets using replicated registers
//
wire busy_ce;
wire startread;
wire [7:1] done;
wire pop_rst;
wire readovlp;
wire last;

//
// Nets assigned to voted nets but not replicated
//
wire tail_rst;
wire inprog;
wire ovlpwen;
wire crcen;
wire [3:0] ovlplast;
wire noend_error;


//
// Nets that cannot be replicated (assigned to inputs or non-replicated nets)
//
wire ovlpren;
wire [19:0] doutx;
wire popbram_rst;
wire head_d12;
wire fendaverr;
wire killalct;
wire killtmb;
wire [5:1] killcfeb;
wire [7:1] killdcd;
wire [7:1] ffhf;  // FIFO half full flags OR'd with kill
wire [7:1] ffmt;  // FIFO empty flags OR'd with kill
wire fcrst;
wire ff_re;
wire dodat;
wire data_ce;
wire flushing;


wire [8:0] ddcnt;
wire [23:0] l1cnt;
wire [1:0] fmt_ver;
reg  [15:0] da_in;
wire [23:0] regcrc;
reg  [7:1] fifordy_b;
reg  ovlpin_b;
reg  prefflast;
wire [12:0] qnoend;
wire preovlast;
wire [12:0] ovlpwa;
wire [12:0] ovlpra;
reg  [19:0] ovlpff_out;
(* ram_style = "block" *)
reg  [19:0] ovlpfifo [8191:0];


//
// Combinatorial logic for non-replicated nets
//

assign ovlpren     = readovlp & ~last;
assign doutx       = ovlpff_out;
assign popbram_rst = RST | POPBRAM;
assign head_d12    = |{DAVACT[16],DAVACT[5:0]};
assign fendaverr   = |(DAVENBL & (DAVACT[15:11] ^ (DAVACT[10:6] | DAVACT[5:1]))); // CFEB DAVs or Multi-Overlaps not matching Pre-Triggers
assign killalct = (KILLINPUT == 3'd1);
assign killtmb  = (KILLINPUT == 3'd2);
assign killcfeb = {(KILLINPUT == 3'd7),(KILLINPUT == 3'd6),(KILLINPUT == 3'd5),(KILLINPUT == 3'd4),(KILLINPUT == 3'd3)};
assign killdcd  = {killalct,killtmb,killcfeb};
assign ffhf     = killdcd | STATUS[40:34];
assign ffmt     = killdcd | STATUS[26:20];
assign fcrst    = RST | FIFOMRST;
assign fmt_ver  = DCFEB_IN_USE ? 2'd2 : 2'd1;

//
// Overlap FIFO memory
//
always @(posedge CLKDDU)
begin
	if (ovlpwen)
		ovlpfifo[ovlpwa] <= {ovlplast,dint};
	ovlpff_out <= ovlpfifo[ovlpra];
end

initial begin
	ovlpin_b = 1'b1;
	prefflast = 1'b0;
end		

  
generate
if(TMR==1) 
begin : control_last_TMR
	vote #(.Width(1)) vote_ovlast_1 (.A(doutx[18]), .B(doutx[17]), .C(doutx[19]), .V(preovlast));
//	assign preovlast = (doutx[17] & doutx[18]) | (doutx[18] & doutx[19]) | (doutx[17] & doutx[19]); // Majority logic
end
else 
begin : control_last_no_TMR
  assign preovlast = doutx[17];
end
endgenerate

//
// Data inputs
//
(* IOB = "TRUE" *)
always @(negedge CLKDDU) //Negative edge and IOB
begin
	fifordy_b <= FFOR_B;
	da_in     <= DATAIN[15:0];
end

(* IOB = "TRUE" *)
always @(negedge CLKDDU or posedge rstlast) //Negative edge and IOB
begin
	if(rstlast)
		begin
			prefflast <= 1'b0;
			ovlpin_b  <= 1'b1;
		end
	else
		if(doeall && |(prio_act & ~FFOR_B & ~RENFIFO_B))
			begin
				prefflast <= DATAIN[16];
				ovlpin_b  <= DATAIN[17];
			end
end

//
// FIFO read enable and ouput enables outputs
//
(* IOB = "TRUE" *)
always @(posedge CLKDDU or posedge pop_rst)
begin
	if(pop_rst)
		RENFIFO_B  <= 7'h7F;
	else
//		RENFIFO_B <= ~(jref | (ooe & ~{7{last}}));
		RENFIFO_B <= ~(jref | (prio_act & {7{ff_re}} & ~{7{last & flushing}}) | (ooe_2 & {7{dodat}} & ~{7{last}}));
end

genvar i;
generate
begin
	for(i=1;i<8;i=i+1) begin: idx1
		(* IOB = "TRUE" *)
		always @(negedge CLKDDU or posedge done[i]) // Negative edge
		begin
			if(done[i])
				OEFIFO_B[i]  <= 1'b1;
			else
//				OEFIFO_B[i] <= ~(JOEF[i] | ooe[i] | ooe_i[i]);
				OEFIFO_B[i] <= ~(JOEF[i] | ooe_1[i] | ooe_i[i]);
		end
	end
end
endgenerate


////////////////////////////////////////////////////////////////////////////
//
// Counters and CRC calculation
//
////////////////////////////////////////////////////////////////////////////

//
// start time out counter
//
cbnce #(
	.Width(9),
	.TMR(TMR)
)
strt_tmo_cntr_i (
	.CLK(CLKDDU),
	.RST(tail_rst),
	.CE(inprog),
	.Q(ddcnt)
);

//
// L1A counter (actually events read out counter)
//
cbnce #(
	.Width(24),
	.TMR(TMR)
)
l1a_cntr_i (
	.CLK(CLKDDU),
	.RST(RST | L1ARST),
	.CE(busy_ce),
	.Q(l1cnt)
);

//
// event timeout counter
//
cbnce #(
	.Width(13),
	.TMR(TMR)
)
evt_tmo_cntr_i (
	.CLK(CLKDDU),
	.RST(ovlpend | startread | rstcnt),
	.CE(oeall),
	.Q(qnoend)
);

//
// Overlap FIFO write address counter
//
cbnce #(
	.Width(13),
	.TMR(TMR)
)
ovlpwa_cntr_i (
	.CLK(CLKDDU),
	.RST(fcrst),
	.CE(ovlpwen),
	.Q(ovlpwa)
);

//
// Overlap FIFO read address counter
//
cbnce #(
	.Width(13),
	.TMR(TMR)
)
ovlpra_cntr_i (
	.CLK(CLKDDU),
	.RST(fcrst),
	.CE(ovlpren),
	.Q(ovlpra)
);

//
// CRC calculation
//
crc22 crc22_i(
	.CLK(CLKDDU),
	.CE(crcen),
	.CLR(clrcrc),
	.DIN(dint),
	.REGCRC(regcrc)
);


generate
if(TMR==1) 
begin : control_logic_TMR

	//
	// local scope registers
	//
	(* syn_preserve = "true" *)  reg  gdav_1_a;
	(* syn_preserve = "true" *)  reg  gdav_2_a;
	(* syn_preserve = "true" *)  reg  gdav_3_a;
	(* syn_preserve = "true" *)  reg  [7:1] oe_1_a;
	(* syn_preserve = "true" *)  reg  [7:1] datanoend_a;
	(* syn_preserve = "true" *)  reg  popbram_a;
	(* syn_preserve = "true" *)  reg  busy_a;
	(* syn_preserve = "true" *)  reg  busy_1_a;
	(* syn_preserve = "true" *)  reg  [8:1] oehdr_a;
	(* syn_preserve = "true" *)  reg  [8:1] tail_a;
	(* syn_preserve = "true" *)  reg  tail8_1_a;
	(* syn_preserve = "true" *)  reg  dav_a;
	(* syn_preserve = "true" *)  reg  rdyovlp_a;
	(* syn_preserve = "true" *)  reg  oeall_1_a;
	(* syn_preserve = "true" *)  reg  oedata_a;
	(* syn_preserve = "true" *)  reg  [7:1] dn_oe_a;
	(* syn_preserve = "true" *)  reg  [7:1] davnodata_a;
	(* syn_preserve = "true" *)  reg  pop_m2_a;
	(* syn_preserve = "true" *)  reg  pop_m1_a;
	(* syn_preserve = "true" *)  reg  pop_a;
	(* syn_preserve = "true" *)  reg  oehdtl_a;
	(* syn_preserve = "true" *)  reg  ht_crc_a;
	(* syn_preserve = "true" *)  reg  dodat_a;
	(* syn_preserve = "true" *)  reg  st_tail_a;
	(* syn_preserve = "true" *)  reg  pbram_a;
	(* syn_preserve = "true" *)  reg  [7:1] ffrfl_a; // raw FIFO full flags
	(* syn_preserve = "true" *)  reg  [7:1] rdy_a;
	(* syn_preserve = "true" *)  reg  [5:1] oe6_1_a;
	(* syn_preserve = "true" *)  reg  [5:1] ovrin_a;
	(* syn_preserve = "true" *)  reg  [5:1] ovr_a;
	(* syn_preserve = "true" *)  reg  [7:1] r_act_a;
	(* syn_preserve = "true" *)  reg  [5:1] rovr_1_a;
	(* syn_preserve = "true" *)  reg  disdav_a;
	(* syn_preserve = "true" *)  reg  rdffnxt_1_a;
	(* syn_preserve = "true" *)  reg  rdffnxt_2_a;
	(* syn_preserve = "true" *)  reg  rdffnxt_3_a;
	(* syn_preserve = "true" *)  reg  rdoneovlp_a;
	(* syn_preserve = "true" *)  reg  dint_ovlp_b_a;
	(* syn_preserve = "true" *)  reg  dtail7_a;
	(* syn_preserve = "true" *)  reg  dtail8_a;
	(* syn_preserve = "true" *)  reg  dtail78_a;
	(* syn_preserve = "true" *)  reg  dn_ovlp_a;
	(* syn_preserve = "true" *)  reg  ooeovlp_a;

	(* syn_preserve = "true" *)  reg  gdav_1_b;
	(* syn_preserve = "true" *)  reg  gdav_2_b;
	(* syn_preserve = "true" *)  reg  gdav_3_b;
	(* syn_preserve = "true" *)  reg  [7:1] oe_1_b;
	(* syn_preserve = "true" *)  reg  [7:1] datanoend_b;
	(* syn_preserve = "true" *)  reg  popbram_b;
	(* syn_preserve = "true" *)  reg  busy_b;
	(* syn_preserve = "true" *)  reg  busy_1_b;
	(* syn_preserve = "true" *)  reg  [8:1] oehdr_b;
	(* syn_preserve = "true" *)  reg  [8:1] tail_b;
	(* syn_preserve = "true" *)  reg  tail8_1_b;
	(* syn_preserve = "true" *)  reg  dav_b;
	(* syn_preserve = "true" *)  reg  rdyovlp_b;
	(* syn_preserve = "true" *)  reg  oeall_1_b;
	(* syn_preserve = "true" *)  reg  oedata_b;
	(* syn_preserve = "true" *)  reg  [7:1] dn_oe_b;
	(* syn_preserve = "true" *)  reg  [7:1] davnodata_b;
	(* syn_preserve = "true" *)  reg  pop_m2_b;
	(* syn_preserve = "true" *)  reg  pop_m1_b;
	(* syn_preserve = "true" *)  reg  pop_b;
	(* syn_preserve = "true" *)  reg  oehdtl_b;
	(* syn_preserve = "true" *)  reg  ht_crc_b;
	(* syn_preserve = "true" *)  reg  dodat_b;
	(* syn_preserve = "true" *)  reg  st_tail_b;
	(* syn_preserve = "true" *)  reg  pbram_b;
	(* syn_preserve = "true" *)  reg  [7:1] ffrfl_b; // raw FIFO full flags
	(* syn_preserve = "true" *)  reg  [7:1] rdy_b;
	(* syn_preserve = "true" *)  reg  [5:1] oe6_1_b;
	(* syn_preserve = "true" *)  reg  [5:1] ovrin_b;
	(* syn_preserve = "true" *)  reg  [5:1] ovr_b;
	(* syn_preserve = "true" *)  reg  [7:1] r_act_b;
	(* syn_preserve = "true" *)  reg  [5:1] rovr_1_b;
	(* syn_preserve = "true" *)  reg  disdav_b;
	(* syn_preserve = "true" *)  reg  rdffnxt_1_b;
	(* syn_preserve = "true" *)  reg  rdffnxt_2_b;
	(* syn_preserve = "true" *)  reg  rdffnxt_3_b;
	(* syn_preserve = "true" *)  reg  rdoneovlp_b;
	(* syn_preserve = "true" *)  reg  dint_ovlp_b_b;
	(* syn_preserve = "true" *)  reg  dtail7_b;
	(* syn_preserve = "true" *)  reg  dtail8_b;
	(* syn_preserve = "true" *)  reg  dtail78_b;
	(* syn_preserve = "true" *)  reg  dn_ovlp_b;
	(* syn_preserve = "true" *)  reg  ooeovlp_b;

	(* syn_preserve = "true" *)  reg  gdav_1_c;
	(* syn_preserve = "true" *)  reg  gdav_2_c;
	(* syn_preserve = "true" *)  reg  gdav_3_c;
	(* syn_preserve = "true" *)  reg  [7:1] oe_1_c;
	(* syn_preserve = "true" *)  reg  [7:1] datanoend_c;
	(* syn_preserve = "true" *)  reg  popbram_c;
	(* syn_preserve = "true" *)  reg  busy_c;
	(* syn_preserve = "true" *)  reg  busy_1_c;
	(* syn_preserve = "true" *)  reg  [8:1] oehdr_c;
	(* syn_preserve = "true" *)  reg  [8:1] tail_c;
	(* syn_preserve = "true" *)  reg  tail8_1_c;
	(* syn_preserve = "true" *)  reg  dav_c;
	(* syn_preserve = "true" *)  reg  rdyovlp_c;
	(* syn_preserve = "true" *)  reg  oeall_1_c;
	(* syn_preserve = "true" *)  reg  oedata_c;
	(* syn_preserve = "true" *)  reg  [7:1] dn_oe_c;
	(* syn_preserve = "true" *)  reg  [7:1] davnodata_c;
	(* syn_preserve = "true" *)  reg  pop_m2_c;
	(* syn_preserve = "true" *)  reg  pop_m1_c;
	(* syn_preserve = "true" *)  reg  pop_c;
	(* syn_preserve = "true" *)  reg  oehdtl_c;
	(* syn_preserve = "true" *)  reg  ht_crc_c;
	(* syn_preserve = "true" *)  reg  dodat_c;
	(* syn_preserve = "true" *)  reg  st_tail_c;
	(* syn_preserve = "true" *)  reg  pbram_c;
	(* syn_preserve = "true" *)  reg  [7:1] ffrfl_c; // raw FIFO full flags
	(* syn_preserve = "true" *)  reg  [7:1] rdy_c;
	(* syn_preserve = "true" *)  reg  [5:1] oe6_1_c;
	(* syn_preserve = "true" *)  reg  [5:1] ovrin_c;
	(* syn_preserve = "true" *)  reg  [5:1] ovr_c;
	(* syn_preserve = "true" *)  reg  [7:1] r_act_c;
	(* syn_preserve = "true" *)  reg  [5:1] rovr_1_c;
	(* syn_preserve = "true" *)  reg  disdav_c;
	(* syn_preserve = "true" *)  reg  rdffnxt_1_c;
	(* syn_preserve = "true" *)  reg  rdffnxt_2_c;
	(* syn_preserve = "true" *)  reg  rdffnxt_3_c;
	(* syn_preserve = "true" *)  reg  rdoneovlp_c;
	(* syn_preserve = "true" *)  reg  dint_ovlp_b_c;
	(* syn_preserve = "true" *)  reg  dtail7_c;
	(* syn_preserve = "true" *)  reg  dtail8_c;
	(* syn_preserve = "true" *)  reg  dtail78_c;
	(* syn_preserve = "true" *)  reg  dn_ovlp_c;
	(* syn_preserve = "true" *)  reg  ooeovlp_c;

	//
	// local scope registers
	//
	(* syn_keep = "true" *)  wire vt_gdav_1_a;
	(* syn_keep = "true" *)  wire vt_gdav_2_a;
	(* syn_keep = "true" *)  wire vt_gdav_3_a;
	(* syn_keep = "true" *)  wire [7:1] vt_oe_1_a;
	(* syn_keep = "true" *)  wire [7:1] vt_datanoend_a;
	(* syn_keep = "true" *)  wire vt_popbram_a;
	(* syn_keep = "true" *)  wire vt_busy_a;
	(* syn_keep = "true" *)  wire vt_busy_1_a;
	(* syn_keep = "true" *)  wire [8:1] vt_oehdr_a;
	(* syn_keep = "true" *)  wire [8:1] vt_tail_a;
	(* syn_keep = "true" *)  wire vt_tail8_1_a;
	(* syn_keep = "true" *)  wire vt_dav_a;
	(* syn_keep = "true" *)  wire vt_rdyovlp_a;
	(* syn_keep = "true" *)  wire vt_oeall_1_a;
	(* syn_keep = "true" *)  wire vt_oedata_a;
	(* syn_keep = "true" *)  wire [7:1] vt_dn_oe_a;
	(* syn_keep = "true" *)  wire [7:1] vt_davnodata_a;
	(* syn_keep = "true" *)  wire vt_pop_m2_a;
	(* syn_keep = "true" *)  wire vt_pop_m1_a;
	(* syn_keep = "true" *)  wire vt_pop_a;
	(* syn_keep = "true" *)  wire vt_oehdtl_a;
	(* syn_keep = "true" *)  wire vt_ht_crc_a;
	(* syn_keep = "true" *)  wire vt_dodat_a;
	(* syn_keep = "true" *)  wire vt_st_tail_a;
	(* syn_keep = "true" *)  wire vt_pbram_a;
	(* syn_keep = "true" *)  wire [7:1] vt_ffrfl_a; // raw FIFO full flags
	(* syn_keep = "true" *)  wire [7:1] vt_rdy_a;
	(* syn_keep = "true" *)  wire [5:1] vt_oe6_1_a;
	(* syn_keep = "true" *)  wire [5:1] vt_ovrin_a;
	(* syn_keep = "true" *)  wire [5:1] vt_ovr_a;
	(* syn_keep = "true" *)  wire [7:1] vt_r_act_a;
	(* syn_keep = "true" *)  wire [5:1] vt_rovr_1_a;
	(* syn_keep = "true" *)  wire vt_disdav_a;
	(* syn_keep = "true" *)  wire vt_rdffnxt_1_a;
	(* syn_keep = "true" *)  wire vt_rdffnxt_2_a;
	(* syn_keep = "true" *)  wire vt_rdffnxt_3_a;
	(* syn_keep = "true" *)  wire vt_rdoneovlp_a;
	(* syn_keep = "true" *)  wire vt_dint_ovlp_b_a;
	(* syn_keep = "true" *)  wire vt_dtail7_a;
	(* syn_keep = "true" *)  wire vt_dtail8_a;
	(* syn_keep = "true" *)  wire vt_dtail78_a;
	(* syn_keep = "true" *)  wire vt_dn_ovlp_a;
	(* syn_keep = "true" *)  wire vt_ooeovlp_a;

	(* syn_keep = "true" *)  wire vt_gdav_1_b;
	(* syn_keep = "true" *)  wire vt_gdav_2_b;
	(* syn_keep = "true" *)  wire vt_gdav_3_b;
	(* syn_keep = "true" *)  wire [7:1] vt_oe_1_b;
	(* syn_keep = "true" *)  wire [7:1] vt_datanoend_b;
	(* syn_keep = "true" *)  wire vt_popbram_b;
	(* syn_keep = "true" *)  wire vt_busy_b;
	(* syn_keep = "true" *)  wire vt_busy_1_b;
	(* syn_keep = "true" *)  wire [8:1] vt_oehdr_b;
	(* syn_keep = "true" *)  wire [8:1] vt_tail_b;
	(* syn_keep = "true" *)  wire vt_tail8_1_b;
	(* syn_keep = "true" *)  wire vt_dav_b;
	(* syn_keep = "true" *)  wire vt_rdyovlp_b;
	(* syn_keep = "true" *)  wire vt_oeall_1_b;
	(* syn_keep = "true" *)  wire vt_oedata_b;
	(* syn_keep = "true" *)  wire [7:1] vt_dn_oe_b;
	(* syn_keep = "true" *)  wire [7:1] vt_davnodata_b;
	(* syn_keep = "true" *)  wire vt_pop_m2_b;
	(* syn_keep = "true" *)  wire vt_pop_m1_b;
	(* syn_keep = "true" *)  wire vt_pop_b;
	(* syn_keep = "true" *)  wire vt_oehdtl_b;
	(* syn_keep = "true" *)  wire vt_ht_crc_b;
	(* syn_keep = "true" *)  wire vt_dodat_b;
	(* syn_keep = "true" *)  wire vt_st_tail_b;
	(* syn_keep = "true" *)  wire vt_pbram_b;
	(* syn_keep = "true" *)  wire [7:1] vt_ffrfl_b; // raw FIFO full flags
	(* syn_keep = "true" *)  wire [7:1] vt_rdy_b;
	(* syn_keep = "true" *)  wire [5:1] vt_oe6_1_b;
	(* syn_keep = "true" *)  wire [5:1] vt_ovrin_b;
	(* syn_keep = "true" *)  wire [5:1] vt_ovr_b;
	(* syn_keep = "true" *)  wire [7:1] vt_r_act_b;
	(* syn_keep = "true" *)  wire [5:1] vt_rovr_1_b;
	(* syn_keep = "true" *)  wire vt_disdav_b;
	(* syn_keep = "true" *)  wire vt_rdffnxt_1_b;
	(* syn_keep = "true" *)  wire vt_rdffnxt_2_b;
	(* syn_keep = "true" *)  wire vt_rdffnxt_3_b;
	(* syn_keep = "true" *)  wire vt_rdoneovlp_b;
	(* syn_keep = "true" *)  wire vt_dint_ovlp_b_b;
	(* syn_keep = "true" *)  wire vt_dtail7_b;
	(* syn_keep = "true" *)  wire vt_dtail8_b;
	(* syn_keep = "true" *)  wire vt_dtail78_b;
	(* syn_keep = "true" *)  wire vt_dn_ovlp_b;
	(* syn_keep = "true" *)  wire vt_ooeovlp_b;

	(* syn_keep = "true" *)  wire vt_gdav_1_c;
	(* syn_keep = "true" *)  wire vt_gdav_2_c;
	(* syn_keep = "true" *)  wire vt_gdav_3_c;
	(* syn_keep = "true" *)  wire [7:1] vt_oe_1_c;
	(* syn_keep = "true" *)  wire [7:1] vt_datanoend_c;
	(* syn_keep = "true" *)  wire vt_popbram_c;
	(* syn_keep = "true" *)  wire vt_busy_c;
	(* syn_keep = "true" *)  wire vt_busy_1_c;
	(* syn_keep = "true" *)  wire [8:1] vt_oehdr_c;
	(* syn_keep = "true" *)  wire [8:1] vt_tail_c;
	(* syn_keep = "true" *)  wire vt_tail8_1_c;
	(* syn_keep = "true" *)  wire vt_dav_c;
	(* syn_keep = "true" *)  wire vt_rdyovlp_c;
	(* syn_keep = "true" *)  wire vt_oeall_1_c;
	(* syn_keep = "true" *)  wire vt_oedata_c;
	(* syn_keep = "true" *)  wire [7:1] vt_dn_oe_c;
	(* syn_keep = "true" *)  wire [7:1] vt_davnodata_c;
	(* syn_keep = "true" *)  wire vt_pop_m2_c;
	(* syn_keep = "true" *)  wire vt_pop_m1_c;
	(* syn_keep = "true" *)  wire vt_pop_c;
	(* syn_keep = "true" *)  wire vt_oehdtl_c;
	(* syn_keep = "true" *)  wire vt_ht_crc_c;
	(* syn_keep = "true" *)  wire vt_dodat_c;
	(* syn_keep = "true" *)  wire vt_st_tail_c;
	(* syn_keep = "true" *)  wire vt_pbram_c;
	(* syn_keep = "true" *)  wire [7:1] vt_ffrfl_c; // raw FIFO full flags
	(* syn_keep = "true" *)  wire [7:1] vt_rdy_c;
	(* syn_keep = "true" *)  wire [5:1] vt_oe6_1_c;
	(* syn_keep = "true" *)  wire [5:1] vt_ovrin_c;
	(* syn_keep = "true" *)  wire [5:1] vt_ovr_c;
	(* syn_keep = "true" *)  wire [7:1] vt_r_act_c;
	(* syn_keep = "true" *)  wire [5:1] vt_rovr_1_c;
	(* syn_keep = "true" *)  wire vt_disdav_c;
	(* syn_keep = "true" *)  wire vt_rdffnxt_1_c;
	(* syn_keep = "true" *)  wire vt_rdffnxt_2_c;
	(* syn_keep = "true" *)  wire vt_rdffnxt_3_c;
	(* syn_keep = "true" *)  wire vt_rdoneovlp_c;
	(* syn_keep = "true" *)  wire vt_dint_ovlp_b_c;
	(* syn_keep = "true" *)  wire vt_dtail7_c;
	(* syn_keep = "true" *)  wire vt_dtail8_c;
	(* syn_keep = "true" *)  wire vt_dtail78_c;
	(* syn_keep = "true" *)  wire vt_dn_ovlp_c;
	(* syn_keep = "true" *)  wire vt_ooeovlp_c;


	//
	// Majority logic/Voting for replicaterd registers
	//
//	vote #(.Width(1)) vote_gdav_1_a      (.A(gdav_1_a),      .B(gdav_1_b),      .C(gdav_1_c),      .V(vt_gdav_1_a));
//	vote #(.Width(1)) vote_gdav_2_a      (.A(gdav_2_a),      .B(gdav_2_b),      .C(gdav_2_c),      .V(vt_gdav_2_a));
//	vote #(.Width(1)) vote_gdav_3_a      (.A(gdav_3_a),      .B(gdav_3_b),      .C(gdav_3_c),      .V(vt_gdav_3_a));
//	vote #(.Width(7)) vote_datanoend_a   (.A(datanoend_a),   .B(datanoend_b),   .C(datanoend_c),   .V(vt_datanoend_a));
//	vote #(.Width(1)) vote_popbram_a     (.A(popbram_a),     .B(popbram_b),     .C(popbram_c),     .V(vt_popbram_a));
//	vote #(.Width(1)) vote_busy_a        (.A(busy_a),        .B(busy_b),        .C(busy_c),        .V(vt_busy_a));
//	vote #(.Width(1)) vote_busy_1_a      (.A(busy_1_a),      .B(busy_1_b),      .C(busy_1_c),      .V(vt_busy_1_a));
//	vote #(.Width(8)) vote_oehdr_a       (.A(oehdr_a),       .B(oehdr_b),       .C(oehdr_c),       .V(vt_oehdr_a));
//	vote #(.Width(8)) vote_tail_a        (.A(tail_a),        .B(tail_b),        .C(tail_c),        .V(vt_tail_a));
//	vote #(.Width(1)) vote_tail8_1_a     (.A(tail8_1_a),     .B(tail8_1_b),     .C(tail8_1_c),     .V(vt_tail8_1_a));
//	vote #(.Width(1)) vote_dav_a         (.A(dav_a),         .B(dav_b),         .C(dav_c),         .V(vt_dav_a));
//	vote #(.Width(1)) vote_rdyovlp_a     (.A(rdyovlp_a),     .B(rdyovlp_b),     .C(rdyovlp_c),     .V(vt_rdyovlp_a));
//	vote #(.Width(1)) vote_oeall_1_a     (.A(oeall_1_a),     .B(oeall_1_b),     .C(oeall_1_c),     .V(vt_oeall_1_a));
//	vote #(.Width(1)) vote_oedata_a      (.A(oedata_a),      .B(oedata_b),      .C(oedata_c),      .V(vt_oedata_a));
//	vote #(.Width(7)) vote_dn_oe_a       (.A(dn_oe_a),       .B(dn_oe_b),       .C(dn_oe_c),       .V(vt_dn_oe_a));
//	vote #(.Width(7)) vote_davnodata_a   (.A(davnodata_a),   .B(davnodata_b),   .C(davnodata_c),   .V(vt_davnodata_a));
//	vote #(.Width(1)) vote_pop_m2_a      (.A(pop_m2_a),      .B(pop_m2_b),      .C(pop_m2_c),      .V(vt_pop_m2_a));
//	vote #(.Width(1)) vote_pop_m1_a      (.A(pop_m1_a),      .B(pop_m1_b),      .C(pop_m1_c),      .V(vt_pop_m1_a));
//	vote #(.Width(1)) vote_pop_a         (.A(pop_a),         .B(pop_b),         .C(pop_c),         .V(vt_pop_a));
//	vote #(.Width(1)) vote_oehdtl_a      (.A(oehdtl_a),      .B(oehdtl_b),      .C(oehdtl_c),      .V(vt_oehdtl_a));
//	vote #(.Width(1)) vote_ht_crc_a      (.A(ht_crc_a),      .B(ht_crc_b),      .C(ht_crc_c),      .V(vt_ht_crc_a));
//	vote #(.Width(1)) vote_dodat_a       (.A(dodat_a),       .B(dodat_b),       .C(dodat_c),       .V(vt_dodat_a));
//	vote #(.Width(1)) vote_st_tail_a     (.A(st_tail_a),     .B(st_tail_b),     .C(st_tail_c),     .V(vt_st_tail_a));
//	vote #(.Width(1)) vote_pbram_a       (.A(pbram_a),       .B(pbram_b),       .C(pbram_c),       .V(vt_pbram_a));
//	vote #(.Width(7)) vote_ffrfl_a       (.A(ffrfl_a),       .B(ffrfl_b),       .C(ffrfl_c),       .V(vt_ffrfl_a));
//	vote #(.Width(7)) vote_rdy_a         (.A(rdy_a),         .B(rdy_b),         .C(rdy_c),         .V(vt_rdy_a));
//	vote #(.Width(5)) vote_oe6_1_a       (.A(oe6_1_a),       .B(oe6_1_b),       .C(oe6_1_c),       .V(vt_oe6_1_a));
//	vote #(.Width(5)) vote_ovrin_a       (.A(ovrin_a),       .B(ovrin_b),       .C(ovrin_c),       .V(vt_ovrin_a));
//	vote #(.Width(5)) vote_ovr_a         (.A(ovr_a),         .B(ovr_b),         .C(ovr_c),         .V(vt_ovr_a));
//	vote #(.Width(7)) vote_r_act_a       (.A(r_act_a),       .B(r_act_b),       .C(r_act_c),       .V(vt_r_act_a));
//	vote #(.Width(5)) vote_rovr_1_a      (.A(rovr_1_a),      .B(rovr_1_b),      .C(rovr_1_c),      .V(vt_rovr_1_a));
//	vote #(.Width(1)) vote_disdav_a      (.A(disdav_a),      .B(disdav_b),      .C(disdav_c),      .V(vt_disdav_a));
//	vote #(.Width(1)) vote_rdffnxt_1_a   (.A(rdffnxt_1_a),   .B(rdffnxt_1_b),   .C(rdffnxt_1_c),   .V(vt_rdffnxt_1_a));
//	vote #(.Width(1)) vote_rdffnxt_2_a   (.A(rdffnxt_2_a),   .B(rdffnxt_2_b),   .C(rdffnxt_2_c),   .V(vt_rdffnxt_2_a));
//	vote #(.Width(1)) vote_rdffnxt_3_a   (.A(rdffnxt_3_a),   .B(rdffnxt_3_b),   .C(rdffnxt_3_c),   .V(vt_rdffnxt_3_a));
//	vote #(.Width(1)) vote_rdoneovlp_a   (.A(rdoneovlp_a),   .B(rdoneovlp_b),   .C(rdoneovlp_c),   .V(vt_rdoneovlp_a));
//	vote #(.Width(1)) vote_dint_ovlp_b_a (.A(dint_ovlp_b_a), .B(dint_ovlp_b_b), .C(dint_ovlp_b_c), .V(vt_dint_ovlp_b_a));
//	vote #(.Width(1)) vote_dtail7_a      (.A(dtail7_a),      .B(dtail7_b),      .C(dtail7_c),      .V(vt_dtail7_a));
//	vote #(.Width(1)) vote_dtail8_a      (.A(dtail8_a),      .B(dtail8_b),      .C(dtail8_c),      .V(vt_dtail8_a));
//	vote #(.Width(1)) vote_dtail78_a     (.A(dtail78_a),     .B(dtail78_b),     .C(dtail78_c),     .V(vt_dtail78_a));
//	vote #(.Width(1)) vote_dn_ovlp_a     (.A(dn_ovlp_a),     .B(dn_ovlp_b),     .C(dn_ovlp_c),     .V(vt_dn_ovlp_a));
//	vote #(.Width(1)) vote_ooeovlp_a     (.A(ooeovlp_a),     .B(ooeovlp_b),     .C(ooeovlp_c),     .V(vt_ooeovlp_a));

//	vote #(.Width(1)) vote_gdav_1_b      (.A(gdav_1_a),      .B(gdav_1_b),      .C(gdav_1_c),      .V(vt_gdav_1_b));
//	vote #(.Width(1)) vote_gdav_2_b      (.A(gdav_2_a),      .B(gdav_2_b),      .C(gdav_2_c),      .V(vt_gdav_2_b));
//	vote #(.Width(1)) vote_gdav_3_b      (.A(gdav_3_a),      .B(gdav_3_b),      .C(gdav_3_c),      .V(vt_gdav_3_b));
//	vote #(.Width(7)) vote_datanoend_b   (.A(datanoend_a),   .B(datanoend_b),   .C(datanoend_c),   .V(vt_datanoend_b));
//	vote #(.Width(1)) vote_popbram_b     (.A(popbram_a),     .B(popbram_b),     .C(popbram_c),     .V(vt_popbram_b));
//	vote #(.Width(1)) vote_busy_b        (.A(busy_a),        .B(busy_b),        .C(busy_c),        .V(vt_busy_b));
//	vote #(.Width(1)) vote_busy_1_b      (.A(busy_1_a),      .B(busy_1_b),      .C(busy_1_c),      .V(vt_busy_1_b));
//	vote #(.Width(8)) vote_oehdr_b       (.A(oehdr_a),       .B(oehdr_b),       .C(oehdr_c),       .V(vt_oehdr_b));
//	vote #(.Width(8)) vote_tail_b        (.A(tail_a),        .B(tail_b),        .C(tail_c),        .V(vt_tail_b));
//	vote #(.Width(1)) vote_tail8_1_b     (.A(tail8_1_a),     .B(tail8_1_b),     .C(tail8_1_c),     .V(vt_tail8_1_b));
//	vote #(.Width(1)) vote_dav_b         (.A(dav_a),         .B(dav_b),         .C(dav_c),         .V(vt_dav_b));
//	vote #(.Width(1)) vote_rdyovlp_b     (.A(rdyovlp_a),     .B(rdyovlp_b),     .C(rdyovlp_c),     .V(vt_rdyovlp_b));
//	vote #(.Width(1)) vote_oeall_1_b     (.A(oeall_1_a),     .B(oeall_1_b),     .C(oeall_1_c),     .V(vt_oeall_1_b));
//	vote #(.Width(1)) vote_oedata_b      (.A(oedata_a),      .B(oedata_b),      .C(oedata_c),      .V(vt_oedata_b));
//	vote #(.Width(7)) vote_dn_oe_b       (.A(dn_oe_a),       .B(dn_oe_b),       .C(dn_oe_c),       .V(vt_dn_oe_b));
//	vote #(.Width(7)) vote_davnodata_b   (.A(davnodata_a),   .B(davnodata_b),   .C(davnodata_c),   .V(vt_davnodata_b));
//	vote #(.Width(1)) vote_pop_m2_b      (.A(pop_m2_a),      .B(pop_m2_b),      .C(pop_m2_c),      .V(vt_pop_m2_b));
//	vote #(.Width(1)) vote_pop_m1_b      (.A(pop_m1_a),      .B(pop_m1_b),      .C(pop_m1_c),      .V(vt_pop_m1_b));
//	vote #(.Width(1)) vote_pop_b         (.A(pop_a),         .B(pop_b),         .C(pop_c),         .V(vt_pop_b));
//	vote #(.Width(1)) vote_oehdtl_b      (.A(oehdtl_a),      .B(oehdtl_b),      .C(oehdtl_c),      .V(vt_oehdtl_b));
//	vote #(.Width(1)) vote_ht_crc_b      (.A(ht_crc_a),      .B(ht_crc_b),      .C(ht_crc_c),      .V(vt_ht_crc_b));
//	vote #(.Width(1)) vote_dodat_b       (.A(dodat_a),       .B(dodat_b),       .C(dodat_c),       .V(vt_dodat_b));
//	vote #(.Width(1)) vote_st_tail_b     (.A(st_tail_a),     .B(st_tail_b),     .C(st_tail_c),     .V(vt_st_tail_b));
//	vote #(.Width(1)) vote_pbram_b       (.A(pbram_a),       .B(pbram_b),       .C(pbram_c),       .V(vt_pbram_b));
//	vote #(.Width(7)) vote_ffrfl_b       (.A(ffrfl_a),       .B(ffrfl_b),       .C(ffrfl_c),       .V(vt_ffrfl_b));
//	vote #(.Width(7)) vote_rdy_b         (.A(rdy_a),         .B(rdy_b),         .C(rdy_c),         .V(vt_rdy_b));
//	vote #(.Width(5)) vote_oe6_1_b       (.A(oe6_1_a),       .B(oe6_1_b),       .C(oe6_1_c),       .V(vt_oe6_1_b));
//	vote #(.Width(5)) vote_ovrin_b       (.A(ovrin_a),       .B(ovrin_b),       .C(ovrin_c),       .V(vt_ovrin_b));
//	vote #(.Width(5)) vote_ovr_b         (.A(ovr_a),         .B(ovr_b),         .C(ovr_c),         .V(vt_ovr_b));
//	vote #(.Width(7)) vote_r_act_b       (.A(r_act_a),       .B(r_act_b),       .C(r_act_c),       .V(vt_r_act_b));
//	vote #(.Width(5)) vote_rovr_1_b      (.A(rovr_1_a),      .B(rovr_1_b),      .C(rovr_1_c),      .V(vt_rovr_1_b));
//	vote #(.Width(1)) vote_disdav_b      (.A(disdav_a),      .B(disdav_b),      .C(disdav_c),      .V(vt_disdav_b));
//	vote #(.Width(1)) vote_rdffnxt_1_b   (.A(rdffnxt_1_a),   .B(rdffnxt_1_b),   .C(rdffnxt_1_c),   .V(vt_rdffnxt_1_b));
//	vote #(.Width(1)) vote_rdffnxt_2_b   (.A(rdffnxt_2_a),   .B(rdffnxt_2_b),   .C(rdffnxt_2_c),   .V(vt_rdffnxt_2_b));
//	vote #(.Width(1)) vote_rdffnxt_3_b   (.A(rdffnxt_3_a),   .B(rdffnxt_3_b),   .C(rdffnxt_3_c),   .V(vt_rdffnxt_3_b));
//	vote #(.Width(1)) vote_rdoneovlp_b   (.A(rdoneovlp_a),   .B(rdoneovlp_b),   .C(rdoneovlp_c),   .V(vt_rdoneovlp_b));
//	vote #(.Width(1)) vote_dint_ovlp_b_b (.A(dint_ovlp_b_a), .B(dint_ovlp_b_b), .C(dint_ovlp_b_c), .V(vt_dint_ovlp_b_b));
//	vote #(.Width(1)) vote_dtail7_b      (.A(dtail7_a),      .B(dtail7_b),      .C(dtail7_c),      .V(vt_dtail7_b));
//	vote #(.Width(1)) vote_dtail8_b      (.A(dtail8_a),      .B(dtail8_b),      .C(dtail8_c),      .V(vt_dtail8_b));
//	vote #(.Width(1)) vote_dtail78_b     (.A(dtail78_a),     .B(dtail78_b),     .C(dtail78_c),     .V(vt_dtail78_b));
//	vote #(.Width(1)) vote_dn_ovlp_b     (.A(dn_ovlp_a),     .B(dn_ovlp_b),     .C(dn_ovlp_c),     .V(vt_dn_ovlp_b));
//	vote #(.Width(1)) vote_ooeovlp_b     (.A(ooeovlp_a),     .B(ooeovlp_b),     .C(ooeovlp_c),     .V(vt_ooeovlp_b));

//	vote #(.Width(1)) vote_gdav_1_c      (.A(gdav_1_a),      .B(gdav_1_b),      .C(gdav_1_c),      .V(vt_gdav_1_c));
//	vote #(.Width(1)) vote_gdav_2_c      (.A(gdav_2_a),      .B(gdav_2_b),      .C(gdav_2_c),      .V(vt_gdav_2_c));
//	vote #(.Width(1)) vote_gdav_3_c      (.A(gdav_3_a),      .B(gdav_3_b),      .C(gdav_3_c),      .V(vt_gdav_3_c));
//	vote #(.Width(7)) vote_datanoend_c   (.A(datanoend_a),   .B(datanoend_b),   .C(datanoend_c),   .V(vt_datanoend_c));
//	vote #(.Width(1)) vote_popbram_c     (.A(popbram_a),     .B(popbram_b),     .C(popbram_c),     .V(vt_popbram_c));
//	vote #(.Width(1)) vote_busy_c        (.A(busy_a),        .B(busy_b),        .C(busy_c),        .V(vt_busy_c));
//	vote #(.Width(1)) vote_busy_1_c      (.A(busy_1_a),      .B(busy_1_b),      .C(busy_1_c),      .V(vt_busy_1_c));
//	vote #(.Width(8)) vote_oehdr_c       (.A(oehdr_a),       .B(oehdr_b),       .C(oehdr_c),       .V(vt_oehdr_c));
//	vote #(.Width(8)) vote_tail_c        (.A(tail_a),        .B(tail_b),        .C(tail_c),        .V(vt_tail_c));
//	vote #(.Width(1)) vote_tail8_1_c     (.A(tail8_1_a),     .B(tail8_1_b),     .C(tail8_1_c),     .V(vt_tail8_1_c));
//	vote #(.Width(1)) vote_dav_c         (.A(dav_a),         .B(dav_b),         .C(dav_c),         .V(vt_dav_c));
//	vote #(.Width(1)) vote_rdyovlp_c     (.A(rdyovlp_a),     .B(rdyovlp_b),     .C(rdyovlp_c),     .V(vt_rdyovlp_c));
//	vote #(.Width(1)) vote_oeall_1_c     (.A(oeall_1_a),     .B(oeall_1_b),     .C(oeall_1_c),     .V(vt_oeall_1_c));
//	vote #(.Width(1)) vote_oedata_c      (.A(oedata_a),      .B(oedata_b),      .C(oedata_c),      .V(vt_oedata_c));
//	vote #(.Width(7)) vote_dn_oe_c       (.A(dn_oe_a),       .B(dn_oe_b),       .C(dn_oe_c),       .V(vt_dn_oe_c));
//	vote #(.Width(7)) vote_davnodata_c   (.A(davnodata_a),   .B(davnodata_b),   .C(davnodata_c),   .V(vt_davnodata_c));
//	vote #(.Width(1)) vote_pop_m2_c      (.A(pop_m2_a),      .B(pop_m2_b),      .C(pop_m2_c),      .V(vt_pop_m2_c));
//	vote #(.Width(1)) vote_pop_m1_c      (.A(pop_m1_a),      .B(pop_m1_b),      .C(pop_m1_c),      .V(vt_pop_m1_c));
//	vote #(.Width(1)) vote_pop_c         (.A(pop_a),         .B(pop_b),         .C(pop_c),         .V(vt_pop_c));
//	vote #(.Width(1)) vote_oehdtl_c      (.A(oehdtl_a),      .B(oehdtl_b),      .C(oehdtl_c),      .V(vt_oehdtl_c));
//	vote #(.Width(1)) vote_ht_crc_c      (.A(ht_crc_a),      .B(ht_crc_b),      .C(ht_crc_c),      .V(vt_ht_crc_c));
//	vote #(.Width(1)) vote_dodat_c       (.A(dodat_a),       .B(dodat_b),       .C(dodat_c),       .V(vt_dodat_c));
//	vote #(.Width(1)) vote_st_tail_c     (.A(st_tail_a),     .B(st_tail_b),     .C(st_tail_c),     .V(vt_st_tail_c));
//	vote #(.Width(1)) vote_pbram_c       (.A(pbram_a),       .B(pbram_b),       .C(pbram_c),       .V(vt_pbram_c));
//	vote #(.Width(7)) vote_ffrfl_c       (.A(ffrfl_a),       .B(ffrfl_b),       .C(ffrfl_c),       .V(vt_ffrfl_c));
//	vote #(.Width(7)) vote_rdy_c         (.A(rdy_a),         .B(rdy_b),         .C(rdy_c),         .V(vt_rdy_c));
//	vote #(.Width(5)) vote_oe6_1_c       (.A(oe6_1_a),       .B(oe6_1_b),       .C(oe6_1_c),       .V(vt_oe6_1_c));
//	vote #(.Width(5)) vote_ovrin_c       (.A(ovrin_a),       .B(ovrin_b),       .C(ovrin_c),       .V(vt_ovrin_c));
//	vote #(.Width(5)) vote_ovr_c         (.A(ovr_a),         .B(ovr_b),         .C(ovr_c),         .V(vt_ovr_c));
//	vote #(.Width(7)) vote_r_act_c       (.A(r_act_a),       .B(r_act_b),       .C(r_act_c),       .V(vt_r_act_c));
//	vote #(.Width(5)) vote_rovr_1_c      (.A(rovr_1_a),      .B(rovr_1_b),      .C(rovr_1_c),      .V(vt_rovr_1_c));
//	vote #(.Width(1)) vote_disdav_c      (.A(disdav_a),      .B(disdav_b),      .C(disdav_c),      .V(vt_disdav_c));
//	vote #(.Width(1)) vote_rdffnxt_1_c   (.A(rdffnxt_1_a),   .B(rdffnxt_1_b),   .C(rdffnxt_1_c),   .V(vt_rdffnxt_1_c));
//	vote #(.Width(1)) vote_rdffnxt_2_c   (.A(rdffnxt_2_a),   .B(rdffnxt_2_b),   .C(rdffnxt_2_c),   .V(vt_rdffnxt_2_c));
//	vote #(.Width(1)) vote_rdffnxt_3_c   (.A(rdffnxt_3_a),   .B(rdffnxt_3_b),   .C(rdffnxt_3_c),   .V(vt_rdffnxt_3_c));
//	vote #(.Width(1)) vote_rdoneovlp_c   (.A(rdoneovlp_a),   .B(rdoneovlp_b),   .C(rdoneovlp_c),   .V(vt_rdoneovlp_c));
//	vote #(.Width(1)) vote_dint_ovlp_b_c (.A(dint_ovlp_b_a), .B(dint_ovlp_b_b), .C(dint_ovlp_b_c), .V(vt_dint_ovlp_b_c));
//	vote #(.Width(1)) vote_dtail7_c      (.A(dtail7_a),      .B(dtail7_b),      .C(dtail7_c),      .V(vt_dtail7_c));
//	vote #(.Width(1)) vote_dtail8_c      (.A(dtail8_a),      .B(dtail8_b),      .C(dtail8_c),      .V(vt_dtail8_c));
//	vote #(.Width(1)) vote_dtail78_c     (.A(dtail78_a),     .B(dtail78_b),     .C(dtail78_c),     .V(vt_dtail78_c));
//	vote #(.Width(1)) vote_dn_ovlp_c     (.A(dn_ovlp_a),     .B(dn_ovlp_b),     .C(dn_ovlp_c),     .V(vt_dn_ovlp_c));
//	vote #(.Width(1)) vote_ooeovlp_c     (.A(ooeovlp_a),     .B(ooeovlp_b),     .C(ooeovlp_c),     .V(vt_ooeovlp_c));

	assign  vt_gdav_1_a      = (gdav_1_a      & gdav_1_b)      | (gdav_1_b      & gdav_1_c)      | (gdav_1_a      & gdav_1_c);      // Majority logic
	assign  vt_gdav_2_a      = (gdav_2_a      & gdav_2_b)      | (gdav_2_b      & gdav_2_c)      | (gdav_2_a      & gdav_2_c);      // Majority logic
	assign  vt_gdav_3_a      = (gdav_3_a      & gdav_3_b)      | (gdav_3_b      & gdav_3_c)      | (gdav_3_a      & gdav_3_c);      // Majority logic
	assign  vt_oe_1_a        = (oe_1_a        & oe_1_b)        | (oe_1_b        & oe_1_c)        | (oe_1_a        & oe_1_c);        // Majority logic
	assign  vt_datanoend_a   = (datanoend_a   & datanoend_b)   | (datanoend_b   & datanoend_c)   | (datanoend_a   & datanoend_c);      // Majority logic
	assign  vt_popbram_a     = (popbram_a     & popbram_b)     | (popbram_b     & popbram_c)     | (popbram_a     & popbram_c);      // Majority logic
	assign  vt_busy_a        = (busy_a        & busy_b)        | (busy_b        & busy_c)        | (busy_a        & busy_c);      // Majority logic
	assign  vt_busy_1_a      = (busy_1_a      & busy_1_b)      | (busy_1_b      & busy_1_c)      | (busy_1_a      & busy_1_c);      // Majority logic
	assign  vt_oehdr_a       = (oehdr_a       & oehdr_b)       | (oehdr_b       & oehdr_c)       | (oehdr_a       & oehdr_c);      // Majority logic
	assign  vt_tail_a        = (tail_a        & tail_b)        | (tail_b        & tail_c)        | (tail_a        & tail_c);      // Majority logic
	assign  vt_tail8_1_a     = (tail8_1_a     & tail8_1_b)     | (tail8_1_b     & tail8_1_c)     | (tail8_1_a     & tail8_1_c);      // Majority logic
	assign  vt_dav_a         = (dav_a         & dav_b)         | (dav_b         & dav_c)         | (dav_a         & dav_c);      // Majority logic
	assign  vt_rdyovlp_a     = (rdyovlp_a     & rdyovlp_b)     | (rdyovlp_b     & rdyovlp_c)     | (rdyovlp_a     & rdyovlp_c);      // Majority logic
	assign  vt_oeall_1_a     = (oeall_1_a     & oeall_1_b)     | (oeall_1_b     & oeall_1_c)     | (oeall_1_a     & oeall_1_c);      // Majority logic
	assign  vt_oedata_a      = (oedata_a      & oedata_b)      | (oedata_b      & oedata_c)      | (oedata_a      & oedata_c);      // Majority logic
	assign  vt_dn_oe_a       = (dn_oe_a       & dn_oe_b)       | (dn_oe_b       & dn_oe_c)       | (dn_oe_a       & dn_oe_c);      // Majority logic
	assign  vt_davnodata_a   = (davnodata_a   & davnodata_b)   | (davnodata_b   & davnodata_c)   | (davnodata_a   & davnodata_c);      // Majority logic
	assign  vt_pop_m2_a      = (pop_m2_a      & pop_m2_b)      | (pop_m2_b      & pop_m2_c)      | (pop_m2_a      & pop_m2_c);      // Majority logic
	assign  vt_pop_m1_a      = (pop_m1_a      & pop_m1_b)      | (pop_m1_b      & pop_m1_c)      | (pop_m1_a      & pop_m1_c);      // Majority logic
	assign  vt_pop_a         = (pop_a         & pop_b)         | (pop_b         & pop_c)         | (pop_a         & pop_c);      // Majority logic
	assign  vt_oehdtl_a      = (oehdtl_a      & oehdtl_b)      | (oehdtl_b      & oehdtl_c)      | (oehdtl_a      & oehdtl_c);      // Majority logic
	assign  vt_ht_crc_a      = (ht_crc_a      & ht_crc_b)      | (ht_crc_b      & ht_crc_c)      | (ht_crc_a      & ht_crc_c);      // Majority logic
	assign  vt_dodat_a       = (dodat_a       & dodat_b)       | (dodat_b       & dodat_c)       | (dodat_a       & dodat_c);      // Majority logic
	assign  vt_st_tail_a     = (st_tail_a     & st_tail_b)     | (st_tail_b     & st_tail_c)     | (st_tail_a     & st_tail_c);      // Majority logic
	assign  vt_pbram_a       = (pbram_a       & pbram_b)       | (pbram_b       & pbram_c)       | (pbram_a       & pbram_c);      // Majority logic
	assign  vt_ffrfl_a       = (ffrfl_a       & ffrfl_b)       | (ffrfl_b       & ffrfl_c)       | (ffrfl_a       & ffrfl_c);      // Majority logic
	assign  vt_rdy_a         = (rdy_a         & rdy_b)         | (rdy_b         & rdy_c)         | (rdy_a         & rdy_c);      // Majority logic
	assign  vt_oe6_1_a       = (oe6_1_a       & oe6_1_b)       | (oe6_1_b       & oe6_1_c)       | (oe6_1_a       & oe6_1_c);      // Majority logic
	assign  vt_ovrin_a       = (ovrin_a       & ovrin_b)       | (ovrin_b       & ovrin_c)       | (ovrin_a       & ovrin_c);      // Majority logic
	assign  vt_ovr_a         = (ovr_a         & ovr_b)         | (ovr_b         & ovr_c)         | (ovr_a         & ovr_c);      // Majority logic
//	assign  vt_ovr_a         = 5'b00000;      // Majority logic
	assign  vt_r_act_a       = (r_act_a       & r_act_b)       | (r_act_b       & r_act_c)       | (r_act_a       & r_act_c);      // Majority logic
	assign  vt_rovr_1_a      = (rovr_1_a      & rovr_1_b)      | (rovr_1_b      & rovr_1_c)      | (rovr_1_a      & rovr_1_c);      // Majority logic
	assign  vt_disdav_a      = (disdav_a      & disdav_b)      | (disdav_b      & disdav_c)      | (disdav_a      & disdav_c);      // Majority logic
	assign  vt_rdffnxt_1_a   = (rdffnxt_1_a   & rdffnxt_1_b)   | (rdffnxt_1_b   & rdffnxt_1_c)   | (rdffnxt_1_a   & rdffnxt_1_c);      // Majority logic
	assign  vt_rdffnxt_2_a   = (rdffnxt_2_a   & rdffnxt_2_b)   | (rdffnxt_2_b   & rdffnxt_2_c)   | (rdffnxt_2_a   & rdffnxt_2_c);      // Majority logic
	assign  vt_rdffnxt_3_a   = (rdffnxt_1_a   & rdffnxt_3_b)   | (rdffnxt_3_b   & rdffnxt_3_c)   | (rdffnxt_3_a   & rdffnxt_3_c);      // Majority logic
	assign  vt_rdoneovlp_a   = (rdoneovlp_a   & rdoneovlp_b)   | (rdoneovlp_b   & rdoneovlp_c)   | (rdoneovlp_a   & rdoneovlp_c);      // Majority logic
	assign  vt_dint_ovlp_b_a = (dint_ovlp_b_a & dint_ovlp_b_b) | (dint_ovlp_b_b & dint_ovlp_b_c) | (dint_ovlp_b_a & dint_ovlp_b_c); // Majority logic
	assign  vt_dtail7_a      = (dtail7_a      & dtail7_b)      | (dtail7_b      & dtail7_c)      | (dtail7_a      & dtail7_c);      // Majority logic
	assign  vt_dtail8_a      = (dtail8_a      & dtail8_b)      | (dtail8_b      & dtail8_c)      | (dtail8_a      & dtail8_c);      // Majority logic
	assign  vt_dtail78_a     = (dtail78_a     & dtail78_b)     | (dtail78_b     & dtail78_c)     | (dtail78_a     & dtail78_c);      // Majority logic
	assign  vt_dn_ovlp_a     = (dn_ovlp_a     & dn_ovlp_b)     | (dn_ovlp_b     & dn_ovlp_c)     | (dn_ovlp_a     & dn_ovlp_c);      // Majority logic
	assign  vt_ooeovlp_a     = (ooeovlp_a     & ooeovlp_b)     | (ooeovlp_b     & ooeovlp_c)     | (ooeovlp_a     & ooeovlp_c);      // Majority logic

	assign  vt_gdav_1_b      = (gdav_1_a      & gdav_1_b)      | (gdav_1_b      & gdav_1_c)      | (gdav_1_a      & gdav_1_c);      // Majority logic
	assign  vt_gdav_2_b      = (gdav_2_a      & gdav_2_b)      | (gdav_2_b      & gdav_2_c)      | (gdav_2_a      & gdav_2_c);      // Majority logic
	assign  vt_gdav_3_b      = (gdav_3_a      & gdav_3_b)      | (gdav_3_b      & gdav_3_c)      | (gdav_3_a      & gdav_3_c);      // Majority logic
	assign  vt_oe_1_b        = (oe_1_a        & oe_1_b)        | (oe_1_b        & oe_1_c)        | (oe_1_a        & oe_1_c);        // Majority logic
	assign  vt_datanoend_b   = (datanoend_a   & datanoend_b)   | (datanoend_b   & datanoend_c)   | (datanoend_a   & datanoend_c);      // Majority logic
	assign  vt_popbram_b     = (popbram_a     & popbram_b)     | (popbram_b     & popbram_c)     | (popbram_a     & popbram_c);      // Majority logic
	assign  vt_busy_b        = (busy_a        & busy_b)        | (busy_b        & busy_c)        | (busy_a        & busy_c);      // Majority logic
	assign  vt_busy_1_b      = (busy_1_a      & busy_1_b)      | (busy_1_b      & busy_1_c)      | (busy_1_a      & busy_1_c);      // Majority logic
	assign  vt_oehdr_b       = (oehdr_a       & oehdr_b)       | (oehdr_b       & oehdr_c)       | (oehdr_a       & oehdr_c);      // Majority logic
	assign  vt_tail_b        = (tail_a        & tail_b)        | (tail_b        & tail_c)        | (tail_a        & tail_c);      // Majority logic
	assign  vt_tail8_1_b     = (tail8_1_a     & tail8_1_b)     | (tail8_1_b     & tail8_1_c)     | (tail8_1_a     & tail8_1_c);      // Majority logic
	assign  vt_dav_b         = (dav_a         & dav_b)         | (dav_b         & dav_c)         | (dav_a         & dav_c);      // Majority logic
	assign  vt_rdyovlp_b     = (rdyovlp_a     & rdyovlp_b)     | (rdyovlp_b     & rdyovlp_c)     | (rdyovlp_a     & rdyovlp_c);      // Majority logic
	assign  vt_oeall_1_b     = (oeall_1_a     & oeall_1_b)     | (oeall_1_b     & oeall_1_c)     | (oeall_1_a     & oeall_1_c);      // Majority logic
	assign  vt_oedata_b      = (oedata_a      & oedata_b)      | (oedata_b      & oedata_c)      | (oedata_a      & oedata_c);      // Majority logic
	assign  vt_dn_oe_b       = (dn_oe_a       & dn_oe_b)       | (dn_oe_b       & dn_oe_c)       | (dn_oe_a       & dn_oe_c);      // Majority logic
	assign  vt_davnodata_b   = (davnodata_a   & davnodata_b)   | (davnodata_b   & davnodata_c)   | (davnodata_a   & davnodata_c);      // Majority logic
	assign  vt_pop_m2_b      = (pop_m2_a      & pop_m2_b)      | (pop_m2_b      & pop_m2_c)      | (pop_m2_a      & pop_m2_c);      // Majority logic
	assign  vt_pop_m1_b      = (pop_m1_a      & pop_m1_b)      | (pop_m1_b      & pop_m1_c)      | (pop_m1_a      & pop_m1_c);      // Majority logic
	assign  vt_pop_b         = (pop_a         & pop_b)         | (pop_b         & pop_c)         | (pop_a         & pop_c);      // Majority logic
	assign  vt_oehdtl_b      = (oehdtl_a      & oehdtl_b)      | (oehdtl_b      & oehdtl_c)      | (oehdtl_a      & oehdtl_c);      // Majority logic
	assign  vt_ht_crc_b      = (ht_crc_a      & ht_crc_b)      | (ht_crc_b      & ht_crc_c)      | (ht_crc_a      & ht_crc_c);      // Majority logic
	assign  vt_dodat_b       = (dodat_a       & dodat_b)       | (dodat_b       & dodat_c)       | (dodat_a       & dodat_c);      // Majority logic
	assign  vt_st_tail_b     = (st_tail_a     & st_tail_b)     | (st_tail_b     & st_tail_c)     | (st_tail_a     & st_tail_c);      // Majority logic
	assign  vt_pbram_b       = (pbram_a       & pbram_b)       | (pbram_b       & pbram_c)       | (pbram_a       & pbram_c);      // Majority logic
	assign  vt_ffrfl_b       = (ffrfl_a       & ffrfl_b)       | (ffrfl_b       & ffrfl_c)       | (ffrfl_a       & ffrfl_c);      // Majority logic
	assign  vt_rdy_b         = (rdy_a         & rdy_b)         | (rdy_b         & rdy_c)         | (rdy_a         & rdy_c);      // Majority logic
	assign  vt_oe6_1_b       = (oe6_1_a       & oe6_1_b)       | (oe6_1_b       & oe6_1_c)       | (oe6_1_a       & oe6_1_c);      // Majority logic
	assign  vt_ovrin_b       = (ovrin_a       & ovrin_b)       | (ovrin_b       & ovrin_c)       | (ovrin_a       & ovrin_c);      // Majority logic
	assign  vt_ovr_b         = (ovr_a         & ovr_b)         | (ovr_b         & ovr_c)         | (ovr_a         & ovr_c);      // Majority logic
//	assign  vt_ovr_b         = 5'b00000;      // Majority logic
	assign  vt_r_act_b       = (r_act_a       & r_act_b)       | (r_act_b       & r_act_c)       | (r_act_a       & r_act_c);      // Majority logic
	assign  vt_rovr_1_b      = (rovr_1_a      & rovr_1_b)      | (rovr_1_b      & rovr_1_c)      | (rovr_1_a      & rovr_1_c);      // Majority logic
	assign  vt_disdav_b      = (disdav_a      & disdav_b)      | (disdav_b      & disdav_c)      | (disdav_a      & disdav_c);      // Majority logic
	assign  vt_rdffnxt_1_b   = (rdffnxt_1_a   & rdffnxt_1_b)   | (rdffnxt_1_b   & rdffnxt_1_c)   | (rdffnxt_1_a   & rdffnxt_1_c);      // Majority logic
	assign  vt_rdffnxt_2_b   = (rdffnxt_2_a   & rdffnxt_2_b)   | (rdffnxt_2_b   & rdffnxt_2_c)   | (rdffnxt_2_a   & rdffnxt_2_c);      // Majority logic
	assign  vt_rdffnxt_3_b   = (rdffnxt_1_a   & rdffnxt_3_b)   | (rdffnxt_3_b   & rdffnxt_3_c)   | (rdffnxt_3_a   & rdffnxt_3_c);      // Majority logic
	assign  vt_rdoneovlp_b   = (rdoneovlp_a   & rdoneovlp_b)   | (rdoneovlp_b   & rdoneovlp_c)   | (rdoneovlp_a   & rdoneovlp_c);      // Majority logic
	assign  vt_dint_ovlp_b_b = (dint_ovlp_b_a & dint_ovlp_b_b) | (dint_ovlp_b_b & dint_ovlp_b_c) | (dint_ovlp_b_a & dint_ovlp_b_c); // Majority logic
	assign  vt_dtail7_b      = (dtail7_a      & dtail7_b)      | (dtail7_b      & dtail7_c)      | (dtail7_a      & dtail7_c);      // Majority logic
	assign  vt_dtail8_b      = (dtail8_a      & dtail8_b)      | (dtail8_b      & dtail8_c)      | (dtail8_a      & dtail8_c);      // Majority logic
	assign  vt_dtail78_b     = (dtail78_a     & dtail78_b)     | (dtail78_b     & dtail78_c)     | (dtail78_a     & dtail78_c);      // Majority logic
	assign  vt_dn_ovlp_b     = (dn_ovlp_a     & dn_ovlp_b)     | (dn_ovlp_b     & dn_ovlp_c)     | (dn_ovlp_a     & dn_ovlp_c);      // Majority logic
	assign  vt_ooeovlp_b     = (ooeovlp_a     & ooeovlp_b)     | (ooeovlp_b     & ooeovlp_c)     | (ooeovlp_a     & ooeovlp_c);      // Majority logic

	assign  vt_gdav_1_c      = (gdav_1_a      & gdav_1_b)      | (gdav_1_b      & gdav_1_c)      | (gdav_1_a      & gdav_1_c);      // Majority logic
	assign  vt_gdav_2_c      = (gdav_2_a      & gdav_2_b)      | (gdav_2_b      & gdav_2_c)      | (gdav_2_a      & gdav_2_c);      // Majority logic
	assign  vt_gdav_3_c      = (gdav_3_a      & gdav_3_b)      | (gdav_3_b      & gdav_3_c)      | (gdav_3_a      & gdav_3_c);      // Majority logic
	assign  vt_oe_1_c        = (oe_1_a        & oe_1_b)        | (oe_1_b        & oe_1_c)        | (oe_1_a        & oe_1_c);        // Majority logic
	assign  vt_datanoend_c   = (datanoend_a   & datanoend_b)   | (datanoend_b   & datanoend_c)   | (datanoend_a   & datanoend_c);      // Majority logic
	assign  vt_popbram_c     = (popbram_a     & popbram_b)     | (popbram_b     & popbram_c)     | (popbram_a     & popbram_c);      // Majority logic
	assign  vt_busy_c        = (busy_a        & busy_b)        | (busy_b        & busy_c)        | (busy_a        & busy_c);      // Majority logic
	assign  vt_busy_1_c      = (busy_1_a      & busy_1_b)      | (busy_1_b      & busy_1_c)      | (busy_1_a      & busy_1_c);      // Majority logic
	assign  vt_oehdr_c       = (oehdr_a       & oehdr_b)       | (oehdr_b       & oehdr_c)       | (oehdr_a       & oehdr_c);      // Majority logic
	assign  vt_tail_c        = (tail_a        & tail_b)        | (tail_b        & tail_c)        | (tail_a        & tail_c);      // Majority logic
	assign  vt_tail8_1_c     = (tail8_1_a     & tail8_1_b)     | (tail8_1_b     & tail8_1_c)     | (tail8_1_a     & tail8_1_c);      // Majority logic
	assign  vt_dav_c         = (dav_a         & dav_b)         | (dav_b         & dav_c)         | (dav_a         & dav_c);      // Majority logic
	assign  vt_rdyovlp_c     = (rdyovlp_a     & rdyovlp_b)     | (rdyovlp_b     & rdyovlp_c)     | (rdyovlp_a     & rdyovlp_c);      // Majority logic
	assign  vt_oeall_1_c     = (oeall_1_a     & oeall_1_b)     | (oeall_1_b     & oeall_1_c)     | (oeall_1_a     & oeall_1_c);      // Majority logic
	assign  vt_oedata_c      = (oedata_a      & oedata_b)      | (oedata_b      & oedata_c)      | (oedata_a      & oedata_c);      // Majority logic
	assign  vt_dn_oe_c       = (dn_oe_a       & dn_oe_b)       | (dn_oe_b       & dn_oe_c)       | (dn_oe_a       & dn_oe_c);      // Majority logic
	assign  vt_davnodata_c   = (davnodata_a   & davnodata_b)   | (davnodata_b   & davnodata_c)   | (davnodata_a   & davnodata_c);      // Majority logic
	assign  vt_pop_m2_c      = (pop_m2_a      & pop_m2_b)      | (pop_m2_b      & pop_m2_c)      | (pop_m2_a      & pop_m2_c);      // Majority logic
	assign  vt_pop_m1_c      = (pop_m1_a      & pop_m1_b)      | (pop_m1_b      & pop_m1_c)      | (pop_m1_a      & pop_m1_c);      // Majority logic
	assign  vt_pop_c         = (pop_a         & pop_b)         | (pop_b         & pop_c)         | (pop_a         & pop_c);      // Majority logic
	assign  vt_oehdtl_c      = (oehdtl_a      & oehdtl_b)      | (oehdtl_b      & oehdtl_c)      | (oehdtl_a      & oehdtl_c);      // Majority logic
	assign  vt_ht_crc_c      = (ht_crc_a      & ht_crc_b)      | (ht_crc_b      & ht_crc_c)      | (ht_crc_a      & ht_crc_c);      // Majority logic
	assign  vt_dodat_c       = (dodat_a       & dodat_b)       | (dodat_b       & dodat_c)       | (dodat_a       & dodat_c);      // Majority logic
	assign  vt_st_tail_c     = (st_tail_a     & st_tail_b)     | (st_tail_b     & st_tail_c)     | (st_tail_a     & st_tail_c);      // Majority logic
	assign  vt_pbram_c       = (pbram_a       & pbram_b)       | (pbram_b       & pbram_c)       | (pbram_a       & pbram_c);      // Majority logic
	assign  vt_ffrfl_c       = (ffrfl_a       & ffrfl_b)       | (ffrfl_b       & ffrfl_c)       | (ffrfl_a       & ffrfl_c);      // Majority logic
	assign  vt_rdy_c         = (rdy_a         & rdy_b)         | (rdy_b         & rdy_c)         | (rdy_a         & rdy_c);      // Majority logic
	assign  vt_oe6_1_c       = (oe6_1_a       & oe6_1_b)       | (oe6_1_b       & oe6_1_c)       | (oe6_1_a       & oe6_1_c);      // Majority logic
	assign  vt_ovrin_c       = (ovrin_a       & ovrin_b)       | (ovrin_b       & ovrin_c)       | (ovrin_a       & ovrin_c);      // Majority logic
	assign  vt_ovr_c         = (ovr_a         & ovr_b)         | (ovr_b         & ovr_c)         | (ovr_a         & ovr_c);      // Majority logic
//	assign  vt_ovr_c         = 5'b00000;      // Majority logic
	assign  vt_r_act_c       = (r_act_a       & r_act_b)       | (r_act_b       & r_act_c)       | (r_act_a       & r_act_c);      // Majority logic
	assign  vt_rovr_1_c      = (rovr_1_a      & rovr_1_b)      | (rovr_1_b      & rovr_1_c)      | (rovr_1_a      & rovr_1_c);      // Majority logic
	assign  vt_disdav_c      = (disdav_a      & disdav_b)      | (disdav_b      & disdav_c)      | (disdav_a      & disdav_c);      // Majority logic
	assign  vt_rdffnxt_1_c   = (rdffnxt_1_a   & rdffnxt_1_b)   | (rdffnxt_1_b   & rdffnxt_1_c)   | (rdffnxt_1_a   & rdffnxt_1_c);      // Majority logic
	assign  vt_rdffnxt_2_c   = (rdffnxt_2_a   & rdffnxt_2_b)   | (rdffnxt_2_b   & rdffnxt_2_c)   | (rdffnxt_2_a   & rdffnxt_2_c);      // Majority logic
	assign  vt_rdffnxt_3_c   = (rdffnxt_1_a   & rdffnxt_3_b)   | (rdffnxt_3_b   & rdffnxt_3_c)   | (rdffnxt_3_a   & rdffnxt_3_c);      // Majority logic
	assign  vt_rdoneovlp_c   = (rdoneovlp_a   & rdoneovlp_b)   | (rdoneovlp_b   & rdoneovlp_c)   | (rdoneovlp_a   & rdoneovlp_c);      // Majority logic
	assign  vt_dint_ovlp_b_c = (dint_ovlp_b_a & dint_ovlp_b_b) | (dint_ovlp_b_b & dint_ovlp_b_c) | (dint_ovlp_b_a & dint_ovlp_b_c); // Majority logic
	assign  vt_dtail7_c      = (dtail7_a      & dtail7_b)      | (dtail7_b      & dtail7_c)      | (dtail7_a      & dtail7_c);      // Majority logic
	assign  vt_dtail8_c      = (dtail8_a      & dtail8_b)      | (dtail8_b      & dtail8_c)      | (dtail8_a      & dtail8_c);      // Majority logic
	assign  vt_dtail78_c     = (dtail78_a     & dtail78_b)     | (dtail78_b     & dtail78_c)     | (dtail78_a     & dtail78_c);      // Majority logic
	assign  vt_dn_ovlp_c     = (dn_ovlp_a     & dn_ovlp_b)     | (dn_ovlp_b     & dn_ovlp_c)     | (dn_ovlp_a     & dn_ovlp_c);      // Majority logic
	assign  vt_ooeovlp_c     = (ooeovlp_a     & ooeovlp_b)     | (ooeovlp_b     & ooeovlp_c)     | (ooeovlp_a     & ooeovlp_c);      // Majority logic

//	assign  vt_gdav_1_a      = gdav_1_a;
//	assign  vt_gdav_2_a      = gdav_2_a;
//	assign  vt_gdav_3_a      = gdav_3_a;
//	assign  vt_datanoend_a   = datanoend_a;
//	assign  vt_popbram_a     = popbram_a;
//	assign  vt_busy_a        = busy_a;
//	assign  vt_busy_1_a      = busy_1_a;
//	assign  vt_oehdr_a       = oehdr_a;
//	assign  vt_tail_a        = tail_a;
//	assign  vt_tail8_1_a     = tail8_1_a;
//	assign  vt_dav_a         = dav_a;
//	assign  vt_rdyovlp_a     = rdyovlp_a;
//	assign  vt_oeall_1_a     = oeall_1_a;
//	assign  vt_oedata_a      = oedata_a;
//	assign  vt_dn_oe_a       = dn_oe_a;
//	assign  vt_davnodata_a   = davnodata_a;
//	assign  vt_pop_m2_a      = pop_m2_a;
//	assign  vt_pop_m1_a      = pop_m1_a;
//	assign  vt_pop_a         = pop_a;
//	assign  vt_oehdtl_a      = oehdtl_a;
//	assign  vt_ht_crc_a      = ht_crc_a;
//	assign  vt_dodat_a       = dodat_a;
//	assign  vt_st_tail_a     = st_tail_a;
//	assign  vt_pbram_a       = pbram_a;
//	assign  vt_ffrfl_a       = ffrfl_a;
//	assign  vt_rdy_a         = rdy_a;
//	assign  vt_oe6_1_a       = oe6_1_a;
//	assign  vt_ovrin_a       = ovrin_a;
//	assign  vt_ovr_a         = ovr_a;
//	assign  vt_r_act_a       = r_act_a;
//	assign  vt_rovr_1_a      = rovr_1_a;
//	assign  vt_disdav_a      = disdav_a;
//	assign  vt_rdffnxt_1_a   = rdffnxt_1_a;
//	assign  vt_rdffnxt_2_a   = rdffnxt_2_a;
//	assign  vt_rdffnxt_3_a   = rdffnxt_1_a;
//	assign  vt_rdoneovlp_a   = rdoneovlp_a;
//	assign  vt_dint_ovlp_b_a = dint_ovlp_b_a;
//	assign  vt_dtail7_a      = dtail7_a;
//	assign  vt_dtail8_a      = dtail8_a;
//	assign  vt_dtail78_a     = dtail78_a;
//	assign  vt_dn_ovlp_a     = dn_ovlp_a;
//	assign  vt_ooeovlp_a     = ooeovlp_a;

//	assign  vt_gdav_1_b      = gdav_1_b;
//	assign  vt_gdav_2_b      = gdav_2_b;
//	assign  vt_gdav_3_b      = gdav_3_b;
//	assign  vt_datanoend_b   = datanoend_b;
//	assign  vt_popbram_b     = popbram_b;
//	assign  vt_busy_b        = busy_b;
//	assign  vt_busy_1_b      = busy_1_b;
//	assign  vt_oehdr_b       = oehdr_b;
//	assign  vt_tail_b        = tail_b;
//	assign  vt_tail8_1_b     = tail8_1_b;
//	assign  vt_dav_b         = dav_b;
//	assign  vt_rdyovlp_b     = rdyovlp_b;
//	assign  vt_oeall_1_b     = oeall_1_b;
//	assign  vt_oedata_b      = oedata_b;
//	assign  vt_dn_oe_b       = dn_oe_b;
//	assign  vt_davnodata_b   = davnodata_b;
//	assign  vt_pop_m2_b      = pop_m2_b;
//	assign  vt_pop_m1_b      = pop_m1_b;
//	assign  vt_pop_b         = pop_b;
//	assign  vt_oehdtl_b      = oehdtl_b;
//	assign  vt_ht_crc_b      = ht_crc_b;
//	assign  vt_dodat_b       = dodat_b;
//	assign  vt_st_tail_b     = st_tail_b;
//	assign  vt_pbram_b       = pbram_b;
//	assign  vt_ffrfl_b       = ffrfl_b;
//	assign  vt_rdy_b         = rdy_b;
//	assign  vt_oe6_1_b       = oe6_1_b;
//	assign  vt_ovrin_b       = ovrin_b;
//	assign  vt_ovr_b         = ovr_b;
//	assign  vt_r_act_b       = r_act_b;
//	assign  vt_rovr_1_b      = rovr_1_b;
//	assign  vt_disdav_b      = disdav_b;
//	assign  vt_rdffnxt_1_b   = rdffnxt_1_b;
//	assign  vt_rdffnxt_2_b   = rdffnxt_2_b;
//	assign  vt_rdffnxt_3_b   = rdffnxt_1_b;
//	assign  vt_rdoneovlp_b   = rdoneovlp_b;
//	assign  vt_dint_ovlp_b_b = dint_ovlp_b_b;
//	assign  vt_dtail7_b      = dtail7_b;
//	assign  vt_dtail8_b      = dtail8_b;
//	assign  vt_dtail78_b     = dtail78_b;
//	assign  vt_dn_ovlp_b     = dn_ovlp_b;
//	assign  vt_ooeovlp_b     = ooeovlp_b;

//	assign  vt_gdav_1_c      = gdav_1_c;
//	assign  vt_gdav_2_c      = gdav_2_c;
//	assign  vt_gdav_3_c      = gdav_3_c;
//	assign  vt_datanoend_c   = datanoend_c;
//	assign  vt_popbram_c     = popbram_c;
//	assign  vt_busy_c        = busy_c;
//	assign  vt_busy_1_c      = busy_1_c;
//	assign  vt_oehdr_c       = oehdr_c;
//	assign  vt_tail_c        = tail_c;
//	assign  vt_tail8_1_c     = tail8_1_c;
//	assign  vt_dav_c         = dav_c;
//	assign  vt_rdyovlp_c     = rdyovlp_c;
//	assign  vt_oeall_1_c     = oeall_1_c;
//	assign  vt_oedata_c      = oedata_c;
//	assign  vt_dn_oe_c       = dn_oe_c;
//	assign  vt_davnodata_c   = davnodata_c;
//	assign  vt_pop_m2_c      = pop_m2_c;
//	assign  vt_pop_m1_c      = pop_m1_c;
//	assign  vt_pop_c         = pop_c;
//	assign  vt_oehdtl_c      = oehdtl_c;
//	assign  vt_ht_crc_c      = ht_crc_c;
//	assign  vt_dodat_c       = dodat_c;
//	assign  vt_st_tail_c     = st_tail_c;
//	assign  vt_pbram_c       = pbram_c;
//	assign  vt_ffrfl_c       = ffrfl_c;
//	assign  vt_rdy_c         = rdy_c;
//	assign  vt_oe6_1_c       = oe6_1_c;
//	assign  vt_ovrin_c       = ovrin_c;
//	assign  vt_ovr_c         = ovr_c;
//	assign  vt_r_act_c       = r_act_c;
//	assign  vt_rovr_1_c      = rovr_1_c;
//	assign  vt_disdav_c      = disdav_c;
//	assign  vt_rdffnxt_1_c   = rdffnxt_1_c;
//	assign  vt_rdffnxt_2_c   = rdffnxt_2_c;
//	assign  vt_rdffnxt_3_c   = rdffnxt_1_c;
//	assign  vt_rdoneovlp_c   = rdoneovlp_c;
//	assign  vt_dint_ovlp_b_c = dint_ovlp_b_c;
//	assign  vt_dtail7_c      = dtail7_c;
//	assign  vt_dtail8_c      = dtail8_c;
//	assign  vt_dtail78_c     = dtail78_c;
//	assign  vt_dn_ovlp_c     = dn_ovlp_c;
//	assign  vt_ooeovlp_c     = ooeovlp_c;


	//
	// module scope and local scope registers
	//
	(* syn_preserve = "true" *)  reg  rstcnt_a;
	(* syn_preserve = "true" *)  reg  ovlpend_a;
	(* syn_preserve = "true" *)  reg  [15:0] dint_a;
	(* syn_preserve = "true" *)  reg  oeall_a;

	(* syn_preserve = "true" *)  reg  rstcnt_b;
	(* syn_preserve = "true" *)  reg  ovlpend_b;
	(* syn_preserve = "true" *)  reg  [15:0] dint_b;
	(* syn_preserve = "true" *)  reg  oeall_b;

	(* syn_preserve = "true" *)  reg  rstcnt_c;
	(* syn_preserve = "true" *)  reg  ovlpend_c;
	(* syn_preserve = "true" *)  reg  [15:0] dint_c;
	(* syn_preserve = "true" *)  reg  oeall_c;

	//
	// voted nets of module and local scope registers
	//
	(* syn_keep = "true" *)  wire vt_rstcnt_a;
	(* syn_keep = "true" *)  wire vt_ovlpend_a;
	(* syn_keep = "true" *)  wire [15:0] vt_dint_a;
	(* syn_keep = "true" *)  wire vt_oeall_a;

	(* syn_keep = "true" *)  wire vt_rstcnt_b;
	(* syn_keep = "true" *)  wire vt_ovlpend_b;
	(* syn_keep = "true" *)  wire [15:0] vt_dint_b;
	(* syn_keep = "true" *)  wire vt_oeall_b;

	(* syn_keep = "true" *)  wire vt_rstcnt_c;
	(* syn_keep = "true" *)  wire vt_ovlpend_c;
	(* syn_keep = "true" *)  wire [15:0] vt_dint_c;
	(* syn_keep = "true" *)  wire vt_oeall_c;

//	vote #(.Width(1))  vote_rstcnt_a   (.A(rstcnt_a),  .B(rstcnt_b),  .C(rstcnt_c),  .V(vt_rstcnt_a));
//	vote #(.Width(1))  vote_ovlpend_a  (.A(ovlpend_a), .B(ovlpend_b), .C(ovlpend_c), .V(vt_ovlpend_a));
//	vote #(.Width(16)) vote_dint_a     (.A(dint_a),    .B(dint_b),    .C(dint_c),    .V(vt_dint_a));
//	vote #(.Width(1))  vote_oeall_a    (.A(oeall_a),   .B(oeall_b),   .C(oeall_c),   .V(vt_oeall_a));
//
//	vote #(.Width(1))  vote_rstcnt_b   (.A(rstcnt_a),  .B(rstcnt_b),  .C(rstcnt_c),  .V(vt_rstcnt_b));
//	vote #(.Width(1))  vote_ovlpend_b  (.A(ovlpend_a), .B(ovlpend_b), .C(ovlpend_c), .V(vt_ovlpend_b));
//	vote #(.Width(16)) vote_dint_b     (.A(dint_a),    .B(dint_b),    .C(dint_c),    .V(vt_dint_b));
//	vote #(.Width(1))  vote_oeall_b    (.A(oeall_a),   .B(oeall_b),   .C(oeall_c),   .V(vt_oeall_b));
//
//	vote #(.Width(1))  vote_rstcnt_c   (.A(rstcnt_a),  .B(rstcnt_b),  .C(rstcnt_c),  .V(vt_rstcnt_c));
//	vote #(.Width(1))  vote_ovlpend_c  (.A(ovlpend_a), .B(ovlpend_b), .C(ovlpend_c), .V(vt_ovlpend_c));
//	vote #(.Width(16)) vote_dint_c     (.A(dint_a),    .B(dint_b),    .C(dint_c),    .V(vt_dint_c));
//	vote #(.Width(1))  vote_oeall_c    (.A(oeall_a),   .B(oeall_b),   .C(oeall_c),   .V(vt_oeall_c));

	assign  vt_rstcnt_a   = (rstcnt_a  & rstcnt_b)  | (rstcnt_b  & rstcnt_c)  | (rstcnt_a  & rstcnt_c);  // Majority logic
	assign  vt_ovlpend_a  = (ovlpend_a & ovlpend_b) | (ovlpend_b & ovlpend_c) | (ovlpend_a & ovlpend_c); // Majority logic
	assign  vt_dint_a     = (dint_a    & dint_b)    | (dint_b    & dint_c)    | (dint_a    & dint_c);    // Majority logic
	assign  vt_oeall_a    = (oeall_a   & oeall_b)   | (oeall_b   & oeall_c)   | (oeall_a   & oeall_c);   // Majority logic

	assign  vt_rstcnt_b   = (rstcnt_a  & rstcnt_b)  | (rstcnt_b  & rstcnt_c)  | (rstcnt_a  & rstcnt_c);  // Majority logic
	assign  vt_ovlpend_b  = (ovlpend_a & ovlpend_b) | (ovlpend_b & ovlpend_c) | (ovlpend_a & ovlpend_c); // Majority logic
	assign  vt_dint_b     = (dint_a    & dint_b)    | (dint_b    & dint_c)    | (dint_a    & dint_c);    // Majority logic
	assign  vt_oeall_b    = (oeall_a   & oeall_b)   | (oeall_b   & oeall_c)   | (oeall_a   & oeall_c);   // Majority logic

	assign  vt_rstcnt_c   = (rstcnt_a  & rstcnt_b)  | (rstcnt_b  & rstcnt_c)  | (rstcnt_a  & rstcnt_c);  // Majority logic
	assign  vt_ovlpend_c  = (ovlpend_a & ovlpend_b) | (ovlpend_b & ovlpend_c) | (ovlpend_a & ovlpend_c); // Majority logic
	assign  vt_dint_c     = (dint_a    & dint_b)    | (dint_b    & dint_c)    | (dint_a    & dint_c);    // Majority logic
	assign  vt_oeall_c    = (oeall_a   & oeall_b)   | (oeall_b   & oeall_c)   | (oeall_a   & oeall_c);   // Majority logic

//	assign  vt_rstcnt_a   = rstcnt_a;
//	assign  vt_ovlpend_a  = ovlpend_a;
//	assign  vt_dint_a     = dint_a;
//	assign  vt_oeall_a    = oeall_a;
	
//	assign  vt_rstcnt_b   = rstcnt_b;
//	assign  vt_ovlpend_b  = ovlpend_b;
//	assign  vt_dint_b     = dint_b;
//	assign  vt_oeall_b    = oeall_b;
	
//	assign  vt_rstcnt_c   = rstcnt_c;
//	assign  vt_ovlpend_c  = ovlpend_c;
//	assign  vt_dint_c     = dint_c;
//	assign  vt_oeall_c    = oeall_c;

	//
	// module scope only registers
	//
	(* syn_preserve = "true" *)  reg  data_hldoff_a;
//	(* syn_preserve = "true" *)  reg  [7:1] ooe_a;
	(* syn_preserve = "true" *)  reg  [7:1] oe_2_a;
	(* syn_preserve = "true" *)  reg  doeall_a;
	(* syn_preserve = "true" *)  reg  [7:1] jref_a;
	(* syn_preserve = "true" *)  reg  rstlast_a;
	(* syn_preserve = "true" *)  reg  [15:0] dout_a;

	(* syn_preserve = "true" *)  reg  data_hldoff_b;
//	(* syn_preserve = "true" *)  reg  [7:1] ooe_b;
	(* syn_preserve = "true" *)  reg  [7:1] oe_2_b;
	(* syn_preserve = "true" *)  reg  doeall_b;
	(* syn_preserve = "true" *)  reg  [7:1] jref_b;
	(* syn_preserve = "true" *)  reg  rstlast_b;
	(* syn_preserve = "true" *)  reg  [15:0] dout_b;

	(* syn_preserve = "true" *)  reg  data_hldoff_c;
//	(* syn_preserve = "true" *)  reg  [7:1] ooe_c;
	(* syn_preserve = "true" *)  reg  [7:1] oe_2_c;
	(* syn_preserve = "true" *)  reg  doeall_c;
	(* syn_preserve = "true" *)  reg  [7:1] jref_c;
	(* syn_preserve = "true" *)  reg  rstlast_c;
	(* syn_preserve = "true" *)  reg  [15:0] dout_c;
	

	//
	// voted nets of module scope registers
	//
	(* syn_keep = "true" *)  wire vt_data_hldoff;
//	(* syn_keep = "true" *)  wire [7:1] vt_ooe;
	(* syn_keep = "true" *)  wire [7:1] vt_oe_2;
	(* syn_keep = "true" *)  wire vt_doeall;
	(* syn_keep = "true" *)  wire [7:1] vt_jref;
	(* syn_keep = "true" *)  wire vt_rstlast;
	(* syn_keep = "true" *)  wire [15:0] vt_dout;

//	vote #(.Width(1))  vote_data_hldoff (.A(data_hldoff_a), .B(data_hldoff_b), .C(data_hldoff_c), .V(vt_data_hldoff));
//	vote #(.Width(7))  vote_ooe         (.A(ooe_a),         .B(ooe_b),         .C(ooe_c),         .V(vt_ooe));
//	vote #(.Width(1))  vote_doeall      (.A(doeall_a),      .B(doeall_b),      .C(doeall_c),      .V(vt_doeall));
//	vote #(.Width(7))  vote_jref        (.A(jref_a),        .B(jref_b),        .C(jref_c),        .V(vt_jref));
//	vote #(.Width(1))  vote_rstlast     (.A(rstlast_a),     .B(rstlast_b),     .C(rstlast_c),     .V(vt_rstlast));
//	vote #(.Width(16)) vote_dout        (.A(dout_a),        .B(dout_b),        .C(dout_c),        .V(vt_dout));

	assign  vt_data_hldoff = (data_hldoff_a & data_hldoff_b) | (data_hldoff_b & data_hldoff_c) | (data_hldoff_a & data_hldoff_c); // Majority logic
//	assign  vt_ooe         = (ooe_a         & ooe_b)         | (ooe_b         & ooe_c)         | (ooe_a         & ooe_c);         // Majority logic
	assign  vt_oe_2        = (oe_2_a        & oe_2_b)        | (oe_2_b        & oe_2_c)        | (oe_2_a        & oe_2_c);        // Majority logic
	assign  vt_doeall      = (doeall_a      & doeall_b)      | (doeall_b      & doeall_c)      | (doeall_a      & doeall_c);      // Majority logic
	assign  vt_jref        = (jref_a        & jref_b)        | (jref_b        & jref_c)        | (jref_a        & jref_c);        // Majority logic
	assign  vt_rstlast     = (rstlast_a     & rstlast_b)     | (rstlast_b     & rstlast_c)     | (rstlast_a     & rstlast_c);     // Majority logic
	assign  vt_dout        = (dout_a        & dout_b)        | (dout_b        & dout_c)        | (dout_a        & dout_c);        // Majority logic

//	assign  vt_data_hldoff = data_hldoff_a;
//	assign  vt_ooe         = ooe_a;
//	assign  vt_doeall      = doeall_a;
//	assign  vt_jref        = jref_a;
//	assign  vt_rstlast     = rstlast_a;
//	assign  vt_dout        = dout_a;


	initial begin
		jref_a  = 7'h00;
		ffrfl_a = 7'h00;
		dodat_a = 1'b0;
		st_tail_a = 1'b0;
		dint_ovlp_b_a = 1'b1;
		
		jref_b  = 7'h00;
		ffrfl_b = 7'h00;
		dodat_b = 1'b0;
		st_tail_b = 1'b0;
		dint_ovlp_b_b = 1'b1;
		
		jref_c  = 7'h00;
		ffrfl_c = 7'h00;
		dodat_c = 1'b0;
		st_tail_c = 1'b0;
		dint_ovlp_b_c = 1'b1;
	end		

	//
	// local scope nets implemented with "assigns"
	//
	(* syn_keep = "true" *)  wire [7:1] errd_rst_a;
	(* syn_keep = "true" *)  wire oehdra_a;
	(* syn_keep = "true" *)  wire oehdrb_a;
	(* syn_keep = "true" *)  wire stpop_a;
	(* syn_keep = "true" *)  wire taila_a;
	(* syn_keep = "true" *)  wire tailb_a;
	(* syn_keep = "true" *)  wire done_ce_a;
	(* syn_keep = "true" *)  wire dodatx_a;
	(* syn_keep = "true" *)  wire [7:1] fffl_a;  // FIFO full flags AND'd with not kill
	(* syn_keep = "true" *)  wire [7:1] oe_a;
	(* syn_keep = "true" *)  wire [5:1] oe6_a;
	(* syn_keep = "true" *)  wire [5:1] rovr_a;
	(* syn_keep = "true" *)  wire [5:1] rst_rovr_a;
	(* syn_keep = "true" *)  wire jrdff_a;
	(* syn_keep = "true" *)  wire rst_dov_a;
	(* syn_keep = "true" *)  wire doneovlp_a;
	(* syn_keep = "true" *)  wire poplast_a;
	(* syn_keep = "true" *)  wire okdata_a;
	(* syn_keep = "true" *)  wire okdata_rst_a;
	
	(* syn_keep = "true" *)  wire [7:1] errd_rst_b;
	(* syn_keep = "true" *)  wire oehdra_b;
	(* syn_keep = "true" *)  wire oehdrb_b;
	(* syn_keep = "true" *)  wire stpop_b;
	(* syn_keep = "true" *)  wire taila_b;
	(* syn_keep = "true" *)  wire tailb_b;
	(* syn_keep = "true" *)  wire done_ce_b;
	(* syn_keep = "true" *)  wire dodatx_b;
	(* syn_keep = "true" *)  wire [7:1] fffl_b;  // FIFO full flags AND'd with not kill
	(* syn_keep = "true" *)  wire [7:1] oe_b;
	(* syn_keep = "true" *)  wire [5:1] oe6_b;
	(* syn_keep = "true" *)  wire [5:1] rovr_b;
	(* syn_keep = "true" *)  wire [5:1] rst_rovr_b;
	(* syn_keep = "true" *)  wire jrdff_b;
	(* syn_keep = "true" *)  wire rst_dov_b;
	(* syn_keep = "true" *)  wire doneovlp_b;
	(* syn_keep = "true" *)  wire poplast_b;
	(* syn_keep = "true" *)  wire okdata_b;
	(* syn_keep = "true" *)  wire okdata_rst_b;
	
	(* syn_keep = "true" *)  wire [7:1] errd_rst_c;
	(* syn_keep = "true" *)  wire oehdra_c;
	(* syn_keep = "true" *)  wire oehdrb_c;
	(* syn_keep = "true" *)  wire stpop_c;
	(* syn_keep = "true" *)  wire taila_c;
	(* syn_keep = "true" *)  wire tailb_c;
	(* syn_keep = "true" *)  wire done_ce_c;
	(* syn_keep = "true" *)  wire dodatx_c;
	(* syn_keep = "true" *)  wire [7:1] fffl_c;  // FIFO full flags AND'd with not kill
	(* syn_keep = "true" *)  wire [7:1] oe_c;
	(* syn_keep = "true" *)  wire [5:1] oe6_c;
	(* syn_keep = "true" *)  wire [5:1] rovr_c;
	(* syn_keep = "true" *)  wire [5:1] rst_rovr_c;
	(* syn_keep = "true" *)  wire jrdff_c;
	(* syn_keep = "true" *)  wire rst_dov_c;
	(* syn_keep = "true" *)  wire doneovlp_c;
	(* syn_keep = "true" *)  wire poplast_c;
	(* syn_keep = "true" *)  wire okdata_c;
	(* syn_keep = "true" *)  wire okdata_rst_c;

	//
	// local scope nets implemented in "always" blocks
	//
	(* syn_keep = "true" *)  reg  [7:1] prio_act_a;
	(* syn_keep = "true" *)  reg  [15:0] d_htov_a;
	(* syn_keep = "true" *)  reg  [11:0] cdcd_a;
	
	(* syn_keep = "true" *)  reg  [7:1] prio_act_b;
	(* syn_keep = "true" *)  reg  [15:0] d_htov_b;
	(* syn_keep = "true" *)  reg  [11:0] cdcd_b;
	
	(* syn_keep = "true" *)  reg  [7:1] prio_act_c;
	(* syn_keep = "true" *)  reg  [15:0] d_htov_c;
	(* syn_keep = "true" *)  reg  [11:0] cdcd_c;
	
	//
	// module and local scope nets
	//
	(* syn_keep = "true" *)  wire busy_ce_a;
	(* syn_keep = "true" *)  wire startread_a;
	(* syn_keep = "true" *)  wire [7:1] done_a;
	(* syn_keep = "true" *)  wire oeovlp_a;
	(* syn_keep = "true" *)  wire pop_rst_a;
	(* syn_keep = "true" *)  wire readovlp_a;
	(* syn_keep = "true" *)  wire last_a;

	(* syn_keep = "true" *)  wire busy_ce_b;
	(* syn_keep = "true" *)  wire startread_b;
	(* syn_keep = "true" *)  wire [7:1] done_b;
	(* syn_keep = "true" *)  wire oeovlp_b;
	(* syn_keep = "true" *)  wire pop_rst_b;
	(* syn_keep = "true" *)  wire readovlp_b;
	(* syn_keep = "true" *)  wire last_b;

	(* syn_keep = "true" *)  wire busy_ce_c;
	(* syn_keep = "true" *)  wire startread_c;
	(* syn_keep = "true" *)  wire [7:1] done_c;
	(* syn_keep = "true" *)  wire oeovlp_c;
	(* syn_keep = "true" *)  wire pop_rst_c;
	(* syn_keep = "true" *)  wire readovlp_c;
	(* syn_keep = "true" *)  wire last_c;

	//
	// Combinatorial logic for local scope variables
	//
	assign errd_rst_a   = vt_davnodata_a | vt_datanoend_a | done_a;
	assign oehdra_a     = |{vt_oehdr_a[4:1]};
	assign oehdrb_a     = |{vt_oehdr_a[8:5]};
	assign stpop_a      = (vt_oehdr_a[4] & !head_d12) | vt_tail8_1_a;
	assign taila_a      = |{vt_tail_a[4:1]};
	assign tailb_a      = |{vt_tail_a[8:5]};
	assign done_ce_a    = last_a & !vt_ovlpend_a; // leading edge of last;
	assign dodatx_a     = vt_dodat_a && !readovlp_a;
	assign fffl_a       = ~killdcd & vt_ffrfl_a;
	assign oe_a         = prio_act_a & vt_rdy_a & ~{2'b0,vt_ovr_a};
	assign oe6_a        = prio_act_a[5:1] & vt_ovr_a;
	assign rovr_a       = {5{RST}} | vt_oe6_1_a;
	assign rst_rovr_a   = {5{RST}} | vt_rovr_1_a;
	assign jrdff_a      = vt_rdffnxt_2_a & ~vt_rdffnxt_3_a;
	assign rst_dov_a    = pop_rst_a | vt_rdoneovlp_a;
	assign doneovlp_a   = pop_rst_a | vt_dn_ovlp_a;
	assign poplast_a    = pop_rst_a | last_a;
	assign okdata_a     = (ddcnt == 9'd448);
	assign okdata_rst_a = RST | okdata_a;

	assign errd_rst_b   = vt_davnodata_b | vt_datanoend_b | done_b;
	assign oehdra_b     = |{vt_oehdr_b[4:1]};
	assign oehdrb_b     = |{vt_oehdr_b[8:5]};
	assign stpop_b      = (vt_oehdr_b[4] & !head_d12) | vt_tail8_1_b;
	assign taila_b      = |{vt_tail_b[4:1]};
	assign tailb_b      = |{vt_tail_b[8:5]};
	assign done_ce_b    = last_b & !vt_ovlpend_b; // leading edge of last;
	assign dodatx_b     = vt_dodat_b && !readovlp_b;
	assign fffl_b       = ~killdcd & vt_ffrfl_b;
	assign oe_b         = prio_act_b & vt_rdy_b & ~{2'b0,vt_ovr_b};
	assign oe6_b        = prio_act_b[5:1] & vt_ovr_b;
	assign rovr_b       = {5{RST}} | vt_oe6_1_b;
	assign rst_rovr_b   = {5{RST}} | vt_rovr_1_b;
	assign jrdff_b      = vt_rdffnxt_2_b & ~vt_rdffnxt_3_b;
	assign rst_dov_b    = pop_rst_b | vt_rdoneovlp_b;
	assign doneovlp_b   = pop_rst_b | vt_dn_ovlp_b;
	assign poplast_b    = pop_rst_b | last_b;
	assign okdata_b     = (ddcnt == 9'd448);
	assign okdata_rst_b = RST | okdata_b;

	assign errd_rst_c   = vt_davnodata_c | vt_datanoend_c | done_c;
	assign oehdra_c     = |{vt_oehdr_c[4:1]};
	assign oehdrb_c     = |{vt_oehdr_c[8:5]};
	assign stpop_c      = (vt_oehdr_c[4] & !head_d12) | vt_tail8_1_c;
	assign taila_c      = |{vt_tail_c[4:1]};
	assign tailb_c      = |{vt_tail_c[8:5]};
	assign done_ce_c    = last_c & !vt_ovlpend_c; // leading edge of last;
	assign dodatx_c     = vt_dodat_c && !readovlp_c;
	assign fffl_c       = ~killdcd & vt_ffrfl_c;
	assign oe_c         = prio_act_c & vt_rdy_c & ~{2'b0,vt_ovr_c};
	assign oe6_c        = prio_act_c[5:1] & vt_ovr_c;
	assign rovr_c       = {5{RST}} | vt_oe6_1_c;
	assign rst_rovr_c   = {5{RST}} | vt_rovr_1_c;
	assign jrdff_c      = vt_rdffnxt_2_c & ~vt_rdffnxt_3_c;
	assign rst_dov_c    = pop_rst_c | vt_rdoneovlp_c;
	assign doneovlp_c   = pop_rst_c | vt_dn_ovlp_c;
	assign poplast_c    = pop_rst_c | last_c;
	assign okdata_c     = (ddcnt == 9'd448);
	assign okdata_rst_c = RST | okdata_c;

	//
	// Combinatorial logic for module scope variables
	//
	// used in local scope and module scope
	assign busy_ce_a    = vt_gdav_3_a & !vt_busy_a;
	assign startread_a  = vt_busy_a & !vt_busy_1_a;
	assign done_a       = {7{pop_rst_a}} | vt_dn_oe_a;
	assign oeovlp_a     = vt_rdyovlp_a & |oe6_a;
	assign pop_rst_a    = vt_pop_a | RST;
	assign readovlp_a   = vt_ooeovlp_a & ~vt_ovlpend_a;
	assign last_a       = readovlp_a ? preovlast : prefflast;

	assign busy_ce_b    = vt_gdav_3_b & !vt_busy_b;
	assign startread_b  = vt_busy_b & !vt_busy_1_b;
	assign done_b       = {7{pop_rst_b}} | vt_dn_oe_b;
	assign oeovlp_b     = vt_rdyovlp_b & |oe6_b;
	assign pop_rst_b    = vt_pop_b | RST;
	assign readovlp_b   = vt_ooeovlp_b & ~vt_ovlpend_b;
	assign last_b       = readovlp_b ? preovlast : prefflast;

//	assign busy_ce_a    = vt_gdav_3_c & !vt_busy_c;
//	assign startread_a  = vt_busy_c & !vt_busy_1_c;
//	assign done_a       = {7{pop_rst_c}} | vt_dn_oe_c;
//	assign oeovlp_a     = vt_rdyovlp_c & |oe6_c;
//	assign pop_rst_a    = vt_pop_c | RST;
//	assign readovlp_a   = vt_ooeovlp_c & ~vt_ovlpend_c;
//	assign last_a       = readovlp_c ? preovlast : prefflast;

//	assign busy_ce_b    = vt_gdav_3_c & !vt_busy_c;
//	assign startread_b  = vt_busy_c & !vt_busy_1_c;
//	assign done_b       = {7{pop_rst_c}} | vt_dn_oe_c;
//	assign oeovlp_b     = vt_rdyovlp_c & |oe6_c;
//	assign pop_rst_b    = vt_pop_c | RST;
//	assign readovlp_b   = vt_ooeovlp_c & ~vt_ovlpend_c;
//	assign last_b       = readovlp_c ? preovlast : prefflast;

	assign busy_ce_c    = vt_gdav_3_c & !vt_busy_c;
	assign startread_c  = vt_busy_c & !vt_busy_1_c;
	assign done_c       = {7{pop_rst_c}} | vt_dn_oe_c;
	assign oeovlp_c     = vt_rdyovlp_c & |oe6_c;
	assign pop_rst_c    = vt_pop_c | RST;
	assign readovlp_c   = vt_ooeovlp_c & ~vt_ovlpend_c;
	assign last_c       = readovlp_c ? preovlast : prefflast;

	//
	// assignments for module level nets
	assign busy_ce    = busy_ce_a;
	assign startread  = startread_a;
	assign done       = done_a;
	assign OEOVLP     = oeovlp_a;
	assign pop_rst    = pop_rst_a;
	assign readovlp   = readovlp_a;
	assign last       = last_a;

	// used in module scope only
	assign tail_rst   = RST | vt_tail_a[1];
	assign ovlpwen    = ~DCFEB_IN_USE & (~pop_rst_a & ~vt_disdav_a & ~vt_dint_ovlp_b_a & vt_oedata_a);
//	assign ovlpwen    = ~pop_rst_a & ~vt_disdav_a & ~vt_dint_ovlp_b_a & vt_oedata_a;
//	assign ovlpwen    = 1'b0;
	assign crcen      = ~vt_disdav_a & (vt_oedata_a | vt_ht_crc_a);
	assign ovlplast   = {{3{vt_ovlpend_a}},vt_dint_a[15]};
	assign ooe_i      = oe_a;

	assign rstcnt  = vt_rstcnt_a;
	assign ovlpend = vt_ovlpend_a;
	assign dint    = vt_dint_a;
	assign oeall   = vt_oeall_a;

	assign data_hldoff = vt_data_hldoff;
//	assign ooe         = vt_ooe;
	assign ooe_1 = vt_oe_1_a;
	assign ooe_2 = vt_oe_2;
	assign doeall      = vt_doeall;
	assign jref        = vt_jref;
	assign rstlast     = vt_rstlast;

	assign clrcrc = vt_oehdr_a[1];

	assign POPBRAM = vt_popbram_a;
	assign DAV = vt_dav_a;
	assign DOUT = vt_dout;

//	
//add always blocks for nets... prio_act, d_htov, cdcd
//

	always @*
	begin
		if(vt_dodat_a)
			casex(vt_r_act_a)
				7'b1xxxxxx : prio_act_a = 7'b1000000; // ALCT
				7'b01xxxxx : prio_act_a = 7'b0100000; // TMB
				7'b00xxxx1 : prio_act_a = 7'b0000001; // CFEB 1
				7'b00xxx10 : prio_act_a = 7'b0000010; // CFEB 2
				7'b00xx100 : prio_act_a = 7'b0000100; // CFEB 3
				7'b00x1000 : prio_act_a = 7'b0001000; // CFEB 4
				7'b0010000 : prio_act_a = 7'b0010000; // CFEB 5
				default    : prio_act_a = 7'b0000000;
			endcase
		else
			prio_act_a = 7'b0000000;
		if(vt_dodat_b)
			casex(vt_r_act_b)
				7'b1xxxxxx : prio_act_b = 7'b1000000; // ALCT
				7'b01xxxxx : prio_act_b = 7'b0100000; // TMB
				7'b00xxxx1 : prio_act_b = 7'b0000001; // CFEB 1
				7'b00xxx10 : prio_act_b = 7'b0000010; // CFEB 2
				7'b00xx100 : prio_act_b = 7'b0000100; // CFEB 3
				7'b00x1000 : prio_act_b = 7'b0001000; // CFEB 4
				7'b0010000 : prio_act_b = 7'b0010000; // CFEB 5
				default    : prio_act_b = 7'b0000000;
			endcase
		else
			prio_act_b = 7'b0000000;
		if(vt_dodat_c)
			casex(vt_r_act_c)
				7'b1xxxxxx : prio_act_c = 7'b1000000; // ALCT
				7'b01xxxxx : prio_act_c = 7'b0100000; // TMB
				7'b00xxxx1 : prio_act_c = 7'b0000001; // CFEB 1
				7'b00xxx10 : prio_act_c = 7'b0000010; // CFEB 2
				7'b00xx100 : prio_act_c = 7'b0000100; // CFEB 3
				7'b00x1000 : prio_act_c = 7'b0001000; // CFEB 4
				7'b0010000 : prio_act_c = 7'b0010000; // CFEB 5
				default    : prio_act_c = 7'b0000000;
			endcase
		else
			prio_act_c = 7'b0000000;
	end

	always @*
	begin
		case({readovlp_a,vt_tail_a,vt_oehdr_a})
			17'b00000000000000001 : d_htov_a = {3'b100,head_d12,l1cnt[11:0]};                                                     // Header 1 code 8 or 9
			17'b00000000000000010 : d_htov_a = {3'b100,head_d12,l1cnt[23:12]};                                                    // Header 2 code 8 or 9
			17'b00000000000000100 : d_htov_a = {3'b100,head_d12,DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[15:11]}; // Header 3 code 8 or 9
			17'b00000000000001000 : d_htov_a = {3'b100,head_d12,BXN[11:0]};                                                       // Header 4 code 8 or 9
			17'b00000000000010000 : d_htov_a = {4'hA,           DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[5:1]};   // Header 5 code A
			17'b00000000000100000 : d_htov_a = {4'hA,           DAQMBID[11:0]};                                                   // Header 6 code A
			17'b00000000001000000 : d_htov_a = {4'hA,           DAVACT[16],DAVACT[0],DAVACT[10:6],BXN[4:0]};                      // Header 7 code A
			17'b00000000010000000 : d_htov_a = {4'hA,           CFEBBX[3:0],fmt_ver[1:0],fendaverr,l1cnt[4:0]};                   // Header 8 code A
			17'b00000000100000000 : d_htov_a = {4'hF,           vt_datanoend_a[7],BXN[4:0],l1cnt[5:0]};                           // Tail 1 code F
			17'b00000001000000000 : d_htov_a = {4'hF,           DAVACT[10:6],2'b00,vt_datanoend_a[5:1]};                          // Tail 2 code F
			17'b00000010000000000 : d_htov_a = {4'hF,           fffl_a[3:1],vt_davnodata_a[6],STATUS[14:7]};                      // Tail 3 code F
			17'b00000100000000000 : d_htov_a = {4'hF,           vt_davnodata_a[7],2'b00,vt_davnodata_a[5:1],2'b00,fffl_a[5:4]};   // Tail 4 code F
			17'b00001000000000000 : d_htov_a = {4'hE,           fffl_a[7:6],ffhf[7:6],vt_datanoend_a[6],2'b11,ffhf[5:1]};         // Tail 5 code E
			17'b00010000000000000 : d_htov_a = {4'hE,           DAQMBID[11:0]};                                                   // Tail 6 code E
			17'b00100000000000000 : d_htov_a = {4'hE,           12'h000};                                                         // Tail 7 code E CRC place holder
			17'b01000000000000000 : d_htov_a = {4'hE,           12'h000};                                                         // Tail 8 code E CRC place holder
			17'b10000000000000000 : d_htov_a =  doutx[15:0];                                                                      // Read overlap FIFO
			default               : d_htov_a = 16'h0000;
		endcase
		case({readovlp_b,vt_tail_b,vt_oehdr_b})
			17'b00000000000000001 : d_htov_b = {3'b100,head_d12,l1cnt[11:0]};                                                     // Header 1 code 8 or 9
			17'b00000000000000010 : d_htov_b = {3'b100,head_d12,l1cnt[23:12]};                                                    // Header 2 code 8 or 9
			17'b00000000000000100 : d_htov_b = {3'b100,head_d12,DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[15:11]}; // Header 3 code 8 or 9
			17'b00000000000001000 : d_htov_b = {3'b100,head_d12,BXN[11:0]};                                                       // Header 4 code 8 or 9
			17'b00000000000010000 : d_htov_b = {4'hA,           DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[5:1]};   // Header 5 code A
			17'b00000000000100000 : d_htov_b = {4'hA,           DAQMBID[11:0]};                                                   // Header 6 code A
			17'b00000000001000000 : d_htov_b = {4'hA,           DAVACT[16],DAVACT[0],DAVACT[10:6],BXN[4:0]};                      // Header 7 code A
			17'b00000000010000000 : d_htov_b = {4'hA,           CFEBBX[3:0],fmt_ver[1:0],fendaverr,l1cnt[4:0]};                   // Header 8 code A
			17'b00000000100000000 : d_htov_b = {4'hF,           vt_datanoend_b[7],BXN[4:0],l1cnt[5:0]};                           // Tail 1 code F
			17'b00000001000000000 : d_htov_b = {4'hF,           DAVACT[10:6],2'b00,vt_datanoend_b[5:1]};                          // Tail 2 code F
			17'b00000010000000000 : d_htov_b = {4'hF,           fffl_b[3:1],vt_davnodata_b[6],STATUS[14:7]};                      // Tail 3 code F
			17'b00000100000000000 : d_htov_b = {4'hF,           vt_davnodata_b[7],2'b00,vt_davnodata_b[5:1],2'b00,fffl_b[5:4]};   // Tail 4 code F
			17'b00001000000000000 : d_htov_b = {4'hE,           fffl_b[7:6],ffhf[7:6],vt_datanoend_b[6],2'b11,ffhf[5:1]};         // Tail 5 code E
			17'b00010000000000000 : d_htov_b = {4'hE,           DAQMBID[11:0]};                                                   // Tail 6 code E
			17'b00100000000000000 : d_htov_b = {4'hE,           12'h000};                                                         // Tail 7 code E CRC place holder
			17'b01000000000000000 : d_htov_b = {4'hE,           12'h000};                                                         // Tail 8 code E CRC place holder
			17'b10000000000000000 : d_htov_b =  doutx[15:0];                                                                      // Read overlap FIFO
			default               : d_htov_b = 16'h0000;
		endcase
		case({readovlp_c,vt_tail_c,vt_oehdr_c})
			17'b00000000000000001 : d_htov_c = {3'b100,head_d12,l1cnt[11:0]};                                                     // Header 1 code 8 or 9
			17'b00000000000000010 : d_htov_c = {3'b100,head_d12,l1cnt[23:12]};                                                    // Header 2 code 8 or 9
			17'b00000000000000100 : d_htov_c = {3'b100,head_d12,DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[15:11]}; // Header 3 code 8 or 9
			17'b00000000000001000 : d_htov_c = {3'b100,head_d12,BXN[11:0]};                                                       // Header 4 code 8 or 9
			17'b00000000000010000 : d_htov_c = {4'hA,           DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[5:1]};   // Header 5 code A
			17'b00000000000100000 : d_htov_c = {4'hA,           DAQMBID[11:0]};                                                   // Header 6 code A
			17'b00000000001000000 : d_htov_c = {4'hA,           DAVACT[16],DAVACT[0],DAVACT[10:6],BXN[4:0]};                      // Header 7 code A
			17'b00000000010000000 : d_htov_c = {4'hA,           CFEBBX[3:0],fmt_ver[1:0],fendaverr,l1cnt[4:0]};                   // Header 8 code A
			17'b00000000100000000 : d_htov_c = {4'hF,           vt_datanoend_c[7],BXN[4:0],l1cnt[5:0]};                           // Tail 1 code F
			17'b00000001000000000 : d_htov_c = {4'hF,           DAVACT[10:6],2'b00,vt_datanoend_c[5:1]};                          // Tail 2 code F
			17'b00000010000000000 : d_htov_c = {4'hF,           fffl_c[3:1],vt_davnodata_c[6],STATUS[14:7]};                      // Tail 3 code F
			17'b00000100000000000 : d_htov_c = {4'hF,           vt_davnodata_c[7],2'b00,vt_davnodata_c[5:1],2'b00,fffl_c[5:4]};   // Tail 4 code F
			17'b00001000000000000 : d_htov_c = {4'hE,           fffl_c[7:6],ffhf[7:6],vt_datanoend_c[6],2'b11,ffhf[5:1]};         // Tail 5 code E
			17'b00010000000000000 : d_htov_c = {4'hE,           DAQMBID[11:0]};                                                   // Tail 6 code E
			17'b00100000000000000 : d_htov_c = {4'hE,           12'h000};                                                         // Tail 7 code E CRC place holder
			17'b01000000000000000 : d_htov_c = {4'hE,           12'h000};                                                         // Tail 8 code E CRC place holder
			17'b10000000000000000 : d_htov_c =  doutx[15:0];                                                                      // Read overlap FIFO
			default               : d_htov_c = 16'h0000;
		endcase
	end

	always @*
	begin
		case({vt_dtail8_a,vt_dtail7_a})
			2'b01   : cdcd_a = {regcrc[22],regcrc[10:0]};  // Tail 7 CRC
			2'b10   : cdcd_a = {regcrc[23],regcrc[21:11]}; // Tail 8 CRC
			default : cdcd_a = 12'h000;
		endcase
		case({vt_dtail8_b,vt_dtail7_b})
			2'b01   : cdcd_b = {regcrc[22],regcrc[10:0]};  // Tail 7 CRC
			2'b10   : cdcd_b = {regcrc[23],regcrc[21:11]}; // Tail 8 CRC
			default : cdcd_b = 12'h000;
		endcase
		case({vt_dtail8_c,vt_dtail7_c})
			2'b01   : cdcd_c = {regcrc[22],regcrc[10:0]};  // Tail 7 CRC
			2'b10   : cdcd_c = {regcrc[23],regcrc[21:11]}; // Tail 8 CRC
			default : cdcd_c = 12'h000;
		endcase
	end


//
//add always blocks for registers: local scope -- 42 signals, modulue and local scope -- 4 signals, and module scope only -- 6 signals
//

////////////////////////////////////////////////////////////////////////////
//
// 40 MHz clock domain registers
//
////////////////////////////////////////////////////////////////////////////

	always @(posedge CLKCMS or posedge pop_rst_a)
	begin
		if(pop_rst_a)
			begin
				gdav_1_a     <= 1'b0;
				datanoend_a  <= 7'h00;
			end
		else
			begin
				gdav_1_a <= GEMPTY_B;
				if(vt_rstcnt_a) datanoend_a  <= oe_a;
			end
	end

	always @(posedge CLKCMS or posedge pop_rst_b)
	begin
		if(pop_rst_b)
			begin
				gdav_1_b     <= 1'b0;
				datanoend_b  <= 7'h00;
			end
		else
			begin
				gdav_1_b <= GEMPTY_B;
				if(vt_rstcnt_b) datanoend_b  <= oe_b;
			end
	end

	always @(posedge CLKCMS or posedge pop_rst_c)
	begin
		if(pop_rst_c)
			begin
				gdav_1_c     <= 1'b0;
				datanoend_c  <= 7'h00;
			end
		else
			begin
				gdav_1_c <= GEMPTY_B;
				if(vt_rstcnt_c) datanoend_c  <= oe_c;
			end
	end
//

	always @(posedge CLKCMS or posedge RST)
	begin
		if(RST)
			popbram_a  <= 1'b0;
		else
			popbram_a <= vt_pbram_a;
		if(RST)
			popbram_b  <= 1'b0;
		else
			popbram_b <= vt_pbram_b;
		if(RST)
			popbram_c  <= 1'b0;
		else
			popbram_c <= vt_pbram_c;
	end

	always @(posedge CLKCMS)
	begin
		rstcnt_a <= qnoend[12];
		rstcnt_b <= qnoend[12];
		rstcnt_c <= qnoend[12];
	end



////////////////////////////////////////////////////////////////////////////
//
// 80 MHz clock domain registers
//
////////////////////////////////////////////////////////////////////////////

	always @(posedge CLKDDU or posedge pop_rst_a)
	begin
		if(pop_rst_a)
			begin
				gdav_2_a  <= 1'b0;
				gdav_3_a  <= 1'b0;
				busy_a    <= 1'b0;
				busy_1_a  <= 1'b0;
				oehdr_a   <= 8'h00;
				tail_a    <= 8'h00;
				tail8_1_a <= 1'b0;
				dav_a     <= 1'b0;
				rdyovlp_a <= 1'b0;
				oeall_1_a <= 1'b0;
				oedata_a  <= 1'b0;
				dn_oe_a   <= 7'h00;
				davnodata_a <= 7'h00;
			end
		else
			begin
				if(GIGAEN) gdav_2_a <= vt_gdav_1_a;
				gdav_3_a <= vt_gdav_2_a;
				busy_a   <= vt_gdav_3_a;
				busy_1_a <= vt_busy_a;
				oehdr_a  <= {vt_oehdr_a[7:1],startread_a};
				tail_a   <= {vt_tail_a[7:1],vt_st_tail_a};
				tail8_1_a <= vt_tail_a[8];
				dav_a     <= ~vt_disdav_a & (vt_oehdtl_a | vt_oedata_a);
				rdyovlp_a <= vt_dodat_a;
				oeall_1_a <= vt_oeall_a;
				oedata_a  <= vt_oeall_1_a;
				if(done_ce_a) dn_oe_a   <= oe_a;
				if(okdata_a && !vt_dodat_a) davnodata_a <= vt_r_act_a & fifordy_b;
			end
	end

	always @(posedge CLKDDU or posedge pop_rst_b)
	begin
		if(pop_rst_b)
			begin
				gdav_2_b  <= 1'b0;
				gdav_3_b  <= 1'b0;
				busy_b    <= 1'b0;
				busy_1_b  <= 1'b0;
				oehdr_b   <= 8'h00;
				tail_b    <= 8'h00;
				tail8_1_b <= 1'b0;
				dav_b     <= 1'b0;
				rdyovlp_b <= 1'b0;
				oeall_1_b <= 1'b0;
				oedata_b  <= 1'b0;
				dn_oe_b   <= 7'h00;
				davnodata_b <= 7'h00;
			end
		else
			begin
				if(GIGAEN) gdav_2_b <= vt_gdav_1_b;
				gdav_3_b <= vt_gdav_2_b;
				busy_b   <= vt_gdav_3_b;
				busy_1_b <= vt_busy_b;
				oehdr_b  <= {vt_oehdr_b[7:1],startread_b};
				tail_b   <= {vt_tail_b[7:1],vt_st_tail_b};
				tail8_1_b <= vt_tail_b[8];
				dav_b     <= ~vt_disdav_b & (vt_oehdtl_b | vt_oedata_b);
				rdyovlp_b <= vt_dodat_b;
				oeall_1_b <= vt_oeall_b;
				oedata_b  <= vt_oeall_1_b;
				if(done_ce_b) dn_oe_b   <= oe_b;
				if(okdata_b && !vt_dodat_b) davnodata_b <= vt_r_act_b & fifordy_b;
			end
	end

	always @(posedge CLKDDU or posedge pop_rst_c)
	begin
		if(pop_rst_c)
			begin
				gdav_2_c  <= 1'b0;
				gdav_3_c  <= 1'b0;
				busy_c    <= 1'b0;
				busy_1_c  <= 1'b0;
				oehdr_c   <= 8'h00;
				tail_c    <= 8'h00;
				tail8_1_c <= 1'b0;
				dav_c     <= 1'b0;
				rdyovlp_c <= 1'b0;
				oeall_1_c <= 1'b0;
				oedata_c  <= 1'b0;
				dn_oe_c   <= 7'h00;
				davnodata_c <= 7'h00;
			end
		else
			begin
				if(GIGAEN) gdav_2_c <= vt_gdav_1_c;
				gdav_3_c <= vt_gdav_2_c;
				busy_c   <= vt_gdav_3_c;
				busy_1_c <= vt_busy_c;
				oehdr_c  <= {vt_oehdr_c[7:1],startread_c};
				tail_c   <= {vt_tail_c[7:1],vt_st_tail_c};
				tail8_1_c <= vt_tail_c[8];
				dav_c     <= ~vt_disdav_c & (vt_oehdtl_c | vt_oedata_c);
				rdyovlp_c <= vt_dodat_c;
				oeall_1_c <= vt_oeall_c;
				oedata_c  <= vt_oeall_1_c;
				if(done_ce_c) dn_oe_c   <= oe_c;
				if(okdata_c && !vt_dodat_c) davnodata_c <= vt_r_act_c & fifordy_b;
			end
	end
//

	always @(posedge CLKDDU or posedge okdata_rst_a)
	begin
		if(okdata_rst_a)
			data_hldoff_a  <= 1'b0;
		else
			if(vt_oehdr_a[8])
				data_hldoff_a <= vt_busy_a;
	end

	always @(posedge CLKDDU or posedge okdata_rst_b)
	begin
		if(okdata_rst_b)
			data_hldoff_b  <= 1'b0;
		else
			if(vt_oehdr_b[8])
				data_hldoff_b <= vt_busy_b;
	end

	always @(posedge CLKDDU or posedge okdata_rst_c)
	begin
		if(okdata_rst_c)
			data_hldoff_c  <= 1'b0;
		else
			if(vt_oehdr_c[8])
				data_hldoff_c <= vt_busy_c;
	end
//

	always @(posedge CLKDDU)
	begin
		if(pop_rst_a) // Synchronous reset
			pop_m2_a <= 1'b0;
		else
			if(stpop_a)
				pop_m2_a <= 1'b1;
				
		if(pop_rst_b) // Synchronous reset
			pop_m2_b <= 1'b0;
		else
			if(stpop_b)
				pop_m2_b <= 1'b1;
				
		if(pop_rst_c) // Synchronous reset
			pop_m2_c <= 1'b0;
		else
			if(stpop_c)
				pop_m2_c <= 1'b1;
	end
	
	always @(posedge CLKDDU or posedge RST)
	begin
		if(RST)
			begin
				pop_m1_a  <= 1'b0;
				pop_a     <= 1'b0;
				oehdtl_a  <= 1'b0;
				ovlpend_a <= 1'b0;
				ht_crc_a  <= 1'b0;
			end
		else
			begin
				pop_m1_a  <= vt_pop_m2_a;
				pop_a     <= vt_pop_m1_a;
				oehdtl_a  <= oehdra_a | oehdrb_a | taila_a | tailb_a;
				ovlpend_a <= last_a;
				ht_crc_a  <= oehdra_a | oehdrb_a | taila_a;
			end
		if(RST)
			begin
				pop_m1_b  <= 1'b0;
				pop_b     <= 1'b0;
				oehdtl_b  <= 1'b0;
				ovlpend_b <= 1'b0;
				ht_crc_b  <= 1'b0;
			end
		else
			begin
				pop_m1_b  <= vt_pop_m2_b;
				pop_b     <= vt_pop_m1_b;
				oehdtl_b  <= oehdra_b | oehdrb_b | taila_b | tailb_b;
				ovlpend_b <= last_b;
				ht_crc_b  <= oehdra_b | oehdrb_b | taila_b;
			end
		if(RST)
			begin
				pop_m1_c  <= 1'b0;
				pop_c     <= 1'b0;
				oehdtl_c  <= 1'b0;
				ovlpend_c <= 1'b0;
				ht_crc_c  <= 1'b0;
			end
		else
			begin
				pop_m1_c  <= vt_pop_m2_c;
				pop_c     <= vt_pop_m1_c;
				oehdtl_c  <= oehdra_c | oehdrb_c | taila_c | tailb_c;
				ovlpend_c <= last_c;
				ht_crc_c  <= oehdra_c | oehdrb_c | taila_c;
			end
	end
//

	always @(posedge CLKDDU or posedge vt_tail_a[1])
	begin
		if(vt_tail_a[1])
			begin
				dodat_a   <= 1'b0;
				st_tail_a <= 1'b0;
			end
		else
			begin
				dodat_a   <= okdata_a;
				if(vt_busy_a && ~|vt_r_act_a)
					st_tail_a <= vt_dodat_a;  // start tail when no more fifos have data for this event
			end
	end

	always @(posedge CLKDDU or posedge vt_tail_b[1])
	begin
		if(vt_tail_b[1])
			begin
				dodat_b   <= 1'b0;
				st_tail_b <= 1'b0;
			end
		else
			begin
				dodat_b   <= okdata_b;
				if(vt_busy_b && ~|vt_r_act_b)
					st_tail_b <= vt_dodat_b;  // start tail when no more fifos have data for this event
			end
	end

	always @(posedge CLKDDU or posedge vt_tail_c[1])
	begin
		if(vt_tail_c[1])
			begin
				dodat_c   <= 1'b0;
				st_tail_c <= 1'b0;
			end
		else
			begin
				dodat_c   <= okdata_c;
				if(vt_busy_c && ~|vt_r_act_c)
					st_tail_c <= vt_dodat_c;  // start tail when no more fifos have data for this event
			end
	end
//

	always @(posedge CLKDDU or posedge popbram_rst)
	begin
		if(popbram_rst)
			pbram_a  <= 1'b0;
		else
			if(stpop_a)
				pbram_a <= 1'b1;
				
		if(popbram_rst)
			pbram_b  <= 1'b0;
		else
			if(stpop_b)
				pbram_b <= 1'b1;
				
		if(popbram_rst)
			pbram_c  <= 1'b0;
		else
			if(stpop_c)
				pbram_c <= 1'b1;
	end
	
// Loop 1 to 7...

	for(i=1;i<8;i=i+1) begin: idx1
		always @(posedge CLKDDU or posedge STATUS[i+33])
		begin
			if(STATUS[i+33])
				ffrfl_a[i] <= 1'b0;
			else
				if(STATUS[i+26])
					ffrfl_a[i] <= STATUS[i+26];
					
			if(STATUS[i+33])
				ffrfl_b[i] <= 1'b0;
			else
				if(STATUS[i+26])
					ffrfl_b[i] <= STATUS[i+26];
					
			if(STATUS[i+33])
				ffrfl_c[i] <= 1'b0;
			else
				if(STATUS[i+26])
					ffrfl_c[i] <= STATUS[i+26];
		end
//

		always @(posedge CLKDDU or posedge pop_rst_a)
		begin
			if(pop_rst_a)
				rdy_a[i] <= 1'b0;
			else
				if(!fifordy_b[i])
					rdy_a[i] <= vt_dodat_a;
		end
		
		always @(posedge CLKDDU or posedge pop_rst_b)
		begin
			if(pop_rst_b)
				rdy_b[i] <= 1'b0;
			else
				if(!fifordy_b[i])
					rdy_b[i] <= vt_dodat_b;
		end
		
		always @(posedge CLKDDU or posedge pop_rst_c)
		begin
			if(pop_rst_c)
				rdy_c[i] <= 1'b0;
			else
				if(!fifordy_b[i])
					rdy_c[i] <= vt_dodat_c;
		end
//

		always @(posedge CLKDDU or posedge done_a[i])
		begin
			if(done_a[i])
				begin
//					ooe_a[i] <= 1'b0;
					oe_1_a[i] <= 1'b0;
					oe_2_a[i] <= 1'b0;
				end
			else
				begin
//					ooe_a[i] <= oe_a[i];
					oe_1_a[i] <= oe_a[i];
					oe_2_a[i] <= vt_oe_1_a[i];
				end
		end
		
		always @(posedge CLKDDU or posedge done_b[i])
		begin
			if(done_b[i])
				begin
//					ooe_b[i] <= 1'b0;
					oe_1_b[i] <= 1'b0;
					oe_2_b[i] <= 1'b0;
				end
			else
				begin
//					ooe_b[i] <= oe_b[i];
					oe_1_b[i] <= oe_b[i];
					oe_2_b[i] <= vt_oe_1_b[i];
				end
		end
		
		always @(posedge CLKDDU or posedge done_c[i])
		begin
			if(done_c[i])
				begin
//					ooe_c[i] <= 1'b0;
					oe_1_c[i] <= 1'b0;
					oe_2_c[i] <= 1'b0;
				end
			else
				begin
//					ooe_c[i] <= oe_c[i];
					oe_1_c[i] <= oe_c[i];
					oe_2_c[i] <= vt_oe_1_c[i];
				end
		end
//

		always @(posedge CLKDDU)
		begin
			if(JOEF[i]) jref_a[i] <= jrdff_a;
			if(JOEF[i]) jref_b[i] <= jrdff_b;
			if(JOEF[i]) jref_c[i] <= jrdff_c;
		end
	end
	
// Loop 1 to 5...

	for(i=1;i<6;i=i+1) begin: idx2

		always @(posedge CLKDDU or posedge rst_rovr_a[i])
		begin
			if(rst_rovr_a[i])
				oe6_1_a[i] <= 1'b0;
			else
				if(done_ce_a) 
					oe6_1_a[i] <= oe6_a[i];
		end
		always @(posedge CLKDDU or posedge rst_rovr_b[i])
		begin
			if(rst_rovr_b[i])
				oe6_1_b[i] <= 1'b0;
			else
				if(done_ce_b) 
					oe6_1_b[i] <= oe6_b[i];
		end
		always @(posedge CLKDDU or posedge rst_rovr_c[i])
		begin
			if(rst_rovr_c[i])
				oe6_1_c[i] <= 1'b0;
			else
				if(done_ce_c) 
					oe6_1_c[i] <= oe6_c[i];
		end
//
		
		always @(posedge CLKDDU or posedge rovr_a[i])
		begin
			if(rovr_a[i])
				begin
					ovrin_a[i] <= 1'b0;
					ovr_a[i]   <= 1'b0;
				end
			else
				begin
					if(!DCFEB_IN_USE && oe_a[i] && last_a) ovrin_a[i] <= ~ovlpin_b;
//					if(oe_a[i] && last_a) ovrin_a[i] <= ~ovlpin_b;
					ovr_a[i]  								<= vt_ovrin_a[i];
				end
		end
		
		always @(posedge CLKDDU or posedge rovr_b[i])
		begin
			if(rovr_b[i])
				begin
					ovrin_b[i] <= 1'b0;
					ovr_b[i]   <= 1'b0;
				end
			else
				begin
					if(!DCFEB_IN_USE && oe_b[i] && last_b) ovrin_b[i] <= ~ovlpin_b;
//					if(oe_b[i] && last_b) ovrin_b[i] <= ~ovlpin_b;
					ovr_b[i]  								<= vt_ovrin_b[i];
				end
		end
		
		always @(posedge CLKDDU or posedge rovr_c[i])
		begin
			if(rovr_c[i])
				begin
					ovrin_c[i] <= 1'b0;
					ovr_c[i]   <= 1'b0;
				end
			else
				begin
					if(!DCFEB_IN_USE && oe_c[i] && last_c) ovrin_c[i] <= ~ovlpin_b;
//					if(oe_c[i] && last_c) ovrin_c[i] <= ~ovlpin_b;
					ovr_c[i]  								<= vt_ovrin_c[i];
				end
		end
//

		always @(posedge CLKDDU or posedge errd_rst_a[i])
		begin
			if(errd_rst_a[i])
				r_act_a[i] <= 1'b0;
			else
				if(busy_ce_a)
					r_act_a[i] <= DAVACT[i];
		end

		always @(posedge CLKDDU or posedge errd_rst_b[i])
		begin
			if(errd_rst_b[i])
				r_act_b[i] <= 1'b0;
			else
				if(busy_ce_b)
					r_act_b[i] <= DAVACT[i];
		end

		always @(posedge CLKDDU or posedge errd_rst_c[i])
		begin
			if(errd_rst_c[i])
				r_act_c[i] <= 1'b0;
			else
				if(busy_ce_c)
					r_act_c[i] <= DAVACT[i];
		end


	end

// elements 6 and 7 of r_act have out of sequence DAVACT
//
	always @(posedge CLKDDU or posedge errd_rst_a[6])
	begin
		if(errd_rst_a[6])
			r_act_a[6] <= 1'b0;
		else
			if(busy_ce_a)
				r_act_a[6] <= DAVACT[0];
	end
	always @(posedge CLKDDU or posedge errd_rst_b[6])
	begin
		if(errd_rst_b[6])
			r_act_b[6] <= 1'b0;
		else
			if(busy_ce_b)
				r_act_b[6] <= DAVACT[0];
	end
	always @(posedge CLKDDU or posedge errd_rst_c[6])
	begin
		if(errd_rst_c[6])
			r_act_c[6] <= 1'b0;
		else
			if(busy_ce_c)
				r_act_c[6] <= DAVACT[0];
	end

	always @(posedge CLKDDU or posedge errd_rst_a[7])
	begin
		if(errd_rst_a[7])
			r_act_a[7] <= 1'b0;
		else
			if(busy_ce_a)
				r_act_a[7] <= DAVACT[16];
	end
	always @(posedge CLKDDU or posedge errd_rst_b[7])
	begin
		if(errd_rst_b[7])
			r_act_b[7] <= 1'b0;
		else
			if(busy_ce_b)
				r_act_b[7] <= DAVACT[16];
	end
	always @(posedge CLKDDU or posedge errd_rst_c[7])
	begin
		if(errd_rst_c[7])
			r_act_c[7] <= 1'b0;
		else
			if(busy_ce_c)
				r_act_c[7] <= DAVACT[16];
	end
//

	always @(negedge CLKDDU) // Negative edge
	begin
		rstlast_a   <= prefflast;
		rstlast_b   <= prefflast;
		rstlast_c   <= prefflast;
	end

	always @(posedge CLKDDU)
	begin
		rovr_1_a      <= rovr_a;
		disdav_a      <= |(prio_act_a & fifordy_b);
		rdffnxt_1_a   <= RDFFNXT;
		rdffnxt_2_a   <= vt_rdffnxt_1_a;
		rdffnxt_3_a   <= vt_rdffnxt_2_a;
		rdoneovlp_a   <= doneovlp_a;
		dint_a        <= dodatx_a  ? da_in : d_htov_a;
		dout_a        <= vt_dtail78_a ? {vt_dint_a[15:12],cdcd_a}  : vt_dint_a;
		dint_ovlp_b_a <= ovlpin_b;
		dtail7_a      <= vt_tail_a[7];
		dtail8_a      <= vt_dtail7_a;
		dtail78_a     <= vt_tail_a[7] | vt_tail_a[8];

		rovr_1_b      <= rovr_b;
		disdav_b      <= |(prio_act_b & fifordy_b);
		rdffnxt_1_b   <= RDFFNXT;
		rdffnxt_2_b   <= vt_rdffnxt_1_b;
		rdffnxt_3_b   <= vt_rdffnxt_2_b;
		rdoneovlp_b   <= doneovlp_b;
		dint_b        <= dodatx_b  ? da_in : d_htov_b;
		dout_b        <= vt_dtail78_b ? {vt_dint_b[15:12],cdcd_b}  : vt_dint_b;
		dint_ovlp_b_b <= ovlpin_b;
		dtail7_b      <= vt_tail_b[7];
		dtail8_b      <= vt_dtail7_b;
		dtail78_b     <= vt_tail_b[7] | vt_tail_b[8];

		rovr_1_c      <= rovr_c;
		disdav_c      <= |(prio_act_c & fifordy_b);
		rdffnxt_1_c   <= RDFFNXT;
		rdffnxt_2_c   <= vt_rdffnxt_1_c;
		rdffnxt_3_c   <= vt_rdffnxt_2_c;
		rdoneovlp_c   <= doneovlp_c;
		dint_c        <= dodatx_c  ? da_in : d_htov_c;
		dout_c        <= vt_dtail78_c ? {vt_dint_c[15:12],cdcd_c}  : vt_dint_c;
		dint_ovlp_b_c <= ovlpin_b;
		dtail7_c      <= vt_tail_c[7];
		dtail8_c      <= vt_dtail7_c;
		dtail78_c     <= vt_tail_c[7] | vt_tail_c[8];
	end
//

	always @(posedge CLKDDU or posedge poplast_a)
	begin
		if(poplast_a)
			begin
				oeall_a  <= 1'b0;
				doeall_a <= 1'b0;
			end
		else
			begin
//				oeall_a  <= oeovlp_a | |oe_a;
				oeall_a  <= oeovlp_a | |vt_oe_1_a;
				doeall_a <= vt_oeall_a;
			end
	end

	always @(posedge CLKDDU or posedge poplast_b)
	begin
		if(poplast_b)
			begin
				oeall_b  <= 1'b0;
				doeall_b <= 1'b0;
			end
		else
			begin
//				oeall_b  <= oeovlp_b | |oe_b;
				oeall_b  <= oeovlp_b | |vt_oe_1_b;
				doeall_b <= vt_oeall_b;
			end
	end

	always @(posedge CLKDDU or posedge poplast_c)
	begin
		if(poplast_c)
			begin
				oeall_c  <= 1'b0;
				doeall_c <= 1'b0;
			end
		else
			begin
//				oeall_c  <= oeovlp_c | |oe_c;
				oeall_c  <= oeovlp_c | |vt_oe_1_c;
				doeall_c <= vt_oeall_c;
			end
	end
//

	always @(posedge CLKDDU or posedge rst_dov_a)
	begin
		if(rst_dov_a)
			dn_ovlp_a <= 1'b0;
		else
			if(done_ce_a) dn_ovlp_a <= oeovlp_a;
	end

	always @(posedge CLKDDU or posedge rst_dov_b)
	begin
		if(rst_dov_b)
			dn_ovlp_b <= 1'b0;
		else
			if(done_ce_b) dn_ovlp_b <= oeovlp_b;
	end

	always @(posedge CLKDDU or posedge rst_dov_c)
	begin
		if(rst_dov_c)
			dn_ovlp_c <= 1'b0;
		else
			if(done_ce_c) dn_ovlp_c <= oeovlp_c;
	end
//

	always @(posedge CLKDDU or posedge doneovlp_a)
	begin
		if(doneovlp_a)
			ooeovlp_a <= 1'b0;
		else
			ooeovlp_a <= oeovlp_a;
	end

	always @(posedge CLKDDU or posedge doneovlp_b)
	begin
		if(doneovlp_b)
			ooeovlp_b <= 1'b0;
		else
			ooeovlp_b <= oeovlp_b;
	end

	always @(posedge CLKDDU or posedge doneovlp_c)
	begin
		if(doneovlp_c)
			ooeovlp_c <= 1'b0;
		else
			ooeovlp_c <= oeovlp_c;
	end

end
else
begin : control_logic_no_TMR

	//
	// local scope registers
	//
	reg  gdav_1_r;
	reg  gdav_2_r;
	reg  gdav_3_r;
	reg  [7:1] datanoend_r;
	reg  popbram_r;
	reg  busy_r;
	reg  busy_1_r;
	reg  [8:1] oehdr_r;
	reg  [8:1] tail_r;
	reg  tail8_1_r;
	reg  dav_r;
	reg  rdyovlp_r;
	reg  oeall_1_r;
	reg  oeall_2_r;
	reg  oeall_3_r;
	reg  oedata_r;
	reg  [7:1] dn_oe_r;
	reg  [7:1] davnodata_r;
	reg  pop_m2_r;
	reg  pop_m1_r;
	reg  pop_r;
	reg  oehdtl_r;
	reg  ht_crc_r;
//	reg  dodat_r;
//	reg  st_tail_r;
	reg  pbram_r;
	reg  [7:1] ffrfl_r; // raw FIFO full flags
	reg  [7:1] rdy_r;
	reg  [5:1] oe6_1_r;
	reg  [5:1] ovrin_r;
	reg  [5:1] ovr_r;
	reg  [7:1] r_act_r;
	reg  [5:1] rovr_1_r;
	reg  disdav_r;
	reg  rdffnxt_1_r;
	reg  rdffnxt_2_r;
	reg  rdffnxt_3_r;
	reg  rdoneovlp_r;
	reg  dint_ovlp_b_r;
	reg  dtail7_r;
	reg  dtail8_r;
	reg  dtail78_r;
	reg  dn_ovlp_r;
	reg  ooeovlp_r;
	reg  strt_tmo_r;
	reg  strt_tmo_1_r;
	reg  ce_b4_1_r;
	reg  ce_b5_1_r;
	reg  ce_l1l_1_r;
	reg  ce_l1h_1_r;
	reg  [15:0] b4_hdr_r;
	reg  [15:0] b5_hdr_r;
	reg  [23:0] l1a_r;
	reg  [23:0] l1a_savd_r [5:1];
	//reg  done_ce_1_r;
	//reg  done_ce_2_r;
	reg  [7:1] prio_act_1_r;
	reg  trans_tora_1_r;
	reg  trans_tora_2_r;
	reg  new_tora_r;
	reg  new_cfeb_r;
	reg  new_event_r;
	reg [7:0] extnd_mt_r;
	reg inv_data_1_r;
	reg inv_data_2_r;
	//
	//Data pipeline registers from the fifo
	//
	reg  alct_flg_r;
	reg  tmb_flg_r;
	reg  [15:0] da_pipe1_r;
	reg  [15:0] da_pipe2_r;
	reg  [15:0] tmb_in_1_r;
	reg  [15:0] tmb_in_2_r;
	reg  [15:0] alct_in_1_r;
	reg  [15:0] alct_in_2_r;
	reg  [15:0] cfeb1_in_1_r;
	reg  [15:0] cfeb1_in_2_r;
	reg  [15:0] cfeb2_in_1_r;
	reg  [15:0] cfeb2_in_2_r;
	reg  [15:0] cfeb3_in_1_r;
	reg  [15:0] cfeb3_in_2_r;
	reg  [15:0] cfeb4_in_1_r;
	reg  [15:0] cfeb4_in_2_r;
	reg  [15:0] cfeb5_in_1_r;
	reg  [15:0] cfeb5_in_2_r;
	
	//
	// module scope and local scope registers
	//
	reg  rstcnt_r;
	reg  ovlpend_r;
	reg  [15:0] dint_r;
	reg  oeall_r;


	//
	// module scope only registers
	//
//	reg  data_hldoff_r;
	reg  [7:1] oe_1_r;
	reg  [7:1] oe_2_r;
//	reg  [7:1] ooe_r;
	reg  doeall_r;
	reg  [7:1] jref_r;
	reg  rstlast_r;
	reg  [15:0] dout_r;

	initial begin
		jref_r  = 7'h00;
		ffrfl_r = 7'h00;
//		dodat_r = 1'b0;
//		st_tail_r = 1'b0;
		dint_ovlp_b_r = 1'b1;
	end		

	//
	// local scope nets
	//
	reg  [15:0] d_htov_i;
	reg  [11:0] cdcd_i;

	wire [7:1] errd_rst_i;
	wire err_akn_i;
	wire oehdra_i;
	wire oehdrb_i;
	wire header_end_i;
	wire stpop_i;
	wire taila_i;
	wire tailb_i;
	wire done_ce_i;
	wire dodatx_i;
	wire [7:1] fffl_i;  // FIFO full flags AND'd with not kill
	wire [7:1] oe_i;
	wire data_ce_i;
	wire [5:1] oe6_i;
	wire [5:1] rovr_i;
	wire [5:1] rst_rovr_i;
	wire jrdff_i;
	wire rst_dov_i;
	wire doneovlp_i;
	wire poplast_i;
//	wire okdata_i;
//	wire okdata_rst_i;
	wire go_i;
	wire gob5_i;
	wire eoe_i;
	wire l1a_eq_i;
	wire l1a_lt_i;
	wire b4_present_i;
	wire missing_dat_i;
	wire ce_b4_i;
	wire ce_b5_i;
	wire ce_l1l_i;
	wire ce_l1h_i;
	wire stmo_ce_i;
	wire data_hldoff_i;
	wire cfeb_act_i;
	wire alct_tmb_act_i;
	wire dodat_i;
	wire do_err_i;
	wire dochk_i;
	wire st_tail_i;
	wire cap_l1a_i;
	wire trans_l1a_i;
	wire mt_i;
	wire clr_done_i;
	wire act_chk_i;
	wire alct_res_i;
	wire tmb_res_i;
	wire trans_tora_i;
	wire trans_flg_i;
	wire proc_data_i;

	//
	// module and local scope nets
	//
	reg  [7:1] prio_act_i;
	wire busy_ce_i;
	wire startread_i;
	wire [7:1] done_i;
	wire oeovlp_i;
	wire pop_rst_i;
	wire readovlp_i;
	wire last_i;
	wire tail_rst_i;
	wire inprog_i;
	wire ff_re_i;
	wire noend_error_i;
	wire flushing_i;


	//
	// Combinatorial logic for local scope variables
	//
	assign errd_rst_i   = davnodata_r | datanoend_r | done_i;
	assign err_akn_i	  = |(datanoend_r & prio_act_1_r);
	assign oehdra_i     = |{oehdr_r[4:1]};
	assign oehdrb_i     = |{oehdr_r[8:5]};
	assign header_end_i = oehdr_r[8];
	assign stpop_i      = (oehdr_r[4] & !head_d12) | tail8_1_r;
	assign taila_i      = |{tail_r[4:1]};
	assign tailb_i      = |{tail_r[8:5]};
	assign done_ce_i    = (last_i & !ovlpend_r) & dodat_i & (|(prio_act_i & ~fifordy_b)); // leading edge of last;
	assign dodatx_i     = dodat_i && !readovlp_i;
	assign fffl_i         = ~killdcd & ffrfl_r;
	assign oe_i         = prio_act_i & rdy_r & ~{2'b00,ovr_r};
	assign oe6_i        = prio_act_i[5:1] & ovr_r;
	assign rovr_i       = {5{RST}} | oe6_1_r;
	assign rst_rovr_i   = {5{RST}} | rovr_1_r;
	assign jrdff_i      = rdffnxt_2_r & ~rdffnxt_3_r;
	assign rst_dov_i    = pop_rst_i | rdoneovlp_r;
	assign doneovlp_i   = pop_rst_i | dn_ovlp_r;
	assign poplast_i    = pop_rst_i | last_i;
//	assign okdata_i     = (ddcnt == 9'd448) || ((ddcnt == 9'd5) && |(r_act_r & ~fifordy_b));  //bgb test mod for start timeout
//	assign okdata_rst_i = RST | okdata_i;
	assign go_i         = |oe_i;
	assign gob5_i       = |oe_i && (DATAIN[15:0] == 16'hc5b5);
	assign eoe_i        = inprog_i && ~|r_act_r;
	assign l1a_eq_i     = (b4_hdr_r == 16'hc4b4) && (l1a_r == l1cnt);
	assign l1a_lt_i     = (b4_hdr_r == 16'hc4b4) && (l1a_r < l1cnt);
	assign b4_present_i = (b4_hdr_r == 16'hc4b4);
	assign stmo_ce_i    = strt_tmo_r & ~strt_tmo_1_r;
	assign cfeb_act_i   = |((r_act_r & ~fifordy_b) & 7'b0011111 & prio_act_i); //CFEB mask
	assign alct_tmb_act_i = |((r_act_r & ~fifordy_b) & 7'b1100000 & prio_act_i); //ALCT_TMB mask
	assign mt_i         = |(prio_act_i & fifordy_b);
	assign alct_res_i	  = trans_tora_i & |(7'b1000000 & prio_act_i);
	assign tmb_res_i	  = trans_tora_i & |(7'b0100000 & prio_act_i);
	assign trans_flg_i   = alct_flg_r & prio_act_i[7] | tmb_flg_r & prio_act_i[6];

	//
	// Combinatorial logic for module scope variables
	//
	// used in local scope and module scope
	assign busy_ce_i    = gdav_3_r & !busy_r;
	assign startread_i  = busy_r & !busy_1_r;
	assign done_i       = {7{pop_rst_i}} | dn_oe_r;
	assign oeovlp_i     = rdyovlp_r & |oe6_i;
	assign pop_rst_i    = pop_r | RST;
	assign readovlp_i   = ooeovlp_r & ~ovlpend_r;
	assign last_i       = readovlp_i ? preovlast : prefflast;
	assign tail_rst_i   = RST | tail_r[1];
	
	
	//
	// assignments for module level nets
	assign busy_ce    = busy_ce_i;
	assign startread  = startread_i;
	assign done       = done_i;
	assign OEOVLP     = oeovlp_i;
	assign pop_rst    = pop_rst_i;
	assign readovlp   = readovlp_i;
	assign last       = last_i;
	assign tail_rst   = tail_rst_i;
	assign inprog     = inprog_i;
	assign ff_re       = ff_re_i;
	assign flushing    = flushing_i;
//	assign okdata     = okdata_i;
	assign dodat      = dodat_i;
	assign prio_act   = prio_act_i;
	assign data_ce    = data_ce_i;
	assign noend_error = noend_error_i;

	// used in module scope only
	assign ovlpwen    = ~DCFEB_IN_USE & (~pop_rst_i & ~disdav_r & ~dint_ovlp_b_r & oedata_r);
//	assign ovlpwen    = ~pop_rst_i & ~disdav_r & ~dint_ovlp_b_r & oedata_r;
	assign crcen      = ~disdav_r & (oedata_r | ht_crc_r);
	assign ovlplast   = {{3{ovlpend_r}},dint_r[15]};
	assign ooe_i      = oe_i;

	assign rstcnt = rstcnt_r;
	assign ovlpend = ovlpend_r;
	assign dint = dint_r;
	assign oeall = oeall_r;
	
//	assign data_hldoff = data_hldoff_r;
//	assign ooe = ooe_r;
	assign ooe_1 = oe_1_r;
	assign ooe_2 = oe_2_r;
	assign doeall = doeall_r;
	assign jref = jref_r;
	assign rstlast = rstlast_r;
	
	assign clrcrc = oehdr_r[1];

	assign POPBRAM = popbram_r;
	assign DAV = dav_r;
	assign DOUT = dout_r;
	
	initial begin
	new_tora_r = 1'b0;
	new_cfeb_r = 1'b0;
	end

	always @(negedge CLKDDU or negedge inprog) //Negative edge
	begin
		if(!inprog)
			begin
				new_tora_r <= 1'b0; //new TMB or ALCT
				new_cfeb_r <= 1'b0;
			end
		else
			if(data_ce && !noend_error)
				begin
					new_tora_r  <= (DATAIN[15:0] == 16'hdb0c) || (DATAIN[15:0] == 16'hdb0a); //tmb or alct beginning of data header
					new_cfeb_r  <= (DATAIN[15:0] == 16'hc4b4); //cfeb beginning of data present
				end
	end
	
	always @(negedge CLKDDU or negedge inprog)
	begin
		if(!inprog)
			begin
				new_event_r <= 1'b0;
			end
		else
			if(flushing_i)
				begin
					new_event_r  <= (DATAIN[15:0] == 16'hc4b4); //cfeb beginning of data present
				end
	end

	always @ (posedge CLKDDU)
	begin
		//done_ce_1_r <= done_ce_i;
		//done_ce_2_r <= done_ce_1_r;
		if(prio_act_i[7] && trans_tora_i)begin
			da_pipe1_r <= alct_in_1_r;
			da_pipe2_r <= alct_in_2_r;
		end
		else if(prio_act_i[6] && trans_tora_i)begin
			da_pipe1_r <= tmb_in_1_r;
			da_pipe2_r <= tmb_in_2_r;
		end
		else
		begin
			da_pipe1_r <= da_in;
			da_pipe2_r <= da_pipe1_r;
		end
	
		cfeb1_in_1_r <= (prio_act_i[1] && data_ce_i) ? da_in : cfeb1_in_1_r;
		cfeb2_in_1_r <= (prio_act_i[2] && data_ce_i) ? da_in : cfeb2_in_1_r;
		cfeb3_in_1_r <= (prio_act_i[3] && data_ce_i) ? da_in : cfeb3_in_1_r;
		cfeb4_in_1_r <= (prio_act_i[4] && data_ce_i) ? da_in : cfeb4_in_1_r;
		cfeb5_in_1_r <= (prio_act_i[5] && data_ce_i) ? da_in : cfeb5_in_1_r;
		tmb_in_1_r   <= (prio_act_i[6] && data_ce_i) ? da_in : tmb_in_1_r;
		alct_in_1_r  <= (prio_act_i[7] && data_ce_i) ? da_in : alct_in_1_r;
		
		cfeb1_in_2_r <= (prio_act_i[1] && data_ce_i) ? cfeb1_in_1_r : cfeb1_in_2_r;
		cfeb2_in_2_r <= (prio_act_i[2] && data_ce_i) ? cfeb2_in_1_r : cfeb2_in_2_r;
		cfeb3_in_2_r <= (prio_act_i[3] && data_ce_i) ? cfeb3_in_1_r : cfeb3_in_2_r;
		cfeb4_in_2_r <= (prio_act_i[4] && data_ce_i) ? cfeb4_in_1_r : cfeb4_in_2_r;
		cfeb5_in_2_r <= (prio_act_i[5] && data_ce_i) ? cfeb5_in_1_r : cfeb5_in_2_r;
		tmb_in_2_r   <= (prio_act_i[6] && data_ce_i) ? tmb_in_1_r : tmb_in_2_r;
		alct_in_2_r  <= (prio_act_i[7] && data_ce_i) ? alct_in_1_r : alct_in_2_r;
	end
	
	always @ (posedge CLKDDU)
	begin
		trans_tora_1_r <= trans_tora_i;
		trans_tora_2_r <= trans_tora_1_r;
	end
	
	always @ (posedge CLKDDU or posedge alct_res_i)
	begin
		if(alct_res_i)
			alct_flg_r <= 1'b0;
		else
			if(new_tora_r & noend_error_i & data_ce_i & prio_act_i[7])
				alct_flg_r <= |(7'b1000000 & prio_act_i);
	end
	
	always @ (posedge CLKDDU or posedge tmb_res_i)
	begin
		if(tmb_res_i)
			tmb_flg_r  <= 1'b0;
		else
			if(new_tora_r & noend_error_i & data_ce_i & prio_act_i[6])
				tmb_flg_r  <= |(7'b0100000 & prio_act_i);
	end

	always @*
	begin
		if(dodat_i || dochk_i || act_chk_i || do_err_i)
			casex(r_act_r)
				7'b1xxxxxx : prio_act_i = 7'b1000000; // ALCT
				7'b01xxxxx : prio_act_i = 7'b0100000; // TMB
				7'b00xxxx1 : prio_act_i = 7'b0000001; // CFEB 1
				7'b00xxx10 : prio_act_i = 7'b0000010; // CFEB 2
				7'b00xx100 : prio_act_i = 7'b0000100; // CFEB 3
				7'b00x1000 : prio_act_i = 7'b0001000; // CFEB 4
				7'b0010000 : prio_act_i = 7'b0010000; // CFEB 5
				default    : prio_act_i = 7'b0000000;
			endcase
		else
			prio_act_i = 7'b0000000;
	end

	always @*
	begin
		case({readovlp_i,tail_r,oehdr_r})
			17'b00000000000000001 : d_htov_i = {3'b100,head_d12,l1cnt[11:0]};                                                     // Header 1 code 8 or 9
			17'b00000000000000010 : d_htov_i = {3'b100,head_d12,l1cnt[23:12]};                                                    // Header 2 code 8 or 9
			17'b00000000000000100 : d_htov_i = {3'b100,head_d12,DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[15:11]}; // Header 3 code 8 or 9
			17'b00000000000001000 : d_htov_i = {3'b100,head_d12,BXN[11:0]};                                                       // Header 4 code 8 or 9
			17'b00000000000010000 : d_htov_i = {4'hA,           DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[5:1]};   // Header 5 code A
			17'b00000000000100000 : d_htov_i = {4'hA,           DAQMBID[11:0]};                                                   // Header 6 code A
			17'b00000000001000000 : d_htov_i = {4'hA,           DAVACT[16],DAVACT[0],DAVACT[10:6],BXN[4:0]};                      // Header 7 code A
			17'b00000000010000000 : d_htov_i = {4'hA,           CFEBBX[3:0],fmt_ver[1:0],fendaverr,l1cnt[4:0]};                   // Header 8 code A
			17'b00000000100000000 : d_htov_i = {4'hF,           datanoend_r[7],BXN[4:0],l1cnt[5:0]};                              // Tail 1 code F
			17'b00000001000000000 : d_htov_i = {4'hF,           DAVACT[10:6],2'b00,datanoend_r[5:1]};                             // Tail 2 code F
			17'b00000010000000000 : d_htov_i = {4'hF,           fffl_i[3:1],davnodata_r[6],STATUS[14:7]};                           // Tail 3 code F
			17'b00000100000000000 : d_htov_i = {4'hF,           davnodata_r[7],2'b00,davnodata_r[5:1],2'b00,fffl_i[5:4]};           // Tail 4 code F
			17'b00001000000000000 : d_htov_i = {4'hE,           fffl_i[7:6],ffhf[7:6],datanoend_r[6],2'b11,ffhf[5:1]};                // Tail 5 code E
			17'b00010000000000000 : d_htov_i = {4'hE,           DAQMBID[11:0]};                                                   // Tail 6 code E
			17'b00100000000000000 : d_htov_i = {4'hE,           12'h000};                                                         // Tail 7 code E CRC place holder
			17'b01000000000000000 : d_htov_i = {4'hE,           12'h000};                                                         // Tail 8 code E CRC place holder
			17'b10000000000000000 : d_htov_i =  doutx[15:0];                                                                      // Read overlap FIFO
			default               : d_htov_i = 16'h0000;
		endcase
	end

	always @*
	begin
		case({dtail8_r,dtail7_r})
			2'b01   : cdcd_i = {regcrc[22],regcrc[10:0]};  // Tail 7 CRC
			2'b10   : cdcd_i = {regcrc[23],regcrc[21:11]}; // Tail 8 CRC
			default : cdcd_i = 12'h000;
		endcase
	end

////////////////////////////////////////////////////////////////////////////
//
// 40 MHz clock domain registers
//
////////////////////////////////////////////////////////////////////////////

	always @(posedge CLKCMS or posedge pop_rst_i)
	begin
		if(pop_rst_i)
			gdav_1_r     <= 1'b0;
		else
			gdav_1_r <= GEMPTY_B;
	end

	always @(posedge CLKCMS or posedge RST)
	begin
		if(RST)
			popbram_r  <= 1'b0;
		else
			popbram_r <= pbram_r;
	end


////////////////////////////////////////////////////////////////////////////
//
// 80 MHz clock domain registers
//
////////////////////////////////////////////////////////////////////////////

	always @(posedge CLKDDU or posedge pop_rst_i)
	begin
		if(pop_rst_i)
			begin
				gdav_2_r  <= 1'b0;
				gdav_3_r  <= 1'b0;
				busy_r    <= 1'b0;
				busy_1_r  <= 1'b0;
				oehdr_r   <= 8'h00;
				tail_r    <= 8'h00;
				tail8_1_r <= 1'b0;
				dav_r     <= 1'b0;
				rdyovlp_r <= 1'b0;
				dn_oe_r   <= 7'h00;
				davnodata_r <= 7'h00;
				prio_act_1_r <= 7'h00;
				datanoend_r  <= 7'h00;
			end
		else
			begin
				if(GIGAEN) gdav_2_r <= gdav_1_r;
				gdav_3_r <= gdav_2_r;
				busy_r   <= gdav_3_r;
				busy_1_r <= busy_r;
				oehdr_r  <= {oehdr_r[7:1],startread_i};
//				tail_r   <= {tail_r[7:1],st_tail_r};
				tail_r   <= {tail_r[7:1],st_tail_i};
				tail8_1_r <= tail_r[8];
				dav_r     <= ~disdav_r & (oehdtl_r | oedata_r);
				rdyovlp_r <= dodat_i;
				if(done_ce_i || clr_done_i) dn_oe_r   <= oe_i;
				if((rstcnt_r && dodat_i) || (rstcnt_r && do_err_i)) datanoend_r  <= datanoend_r | oe_i;
				if(missing_dat_i)
					davnodata_r <= (r_act_r & prio_act_i) | davnodata_r;
				else
					if(stmo_ce_i)
						davnodata_r <= (r_act_r & fifordy_b) | davnodata_r;
				prio_act_1_r <= prio_act_i;
			end
	end
	
	always @(posedge CLKDDU or posedge pop_rst_i or posedge st_tail_i)
	begin
		if(pop_rst_i || st_tail_i)
			begin
				oeall_1_r <= 1'b0;
				oeall_2_r <= 1'b0;
				oeall_3_r <= 1'b0;
				oedata_r  <= 1'b0;
			end
		else
			begin
				oeall_1_r <= oeall_r;
				oeall_2_r <= oeall_1_r;
				oeall_3_r <= (trans_tora_1_r || trans_tora_2_r) ? oeall_r : oeall_2_r;
				oedata_r  <= oeall_3_r;
			end
	end

//	always @(posedge CLKDDU or posedge okdata_rst_i)
//	begin
//		if(okdata_rst_i)
//			data_hldoff_r  <= 1'b0;
//		else
//			if(oehdr_r[8])
//				data_hldoff_r <= busy_r;
//	end
	
	always @(posedge CLKDDU or posedge tail_rst_i)
	begin
		if(tail_rst_i) begin
				strt_tmo_r  <= 1'b0;
				strt_tmo_1_r  <= 1'b0;
			end
		else begin
				if((ddcnt == STMO))	strt_tmo_r <= 1'b1;
				strt_tmo_1_r  <= strt_tmo_r;
			end
	end

	always @(posedge CLKDDU)
	begin
		//use qnoend[8] for simulatiion
		extnd_mt_r  <= {extnd_mt_r[6:0], |(prio_act_i & fifordy_b)};
		rstcnt_r    <= (qnoend[12] | noend_error_i | (&extnd_mt_r & dodat_i)) & ~rstcnt_r & ~err_akn_i; //(timeout | saw new event | fifo empty after 8 clocks)
	end

	always @(posedge CLKDDU)
	begin
		if(pop_rst_i) // Synchronous reset
			pop_m2_r <= 1'b0;
		else
			if(stpop_i)
				pop_m2_r <= 1'b1;
	end
	
	always @(posedge CLKDDU or posedge RST)
	begin
		if(RST)
			begin
				pop_m1_r  <= 1'b0;
				pop_r     <= 1'b0;
				oehdtl_r  <= 1'b0;
				ovlpend_r <= 1'b0;
				ht_crc_r  <= 1'b0;
			end
		else
			begin
				pop_m1_r  <= pop_m2_r;
				pop_r     <= pop_m1_r;
				oehdtl_r  <= oehdra_i | oehdrb_i | taila_i | tailb_i;
				ovlpend_r <= last_i;
				ht_crc_r  <= oehdra_i | oehdrb_i | taila_i;
			end
	end

//	always @(posedge CLKDDU or posedge tail_r[1])
//	begin
//		if(tail_r[1])
//			begin
//				dodat_r   <= 1'b0;
//				st_tail_r <= 1'b0;
//			end
//		else
//			begin
//				dodat_r   <= okdata_i;
//				if(busy_r && ~|r_act_r)
//					st_tail_r <= dodat_r;  // start tail when no more fifos have data for this event
//			end
//	end

	always @(posedge CLKDDU or posedge popbram_rst)
	begin
		if(popbram_rst)
			pbram_r  <= 1'b0;
		else
			if(stpop_i)
				pbram_r <= 1'b1;
	end

	for(i=1;i<8;i=i+1) begin: idx1
		always @(posedge CLKDDU or posedge STATUS[i+33])
		begin
			if(STATUS[i+33])
				ffrfl_r[i] <= 1'b0;
			else
				if(STATUS[i+26])
					ffrfl_r[i] <= STATUS[i+26];
		end
		
		always @(posedge CLKDDU or posedge pop_rst_i)
		begin
			if(pop_rst_i)
				rdy_r[i] <= 1'b0;
			else
				if(!fifordy_b[i])
					rdy_r[i] <= dodat_i || dochk_i || act_chk_i || do_err_i;
		end
		
		always @(posedge CLKDDU or posedge done_i[i])
		begin
			if(done_i[i])
				begin
//					ooe_r[i] <= 1'b0;
					oe_1_r[i] <= 1'b0;
					oe_2_r[i] <= 1'b0;
				end
			else
				begin
//					ooe_r[i] <= oe_i[i];
					oe_1_r[i] <= oe_i[i];
					oe_2_r[i] <= oe_1_r[i];
				end
		end

		always @(posedge CLKDDU)
		begin
			if(JOEF[i]) jref_r[i] <= jrdff_i;
		end
	end
	for(i=1;i<6;i=i+1) begin: idx2
		always @(posedge CLKDDU or posedge rst_rovr_i[i])
		begin
			if(rst_rovr_i[i])
				oe6_1_r[i] <= 1'b0;
			else
				if(done_ce_i) 
					oe6_1_r[i] <= oe6_i[i];
		end
		
		always @(posedge CLKDDU or posedge rovr_i[i])
		begin
			if(rovr_i[i])
				begin
					ovrin_r[i] <= 1'b0;
					ovr_r[i]   <= 1'b0;
				end
			else
				begin
					if(!DCFEB_IN_USE && oe_i[i] && last_i) ovrin_r[i] <= ~ovlpin_b;
//					if(oe_i[i] && last_i) ovrin_r[i] <= ~ovlpin_b;
					ovr_r[i]   <= ovrin_r[i];
//					ovr_r[i]   <= 1'b0;
				end
		end
		
		always @(posedge CLKDDU or posedge errd_rst_i[i])
		begin
			if(errd_rst_i[i])
				r_act_r[i] <= 1'b0;
			else
				if(busy_ce_i)
					r_act_r[i] <= DAVACT[i];
		end

		always @(posedge CLKDDU or posedge RST)
		begin
			if(RST) begin
				l1a_savd_r[i] <= 24'h000000;
				l1a_r       <= 24'h000000;
			end
			else begin
				if(cap_l1a_i && prio_act_i[i]) begin
					l1a_savd_r[i] <= l1a_r;
				end
				if(ce_l1l_i) begin 
					l1a_r[11:0] <= da_in[11:0];
				end
				else if(ce_l1h_i) begin
					l1a_r[23:12] <= da_in[11:0];
				end
				else if(trans_l1a_i && prio_act_i[i]) begin
					l1a_r <= l1a_savd_r[i];
				end
			end
		end
	end

	always @(posedge CLKDDU or posedge errd_rst_i[6])
	begin
		if(errd_rst_i[6])
			r_act_r[6] <= 1'b0;
		else
			if(busy_ce_i)
				r_act_r[6] <= DAVACT[0];
	end
	always @(posedge CLKDDU or posedge errd_rst_i[7])
	begin
		if(errd_rst_i[7])
			r_act_r[7] <= 1'b0;
		else
			if(busy_ce_i)
				r_act_r[7] <= DAVACT[16];
	end

	always @(negedge CLKDDU) // Negative edge
	begin
		rstlast_r   <= prefflast;
	end

	always @(posedge CLKDDU)
	begin
		rovr_1_r      <= rovr_i;
		inv_data_1_r  <= |(prio_act_i & fifordy_b) & proc_data_i;
		inv_data_2_r  <= inv_data_1_r;
		disdav_r      <= inv_data_2_r || data_hldoff_i;
		rdffnxt_1_r    <= RDFFNXT;
		rdffnxt_2_r    <= rdffnxt_1_r;
		rdffnxt_3_r    <= rdffnxt_2_r;
		rdoneovlp_r   <= doneovlp_i;
		//dint_r        <= dodatx_i  ? da_in : d_htov_i;
		dint_r        <= dodatx_i  ? da_pipe2_r : d_htov_i;
		dout_r        <= dtail78_r ? {dint_r[15:12],cdcd_i}  : dint_r;
		dint_ovlp_b_r <= ovlpin_b;
		dtail7_r      <= tail_r[7];
		dtail8_r      <= dtail7_r;
		dtail78_r     <= tail_r[7] | tail_r[8];
	end

	always @(posedge CLKDDU)
	begin
	   ce_b4_1_r  <= ce_b4_i;
	   ce_l1l_1_r <= ce_l1l_i;
	   ce_l1h_1_r <= ce_l1h_i;
	   ce_b5_1_r  <= ce_b5_i;
		if(ce_b4_i)   b4_hdr_r  <= da_in;
		if(ce_b5_i)   b5_hdr_r  <= da_in;
	end

	always @(posedge CLKDDU or posedge poplast_i or posedge st_tail_i)
	begin
		if(poplast_i || st_tail_i)
			begin
				oeall_r  <= 1'b0;
				doeall_r <= 1'b0;
			end
		else
			begin
//				oeall_r  <= oeovlp_i | |oe_i;
				oeall_r  <= oeovlp_i | |oe_1_r;
				doeall_r <= oeall_r;
			end
	end

	always @(posedge CLKDDU or posedge rst_dov_i)
	begin
		if(rst_dov_i)
			dn_ovlp_r <= 1'b0;
		else
			if(done_ce_i) dn_ovlp_r <= oeovlp_i;
	end

	always @(posedge CLKDDU or posedge doneovlp_i)
	begin
		if(doneovlp_i)
			ooeovlp_r <= 1'b0;
		else
			ooeovlp_r <= oeovlp_i;
	end


//
// State machine for checking L1A before processing data
//
L1A_Checker_FSM L1A_Checker_FSM_i (
//outputs from state machine
	.ACT_CHK(act_chk_i),
	.CAP_L1A(cap_l1a_i),
	.CE_B4(ce_b4_i),
	.CE_B5(ce_b5_i),
	.CE_L1L(ce_l1l_i),
	.CE_L1H(ce_l1h_i),
	.CLR_DONE(clr_done_i),
	.DATA_CE(data_ce_i),
	.DATA_HLDOFF(data_hldoff_i),
	.DOCHK(dochk_i),
	.DODAT(dodat_i),
	.DO_ERR(do_err_i),
	.FLUSHING(flushing_i),
	.INPROG(inprog_i),
	.MISSING_DAT(missing_dat_i),
	.NOEND_ERROR(noend_error_i),
	.PROC_DATA(proc_data_i),
	.READ_ENA(ff_re_i),
	.STRT_TAIL(st_tail_i),
	.TRANS_L1A(trans_l1a_i),
	.TRANS_TORA(trans_tora_i),
	//inputs
	//.ALCT_FLG(alct_flg_r),
	.ALCT_TMB_ACT(alct_tmb_act_i),
	.B4_PRESENT(b4_present_i),
	.CFEB_ACT(cfeb_act_i),
	.CLK(CLKDDU),
	.DONE_CE(done_ce_i),
	.EOE(eoe_i),
	.ERR_AKN(err_akn_i),
	//.EXTND_MT(extnd_mt_r),
	.GO(go_i),
	.GOB5(gob5_i),
	.HEADER_END(header_end_i),
	.L1A_EQ(l1a_eq_i),
	.L1A_LT(l1a_lt_i),
	.LAST(last_i),
	.MT(mt_i),
	.NEW_CFEB(new_cfeb_r),
	.NEW_EVENT(new_event_r),
	.NEW_TORA(new_tora_r),
	.PROC_TMO(rstcnt_r),
	.RST(RST),
	.STRT_TMO(strt_tmo_r),
	//.TMB_FLG(tmb_flg_r),
	.TRANS_FLG(trans_flg_i)
);

end
endgenerate

endmodule
