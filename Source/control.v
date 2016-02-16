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
	parameter TMR = 0
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
	output reg DAV,
	output reg POPBRAM,
	output OEOVLP,
	output reg [7:1] RENFIFO_B,
	output reg [7:1] OEFIFO_B,
	output [7:1] FEMP,
	output reg [15:0] DOUT
);

reg  gdav_1;
reg  gdav_2;
reg  gdav_3;
reg  busy;
reg  busy_1;
wire busy_ce;
wire stpop;
reg  pop;
wire pop_rst;
reg  pop_m3;
reg  pop_m2;
reg  pop_m1;
reg  pbram;
wire popbram_rst;
wire startread;
reg  [8:1] oehdr;
reg  [8:1] tail;
reg  tail8_1;
wire oehdra;
wire oehdrb;
wire taila;
wire tailb;
reg  oehdtl;
reg  dodat;
wire dodatx;
reg  st_tail;
wire okdata;
wire okdata_rst;
wire l1only;
wire head_d12;
wire tail_rst;
wire [8:0] ddcnt;
reg  data_hldoff;
reg  [15:0] d_htov;
wire [1:0] fmt_ver = 2'b01;
wire fendaverr;
reg  [15:0] da_in;
reg  [15:0] dint;
wire [23:0] regcrc;
wire [23:0] l1cnt;
reg  [11:0] cdcd;
reg  [7:1] datanoend;
reg  [7:1] davnodata;
wire [7:1] errord;
wire killalct;
wire killtmb;
wire [5:1] killcfeb;
wire [7:1] killdcd;
reg  [7:1] ffrfl; // raw FIFO full flags
wire [7:1] fffl;  // FIFO full flags AND'd with not kill
wire [7:1] ffhf;  // FIFO half full flags OR'd with kill
wire [7:1] ffmt;  // FIFO empty flags OR'd with kill
reg  [7:1] fifordy_b;
reg  [7:1] rdy;
reg  [7:1] r_act;
reg  [7:1] prio_act;
wire [7:1] oe;
reg  [7:1] ooe;
reg  [7:1] dn_oe;
wire [5:1] oe6;
reg  [5:1] oe6_1;
reg  [5:1] ovrin;
reg  [5:1] ovr;
wire [5:1] rovr;
reg  [5:1] rovr_1;
wire [5:1] rst_rovr;
reg  dint_ovlp_b;
reg  ovlpin_b;
wire readovlp;
wire ovlpren;
reg  rdyovlp;
reg  ovlpend;
wire doneovlp;
reg  rdoneovlp;
reg  dn_ovlp;
wire rst_dov;
reg  ooeovlp;
reg  disdav;
wire last;
reg  prefflast;
reg  rstlast;
wire poplast;
wire done_ce;
reg  oeall;
reg  doeall;
reg  oeall_r;
reg  oedata;
wire [7:1] done;
wire [7:1] errd_rst;
wire jrdff;
reg  rdffnxt_1;
reg  rdffnxt_2;
reg  rdffnxt_3;
reg  [7:1] jref;
reg  dtail7;
reg  dtail8;
reg  dtail78;
wire ovlpwen;
reg  ht_crc;
wire crcen;
wire [11:0] qnoend;
reg  rstcnt;
wire [3:0] ovlplast;
wire preovlast;
wire fcrst;
wire [12:0] ovlpwa;
wire [12:0] ovlpra;
wire [19:0] doutx;
reg  [19:0] ovlpff_out;
(* ram_style = "block" *)
reg  [19:0] ovlpfifo [8191:0];

assign doutx       = ovlpff_out;
assign FEMP        = FFOR_B;
assign OEOVLP      = rdyovlp & |oe6;
assign busy_ce     = gdav_3 & !busy;
assign startread   = busy & !busy_1;
assign readovlp    = ooeovlp & ~ovlpend;
assign ovlpren     = readovlp & ~last;
assign ovlpwen     = ~pop_rst & ~disdav & ~dint_ovlp_b & oedata;
assign last        = readovlp ? preovlast : prefflast;
assign pop_rst     = pop | RST;
assign rst_dov     = pop_rst | rdoneovlp;
assign poplast     = pop_rst | last;
assign head_d12    = |{DAVACT[16],DAVACT[5:0]};
assign l1only      = oehdr[4] & !head_d12;
assign stpop       = l1only | tail8_1;
assign popbram_rst = RST | POPBRAM;
assign oehdra      = |{oehdr[4:1]};
assign oehdrb      = |{oehdr[8:5]};
assign taila       = |{tail[4:1]};
assign tailb       = |{tail[8:5]};
assign okdata      = (ddcnt == 9'd448);
assign okdata_rst  = RST | okdata;
assign tail_rst    = RST | tail[1];
assign dodatx      = dodat && !readovlp;
assign fendaverr   = |(DAVENBL & (DAVACT[15:11] ^ (DAVACT[10:6] | DAVACT[5:1]))); // CFEB DAVs or Multi-Overlaps not matching Pre-Triggers

assign killalct = (KILLINPUT == 3'd1);
assign killtmb  = (KILLINPUT == 3'd2);
assign killcfeb = {(KILLINPUT == 3'd7),(KILLINPUT == 3'd6),(KILLINPUT == 3'd5),(KILLINPUT == 3'd4),(KILLINPUT == 3'd3)};
assign killdcd  = {killalct,killtmb,killcfeb};
assign ffhf     = killdcd | STATUS[40:34];
assign ffmt     = killdcd | STATUS[26:20];
assign fffl     = ~killdcd & ffrfl;
assign rovr     = {5{RST}} | oe6_1;
assign rst_rovr = {5{RST}} | rovr_1;
assign done_ce  = last & !ovlpend; // leading edge of last;
assign errd_rst = errord | done;

assign oe       = prio_act & rdy & ~{2'b0,ovr};
assign oe6      = prio_act[5:1] & ovr;
assign jrdff    = rdffnxt_2 & ~rdffnxt_3;
assign doneovlp = pop_rst | dn_ovlp;
assign done     = {7{pop_rst}} | dn_oe;
assign crcen    = ~disdav & (oedata | ht_crc);
assign errord   = davnodata | datanoend;
assign ovlplast = {{3{ovlpend}},dint[15]};
assign fcrst    = RST | FIFOMRST;
  
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


always @*
begin
	if(dodat)
		casex(r_act)
			7'b1xxxxxx : prio_act = 7'b1000000; // ALCT
			7'b01xxxxx : prio_act = 7'b0100000; // TMB
			7'b00xxxx1 : prio_act = 7'b0000001; // CFEB 1
			7'b00xxx10 : prio_act = 7'b0000010; // CFEB 2
			7'b00xx100 : prio_act = 7'b0000100; // CFEB 3
			7'b00x1000 : prio_act = 7'b0001000; // CFEB 4
			7'b0010000 : prio_act = 7'b0010000; // CFEB 5
			default    : prio_act = 7'b0000000;
		endcase
	else
		prio_act = 7'b0000000;
end

always @*
begin
	case({readovlp,tail,oehdr})
		17'b00000000000000001 : d_htov = {3'b100,head_d12,l1cnt[11:0]};                                                     // Header 1 code 8 or 9
		17'b00000000000000010 : d_htov = {3'b100,head_d12,l1cnt[23:12]};                                                    // Header 2 code 8 or 9
		17'b00000000000000100 : d_htov = {3'b100,head_d12,DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[15:11]}; // Header 3 code 8 or 9
		17'b00000000000001000 : d_htov = {3'b100,head_d12,BXN[11:0]};                                                       // Header 4 code 8 or 9
		17'b00000000000010000 : d_htov = {4'hA,           DAVACT[16],DAVACT[0],fmt_ver[1:0],fendaverr,2'b00,DAVACT[5:1]};   // Header 5 code A
		17'b00000000000100000 : d_htov = {4'hA,           DAQMBID[11:0]};                                                   // Header 6 code A
		17'b00000000001000000 : d_htov = {4'hA,           DAVACT[16],DAVACT[0],DAVACT[10:6],BXN[4:0]};                      // Header 7 code A
		17'b00000000010000000 : d_htov = {4'hA,           CFEBBX[3:0],fmt_ver[1:0],fendaverr,l1cnt[4:0]};                   // Header 8 code A
		17'b00000000100000000 : d_htov = {4'hF,           datanoend[7],BXN[4:0],l1cnt[5:0]};                                // Tail 1 code F
		17'b00000001000000000 : d_htov = {4'hF,           DAVACT[10:6],2'b00,datanoend[5:1]};                               // Tail 2 code F
		17'b00000010000000000 : d_htov = {4'hF,           fffl[3:1],davnodata[6],STATUS[14:7]};                             // Tail 3 code F
		17'b00000100000000000 : d_htov = {4'hF,           davnodata[7],2'b00,davnodata[5:1],2'b00,fffl[5:4]};               // Tail 4 code F
		17'b00001000000000000 : d_htov = {4'hE,           fffl[7:6],ffhf[7:6],datanoend[6],2'b11,ffhf[5:1]};                // Tail 5 code E
		17'b00010000000000000 : d_htov = {4'hE,           DAQMBID[11:0]};                                                   // Tail 6 code E
		17'b00100000000000000 : d_htov = {4'hE,           12'h000};                                                         // Tail 7 code E CRC place holder
		17'b01000000000000000 : d_htov = {4'hE,           12'h000};                                                         // Tail 8 code E CRC place holder
		17'b10000000000000000 : d_htov =  doutx[15:0];                                                                      // Read overlap FIFO
		default               : d_htov = 16'h0000;
	endcase
end

always @*
begin
	case({dtail8,dtail7})
		2'b01   : cdcd = {regcrc[22],regcrc[10:0]};  // Tail 7 CRC
		2'b10   : cdcd = {regcrc[23],regcrc[21:11]}; // Tail 8 CRC
		default : cdcd = 12'h000;
	endcase
end

always @(posedge CLKCMS or posedge pop_rst)
begin
	if(pop_rst)
		begin
			gdav_1     <= 1'b0;
			datanoend  <= 7'h00;
		end
	else
		begin
			gdav_1 <= GEMPTY_B;
			if(rstcnt) datanoend  <= oe;
		end
end

always @(posedge CLKCMS or posedge RST)
begin
	if(RST)
		POPBRAM  <= 1'b0;
	else
		POPBRAM <= pbram;
end

always @(posedge CLKCMS)
begin
	rstcnt <= qnoend[11];
end


(* IOB = "TRUE" *)
always @(negedge CLKDDU) //Negative edge and IOB
begin
	fifordy_b <= FEMP;
	da_in     <= DATAIN[15:0];
end

(* IOB = "TRUE" *)
always @(posedge CLKDDU or posedge pop_rst)
begin
	if(pop_rst)
		RENFIFO_B  <= 1'b1;
	else
		RENFIFO_B <= ~(jref | (ooe & ~{7{last}}));
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
		if(doeall)
			begin
				prefflast <= DATAIN[16];
				ovlpin_b  <= DATAIN[17];
			end
end

always @(posedge CLKDDU or posedge pop_rst)
begin
	if(pop_rst)
		begin
			gdav_2  <= 1'b0;
			busy    <= 1'b0;
			busy_1  <= 1'b0;
			oehdr   <= 8'h00;
			tail    <= 8'h00;
			tail8_1 <= 1'b0;
			DAV     <= 1'b0;
			rdyovlp <= 1'b0;
			oeall_r <= 1'b0;
			oedata  <= 1'b0;
			dn_oe   <= 7'h00;
			davnodata <= 7'h00;
		end
	else
		begin
			if(GIGAEN) gdav_2 <= gdav_1;
			gdav_3 <= gdav_2;
			busy   <= gdav_3;
			busy_1 <= busy;
			oehdr  <= {oehdr[7:1],startread};
			tail   <= {tail[7:1],st_tail};
			tail8_1 <= tail[8];
			DAV     <= ~disdav & (oehdtl | oedata);
			rdyovlp <= dodat;
			oeall_r <= oeall;
			oedata  <= oeall_r;
			if(done_ce) dn_oe   <= oe;
			if(okdata && !dodat) davnodata <= r_act & fifordy_b;
		end
end

always @(posedge CLKDDU or posedge okdata_rst)
begin
	if(okdata_rst)
		data_hldoff  <= 1'b0;
	else
		if(oehdr[8])
			data_hldoff <= busy;
end

//
// data hold off counter
//
cbnce #(
	.Width(9),
	.TMR(TMR)
)
dhldoff_cntr_i (
	.CLK(CLKDDU),
	.RST(tail_rst),
	.CE(data_hldoff),
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
	.Width(12),
	.TMR(TMR)
)
evt_tmo_cntr_i (
	.CLK(CLKCMS),
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
	.CLR(oehdr[1]),
	.DIN(dint),
	.REGCRC(regcrc)
);

always @(posedge CLKDDU)
begin
	if(pop_rst) // Synchronous reset
		pop_m3 <= 1'b0;
	if(stpop)
		pop_m3 <= 1'b1;
end

always @(posedge CLKDDU or posedge RST)
begin
	if(RST)
		begin
			pop_m2  <= 1'b0;
			pop_m1  <= 1'b0;
			pop     <= 1'b0;
			oehdtl  <= 1'b0;
			ovlpend <= 1'b0;
			ht_crc  <= 1'b0;
		end
	else
		begin
			pop_m2  <= pop_m3;
			pop_m1  <= pop_m2;
			pop     <= pop_m1;
			oehdtl  <= oehdra | oehdrb | taila | tailb;
			ovlpend <= last;
			ht_crc  <= oehdra | oehdrb | taila;
		end
end

always @(posedge CLKDDU or posedge tail[1])
begin
	if(tail[1])
		begin
			dodat   <= 1'b0;
			st_tail <= 1'b0;
		end
	else
		begin
			dodat   <= okdata;
			if(busy && ~|r_act)
				st_tail <= dodat;  // start tail when no more fifos have data for this event
		end
end

always @(posedge CLKDDU or posedge popbram_rst)
begin
	if(popbram_rst)
		pbram  <= 1'b0;
	else
		if(stpop)
			pbram <= 1'b1;
end

genvar i;
generate
begin
	for(i=1;i<8;i=i+1) begin: idx1
		always @(posedge CLKDDU or posedge STATUS[i+33])
		begin
			if(STATUS[i+33])
				ffrfl[i] <= 1'b0;
			else
				if(STATUS[i+26])
					ffrfl[i] <= STATUS[i+26];
		end
		
		always @(posedge CLKDDU or posedge pop_rst)
		begin
			if(pop_rst)
				rdy[i] <= 1'b0;
			else
				if(!fifordy_b[i])
					rdy[i] <= dodat;
		end
		
		always @(posedge CLKDDU or posedge done[i])
		begin
			if(done[i])
				ooe[i] <= 1'b0;
			else
				ooe[i] <= oe[i];
		end

		always @(posedge CLKDDU)
		begin
			if(JOEF[i]) jref[i] <= jrdff;
		end
		
		(* IOB = "TRUE" *)
		always @(negedge CLKDDU or posedge done[i]) // Negative edge
		begin
			if(done[i])
				OEFIFO_B[i]  <= 1'b1;
			else
				OEFIFO_B[i] <= ~(JOEF[i] | ooe[i]);
		end
	end
	for(i=1;i<6;i=i+1) begin: idx2
		always @(posedge CLKDDU or posedge rst_rovr[i])
		begin
			if(rst_rovr[i])
				oe6_1[i] <= 1'b0;
			else
				if(done_ce) 
					oe6_1[i] <= oe6[i];
		end
		
		always @(posedge CLKDDU or posedge rovr[i])
		begin
			if(rovr[i])
				begin
					ovrin[i] <= 1'b0;
					ovr[i]   <= 1'b0;
				end
			else
				begin
					if(oe[i] && last) ovrin[i] <= ~ovlpin_b;
					ovr[i]   <= ovrin[i];
				end
		end
		
		always @(posedge CLKDDU or posedge errd_rst[i])
		begin
			if(errd_rst[i])
				r_act[i] <= 1'b0;
			else
				if(busy_ce)
					r_act[i] <= DAVACT[i];
		end

	end
end
endgenerate


always @(posedge CLKDDU or posedge errd_rst[6])
begin
	if(errd_rst[6])
		r_act[6] <= 1'b0;
	else
		if(busy_ce)
			r_act[6] <= DAVACT[0];
end
always @(posedge CLKDDU or posedge errd_rst[7])
begin
	if(errd_rst[7])
		r_act[7] <= 1'b0;
	else
		if(busy_ce)
			r_act[7] <= DAVACT[16];
end

always @(negedge CLKDDU) // Negative edge
begin
	rstlast   <= prefflast;
end

always @(posedge CLKDDU)
begin
	rovr_1      <= rovr;
	disdav      <= |(prio_act & fifordy_b);
	rdffnxt_1   <= RDFFNXT;
	rdffnxt_2   <= rdffnxt_1;
	rdffnxt_3   <= rdffnxt_2;
	rdoneovlp   <= doneovlp;
	dint        <= dodatx  ? da_in : d_htov;
	DOUT        <= dtail78 ? {dint[15:12],cdcd}  : dint;
	dint_ovlp_b <= ovlpin_b;
	dtail7      <= tail[7];
	dtail8      <= dtail7;
	dtail78     <= tail[7] | tail[8];
end

always @(posedge CLKDDU or posedge poplast)
begin
	if(poplast)
		begin
			oeall  <= 1'b0;
			doeall <= 1'b0;
		end
	else
		begin
			oeall  <= OEOVLP | |oe;
			doeall <= oeall;
		end
end

always @(posedge CLKDDU or posedge rst_dov)
begin
	if(rst_dov)
		dn_ovlp <= 1'b0;
	else
		if(done_ce) dn_ovlp <= OEOVLP;
end

always @(posedge CLKDDU or posedge doneovlp)
begin
	if(doneovlp)
		ooeovlp <= 1'b0;
	else
		ooeovlp <= OEOVLP;
end

//
// Overlap FIFO memory
//
always @(posedge CLKDDU)
begin
	if (ovlpwen)
		ovlpfifo[ovlpwa] <= {ovlplast,dint};
	ovlpff_out <= ovlpfifo[ovlpra];
end

endmodule
