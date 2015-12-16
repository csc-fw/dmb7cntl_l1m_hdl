`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Ben Bylsma
// 
// Create Date:    12:30:24 10/11/2010 
// Design Name: 
// Module Name:    instr_dcd 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
//   Performs instruction register decoding (JTAG User1 register).
//
// Function  Description
// ---------------------------------------
//   0     | No Op 
//   1     | JTAG System Reset
//   2     | Preset/Clear certain JTAG registers to their firmware defaults
//   3     | BUCKEYE Inject
//   4     | BUCKEYE Pulse
//   5     | Pedestal data taking
//   6     | Load Trigger Register
//   7     | Cycle Trigger Register Once
//   8     | Continuously Cycle Trigger Register
//   9     | Load CFEB selection Register
//  10     | DAQMB Status
//  11     | Trigger select in cal_mode
//  12     | FIFO manual read control
//  13     | DAV Delay Setting
//  14     | FIFO Master Reset and GLINK Reset
//  15     | Load DAQMB Crate ID
//  16     | Load CFEB Clock Delay
//  17     | Set Calibration timing (Calib Pulse Delay)
//  18     | Set Loop Back for Glink, toggling (obsolete - not connected to Glink)
//  19     | Load Random Trigger Frequency
//  20     | Toggle Random trigger start control
//  21     | Serial Flash Memory
//  22     | Serial Flash Memory
//  23     | Serial Flash Memory
//  24     | Serial Flash Memory
//  25     | Serial Flash Memory
//  26     | Serial Flash Memory
//  27     | Serial Flash Memory
//  28     | Load Cable Delay
//  29     | Serial Flash Memory
//  30     | Serial Flash Memory
//  31     | Serial Flash Memory
//  32     | Burst of 1000 (really 512+256+128) Random events (L1ACC)
//  33     | Load the LCT_request delay and control the LCT request signal
//  34     | To toggle the max BX_counter number, default to 923, toggle to 3563 (obsolete)
//  35     | Serial Flash Memory Test
//  36     | Delay Counter readout, similar to function 10, status monitor
//  37     | 
//  38     | DAV timing readout, "Scope"
//  39     | Enable All CFEB data
//  40     | Load Extra L1A latency adjustment for Calibration mode  (obsolete)
//  41     | L1A fine Delay (obsolete)
//  42     | Load (update) the xL1ALatency (work with Function 40)
//  43     | Load (update) the L1A Fine delay (work with Function 41)
//  44     | Set the Kill Input bits (obsolete -- done with instruction 16 instead)
//  45     | Load (update) the Kill Input (work with Function 44)
//  46     | Set DCFEB_IN_USE bit and OPT_COP_ADJ delay (1+3 bits)
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module instr_dcd(
  input CLK,  //CMS clock for update register
  input DRCK,
  input SEL,
  input TDI,
  input UPDATE,
  input SHIFT,
  input RST,
  input CLR,            // clear current instruction
  output reg [47:0] F,
  output TDO);

  reg[7:0] d;
  wire rst_f;
  reg update_1;
  wire update_ce;
  
  assign TDO = d[0];
  assign rst_f = RST | CLR;
  assign update_ce = SEL & ~UPDATE & update_1; //trailing edge of UPDATE, one CLK cycle long
  
  always @(posedge DRCK or posedge RST) begin
    if (RST)
	   d <= 8'h00;
	 else
      if (SEL & SHIFT)
        d <= {TDI,d[7:1]};
		else
		  d <= d;
  end
  
  always @(posedge CLK) begin
    update_1 <= UPDATE;
  end
  
  always @(posedge CLK or posedge rst_f) begin
    if(rst_f)
	   F <= 48'h000000000000;
	 else
	   if(update_ce)
		  case (d)
		    8'h00:   F <= 48'h000000000001;
		    8'h01:   F <= 48'h000000000002;
		    8'h02:   F <= 48'h000000000004;
		    8'h03:   F <= 48'h000000000008;
		    8'h04:   F <= 48'h000000000010;
		    8'h05:   F <= 48'h000000000020;
		    8'h06:   F <= 48'h000000000040;
		    8'h07:   F <= 48'h000000000080;
		    8'h08:   F <= 48'h000000000100;
		    8'h09:   F <= 48'h000000000200;
		    8'h0A:   F <= 48'h000000000400;
		    8'h0B:   F <= 48'h000000000800;
		    8'h0C:   F <= 48'h000000001000;
		    8'h0D:   F <= 48'h000000002000;
		    8'h0E:   F <= 48'h000000004000;
		    8'h0F:   F <= 48'h000000008000;
			 
		    8'h10:   F <= 48'h000000010000;
		    8'h11:   F <= 48'h000000020000;
		    8'h12:   F <= 48'h000000040000;
		    8'h13:   F <= 48'h000000080000;
		    8'h14:   F <= 48'h000000100000;
		    8'h15:   F <= 48'h000000200000;
		    8'h16:   F <= 48'h000000400000;
		    8'h17:   F <= 48'h000000800000;
		    8'h18:   F <= 48'h000001000000;
		    8'h19:   F <= 48'h000002000000;
		    8'h1A:   F <= 48'h000004000000;
		    8'h1B:   F <= 48'h000008000000;
		    8'h1C:   F <= 48'h000010000000;
		    8'h1D:   F <= 48'h000020000000;
		    8'h1E:   F <= 48'h000040000000;
		    8'h1F:   F <= 48'h000080000000;
			 
		    8'h20:   F <= 48'h000100000000;
		    8'h21:   F <= 48'h000200000000;
		    8'h22:   F <= 48'h000400000000;
		    8'h23:   F <= 48'h000800000000;
		    8'h24:   F <= 48'h001000000000;
		    8'h25:   F <= 48'h002000000000;
		    8'h26:   F <= 48'h004000000000;
		    8'h27:   F <= 48'h008000000000;
		    8'h28:   F <= 48'h010000000000;
		    8'h29:   F <= 48'h020000000000;
		    8'h2A:   F <= 48'h040000000000;
		    8'h2B:   F <= 48'h080000000000;
		    8'h2C:   F <= 48'h100000000000;
		    8'h2D:   F <= 48'h200000000000;
		    8'h2E:   F <= 48'h400000000000;
		    8'h2F:   F <= 48'h800000000000;
			 
		  endcase
		else
		  F <= F;
  end
  
endmodule
