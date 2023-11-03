
// Created by fizzim_tmr.pl version $Revision: 4.44 on 2023:09:01 at 09:16:07 (www.fizzim.com)

module L1A_Checker_FSM_TMR (
  output ACT_CHK,
  output CAP_L1A,
  output CE_B4,
  output CE_B5,
  output CE_L1H,
  output CE_L1L,
  output CLR_DONE,
  output DATA_CE,
  output DATA_HLDOFF,
  output DOCHK,
  output DODAT,
  output DO_ERR,
  output FLUSHING,
  output INPROG,
  output MISSING_DAT,
  output NOEND_ERROR,
  output PROC_DATA,
  output READ_ENA,
  output STRT_TAIL,
  output TRANS_L1A,
  output TRANS_TORA,
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
  Trans_Tora1     = 5'b11001; 

  (* syn_preserve = "true" *) reg [4:0] state_1;
  (* syn_preserve = "true" *) reg [4:0] state_2;
  (* syn_preserve = "true" *) reg [4:0] state_3;

  (* syn_keep = "true" *) wire [4:0] voted_state_1;
  (* syn_keep = "true" *) wire [4:0] voted_state_2;
  (* syn_keep = "true" *) wire [4:0] voted_state_3;

  assign voted_state_1       = (state_1       & state_2      ) | (state_2       & state_3      ) | (state_1       & state_3      ); // Majority logic
  assign voted_state_2       = (state_1       & state_2      ) | (state_2       & state_3      ) | (state_1       & state_3      ); // Majority logic
  assign voted_state_3       = (state_1       & state_2      ) | (state_2       & state_3      ) | (state_1       & state_3      ); // Majority logic


  (* syn_keep = "true" *) reg [4:0] nextstate_1;
  (* syn_keep = "true" *) reg [4:0] nextstate_2;
  (* syn_keep = "true" *) reg [4:0] nextstate_3;


  (* syn_preserve = "true" *)  reg ACT_CHK_1;
  (* syn_preserve = "true" *)  reg ACT_CHK_2;
  (* syn_preserve = "true" *)  reg ACT_CHK_3;
  (* syn_preserve = "true" *)  reg CAP_L1A_1;
  (* syn_preserve = "true" *)  reg CAP_L1A_2;
  (* syn_preserve = "true" *)  reg CAP_L1A_3;
  (* syn_preserve = "true" *)  reg CE_B4_1;
  (* syn_preserve = "true" *)  reg CE_B4_2;
  (* syn_preserve = "true" *)  reg CE_B4_3;
  (* syn_preserve = "true" *)  reg CE_B5_1;
  (* syn_preserve = "true" *)  reg CE_B5_2;
  (* syn_preserve = "true" *)  reg CE_B5_3;
  (* syn_preserve = "true" *)  reg CE_L1H_1;
  (* syn_preserve = "true" *)  reg CE_L1H_2;
  (* syn_preserve = "true" *)  reg CE_L1H_3;
  (* syn_preserve = "true" *)  reg CE_L1L_1;
  (* syn_preserve = "true" *)  reg CE_L1L_2;
  (* syn_preserve = "true" *)  reg CE_L1L_3;
  (* syn_preserve = "true" *)  reg CLR_DONE_1;
  (* syn_preserve = "true" *)  reg CLR_DONE_2;
  (* syn_preserve = "true" *)  reg CLR_DONE_3;
  (* syn_preserve = "true" *)  reg DATA_CE_1;
  (* syn_preserve = "true" *)  reg DATA_CE_2;
  (* syn_preserve = "true" *)  reg DATA_CE_3;
  (* syn_preserve = "true" *)  reg DATA_HLDOFF_1;
  (* syn_preserve = "true" *)  reg DATA_HLDOFF_2;
  (* syn_preserve = "true" *)  reg DATA_HLDOFF_3;
  (* syn_preserve = "true" *)  reg DOCHK_1;
  (* syn_preserve = "true" *)  reg DOCHK_2;
  (* syn_preserve = "true" *)  reg DOCHK_3;
  (* syn_preserve = "true" *)  reg DODAT_1;
  (* syn_preserve = "true" *)  reg DODAT_2;
  (* syn_preserve = "true" *)  reg DODAT_3;
  (* syn_preserve = "true" *)  reg DO_ERR_1;
  (* syn_preserve = "true" *)  reg DO_ERR_2;
  (* syn_preserve = "true" *)  reg DO_ERR_3;
  (* syn_preserve = "true" *)  reg FLUSHING_1;
  (* syn_preserve = "true" *)  reg FLUSHING_2;
  (* syn_preserve = "true" *)  reg FLUSHING_3;
  (* syn_preserve = "true" *)  reg INPROG_1;
  (* syn_preserve = "true" *)  reg INPROG_2;
  (* syn_preserve = "true" *)  reg INPROG_3;
  (* syn_preserve = "true" *)  reg MISSING_DAT_1;
  (* syn_preserve = "true" *)  reg MISSING_DAT_2;
  (* syn_preserve = "true" *)  reg MISSING_DAT_3;
  (* syn_preserve = "true" *)  reg NOEND_ERROR_1;
  (* syn_preserve = "true" *)  reg NOEND_ERROR_2;
  (* syn_preserve = "true" *)  reg NOEND_ERROR_3;
  (* syn_preserve = "true" *)  reg PROC_DATA_1;
  (* syn_preserve = "true" *)  reg PROC_DATA_2;
  (* syn_preserve = "true" *)  reg PROC_DATA_3;
  (* syn_preserve = "true" *)  reg READ_ENA_1;
  (* syn_preserve = "true" *)  reg READ_ENA_2;
  (* syn_preserve = "true" *)  reg READ_ENA_3;
  (* syn_preserve = "true" *)  reg STRT_TAIL_1;
  (* syn_preserve = "true" *)  reg STRT_TAIL_2;
  (* syn_preserve = "true" *)  reg STRT_TAIL_3;
  (* syn_preserve = "true" *)  reg TRANS_L1A_1;
  (* syn_preserve = "true" *)  reg TRANS_L1A_2;
  (* syn_preserve = "true" *)  reg TRANS_L1A_3;
  (* syn_preserve = "true" *)  reg TRANS_TORA_1;
  (* syn_preserve = "true" *)  reg TRANS_TORA_2;
  (* syn_preserve = "true" *)  reg TRANS_TORA_3;

  // Assignment of outputs and flags to voted majority logic of replicated registers
  assign ACT_CHK     = (ACT_CHK_1     & ACT_CHK_2    ) | (ACT_CHK_2     & ACT_CHK_3    ) | (ACT_CHK_1     & ACT_CHK_3    ); // Majority logic
  assign CAP_L1A     = (CAP_L1A_1     & CAP_L1A_2    ) | (CAP_L1A_2     & CAP_L1A_3    ) | (CAP_L1A_1     & CAP_L1A_3    ); // Majority logic
  assign CE_B4       = (CE_B4_1       & CE_B4_2      ) | (CE_B4_2       & CE_B4_3      ) | (CE_B4_1       & CE_B4_3      ); // Majority logic
  assign CE_B5       = (CE_B5_1       & CE_B5_2      ) | (CE_B5_2       & CE_B5_3      ) | (CE_B5_1       & CE_B5_3      ); // Majority logic
  assign CE_L1H      = (CE_L1H_1      & CE_L1H_2     ) | (CE_L1H_2      & CE_L1H_3     ) | (CE_L1H_1      & CE_L1H_3     ); // Majority logic
  assign CE_L1L      = (CE_L1L_1      & CE_L1L_2     ) | (CE_L1L_2      & CE_L1L_3     ) | (CE_L1L_1      & CE_L1L_3     ); // Majority logic
  assign CLR_DONE    = (CLR_DONE_1    & CLR_DONE_2   ) | (CLR_DONE_2    & CLR_DONE_3   ) | (CLR_DONE_1    & CLR_DONE_3   ); // Majority logic
  assign DATA_CE     = (DATA_CE_1     & DATA_CE_2    ) | (DATA_CE_2     & DATA_CE_3    ) | (DATA_CE_1     & DATA_CE_3    ); // Majority logic
  assign DATA_HLDOFF = (DATA_HLDOFF_1 & DATA_HLDOFF_2) | (DATA_HLDOFF_2 & DATA_HLDOFF_3) | (DATA_HLDOFF_1 & DATA_HLDOFF_3); // Majority logic
  assign DOCHK       = (DOCHK_1       & DOCHK_2      ) | (DOCHK_2       & DOCHK_3      ) | (DOCHK_1       & DOCHK_3      ); // Majority logic
  assign DODAT       = (DODAT_1       & DODAT_2      ) | (DODAT_2       & DODAT_3      ) | (DODAT_1       & DODAT_3      ); // Majority logic
  assign DO_ERR      = (DO_ERR_1      & DO_ERR_2     ) | (DO_ERR_2      & DO_ERR_3     ) | (DO_ERR_1      & DO_ERR_3     ); // Majority logic
  assign FLUSHING    = (FLUSHING_1    & FLUSHING_2   ) | (FLUSHING_2    & FLUSHING_3   ) | (FLUSHING_1    & FLUSHING_3   ); // Majority logic
  assign INPROG      = (INPROG_1      & INPROG_2     ) | (INPROG_2      & INPROG_3     ) | (INPROG_1      & INPROG_3     ); // Majority logic
  assign MISSING_DAT = (MISSING_DAT_1 & MISSING_DAT_2) | (MISSING_DAT_2 & MISSING_DAT_3) | (MISSING_DAT_1 & MISSING_DAT_3); // Majority logic
  assign NOEND_ERROR = (NOEND_ERROR_1 & NOEND_ERROR_2) | (NOEND_ERROR_2 & NOEND_ERROR_3) | (NOEND_ERROR_1 & NOEND_ERROR_3); // Majority logic
  assign PROC_DATA   = (PROC_DATA_1   & PROC_DATA_2  ) | (PROC_DATA_2   & PROC_DATA_3  ) | (PROC_DATA_1   & PROC_DATA_3  ); // Majority logic
  assign READ_ENA    = (READ_ENA_1    & READ_ENA_2   ) | (READ_ENA_2    & READ_ENA_3   ) | (READ_ENA_1    & READ_ENA_3   ); // Majority logic
  assign STRT_TAIL   = (STRT_TAIL_1   & STRT_TAIL_2  ) | (STRT_TAIL_2   & STRT_TAIL_3  ) | (STRT_TAIL_1   & STRT_TAIL_3  ); // Majority logic
  assign TRANS_L1A   = (TRANS_L1A_1   & TRANS_L1A_2  ) | (TRANS_L1A_2   & TRANS_L1A_3  ) | (TRANS_L1A_1   & TRANS_L1A_3  ); // Majority logic
  assign TRANS_TORA  = (TRANS_TORA_1  & TRANS_TORA_2 ) | (TRANS_TORA_2  & TRANS_TORA_3 ) | (TRANS_TORA_1  & TRANS_TORA_3 ); // Majority logic

  // Assignment of error detection logic to replicated signals

  // comb always block
  always @* begin
    nextstate_1 = 5'bxxxxx; // default to x because default_state_is_x is set
    nextstate_2 = 5'bxxxxx; // default to x because default_state_is_x is set
    nextstate_3 = 5'bxxxxx; // default to x because default_state_is_x is set
    case (voted_state_1)
      Idle           : if      (HEADER_END)                           nextstate_1 = Start_Hold;
                       else                                           nextstate_1 = Idle;
      Act_Chk        : if      (ALCT_TMB_ACT)                         nextstate_1 = Start_Data;
                       else if (CFEB_ACT)                             nextstate_1 = Start_Chk;
                       else if (EOE)                                  nextstate_1 = Start_Tail;
                       else                                           nextstate_1 = Act_Chk;
      DONE_FLUSH     :                                                nextstate_1 = Act_Chk;
      END_PROC1      :                                                nextstate_1 = END_PROC2;
      END_PROC2      :                                                nextstate_1 = Act_Chk;
      Flush2Last     : if      (LAST)                                 nextstate_1 = Start_Chk;
                       else if (NEW_EVENT)                            nextstate_1 = Pop2;
                       else if (MT)                                   nextstate_1 = DONE_FLUSH;
                       else                                           nextstate_1 = Flush2Last;
      L1A_Chk        : if      (L1A_EQ)                               nextstate_1 = Pop4;
                       else if (L1A_LT)                               nextstate_1 = Flush2Last;
                       else                                           nextstate_1 = Save_L1A;
      NO_END1        :                                                nextstate_1 = NO_END2;
      NO_END2        : if      ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate_1 = Act_Chk;
                       else                                           nextstate_1 = NO_END2;
      Pause          :                                                nextstate_1 = L1A_Chk;
      Pop0           :                                                nextstate_1 = Pop1;
      Pop1           :                                                nextstate_1 = Pop2;
      Pop2           :                                                nextstate_1 = Pop3;
      Pop3           : if      (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate_1 = Pause;
                       else                                           nextstate_1 = Flush2Last;
      Pop4           :                                                nextstate_1 = Start_Data;
      Proc_Data      : if      (DONE_CE)                              nextstate_1 = END_PROC1;
                       else if (NEW_TORA)                             nextstate_1 = NO_END1;
                       else if (NEW_CFEB)                             nextstate_1 = Pop2;
                       else if (PROC_TMO)                             nextstate_1 = Act_Chk;
                       else                                           nextstate_1 = Proc_Data;
      Save_L1A       : if      (NEW_CFEB)                             nextstate_1 = NO_END2;
                       else                                           nextstate_1 = Act_Chk;
      Start_Chk      : if      (GOB5)                                 nextstate_1 = Trans_L1A;
                       else if (GO)                                   nextstate_1 = Pop0;
                       else                                           nextstate_1 = Start_Chk;
      Start_Data     : if      (GO && TRANS_FLG)                      nextstate_1 = Trans_Tora1;
                       else if (GO)                                   nextstate_1 = Strt_Proc_Data1;
                       else                                           nextstate_1 = Start_Data;
      Start_Hold     : if      (STRT_TMO)                             nextstate_1 = Act_Chk;
                       else                                           nextstate_1 = Start_Hold;
      Start_Tail     :                                                nextstate_1 = Idle;
      Strt_Proc_Data1:                                                nextstate_1 = Strt_Proc_Data2;
      Strt_Proc_Data2:                                                nextstate_1 = Strt_Proc_Data3;
      Strt_Proc_Data3:                                                nextstate_1 = Proc_Data;
      Trans_L1A      :                                                nextstate_1 = L1A_Chk;
      Trans_Tora1    :                                                nextstate_1 = Proc_Data;
    endcase
    case (voted_state_2)
      Idle           : if      (HEADER_END)                           nextstate_2 = Start_Hold;
                       else                                           nextstate_2 = Idle;
      Act_Chk        : if      (ALCT_TMB_ACT)                         nextstate_2 = Start_Data;
                       else if (CFEB_ACT)                             nextstate_2 = Start_Chk;
                       else if (EOE)                                  nextstate_2 = Start_Tail;
                       else                                           nextstate_2 = Act_Chk;
      DONE_FLUSH     :                                                nextstate_2 = Act_Chk;
      END_PROC1      :                                                nextstate_2 = END_PROC2;
      END_PROC2      :                                                nextstate_2 = Act_Chk;
      Flush2Last     : if      (LAST)                                 nextstate_2 = Start_Chk;
                       else if (NEW_EVENT)                            nextstate_2 = Pop2;
                       else if (MT)                                   nextstate_2 = DONE_FLUSH;
                       else                                           nextstate_2 = Flush2Last;
      L1A_Chk        : if      (L1A_EQ)                               nextstate_2 = Pop4;
                       else if (L1A_LT)                               nextstate_2 = Flush2Last;
                       else                                           nextstate_2 = Save_L1A;
      NO_END1        :                                                nextstate_2 = NO_END2;
      NO_END2        : if      ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate_2 = Act_Chk;
                       else                                           nextstate_2 = NO_END2;
      Pause          :                                                nextstate_2 = L1A_Chk;
      Pop0           :                                                nextstate_2 = Pop1;
      Pop1           :                                                nextstate_2 = Pop2;
      Pop2           :                                                nextstate_2 = Pop3;
      Pop3           : if      (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate_2 = Pause;
                       else                                           nextstate_2 = Flush2Last;
      Pop4           :                                                nextstate_2 = Start_Data;
      Proc_Data      : if      (DONE_CE)                              nextstate_2 = END_PROC1;
                       else if (NEW_TORA)                             nextstate_2 = NO_END1;
                       else if (NEW_CFEB)                             nextstate_2 = Pop2;
                       else if (PROC_TMO)                             nextstate_2 = Act_Chk;
                       else                                           nextstate_2 = Proc_Data;
      Save_L1A       : if      (NEW_CFEB)                             nextstate_2 = NO_END2;
                       else                                           nextstate_2 = Act_Chk;
      Start_Chk      : if      (GOB5)                                 nextstate_2 = Trans_L1A;
                       else if (GO)                                   nextstate_2 = Pop0;
                       else                                           nextstate_2 = Start_Chk;
      Start_Data     : if      (GO && TRANS_FLG)                      nextstate_2 = Trans_Tora1;
                       else if (GO)                                   nextstate_2 = Strt_Proc_Data1;
                       else                                           nextstate_2 = Start_Data;
      Start_Hold     : if      (STRT_TMO)                             nextstate_2 = Act_Chk;
                       else                                           nextstate_2 = Start_Hold;
      Start_Tail     :                                                nextstate_2 = Idle;
      Strt_Proc_Data1:                                                nextstate_2 = Strt_Proc_Data2;
      Strt_Proc_Data2:                                                nextstate_2 = Strt_Proc_Data3;
      Strt_Proc_Data3:                                                nextstate_2 = Proc_Data;
      Trans_L1A      :                                                nextstate_2 = L1A_Chk;
      Trans_Tora1    :                                                nextstate_2 = Proc_Data;
    endcase
    case (voted_state_3)
      Idle           : if      (HEADER_END)                           nextstate_3 = Start_Hold;
                       else                                           nextstate_3 = Idle;
      Act_Chk        : if      (ALCT_TMB_ACT)                         nextstate_3 = Start_Data;
                       else if (CFEB_ACT)                             nextstate_3 = Start_Chk;
                       else if (EOE)                                  nextstate_3 = Start_Tail;
                       else                                           nextstate_3 = Act_Chk;
      DONE_FLUSH     :                                                nextstate_3 = Act_Chk;
      END_PROC1      :                                                nextstate_3 = END_PROC2;
      END_PROC2      :                                                nextstate_3 = Act_Chk;
      Flush2Last     : if      (LAST)                                 nextstate_3 = Start_Chk;
                       else if (NEW_EVENT)                            nextstate_3 = Pop2;
                       else if (MT)                                   nextstate_3 = DONE_FLUSH;
                       else                                           nextstate_3 = Flush2Last;
      L1A_Chk        : if      (L1A_EQ)                               nextstate_3 = Pop4;
                       else if (L1A_LT)                               nextstate_3 = Flush2Last;
                       else                                           nextstate_3 = Save_L1A;
      NO_END1        :                                                nextstate_3 = NO_END2;
      NO_END2        : if      ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate_3 = Act_Chk;
                       else                                           nextstate_3 = NO_END2;
      Pause          :                                                nextstate_3 = L1A_Chk;
      Pop0           :                                                nextstate_3 = Pop1;
      Pop1           :                                                nextstate_3 = Pop2;
      Pop2           :                                                nextstate_3 = Pop3;
      Pop3           : if      (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate_3 = Pause;
                       else                                           nextstate_3 = Flush2Last;
      Pop4           :                                                nextstate_3 = Start_Data;
      Proc_Data      : if      (DONE_CE)                              nextstate_3 = END_PROC1;
                       else if (NEW_TORA)                             nextstate_3 = NO_END1;
                       else if (NEW_CFEB)                             nextstate_3 = Pop2;
                       else if (PROC_TMO)                             nextstate_3 = Act_Chk;
                       else                                           nextstate_3 = Proc_Data;
      Save_L1A       : if      (NEW_CFEB)                             nextstate_3 = NO_END2;
                       else                                           nextstate_3 = Act_Chk;
      Start_Chk      : if      (GOB5)                                 nextstate_3 = Trans_L1A;
                       else if (GO)                                   nextstate_3 = Pop0;
                       else                                           nextstate_3 = Start_Chk;
      Start_Data     : if      (GO && TRANS_FLG)                      nextstate_3 = Trans_Tora1;
                       else if (GO)                                   nextstate_3 = Strt_Proc_Data1;
                       else                                           nextstate_3 = Start_Data;
      Start_Hold     : if      (STRT_TMO)                             nextstate_3 = Act_Chk;
                       else                                           nextstate_3 = Start_Hold;
      Start_Tail     :                                                nextstate_3 = Idle;
      Strt_Proc_Data1:                                                nextstate_3 = Strt_Proc_Data2;
      Strt_Proc_Data2:                                                nextstate_3 = Strt_Proc_Data3;
      Strt_Proc_Data3:                                                nextstate_3 = Proc_Data;
      Trans_L1A      :                                                nextstate_3 = L1A_Chk;
      Trans_Tora1    :                                                nextstate_3 = Proc_Data;
    endcase
  end

  // Assign reg'd outputs to state bits

  // sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      state_1 <= Idle;
      state_2 <= Idle;
      state_3 <= Idle;
    end
    else begin
      state_1 <= nextstate_1;
      state_2 <= nextstate_2;
      state_3 <= nextstate_3;
    end
  end

  // datapath sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      ACT_CHK_1 <= 0;
      ACT_CHK_2 <= 0;
      ACT_CHK_3 <= 0;
      CAP_L1A_1 <= 0;
      CAP_L1A_2 <= 0;
      CAP_L1A_3 <= 0;
      CE_B4_1 <= 0;
      CE_B4_2 <= 0;
      CE_B4_3 <= 0;
      CE_B5_1 <= 0;
      CE_B5_2 <= 0;
      CE_B5_3 <= 0;
      CE_L1H_1 <= 0;
      CE_L1H_2 <= 0;
      CE_L1H_3 <= 0;
      CE_L1L_1 <= 0;
      CE_L1L_2 <= 0;
      CE_L1L_3 <= 0;
      CLR_DONE_1 <= 0;
      CLR_DONE_2 <= 0;
      CLR_DONE_3 <= 0;
      DATA_CE_1 <= 0;
      DATA_CE_2 <= 0;
      DATA_CE_3 <= 0;
      DATA_HLDOFF_1 <= 0;
      DATA_HLDOFF_2 <= 0;
      DATA_HLDOFF_3 <= 0;
      DOCHK_1 <= 0;
      DOCHK_2 <= 0;
      DOCHK_3 <= 0;
      DODAT_1 <= 0;
      DODAT_2 <= 0;
      DODAT_3 <= 0;
      DO_ERR_1 <= 0;
      DO_ERR_2 <= 0;
      DO_ERR_3 <= 0;
      FLUSHING_1 <= 0;
      FLUSHING_2 <= 0;
      FLUSHING_3 <= 0;
      INPROG_1 <= 0;
      INPROG_2 <= 0;
      INPROG_3 <= 0;
      MISSING_DAT_1 <= 0;
      MISSING_DAT_2 <= 0;
      MISSING_DAT_3 <= 0;
      NOEND_ERROR_1 <= 0;
      NOEND_ERROR_2 <= 0;
      NOEND_ERROR_3 <= 0;
      PROC_DATA_1 <= 0;
      PROC_DATA_2 <= 0;
      PROC_DATA_3 <= 0;
      READ_ENA_1 <= 0;
      READ_ENA_2 <= 0;
      READ_ENA_3 <= 0;
      STRT_TAIL_1 <= 0;
      STRT_TAIL_2 <= 0;
      STRT_TAIL_3 <= 0;
      TRANS_L1A_1 <= 0;
      TRANS_L1A_2 <= 0;
      TRANS_L1A_3 <= 0;
      TRANS_TORA_1 <= 0;
      TRANS_TORA_2 <= 0;
      TRANS_TORA_3 <= 0;
    end
    else begin
      ACT_CHK_1 <= 0; // default
      ACT_CHK_2 <= 0; // default
      ACT_CHK_3 <= 0; // default
      CAP_L1A_1 <= 0; // default
      CAP_L1A_2 <= 0; // default
      CAP_L1A_3 <= 0; // default
      CE_B4_1 <= 0; // default
      CE_B4_2 <= 0; // default
      CE_B4_3 <= 0; // default
      CE_B5_1 <= 0; // default
      CE_B5_2 <= 0; // default
      CE_B5_3 <= 0; // default
      CE_L1H_1 <= 0; // default
      CE_L1H_2 <= 0; // default
      CE_L1H_3 <= 0; // default
      CE_L1L_1 <= 0; // default
      CE_L1L_2 <= 0; // default
      CE_L1L_3 <= 0; // default
      CLR_DONE_1 <= 0; // default
      CLR_DONE_2 <= 0; // default
      CLR_DONE_3 <= 0; // default
      DATA_CE_1 <= 0; // default
      DATA_CE_2 <= 0; // default
      DATA_CE_3 <= 0; // default
      DATA_HLDOFF_1 <= 0; // default
      DATA_HLDOFF_2 <= 0; // default
      DATA_HLDOFF_3 <= 0; // default
      DOCHK_1 <= 0; // default
      DOCHK_2 <= 0; // default
      DOCHK_3 <= 0; // default
      DODAT_1 <= 0; // default
      DODAT_2 <= 0; // default
      DODAT_3 <= 0; // default
      DO_ERR_1 <= 0; // default
      DO_ERR_2 <= 0; // default
      DO_ERR_3 <= 0; // default
      FLUSHING_1 <= 0; // default
      FLUSHING_2 <= 0; // default
      FLUSHING_3 <= 0; // default
      INPROG_1 <= 1; // default
      INPROG_2 <= 1; // default
      INPROG_3 <= 1; // default
      MISSING_DAT_1 <= 0; // default
      MISSING_DAT_2 <= 0; // default
      MISSING_DAT_3 <= 0; // default
      NOEND_ERROR_1 <= 0; // default
      NOEND_ERROR_2 <= 0; // default
      NOEND_ERROR_3 <= 0; // default
      PROC_DATA_1 <= 0; // default
      PROC_DATA_2 <= 0; // default
      PROC_DATA_3 <= 0; // default
      READ_ENA_1 <= 0; // default
      READ_ENA_2 <= 0; // default
      READ_ENA_3 <= 0; // default
      STRT_TAIL_1 <= 0; // default
      STRT_TAIL_2 <= 0; // default
      STRT_TAIL_3 <= 0; // default
      TRANS_L1A_1 <= 0; // default
      TRANS_L1A_2 <= 0; // default
      TRANS_L1A_3 <= 0; // default
      TRANS_TORA_1 <= 0; // default
      TRANS_TORA_2 <= 0; // default
      TRANS_TORA_3 <= 0; // default
      case (nextstate_1)
        Idle           :        INPROG_1 <= 0;
        Act_Chk        : begin
                                ACT_CHK_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
        end
        DONE_FLUSH     : begin
                                CLR_DONE_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                MISSING_DAT_1 <= 1;
        end
        END_PROC1      :        DODAT_1 <= 1;
        END_PROC2      :        DODAT_1 <= 1;
        Flush2Last     : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                FLUSHING_1 <= 1;
                                READ_ENA_1 <= 1;
        end
        L1A_Chk        : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
        end
        NO_END1        : begin
                                DATA_CE_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DO_ERR_1 <= 1;
                                NOEND_ERROR_1 <= 1;
        end
        NO_END2        : begin
                                DATA_HLDOFF_1 <= 1;
                                DO_ERR_1 <= 1;
                                NOEND_ERROR_1 <= 1;
        end
        Pause          : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
        end
        Pop0           : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                READ_ENA_1 <= 1;
        end
        Pop1           : begin
                                CE_B4_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                READ_ENA_1 <= 1;
        end
        Pop2           : begin
                                CE_L1L_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                READ_ENA_1 <= 1;
        end
        Pop3           : begin
                                CE_L1H_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
        end
        Pop4           : begin
                                CE_B5_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                READ_ENA_1 <= 1;
        end
        Proc_Data      : begin
                                DATA_CE_1 <= 1;
                                DODAT_1 <= 1;
                                PROC_DATA_1 <= 1;
        end
        Save_L1A       : begin
                                CAP_L1A_1 <= 1;
                                CLR_DONE_1 <= !NEW_CFEB;
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                MISSING_DAT_1 <= !NEW_CFEB;
        end
        Start_Chk      : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
        end
        Start_Data     : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
        end
        Start_Hold     : begin
                                ACT_CHK_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
        end
        Start_Tail     : begin
                                INPROG_1 <= 0;
                                STRT_TAIL_1 <= 1;
        end
        Strt_Proc_Data1: begin
                                DATA_CE_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DODAT_1 <= 1;
        end
        Strt_Proc_Data2: begin
                                DATA_CE_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DODAT_1 <= 1;
        end
        Strt_Proc_Data3: begin
                                DATA_CE_1 <= 1;
                                DATA_HLDOFF_1 <= 1;
                                DODAT_1 <= 1;
        end
        Trans_L1A      : begin
                                DATA_HLDOFF_1 <= 1;
                                DOCHK_1 <= 1;
                                TRANS_L1A_1 <= 1;
        end
        Trans_Tora1    : begin
                                DATA_HLDOFF_1 <= 1;
                                DODAT_1 <= 1;
                                TRANS_TORA_1 <= 1;
        end
      endcase
      case (nextstate_2)
        Idle           :        INPROG_2 <= 0;
        Act_Chk        : begin
                                ACT_CHK_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
        end
        DONE_FLUSH     : begin
                                CLR_DONE_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                MISSING_DAT_2 <= 1;
        end
        END_PROC1      :        DODAT_2 <= 1;
        END_PROC2      :        DODAT_2 <= 1;
        Flush2Last     : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                FLUSHING_2 <= 1;
                                READ_ENA_2 <= 1;
        end
        L1A_Chk        : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
        end
        NO_END1        : begin
                                DATA_CE_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DO_ERR_2 <= 1;
                                NOEND_ERROR_2 <= 1;
        end
        NO_END2        : begin
                                DATA_HLDOFF_2 <= 1;
                                DO_ERR_2 <= 1;
                                NOEND_ERROR_2 <= 1;
        end
        Pause          : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
        end
        Pop0           : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                READ_ENA_2 <= 1;
        end
        Pop1           : begin
                                CE_B4_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                READ_ENA_2 <= 1;
        end
        Pop2           : begin
                                CE_L1L_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                READ_ENA_2 <= 1;
        end
        Pop3           : begin
                                CE_L1H_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
        end
        Pop4           : begin
                                CE_B5_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                READ_ENA_2 <= 1;
        end
        Proc_Data      : begin
                                DATA_CE_2 <= 1;
                                DODAT_2 <= 1;
                                PROC_DATA_2 <= 1;
        end
        Save_L1A       : begin
                                CAP_L1A_2 <= 1;
                                CLR_DONE_2 <= !NEW_CFEB;
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                MISSING_DAT_2 <= !NEW_CFEB;
        end
        Start_Chk      : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
        end
        Start_Data     : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
        end
        Start_Hold     : begin
                                ACT_CHK_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
        end
        Start_Tail     : begin
                                INPROG_2 <= 0;
                                STRT_TAIL_2 <= 1;
        end
        Strt_Proc_Data1: begin
                                DATA_CE_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DODAT_2 <= 1;
        end
        Strt_Proc_Data2: begin
                                DATA_CE_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DODAT_2 <= 1;
        end
        Strt_Proc_Data3: begin
                                DATA_CE_2 <= 1;
                                DATA_HLDOFF_2 <= 1;
                                DODAT_2 <= 1;
        end
        Trans_L1A      : begin
                                DATA_HLDOFF_2 <= 1;
                                DOCHK_2 <= 1;
                                TRANS_L1A_2 <= 1;
        end
        Trans_Tora1    : begin
                                DATA_HLDOFF_2 <= 1;
                                DODAT_2 <= 1;
                                TRANS_TORA_2 <= 1;
        end
      endcase
      case (nextstate_3)
        Idle           :        INPROG_3 <= 0;
        Act_Chk        : begin
                                ACT_CHK_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
        end
        DONE_FLUSH     : begin
                                CLR_DONE_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                MISSING_DAT_3 <= 1;
        end
        END_PROC1      :        DODAT_3 <= 1;
        END_PROC2      :        DODAT_3 <= 1;
        Flush2Last     : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                FLUSHING_3 <= 1;
                                READ_ENA_3 <= 1;
        end
        L1A_Chk        : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
        end
        NO_END1        : begin
                                DATA_CE_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DO_ERR_3 <= 1;
                                NOEND_ERROR_3 <= 1;
        end
        NO_END2        : begin
                                DATA_HLDOFF_3 <= 1;
                                DO_ERR_3 <= 1;
                                NOEND_ERROR_3 <= 1;
        end
        Pause          : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
        end
        Pop0           : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                READ_ENA_3 <= 1;
        end
        Pop1           : begin
                                CE_B4_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                READ_ENA_3 <= 1;
        end
        Pop2           : begin
                                CE_L1L_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                READ_ENA_3 <= 1;
        end
        Pop3           : begin
                                CE_L1H_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
        end
        Pop4           : begin
                                CE_B5_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                READ_ENA_3 <= 1;
        end
        Proc_Data      : begin
                                DATA_CE_3 <= 1;
                                DODAT_3 <= 1;
                                PROC_DATA_3 <= 1;
        end
        Save_L1A       : begin
                                CAP_L1A_3 <= 1;
                                CLR_DONE_3 <= !NEW_CFEB;
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                MISSING_DAT_3 <= !NEW_CFEB;
        end
        Start_Chk      : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
        end
        Start_Data     : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
        end
        Start_Hold     : begin
                                ACT_CHK_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
        end
        Start_Tail     : begin
                                INPROG_3 <= 0;
                                STRT_TAIL_3 <= 1;
        end
        Strt_Proc_Data1: begin
                                DATA_CE_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DODAT_3 <= 1;
        end
        Strt_Proc_Data2: begin
                                DATA_CE_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DODAT_3 <= 1;
        end
        Strt_Proc_Data3: begin
                                DATA_CE_3 <= 1;
                                DATA_HLDOFF_3 <= 1;
                                DODAT_3 <= 1;
        end
        Trans_L1A      : begin
                                DATA_HLDOFF_3 <= 1;
                                DOCHK_3 <= 1;
                                TRANS_L1A_3 <= 1;
        end
        Trans_Tora1    : begin
                                DATA_HLDOFF_3 <= 1;
                                DODAT_3 <= 1;
                                TRANS_TORA_3 <= 1;
        end
      endcase
    end
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [119:0] statename;
  always @* begin
    case (state_1)
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
      default        : statename = "XXXXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

