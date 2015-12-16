`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:47:30 02/06/2015 
// Design Name: 
// Module Name:    cb4gray 
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
module cb4gray #(
	parameter TMR = 0
)(
	input CLK,
	input RST,
	input CE,
	output reg [3:0] Q,
	output [3:0] QI,
	output TC
);

wire [3:0] gray_out;

assign TC = (QI == 4'hF);

(* syn_useioff = "True" *)
always @(posedge CLK or posedge RST)
begin
	if(RST)
		Q <= 4'h0;
	else
		if(CE)
			Q <= gray_out;
end

generate
if(TMR==1) 
begin : cb4gray_tmr

	(* syn_keep = "true" *) reg [3:0] gray_a;
	(* syn_keep = "true" *) reg [3:0] gray_b;
	(* syn_keep = "true" *) reg [3:0] gray_c;

	(* syn_keep = "true" *) wire [3:0] bcnt_a;
	(* syn_keep = "true" *) wire [3:0] bcnt_b;
	(* syn_keep = "true" *) wire [3:0] bcnt_c;

	assign QI = bcnt_a;

	cbnce3q #(.Width(4), .TMR(1)) bin_cnt_i (.CLK(CLK),.RST(RST),.CE(CE),.Q1(bcnt_a),.Q2(bcnt_b),.Q3(bcnt_c));

	// offset Gray coding
	always @* begin
		case (bcnt_a)
			4'b0000: gray_a <= 4'b0001;
			4'b0001: gray_a <= 4'b0011;
			4'b0010: gray_a <= 4'b0010;
			4'b0011: gray_a <= 4'b0110;
			4'b0100: gray_a <= 4'b0111;
			4'b0101: gray_a <= 4'b0101;
			4'b0110: gray_a <= 4'b0100;
			4'b0111: gray_a <= 4'b1100;
			4'b1000: gray_a <= 4'b1101;
			4'b1001: gray_a <= 4'b1111;
			4'b1010: gray_a <= 4'b1110;
			4'b1011: gray_a <= 4'b1010;
			4'b1100: gray_a <= 4'b1011;
			4'b1101: gray_a <= 4'b1001;
			4'b1110: gray_a <= 4'b1000;
			4'b1111: gray_a <= 4'b0000;
			default: gray_a <= 4'b0000;
		endcase	 
		case (bcnt_b)
			4'b0000: gray_b <= 4'b0001;
			4'b0001: gray_b <= 4'b0011;
			4'b0010: gray_b <= 4'b0010;
			4'b0011: gray_b <= 4'b0110;
			4'b0100: gray_b <= 4'b0111;
			4'b0101: gray_b <= 4'b0101;
			4'b0110: gray_b <= 4'b0100;
			4'b0111: gray_b <= 4'b1100;
			4'b1000: gray_b <= 4'b1101;
			4'b1001: gray_b <= 4'b1111;
			4'b1010: gray_b <= 4'b1110;
			4'b1011: gray_b <= 4'b1010;
			4'b1100: gray_b <= 4'b1011;
			4'b1101: gray_b <= 4'b1001;
			4'b1110: gray_b <= 4'b1000;
			4'b1111: gray_b <= 4'b0000;
			default: gray_b <= 4'b0000;
		endcase	 
		case (bcnt_c)
			4'b0000: gray_c <= 4'b0001;
			4'b0001: gray_c <= 4'b0011;
			4'b0010: gray_c <= 4'b0010;
			4'b0011: gray_c <= 4'b0110;
			4'b0100: gray_c <= 4'b0111;
			4'b0101: gray_c <= 4'b0101;
			4'b0110: gray_c <= 4'b0100;
			4'b0111: gray_c <= 4'b1100;
			4'b1000: gray_c <= 4'b1101;
			4'b1001: gray_c <= 4'b1111;
			4'b1010: gray_c <= 4'b1110;
			4'b1011: gray_c <= 4'b1010;
			4'b1100: gray_c <= 4'b1011;
			4'b1101: gray_c <= 4'b1001;
			4'b1110: gray_c <= 4'b1000;
			4'b1111: gray_c <= 4'b0000;
			default: gray_c <= 4'b0000;
		endcase	 
	end

	vote #(.Width(4)) vote_gray (.A(gray_a), .B(gray_b), .C(gray_c), .V(gray_out));

end
else
begin : cb4gray_notmr

	reg  [3:0] gray;
	wire [3:0] bcnt;

	assign QI = bcnt;

	cbnce #(.Width(4), .TMR(0)) bin_cnt_i (.CLK(CLK),.RST(RST),.CE(CE),.Q(bcnt));

	// offset Gray coding
	always @* begin
		case (bcnt)
			4'b0000: gray <= 4'b0001;
			4'b0001: gray <= 4'b0011;
			4'b0010: gray <= 4'b0010;
			4'b0011: gray <= 4'b0110;
			4'b0100: gray <= 4'b0111;
			4'b0101: gray <= 4'b0101;
			4'b0110: gray <= 4'b0100;
			4'b0111: gray <= 4'b1100;
			4'b1000: gray <= 4'b1101;
			4'b1001: gray <= 4'b1111;
			4'b1010: gray <= 4'b1110;
			4'b1011: gray <= 4'b1010;
			4'b1100: gray <= 4'b1011;
			4'b1101: gray <= 4'b1001;
			4'b1110: gray <= 4'b1000;
			4'b1111: gray <= 4'b0000;
			default: gray <= 4'b0000;
		endcase	 
	end

	assign gray_out = gray;

end
endgenerate

endmodule
