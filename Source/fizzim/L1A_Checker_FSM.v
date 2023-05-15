
// Created by fizzim_tmr.pl version $Revision: 4.44 on 2022:11:18 at 15:42:01 (www.fizzim.com)

module L1A_Checker_FSM (
  output reg ACT_CHK,
  output reg CAP_L1A,
  output reg CE_B4,
  output reg CE_B5,
  output reg CE_L1H,
  output reg CE_L1L,
  output reg CLR_DONE,
  output reg DATA_HLDOFF,
  output reg DOCHK,
  output reg DODAT,
  output reg INPROG,
  output reg READ_ENA,
  output reg STRT_TAIL,
  output reg TRANS_L1A,
  input ALCT_TMB_ACT,
  input CFEB_ACT,
  input CLK,
  input DONE_CE,
  input EOE,
  input GO,
  input GOB5,
  input HEADER_END,
  input L1A_EQ,
  input L1A_LT,
  input LAST,
  input MT,
  input RST 
);

  // state bits
  parameter 
  Idle           = 5'b00000, 
  Act_Chk        = 5'b00001, 
  DONE_FLUSH     = 5'b00010, 
  Flush2Last     = 5'b00011, 
  L1A_Chk        = 5'b00100, 
  Pause          = 5'b00101, 
  Pop1           = 5'b00110, 
  Pop2           = 5'b00111, 
  Pop3           = 5'b01000, 
  Pop4           = 5'b01001, 
  Proc_Data      = 5'b01010, 
  Save_L1A       = 5'b01011, 
  Start_Chk      = 5'b01100, 
  Start_Data     = 5'b01101, 
  Start_Tail     = 5'b01110, 
  Strt_Proc_Data = 5'b01111, 
  Trans_L1A      = 5'b10000; 

  reg [4:0] state;


  reg [4:0] nextstate;



  // comb always block
  always @* begin
    nextstate = 5'bxxxxx; // default to x because default_state_is_x is set
    case (state)
      Idle          : if      (HEADER_END)    nextstate = Act_Chk;
                      else                    nextstate = Idle;
      Act_Chk       : if      (ALCT_TMB_ACT)  nextstate = Start_Data;
                      else if (CFEB_ACT)      nextstate = Start_Chk;
                      else if (EOE)           nextstate = Start_Tail;
                      else                    nextstate = Act_Chk;
      DONE_FLUSH    :                         nextstate = Act_Chk;
      Flush2Last    : if      (LAST)          nextstate = Start_Chk;
                      else if (MT)            nextstate = DONE_FLUSH;
                      else                    nextstate = Flush2Last;
      L1A_Chk       : if      (L1A_EQ)        nextstate = Pop4;
                      else if (L1A_LT)        nextstate = Flush2Last;
                      else                    nextstate = Save_L1A;
      Pause         :                         nextstate = L1A_Chk;
      Pop1          :                         nextstate = Pop2;
      Pop2          :                         nextstate = Pop3;
      Pop3          :                         nextstate = Pause;
      Pop4          :                         nextstate = Start_Data;
      Proc_Data     : if      (DONE_CE)       nextstate = Act_Chk;
                      else                    nextstate = Proc_Data;
      Save_L1A      :                         nextstate = Act_Chk;
      Start_Chk     : if      (GOB5)          nextstate = Trans_L1A;
                      else if (GO)            nextstate = Pop1;
                      else                    nextstate = Start_Chk;
      Start_Data    : if      (GO)            nextstate = Strt_Proc_Data;
                      else                    nextstate = Start_Data;
      Start_Tail    :                         nextstate = Idle;
      Strt_Proc_Data:                         nextstate = Proc_Data;
      Trans_L1A     :                         nextstate = L1A_Chk;
    endcase
  end

  // Assign reg'd outputs to state bits

  // sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST)
      state <= Idle;
    else
      state <= nextstate;
  end

  // datapath sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      ACT_CHK <= 0;
      CAP_L1A <= 0;
      CE_B4 <= 0;
      CE_B5 <= 0;
      CE_L1H <= 0;
      CE_L1L <= 0;
      CLR_DONE <= 0;
      DATA_HLDOFF <= 0;
      DOCHK <= 0;
      DODAT <= 0;
      INPROG <= 0;
      READ_ENA <= 0;
      STRT_TAIL <= 0;
      TRANS_L1A <= 0;
    end
    else begin
      ACT_CHK <= 0; // default
      CAP_L1A <= 0; // default
      CE_B4 <= 0; // default
      CE_B5 <= 0; // default
      CE_L1H <= 0; // default
      CE_L1L <= 0; // default
      CLR_DONE <= 0; // default
      DATA_HLDOFF <= 0; // default
      DOCHK <= 0; // default
      DODAT <= 0; // default
      INPROG <= 1; // default
      READ_ENA <= 0; // default
      STRT_TAIL <= 0; // default
      TRANS_L1A <= 0; // default
      case (nextstate)
        Idle          :        INPROG <= 0;
        Act_Chk       : begin
                               ACT_CHK <= 1;
                               DATA_HLDOFF <= 1;
        end
        DONE_FLUSH    : begin
                               CLR_DONE <= 1;
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
        end
        Flush2Last    : begin
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
                               READ_ENA <= 1;
        end
        L1A_Chk       : begin
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
        end
        Pause         : begin
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
        end
        Pop1          : begin
                               CE_B4 <= 1;
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
                               READ_ENA <= 1;
        end
        Pop2          : begin
                               CE_L1L <= 1;
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
                               READ_ENA <= 1;
        end
        Pop3          : begin
                               CE_L1H <= 1;
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
                               READ_ENA <= 1;
        end
        Pop4          : begin
                               CE_B5 <= 1;
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
                               READ_ENA <= 1;
        end
        Proc_Data     :        DODAT <= 1;
        Save_L1A      : begin
                               CAP_L1A <= 1;
                               CLR_DONE <= 1;
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
        end
        Start_Chk     : begin
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
        end
        Start_Data    : begin
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
        end
        Start_Tail    : begin
                               INPROG <= 0;
                               STRT_TAIL <= 1;
        end
        Strt_Proc_Data: begin
                               DATA_HLDOFF <= 1;
                               DODAT <= 1;
        end
        Trans_L1A     : begin
                               DATA_HLDOFF <= 1;
                               DOCHK <= 1;
                               TRANS_L1A <= 1;
        end
      endcase
    end
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [111:0] statename;
  always @* begin
    case (state)
      Idle          : statename = "Idle";
      Act_Chk       : statename = "Act_Chk";
      DONE_FLUSH    : statename = "DONE_FLUSH";
      Flush2Last    : statename = "Flush2Last";
      L1A_Chk       : statename = "L1A_Chk";
      Pause         : statename = "Pause";
      Pop1          : statename = "Pop1";
      Pop2          : statename = "Pop2";
      Pop3          : statename = "Pop3";
      Pop4          : statename = "Pop4";
      Proc_Data     : statename = "Proc_Data";
      Save_L1A      : statename = "Save_L1A";
      Start_Chk     : statename = "Start_Chk";
      Start_Data    : statename = "Start_Data";
      Start_Tail    : statename = "Start_Tail";
      Strt_Proc_Data: statename = "Strt_Proc_Data";
      Trans_L1A     : statename = "Trans_L1A";
      default       : statename = "XXXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

