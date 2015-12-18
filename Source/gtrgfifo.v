`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:41:08 11/06/2015 
// Design Name: 
// Module Name:    gtrgfifo 
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
module gtrgfifo #(
	parameter TMR = 0
)
(
	input CLK,
	input RST,
	input RDRST,
	input PUSH,
	input TMBDAV,
	input ALCTDAV,
	input POP,
	input BXRST,
	input BC0,
	input [5:0] STRIP,
	input [5:1] DAV,
	input [3:0] L1FINEDELAY,
	input [4:0] FEBDAVDLY,
	input [4:0] TMBDAVDLY,
	input [4:0] GPUSHDLY,
	input [4:0] ALCTDAVDLY,
	input [7:0] CABLEDLY,
	input [5:1] MOVLP,
	input [2:0] KILLINPUT,
	output reg DPUSH,
	output GTRGFIFOERR,
	output EMPTY_B,
	output [5:1] DAVEN,
	output [31:0] TMDV,
	output [7:2] MONITOR,
	output [2:0] DAVMON,
	output [16:0] DAVSOUT,
	output [3:0] CFEBBX,
	output [11:0] BXCOUNTOUT,
	output [7:0] UPDN,
	output [15:0] GTRGDIAG,
	output reg [5:1] DAVERROR
);

wire [9:0] l1abuf;
wire ce_wr;
wire ce_rd;
wire empty;
wire full;
wire [9:0] wadd;
wire [9:0] radd;
wire [16:0] davs;
wire davss;
reg  [10:1] cfeb_md_davs;
wire [15:0] raminbx;
wire [1:0] ramina;
wire [1:0] raminb;
wire [1:0] ramoutb;
wire [3:0] cfebbxout;
(* ram_style = "block" *)
reg  [17:0] gtrgbxff [1023:0];
reg  [17:0] gtrgbxff_dout;


wire killalct;
wire killtmb;
wire [5:1] killcfeb;

wire [5:1] cdav_sync;
wire [5:1] cdav_dly;
reg  [5:1] cdav;
wire [5:1] dly_cfeb_dav;

wire [5:1] mdav_sync;
wire [5:1] mdav_dly;
reg  [5:1] mdav;
wire [5:1] dly_cfeb_mov;

wire tmbmon;
wire tmb_d4;
reg  tmb_mid;
wire dly_tmb_dav;

wire alctmon;
wire adav0;
wire alct_d4;
wire alct_mid;
wire dly_alct_dav;

wire [11:0] bxcount;
wire [15:12] bxcnt;
wire bx_cnt_rst;

wire vpush;

reg [4:1] alct_dav_scope;
reg [4:0] alct_dav_scope_reg;
reg [4:1] tmb_dav_scope;
reg [4:0] tmb_dav_scope_reg;
reg [4:1] cfeb_dav_scope;
reg [4:0] cfeb_dav_scope_reg;
wire cfeb_dav_or;
reg [3:0] lct0_m;
reg [3:0] lct1_m;
reg [3:0] lct2_m;
reg [3:0] lct3_m;
reg [3:0] lct4_m;
reg [3:0] lct5_m;
wire lct0_p1;
wire lct1_p1;
wire lct2_p1;
wire lct3_p1;
wire lct4_p1;
wire lct5_p1;
reg [4:0] lct0_m_reg;
reg [4:0] lct1_m_reg;
reg [4:0] lct2_m_reg;
reg [4:0] lct3_m_reg;
reg [4:0] lct4_m_reg;
reg [4:0] lct5_m_reg;
wire [5:1] lct_5bx_or;

wire [5:1] dummy;

assign {lct5_p1,lct4_p1,lct3_p1,lct2_p1,lct1_p1,lct0_p1} = STRIP;
assign davss      = |{lct0_m,lct0_p1}; // 5 bx OR of LCT0 which is the OR of all LCT for the 5 CFEBs
assign lct_5bx_or = {|{lct5_m,lct5_p1}, |{lct4_m,lct4_p1}, |{lct3_m,lct3_p1}, |{lct2_m,lct2_p1}, |{lct1_m,lct1_p1}};

assign TMDV = {7'b0000000,lct0_m_reg,lct3_m_reg,alct_dav_scope_reg,tmb_dav_scope_reg,cfeb_dav_scope_reg};

assign cfeb_dav_or = |dly_cfeb_dav;

assign raminbx[15:12] = bxcnt[15:12];
assign bx_cnt_rst = BC0 | BXRST | (bxcount == 12'd3563);

assign empty   = ~|l1abuf;
assign EMPTY_B = ~empty;
assign full    = &l1abuf;
assign ce_wr   = DPUSH & ~full;
assign ce_rd   = POP & ~empty;
assign GTRGFIFOERR = (DPUSH & full) | (POP & empty);
assign BXCOUNTOUT  = gtrgbxff_dout[11:0];
assign cfebbxout   = gtrgbxff_dout[15:12];
assign CFEBBX[3:1] = cfebbxout[3:1];
assign ramoutb     = gtrgbxff_dout[17:16];

assign UPDN[7]   = |l1abuf[9:7];
assign UPDN[6:0] = UPDN[7] ? l1abuf[9:3] : l1abuf[6:0];
assign DAVMON = {adav0,tmbmon,(|cdav | |mdav)};
assign MONITOR = {DPUSH,davs[0],davs[3],tmbmon,DAVMON[0],davs[16]};
assign davs = {alct_dav_scope[1],lct_5bx_or,cfeb_md_davs,tmb_dav_scope[1]};

assign GTRGDIAG = {lct_5bx_or,CABLEDLY[5:4],KILLINPUT[2:0],DAVEN[3],dly_cfeb_dav[3],cdav[3],cdav_dly[3],cdav_sync[3],DAV[3]};

assign ramina = {davss,davs[16]};
assign raminb = {raminbx[12],raminbx[12]};

assign killalct = (KILLINPUT == 3'd1);
assign killtmb  = (KILLINPUT == 3'd2);
assign killcfeb = {(KILLINPUT == 3'd7),(KILLINPUT == 3'd6),(KILLINPUT == 3'd5),(KILLINPUT == 3'd4),(KILLINPUT == 3'd3)};

//
// L1A Buffer counter
//
udl_cnt #(
	.Width(10),
	.TMR(TMR)
)
L1A_buffer_count_i
(
	.CLK(CLK),
	.RST(RST),
	.CE(ce_wr ^ ce_rd),
	.L(1'b0),
	.UP(ce_wr),
	.D(10'h000),
	.Q(l1abuf)
);


//
// Write address counter
//
cbnce #(
	.Width(10),
	.TMR(TMR)
)
write_addr_cntr_i (
	.CLK(CLK),
	.RST(RST),
	.CE(ce_wr),
	.Q(wadd)
);

//
// Read address counter
//
cbnce #(
	.Width(10),
	.TMR(TMR)
)
read_addr_cntr_i (
	.CLK(CLK),
	.RST(RST),
	.CE(ce_rd),
	.Q(radd)
);


//
// GTRG bx count FIFO memory
//
always @(posedge CLK)
begin
	if (ce_wr)
		gtrgbxff[wadd] <= {raminb,raminbx};
	if(RST)
		gtrgbxff_dout <= 0;
	else
		gtrgbxff_dout <= gtrgbxff[radd];
end

//
// GTRG FIFO memory
//
generate
if(TMR==1) 
begin : gtrg_ff_TMR

	(* syn_preserve = "true" *) reg [17:0] davsout_a;
	(* syn_preserve = "true" *) reg [17:0] davsout_b;
	(* syn_preserve = "true" *) reg [17:0] davsout_c;
	
	(* syn_preserve = "true" *) reg  [17:0] gtrgffa [1023:0];
	(* syn_preserve = "true" *) reg  [17:0] gtrgffb [1023:0];
	(* syn_preserve = "true" *) reg  [17:0] gtrgffc [1023:0];
	
	always @(posedge CLK)
	begin
		if (ce_wr)
			begin
				gtrgffa[wadd] <= {ramina,davs[15:0]};
				gtrgffb[wadd] <= {ramina,davs[15:0]};
				gtrgffc[wadd] <= {ramina,davs[15:0]};
			end
		if(RST)
			begin
				davsout_a <= 0;
				davsout_b <= 0;
				davsout_c <= 0;
			end
		else
			begin
				davsout_a <= gtrgffa[radd];
				davsout_b <= gtrgffb[radd];
				davsout_c <= gtrgffc[radd];
			end
	end

	// DAVSOUT Vote
	vote #(.Width(17)) davs_vt (.A(davsout_a[16:0]),.B(davsout_b[16:0]),.C(davsout_c[16:0]),.V(DAVSOUT));
//	assign DAVSOUT = (davsout_a[16:0] & davsout_b[16:0]) | (davsout_b[16:0] & davsout_c[16:0]) | (davsout_a[16:0] & davsout_c[16:0]); // Majority logic
	vote bxcnt0_vt     (.A(cfebbxout[0]),.B(ramoutb[1]),.C(ramoutb[0]),.V(CFEBBX[0]));
//	assign CFEBBX[0] = (cfebbxout[0] & ramoutb[1]) | (ramoutb[1] & ramoutb[0]) | (cfebbxout[0] & ramoutb[0]); // Majority logic
end
else 
begin : gtrg_ff_no_TMR

	reg [17:0] davsout_r;
	
	reg [17:0] gtrgff [1023:0];

	always @(posedge CLK)
	begin
		if (ce_wr)
			gtrgff[wadd] <= {ramina,davs[15:0]};
		if(RST)
			davsout_r <= 0;
		else
			davsout_r <= gtrgff[radd];
	end

	assign DAVSOUT   = davsout_r[16:0];
	assign CFEBBX[0] = cfebbxout[0];
end
endgenerate

genvar i;
generate
begin
	for(i=1;i<6;i=i+1) begin: idx1
		// DAVs returned from CFEBs
		sync_mux Cdav_Sync_Mux_i (.C(CLK),  .RST(RST),.D(DAV[i]),.S(CABLEDLY[5:4]),.KILL(killcfeb[i]),.Q(cdav_sync[i]),.ENOUT(DAVEN[i])); // Synchronization, clock phase selection, and cable delay (1.5 to 3 clocks)
		srl_16dx1 Cdavrevf_srl_i (.CLK(CLK),.CE(DAVEN[i]),.A(~L1FINEDELAY),  .I(cdav_sync[i]),.O(cdav_dly[i]),    .Q15()); // Reverse L1A Fine delay
		srl_16dx1 Cdavfdly_srl_i (.CLK(CLK),.CE(1'b1),    .A(FEBDAVDLY[3:0]),.I(cdav[i]),     .O(dly_cfeb_dav[i]),.Q15()); // CFEB DAV delay (4 bits)
		
		// multiple Overlap errors (MOVLPs) from CFEBs
		sync_mux Mdav_Sync_Mux_i (.C(CLK),  .RST(RST),.D(MOVLP[i]),.S(CABLEDLY[5:4]),.KILL(killcfeb[i]),.Q(mdav_sync[i]),.ENOUT(dummy[i])); // Synchronization, clock phase selection, and cable delay (1.5 to 3 clocks)
		srl_16dx1 Mdavrevf_srl_i (.CLK(CLK),.CE(DAVEN[i]),.A(~L1FINEDELAY),  .I(mdav_sync[i]),.O(mdav_dly[i]),    .Q15()); // Reverse L1A Fine delay
		srl_16dx1 Mdavfdly_srl_i (.CLK(CLK),.CE(1'b1),    .A(FEBDAVDLY[3:0]),.I(mdav[i]),     .O(dly_cfeb_mov[i]),.Q15()); // CFEB MOVLP delay (4 bits)
	end
	for(i=0;i<12;i=i+1) begin: idx2
		// BX Counter and delay
		pushdly bx_pushdly_i (.CLK(CLK),.DIN(bxcount[i]),.DELAY(GPUSHDLY),.DOUT(raminbx[i]));
	end
end
endgenerate


always @(posedge CLK or posedge RST)
begin
	if(RST)
		begin
			cdav         <= 5'b00000;
			mdav         <= 5'b00000;
			cfeb_md_davs <= 10'b0000000000;
		end
	else
		begin
			cdav         <= cdav_dly;
			mdav         <= mdav_dly;
			cfeb_md_davs <= {dly_cfeb_mov,dly_cfeb_dav};
		end
end

// DAV returned from TMB
sync_in TMBdav_Sync_in_i  (.C(CLK),  .RST(RST),.D(TMBDAV),.KILL(killtmb),.Q(tmbmon)); // Synchronization registers (2 clocks)
srl_16dx1 TMBdav_d4_srl_i (.CLK(CLK),.CE(1'b1),.A(4'hF),          .I(tmbmon), .O(tmb_d4),     .Q15()); // 16 clocks
srl_16dx1 TMBdav_srl_i    (.CLK(CLK),.CE(1'b1),.A(TMBDAVDLY[3:0]),.I(tmb_mid),.O(dly_tmb_dav),.Q15());       // TMB DAV delay 

always @(posedge CLK)
begin
	tmb_mid <= TMBDAVDLY[4] ? tmb_d4 : tmbmon; // + 1 clock
end


// DAV returned from ALCT
assign alct_mid = ALCTDAVDLY[4] ? alct_d4 : adav0;                                                                  // no clock
sync_in ALCTdav_Sync_in_i      (.C(CLK),  .RST(RST),.D(ALCTDAV),.KILL(killalct),.Q(alctmon)); // Synchronization registers (2 clocks)
srl_16dx1 ALCTdav_cbldly_srl_i (.CLK(CLK),.CE(1'b1),.A({2'b00,CABLEDLY[7:6]}),.I(alctmon), .O(adav0),       .Q15());        // ALCT Cable delay (0 to 3) + 1 clocks
srl_16dx1 ALCTdav_d4_srl_i     (.CLK(CLK),.CE(1'b1),.A(4'hF),                 .I(adav0),   .O(alct_d4),     .Q15()); // 16 clocks
srl_16dx1 ALCTdav_srl_i        (.CLK(CLK),.CE(1'b1),.A(ALCTDAVDLY[3:0]),      .I(alct_mid),.O(dly_alct_dav),.Q15());        // ALCT DAV delay with clock enable


// DMB BX Counter

cbncer #(
	.Width(12),
	.TMR(TMR)
)
bx_cntr_i (
	.CLK(CLK),
	.SRST(bx_cnt_rst),
	.CE(1'b1),
	.Q(bxcount)
);


// CFEB BX Counter

cbnce #(
	.Width(4),
	.TMR(TMR)
)
CFEB_bx_cntr_i (
	.CLK(CLK),
	.RST(RST),
	.CE(1'b1),
	.Q(bxcnt)
);


always @(posedge CLK)
begin
	if(DPUSH)
		DAVERROR <= (davs[5:1] | davs[10:6]) ^ davs[15:11];
end

// Push delay loggic
generate
if(TMR==1) 
begin : push_dly_TMR

	(* syn_keep = "true" *) wire dpush_a;
	(* syn_keep = "true" *) wire dpush_b;
	(* syn_keep = "true" *) wire dpush_c;
	
	pushdly push_pushdly_a (.CLK(CLK),.DIN(PUSH),.DELAY(GPUSHDLY),.DOUT(dpush_a));
	pushdly push_pushdly_b (.CLK(CLK),.DIN(PUSH),.DELAY(GPUSHDLY),.DOUT(dpush_b));
	pushdly push_pushdly_c (.CLK(CLK),.DIN(PUSH),.DELAY(GPUSHDLY),.DOUT(dpush_c));
	
	vote push_vt (.A(dpush_a),.B(dpush_b),.C(dpush_c),.V(vpush));
end
else 
begin : push_dly_no_TMR
	pushdly push_pushdly_i (.CLK(CLK),.DIN(PUSH),.DELAY(GPUSHDLY),.DOUT(vpush));
end
endgenerate

always @(posedge CLK)
begin
	DPUSH <= vpush;
end

//
// DAV Scope logic
//

always @(posedge CLK)
begin
	alct_dav_scope <= {alct_dav_scope[3:1],dly_alct_dav}; //ALCT DAV pipe
	tmb_dav_scope  <= {tmb_dav_scope[3:1],dly_tmb_dav};   //TMB DAV pipe
	cfeb_dav_scope <= {cfeb_dav_scope[3:1],cfeb_dav_or};  //CFEB DAV pipe
end

always @(posedge CLK or posedge RDRST)
begin
	if(RDRST)
		begin
			alct_dav_scope_reg <= 5'b00000; //ALCT DAV scope
			tmb_dav_scope_reg  <= 5'b00000; //TMB DAV scope
			cfeb_dav_scope_reg <= 5'b00000; //CFEB DAV scope
		end
	else
		if(DPUSH)
			begin
				alct_dav_scope_reg <= {alct_dav_scope,dly_alct_dav}; //ALCT DAV scope
				tmb_dav_scope_reg  <= {tmb_dav_scope,dly_tmb_dav}; //TMB DAV scope
				cfeb_dav_scope_reg <= {cfeb_dav_scope,cfeb_dav_or}; //CFEB DAV scope
			end
end




//
// LCT scope logic
//

always @(posedge CLK)
begin
	lct0_m <= {lct0_m[2:0],lct0_p1};
	lct1_m <= {lct1_m[2:0],lct1_p1};
	lct2_m <= {lct2_m[2:0],lct2_p1};
	lct3_m <= {lct3_m[2:0],lct3_p1};
	lct4_m <= {lct4_m[2:0],lct4_p1};
	lct5_m <= {lct5_m[2:0],lct5_p1};
end

always @(posedge CLK or posedge RDRST)
begin
	if(RDRST)
		begin
			lct0_m_reg <= 5'b00000; 
			lct1_m_reg <= 5'b00000; 
			lct2_m_reg <= 5'b00000; 
			lct3_m_reg <= 5'b00000; 
			lct4_m_reg <= 5'b00000; 
			lct5_m_reg <= 5'b00000; 
		end
	else
		if(DPUSH)
			begin
				lct0_m_reg <= {lct0_m,lct0_p1};
				lct1_m_reg <= {lct1_m,lct1_p1};
				lct2_m_reg <= {lct2_m,lct2_p1};
				lct3_m_reg <= {lct3_m,lct3_p1};
				lct4_m_reg <= {lct4_m,lct4_p1};
				lct5_m_reg <= {lct5_m,lct5_p1};
			end
end



endmodule
