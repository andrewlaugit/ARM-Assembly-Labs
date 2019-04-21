/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  

_start: 	MOV     R4, #TEST_NUM   // load the data word address into r4
		MOV	R5, #0		// store max 1s in R5
		MOV	R6, #0		// store max 0s in R6
		MOV	R7, #0		// store max 1010s in R7
MAIN:   	LDR     R1, [R4], #4    // load word into R1
		CMP	R1, #0		// loop until word is 0
		BEQ	DISPLAY		// print results onto hex
		BL	ONES		// get number of 1s in the word
		CMP	R5, R0		// compare r5-r0 to check for max
		MOVLT	R5, R0		// if r0 larger than r5 (neg result), store it
		BL	ZEROS		// get number of 0s in the word
		CMP	R6, R0		// compare r6-r0 to check for max
		MOVLT	R6, R0		// if r0 larger than r6 (neg result), store it
		BL	ALTS		// get number of 0s in the word
		CMP	R7, R0		// compare r7-r0 to check for max
		MOVLT	R7, R0		// if r0 larger than r7 (neg result), store it
		B	MAIN		// repeat
END:		B	END

ONES:		MOV     R0, #0          // R0 will hold the result
		PUSH	{R1}		// save r1 for later
LOOP_ONE:   	CMP     R1, #0        	// loop until the data contains no more 1's
       		BEQ     END_ONES	//             
        	LSR     R2, R1, #1    	// perform SHIFT, followed by AND
        	AND     R1, R1, R2    	// removes 1 consective 1  
        	ADD     R0, #1        	// count the string length so far
        	B       LOOP_ONE		
END_ONES:       POP	{R1}		// return original r1
		MOV	PC, LR		// return to caller

ZEROS:		PUSH	{R1,LR}		// save r1 and LR for later
		MOV	R2, #ALL_ONES	// get address of all ones
		LDR	R2, [R2]	// load all 1s into r2
		EOR	R1, R1, R2	// xor with 1s to 'not' r1, making all 1->0, 0->1 
		BL	ONES		// get number of zeros
		POP	{R1, LR}	// return original value
		MOV	PC, LR		// return to caller

ALTS:		PUSH	{R1,LR}		// save r1 and LR for later
		MOV	R3, #0		// store max in r3 for now
		MOV	R2, #ALL_ALT	// get address of all 1010s
		LDR	R2, [R2]	// load all 1010s into r2
		EOR	R1, R1, R2	// xor with 1010... to make alternatings 0s or 1s
		BL	ONES		// if 1010 matches with 0101, get max number of alternating
		CMP	R3, R0		// compare r3-r0 to check for max
		MOVLT	R3, R0		// if r0 larger than r3 (neg result), store it
		BL	ZEROS		// if 1010 matches with 1010, get max number of alternating
		CMP	R3, R0		// compare r3-r0 to check for max
		MOVLT	R3, R0		// if r0 larger than r3 (neg result), store it
		MOV	R0, R3		// return r0
		POP	{R1, LR}	// restore original values
		MOV	PC, LR		// return to caller

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:       	MOV	R8, #HEX_ADD1	// r8 holds hex address of HEX3-HEX0
		LDR	R8, [R8]
		MOV	R9, #10		// divide by value
        MOV R12, #0
        
		MOV	R0, R5		// post r5 on hex 0 and 1 ==============================================
		BL	DIVIDE		// convert to decimals
        MOV R11, R1		// quotient (tens)
		BL	SEG7_CODE
        MOV R4, R0		// seg7 code
        MOV R0, R11		// quotient (tens)
        BL	SEG7_CODE
		ORR R12, R4, R0, LSL # 8	// store ones digit into hex 0
        
		MOV	R0, R6		// post r6 on hex 0 and 1 ==============================================
		BL	DIVIDE		// convert to decimals
        MOV R11, R1		// quotient (tens)
		BL	SEG7_CODE
        ORR R12, R12, R0, LSL #16	// store tens digit into hex 0
        MOV R0, R11		// quotient (tens)
        BL	SEG7_CODE
        ORR R12, R12, R0, LSL #24 // store ones digit into hex 0
		STR	R12, [R8]
        
        MOV R12, #0
		MOV	R8, #HEX_ADD2	// r8 holds hex address of HEX5-HEX4
		LDR	R8, [R8] 
		MOV	R0, R7		// post r5 on hex 0 and 1 ==============================================
		BL	DIVIDE		// convert to decimals
        MOV R11, R1		// quotient (tens)
		BL	SEG7_CODE
        MOV R4, R0		// seg7 code
        MOV R0, R11		// quotient (tens)
        BL	SEG7_CODE
		ORR R12, R4, R0, LSL # 8	// store ones digit into hex 0
		STR	R12, [R8]
		B	END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     	MOV    R1, #0	 // r3 is quotient
		
CONT:    	CMP    R0, R9	 // R9 - R1, raise flags accordingly
            	BLT    DIV_END	 // if result -ve, done with division
            	SUB    R0, R9	 // if not -ve, subtract r9 from r0
            	ADD    R1, #1	 // add 1 to quotient
            	B      CONT	 // repeat sequence

DIV_END:    	MOV    PC, LR	 // return to caller

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 * 	Parameters: R0 = the decimal value of the digit to be displayed
 * 	Returns: R0 = bit patterm to be written5:02 PM 2019-02-23 to the HEX display
 */

SEG7_CODE:  	MOV     R3, #BIT_CODES
            	LDRB    R0, [R3, R0]    
            	MOV     PC, LR     

TEST_NUM:	.word   0xf0f03eaa
		.word   0xac000fff
		.word	0x00000000 	//0
ALL_ONES:	.word   0xffffffff	// all 1s
ALL_ALT:	.word	0xaaaaaaaa	// 1010s
HEX_ADD1:	.word	0xFF200020	//hex3-0
HEX_ADD2:	.word	0xFF200030	//hex5-4

BIT_CODES: 	.byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            	.byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            	.skip   2      // pad with 2 bytes to maintain word alignment                   

 


   		.end      





	