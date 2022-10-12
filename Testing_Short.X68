*-----------------------------------------------------------
* Title      : Suspicious Disassemblers (Bazen, Adam)
* Written by : Bazen Nega, Adam Deehring
* Date       : 12 - 7 - 2019
* Description: Tests for the Disassembler to disassemble in an isolated area of memory
*-----------------------------------------------------------
    ORG    $8000
START:                  ; first instruction of program

* Put program code here

    ** Miscellaneous tests
    BRA $8080
    MOVE D0,D3
    EOR D0,(A0)+
    LSL #8,D5
    MOVEA #4,A2
    ADDA.L D0,A2
    SUB (A3),D2
    SUB D5,(A6)
    ADD D3,(A2)+
    ADD.L -(A2),D5
    SUBQ #8,D3
    MULS #2133,D5
    DIVS #25,D7
    LEA $5023,A5
    ORI #$500,-(A6)
    OR (A6)+,D1
    OR ($500),D3
    NEG.L $2016
    ADD D0,D5
    LSR.B D7,D3
    LSR $1234
    LSL.L D7,D0
    ASR.B #8,D2
    ASL D1,D6
    ABCD D0, D0
    ABCD D0, D2
    ASL ($5020)
    MOVE.B D5,D2
    DIVS $50,D5
    BLT $80CE
    CMP D1,D5
    ABCD D5,D0
    BCLR.L #20,D5
    LSL $245
    JSR $5000
    RTS
    NOP
    
    ** MOVE, MOVEA, MOVEM tests
    MOVE D0,D5
    MOVE A3,D2
    MOVE (A2),(A1)+
    MOVE -(A6),$23402
    MOVE #$5234,$23421562
    MOVE D1, (A5)+
    MOVE #$340,$5234
    
    MOVEA D4,A2
    MOVEA (A2)+,A6
    MOVEA -(A1),A3
    MOVEA (A4),A1
    MOVEA A2,A4
    MOVE $1200,A2
    MOVE $34112337,A5
    MOVE #$123,A3
    
    MOVEM D4/D1/D7/D2, -(A7)
    MOVEM.L (A7)+, D4/D1/A4/A6/A2/A3/A1
    MOVEM.W (A7)+, D4/D1/A4/A6/A2/A3/A1
    
    ** ADD, ADDA tests
    ADD D4,D2
    ADD A3,D7
    ADD.B (A1),D3
    ADD -(A6),D4
    ADD (A4)+,D5
    ADD.L $2350,D1
    ADD $52314902,D3
    ADD.L #$123,D6
    ABCD D5,D0
    ADD.B D2,(A2)+  
    ADD D1,$50234
    ADD D6,$5023
    ADD D3,(A3)
    ADD D7,-(A4)
    ABCD D5,D0
    
    ADDA D1,A3 
    ADDA A4,A6
    ADDA (A5),A2
    ADDA (A3)+,A5
    ADDA -(A2),A4
    ADDA $5234,A1
    ADDA $52346000,A2
    
    ** SUB, SUBQ tests
    SUB D4,D2
    SUB A3,D7
    SUB (A1),D3
    SUB -(A6),D4
    SUB.L (A4)+,D5
    SUB $2350,D1
    SUB $52314902,D3
    SUB #$123,D6
    ABCD D5,D0
    SUB D2,(A2)+ 
    SUB D1,$50234
    SUB D6,$5023
    SUB D3,(A3)
    SUB D7,-(A4)
    ABCD D5,D0
    
    SUBQ #$2,D2 
    SUBQ #$7,A4
    SUBQ #$8,(A2)
    SUBQ #$6,(A3)+
    SUBQ #$5,-(A6)
    ABCD D5,D0    
    SUBQ #$4,$5234
    SUBQ #$1,$90000000
    
    ** MULS, DIVS tests
    MULS D2,D5
    MULS (A2),D6
    MULS (A5)+,D3
    MULS -(A4),D7
    MULS (6,A6),D4 
    MULS $5234,D2 
    MULS $54234234,D1
    MULS #$3241,D3
    
    DIVS D2,D5
    DIVS (A2),D6
    DIVS (A5)+,D3
    DIVS -(A4),D7
    ABCD D5,D0
    DIVS $5234,D2 
    DIVS $54234234,D1
    DIVS #$3241,D3
    
    **LEA tests
    LEA (A4),A2
    ABCD D5,D0
    LEA $5423,A3
    LEA $41231111,A1
    
    **OR, ORI tests
    OR D3,D2
    OR.B D1,(A3)
    OR.L D7,(A2)+
    OR.W D3,-(A4)
    OR.L D4, $5234
    OR.B D2, $43124920
    OR.B (A2)+, D2
    OR.L -(A5),D4 
    OR $2523,D1
    ABCD D5,D0
    OR.B (A4),D5
    OR $45234123,D3
    
    ORI.L #$12332343,D2
    ORI.W #$4513,(A5)
    ORI.B #$32,(A4)+
    ORI.W #$1232,-(A2)
    ORI.W #$4123,$4575
    ORI.L #$35234230,$32412345
    
    **NEG tests
    NEG.W D3
    NEG.L (A2)
    NEG.B (A4)+
    NEG.L -(A1)
    ABCD D5,D0
    NEG.W $5234 
    NEG.B $21523967
    
    **EOR tests
    EOR.B D4,D7
    EOR.W D3,(A5)
    EOR.L D2,(A4)+
    EOR.B D6,-(A3)
    ABCD D5,D0
    EOR.B D5,$4305
    EOR.L D7,$50456356
    
    **LSR, LSL, ASL, ASR, ROR, ROL tests
    LSL.W D4,D7
    LSR.W #$8,D5
    LSL.L #$2,D6
    LSR (A4)
    LSL (A2)+
    LSR -(A3)
    ABCD D5,D0
    LSR $4314
    LSL $21491324
    
    ASL.W D4,D7
    ASR.W #$8,D5
    ASL.L #$2,D6
    ASR (A4)
    ASL (A2)+
    ASR -(A3)
    ABCD D5,D0
    ASR $4314
    ASL $21491324
    
    ROR D5,D2
    ROR (A4)
    ROL (A6)+
    ROR -(A2)
    ABCD D5,D0
    ROR $2008
    ROL $12309823
    ROR.L #$7,D2
    
    **BCLR tests
    BCLR.L D3,D2
    BCLR D7,(A3)
    BCLR D4,(A4)+
    BCLR D6,-(A5)
    ABCD D5,D0
    BCLR.B D0,$5423
    BCLR.B D5,$92304523
    BCLR.L D0,D3
    BCLR.L #$5234,D4
    BCLR.B #$5234,(A3)
    BCLR.B #$0234,(A1)+
    BCLR.B #$5234,-(A4)
    ABCD D5,D0
    BCLR D4,(A4)
    BCLR.B #$5234,$5234
    BCLR.B #$9912,$19601345
    BCLR.L #$4524,D0
    BCLR.L #$00000034,D4
    BCLR.B #$34,$0A000034
    
    **CMP, CMPI tests
    CMP.B D1,D3
    CMP.L A3,D5
    CMP.B (A5),D3
    CMP.B (A6)+,D3
    CMP.B -(A4),D3
    ABCD D5,D0
    CMP.B $1340,D3
    CMP.B $35234904,D3
    
    CMPI #$4123,D5
    CMPI.L #$42341512,D2
    CMPI.B #$12,D6
    CMPI #$1234,(A3)+
    CMPI #$4313,-(A4)
    ABCD D5,D0
    CMPI #$5133,$7453
    CMPI #$1276,$73451249
    
    **Bcc (BCS, BGE, BLT, BVC) tests
    BCS.B $8302
    BCS.W $4123
    BCS.W $1090
    BGE.B $8302
    BGE.W $3248
    BGE.W $1934
    BLT.B $8302 
    BLT.W $6256
    BLT.W $2346
    BVC.B $8302
    BVC.W $7265
    BVC.W $8153
    
    **BRA tests
    BRA.B $8322
    BRA.W $9234
    
    *JSR, RTS tests
    JSR (A5)
    JSR $5134
    JSR $90124544
    RTS
    SUBQ.L #$4,D2
    
    
    MOVEM (A7)+, A6/A3/D1
    MOVEM $32442,A6/A3/D6/D5/D3/D4
    MOVEM D2,-(SP)
    MOVEM $5234,D5/A6/A1/A0
    MOVEM (SP)+,A3/D6/D1
    MOVEM $2,A3
    MOVEM A5,-(SP)
    ADD.B D4,D7
    ADD.L #$50084534,D6
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
