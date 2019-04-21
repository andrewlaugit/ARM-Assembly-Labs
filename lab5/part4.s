/* Program that creates a clock second delay */

          .text                   // executable code follows
          .global _start                  

_start: 	MOV     R4, #KEY_ADD    // load the key edgecapture
		LDR	R4, [R4]	
		MOV	R5, #0		// r5 will hold the seconds, ones
		MOV	R6, #0		// r6 will hold the seconds, tens
		MOV	R10, #0		// r10 will hold the hundredths of seconds, ones
		MOV	R11, #0		// r11 will hold the hundredths of seconds, tens
		MOV	R7, #1		// will be like boolean, 1 for go, 0 for stop
		LDR	R8, =0xFFFEC600 // address of A9 private timer
		LDR	R9, =2000000	// 2 mil / 200 MHz should equal 0.01 seconds
		STR	R9, [R8]
		MOV	R0, #0b011
		STR	R0, [R8, #8]	// start timer
		BL	DISPLAY		// write 0 to the hex0 initially

MAIN:		LDR	R1, [R4, #12]	// read the KEY	
		CMP	R1, #0		// if not equal, key has been pressed
        	MOV	R0, R7		// update go status
		BLNE	STARTSTOP
        	MOV 	R7, R0
        	MOV	R12, #0
        	STRNE 	R1, [R4, #12]	// reset the edgecapture if set

        	MOV 	R0, R5		// update count
        	MOV 	R1, R6
		MOV	R2, R10
		MOV	R3, R11
		BL	COUNT		// increment count accordingly
        	MOV 	R5, R0
       		MOV 	R6, R1
		MOV	R10, R2
		MOV	R11, R3
        	BL	DISPLAY		// write the count to the hex
		BL 	DELAY		// do a 0.25 sec delay	
		B	MAIN		// loop

DELAY:		LDR	R0, [R8, #0xC]	// load timer status
		CMP	R0, #0
		BEQ	DELAY		// repeat if not done
		STR	R0, [R8, #0xC]	// reset F to 0
		MOV	PC, LR		// return to caller

STARTSTOP:	CMP	R1, #1
		BEQ 	FLIPGO
        	MOV	PC, LR		// return to caller
        
FLIPGO:		CMP	R0, #0
		MOVEQ	R0, #1		// if already at go, make stop
		MOVNE	R0, #0		// if already at stop, make go
       		MOV	PC, LR		// return to caller

COUNT:		CMP	R7, #1		// if no go, return
		MOVNE	PC, LR		
		ADD	R0, #1		// increment hundreds(ones) of seconds

		CMP	R0, #10		// if hundreds(ones) 10, make it 0 and increment hundreds(tens) by 1
		MOVEQ	R0, #0
		ADDEQ	R1, #1

		CMP	R1, #10		// if hundreds(tens) 100, make it 0 and increment seconds(ones) by 1
		MOVEQ	R1, #0
		ADDEQ	R2, #1

		CMP	R2, #10		// if seconds(ones) 10, make it 0 and increment seconds(tens) by 1
		MOVEQ	R2, #0
		ADDEQ	R3, #1	
		
		CMP	R3, #6		// if seconds(tens) 6, make it 0
		MOVEQ	R3, #0
	
		MOV	PC, LR		// return to caller

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:	PUSH 	{LR}       	
		MOV	R2, #0
		MOV	R3, #HEX_ADD1	// r8 holds hex address of HEX3-HEX0
		LDR	R3, [R3]

		MOV	R1, R5		// display hundredths(ones)
		BL	SEG7_CODE
		ORR	R2, R2, R0
	
		MOV	R1, R6		// display hundredths(tens)
		BL	SEG7_CODE
		ORR	R2, R2, R0, LSL #8
		
		MOV	R1, R10		// display seconds(ones)
		BL	SEG7_CODE
		ORR	R2, R2, R0, LSL #16
		
		MOV	R1, R11		// display seconds(tenss)
		BL	SEG7_CODE
		ORR	R2, R2, R0, LSL #24
		
		STR	R2, [R3]
	
		MOV	R2, #0
		MOV	R3, #HEX_ADD2	// r8 holds hex address of HEX5-HEX4
		LDR	R3, [R3]
		STR	R2, [R3]	// blank the screen
        	POP 	{LR}   
		MOV	PC, LR		// return to caller

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 * 	Parameters: R0 = the decimal value of the digit to be displayed
 * 	Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  	PUSH 	{R2}
		MOV     R2, #BIT_CODES
            	LDRB    R0, [R2, R1]
		POP	{R2}
            	MOV     PC, LR     

HEX_ADD1:	.word	0xFF200020	//hex3-0
HEX_ADD2:	.word	0xFF200030	//hex5-4
KEY_ADD:	.word	0xFF200050	// keys 3-0

BIT_CODES: 	.byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            	.byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            	.skip   2      // pad with 2 bytes to maintain word alignment                   
   		.end      
