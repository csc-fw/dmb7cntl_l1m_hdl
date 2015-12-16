`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:37:22 02/05/2015 
// Design Name: 
// Module Name:    cbnce3q
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
module cbnce3q #(
	parameter Width = 4,
	parameter TMR = 0
)(
	input CLK,
	input RST,
	input CE,
	output [Width-1:0] Q1,
	output [Width-1:0] Q2,
	output [Width-1:0] Q3
);


generate
if(TMR==1) 
begin : cbnce_tmr

	(* syn_preserve = "true" *) reg [Width-1:0] cnt_1;
	(* syn_preserve = "true" *) reg [Width-1:0] cnt_2;
	(* syn_preserve = "true" *) reg [Width-1:0] cnt_3;

	(* syn_keep = "true" *) wire [Width-1:0] voted_cnt_1;

	  vote #(.Width(Width)) vote_cnt_1 (.A(cnt_1), .B(cnt_2), .C(cnt_3), .V(voted_cnt_1));

	assign Q1  =  cnt_1;
	assign Q2  =  cnt_2;
	assign Q3  =  cnt_3;

	always @(posedge CLK or posedge RST) begin
		if (RST) begin
			cnt_1 <= 0;
			cnt_2 <= 0;
			cnt_3 <= 0;
		end
		else
			if(CE) begin
				cnt_1 <= voted_cnt_1 + 1;
				cnt_2 <= voted_cnt_1 + 1;
				cnt_3 <= voted_cnt_1 + 1;
			end
			else begin
				cnt_1 <= voted_cnt_1;
				cnt_2 <= voted_cnt_1;
				cnt_3 <= voted_cnt_1;
			end
	end
end
else
begin : cbnce_notmr

	reg [Width-1:0] cnt;

	assign Q1  =  cnt;
	assign Q2  =  cnt;
	assign Q3  =  cnt;

	always @(posedge CLK or posedge RST) begin
		if (RST)
			cnt <= 0;
		else
			if(CE)
				cnt <= cnt + 1;
	end
end
endgenerate

endmodule
