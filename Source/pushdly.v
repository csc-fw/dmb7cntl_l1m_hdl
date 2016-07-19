`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:55:17 11/12/2015 
// Design Name: 
// Module Name:    pushdly 
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
module pushdly(
	input CLK,
	input DIN,
	input [4:0] DELAY,
	output reg DOUT
);

	(* syn_keep = "true" *)     wire dmid;
	(* syn_preserve = "true" *) reg  dmid_r;
	(* syn_keep = "true" *)     wire dly;

//srl_16dx1 pushdelay_1 (.CLK(CLK), .CE(1'b1),.A(4'hF),.I(DIN),.O(dmid),.Q15()); // 16 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) pushdelay_1 (.CLK(CLK),.A3(1'b1),.A2(1'b1),.A1(1'b1),.A0(1'b1),.D(DIN),   .Q(dmid)); // 16 clocks

always @(posedge CLK)
begin
	dmid_r <= DELAY[4] ? dmid : DIN; // (0, 16) + 1 clocks
	DOUT   <= dly;                   // + 1 clock
end

//srl_16dx1 pushdelay_2 (.CLK(CLK), .CE(1'b1),.A(DELAY[3:0]),.I(dmid_r),.O(dly),.Q15()); // GPUSHDLY[3:0] + 1 clocks
(* syn_preserve = "true" *)  SRL16 #(.INIT(16'h0000)) pushdelay_2 (.CLK(CLK),.A3(DELAY[3]),.A2(DELAY[2]),.A1(DELAY[1]),.A0(DELAY[0]),.D(dmid_r),.Q(dly)); // GPUSHDLY[3:0] + 1 clocks

endmodule
