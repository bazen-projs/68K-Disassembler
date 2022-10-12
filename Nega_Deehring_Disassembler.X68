*--------------------------------------------------------------------------
* Title      : Motorola 68K Disassembler Final Capstone Project
* Written by : Bazen Nega, Adam Deehring
* Date       : 11 - 11 - 2019
* 
* Description: This code contains a method for you to use
* with your Disassembler project IO, and a short demo of 
* how to call this method in the body of the "START" code.
* 
* Hints and Tips:
*   -Follow the code commenting convention here for file & method headers
*   -Don't rename this file name (Main.X68)
*   -Don't reorg the start address ($1000)
*   -Don't rename or edit the IO method I've provided you with here
*   -Don't rename the config.cfg file or change the file format: 
*    <Long_StartAddress>\CR\LF
*    <Long_EndAddress>\CR\LF<EOF>
*---------------------------------------------------------------------------
    ORG    $1000    *Don't change this; see hints and tips above
*---------------------------------------------------------------------------
START:
    ***********************************************************
    * Code demo for printing strings to console & file is here
    * Pay close attention to:
    *   (1) the detailed comments, 
    *   (2) how to build a (Callee-Saved) method
    *   (3) how to call that method using JSR (return with RTS)
    ***********************************************************
    *LEA MSG1, A1        ; buffer of chars to write
    *JSR TrapTask13
    
    *LEA MSG2, A1        ; buffer of chars to write    
    *JSR TrapTask13

    *LEA ascii_val, A1
    *JSR AsciiToHex     ;  example of how to convert ascii to hex

        JSR StoreAddressesFromConfig
         
        LEA String_Buffer_Block,A5
        
        MOVEA.L Start_Address,A4   * move start address to A4 (which will parse through the "testing region" in the final code)
        CMPA.L #$FFFFFFFF,A4
        BEQ end_Program
        
*********************************************************************************
* Method Name: start_Disassembly
* Description: Iterates through the memory region that will be disassembled, and checks
*              checks for the matching of various supported instructions with the opcode
*              being read (branches to specialized disassembling function for opcode if match found,
*              otherwise continue checking for a match with the next supported instruction)
*
* Calling Convention: Neither
*
* Preconditions & Method Input:
*   A start address has been provided in A4, and an end address has been provided in the memory location of
*   a variable named "End_Address" 
*
* Postconditions & Output:
*   An opcode instruction specialized decoding function is branched to, or we branch to the end of the program
*
*  D7 holds a copy of the current instruction pointed to by A4
*  A4 points to the instruction currently being decoded
*  A5 points at the head of the string buffer block holding the string to be printed out by "TrapTask13"
*  D5 holds a number to be shifted by for a shift operation if the shift value needed exceeds 8
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
********************************************************************************
start_Disassembly:
        CMPA.L End_Address,A4
        BGT end_Program
        MOVE.L #2,D0
        CLR.L D6
        CLR.L D4
        CLR.L D5
        CLR.L D2
        CLR.L D1
        MOVE.L #$0000,A0
        MOVE.L #$0000,A1
        MOVE.L #$0000,A2
        MOVE.L #$0000,A3
        MOVE.L #$0000,A5
        MOVE.L A4,A6
        MOVE.L A4,A0
        JSR Clear_String_Buffer
        LEA String_Buffer_Block,A5
**********Lines added to get print the addresses before a disassembled instruction - 5 lines of code - Start****************
        MOVE.L A4,D1
        MOVE #28,D3
        JSR Add_Hex_String_To_Buffer
        JSR Add_Space
        CLR.L D1
**********Lines added to get print the addresses before a disassembled instruction - 5 lines of code - End******************
        *LEA my_Test_Value, A1 * loads the test value into A1
        *MOVEA A1, A0          * saves the address of A1 into A0
        *JSR AsciiToHex        * call the AscciToHex function to convert the test value from ascii to hex
        MOVE.W (A4),D7
        MOVE.L D7, D3         * moves the converted hex value to D3
        *ANDI.L #$FFFF0000,D3 * checks for a NOP operation
        *MOVE #16,D5
        *LSR.L D5,D3
        CMPI #$4E71,D3
        BEQ NOP_Operation
        JSR Place_D7_in_D3 * re-initializes the value of D3 to the Hex instruction to be deassembled
        *ANDI.L #$FFFF,D3 * checks for an RTS operation
        *MOVE #16,D5
        *LSR.L D5,D3
        CMPI #$4E75,D3
        BEQ RTS_Operation
        JSR Place_D7_in_D3
        ANDI.L #JSR_Mask,D3
        LSR.L #6,D3
        CMPI.W #314,D3
        BEQ Start_JSR_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #NEG_BRA_Mask,D3
        LSR.L #8,D3
        CMPI.W #68,D3
        BEQ Start_NEG_Disassembly
        CMPI.W #12,D3
        BEQ Start_CMPI_Disassembly
        CMPI #0,D3
        BEQ Start_ORI_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #LEA_MULS_Mask,D3
        LSR.L #6,D3
        CMPI.W #263,D3
        BEQ Start_LEA_Disassembly
        CMPI #775,D3
        BEQ Start_MULTS_Disassembly
        CMPI #519, D3
        BEQ Start_DIVS_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #Bcc_CMPI_Mask,D3
        MOVE #12,D5
        LSR.L D5,D3
        CMPI.W #6,D3
        BEQ Start_Bcc_Disassembly
        CMPI.W #14,D3
        BEQ Start_Shifting_Disassembly
        CMPI.W #8,D3
        BEQ Start_OR_Disassembly
        CMPI.W #13,D3
        BEQ Start_Add_Disassembly
        CMPI.W #9,D3
        BEQ Start_Sub_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #SubQ_Mask,D3
        LSR.L #8,D3
        CMPI.W #81,D3
        BEQ Start_SubQ_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #MoveM_Op_Code_Mask,D3
        MOVE #7,D5
        LSR.L D5,D3
        CMPI.W #145,D3
        BEQ Start_MoveM_toM_Disassembly
        CMPI.W #153,D3
        BEQ Start_MoveM_toM_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #Bit_Test_and_Clear_Mask,D3 * start testing for BCLR instruction (Test a Bit and Clear)
        CMPI.W #384,D3
        BEQ Start_Test_Bit_Clear_Disassembly1
        JSR Place_D7_in_D3
        ANDI.L #Bit_Test_and_Clear_Mask2,D3
        LSR.L #6,D3
        CMPI.W #34,D3
        BEQ Start_Test_Bit_Clear_Disassembly2
        JSR Place_D7_in_D3
        ANDI.L #Bcc_CMPI_Mask,D3
        MOVE #12,D5
        LSR.L D5,D3
        CMPI.B #11,D3
        BEQ Start_CMP_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #$F000, D3 * Performs a an AND operation on the converted value with a bitmask and stores the result in D3 (isolates the first four bits)
        MOVE #12,D5           * sets the shift count for how many bits right the first four bits will be shifted to be at the least significant portion of the hex value (32 bits in total, we're starting to move at the 28th bit, hence, shift 28)
        LSR.L D5,D3           * shift the bit values in D3 by the value in D5 (28)
        CMPI.B #4,D3
        BLT Start_Move_Disassembly * statement checks if D3 is less than 4 to confirm "MOVE" operation
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly

*********************************************************************************
* Method Name: Start_MULS_DIVS_Disassembly
* Description: Begins processing of the decoding of a MULS or DIVS instruction. It will load
*              appropriate ascii chars into the string buffer, call the "DestAddressingModeDetermine" function to determine effective addresses, 
*              and print the appropriate string represented assembly language MULS/DIVS instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "MULS" or "DIVS")
*  D7 holds the current instruction opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  A3 stores a flag telling the effective address function what size the operation is (this only has significance if the effective address is determined to be immediate)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
********************************************************************************
Start_MULS_DIVS_Disassembly        
Start_MULTS_Disassembly
        LEA MULS_op,A2
        JSR Start_String_Appending
        BRA After_MULTS_Decision
Start_DIVS_Disassembly
        LEA DIVS_op,A2
        JSR Start_String_Appending
After_MULTS_Decision
        JSR Place_D7_in_D3
        LEA Word_Size,A2
        JSR Start_String_Appending
        MOVE #2,A3
        CLR D2
        MOVE #84,D4
        JSR DestAddressingModeDetermine
        JSR Add_Comma
        CLR D4
        MOVE #1,D2
        JSR R_Destination
        ADDA D0,A4
        JSR TrapTask13
        JSR Clear_String_Buffer
        BRA start_Disassembly
        
        
*********************************************************************************
* Method Name: Start_SubQ_Disassembly
* Description: Begins processing of the decoding of a SUBQ instruction. It will load
*              appropriate ascii chars into the string buffer, call the "DestAddressingModeDetermine" function to determine effective addresses, 
*              and print the appropriate string represented assembly language SUBQ instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "SUBQ")
*  A4 points to the current instruction opcode
*  D7 holds the current instruction opcode word
*  D5 holds a number to be shifted by for a shift operation if the shift value needed exceeds 8
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*  D6 temporarily stores values that D3 would store while D3 is occupied bit masking for other tasks at the moment
Start_SubQ_Disassembly
        LEA SubQ_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ Byte_Size_SubQ
        CMPI #1,D3
        BEQ Word_Size_SubQ
        CMPI #2,D3
        BEQ Long_Size_SubQ
        BRA SubQ_Error
Byte_Size_SubQ
        JSR Byte_Print
        MOVE #84,D4
        MOVE #4,D6
        BRA After_Size_SubQ
Word_Size_SubQ
        JSR Word_Print
        MOVE #12,D6
        BRA After_Size_SubQ
Long_Size_SubQ
        JSR Long_Print
        MOVE #28,D6
After_Size_SubQ
        JSR AddPoundSign
        JSR AddHexCash
        JSR Place_D7_in_D3
        ANDI #$0E00,D3
        MOVE #9,D5
        LSR.L D5,D3
        CMPI #0,D3
        BEQ ChangeToEight
        BRA After_Addition_Decision
ChangeToEight
        ADD #8,D3
        
After_Addition_Decision
        MOVE D3,D1
        Move D6,D3
        JSR Add_Hex_String_To_Buffer
        JSR Add_Comma
        CLR D2
        MOVE #60,D6
        JSR DestAddressingModeDetermine
        CLR D6
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
SUBQ_Error
        *JSR Print_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly

*********************************************************************************
* Method Name: Start_Sub_Disassembly
* Description: Begins processing of the decoding of a SUB instruction. It will load
*              appropriate ascii chars representing "SUB" into the string buffer and branch to another label to continue processing the 
*              instruction.
*
* Calling Convention: Neither
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode field via "Start_String_Appending" call.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "SUB")
*  D5 ??? (appears to be left over from earlier build)
*  D3 ??? (appears to be left over from earlier build)
Start_Sub_Disassembly
        MOVE D3,D5
        LEA SUB_op,A2
        JSR Start_String_Appending
        BRA After_Decision_Add
        
*********************************************************************************
* Method Name: Start_Add_Disassembly
* Description: Begins processing of the decoding of a ADD instruction. It will first check to see
*              if the instruction is in fact an ADDA instruction, using bit masks. If so, it will go
*              to the label "ADDA_Disassembly" to begin processing the different instruction, otherwise it will
*              continue processing the "ADD" instruction.
*
* Calling Convention: Neither
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Branches to correct disassembly function based on condition of effective addressing field
*
*  D3 holds a copy of the current instruction opcode word for bit mask manipulation without data loss
*  D7 holds the current instruction opcode word   
Start_Add_Disassembly
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #3,D3
        BNE ADD_Disassembly  * Checks for an ADDA instruction and branches if confirmed
        
*********************************************************************************
* Method Name: Start_ADDA_Disassembly
* Description: Begins processing of the decoding of a ADDA instruction. It will load
*              appropriate ascii chars representing "ADDA" into the string buffer and call the "DestAddressingModeDetermine"
*              function to decode and build the effective addresses string, and will branch to "End_Add" to print and loop back 
*              to "start_Disassembly"
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Test for "ADD" instruction in "Start_Add_Disassembly" failed. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode instruction via "Start_String_Appending" call and prints to file.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "ADDA")
*  D7 holds the current instruction word
*  D3 represents the width of the string hex value that will be converted to ascii (4: byte, 12: word, 28: long)
*  A3 stores a flag to indicate the size of the operation (1: byte, 2: word, 3: long) to the "DestAddressingModeDetermine" function (only has significance for handling
*  immediate addressing)
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
ADDA_Disassembly
        LEA ADDA_op,A2
        JSR Start_String_Appending
        BTST #8,D7
        BNE Long_ADDA
Word_ADDA
        LEA Word_Size,A2
        MOVE #2,A3
        MOVE #12,D3
        JSR Start_String_Appending
        BRA Continue_ADDA
Long_ADDA
        LEA Long_Size,A2
        MOVE #3,A3
        MOVE #28,D3
        JSR Start_String_Appending
Continue_ADDA
        CLR D2
        JSR DestAddressingModeDetermine
        MOVE #1,D4  * tells the R_Destination function that it wants an address register printed
        MOVE #1,D2  * tells the R_Desination function that it wants a destination (bits 9-11) register printed)
        JSR Add_Comma
        JSR R_Destination
        BRA End_Add
       
*********************************************************************************
* Method Name: ADD_Disassembly
* Description: Begins processing of the decoding of a ADD instruction. It will load
*              appropriate ascii chars representing "ADD" into the string buffer and call the "DestAddressingModeDetermine"
*              function to decode and build the effective addresses string, and will branch to "End_Add" to print and loop back 
*              to "start_Disassembly". If size determined is invalid, then branch to "Add_Error" to print "XXXXXXXX DATA YYYY" and clear the string 
*              buffer.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "Start_Add_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode instruction via "Start_String_Appending" call and prints to file.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "ADD")
*  D7 holds the current instruction word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data (determines size of operation here)
*  A3 stores a flag to indicate the size of the operation (1: byte, 2: word, 3: long) to the "DestAddressingModeDetermine" function (only has significance for handling
*  immediate addressing)
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  A4 points to the current instruction opcode word in memory
ADD_Disassembly
        LEA Add_op,A2
        JSR Start_String_Appending
        
After_Decision_Add
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ Byte_Size_Add
        CMPI #1,D3
        BEQ Word_Size_Add
        CMPI #2,D3
        BEQ Long_Size_Add
        BRA Add_Error
Byte_Size_Add
        JSR Byte_Print
        MOVE #1,A3
        BRA Check_Order_Add
        
Word_Size_Add
        JSR Word_Print
        MOVE #2,A3
        BRA Check_Order_Add

Long_Size_Add
        JSR Long_Print
        MOVE #3,A3

Check_Order_Add
        CLR D2
        BTST #8,D7
        BNE EffectiveAdd_Add_First
        BRA Data_Add_First
Data_Add_First
        CLR D2
        JSR DestAddressingModeDetermine
        JSR Add_Comma
        MOVE #1,D2
        JSR R_Destination
        CLR D5
        BRA End_Add
EffectiveAdd_Add_First
        MOVE #1,D2
        JSR R_Destination
        JSR Add_Comma
        CLR D2
        MOVE #404,D4
        JSR DestAddressingModeDetermine
        CLR D5

End_Add
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly

Add_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly


*********************************************************************************
* Method Name: Start_ORI_Disassembly
* Description: Begins processing of the decoding of a ORI instruction. It will load
*              appropriate ascii chars into the string buffer, call the "DestAddressingModeDetermine" function to determine the destination effective address, 
*              and print the appropriate string represented assembly language ORI instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "ORI")
*  A3 stores a flag to indicate the size of the operation (1: byte, 2: word, 3: long) to the "DestAddressingModeDetermine" function (only has significance for handling
*  immediate addressing)
*  A4 points to the current instruction opcode in memory
*  D7 holds the current instruction opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************
Start_ORI_Disassembly
        LEA ORI_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ Byte_ORI
        CMPI #1,D3
        BEQ Word_ORI
        CMPI #2,D3
        BEQ Long_ORI
        BRA ORI_Error
Byte_ORI
        JSR Byte_Print
        MOVE #1,A3
        MOVE #4,D3
        BRA After_Size_ORI
        
Word_ORI
        JSR Word_Print
        MOVE #2,A3
        MOVE #12,D3
        BRA After_Size_ORI

Long_ORI
        JSR Long_Print
        MOVE #28,D3
        MOVE #3,A3   

After_Size_ORI
        JSR IsolateInstrOperands
        JSR AddPoundSign
        JSR AddHexCash
        JSR Add_Hex_String_To_Buffer
        MOVE.L D6,D1
        JSR Add_Comma
        CLR D2
        MOVE #99,D4  * indicate that the function call came from an ORI instruction to DestAddressingModeDetermine
        CLR.L D1
        JSR DestAddressingModeDetermine
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
        
ORI_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly
        

*********************************************************************************
* Method Name: Start_OR_Disassembly
* Description: Begins processing of the decoding of a OR instruction. It will load
*              appropriate ascii chars into the string buffer, call the "DestAddressingModeDetermine" function to determine the destination effective address, 
*              and print the appropriate string represented assembly language OR instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "OR")
*  A3 stores a flag to indicate the size of the operation (1: byte, 2: word, 3: long) to the "DestAddressingModeDetermine" function (only has significance for handling
*  immediate addressing)
*  A4 points to the current instruction opcode in memory
*  D7 holds the current instruction opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************
Start_OR_Disassembly
        LEA OR_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ Byte_Size_OR
        CMPI #1,D3
        BEQ Word_Size_OR
        CMPI #2,D3
        BEQ Long_Size_OR
        BRA OR_Error
Byte_Size_OR
        JSR Byte_Print
        MOVE #1,A3
        BRA After_Size_OR
Word_Size_OR
        JSR Word_Print
        MOVE #2,A3
        BRA After_Size_OR
Long_Size_OR
        JSR Long_Print
        MOVE #3,A3
After_Size_OR
        BTST #8,D7
        BNE Print_Data_Reg_First
        BRA Print_Effective_Address_First
Print_Data_Reg_First
        CLR D4
        MOVE #1,D2
        JSR R_Destination
        JSR Add_Comma
        CLR D2
        MOVE #92,D4 * signals to DestAddressingModeDetermine that the function call came from an OR instruction with effective address as destination
        JSR DestAddressingModeDetermine
        BRA After_OR_Decision
Print_Effective_Address_First
        CLR D2
        MOVE #98,D4 * signals to DestAddressingModeDetermine that the function call came from an OR instruction with effective address as source
        JSR DestAddressingModeDetermine
        JSR Add_Comma
        CLR D2
        MOVE #1,D2
        JSR R_Destination
        
After_OR_Decision
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
        
OR_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly
        
*********************************************************************************
* Method Name: Start_Shifting_Disassembly
* Description: Begins processing of the decoding of various shift instructions (LSL,LSR,ASL,ASR,ROL,ROR). It will determine which subtype the instruction
*              is via bit masking as well as what operand format it comes in (i.e. Dn,Dn or #<data>,Dy, or <ea>). Appropriate ascii chars will 
*              then be put into the string buffer, call the "DestAddressingModeDetermine" function to determine the effective addresses, 
*              and print the appropriate string represented assembly language shifting instruction (any one of them).
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "LSL","LSR","ASR","ASL","ROR","ROL")
*  A4 points to the current instruction opcode in memory
*  D7 holds the current instruction opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D6 temporarily holding the value D3 would hold when D3 needs to be used for another bit masking purpose at a particular moment
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************
Start_Shifting_Disassembly
        JSR Place_D7_in_D3
        ANDI #$FFC0,D3
        LSR.L #6,D3
        CMPI #907,D3
        BEQ Memory_Logical_Shift_Right
        CMPI #911,D3
        BEQ Memory_Logical_Shift_Left
        CMPI #899,D3
        BEQ Memory_Arithmetic_Shift_Right
        CMPI #903,D3
        BEQ Memory_Arithmetic_Shift_Left
        CMPI #923,D3
        BEQ Memory_Roll_Right
        CMPI #927,D3
        BEQ Memory_Roll_Left
        JSR Place_D7_in_D3
        ANDI #$0018,D3
        LSR #3,D3
        CMPI #1,D3
        BEQ Register_Shift
        CMPI #0,D3
        BEQ Register_Shift
        CMPI #3,D3
        BEQ Register_Shift
        BRA Shift_Error
Memory_Arithmetic_Shift_Right
        LEA ASR_op,A2
        JSR Start_String_Appending
        JSR Add_Space
        BRA ContinueMemoryShift
        
Memory_Arithmetic_Shift_Left
        LEA ASL_op,A2
        JSR Start_String_Appending
        JSR Add_Space
        BRA ContinueMemoryShift

Memory_Roll_Left
        LEA ROL_op,A2
        JSR Start_String_Appending
        JSR Add_Space
        BRA ContinueMemoryShift
        
Memory_Roll_Right
        LEA ROR_op,A2
        JSR Start_String_Appending
        JSR Add_Space
        BRA ContinueMemoryShift

Memory_Logical_Shift_Right
        LEA LSR_op,A2
        JSR Start_String_Appending
        JSR Add_Space
        BRA ContinueMemoryShift
Memory_Logical_Shift_Left
        LEA LSL_op,A2
        JSR Start_String_Appending
        JSR Add_Space
ContinueMemoryShift
        CLR D2
        MOVE #31,D4     * flag indicates that function call came from a LSd Memory Shift operation to DestAddressingModeDetermine
        JSR DestAddressingModeDetermine
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
       * ANDI #$0100,D3
       * LSR.L #8,D3
       * CMPI #0,D3
       * BEQ PrintLSR
   
Register_Shift
        MOVE D3,D6
        JSR Place_D7_in_D3
        ANDI #$0100,D3
        LSR.L #8,D3
        CMPI #1,D3
        BEQ Register_Left
Register_Right
        CMPI #0,D6
        BEQ Print_ArithmeticR
        CMPI #3,D6
        BEQ Print_RORR
        LEA LSR_op,A2
        JSR Start_String_Appending
        BRA ProcessRegisterShift
        
Print_RORR
        LEA ROR_op,A2
        JSR Start_String_Appending
        BRA ProcessRegisterShift
        
Print_ArithmeticR
        LEA ASR_op,A2
        JSR Start_String_Appending
        BRA ProcessRegisterShift
        
Register_Left
        CMPI #0,D6
        BEQ Print_ArithmeticL
        CMPI #3,D6
        BEQ Print_RORL
        LEA LSL_op,A2
        JSR Start_String_Appending
        BRA ProcessRegisterShift
Print_ArithmeticL
        LEA ASL_op,A2
        JSR Start_String_Appending
        BRA ProcessRegisterShift
        
Print_RORL
        LEA ROL_op,A2
        JSR Start_String_Appending
        
ProcessRegisterShift
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ Reg_Byte
        CMPI #1,D3
        BEQ Reg_Word
        CMPI #2,D3
        BEQ Reg_Long
        BRA Shift_Error
Reg_Byte
        LEA Byte_Size,A2
        MOVE #4,D5
        BRA ProcessRegister
Reg_Word
        LEA Word_Size,A2
        MOVE #12,D5
        BRA ProcessRegister
Reg_Long
        LEA Long_Size,A2
        MOVE #28,D5
ProcessRegister
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$0020,D3
        LSR.L #5,D3
        CMPI #1,D3
        BEQ RegisterSpecified
RegisterImmediate
        JSR Place_D7_in_D3
        JSR LSd_Register_Mask_Isolate
        JSR AddPoundSign
        JSR AddHexCash
        CMPI #0,D3
        BNE AfterEight
ConvertFromEight
        MOVE #8,D3
AfterEight
        MOVE D3,D1
        MOVE D5,D3
        JSR Add_Hex_String_To_Buffer
        JSR Add_Comma
        CLR D2
        JSR R_Destination
        BRA EndShift
RegisterSpecified
        JSR Place_D7_in_D3
        JSR LSd_Register_Mask_Isolate
        MOVE #1,D2
        CLR D4
        JSR R_Destination
        JSR Add_Comma
        CLR D2
        JSR R_Destination
EndShift
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
Shift_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly
        

*********************************************************************************
* Method Name: Start_CMPI_Disassembly
* Description: Begins processing of the decoding of a CMPI instruction. Appropriate ascii chars will then be put into the string buffer, call 
*              the "DestAddressingModeDetermine" function to determine the effective addresses, and print the appropriate string 
*              represented assembly language CMPI instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "CMPI")
*  A4 points to the current instruction opcode in memory
*  A6 points to a displacement point from the current instruction opcode address (allows fetching of word operands without changing A4)
*  D7 holds the current instruction opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************
Start_CMPI_Disassembly
        LEA CMPI_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ CMPI_Byte
        CMPI #1,D3
        BEQ CMPI_Word
        CMPI #2,D3
        BEQ CMPI_Long
        BRA CMPI_Error
CMPI_Byte
        LEA Byte_Size,A2
        JSR Start_String_Appending
        MOVE.L A4,A6
        ADDA #2,A6
        ADDI #2,D0
        MOVE.W (A6),D1
        ANDI.W #$00FF,D1
        JSR AddPoundSign
        JSR AddHexCash
        MOVE #4,D3
        JSR Add_Hex_String_To_Buffer
        BRA Process_CMPI
CMPI_Word
        LEA Word_Size,A2
        JSR Start_String_Appending
        MOVE.L A4,A6
        ADDA #2,A6
        ADDI #2,D0
        MOVE.W (A6),D1
        JSR AddPoundSign
        JSR AddHexCash
        MOVE #12,D3
        JSR Add_Hex_String_To_Buffer
        BRA Process_CMPI
CMPI_Long
        LEA Long_Size,A2
        JSR Start_String_Appending
        MOVE.L A4,A6
        ADDA #2,A6
        MOVE.W (A6),D1
        ADDA #2,A6
        ADDI #4,D0
        MOVE #16,D5
        LSL.L D5,D1
        MOVE.W (A6),D1
        JSR AddPoundSign
        JSR AddHexCash
        MOVE #28,D3
        JSR Add_Hex_String_To_Buffer
Process_CMPI
        CLR D2                
        MOVE #27,D4
        JSR Add_Comma
        CLR.L D1
        JSR DestAddressingModeDetermine
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
        
CMPI_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly
        

*********************************************************************************
* Method Name: Start_CMP_Disassembly
* Description: Begins processing of the decoding of a CMP instruction. Can branch to an EOR instruction if specific fields in the opcode
*              line up with an EOR interpretation. This is a result of shared fields between the two instructions. 
*              Appropriate ascii chars will then be put into the string buffer, call the "DestAddressingModeDetermine" function to 
*              determine the effective addresses, and print the appropriate string represented assembly language CMP instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format. Could also branch to "Start_EOR_Disassembly", if EOR condition check passes.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "CMP")
*  A4 points to the current instruction opcode in memory
*  D7 holds the current instruction opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************
Start_CMP_Disassembly
        BTST #8,D7
        BNE Start_EOR_Disassembly * checks to see if instruction is actually an EOR instruction
        LEA CMP_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI.L #$01C0,D3
        MOVE #6,D5
        LSR.L D5,D3
        CMPI #0,D3
        BEQ CMP_Byte
        CMPI #1,D3
        BEQ CMP_Word
        CMPI #2,D3
        BEQ CMP_Long
        BRA CMP_Error
CMP_Byte
        LEA Byte_Size,A2
        JSR Start_String_Appending
        BRA Process_CMP
CMP_Word
        LEA Word_Size,A2
        JSR Start_String_Appending
        BRA Process_CMP
CMP_Long
        LEA Long_Size,A2
        JSR Start_String_Appending
Process_CMP
        CLR D2
        MOVE #21,D4 * mark as from CMP instruction for proper data register direct processing in the DestAddressingModeDetermine function
        JSR DestAddressingModeDetermine
        *JSR Print_Data_Register
        JSR Place_D7_in_D3
        ANDI #$0E00,D3
        MOVE #9,D5
        LSR.L D5,D3
        CLR.L D1
        MOVE D3,D5
        JSR Add_Comma
        JSR CallDPrintNumber
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
        
CMP_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly

*********************************************************************************
* Method Name: Start_EOR_Disassembly
* Description: Begins processing of the decoding of a EOR instruction. Appropriate ascii chars will then be put into the string buffer, call 
*              the "DestAddressingModeDetermine" function to determine the effective addresses, and print the appropriate string 
*              represented assembly language EOR instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "Start_CMP_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "EOR")
*  A4 points to the current instruction opcode in memory
*  D7 holds the current instruction opcode word
*  D6 stores a flag that notifies the "DestAddressingModeDetermine" function that the function calling it is processing a destination operand (#60 indicates this state)
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************       
Start_EOR_Disassembly
        LEA EOR_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$01C0,D3
        LSR.L #6,D3
        CMPI #4,D3
        BEQ Byte_Size_EOR
        CMPI #5,D3
        BEQ Word_Size_EOR
        CMPI #6,D3
        BEQ Long_Size_EOR
        BRA EOR_Error
Byte_Size_EOR
        JSR Byte_Print
        BRA After_Size_EOR
Word_Size_EOR
        JSR Word_Print
        BRA After_Size_EOR
Long_Size_EOR
        JSR Long_Print
After_Size_EOR
        MOVE #1,D2     * move 1 to D2 to specify printing the "destination" register (reaaly printing the left most register specification (bits 9 through 11)
        CLR D4
        JSR R_Destination
        JSR Add_Comma
        MOVE #500,D4
        MOVE #60,D6
        CLR.L D2
        JSR DestAddressingModeDetermine
        CLR D6
        ADD D0,A4
        JSR TrapTask13
        BRA start_Disassembly
EOR_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly


*********************************************************************************
* Method Name: Start_Bcc_Disassembly
* Description: Begins processing of the decoding of a Bcc instruction (any one of them). The specific subtype is determined first via
*              bit masking. Appropriate ascii chars will then be put into the string buffer, call the "DestAddressingModeDetermine" 
*              function to determine the effective addresses, and print the appropriate string represented assembly language Bcc instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "BVC,BLT,BCS,BGE")
*  A4 points to the current instruction opcode in memory
*  A3 stores a flag to indicate the size of the operation (1: byte, 2: word, 3: long) to the "DestAddressingModeDetermine" function (only has significance for handling
*  immediate addressing)
*  D7 holds the current instruction opcode word
*  D6 holds the word operands after the opcode word
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data, also stores width of ascii hex value to be appended
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*  D1 holds the hex value to be converted to hex
*********************************************************************************     
Start_Bcc_Disassembly
        JSR Place_D7_in_D3
        ANDI.L #$0F00,D3
        MOVE #8,D5
        LSR.L D5,D3
CheckCondition
        CMPI #5,D3
        BEQ BCS
        CMPI #12,D3
        BEQ BGE
        CMPI #13,D3
        BEQ BLT
        CMPI #8,D3
        BEQ BVC
        CMPI #0,D3
        BEQ BRA
        BRA UnrecognizedCondition
BCS
        LEA BCS_op,A2
        JSR Start_String_Appending
        BRA Process_Bcc_Disassembly
BGE
        LEA BGE_op,A2
        JSR Start_String_Appending
        BRA Process_Bcc_Disassembly
BLT
        LEA BLT_op,A2
        JSR Start_String_Appending
        BRA Process_Bcc_Disassembly
BVC
        LEA BVC_op,A2
        JSR Start_String_Appending
        BRA Process_Bcc_Disassembly
        
BRA
        LEA BRA_op,A2
        JSR Start_String_Appending

Process_Bcc_Disassembly
        JSR Place_D7_in_D3
        ANDI #$00FF,D3
        CMPI.B #$00,D3
        BEQ One_Word
        CMPI.B #$FF,D3
        BEQ UnrecognizedCondition
        BRA One_Byte
One_Byte
        LEA Byte_Size,A2
        JSR Start_String_Appending
        JSR AddHexCash
        JSR Place_D7_in_D3
        ANDI #$00FF,D3
        CLR.L D1
        MOVE.L A4,D1
        MOVE.L D3,D4
        ADD.L D4,D1
        ADD #2,D1
        MOVE #28,D3
        JSR Add_Hex_String_To_Buffer
        BRA After_Word_Decision
One_Word
        LEA Word_Size,A2
        JSR Start_String_Appending
        JSR AddHexCash
        MOVEA.L #2,A3           * Need to isolate A3 (2: word, 3: long)
        MOVE A4, D2
        JSR IsolateInstrOperands
        CLR.L D1
        MOVE.W D6,D1
        ADD.L A4,D1
        ADD #2,D1
        MOVE #28,D3
        ANDI.L #$FFFF,D1
        JSR Add_Hex_String_To_Buffer
After_Word_Decision 
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
        
UnrecognizedCondition
        JSR Error_Subroutine
        ADD D0,A4
        BRA start_Disassembly


*********************************************************************************
* Method Name: Start_NEG_Disassembly
* Description: Begins processing of the decoding of a NEG instruction. Appropriate ascii chars will then be put into the string buffer, 
*              call the "DestAddressingModeDetermine" function to determine the effective addresses, and print the appropriate string 
*              represented assembly language NEG instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "NEG")
*  A4 points to the current instruction opcode in memory
*  D7 holds the current instruction opcode word
*  D6 flag for destination operand for DestAdressingModeDetermine
*  D3 temporarily holds a copy of the current intruction opcode word to allow for manipulation via bit masks, without loss of data, also stores width of ascii hex value to be appended
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************     
Start_NEG_Disassembly
        LEA NEG_op,A2
        JSR Start_String_Appending
        JSR Place_D7_in_D3
        ANDI #$00C0,D3
        LSR.L #6,D3
        CMPI #0,D3
        BEQ NEG_Byte
        CMPI #1,D3
        BEQ NEG_Word
        CMPI #2,D3
        BEQ NEG_Long
        BRA NEG_Error
NEG_Byte
        JSR Byte_Print
        MOVE #4,D3
        BRA NEG_Size_Determined
NEG_Word
        JSR Word_Print
        MOVE #12,D3
        BRA NEG_Size_Determined
NEG_Long
        JSR Long_Print
        MOVE #28,D3
NEG_Size_Determined
        MOVE #500,D4     * flag for telling DestAddressingModeDetermine that a NEG operation called it
        MOVE $60,D6
        CLR D2
        JSR DestAddressingModeDetermine
        CLR D6
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly
NEG_Error
        JSR Error_Subroutine
        ADDA D0,A4
        BRA start_Disassembly       


*********************************************************************************
* Method Name: Start_LEA_Disassembly
* Description: Begins processing of the decoding of a LEA instruction. Appropriate ascii chars will then be put into the string buffer, 
*              call the "DestAddressingModeDetermine" function to determine the effective addresses, and print the appropriate string 
*              represented assembly language LEA instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "LEA")
*  A4 points to the current instruction opcode in memory
*  D6 flags a destination operand to "DestAddressingModeDetermine"
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D2 stores a flag that tells the effective addressing function, "DestAddressingModeDetermine" whether to process bits 0-5 (D2 = 1) or 6-11 (D2 = anything else)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************     
Start_LEA_Disassembly
        LEA LEA_op,A2
        JSR Start_String_Appending
        MOVE #400,D4      * flag to let DestAddressingModeDetermine know this is an LEA function
        MOVE #60,D6
        CLR.L D2
        JSR DestAddressingModeDetermine
        CLR D6
        JSR Add_Comma
        MOVE #1,D4
        MOVE #1,D2
        JSR R_Destination
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly


*********************************************************************************
* Method Name: Start_JSR_Disassembly
* Description: Begins processing of the decoding of a JSR instruction. Appropriate ascii chars will then be put into the string buffer, 
*              call the "DestAddressingModeDetermine" function to determine the effective addresses, and print the appropriate string 
*              represented assembly language JSR instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "JSR")
*  A4 points to the current instruction opcode in memory
*  D6 flags a destination operand to "DestAddressingModeDetermine"
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D0 stores the amount by which A4 will be incremented after the completion of this function
*********************************************************************************  
Start_JSR_Disassembly
        MOVE #55,D4       * flag to let DestAddressingModeDetermine know this is a JSR instruction
        MOVE #60,D6
        LEA JSR_op,A2
        JSR Start_String_Appending
        JSR DestAddressingModeDetermine
        CLR D6
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly


*********************************************************************************
* Method Name: Start_Test_Bit_Clear_Disassembly1
* Description: Begins processing of the decoding of a BCLR dynamic instruction. Source is always data register. Appropriate ascii chars 
*              will then be put into the string buffer, call the "DestAddressingModeDetermine" function to determine the effective 
*              addresses, and print the appropriate string represented assembly language BCLR instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "BCLR")
*  A4 points to the current instruction opcode in memory
*  D6 flags a destination operand to "DestAddressingModeDetermine"
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*********************************************************************************  
Start_Test_Bit_Clear_Disassembly1 * make D4 1 if using an Address register
        LEA BCLR_op,A2
        JSR Start_String_Appending
        MOVE #60,D6 * marks a destination address for DestAddressingModeDetermine
        MOVE #15,D4 * marks a destination location as from BCLR
        JSR DestAddressingModeDetermine
        CLR D6
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly


*********************************************************************************
* Method Name: Start_Test_Bit_Clear_Disassembly2
* Description: Begins processing of the decoding of a BCLR static instruction. Source is always immediate. Appropriate ascii chars 
*              will then be put into the string buffer, call the "DestAddressingModeDetermine" function to determine the effective 
*              addresses, and print the appropriate string represented assembly language BCLR instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "BCLR")
*  A3 holds immediate data after opcode word
*  A4 points to the current instruction opcode in memory
*  D3 used for both specifying width size of converted hex to ascii character, and acts as a bit mask destination for isolating bits for operation size validation
*  D6 flags a destination operand to "DestAddressingModeDetermine"
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D1 holds the immediate data (transferred from D6 to fulfill AsciiToHex precondition of value in D1)
*********************************************************************************  
Start_Test_Bit_Clear_Disassembly2
        LEA BCLR_op,A2
        JSR Start_String_Appending
        MOVE (2,A4),A3
        ADD #2,D0
        MOVE A3,D1
        CMPI.L #255,D1
        BGT BCLR_ERROR
        MOVE D7,D3
        ANDI.L #$0038,D3
        LSR.L #3,D3
        CMPI #0,D3
        BEQ WriteLong
WriteByte
        LEA Byte_Size,A2
        JSR Start_String_Appending   
        MOVE #4,D3   
        BRA After_Size_Decision
BCLR_ERROR
        JSR Error_Subroutine
        ADDA D0,A4
        BRA END_BCLR
WriteLong
        LEA Long_Size,A2
        MOVE #28,D3
        JSR Start_String_Appending
After_Size_Decision
        MOVE #50,D4
        MOVE #60,D6
        JSR AddPoundSign
        JSR AddHexCash
        JSR Add_Hex_String_To_Buffer
        JSR Add_Comma
        JSR DestAddressingModeDetermine
        CLR D6
        ADDA D0,A4
        *ADDA #2,A4
        JSR TrapTask13
END_BCLR
        BRA start_Disassembly
        

*********************************************************************************
* Method Name: BCLR_Data_Register_Print
* Description: Adds to the string buffer a data register of number matching what is specified in bits 9-11.
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   Called by a function in the middle of processing a BCLR instruction. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Print_Data_Register" and "Add_Hex_String_To_Buffer" call.
*
*  D7 holds the current opcode intruction word
*  D3 holds a copy of the current opcode instruction word for processing bit masks and manipulating data without permanent loss
*  D5 holds a shift count for shifting register D3 (since shift value is greater than 8)
*  D1 holds the register number for the data register, and is converted from hex to ascii to add to the buffer
*********************************************************************************  
BCLR_Regs REG D0-D3,D5
BCLR_Data_Register_Print
        MOVEM.L BCLR_Regs,-(SP)
        JSR Print_Data_Register
        MOVE.L D7,D3
        ANDI.L #$0E00,D3
        MOVE #9,D5
        LSR.L D5,D3
        MOVE D3,D1
        MOVE #0,D3
        JSR Add_Hex_String_To_Buffer
        MOVEM.L (SP)+,BCLR_Regs
        RTS

*********************************************************************************
* Method Name: Start_MoveM_toM_Disassembly
* Description: Begins processing of the decoding of a MOVEM dynamic instruction. Determines direction of transfer (either memory to register or register to
*              memory). Appropriate ascii chars will then be put into the string buffer, call the "DestAddressingModeDetermine" function to determine the 
*              effective addresses, and print the appropriate string represented assembly language MOVEM instruction.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word via "Start_String_Appending" call, prints 
*   the string to console and writes to file via "TrapTask13" call. Clears the buffer after it's done using it. Increment the A4 instruction pointer
*   necessary amount given current instruction format.
*
*  A2 holds the address of the variable string holding the operation string opcode word (i.e. "MOVEM")
*  A3 stores the register list before moving it to D6
*  A4 points to the current instruction opcode in memory
*  D7 holds the current intruction opcode word
*  D3 holds a copy of the current intruction opcode word for the purposes of bit mask manipulation without permanently losing data from D7
*  D6 holds the register list that comes after the instruction opcode word
*  D4 stores a flag that uniquely identifies this function as the calling function when "DestAddressingModeDetermine" is called, allowing
*  the function to know which addressing modes to forbid for this instruction.
*  D5 holds the shift value for registers to shift by (when shift value is greater than 8)
*  D2 stores a flag that indicates which bits to isolate for an effective address in a function call (0: bits 0-5, 1: 6-11)
*********************************************************************************  
Start_MoveM_toM_Disassembly
        LEA MoveM_op,A2
        JSR Start_String_Appending
        MOVE (2, A4),A3
        MOVE D7,D3
        ANDI.W #$0040,D3
        LSR #6,D3
        BEQ Print_Word       
Print_Long
        LEA Long_Size,A2
        BRA M_Size_Decided

Print_Word
        LEA Word_Size,A2
        
M_Size_Decided
        JSR Start_String_Appending
        *ADDA #2,A4
        CLR.L D2
        JSR Place_D7_in_D3
        ANDI.W #$0400,D3
        MOVE #10,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mem_to_Reg
        CMPI #0,D3
        BEQ Reg_to_Mem
        JSR Error_Subroutine
        ADD D0,A4
        BRA start_Disassembly
        
Mem_to_Reg
        MOVE #65,D4
        JSR DestAddressingModeDetermine
        JSR Add_Comma
        JSR GetRegisterList
        JSR Increment_Function
        CLR.L D3
        ADD D0,A4
        JSR TrapTask13
        BRA start_Disassembly

Reg_to_Mem
        JSR GetRegisterList
        JSR Add_Comma
        MOVE #66,D4
        JSR DestAddressingModeDetermine * will determine effective address
        JSR Increment_Function
        CLR.L D3
        ADD D0,A4
        JSR TrapTask13
        BRA start_Disassembly


GetRegisterList:
        MOVE D7,D6
        ANDI #Move_Source_Mode,D6
        LSR.L #3,D6
        CMPI #4,D6
        BEQ Set_Flag
        BRA After_Flag_Decision
Set_Flag MOVE #100,D4 * tells the algorithm that the mode used is predecrement
After_Flag_Decision
        MOVEA A3,A6
        *ADDA #2,A6
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0001,D3 * get least significant bit (equivalent to D0)
        MOVE #0,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark1
NotMet1 BRA NextPoint1   
Mark1   
        CMPI #100,D4
        BEQ PreDecrementMode
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint1
PreDecrementMode JSR MOVEM_PreDecrement
NextPoint1
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0002,D3
        MOVE #1,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark2
NotMet2 BRA NextPoint2        
Mark2   
        CMPI #100,D4
        BEQ PreDecrementMode2
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint2
PreDecrementMode2 JSR MOVEM_PreDecrement
NextPoint2
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0004,D3
        MOVE #2,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark3
NotMet3 BRA NextPoint3
Mark3   
        CMPI #100,D4
        BEQ PreDecrementMode3
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint3
PreDecrementMode3 JSR MOVEM_PreDecrement
NextPoint3
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0008,D3
        MOVE #3,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark4
NotMet4 BRA NextPoint4
Mark4   
        CMPI #100,D4
        BEQ PreDecrementMode4
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint4
PreDecrementMode4 JSR MOVEM_PreDecrement
NextPoint4
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0010,D3
        MOVE #4,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark5                       
NotMet5 BRA NextPoint5
Mark5   
        CMPI #100,D4
        BEQ PreDecrementMode5
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint5
PreDecrementMode5 JSR MOVEM_PreDecrement
NextPoint5
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0020,D3
        MOVE #5,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark6      
NotMet6 BRA NextPoint6
Mark6   
        CMPI #100,D4
        BEQ PreDecrementMode6
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint6
PreDecrementMode6 JSR MOVEM_PreDecrement
NextPoint6
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0040,D3
        MOVE #6,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark7
NotMet7 BRA NextPoint7
Mark7   
        CMPI #100,D4
        BEQ PreDecrementMode7
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint7
PreDecrementMode7 JSR MOVEM_PreDecrement
NextPoint7
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0080,D3
        MOVE #7,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark8
NotMet8 BRA NextPoint8
Mark8   
        CMPI #100,D4
        BEQ PreDecrementMode8
        JSR CallDPrintNumber
        JSR Add_Slash
        BRA NextPoint8
PreDecrementMode8 JSR MOVEM_PreDecrement
NextPoint8
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0100,D3
        MOVE #8,D5
        LSR.L D5,D3
        CMPI #1,D3
        BEQ Mark9
NotMet9 BRA NextPoint9
Mark9   
        CMPI #100,D4
        BEQ PreDecrementMode9
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint9
PreDecrementMode9 
        MOVE #1,D2
        JSR MOVEM_PreDecrement_Rev
NextPoint9
        MOVE #1,D2
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0200,D3
        MOVE #9,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark10
NotMet10 BRA NextPoint10
Mark10  
        CMPI #100,D4
        BEQ PreDecrementMode10
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint10
PreDecrementMode10 JSR MOVEM_PreDecrement_Rev
NextPoint10
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0400,D3
        MOVE #10,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark11
NotMet11 BRA NextPoint11
Mark11  
        CMPI #100,D4
        BEQ PreDecrementMode11
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint11
PreDecrementMode11 JSR MOVEM_PreDecrement_Rev
NextPoint11
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$0800,D3
        MOVE #11,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark12
NotMet12 BRA NextPoint12
Mark12  
        CMPI #100,D4
        BEQ PreDecrementMode12
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint12
PreDecrementMode12 JSR MOVEM_PreDecrement_Rev
NextPoint12
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$1000,D3
        MOVE #12,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark13
NotMet13 BRA NextPoint13
Mark13  
        CMPI #100,D4
        BEQ PreDecrementMode13
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint13
PreDecrementMode13 JSR MOVEM_PreDecrement_Rev
NextPoint13
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$2000,D3
        MOVE #13,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark14
NotMet14 BRA NextPoint14
Mark14  
        CMPI #100,D4
        BEQ PreDecrementMode14
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint14
PreDecrementMode14 JSR MOVEM_PreDecrement_Rev
NextPoint14
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$4000,D3
        MOVE #14,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark15
NotMet15 BRA NextPoint15
Mark15  
        CMPI #100,D4
        BEQ PreDecrementMode15
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint15
PreDecrementMode15 JSR MOVEM_PreDecrement_Rev
NextPoint15
        MOVE A6,D6
        MOVE D6,D3
        ANDI #$8000,D3
        MOVE #15,D5
        LSR.L D5,D3
        ADDI #2,D2
        CMPI #1,D3
        BEQ Mark16
NotMet16 BRA NextPoint16
Mark16  
        CMPI #100,D4
        BEQ PreDecrementMode16
        SUBI #8,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        BRA NextPoint16
PreDecrementMode16 JSR MOVEM_PreDecrement_Rev
NextPoint16
        RTS 
        

*********************************************************************************
* Method Name: CallDPrintNumber
* Description: Loads the "D" prefix of a data register into the string buffer. As well as append the hex number in D1 in Ascii format. 
*
* Calling Convention: None
*
* Preconditions & Method Input:
*   None
*
* Postconditions & Output:
*   Appends to string buffer the ascii character "D" followed by the ascii converted hex value in D1.
*
*  A2 holds the address of the variable string holding the ascii char we want (i.e. "D")
*  D3 holds the width of the ascii converted hex value to be appended to the string buffer
*  D5 holds the value that will be moved to D1 to be converted from hex to ascii and appended to the buffer
*  D1 holds the hex value that will be converted to ascii and appended to the string buffer
*********************************************************************************  
CallDPrintNumber
        LEA Data_Register,A2
        JSR Start_String_Appending
        MOVE D5,D1
        MOVE #0,D3
        JSR Add_Hex_String_To_Buffer
        RTS
        
        
*********************************************************************************
* Method Name: CallAPrintNumber
* Description: Loads the "A" prefix of a data register into the string buffer. As well as append the hex number in D1 in Ascii format. 
*
* Calling Convention: None
*
* Preconditions & Method Input:
*   None
*
* Postconditions & Output:
*   Appends to string buffer the ascii character "A" followed by the ascii converted hex value in D1.
*
*  A2 holds the address of the variable string holding the ascii char we want (i.e. "A")
*  D3 holds the width of the ascii converted hex value to be appended to the string buffer
*  D5 holds the value that will be moved to D1 to be converted from hex to ascii and appended to the buffer
*  D1 holds the hex value that will be converted to ascii and appended to the string buffer
********************************************************************************* 
CallAPrintNumber
        LEA Address_Register,A2
        JSR Start_String_Appending
        MOVE D5,D1
        MOVE #0,D3
        JSR Add_Hex_String_To_Buffer
        RTS

*********************************************************************************
* Method Name: Start_Move_Disassembly
* Description: Begins processing of the decoding of a standard MOVE instruction. Can branch to processing a MOVEA instruction disassembling label
*              if condition for bits passes. Appropriate ascii chars will then be as into the string buffer, call the "DestAddressingModeDetermine" 
*              function to determine the effective addresses, and print the appropriate string represented assembly language MOVE instruction, or MOVEA if
*              determined.
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   Is called by the "start_Disassembly" function after correct opcode fields matching. A4 references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent to opcode word MOVE via "Start_String_Appending" and "TrapTask13" call.
*
*  A2 holds the address of the variable string holding the ascii char we want (i.e. "MOVE", or "MOVEA", or ".L ",".W ",".B ")
*  A3 acts as a flag for DestAdressingModeDetermine for operation size (1: byte, 2: word, 3: long)
*  D7 holds the current instruction opcode word
*  D3 holds a copy of the current instruction opcode word for allowing bit mask manipulation without losing D7 data (helps for operation size determination)
*  D5 holds the shift value that is used to shift values in data register with shift count greater than 8
*  D2 stores a flag that tells "DestAddressingModeDetermine" which effective address bits to process (1: 0-5 bits, 2: 6-11 bits)
********************************************************************************* 
Start_Move_Disassembly
        JSR Move_operation   * If D3 is greater than or equal to 0, start the "MOVE" dissassembling
        ADDA D0,A4
        JSR TrapTask13
        BRA start_Disassembly

Move_Registers REG D3,D2,A1 * set of register to be saved and restored after the function ends (earlier draft, probably needed but not sure which registers need saving, and which can be discarded)
Move_operation:
        MOVE.L D7,D3
        ANDI.L #Move_Destination_Mode,D3
        MOVE #6,D5
        LSR.L D5,D3
        CMPI.B #1,D3
        BEQ Move_Address
Standard_Move     
        LEA Move_op, A2 * loads address of "MOVE" op string to A2 buffer
        JSR Start_String_Appending 
        BRA Subtype_Decided
Move_Address
        LEA MoveA_op,A2 * loads address of "MOVEA" op string to A2 buffer
        JSR Start_String_Appending
Subtype_Decided
        MOVE.L D7,D3    * Move converted hex value to D3, again
        ANDI.L #$3000, D3 * compare second two bytes of hex value to check the size of the operation (byte, word, long)
        MOVE #12,D5     * prepare shifting by the value 28 again, for least significant repositioning of size field
        LSR.L D5,D3     * shift the bits in D3 by value in D5 (28)
        CMPI.B #3,D3    * statement checks if size is word
        BEQ Word_Operation * executes if true
        CMPI.B #1,D3    * CMPI statement checks if size if byte
        BEQ Byte_Operation * executes if true
        CMPI.B #2,D3    * CMPI statement checks if size is long
        BEQ Long_Operation * executes if true
        BRA Error_Mode
       
* function prints out byte modifier (.B) 
Byte_Operation: 
        LEA Byte_Size,A2
        *TRAP #15
        MOVE #4,D3
        JSR Start_String_Appending
        MOVE #1,A3
        BRA Size_Confirmed

* function prints out word modifier (.W)
Word_Operation:
        LEA Word_Size,A2
        *TRAP #15
        MOVE #12,D3
        JSR Start_String_Appending
        MOVE #2,A3
        BRA Size_Confirmed
        
* function prints out long modifier (.L)
Long_Operation:
        LEA Long_Size,A2
        *TRAP #15
        MOVE #28,D3
        JSR Start_String_Appending
        MOVE #3,A3
        BRA Size_Confirmed

* function prints out the specific register that is specified by the opcode word (uses flags to indicate which field to process)
* D5 is holding the #of bits to be shifted right
R_Destination:
        MOVEM.L Move_Registers,-(SP)
        MOVE.L D7,D3
        CMPI.B #1,D2
        BEQ GetDestinationReg
        
GetSourceReg                                    * for Standard Move instruction
        ANDI.L #Move_Source_Register,D3
        BRA After_Decision
        
GetDestinationReg
        ANDI.L #Move_Destination_Register,D3 * for standard Move instruction
        MOVE #9,D5
        LSR.L D5,D3
        
After_Decision 
        JSR Decision_Register * check if D4 is 1 to confirm if effective address involves address register
        MOVE D3,D1    * move determined register number into D1
        MOVE #0,D3
        JSR Add_Hex_String_To_Buffer
        MOVEM.L (SP)+,Move_Registers
        RTS           * return to stack
        
* calculates the register number for the opcode (can function independently from the above function but is also accomplished in functionality by the above function, this was necessary for one of the addressing modes)
CalculateRegisterNum:
    MOVE.L D7,D3
    CMPI.B #1,D2
    BEQ Destination_Calculation
    
Source_Calculation
    ANDI.L #Move_Source_Register,D3
    RTS
Destination_Calculation    
    ANDI.L #Move_Destination_Register,D3
    MOVE #9, D5
    LSR.L D5,D3
    RTS

Decision_Register:
    CMPI.L #1,D4
    BEQ Address_Reg
    BRA Data_Reg
    
Data_Reg 
    JSR Print_Data_Register
    BRA END
    
Address_Reg 
    JSR Print_Address_Register
    
END 
    CLR.L D4
    RTS

* called when size of operation is printed, calls the DesAddressingModeDetermine
* function, which prints out the destination effective address
Size_Confirmed:
    CLR.L D2
    JSR DestAddressingModeDetermine
    LEA Comma,A2
    JSR Start_String_Appending
    MOVE.B #1,D2  * set flag to indicate the processing of destination operand (tells the function to process leftmost effective address)
    MOVE.B #60,D6 * generalized flag for destination addresses (for the purposes of ruling out immediate data as destination)
    JSR DestAddressingModeDetermine
    CLR D6
    RTS
        
end_Program:
    STOP #2700
    **************************************************
    *Your disassembler code goes here
    **************************************************
    
    ;Open config.cfg (trap subtasks 50-59) (this is an IO responsibility if 3 team members)
    ;load start and end address as longs
    
    ;loop from start to end, printing out the instruction or DATA if not recognized 
    ;   use my method below (printStringToFileAndConsole) to print out the individual instruction (or DATA)

    SIMHALT

*********************************************************************************
* Method Name: NOP_Operation
* Description: call this method from your code above; see the examples above on
*   how to call methods and use them profusely as you build your final project
*
* Preconditions:  The value of the hex instruction is in D3
* Postconditions: Loads the effective address of the "NOP" op string, and calls TrapTask14 
*                 to print it out. Branches to end of program afterwards.
*********************************************************************************
NOP_Operation:
    LEA NOP_op,A2
    JSR Start_String_Appending
    JSR TrapTask13
    ADDA #2,A4
    BRA start_Disassembly
    
*********************************************************************************
* Method Name: RTS_Operation
* Description: call this method from your code above; see the examples above on
*   how to call methods and use them profusely as you build your final project
*
* Preconditions:  The value of the hex instruction is in D3
* Postconditions: Loads the effective address of the "RTS" op string, and calls TrapTask14 
*                 to print it out. Branches to end of program afterwards.
*********************************************************************************
RTS_Operation:
    LEA RTS_op,A2
    JSR Start_String_Appending
    JSR TrapTask13
    ADDA #2,A4
    BRA start_Disassembly
    
*********************************************************************************
* Method Name: DestAddressingModeDetermine
* Description: Does the processing of decoding effective addressing. Will take one of the 6 bit effective address fields and decode them into one of the 
*              supported addressing modes (Data Register Direct, Address Register Direct, Address Register Indirect (ARI), ARI PostIncrement, ARI PreDecrement). 
*              If none are decoded go to error and print "XXXXXXXX DATA YYYY". Appropriate ascii chars in accordance with the addressing mode will then be 
*              added into the string buffer.
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   Is called by any specialized operation disassembling function after specifying which addressing field to process with D2 flag (1: 6-11 bits, 2:0-5 bits). A4 
*   references the current instruction opcode word, as well as D7.
*
* Postconditions & Output:
*   Appends to string buffer the correct assembly language equivalent of the effective addressing mode decoded.
*
*  A2 holds the address of the variable string holding the ascii char we want (i.e. "(",")","-","+","D","A", etc)
*  A3 acts as a flag for DestAdressingModeDetermine for operation size (1: byte, 2: word, 3: long)
*  D7 holds the current instruction opcode word
*  D3 holds a copy of the current instruction opcode word for allowing bit mask manipulation without losing D7 data (helps for operation size determination),
*  also is used for determining ascii hex width for buffer, and as flag for telling the functions called for absolute addressing that a long operation
*  is being done as opposed to word, can also help distinguish difference between word operands addressing modes (absolute addressing, immediate addressing)
*  D5 holds the shift value that is used to shift values in data register with shift count greater than 8
*  D2 stores a flag that tells the function which effective address bits to process (1: 6-11 bits, 2: 0-5 bits)
*  D4 holds a flag that tell the function whether the particular operation function that called it allows the particular addressing mode that's been determined.
*  If not, it can go to error (label "Error Mode")
********************************************************************************* 
Addressing_Regs REG D1,D4,D5,D6
DestAddressingModeDetermine:
        MOVEM Addressing_Regs,-(SP)
        MOVE.L D7,D3
        CMPI.B #1,D2
        BNE source_Operand
destination_Operand 
        ANDI.L #Move_Destination_Mode,D3
        MOVE #6,D5
        LSR.L D5,D3
        BRA decided_Operand
source_Operand
        ANDI.L #Move_Source_Mode,D3
        MOVE #3,D5
        LSR.L D5,D3
decided_Operand
        CMPI.B #0,D3
        BEQ Data_Reg_Direct
        CMPI.B #1,D3
        BEQ Address_Reg_Direct
   *     JSR R_Destination * handles Data register direct
        CMPI.B #2,D3 * handles Address register indirect
        BEQ Address_Reg_Indirect
        CMPI.B #3,D3
        BEQ Address_Reg_Indir_Post_Inc * handles Address register indirect with post increment
        CMPI.B #4,D3
        BEQ Address_Reg_Indir_Pre_Dec * handles Address register indirect with pre decrement
        CMPI.B #7,D3
        BEQ Absolute_Addressing
        BRA Error_Mode
 
Address_Reg_Direct       
      * CMPI.B #1,D2
      * BEQ Error_Mode
       CMPI #15,D4            * checks if operation is BCLR
       BEQ BCLR_A
       CMPI #98,D4
       BEQ BCLR_A
       CMPI #84,D4  * indicates that the operation is a byte size SUBQ operation or a MULS.W operation
       BEQ BCLR_A
       CMPI #99,D4
       BEQ BCLR_A
       CMPI #404,D4
       BEQ BCLR_A
       CMPI #92,D4
       BEQ BCLR_A
       CMPI #50,D4
       BEQ BCLR_A
       CMPI #55,D4
       BEQ BCLR_A
       CMPI #400,D4
       BEQ BCLR_A
       CMPI #500,D4 * checks for NEG Operation
       BEQ BCLR_A
       CMPI #27,D4
       BEQ BCLR_A
       CMPI #31,D4
       BEQ BCLR_A
After_BCLR_Decision
MOVEM_Check
       CMPI #66,D4 * indicates a register to memory transfer for a MOVEM instruction
       BEQ Error_Mode
       CMPI #65,D4 * indicates a memory to register transfer for a MOVEM instruction
       BEQ Error_Mode
       MOVE #1,D4
       JSR R_Destination
       CLR.L D4
       BRA END_EFF_ADD
BCLR_A                   * also indicates other operations that forbid this effective address in certain positions (source or destination)
       BRA Error_Mode
       BRA END_EFF_ADD
       
Address_Reg_Indirect
        CMPI #15,D4
        BNE After_AReg_In
BCLR_ARegIn
        LEA Byte_Size,A2
        JSR Start_String_Appending
        JSR BCLR_Data_Register_Print
        JSR Add_Comma       
After_AReg_In
        MOVE #1,D4
        JSR OpenParen
        JSR R_Destination
        CLR.L D4
        JSR CloseParen
        BRA END_EFF_ADD
            
Address_Reg_Indir_Post_Inc
        CMPI #15,D4
        BNE After_AReg_InPost
BCLR_ARegInPost
        LEA Byte_Size,A2
        JSR Start_String_Appending
        JSR BCLR_Data_Register_Print
        JSR Add_Comma           
After_AReg_InPost
        CMPI #66,D4
        BEQ Error_Mode
        CMPI #55,D4
        BEQ Error_Mode
        CMPI #400,D4
        BEQ Error_Mode
        MOVE #1,D4
        JSR OpenParen
        JSR R_Destination
        JSR CloseParen
        JSR AddPostIncrement
        CLR.L D4
        BRA END_EFF_ADD

Address_Reg_Indir_Pre_Dec
        CMPI #15,D4
        BNE After_AReg_InPre
BCLR_ARegInPre
        LEA Byte_Size,A2
        JSR Start_String_Appending
        JSR BCLR_Data_Register_Print
        JSR Add_Comma       
After_AReg_InPre
        CMPI #65,D4
        BEQ Error_Mode
        CMPI #55,D4
        BEQ Error_Mode
        CMPI #400,D4
        BEQ Error_Mode
        MOVE #1,D4
        JSR AddPreDecrement
        JSR OpenParen
        JSR R_Destination
        JSR CloseParen
        BRA END_EFF_ADD
            
Absolute_Addressing
        CMPI #15,D4
        BNE After_Absolute
BCLR_Absolute
        LEA Byte_Size,A2
        JSR Start_String_Appending
        JSR BCLR_Data_Register_Print
        JSR Add_Comma
After_Absolute
        JSR CalculateRegisterNum
        CMPI.B #4,D3
        BEQ Immediate_Addressing
        CMPI.B #0,D3
        BEQ Absolute_Address_Word
        CMPI.B #1,D3
        BEQ Set_D3_For_Long_Operand_Flag
        BRA END_EFF_ADD

Set_D3_For_Long_Operand_Flag
        MOVE #5,D3

Absolute_Address_Word
        JSR AddHexCash
        JSR IsolateSecondInstrWord
        MOVE.L D6,D1
        CMPI #400,D4
        BNE After_LEA_Decision
Force_LEA_Long
        MOVE #28,D3
After_LEA_Decision
        CMPI #500,D4
        BNE AfterNegMoveDecision
MoveSizeIdentifier
        MOVE D0,D3
AfterNegMoveDecision
        MOVE #28,D3
        JSR Add_Hex_String_To_Buffer
        BRA END_EFF_ADD

Data_Reg_Direct
        CMPI #15,D4
        BNE MOVEM_Proc
BCLR_Proc
        LEA Long_Size,A2
        JSR Start_String_Appending
        JSR BCLR_Data_Register_Print
        JSR Add_Comma
        BRA After_Op_Decided
MOVEM_Proc                      * also checks if its anything other than a BCLR instruction
        CMPI #21,D4
        BEQ After_op_Decided
        CMPI #31,D4
        BEQ Error_Mode
        CMPI #92,D4
        BEQ Error_Mode
        CMPI #404,D4
        BEQ Error_Mode
        CMPI #66,D4
        BEQ Error_Mode
        CMPI #65,D4
        BEQ Error_Mode
        CMPI #55,D4
        BEQ Error_Mode
        CMPI #400,D4
        BEQ Error_Mode
After_Op_Decided
        JSR R_Destination
        BRA END_EFF_ADD
    
Immediate_Addressing
        CMPI #60,D6 * Generalized check for destination operand processing
        BEQ Error_Mode
        CMPI #66,D4
        BEQ Error_Mode
        CMPI #404,D4
        BEQ Error_Mode
        CMPI #92,D4
        BEQ Error_Mode
        CMPI #99,D4
        BEQ Error_Mode
        CMPI #65,D4
        BEQ Error_Mode
        CMPI #27,D4
        BEQ Error_Mode
        CMPI #31,D4
        BEQ Error_Mode
        CMPI.B #1,D2
        BEQ Error_Mode
        JSR AddPoundSign
        JSR AddHexCash
        JSR IsolateInstrOperands
        JSR Add_Hex_String_To_Buffer
        BRA END_EFF_ADD

Error_Mode        
        JSR Error_Subroutine
        MOVEM (SP)+,Addressing_Regs
        CLR.L D6
        ADDA D0,A4
        BRA start_Disassembly
        
END_EFF_ADD
        MOVEM (SP)+,Addressing_Regs     
        RTS
*********************************************************************************
* Method Name: TrapTask13
* Description: Creates a file if none exists, and appends bytes to that file
*   while also echoing the written bytes to the screen.  You shouldn't need to
*   change this code.
*
* Calling Convention: Callee-Saved 
*
* Preconditions & Method Input:
*   A1 points to the null-terminated buffer to write (newline will be added for you)
*
* Postconditions & Output:
*   ALL files that were previously open will be CLOSED (FileIDs will be invalid)
*   See 'Output.txt' in directory for the results, also piped to the console
*
*
*  A2 holds a pointer to null terminated string to write (input)
*  A3 points to the null-terminated file name
*  D3 holds the number of bytes already in the file to write
*
*  D5 holds number of bytes to write
********************************************************************************
toSave REG D0-D5/A2-A3
TrapTask13:
    *******************************************************************
    * Method initialization, regsiter spilling, parameter saving, etc.
    *******************************************************************
    MOVEM.L toSave, -(SP)   ;  Callee-Saved, so save and restore     
      
    MOVEA.L A1, A2 ; save this buffer to write
    LEA outFilename, A3  ; save this for later, too
      
    move #50,d0   
    trap #15 ; close all files, suggested to begin any IO 
    *******************************************************************
    * End Method Init
    *******************************************************************

    ******************************************************************************************
    * Calculate the number of bytes to write by searching for the null in the target buffer A0
    ******************************************************************************************
    CLR.L D5 *D5 is now the number of bytes to write
nullLoop:
    MOVE.B (A1)+, D0
    CMPI.B #0,D0  * compare to null
    BEQ findNullLoopDone
    ADDI.W #1, D5
    BRA nullLoop
    
findNullLoopDone:
    MOVEA.L A3, A1 * reset A1 so it points to the file to write to (to open, next)
    
    ;check if file exists, and open with task 51 if so, otherwise 52
    ;(precondition here is A1 points to the null-terminated filename )
    MOVE.B #51, D0      ;open file (task 51 is existing, 52 is new)
    trap #15
      
    if.w D0 <NE> #0 then.s         ; if file error (404, not found)
        MOVE.B #52, D0             ; open new file (52 is new)
        trap #15
    endi
    
    ********************************************************************************************************* 
    * Seek to END of FILE by counting the number of bytes, closing, reopening, then seeking.
    *    (first, count number of bytes already in the file to obtain seek position)
    *********************************************************************************************************
    Clr.L D3   ;TODO: reg save, D3 is now our count of bytes read
    MOVE.L #1, D2 ; read one byte at a time
    LEA byteRead, A1
    
countLoop:
    MOVE.B #53, D0 ; try to read one byte (TODO: move out of loop)
    trap #15
    
    CMPI.W #1,D0  ;1 == EOF
    BEQ countDone
    ADDI #1, D3
    BRA countLoop
    
countDone:    
    * close this file
     move #56,d0  
     trap #15 
     
     * reopen the target file
     MOVE.L A3,A1
     MOVE #51, D0
     trap #15
     
    * seek to right position, then continue with writing
    MOVE.L D3, D2 ; move the number of bytes found in the file to D2
    MOVE #55, D0  ; position file task
    trap #15

    ******************************************************************************
    * Actually write the buffer to the file, after caculating the number of bytes 
    *  to write and after seeking to the right location in the file for append
    ******************************************************************************

    MOVE.L D5, D2 ; restore this for the actually writing the buffer 
    ; assumes A0 hasnt changed since handed to this method      
    MOVEA.L A2, A1 ; load the address of the buffer we want to write to disk
    ; assumes file ID is still stored in D1.L  
    MOVE.B #54, D0 ; subtask 54 is write to open file (append, or?), assumes D2 holds # of bytes
    trap #15

    ; add a newline to the file output
    LEA NEWLINE, A1
    MOVE.B #54, D0 
    MOVE.B #2,D2  ; kills # of bytes to write from input param
    trap #15
    
    ; finally, close only this file
    MOVE.B #56, D0 ; close file task
    trap #15
  
    ; report to screen
    MOVEA.L A2, A1 ; load the address of the buffer we want to write to disk & screen
    MOVE.B #13, D0
    trap #15
      
    ; restore context
    MOVEM.L (SP)+, toSave
    
    RTS
    
    
*----------------------------------------------------------------------------------
* Method Name: AsciiToHex
* Written by : Berger, Modified by Nash
* Date       : 3/1/2019
* Description: Converts chars '0'-'9' and 'a'-'f' to 0-9,a-F
*              Transforms/unpacks 8 chars (8b each) pointed to by A1 into 
*              its (4b each) equivalent hex value 
*  
*  Preconditions & Input
*       A1 (input) points to a memory buffer holding 8 ascii chars (not null-terminated) 
*       This function calls another function (strip_ascii)
*
*  Postconditions & Output
*       D7 (output) holds the converted value 
*       Caller-Saved : D0 is temp, D6 is a loop var
*----------------------------------------------------------------------------------
AsciiToHexRegList REG D0,D6
AsciiToHex     
    MOVEM.L asciiToHexRegList, -(SP)  *save context
    CLR.L D7 * clear our return value
    MOVE.L #8, D6 ; and set up our loop counter

chrLoop
    MOVE.B (A1)+,D0 * Get the first byte
    jsr strip_ascii * Get rid of the ascii code    
    OR.W D0,D7 * Load the bits into D7
    
    subI.B #1,D6  *decrement our loop variable
    BEQ chrDone   *skip shifting if we are done
    
    ASL.L #4,D7 * shift left 4 bits to prepare for next byte
    BRA chrLoop

chrDone
    MOVEM.L (SP)+,asciiToHexRegList 
    RTS


**********************************************************************
* SUBROUTINE: strip_ascii
* remove the ascii code from the digits 0-9,a-f, or A-F
* Input Parameters: <D0> = ascii code
*
* Return parameters: D0.B = number 0...F, returned as 00...0F
* Registers used internally: D0
* Assumptions: D0 contains $30-$39, $41-$46 or $61-66
*
***********************************************************************
strip_ascii
      CMP.B #$39,D0 * Is it in range of 0-9?
      BLE sub30 * Its a number
      CMP.B #$46,D0 * Is is A...F?
      BLE sub37 * Its A...F
      SUB.B #$57,D0 * Its a...f
      BRA ret_sa * Go back
sub37 SUB.B #$37,D0 * Strip 37
      BRA ret_sa * Go back
sub30 SUB.B #$30,D0 * Strip 30
ret_sa RTS * Go back
    
* loads an open parenthesis into the string buffer
OpenParen:
    LEA Open_Paren,A2
    JSR Start_String_Appending
    RTS
    
* loads a close parenthesis into the string buffer
CloseParen:
    LEA Close_Paren,A2
    JSR Start_String_Appending
    RTS
    
* loads a plus sign into the string buffer
AddPostIncrement:
    LEA Plus,A2
    JSR Start_String_Appending
    RTS
    
* loads a minus sign into the string buffer
AddPreDecrement:
    LEA Minus,A2
    JSR Start_String_Appending
    RTS
    
* loads a hex cash sign into the string buffer
AddHexCash:
    LEA HexCash,A2
    JSR Start_String_Appending
    RTS

* loads a pound sign into the string buffer
AddPoundSign:
    LEA Pound,A2
    JSR Start_String_Appending
    RTS

* loads a newline character into the string buffer
AddNewLine:
    LEA NEWLINE,A2
    JSR Start_String_Appending
    RTS
    
* loads the value in A2 into the string buffer
DisplayInHex:
    JSR Start_String_Appending
    RTS
    
*********************************************************************************
* Method Name: IsolateSecondInstrWord
* Description: Processes the absolute addressing effective address mode. And places the operand words in D1.
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   Is called by a function initiating an absolute addressing mode. A4 is pointing to the current instruction opcode word. D0 is holding the exact displacement count
*   of moves forward from the opcode made over the course of the current instruction (over the course of the same A4 value). D3 is flagged with whatever value
*   is needed to specify the correct word length intended (D3 needs to be 5 for a long absolute address operation to be initiated, anything else is word)
*
* Postconditions & Output:
*   Places the completely processed operand words into D1, resets the value of A4 to what it was when the function was called. A hex to ascii width specifier in
*   D3
*
*  A6 holds a pointer to where A4 is pointing at, but is allowed to be added to in accordance with what operands need to be fetched.
*  D0 holds the counter of displacements made from the current value of A4 (and thus the value that needs to be added to A4 at the end of the current instruction
*  , unless an error ("XXXXXXXX DATA YYYY") is reached)
*  A4 the pointer to the current instruction opcode word
*  D4 acts as a flag that specifies certain kinds of instructions that need to be processed differently
*  D3 acts as a flag telling the function to either do a long operation (D3 == 5), or not (D3 == anything else), D3 also acts as a hex to ascii width specifier
*  as an output value of the function
*  D2 is a holder for a shift count value for a data register shift, since the value required is greater than #8, this is necessary
*  D6 holds the full operand word to be returned by the function (is moved to D1 later on by the end of the function)
********************************************************************************
IsolateSecondInstrWord:
    MOVEM D2,-(SP)
    *MOVE D7,D6
    MOVE.L A4,A6
    CMPI #65,D4
    BEQ AddingForMoveM
    CMPI #66,D4
    BEQ AddingForMoveM
AddingForNonMoveM    * also for BCLR Dynamic
    ADDA D0,A6
    ADD #2,D0
    BRA AfterMoveMDecision
AddingForMoveM
    ADDA #4,A6
    ADDI #4,D0
AfterMoveMDecision
    CLR.L D6
    MOVE (A6),D6
    CMPI #5,D3
    BNE  Just_A_Word
    MOVE.L A4,A6
    ADD D0,A6
    CMPI #65,D4
    BEQ After_Potential_D0_Increment
    CMPI #66,D4
    BEQ After_Potential_D0_Increment
    ADDI #2,D0
After_Potential_D0_Increment
    MOVE #16,D2
    LSL.L D2,D6
    MOVE.W (A6),D6
    MOVE #28,D3
    MOVE.L D6,D1
    BRA Fin_Isol
Just_A_Word
    MOVE #12,D3
    MOVE.W D6,D1
    CMPI #65,D4
    BEQ MOVEM_Subtract
    CMPI #66,D4
    BEQ MOVEM_Subtract
    BRA Fin_Isol
MOVEM_Subtract
    SUB #2,D0
Fin_Isol
    MOVE.L A4,A6
    MOVEM (SP)+,D2
    RTS   
    
* same as above, but for Immediate Addressing only (except Bcc which uses this with displacement)
IsolateInstrOperands:
    MOVEM D2,-(SP)
    *MOVE D7,D6
    ADDA #2,A6
    ADDI #2,D0
    CMPA #1,A3
    BEQ IsolateByte
    CMPA #2,A3
    BEQ IsolateWord
    CMPA #3,A3
    BEQ IsolateLong
    BRA Fin_Isol2
IsolateByte
    MOVE.W (A6),D6
    ANDI #$00FF,D6
    MOVE.W D6,D1
    ANDI #$00FF,D1
    MOVE #4,D3
    BRA Fin_Isol2
IsolateWord
    MOVE.W (A6),D6
    MOVE.W D6,D1
    MOVE #12,D3
    BRA Fin_Isol2
IsolateLong
    CLR.L D6
    MOVE (A6),D6
    MOVE #16,D2
    LSL.L D2,D6
    ADDA #2,A6
    ADDI #2,D0
    MOVE.W (A6),D6
    MOVE.L D6,D1
    MOVE #28,D3
Fin_Isol2
    MOVEM (SP)+,D2
    RTS   
    
** loads an data register letter "D", into the string buffer
Print_Data_Register:
    LEA Data_Register,A2
    JSR Start_String_Appending
    RTS
    
** loads an address register letter "A" into the string buffer
Print_Address_Register:
    LEA Address_Register,A2
    JSR Start_String_Appending
    RTS
    
** place the contents of D7 into D3
Place_D7_in_D3
    MOVE.L D7,D3
    RTS
    
** increment the A4 disassembler memory region pointer
Increment_Function
    ADDI #2,D0
    RTS
    
** print the address register specified by the calling MOVEM disassembling function
MOVEM_PreDecrement
        MOVE #7,D6
        SUB D5,D6
        MOVE D6,D5
        JSR CallAPrintNumber
        JSR Add_Slash
        RTS

** print the data register specified by the calling MOVEM disassembling function
MOVEM_PreDecrement_Rev
        SUB D2,D5
        JSR CallDPrintNumber
        JSR Add_Slash
        RTS

** loads a comma into the string buffer
Add_Comma
        LEA Comma,A2
        JSR Start_String_Appending
        RTS
        
** loads an empty space into the string buffer
Add_Space
        LEA Empty_Space,A2
        JSR Start_String_Appending
        RTS
        
** loads a slash into the string buffer
Add_Slash
        LEA Slash,A2
        JSR Start_String_Appending
        RTS

** loads a "DATA" string into the string buffer
Print_Error
        LEA Print_Data_Error,A2
        JSR Start_String_Appending
        RTS

** isolates a register of an LSd instruction opcode
LSd_Register_Mask_Isolate
        MOVEM D5,-(SP)
        ANDI #$0E00,D3
        MOVE #9,D5
        LSR.L D5,D3
        MOVEM (SP)+,D5
        RTS

** loads a byte specifier into the string buffer
Byte_Print
        LEA Byte_Size,A2
        JSR Start_String_Appending
        RTS    
    
** loads a word specifier into the string buffer
Word_Print
        LEA Word_Size,A2
        JSR Start_String_Appending
        RTS

** loads a long specifier into the string buffer
Long_Print
        LEA Long_Size,A2
        JSR Start_String_Appending
        RTS


*********************************************************************************
* Method Name: Start_String_Appending
* Description: Takes the null-terminated string at pointed to by A2, and appends it to the string buffer, which is pointed to by A5. Continues to loop
*              through string pointed to by A2 until null-character is detected. 
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   A2 is pointing to the head of the string that needs to be appended to the string buffer. A5 is pointing to the head of the string buffer.
*
* Postconditions & Output:
*   A5 has the string pointed to by A2 appended to its string buffer. And A1 also is made to point to the head of the string buffer block.
*
*  A5 points to the string buffer
*  A2 points to the string to be appended to the buffer
*  A1 points to the head of the string buffer as a return value of the function
********************************************************************************
AppendingRegs   REG     A2,D5
Start_String_Appending
    MOVEM AppendingRegs,-(SP)
    
String_Appending_Loop
    CMPI.B #$00,(A2)
    BEQ EndStringLoop
    MOVE.B (A2)+,(A5)+
    
AddNullToStringBuffer
    MOVE.B #$00,(A5)
    BRA String_Appending_Loop
    
EndStringLoop
    LEA String_Buffer_Block,A1
    MOVEM (SP)+,AppendingRegs
    RTS
    
  
*********************************************************************************
* Method Name: Clear_String_Buffer
* Description: Clears the contents of the string buffer to prepare for the next instruction to be read, or to rewrite the buffer for printing an
*   error string ("XXXXXXXX DATA YYYY").
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   None
*
* Postconditions & Output:
*   The string buffer block is left with no elements (data) in its contents.
*
*  A1 points to the string buffer block
*  D5 stores a counter for the loop to iterate through as many blocks as there exist in the string buffer block (in this case, 20)
********************************************************************************  
Clear_String_Buffer
    MOVEM AppendingRegs,-(SP)
    LEA String_Buffer_Block,A1
    MOVE #20,D5  
ClearStringBufferLoop
    CMPI #0,D5
    BEQ EmptiedBuffer
    MOVE.B #$FF,(A1)
    ADD #1,A1
    SUB #1,D5
    BRA ClearStringBufferLoop
EmptiedBuffer
    MOVE.B #$FF,(A1)
    MOVEM (SP)+,AppendingRegs
    RTS


*********************************************************************************
* Method Name: Add_Hex_String_To_Buffer
* Description: Takes the hex value stored in D1, and converts it from hex to ascii via the label inside called "HexToAscii", then appends this value to the string
* buffer block by using "Start_String_Appending".
*
* Calling Convention: Caller-Saved
*
* Preconditions & Method Input:
*   The value to be converted to ascii and appended to the string buffer block is stored in D1.
*
* Postconditions & Output:
*   The ascii converted value of the hex value stored in D1 is appended to the string buffer block. The value stored in D3 represents the 
*   the width of the ascii hex value intended (4 gives a byte, 12 gives a word, 28 gives a long).
*
*  A2 is the register that Start_String_Appending appends to the string buffer block, so it is where the converted hex value is appended.
*  D3 holds the width of the ascii hex value intended
*  D6 holds value to be converted (moved from D1) and is manipulated to convert a nibble at a time and place them in memory space pointed to by A2
********************************************************************************  
Add_Hex_String_To_Buffer
    MOVE #$6000,A2
    MOVEM D1/D2/D3/D6/A2,-(SP)
    JSR HexToAscii
    MOVEM (SP)+,D1/D2/D3/D6/A2
    JSR Start_String_Appending
    RTS

HexToAscii
    CMPI #$0,D3
    BLT EndConversion
    MOVE.L D1,D6
    LSR.L D3,D6
    ANDI.L #$0000000F,D6
    MOVE.B D6,(A2)
    CMPI.B #10,(A2)
    BLT AddForNumeric
AddForLetter
    ADDI.B #55,(A2)+
    BRA After_Addition
AddForNumeric
    ADDI.B #48,(A2)+
After_Addition
    SUBI #4,D3
    BRA HexToAscii
EndConversion
    MOVE.B #$00,(A2)
    RTS
   
*********************************************************************************
* Method Name: Error_Subroutine
* Description: Clears the string buffer to prepare for an error and to load the string buffer with the error string "XXXXXXXX DATA YYYY",
*              where X is the memory address of the instruction that resulted in an error in processing, and the Y is the data stored at the
*              memory location that initiated the error. This is then printed to the console and out to the file "output.txt" via the
*              TrapTask13 function.
*
* Calling Convention: None
*
* Preconditions & Method Input:
*   A undetermined opcode or addressing mode was detected. A0 is pointing at the same location as A4 (and thus at the same address as the instruction
*   that initiated the error)
*
* Postconditions & Output:
*   The string buffer block is erased and replaced with the error data string from above, and printed to console and "output.txt" file.
*
*  A5 holds the head of the string buffer block
*  A0 points to the current instruction opcode word and moves its value to D1 for conversion to hex to be prepared via "Add_Hex_String_To_Buffer" for
*  proper formatting of error data string as above.
*  D3 specifies the intended width of the ascii converted hex value (4: byte, 12: word, 28: long)
*  A2 points to where the "DATA" string is loaded in memory, to prepare for appending to the string buffer via "Start_String_Appending"
*  D7 holds the current instruction opcode word
*  D1 holds the value that is hex converted to ascii via "Add_Hex_String_To_Buffer" (which has a precondition that its converting variable is placed in D1)
*  D0 stores the amount by which A4 will be incremented after the completion of this function
********************************************************************************
Error_Subroutine
    JSR Clear_String_Buffer
    LEA String_Buffer_Block, A5
    MOVE.L A0,D1
    MOVE #28,D3    * flags the address of the current instruction that is placed before the "DATA" word as being long (8 hex characters)
    JSR Add_Hex_String_To_Buffer
    JSR Add_Space
    LEA Print_Data_Error,A2
    JSR Start_String_Appending
    JSR Add_Space
    MOVE.L D7,D1
    MOVE #12,D3   * flags the data at the address of the current instruction that is placed after the "DATA" word as being word (4 hex characters)
    JSR Add_Hex_String_To_Buffer
    JSR TrapTask13
    MOVE #2,D0
    RTS


*********************************************************************************
* Method Name: StoreAddressesFromConfig
* Description: Opens the file specified in the configFilename variable that is defined in the Variables section. Once the file has been opened, 
*              the method will load an uninitialized area of code 64 bits long, to account for the ASCII representation of a long. It will grab 
*              the next 8 ASCII chars, and then covert those chars into Hex and place it in the region of memory corresponding to the variable 
*              Start_Address. It skips over the next two ASCII chars, and then repeat the process for the 8 ASCII chars that represent the 
*              End_Address variable. After this it closes the file
* 
* Calling Convention: Caller-Save
*
* Preconditions & Method Input:
*   configFilename is initialized to a file name
*   File format of the configFilename file is
*    <Long_StartAddress>\CR\LF
*    <Long_EndAddress>\CR\LF<EOF>
*
* Postconditions & Output:
*   Start_Address and End_Address contain the memory address defined in the configFileName file.
*
*  D0 holds the trap task that will be used for File IO
*  A1 hold the file name for the file that you want to open, as well as holds head of the string buffer for the ASCII to Hex coversion
*  D2 hold the number of bytes that the Trap Task will read from the file
********************************************************************************
ConfigRegList   REG D0/D2/A1

StoreAddressesFromConfig
    MOVEM.L ConfigRegList, -(SP)
    MOVE #50, D0
    TRAP #15

    MOVE #51, D0
    LEA configFilename, A1
    TRAP #15

    LEA AddrBuffer, A1
    MOVE.L #8, D2
    MOVE #53, D0
    TRAP #15


    JSR AsciiToHex
    MOVE.L D7, Start_Address

    CLR.L D7

    MOVE.L #2, D2
    MOVE #53, D0
    TRAP #15


    LEA AddrBuffer, A1
    MOVE.L #8, D2
    MOVE #53, D0
    TRAP #15

    JSR AsciiToHex
    MOVE.L D7, End_Address
    
    MOVE.B #56, D0
    TRAP #15

    MOVEM.L (SP)+,ConfigRegList
    RTS
       
* Required variables and constants go here for your Disassembler
CR                  EQU $0D
LF                  EQU $0A
NEWLINE             DC.B CR,LF,0
String_Buffer_Block DS.B 20
AddrBuffer          DS.L 2
MSG1                DC.B 'MOVE.L D4,D5',0
MSG2                DC.B 'ADD.B D0,D1',0
outFilename         DC.B 'Output.txt',0
configFilename      DC.B 'config.cfg',0
byteRead            DS.B 1
Start_Address       DS.L  1
End_Address         DS.L  1
Move_Destination_Register EQU $0E00
Move_Destination_Mode     EQU $01C0
Move_Source_Mode    EQU $0038
Move_Source_Register      EQU $0007
MoveM_Op_Code_Mask  EQU $FF80
Bit_Test_and_Clear_Mask EQU $F1C0
Bit_Test_and_Clear_Mask2 EQU $FFC0
JSR_Mask            EQU $FFC0
LEA_MULS_Mask       EQU $F1C0
NEG_BRA_Mask        EQU $FF00
Bcc_CMPI_Mask       EQU $F000
SubQ_Mask           EQU $F100
Isolate_Second_Word EQU $0000FFFF
Print_Data_Error    DC.B 'DATA',0
Move_op             DC.B 'MOVE',0
MoveA_op            DC.B 'MOVEA',0
MoveM_op            DC.B 'MOVEM',0
NOP_op              DC.B 'NOP',0
RTS_op              DC.B 'RTS',0
BCLR_op             DC.B 'BCLR',0
JSR_op              DC.B 'JSR ',0
LEA_op              DC.B 'LEA.L ',0
NEG_op              DC.B 'NEG',0
BRA_op              DC.B 'BRA',0
BCS_op              DC.B 'BCS',0
BGE_op              DC.B 'BGE',0
BLT_op              DC.B 'BLT',0
BVC_op              DC.B 'BVC',0
CMP_op              DC.B 'CMP',0
CMPI_op             DC.B 'CMPI',0
LSL_op              DC.B 'LSL',0
LSR_op              DC.B 'LSR',0
ASL_op              DC.B 'ASL',0
ASR_op              DC.B 'ASR',0
ROL_op              DC.B 'ROL',0
ROR_op              DC.B 'ROR',0
EOR_op              DC.B 'EOR',0
OR_op               DC.B 'OR',0
ORI_op              DC.B 'ORI',0
Add_op              DC.B 'ADD',0
ADDA_op             DC.B 'ADDA',0
SUB_op              DC.B 'SUB',0
SUBQ_op             DC.B 'SUBQ',0
MULS_op             DC.B 'MULS',0
DIVS_op             DC.B 'DIVS',0
Data_Register       DC.B 'D',0
Address_Register    DC.B 'A',0
Word_Size           DC.B '.W ',0
Byte_Size           DC.B '.B ',0
Long_Size           DC.B '.L ',0
Open_Paren          DC.B '(',0
Close_Paren         DC.B ')',0
Plus                DC.B '+',0
Minus               DC.B '-',0
HexCash             DC.B '$',0
Pound               DC.B '#',0
Comma               DC.B ',',0
Slash               DC.B '/',0
Empty_Space         DC.B ' ',0

   END    START        ; last line of source












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
