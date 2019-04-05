`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:53:45 04/07/2016 
// Design Name: 
// Module Name:    trig_encoder 
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
module trig_encoder(
	input ENCODE,
	input DCFEB_IN_USE,
	input SND_WIN,
	input RESYNC_RST,
	input L1ACFEB,
	input [5:1] PRE_LCT_OUT,
	input [5:1] MTCH_WIN_0,
	input [5:1] L1A_MATCH,
	output reg [5:1] ENC_BIT0,
	output reg [5:1] ENC_BIT1, // uses TP[4:1]
	output reg [5:1] ENC_BIT2  // uses TP[8:5]
);


genvar i;
generate
	for(i=1;i<6;i=i+1) begin: idx1
		always @* begin
			if(ENCODE && !DCFEB_IN_USE)
				casex({RESYNC_RST,L1A_MATCH[i],L1ACFEB,PRE_LCT_OUT[i]})
					4'b0000 : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd0; 
					4'b0001 : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd1; 
					4'b0011 : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd2; 
					4'b0111 : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd3; 
					4'b0010 : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd4; 
					4'b0110 : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd5; 
					4'b1xxx : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd7; 
					default : {ENC_BIT2[i],ENC_BIT1[i],ENC_BIT0[i]} = 3'd0;
				endcase
			else	begin
				// L1A_MATCH is:
				//		pre-LCT matched with L1A for (Use_CLCT ==0)
				//		CLCT matched with L1A (Use_CLCT ==1)
				ENC_BIT0[i] = DCFEB_IN_USE ? (SND_WIN ? MTCH_WIN_0[i] : L1A_MATCH[i]) : PRE_LCT_OUT[i];
				ENC_BIT1[i] = L1ACFEB;
				ENC_BIT2[i] = RESYNC_RST;
			end
		end
	end
endgenerate


endmodule
