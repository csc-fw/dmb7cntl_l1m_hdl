DMB Control firmware HDL version
================================================================
Official firmware for the Control FPGA in the DMBs (not ODMBs)
This repository contains the HDL source code only, no ISE project files
The target FPGA is a Virtex II 500 (xc2v500-4fg456)
This code is designed to be compatible with CFEBs and DCFEBs (pre-LCT or L1A_Matches sent to FEB).
This code can accomodate 12.5 uSec L1A latencies.
If the DMB's are modified, this code can encode the trigger info
to include pre-LCTs, L1A_Matches, L1A, and Resyncs in 3 bits.  This allows
CFEBs to only readout on L1A_Matches with the full LCT (not just pre-LCT).

