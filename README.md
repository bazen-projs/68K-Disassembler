Adam Deehring

Bazen Nega

**Suspicious Disassemblers - Disassembler Project** 

**Program Specification**

**Manual**

**What does it do?**

Our disassembler parses through one word at a time from memory, and breaks it down based on its unique field identifiers, whose locations vary amongst the many opcodes of the 68k. We systematically break down a word from each incrementing location in memory, checking the values of specific bits of that word, in order to determine what operation code it translates to. We branch to different subroutine often, as they will further break down the current word, and this is done once we have identified which operation code that the current word could represent. In the cases where the operation code is followed by a memory address or an immediate value, our program will account for those, and represent them correctly in its output.

As a means to print data, throughout the program, we continuously append the ASCII representations of the operation codes into a buffer in memory. This allows us to print the ASCII representation later on in the program, so that once we have successfully decoded the current field of the opcode, we append that representation into a string buffer and print it out to the user along with the rest of the instruction’s characters once the whole instruction has been decoded. This allows to systematically build our outputs, and when we have reached the end of a particular opcode, we print that string buffer using the TrapTask13 method. In the cases where we run into an opcode or effective address that isn’t supported, we immediate flush what is in the string buffer and fill it with “X DATA Y” where X is its location in memory and Y being the illegal opcode. 

**How do you use our Disassembler?**

`	`In order to use our program, your use case can be broken down into three different categories. These categories are:

1. When the data that you want to disassemble has already been loaded into the memory of the 68k (hard coded)
1. When the data that you want to disassemble is in a separate file
1. When the data that you want to disassemble is in a separate file and in a different directory

If the data is already in the memory of your 68k simulator (or Category 1), all you need to run our disassembler is to ensure that the config.cfg is present, and ensure that the first line contains ONLY the start address desired the disassembler to start at in hexadecimal format, and the second line contains ONLY the end address desired in the hexadecimal format. 

`	`If you want to load data into the memory of the 68k simulator (or Category 2), you must load that data in via the simulator by clicking the “Assemble Source File” button, and opening the test data file via the “Open Data” button under “File”.  And once again, a config.cfg file must be present in order for the disassembler to function properly. 

`	`If you want to load data into the memory of the 68k simulator from a file that is not your current directory (or Category 3), you must load that data in via the simulator by clicking the “Assemble Source File” button, and navigate to and open the test data file via the “Open Data” button under “File”. A config.cfg file must be present in that directory for the disassembler to function properly. 

Once you have assured that there is a config.cfg in the same directory as the data in which you are loading into the simulator, you should first check that the values in the config.cfg file are the correct start and end addresses. After checking them, all you need to do is to click Run in the simulator to use our disassembler.

`	`The program will output the derived opcodes into the output window of the 68k simulator, as well as output them into a output.txt file, that will be stored in the current directory if the data was preloaded, and the directory of the data that was loaded into memory if from a different location.



**Code Standards**

When programming our disassembler, we tried to abide by code standards. One standard was when we pushed our registers to memory, Callee-Saved was used in most cases  but there are cases where Caller-Saved was used, but this was seldom done. However, with our implementation, we do not rely heavily on pushing values to the stack, which is due to our heavy usage of flags to communicate information across our program and wanting the information coming into the subroutines to be used and altered on the way out. 

When disassembling a command, in order to pass information around about that particular command, we employed the use of Flag Registers, which are data registers that hold specific numbers to signal specific conditions to various functions. We use these quite profusely in our code. One of our flag registers was used to determine what operation code was calling our Effective Addressing subroutine, so that we had the ability to check for illegal addressing modes, allowing us to branch immediately to our error subroutine. Another flag register was used to determine if the bits that the subroutine should break down are for the least significant 6 bits (usually the source: 0-5), or the middle to higher 6 bits (usually the destination: 6-11) and another flag register determined whether the function was being called for a source Effective Address or a destination Effective Address, so whether it was in the format of Mode followed by Register or vise versa.

**Data Registers**

**D0** stores the number of bytes to add to the value of A4 (the instruction looper) at the end of the current instruction processing/decoding.

- It is also used as a temporary variable in TrapTask13, as a loop variable, and AsciiToHex, as the converted ASCII char. 

**D1** is primarily used for HexToAscii conversion. We place the number we want to be converted from Hex to ASCII into this register.  

**D2** is a flag register, which is used to determine whether we are dealing with bits 0-5 or 6-11 for effective addressing.

**D3** holds the hex value of the word we are currently process, but a version that we can manipulate in order to break down the word, without worrying about losing a copy of the current word. It also signals the size of the word to be appended to the buffer (i.e. whether the value in D1 should be formatted as a byte, word, long, as its converted by the “HexToAscii” function)

**D4** is one of our Flag Register. 

- It contains a value corresponding to the opcode that is currently being processed, and flags this to the “DestAddressingModeDetermine” function for determining effective addresses, so that we can detect illegal Effective Addressing modes for those commands. 

**D5** is one of our Temporary Variables, and has a few different miscellaneous jobs dependent on the command that is being processed

- Throughout the program, D5 holds the amount values were shifted
- In the subroutine TrapTask13, D5 holds the number of bytes that the assembler will need to write

**D6** is another one of our Temporary Variables, as well as a flag register.

- When this register is used as a flag register, it marks if the effective address is a destination addressing mode or a source addressing mode. 
- In a few locations in our implementation, we store the word operands that follow an opcode value word into this location and then from D6 into D1 ( the reason for this redundancy is that this is a remnant of an older implementation where we used D6 to hold the hex value to be converted)
- With MOVEM, D6 holds register list of what is being moved
- With strip\_ascii, D6 is a loop variable.
- Elsewhere, it is used to store the number of ASCII chars that will be added to the string buffer.

**D7** the Hex value of the current unmanipulated word that we are processing and often placed in D3 for temporary manipulation. 

**Address Registers**

**A0** is used only for holding and printing out the current data at the current instruction address for the “Error\_Subroutine” function. This aides in the formatting of the error output “XXXXXXXX DATA YYYY”, 

**A1** is used for printing in our implementation, as we load our string buffer to that address register when we get read to call TrapTask13

**A2** is used for printing in our implementation. This Address Register holds the address for the location of the ASCII representation of something we want to add to the string buffer, then we call the “Start\_String\_Appending” function. We load the location of the string we want to append into A2 before calling this function. 

**A3**’s use changes throughout the program:

- In TrapTask13, it is used to hold the file name of the output file
- Elsewhere, it is used to hold the number determining we are dealing with a Byte, a Word, or a Long, for immediate address processing.

**A4** is our pointer to our current position in memory, pointing to the word that we are currently disassembling.

**A5** holds the address to the location of our String Buffer. We copy this value to A1, as required by the TrapTask13’s preconditions.

**A6** is one of our Temporary Variables for Addresses

- It has heavy use in the MoveM subroutine, where it is used to store the list of which registers need to be pushed to the stack. It also is used for holding an address that can be offset from the current instruction address for the sake of processing immediate addressing and absolute addressing without permanently altering the contents of A4, which keeps track of where we are in the memory disassembling region.

**A7**, which is normally used to hold the stack pointer, is used in our implementation. But we used -(SP) or (SP)+  when needing to push or pull anything from the stack, instead of directly calling -(A7) or (A7)+ 
