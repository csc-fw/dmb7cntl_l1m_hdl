
// Created by fizzim_tmr.pl version $Revision: 4.44 on 2023:06:27 at 16:16:14 (www.fizzim.com)

module L1A_Checker_FSM (
  output reg ACT_CHK,
  output reg CAP_L1A,
  output reg CE_B4,
  output reg CE_B5,
  output reg CE_L1H,
  output reg CE_L1L,
  output reg CLR_DONE,
  output reg DATA_CE,
  output reg DATA_HLDOFF,
  output reg DOCHK,
  output reg DODAT,
  output reg DO_ERR,
  output reg FLUSHING,
  output reg INPROG,
  output reg MISSING_DAT,
  output reg NOEND_ERROR,
  output reg READ_ENA,
  output reg STRT_TAIL,
  output reg TRANS_L1A,
  output reg TRANS_TORA,
  input ALCT_FLG,
  input ALCT_TMB_ACT,
  input B4_PRESENT,
  input CFEB_ACT,
  input CLK,
  input DONE_CE,
  input EOE,
  input ERR_AKN,
  input EXTND_MT,
  input GO,
  input GOB5,
  input HEADER_END,
  input L1A_EQ,
  input L1A_LT,
  input LAST,
  input MT,
  input NEW_CFEB,
  input NEW_EVENT,
  input NEW_TORA,
  input PROC_TMO,
  input RST,
  input STRT_TMO,
  input TMB_FLG,
  input TRANS_FLG 
);

  // state bits
  parameter 
  Idle            = 5'b00000, 
  Act_Chk         = 5'b00001, 
  DONE_FLUSH      = 5'b00010, 
  END_PROC1       = 5'b00011, 
  END_PROC2       = 5'b00100, 
  Flush2Last      = 5'b00101, 
  L1A_Chk         = 5'b00110, 
  NO_END1         = 5'b00111, 
  NO_END2         = 5'b01000, 
  Pause           = 5'b01001, 
  Pop0            = 5'b01010, 
  Pop1            = 5'b01011, 
  Pop2            = 5'b01100, 
  Pop3            = 5'b01101, 
  Pop4            = 5'b01110, 
  Proc_Data       = 5'b01111, 
  Save_L1A        = 5'b10000, 
  Start_Chk       = 5'b10001, 
  Start_Data      = 5'b10010, 
  Start_Hold      = 5'b10011, 
  Start_Tail      = 5'b10100, 
  Strt_Proc_Data1 = 5'b10101, 
  Strt_Proc_Data2 = 5'b10110, 
  Strt_Proc_Data3 = 5'b10111, 
  Trans_L1A       = 5'b11000, 
  Trans_Tora1     = 5'b11001, 
  Trans_Tora2     = 5'b11010, 
  Trans_Tora3     = 5'b11011; 

  reg [4:0] state;


  reg [4:0] nextstate;



  // comb always block
  always @* begin
    nextstate = 5'bxxxxx; // default to x because default_state_is_x is set
    case (state)
      Idle           : if      (HEADER_END)                           nextstate = Start_Hold;
                       else                                           nextstate = Idle;
      Act_Chk        : if      (ALCT_TMB_ACT)                         nextstate = Start_Data;
                       else if (CFEB_ACT)                             nextstate = Start_Chk;
                       else if (EOE)                                  nextstate = Start_Tail;
                       else                                           nextstate = Act_Chk;
      DONE_FLUSH     :                                                nextstate = Act_Chk;
      END_PROC1      :                                                nextstate = END_PROC2;
      END_PROC2      :                                                nextstate = Act_Chk;
      Flush2Last     : if      (LAST)                                 nextstate = Start_Chk;
                       else if (NEW_EVENT)                            nextstate = Pop2;
                       else if (MT)                                   nextstate = DONE_FLUSH;
                       else                                           nextstate = Flush2Last;
      L1A_Chk        : if      (L1A_EQ)                               nextstate = Pop4;
                       else if (L1A_LT)                               nextstate = Flush2Last;
                       else                                           nextstate = Save_L1A;
      NO_END1        :                                                nextstate = NO_END2;
      NO_END2        : if      ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate = Act_Chk;
                       else                                           nextstate = NO_END2;
      Pause          :                                                nextstate = L1A_Chk;
      Pop0           :                                                nextstate = Pop1;
      Pop1           :                                                nextstate = Pop2;
      Pop2           :                                                nextstate = Pop3;
      Pop3           : if      (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate = Pause;
                       else                                           nextstate = Flush2Last;
      Pop4           :                                                nextstate = Start_Data;
      Proc_Data      : if      (DONE_CE)                              nextstate = END_PROC1;
                       else if (NEW_TORA)                             nextstate = NO_END1;
                       else if (NEW_CFEB)                             nextstate = Pop2;
                       else if (PROC_TMO)                             nextstate = Act_Chk;
                       else                                           nextstate = Proc_Data;
      Save_L1A       : if      (NEW_CFEB)                             nextstate = NO_END2;
                       else                                           nextstate = Act_Chk;
      Start_Chk      : if      (GOB5)                                 nextstate = Trans_L1A;
                       else if (GO)                                   nextstate = Pop0;
                       else                                           nextstate = Start_Chk;
      Start_Data     : if      (GO && TRANS_FLG)                      nextstate = Trans_Tora1;
                       else if (GO)                                   nextstate = Strt_Proc_Data1;
                       else                                           nextstate = Start_Data;
      Start_Hold     : if      (STRT_TMO)                             nextstate = Act_Chk;
                       else                                           nextstate = Start_Hold;
      Start_Tail     :                                                nextstate = Idle;
      Strt_Proc_Data1:                                                nextstate = Strt_Proc_Data2;
      Strt_Proc_Data2:                                                nextstate = Strt_Proc_Data3;
      Strt_Proc_Data3:                                                nextstate = Proc_Data;
      Trans_L1A      :                                                nextstate = L1A_Chk;
      Trans_Tora1    :                                                nextstate = Trans_Tora2;
      Trans_Tora2    :                                                nextstate = Trans_Tora3;
      Trans_Tora3    :                                                nextstate = Proc_Data;
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
      DATA_CE <= 0;
      DATA_HLDOFF <= 0;
      DOCHK <= 0;
      DODAT <= 0;
      DO_ERR <= 0;
      FLUSHING <= 0;
      INPROG <= 0;
      MISSING_DAT <= 0;
      NOEND_ERROR <= 0;
      READ_ENA <= 0;
      STRT_TAIL <= 0;
      TRANS_L1A <= 0;
      TRANS_TORA <= 0;
    end
    else begin
      ACT_CHK <= 0; // default
      CAP_L1A <= 0; // default
      CE_B4 <= 0; // default
      CE_B5 <= 0; // default
      CE_L1H <= 0; // default
      CE_L1L <= 0; // default
      CLR_DONE <= 0; // default
      DATA_CE <= 0; // default
      DATA_HLDOFF <= 0; // default
      DOCHK <= 0; // default
      DODAT <= 0; // default
      DO_ERR <= 0; // default
      FLUSHING <= 0; // default
      INPROG <= 1; // default
      MISSING_DAT <= 0; // default
      NOEND_ERROR <= 0; // default
      READ_ENA <= 0; // default
      STRT_TAIL <= 0; // default
      TRANS_L1A <= 0; // default
      TRANS_TORA <= 0; // default
      case (nextstate)
        Idle           :        INPROG <= 0;
        Act_Chk        : begin
                                ACT_CHK <= 1;
                                DATA_HLDOFF <= 1;
        end
        DONE_FLUSH     : begin
                                CLR_DONE <= 1;
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
        end
        END_PROC1      :        DODAT <= 1;
        END_PROC2      :        DODAT <= 1;
        Flush2Last     : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                FLUSHING <= 1;
                                READ_ENA <= 1;
        end
        L1A_Chk        : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
        end
        NO_END1        : begin
                                DATA_CE <= 1;
                                DATA_HLDOFF <= 1;
                                DO_ERR <= 1;
                                NOEND_ERROR <= 1;
        end
        NO_END2        : begin
                                DATA_HLDOFF <= 1;
                                DO_ERR <= 1;
                                NOEND_ERROR <= 1;
        end
        Pause          : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
        end
        Pop0           : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                READ_ENA <= 1;
        end
        Pop1           : begin
                                CE_B4 <= 1;
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                READ_ENA <= 1;
        end
        Pop2           : begin
                                CE_L1L <= 1;
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                READ_ENA <= 1;
        end
        Pop3           : begin
                                CE_L1H <= 1;
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
        end
        Pop4           : begin
                                CE_B5 <= 1;
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                READ_ENA <= 1;
        end
        Proc_Data      : begin
                                DATA_CE <= 1;
                                DODAT <= 1;
        end
        Save_L1A       : begin
                                CAP_L1A <= 1;
                                CLR_DONE <= !NEW_CFEB;
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                MISSING_DAT <= !NEW_CFEB;
        end
        Start_Chk      : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
        end
        Start_Data     : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
        end
        Start_Hold     : begin
                                ACT_CHK <= 1;
                                DATA_HLDOFF <= 1;
        end
        Start_Tail     : begin
                                INPROG <= 0;
                                STRT_TAIL <= 1;
        end
        Strt_Proc_Data1: begin
                                DATA_CE <= 1;
                                DATA_HLDOFF <= 1;
                                DODAT <= 1;
        end
        Strt_Proc_Data2: begin
                                DATA_CE <= 1;
                                DATA_HLDOFF <= 1;
                                DODAT <= 1;
        end
        Strt_Proc_Data3: begin
                                DATA_CE <= 1;
                                DATA_HLDOFF <= 1;
                                DODAT <= 1;
        end
        Trans_L1A      : begin
                                DATA_HLDOFF <= 1;
                                DOCHK <= 1;
                                TRANS_L1A <= 1;
        end
        Trans_Tora1    : begin
                                DATA_HLDOFF <= 1;
                                DODAT <= 1;
                                TRANS_TORA <= 1;
        end
        Trans_Tora2    : begin
                                DATA_HLDOFF <= 1;
                                DODAT <= 1;
                                TRANS_TORA <= 1;
        end
        Trans_Tora3    :        DODAT <= 1;
      endcase
    end
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [119:0] statename;
  always @* begin
    case (state)
      Idle           : statename = "Idle";
      Act_Chk        : statename = "Act_Chk";
      DONE_FLUSH     : statename = "DONE_FLUSH";
      END_PROC1      : statename = "END_PROC1";
      END_PROC2      : statename = "END_PROC2";
      Flush2Last     : statename = "Flush2Last";
      L1A_Chk        : statename = "L1A_Chk";
      NO_END1        : statename = "NO_END1";
      NO_END2        : statename = "NO_END2";
      Pause          : statename = "Pause";
      Pop0           : statename = "Pop0";
      Pop1           : statename = "Pop1";
      Pop2           : statename = "Pop2";
      Pop3           : statename = "Pop3";
      Pop4           : statename = "Pop4";
      Proc_Data      : statename = "Proc_Data";
      Save_L1A       : statename = "Save_L1A";
      Start_Chk      : statename = "Start_Chk";
      Start_Data     : statename = "Start_Data";
      Start_Hold     : statename = "Start_Hold";
      Start_Tail     : statename = "Start_Tail";
      Strt_Proc_Data1: statename = "Strt_Proc_Data1";
      Strt_Proc_Data2: statename = "Strt_Proc_Data2";
      Strt_Proc_Data3: statename = "Strt_Proc_Data3";
      Trans_L1A      : statename = "Trans_L1A";
      Trans_Tora1    : statename = "Trans_Tora1";
      Trans_Tora2    : statename = "Trans_Tora2";
      Trans_Tora3    : statename = "Trans_Tora3";
      default        : statename = "XXXXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

