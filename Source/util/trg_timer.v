`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:31:13 11/06/2015 
// Design Name: 
// Module Name:    trg_timer 
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
module trg_timer #(
	parameter Width = 8,
	parameter TMR = 0
)
(
	input CLK,
	input HOLDOFF,
	input CLR,
	input START,
	input STOP,
	output reg [Width-1:0] TIME
);

reg  clr_cnt;
wire clr_cnt_ho;
reg  start_ce;
wire [Width-1:0] count;

assign clr_cnt_ho = clr_cnt | HOLDOFF;

cbnce #(
	.Width(Width),
	.TMR(TMR)
)
trig_timer_i (
	.CLK(CLK),
	.RST(clr_cnt_ho),
	.CE(start_ce),
	.Q(count)
);

always @(posedge CLK)
begin
	clr_cnt <= STOP;
end

always @(posedge CLK or posedge HOLDOFF)
begin
	if(HOLDOFF)
		start_ce <= 1'b0;
	else
		start_ce <= !STOP & (START | start_ce);
end

always @(posedge CLK or posedge CLR)
begin
	if(CLR)
		TIME <= 0;
	else
		if(STOP)
			TIME <= count;
end


endmodule
