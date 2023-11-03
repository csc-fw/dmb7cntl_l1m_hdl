
// Created by fizzim_tmr.pl version $Revision: 4.44 on 2023:10:31 at 12:27:59 (www.fizzim.com)

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
  Idle_BIT = 0,
  Act_Chk_BIT = 1,
  DONE_FLUSH_BIT = 2,
  END_PROC1_BIT = 3,
  END_PROC2_BIT = 4,
  Flush2Last_BIT = 5,
  L1A_Chk_BIT = 6,
  NO_END1_BIT = 7,
  NO_END2_BIT = 8,
  Pause_BIT = 9,
  Pop0_BIT = 10,
  Pop1_BIT = 11,
  Pop2_BIT = 12,
  Pop3_BIT = 13,
  Pop4_BIT = 14,
  Proc_Data_BIT = 15,
  Save_L1A_BIT = 16,
  Start_Chk_BIT = 17,
  Start_Data_BIT = 18,
  Start_Hold_BIT = 19,
  Start_Tail_BIT = 20,
  Strt_Proc_Data1_BIT = 21,
  Strt_Proc_Data2_BIT = 22,
  Strt_Proc_Data3_BIT = 23,
  Trans_L1A_BIT = 24,
  Trans_Tora1_BIT = 25;

  parameter 
  Idle            = 26'b1<<Idle_BIT, 
  Act_Chk         = 26'b1<<Act_Chk_BIT, 
  DONE_FLUSH      = 26'b1<<DONE_FLUSH_BIT, 
  END_PROC1       = 26'b1<<END_PROC1_BIT, 
  END_PROC2       = 26'b1<<END_PROC2_BIT, 
  Flush2Last      = 26'b1<<Flush2Last_BIT, 
  L1A_Chk         = 26'b1<<L1A_Chk_BIT, 
  NO_END1         = 26'b1<<NO_END1_BIT, 
  NO_END2         = 26'b1<<NO_END2_BIT, 
  Pause           = 26'b1<<Pause_BIT, 
  Pop0            = 26'b1<<Pop0_BIT, 
  Pop1            = 26'b1<<Pop1_BIT, 
  Pop2            = 26'b1<<Pop2_BIT, 
  Pop3            = 26'b1<<Pop3_BIT, 
  Pop4            = 26'b1<<Pop4_BIT, 
  Proc_Data       = 26'b1<<Proc_Data_BIT, 
  Save_L1A        = 26'b1<<Save_L1A_BIT, 
  Start_Chk       = 26'b1<<Start_Chk_BIT, 
  Start_Data      = 26'b1<<Start_Data_BIT, 
  Start_Hold      = 26'b1<<Start_Hold_BIT, 
  Start_Tail      = 26'b1<<Start_Tail_BIT, 
  Strt_Proc_Data1 = 26'b1<<Strt_Proc_Data1_BIT, 
  Strt_Proc_Data2 = 26'b1<<Strt_Proc_Data2_BIT, 
  Strt_Proc_Data3 = 26'b1<<Strt_Proc_Data3_BIT, 
  Trans_L1A       = 26'b1<<Trans_L1A_BIT, 
  Trans_Tora1     = 26'b1<<Trans_Tora1_BIT, 
  XXX             = 26'bx;

  (* syn_preserve = "true" *) reg [25:0] state_1;
  (* syn_preserve = "true" *) reg [25:0] state_2;
  (* syn_preserve = "true" *) reg [25:0] state_3;

  (* syn_keep = "true" *) wire [25:0] voted_state_1;
  (* syn_keep = "true" *) wire [25:0] voted_state_2;
  (* syn_keep = "true" *) wire [25:0] voted_state_3;

  assign voted_state_1       = (state_1       & state_2      ) | (state_2       & state_3      ) | (state_1       & state_3      ); // Majority logic
  assign voted_state_2       = (state_1       & state_2      ) | (state_2       & state_3      ) | (state_1       & state_3      ); // Majority logic
  assign voted_state_3       = (state_1       & state_2      ) | (state_2       & state_3      ) | (state_1       & state_3      ); // Majority logic


  (* syn_keep = "true" *) reg [25:0] nextstate_1;
  (* syn_keep = "true" *) reg [25:0] nextstate_2;
  (* syn_keep = "true" *) reg [25:0] nextstate_3;


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
    nextstate_1 = XXX; // default to x because default_state_is_x is set
    nextstate_2 = XXX; // default to x because default_state_is_x is set
    nextstate_3 = XXX; // default to x because default_state_is_x is set
    case (1'b1) // synopsys parallel_case full_case
      voted_state_1[Idle_BIT]: if            (HEADER_END)                           nextstate_1 = Start_Hold;
                               else                                                 nextstate_1 = Idle;
      voted_state_1[Act_Chk_BIT]: if         (ALCT_TMB_ACT)                         nextstate_1 = Start_Data;
                                  else if    (CFEB_ACT)                             nextstate_1 = Start_Chk;
                                  else if    (EOE)                                  nextstate_1 = Start_Tail;
                                  else                                              nextstate_1 = Act_Chk;
      voted_state_1[DONE_FLUSH_BIT]:                                                nextstate_1 = Act_Chk;
      voted_state_1[END_PROC1_BIT]:                                                 nextstate_1 = END_PROC2;
      voted_state_1[END_PROC2_BIT]:                                                 nextstate_1 = Act_Chk;
      voted_state_1[Flush2Last_BIT]: if      (LAST)                                 nextstate_1 = Start_Chk;
                                     else if (NEW_EVENT)                            nextstate_1 = Pop2;
                                     else if (MT)                                   nextstate_1 = DONE_FLUSH;
                                     else                                           nextstate_1 = Flush2Last;
      voted_state_1[L1A_Chk_BIT]: if         (L1A_EQ)                               nextstate_1 = Pop4;
                                  else if    (L1A_LT)                               nextstate_1 = Flush2Last;
                                  else                                              nextstate_1 = Save_L1A;
      voted_state_1[NO_END1_BIT]:                                                   nextstate_1 = NO_END2;
      voted_state_1[NO_END2_BIT]: if         ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate_1 = Act_Chk;
                                  else                                              nextstate_1 = NO_END2;
      voted_state_1[Pause_BIT]:                                                     nextstate_1 = L1A_Chk;
      voted_state_1[Pop0_BIT]:                                                      nextstate_1 = Pop1;
      voted_state_1[Pop1_BIT]:                                                      nextstate_1 = Pop2;
      voted_state_1[Pop2_BIT]:                                                      nextstate_1 = Pop3;
      voted_state_1[Pop3_BIT]: if            (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate_1 = Pause;
                               else                                                 nextstate_1 = Flush2Last;
      voted_state_1[Pop4_BIT]:                                                      nextstate_1 = Start_Data;
      voted_state_1[Proc_Data_BIT]: if       (DONE_CE)                              nextstate_1 = END_PROC1;
                                    else if  (NEW_TORA)                             nextstate_1 = NO_END1;
                                    else if  (NEW_CFEB)                             nextstate_1 = Pop2;
                                    else if  (PROC_TMO)                             nextstate_1 = Act_Chk;
                                    else                                            nextstate_1 = Proc_Data;
      voted_state_1[Save_L1A_BIT]: if        (NEW_CFEB)                             nextstate_1 = NO_END2;
                                   else                                             nextstate_1 = Act_Chk;
      voted_state_1[Start_Chk_BIT]: if       (GOB5)                                 nextstate_1 = Trans_L1A;
                                    else if  (GO)                                   nextstate_1 = Pop0;
                                    else                                            nextstate_1 = Start_Chk;
      voted_state_1[Start_Data_BIT]: if      (GO && TRANS_FLG)                      nextstate_1 = Trans_Tora1;
                                     else if (GO)                                   nextstate_1 = Strt_Proc_Data1;
                                     else                                           nextstate_1 = Start_Data;
      voted_state_1[Start_Hold_BIT]: if      (STRT_TMO)                             nextstate_1 = Act_Chk;
                                     else                                           nextstate_1 = Start_Hold;
      voted_state_1[Start_Tail_BIT]:                                                nextstate_1 = Idle;
      voted_state_1[Strt_Proc_Data1_BIT]:                                           nextstate_1 = Strt_Proc_Data2;
      voted_state_1[Strt_Proc_Data2_BIT]:                                           nextstate_1 = Strt_Proc_Data3;
      voted_state_1[Strt_Proc_Data3_BIT]:                                           nextstate_1 = Proc_Data;
      voted_state_1[Trans_L1A_BIT]:                                                 nextstate_1 = L1A_Chk;
      voted_state_1[Trans_Tora1_BIT]:                                               nextstate_1 = Proc_Data;
    endcase
    case (1'b1) // synopsys parallel_case full_case
      voted_state_2[Idle_BIT]: if            (HEADER_END)                           nextstate_2 = Start_Hold;
                               else                                                 nextstate_2 = Idle;
      voted_state_2[Act_Chk_BIT]: if         (ALCT_TMB_ACT)                         nextstate_2 = Start_Data;
                                  else if    (CFEB_ACT)                             nextstate_2 = Start_Chk;
                                  else if    (EOE)                                  nextstate_2 = Start_Tail;
                                  else                                              nextstate_2 = Act_Chk;
      voted_state_2[DONE_FLUSH_BIT]:                                                nextstate_2 = Act_Chk;
      voted_state_2[END_PROC1_BIT]:                                                 nextstate_2 = END_PROC2;
      voted_state_2[END_PROC2_BIT]:                                                 nextstate_2 = Act_Chk;
      voted_state_2[Flush2Last_BIT]: if      (LAST)                                 nextstate_2 = Start_Chk;
                                     else if (NEW_EVENT)                            nextstate_2 = Pop2;
                                     else if (MT)                                   nextstate_2 = DONE_FLUSH;
                                     else                                           nextstate_2 = Flush2Last;
      voted_state_2[L1A_Chk_BIT]: if         (L1A_EQ)                               nextstate_2 = Pop4;
                                  else if    (L1A_LT)                               nextstate_2 = Flush2Last;
                                  else                                              nextstate_2 = Save_L1A;
      voted_state_2[NO_END1_BIT]:                                                   nextstate_2 = NO_END2;
      voted_state_2[NO_END2_BIT]: if         ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate_2 = Act_Chk;
                                  else                                              nextstate_2 = NO_END2;
      voted_state_2[Pause_BIT]:                                                     nextstate_2 = L1A_Chk;
      voted_state_2[Pop0_BIT]:                                                      nextstate_2 = Pop1;
      voted_state_2[Pop1_BIT]:                                                      nextstate_2 = Pop2;
      voted_state_2[Pop2_BIT]:                                                      nextstate_2 = Pop3;
      voted_state_2[Pop3_BIT]: if            (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate_2 = Pause;
                               else                                                 nextstate_2 = Flush2Last;
      voted_state_2[Pop4_BIT]:                                                      nextstate_2 = Start_Data;
      voted_state_2[Proc_Data_BIT]: if       (DONE_CE)                              nextstate_2 = END_PROC1;
                                    else if  (NEW_TORA)                             nextstate_2 = NO_END1;
                                    else if  (NEW_CFEB)                             nextstate_2 = Pop2;
                                    else if  (PROC_TMO)                             nextstate_2 = Act_Chk;
                                    else                                            nextstate_2 = Proc_Data;
      voted_state_2[Save_L1A_BIT]: if        (NEW_CFEB)                             nextstate_2 = NO_END2;
                                   else                                             nextstate_2 = Act_Chk;
      voted_state_2[Start_Chk_BIT]: if       (GOB5)                                 nextstate_2 = Trans_L1A;
                                    else if  (GO)                                   nextstate_2 = Pop0;
                                    else                                            nextstate_2 = Start_Chk;
      voted_state_2[Start_Data_BIT]: if      (GO && TRANS_FLG)                      nextstate_2 = Trans_Tora1;
                                     else if (GO)                                   nextstate_2 = Strt_Proc_Data1;
                                     else                                           nextstate_2 = Start_Data;
      voted_state_2[Start_Hold_BIT]: if      (STRT_TMO)                             nextstate_2 = Act_Chk;
                                     else                                           nextstate_2 = Start_Hold;
      voted_state_2[Start_Tail_BIT]:                                                nextstate_2 = Idle;
      voted_state_2[Strt_Proc_Data1_BIT]:                                           nextstate_2 = Strt_Proc_Data2;
      voted_state_2[Strt_Proc_Data2_BIT]:                                           nextstate_2 = Strt_Proc_Data3;
      voted_state_2[Strt_Proc_Data3_BIT]:                                           nextstate_2 = Proc_Data;
      voted_state_2[Trans_L1A_BIT]:                                                 nextstate_2 = L1A_Chk;
      voted_state_2[Trans_Tora1_BIT]:                                               nextstate_2 = Proc_Data;
    endcase
    case (1'b1) // synopsys parallel_case full_case
      voted_state_3[Idle_BIT]: if            (HEADER_END)                           nextstate_3 = Start_Hold;
                               else                                                 nextstate_3 = Idle;
      voted_state_3[Act_Chk_BIT]: if         (ALCT_TMB_ACT)                         nextstate_3 = Start_Data;
                                  else if    (CFEB_ACT)                             nextstate_3 = Start_Chk;
                                  else if    (EOE)                                  nextstate_3 = Start_Tail;
                                  else                                              nextstate_3 = Act_Chk;
      voted_state_3[DONE_FLUSH_BIT]:                                                nextstate_3 = Act_Chk;
      voted_state_3[END_PROC1_BIT]:                                                 nextstate_3 = END_PROC2;
      voted_state_3[END_PROC2_BIT]:                                                 nextstate_3 = Act_Chk;
      voted_state_3[Flush2Last_BIT]: if      (LAST)                                 nextstate_3 = Start_Chk;
                                     else if (NEW_EVENT)                            nextstate_3 = Pop2;
                                     else if (MT)                                   nextstate_3 = DONE_FLUSH;
                                     else                                           nextstate_3 = Flush2Last;
      voted_state_3[L1A_Chk_BIT]: if         (L1A_EQ)                               nextstate_3 = Pop4;
                                  else if    (L1A_LT)                               nextstate_3 = Flush2Last;
                                  else                                              nextstate_3 = Save_L1A;
      voted_state_3[NO_END1_BIT]:                                                   nextstate_3 = NO_END2;
      voted_state_3[NO_END2_BIT]: if         ((NEW_TORA || NEW_CFEB) && ERR_AKN)    nextstate_3 = Act_Chk;
                                  else                                              nextstate_3 = NO_END2;
      voted_state_3[Pause_BIT]:                                                     nextstate_3 = L1A_Chk;
      voted_state_3[Pop0_BIT]:                                                      nextstate_3 = Pop1;
      voted_state_3[Pop1_BIT]:                                                      nextstate_3 = Pop2;
      voted_state_3[Pop2_BIT]:                                                      nextstate_3 = Pop3;
      voted_state_3[Pop3_BIT]: if            (B4_PRESENT || NEW_CFEB || NEW_EVENT)  nextstate_3 = Pause;
                               else                                                 nextstate_3 = Flush2Last;
      voted_state_3[Pop4_BIT]:                                                      nextstate_3 = Start_Data;
      voted_state_3[Proc_Data_BIT]: if       (DONE_CE)                              nextstate_3 = END_PROC1;
                                    else if  (NEW_TORA)                             nextstate_3 = NO_END1;
                                    else if  (NEW_CFEB)                             nextstate_3 = Pop2;
                                    else if  (PROC_TMO)                             nextstate_3 = Act_Chk;
                                    else                                            nextstate_3 = Proc_Data;
      voted_state_3[Save_L1A_BIT]: if        (NEW_CFEB)                             nextstate_3 = NO_END2;
                                   else                                             nextstate_3 = Act_Chk;
      voted_state_3[Start_Chk_BIT]: if       (GOB5)                                 nextstate_3 = Trans_L1A;
                                    else if  (GO)                                   nextstate_3 = Pop0;
                                    else                                            nextstate_3 = Start_Chk;
      voted_state_3[Start_Data_BIT]: if      (GO && TRANS_FLG)                      nextstate_3 = Trans_Tora1;
                                     else if (GO)                                   nextstate_3 = Strt_Proc_Data1;
                                     else                                           nextstate_3 = Start_Data;
      voted_state_3[Start_Hold_BIT]: if      (STRT_TMO)                             nextstate_3 = Act_Chk;
                                     else                                           nextstate_3 = Start_Hold;
      voted_state_3[Start_Tail_BIT]:                                                nextstate_3 = Idle;
      voted_state_3[Strt_Proc_Data1_BIT]:                                           nextstate_3 = Strt_Proc_Data2;
      voted_state_3[Strt_Proc_Data2_BIT]:                                           nextstate_3 = Strt_Proc_Data3;
      voted_state_3[Strt_Proc_Data3_BIT]:                                           nextstate_3 = Proc_Data;
      voted_state_3[Trans_L1A_BIT]:                                                 nextstate_3 = L1A_Chk;
      voted_state_3[Trans_Tora1_BIT]:                                               nextstate_3 = Proc_Data;
    endcase
  end

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
      case (1'b1) // synopsys parallel_case full_case
        nextstate_1[Idle_BIT]     :              INPROG_1 <= 0;
        nextstate_1[Act_Chk_BIT]  : begin
                                                 ACT_CHK_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
        end
        nextstate_1[DONE_FLUSH_BIT]: begin
                                                 CLR_DONE_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 MISSING_DAT_1 <= 1;
        end
        nextstate_1[END_PROC1_BIT]:              DODAT_1 <= 1;
        nextstate_1[END_PROC2_BIT]:              DODAT_1 <= 1;
        nextstate_1[Flush2Last_BIT]: begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 FLUSHING_1 <= 1;
                                                 READ_ENA_1 <= 1;
        end
        nextstate_1[L1A_Chk_BIT]  : begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
        end
        nextstate_1[NO_END1_BIT]  : begin
                                                 DATA_CE_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DO_ERR_1 <= 1;
                                                 NOEND_ERROR_1 <= 1;
        end
        nextstate_1[NO_END2_BIT]  : begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DO_ERR_1 <= 1;
                                                 NOEND_ERROR_1 <= 1;
        end
        nextstate_1[Pause_BIT]    : begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
        end
        nextstate_1[Pop0_BIT]     : begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 READ_ENA_1 <= 1;
        end
        nextstate_1[Pop1_BIT]     : begin
                                                 CE_B4_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 READ_ENA_1 <= 1;
        end
        nextstate_1[Pop2_BIT]     : begin
                                                 CE_L1L_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 READ_ENA_1 <= 1;
        end
        nextstate_1[Pop3_BIT]     : begin
                                                 CE_L1H_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
        end
        nextstate_1[Pop4_BIT]     : begin
                                                 CE_B5_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 READ_ENA_1 <= 1;
        end
        nextstate_1[Proc_Data_BIT]: begin
                                                 DATA_CE_1 <= 1;
                                                 DODAT_1 <= 1;
                                                 PROC_DATA_1 <= 1;
        end
        nextstate_1[Save_L1A_BIT] : begin
                                                 CAP_L1A_1 <= 1;
                                                 CLR_DONE_1 <= !NEW_CFEB;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 MISSING_DAT_1 <= !NEW_CFEB;
        end
        nextstate_1[Start_Chk_BIT]: begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
        end
        nextstate_1[Start_Data_BIT]: begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
        end
        nextstate_1[Start_Hold_BIT]: begin
                                                 ACT_CHK_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
        end
        nextstate_1[Start_Tail_BIT]: begin
                                                 INPROG_1 <= 0;
                                                 STRT_TAIL_1 <= 1;
        end
        nextstate_1[Strt_Proc_Data1_BIT]: begin
                                                 DATA_CE_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DODAT_1 <= 1;
        end
        nextstate_1[Strt_Proc_Data2_BIT]: begin
                                                 DATA_CE_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DODAT_1 <= 1;
        end
        nextstate_1[Strt_Proc_Data3_BIT]: begin
                                                 DATA_CE_1 <= 1;
                                                 DATA_HLDOFF_1 <= 1;
                                                 DODAT_1 <= 1;
        end
        nextstate_1[Trans_L1A_BIT]: begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DOCHK_1 <= 1;
                                                 TRANS_L1A_1 <= 1;
        end
        nextstate_1[Trans_Tora1_BIT]: begin
                                                 DATA_HLDOFF_1 <= 1;
                                                 DODAT_1 <= 1;
                                                 TRANS_TORA_1 <= 1;
        end
      endcase
      case (1'b1) // synopsys parallel_case full_case
        nextstate_2[Idle_BIT]     :              INPROG_2 <= 0;
        nextstate_2[Act_Chk_BIT]  : begin
                                                 ACT_CHK_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
        end
        nextstate_2[DONE_FLUSH_BIT]: begin
                                                 CLR_DONE_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 MISSING_DAT_2 <= 1;
        end
        nextstate_2[END_PROC1_BIT]:              DODAT_2 <= 1;
        nextstate_2[END_PROC2_BIT]:              DODAT_2 <= 1;
        nextstate_2[Flush2Last_BIT]: begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 FLUSHING_2 <= 1;
                                                 READ_ENA_2 <= 1;
        end
        nextstate_2[L1A_Chk_BIT]  : begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
        end
        nextstate_2[NO_END1_BIT]  : begin
                                                 DATA_CE_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DO_ERR_2 <= 1;
                                                 NOEND_ERROR_2 <= 1;
        end
        nextstate_2[NO_END2_BIT]  : begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DO_ERR_2 <= 1;
                                                 NOEND_ERROR_2 <= 1;
        end
        nextstate_2[Pause_BIT]    : begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
        end
        nextstate_2[Pop0_BIT]     : begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 READ_ENA_2 <= 1;
        end
        nextstate_2[Pop1_BIT]     : begin
                                                 CE_B4_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 READ_ENA_2 <= 1;
        end
        nextstate_2[Pop2_BIT]     : begin
                                                 CE_L1L_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 READ_ENA_2 <= 1;
        end
        nextstate_2[Pop3_BIT]     : begin
                                                 CE_L1H_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
        end
        nextstate_2[Pop4_BIT]     : begin
                                                 CE_B5_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 READ_ENA_2 <= 1;
        end
        nextstate_2[Proc_Data_BIT]: begin
                                                 DATA_CE_2 <= 1;
                                                 DODAT_2 <= 1;
                                                 PROC_DATA_2 <= 1;
        end
        nextstate_2[Save_L1A_BIT] : begin
                                                 CAP_L1A_2 <= 1;
                                                 CLR_DONE_2 <= !NEW_CFEB;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 MISSING_DAT_2 <= !NEW_CFEB;
        end
        nextstate_2[Start_Chk_BIT]: begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
        end
        nextstate_2[Start_Data_BIT]: begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
        end
        nextstate_2[Start_Hold_BIT]: begin
                                                 ACT_CHK_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
        end
        nextstate_2[Start_Tail_BIT]: begin
                                                 INPROG_2 <= 0;
                                                 STRT_TAIL_2 <= 1;
        end
        nextstate_2[Strt_Proc_Data1_BIT]: begin
                                                 DATA_CE_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DODAT_2 <= 1;
        end
        nextstate_2[Strt_Proc_Data2_BIT]: begin
                                                 DATA_CE_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DODAT_2 <= 1;
        end
        nextstate_2[Strt_Proc_Data3_BIT]: begin
                                                 DATA_CE_2 <= 1;
                                                 DATA_HLDOFF_2 <= 1;
                                                 DODAT_2 <= 1;
        end
        nextstate_2[Trans_L1A_BIT]: begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DOCHK_2 <= 1;
                                                 TRANS_L1A_2 <= 1;
        end
        nextstate_2[Trans_Tora1_BIT]: begin
                                                 DATA_HLDOFF_2 <= 1;
                                                 DODAT_2 <= 1;
                                                 TRANS_TORA_2 <= 1;
        end
      endcase
      case (1'b1) // synopsys parallel_case full_case
        nextstate_3[Idle_BIT]     :              INPROG_3 <= 0;
        nextstate_3[Act_Chk_BIT]  : begin
                                                 ACT_CHK_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
        end
        nextstate_3[DONE_FLUSH_BIT]: begin
                                                 CLR_DONE_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 MISSING_DAT_3 <= 1;
        end
        nextstate_3[END_PROC1_BIT]:              DODAT_3 <= 1;
        nextstate_3[END_PROC2_BIT]:              DODAT_3 <= 1;
        nextstate_3[Flush2Last_BIT]: begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 FLUSHING_3 <= 1;
                                                 READ_ENA_3 <= 1;
        end
        nextstate_3[L1A_Chk_BIT]  : begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
        end
        nextstate_3[NO_END1_BIT]  : begin
                                                 DATA_CE_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DO_ERR_3 <= 1;
                                                 NOEND_ERROR_3 <= 1;
        end
        nextstate_3[NO_END2_BIT]  : begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DO_ERR_3 <= 1;
                                                 NOEND_ERROR_3 <= 1;
        end
        nextstate_3[Pause_BIT]    : begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
        end
        nextstate_3[Pop0_BIT]     : begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 READ_ENA_3 <= 1;
        end
        nextstate_3[Pop1_BIT]     : begin
                                                 CE_B4_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 READ_ENA_3 <= 1;
        end
        nextstate_3[Pop2_BIT]     : begin
                                                 CE_L1L_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 READ_ENA_3 <= 1;
        end
        nextstate_3[Pop3_BIT]     : begin
                                                 CE_L1H_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
        end
        nextstate_3[Pop4_BIT]     : begin
                                                 CE_B5_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 READ_ENA_3 <= 1;
        end
        nextstate_3[Proc_Data_BIT]: begin
                                                 DATA_CE_3 <= 1;
                                                 DODAT_3 <= 1;
                                                 PROC_DATA_3 <= 1;
        end
        nextstate_3[Save_L1A_BIT] : begin
                                                 CAP_L1A_3 <= 1;
                                                 CLR_DONE_3 <= !NEW_CFEB;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 MISSING_DAT_3 <= !NEW_CFEB;
        end
        nextstate_3[Start_Chk_BIT]: begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
        end
        nextstate_3[Start_Data_BIT]: begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
        end
        nextstate_3[Start_Hold_BIT]: begin
                                                 ACT_CHK_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
        end
        nextstate_3[Start_Tail_BIT]: begin
                                                 INPROG_3 <= 0;
                                                 STRT_TAIL_3 <= 1;
        end
        nextstate_3[Strt_Proc_Data1_BIT]: begin
                                                 DATA_CE_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DODAT_3 <= 1;
        end
        nextstate_3[Strt_Proc_Data2_BIT]: begin
                                                 DATA_CE_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DODAT_3 <= 1;
        end
        nextstate_3[Strt_Proc_Data3_BIT]: begin
                                                 DATA_CE_3 <= 1;
                                                 DATA_HLDOFF_3 <= 1;
                                                 DODAT_3 <= 1;
        end
        nextstate_3[Trans_L1A_BIT]: begin
                                                 DATA_HLDOFF_3 <= 1;
                                                 DOCHK_3 <= 1;
                                                 TRANS_L1A_3 <= 1;
        end
        nextstate_3[Trans_Tora1_BIT]: begin
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
    case (1'b1)
      state_1[Idle_BIT]     :       statename = "Idle";
      state_1[Act_Chk_BIT]  :       statename = "Act_Chk";
      state_1[DONE_FLUSH_BIT]:      statename = "DONE_FLUSH";
      state_1[END_PROC1_BIT]:       statename = "END_PROC1";
      state_1[END_PROC2_BIT]:       statename = "END_PROC2";
      state_1[Flush2Last_BIT]:      statename = "Flush2Last";
      state_1[L1A_Chk_BIT]  :       statename = "L1A_Chk";
      state_1[NO_END1_BIT]  :       statename = "NO_END1";
      state_1[NO_END2_BIT]  :       statename = "NO_END2";
      state_1[Pause_BIT]    :       statename = "Pause";
      state_1[Pop0_BIT]     :       statename = "Pop0";
      state_1[Pop1_BIT]     :       statename = "Pop1";
      state_1[Pop2_BIT]     :       statename = "Pop2";
      state_1[Pop3_BIT]     :       statename = "Pop3";
      state_1[Pop4_BIT]     :       statename = "Pop4";
      state_1[Proc_Data_BIT]:       statename = "Proc_Data";
      state_1[Save_L1A_BIT] :       statename = "Save_L1A";
      state_1[Start_Chk_BIT]:       statename = "Start_Chk";
      state_1[Start_Data_BIT]:      statename = "Start_Data";
      state_1[Start_Hold_BIT]:      statename = "Start_Hold";
      state_1[Start_Tail_BIT]:      statename = "Start_Tail";
      state_1[Strt_Proc_Data1_BIT]: statename = "Strt_Proc_Data1";
      state_1[Strt_Proc_Data2_BIT]: statename = "Strt_Proc_Data2";
      state_1[Strt_Proc_Data3_BIT]: statename = "Strt_Proc_Data3";
      state_1[Trans_L1A_BIT]:       statename = "Trans_L1A";
      state_1[Trans_Tora1_BIT]:     statename = "Trans_Tora1";
      default        :              statename = "XXXXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

