/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  

_start: 	MOV     R4, #TEST_NUM   // load the data word address into r4
		MOV	R5, #0		// store max 1s in R5
		MOV	R6, #0		// store max 0s in R6
		MOV	R7, #0		// store max 1010s in R7
MAIN:   	LDR     R1, [R4], #4    // load word into R1
		CMP	R1, #0		// loop until word is 0
		BEQ	END
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

TEST_NUM:	.word   0x103fe00f 	//9
		.word	0xf000000f	//4 ones, 24 zeros
		.word	0x000000aa	//8 alts
		.word	0x00000fff	//12 ones
		.word	0x0000aaaa	//16 alts
		.word	0x000fffff	//20 ones
		.word	0x00aaaaaa	//24 alts
		.word	0x0fffffff	//28 ones
		.word	0xaaaaaaaa	//32 alts
		.word	0x0000ff0f	//8 ones
		.word	0x000aaa0a	//12 alts
		.word	0x000aa0aa 	//8 alts
		.word	0x00000000 	//0
ALL_ONES:	.word   0xffffffff	// all 1s
ALL_ALT:	.word	0xaaaaaaaa	// 1010s
		
		.end                            