`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:52:10 11/05/2015 
// Design Name: 
// Module Name:    clkgen2 
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
module clkgen2(
	input CLKIN1,
	input CLKIN2,
	output reg READY,
	output CLKDDU,
	output CLKCMS,
	output RAW_CLKCMS,
	output CLK80,
	output FIFORCLK1,
	output FIFORCLK2,
	output DV128CLK
);

wire r_clkcms;
wire r_clkddu;
wire r_clk80;
wire r_ffclk;
wire cmslck;
wire ddulck;
wire r_dv128clk;
wire lock1;
wire lock2;
wire imclk1;
wire imclk2;
wire imclk3;

assign RAW_CLKCMS = r_clkcms;

   // DCM: Digital Clock Manager Circuit
   //      Virtex-II/II-Pro and Spartan-3
   // Xilinx HDL Language Template, version 10.1.3

   DCM #(
      .SIM_MODE("SAFE"),  // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
      .CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                          //   7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      .CLKFX_DIVIDE(1),   // Can be any integer from 1 to 32
      .CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
      .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
      .CLKIN_PERIOD(25.0),  // Specify period of input clock
      .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
      .CLK_FEEDBACK("2X"),  // Specify clock feedback of NONE, 1X or 2X
      .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                            //   an integer from 0 to 15
      .DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
      .DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
      .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
      .FACTORY_JF(16'hC080),   // FACTORY JF values
      .PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
      .STARTUP_WAIT("FALSE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
   ) DCM_clkcms_i (
      .CLK0(r_clkcms),     // 0 degree DCM CLK output
      .CLK180(), // 180 degree DCM CLK output
      .CLK270(), // 270 degree DCM CLK output
      .CLK2X(r_clk80),   // 2X DCM CLK output
      .CLK2X180(), // 2X, 180 degree DCM CLK out
      .CLK90(),   // 90 degree DCM CLK output
      .CLKDV(),   // Divided DCM CLK out (CLKDV_DIVIDE)
      .CLKFX(),   // DCM CLK synthesis out (M/D)
      .CLKFX180(), // 180 degree CLK synthesis out
      .LOCKED(cmslck), // DCM LOCK status output
      .PSDONE(), // Dynamic phase adjust done output
      .STATUS(), // 8-bit DCM status bits output
      .CLKFB(CLK80),   // DCM clock feedback
      .CLKIN(CLKIN1),   // Clock input (from IBUFG, BUFG or DCM)
      .PSCLK(),   // Dynamic phase adjust clock input
      .PSEN(),     // Dynamic phase adjust enable input
      .PSINCDEC(), // Dynamic phase adjust increment/decrement
      .RST(1'b0)        // DCM asynchronous reset input
   );

   // DCM: Digital Clock Manager Circuit
   //      Virtex-II/II-Pro and Spartan-3
   // Xilinx HDL Language Template, version 10.1.3

   DCM #(
      .SIM_MODE("SAFE"),  // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
      .CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                          //   7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      .CLKFX_DIVIDE(1),   // Can be any integer from 1 to 32
      .CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
      .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
      .CLKIN_PERIOD(12.5),  // Specify period of input clock
      .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
      .CLK_FEEDBACK("1X"),  // Specify clock feedback of NONE, 1X or 2X
      .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                            //   an integer from 0 to 15
      .DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
      .DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
      .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
      .FACTORY_JF(16'hC080),   // FACTORY JF values
      .PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
      .STARTUP_WAIT("FALSE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
   ) DCM_clkddu_i (
      .CLK0(r_clkddu),     // 0 degree DCM CLK output
      .CLK180(r_ffclk), // 180 degree DCM CLK output
      .CLK270(), // 270 degree DCM CLK output
      .CLK2X(),   // 2X DCM CLK output
      .CLK2X180(), // 2X, 180 degree DCM CLK out
      .CLK90(),   // 90 degree DCM CLK output
      .CLKDV(),   // Divided DCM CLK out (CLKDV_DIVIDE)
      .CLKFX(),   // DCM CLK synthesis out (M/D)
      .CLKFX180(), // 180 degree CLK synthesis out
      .LOCKED(ddulck), // DCM LOCK status output
      .PSDONE(), // Dynamic phase adjust done output
      .STATUS(), // 8-bit DCM status bits output
      .CLKFB(CLKDDU),   // DCM clock feedback
      .CLKIN(CLKIN2),   // Clock input (from IBUFG, BUFG or DCM)
      .PSCLK(),   // Dynamic phase adjust clock input
      .PSEN(),     // Dynamic phase adjust enable input
      .PSINCDEC(), // Dynamic phase adjust increment/decrement
      .RST(1'b0)        // DCM asynchronous reset input
   );

assign FIFORCLK1 = r_ffclk;
assign FIFORCLK2 = r_ffclk;
BUFG BUFG_clkcms_i (.O(CLKCMS),.I(r_clkcms));
BUFG BUFG_clk80_i  (.O(CLK80),.I(r_clk80));
BUFG BUFG_clkddu_i (.O(CLKDDU),.I(r_clkddu));
BUFG BUFG_dv128_i  (.O(DV128CLK),.I(r_dv128clk));

srl_16dx1 cmslckdly_i (.CLK(CLK80), .CE(1'b1),.A(4'hF),.I(cmslck),.O(lock1),.Q15());
srl_16dx1 ddulckdly_i (.CLK(CLKDDU),.CE(1'b1),.A(4'hF),.I(ddulck),.O(lock2),.Q15());

always @(posedge CLKCMS)
begin
	READY <= lock1 & lock2;
end

srl_16dx1 dv128clksrl_1 (.CLK(CLKCMS), .CE(1'b1),.A(4'hF),.I(~r_dv128clk),.O(imclk1),    .Q15());
srl_16dx1 dv128clksrl_2 (.CLK(CLKCMS), .CE(1'b1),.A(4'hF),.I(imclk1),     .O(imclk2),    .Q15());
srl_16dx1 dv128clksrl_3 (.CLK(CLKCMS), .CE(1'b1),.A(4'hF),.I(imclk2),     .O(imclk3),    .Q15());
srl_16dx1 dv128clksrl_4 (.CLK(CLKCMS), .CE(1'b1),.A(4'hF),.I(imclk3),     .O(r_dv128clk),.Q15());


endmodule
