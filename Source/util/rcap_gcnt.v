`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:09:47 02/06/2015 
// Design Name: 
// Module Name:    rcap_gcnt 
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
module rcap_gcnt #(
	parameter TMR =0
)(
	input CLK,
	input RST,
	input CE,
	input START,
	input UPSIE,
	output reg [2:0] SAMP
);

wire clr_cnt;
wire [2:0] gcnt_out;
 
assign clr_cnt = RST | START;

always @(negedge CLK or posedge RST)
begin
	if(RST)
		SAMP <= 4'h0;
	else
		SAMP <= gcnt_out;
end

generate
if(TMR==1) 
begin : rcap_gcnt_tmr

	(* syn_keep = "true" *) wire [2:0] bcnt_a;
	(* syn_keep = "true" *) wire [2:0] bcnt_b;
	(* syn_keep = "true" *) wire [2:0] bcnt_c;

	(* syn_keep = "true" *) reg [2:0] gcnt_a;
	(* syn_keep = "true" *) reg [2:0] gcnt_b;
	(* syn_keep = "true" *) reg [2:0] gcnt_c;

	cbnce3q #(.Width(3), .TMR(1)) bin_cnt_i (.CLK(CLK),.RST(clr_cnt),.CE(CE),.Q1(bcnt_a),.Q2(bcnt_b),.Q3(bcnt_c));

	always @* begin
		case ({UPSIE,bcnt_a})
			4'b0000: gcnt_a <= 3'b100;
			4'b0001: gcnt_a <= 3'b101;
			4'b0010: gcnt_a <= 3'b111;
			4'b0011: gcnt_a <= 3'b110;
			4'b0100: gcnt_a <= 3'b010;
			4'b0101: gcnt_a <= 3'b011;
			4'b0110: gcnt_a <= 3'b001;
			4'b0111: gcnt_a <= 3'b000;
			4'b1000: gcnt_a <= 3'b000;
			4'b1001: gcnt_a <= 3'b001;
			4'b1010: gcnt_a <= 3'b011;
			4'b1011: gcnt_a <= 3'b010;
			4'b1100: gcnt_a <= 3'b110;
			4'b1101: gcnt_a <= 3'b111;
			4'b1110: gcnt_a <= 3'b101;
			4'b1111: gcnt_a <= 3'b100;
			default: gcnt_a <= 3'b000;
		endcase	 
		case ({UPSIE,bcnt_b})
			4'b0000: gcnt_b <= 3'b100;
			4'b0001: gcnt_b <= 3'b101;
			4'b0010: gcnt_b <= 3'b111;
			4'b0011: gcnt_b <= 3'b110;
			4'b0100: gcnt_b <= 3'b010;
			4'b0101: gcnt_b <= 3'b011;
			4'b0110: gcnt_b <= 3'b001;
			4'b0111: gcnt_b <= 3'b000;
			4'b1000: gcnt_b <= 3'b000;
			4'b1001: gcnt_b <= 3'b001;
			4'b1010: gcnt_b <= 3'b011;
			4'b1011: gcnt_b <= 3'b010;
			4'b1100: gcnt_b <= 3'b110;
			4'b1101: gcnt_b <= 3'b111;
			4'b1110: gcnt_b <= 3'b101;
			4'b1111: gcnt_b <= 3'b100;
			default: gcnt_b <= 3'b000;
		endcase	 
		case ({UPSIE,bcnt_c})
			4'b0000: gcnt_c <= 3'b100;
			4'b0001: gcnt_c <= 3'b101;
			4'b0010: gcnt_c <= 3'b111;
			4'b0011: gcnt_c <= 3'b110;
			4'b0100: gcnt_c <= 3'b010;
			4'b0101: gcnt_c <= 3'b011;
			4'b0110: gcnt_c <= 3'b001;
			4'b0111: gcnt_c <= 3'b000;
			4'b1000: gcnt_c <= 3'b000;
			4'b1001: gcnt_c <= 3'b001;
			4'b1010: gcnt_c <= 3'b011;
			4'b1011: gcnt_c <= 3'b010;
			4'b1100: gcnt_c <= 3'b110;
			4'b1101: gcnt_c <= 3'b111;
			4'b1110: gcnt_c <= 3'b101;
			4'b1111: gcnt_c <= 3'b100;
			default: gcnt_c <= 3'b000;
		endcase	 
	end

	vote #(.Width(3)) vote_gcnt (.A(gcnt_a),.B(gcnt_b),.C(gcnt_c),.V(gcnt_out));

end
else
begin : rcap_gcnt_notmr

	wire [2:0] bcnt;
	reg [2:0] gcnt;

	cbnce #(.Width(3), .TMR(0)) bin_cnt_i (.CLK(CLK),.RST(clr_cnt),.CE(CE),.Q(bcnt));

	always @* begin
		case ({UPSIE,bcnt})
			4'b0000: gcnt <= 3'b100;
			4'b0001: gcnt <= 3'b101;
			4'b0010: gcnt <= 3'b111;
			4'b0011: gcnt <= 3'b110;
			4'b0100: gcnt <= 3'b010;
			4'b0101: gcnt <= 3'b011;
			4'b0110: gcnt <= 3'b001;
			4'b0111: gcnt <= 3'b000;
			4'b1000: gcnt <= 3'b000;
			4'b1001: gcnt <= 3'b001;
			4'b1010: gcnt <= 3'b011;
			4'b1011: gcnt <= 3'b010;
			4'b1100: gcnt <= 3'b110;
			4'b1101: gcnt <= 3'b111;
			4'b1110: gcnt <= 3'b101;
			4'b1111: gcnt <= 3'b100;
			default: gcnt <= 3'b000;
		endcase	 
	end

	assign gcnt_out = gcnt;
end
endgenerate
endmodule
