/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  

_start: 	MOV     R4, #KEY_ADD    // load the key adress into r4
		LDR	R4, [R4]
		MOV	R8, #0b1000	// pattern for key 3 press
		MOV	R7, #0b0100	// pattern for key 2 press	
 	  	MOV	R6, #0b0010	// pattern for key 1 press
		MOV	R5, #0b0001	// pattern for key 0 press
		MOV	R3, #0		// r3 will hold the display number
		BL	DISPLAY		// write 0 to the hex0 initially
MAIN:		LDR	R1, [R4]	// read the KEY	
		CMP	R5, R1		// compare pattern with key0 press
		BEQ	WRITE0
		CMP	R6, R1		// compare pattern with key1 press
		BEQ	ADD1	
		CMP	R7, R1		// compare pattern with key2 press
		BEQ	SUB1	
		CMP	R8, R1		// compare pattern with key3 press
		BEQ	BLANK
		B	MAIN		// loop

WRITE0:		LDR	R1, [R4]	// read the KEY	
		CMP	R1, #0
		BNE	WRITE0		// repeat until key has been released
		MOV	R3, #0		// count = 0
		B	DISPLAY

ADD1:		LDR	R1, [R4]	// read the KEY	
		CMP	R1, #0
		BNE	ADD1		// repeat until key has been released
		ADD	R3, #1		// count ++
		CMP	R3, #9		// if 10, need to revert back to 0
		BGT	WRITE0
		B	DISPLAY

SUB1:		LDR	R1, [R4]	// read the KEY	
		CMP	R1, #0
		BNE	SUB1		// repeat until key has been released
		SUB	R3, #1		// count --
		CMP	R3, #0		// if -ve, revert back to 0
		BLT	WRITE0	
		B	DISPLAY

BLANK:		LDR	R1, [R4]	// read the KEY	
		CMP	R1, #0
		BNE	BLANK		// repeat until key has been released
		MOV	R3, #-1		// count = -1, (for no blank)
		B	DISPLAY

ANYKEY:		LDR	R1, [R4]	// read the hex
		CMP	R1, #0
		BNE	WRITE0		// write 0 to the hex
		B	ANYKEY		// loop			

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:       	MOV	R12, #0
		MOV	R9, #HEX_ADD1	// r8 holds hex address of HEX3-HEX0
		LDR	R9, [R9]
		STR	R12, [R9]	// blank the screen
		CMP	R3, #-1		// if key3 was pressed, done
		BEQ	ANYKEY
		BL	SEG7_CODE
		STR	R0, [R9]	// store value (not blank)

		MOV	R9, #HEX_ADD2	// r8 holds hex address of HEX5-HEX4
		LDR	R9, [R9]
		STR	R12, [R9]	// blank the screen	
		B	MAIN

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 * 	Parameters: R0 = the decimal value of the digit to be displayed
 * 	Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  	MOV     R2, #BIT_CODES
            	LDRB    R0, [R2, R3]    
            	MOV     PC, LR     

HEX_ADD1:	.word	0xFF200020	//hex3-0
HEX_ADD2:	.word	0xFF200030	//hex5-4
KEY_ADD:	.word	0xFF200050	// keys 3-0

BIT_CODES: 	.byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            	.byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            	.skip   2      // pad with 2 bytes to maintain word alignment                   
   		.end      





	