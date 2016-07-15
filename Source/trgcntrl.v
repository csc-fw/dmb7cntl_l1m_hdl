`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:15:31 11/05/2015 
// Design Name: 
// Module Name:    trgcntrl 
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
module trgcntrl #(
	parameter TMR = 0
)
(
	input CLK,
	input CGTRG,
	input BGTRG,
	input CMODE,
	input CALTRGSEL,
	input EAFEB,
	input LAT_12_5US,
	input MTCH_3BX,
	input USE_CLCT,
	input DCFEB_IN_USE,
	input [2:0] OPT_COP_ADJ,
	input [3:0] CLCT_ADJ,
	input [5:0] CSTRIP,
	input [5:0] PRE_LCT_IN,
	input [5:1] CLCT,
	input [3:0] L1FINEDELAY,
	input [5:0] L1LATNCY,
	input [4:0] GPUSHDLY,
	input [7:0] CABLEDLY,
	input [1:0] XL1ADLY,
	input [2:0] KILLINPUT,
	input [3:0] JTRGEN,
	output L1ACFEB,
	output reg GFPUSH,
	output reg LCTERR,
	output [5:0] L1A_MATCH,
	output [5:0] PSH_AFF,
	output [5:0] DLY_AFF,
	output [5:0] PRE_LCT_OUT
);

reg  [5:0] pre_lct_r;
wire [5:0] pre_lct_d;
reg  [5:1] clct_r;
wire [5:0] clct_r6;
wire [5:1] strip_m1;
wire [5:1] strip_m2;
wire [5:1] killcfeb;

wire jcalsel;
wire cal1_sel;
wire cal_mode;
wire all_sel;
reg  bgtrg_1;
wire l1a;
wire killalct;
wire killtmb;

assign cal_mode      = CMODE & CALTRGSEL;
assign jcalsel       = JTRGEN[0] & cal_mode;
assign cal1_sel      = JTRGEN[1] & cal_mode;
assign all_sel       = EAFEB     & ~cal_mode;
assign {strip_m1,PRE_LCT_OUT[0]} = jcalsel ? CSTRIP : pre_lct_d;
assign strip_m2      = all_sel ? {5{PRE_LCT_OUT[0]}} : strip_m1;
assign PRE_LCT_OUT[5:1]  = strip_m2 & ~killcfeb;
assign clct_r6       = {clct_r,|clct_r};
assign l1a           = cal1_sel ? CGTRG : bgtrg_1;

assign killalct = (KILLINPUT == 3'd1);
assign killtmb  = (KILLINPUT == 3'd2);
assign killcfeb = {(KILLINPUT == 3'd7),(KILLINPUT == 3'd6),(KILLINPUT == 3'd5),(KILLINPUT == 3'd4),(KILLINPUT == 3'd3)};

(* IOB = "TRUE" *)
always @(posedge CLK)
begin
	pre_lct_r <= PRE_LCT_IN;
	clct_r    <= CLCT;
	bgtrg_1   <= ~BGTRG;
end

always @(posedge CLK)
begin
	LCTERR <= PRE_LCT_OUT[0] ^ (|PRE_LCT_OUT[5:1]);
	GFPUSH <= l1a;
end

genvar i;
generate
begin
	for(i=0;i<6;i=i+1) begin: idx1
		tmplctdly tmplctdly_i (.CLK(CLK),.DIN(pre_lct_r[i]),.DELAY(CABLEDLY[3:1]),.DOUT(pre_lct_d[i]));
	end
	if(TMR)
	begin
		(* syn_keep = "true" *) wire [5:0] l1mtch_a;
		(* syn_keep = "true" *) wire [5:0] l1mtch_b;
		(* syn_keep = "true" *) wire [5:0] l1mtch_c;
		(* syn_keep = "true" *) wire [5:0] d_lct_out_a;
		(* syn_keep = "true" *) wire [5:0] d_lct_out_b;
		(* syn_keep = "true" *) wire [5:0] d_lct_out_c;
		(* syn_keep = "true" *) wire [5:0] d_push_out_a;
		(* syn_keep = "true" *) wire [5:0] d_push_out_b;
		(* syn_keep = "true" *) wire [5:0] d_push_out_c;
		for(i=0;i<6;i=i+1) begin: idx2
			lctdly  lctdly_a  (.CLK(CLK),.PLCT(PRE_LCT_OUT[i]),.CLCT(clct_r6[i]),.L1A(l1a),.LAT_12_5US(LAT_12_5US),.MTCH_3BX(MTCH_3BX),.USE_CLCT(USE_CLCT),.CLCT_ADJ(CLCT_ADJ),.OPT_COP(OPT_COP_ADJ),.DELAY(L1LATNCY),.XL1ADLY(XL1ADLY),.L1FD(L1FINEDELAY),.DOUT(d_lct_out_a[i]),.L1A_MATCH(l1mtch_a[i]));
			lctdly  lctdly_b  (.CLK(CLK),.PLCT(PRE_LCT_OUT[i]),.CLCT(clct_r6[i]),.L1A(l1a),.LAT_12_5US(LAT_12_5US),.MTCH_3BX(MTCH_3BX),.USE_CLCT(USE_CLCT),.CLCT_ADJ(CLCT_ADJ),.OPT_COP(OPT_COP_ADJ),.DELAY(L1LATNCY),.XL1ADLY(XL1ADLY),.L1FD(L1FINEDELAY),.DOUT(d_lct_out_b[i]),.L1A_MATCH(l1mtch_b[i]));
			lctdly  lctdly_c  (.CLK(CLK),.PLCT(PRE_LCT_OUT[i]),.CLCT(clct_r6[i]),.L1A(l1a),.LAT_12_5US(LAT_12_5US),.MTCH_3BX(MTCH_3BX),.USE_CLCT(USE_CLCT),.CLCT_ADJ(CLCT_ADJ),.OPT_COP(OPT_COP_ADJ),.DELAY(L1LATNCY),.XL1ADLY(XL1ADLY),.L1FD(L1FINEDELAY),.DOUT(d_lct_out_c[i]),.L1A_MATCH(l1mtch_c[i]));
			pushdly pushdly_a (.CLK(CLK),.DIN(d_lct_out_a[i]),.DELAY(GPUSHDLY),.DOUT(d_push_out_a[i]));
			pushdly pushdly_b (.CLK(CLK),.DIN(d_lct_out_b[i]),.DELAY(GPUSHDLY),.DOUT(d_push_out_b[i]));
			pushdly pushdly_c (.CLK(CLK),.DIN(d_lct_out_c[i]),.DELAY(GPUSHDLY),.DOUT(d_push_out_c[i]));
		end
		
		vote #(.Width(6)) l1mtch_vt    (.A(l1mtch_a),    .B(l1mtch_b),    .C(l1mtch_c),    .V(L1A_MATCH));
		vote #(.Width(6)) lctdly_vt    (.A(d_lct_out_a), .B(d_lct_out_b), .C(d_lct_out_c), .V(DLY_AFF));
		vote #(.Width(6)) pushmtch_vt  (.A(d_push_out_a),.B(d_push_out_b),.C(d_push_out_c),.V(PSH_AFF));
	end
	else
	begin
		wire [5:0] d_lct_out_i;
		for(i=0;i<6;i=i+1) begin: idx2
			lctdly  lctdly_i  (.CLK(CLK),.PLCT(PRE_LCT_OUT[i]),.CLCT(clct_r6[i]),.L1A(l1a),.LAT_12_5US(LAT_12_5US),.MTCH_3BX(MTCH_3BX),.USE_CLCT(USE_CLCT),.CLCT_ADJ(CLCT_ADJ),.OPT_COP(OPT_COP_ADJ),.DELAY(L1LATNCY),.XL1ADLY(XL1ADLY),.L1FD(L1FINEDELAY),.DOUT(d_lct_out_i[i]),.L1A_MATCH(L1A_MATCH[i]));
			pushdly pushdly_i (.CLK(CLK),.DIN(d_lct_out_i[i]),.DELAY(GPUSHDLY),.DOUT(PSH_AFF[i]));
		end
		assign DLY_AFF = d_lct_out_i;
	end
end
endgenerate


srl_16dx1 l1a_cfeb_srl_i (.CLK(CLK), .CE(1'b1),.A(L1FINEDELAY),.I(l1a),.O(L1ACFEB),.Q15());


endmodule
