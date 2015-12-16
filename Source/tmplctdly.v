`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:38:33 11/12/2015 
// Design Name: 
// Module Name:    tmplctdly 
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
module tmplctdly(
    input CLK,
    input DIN,
    input [2:0] DELAY,
    output reg DOUT
    );

reg [6:0] dshft;

always @(posedge CLK)
begin
	dshft <= {dshft[5:0],DIN};
end

always @*
begin
	case(DELAY)
		3'd0 : DOUT = DIN; 
		3'd1 : DOUT = dshft[0]; 
		3'd2 : DOUT = dshft[1]; 
		3'd3 : DOUT = dshft[2]; 
		3'd4 : DOUT = dshft[3]; 
		3'd5 : DOUT = dshft[4]; 
		3'd6 : DOUT = dshft[5]; 
		3'd7 : DOUT = dshft[6]; 
		default : DOUT = DIN;
	endcase
end

endmodule
