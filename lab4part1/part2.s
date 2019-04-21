/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  

_start: 	MOV     R4, #TEST_NUM   // load the data word address into r4
		MOV	R5, #0		// store max in R5
MAIN:   	LDR     R1, [R4], #4    // load word into R1
		CMP	R1, #0		// loop until word is 0
		BEQ	END
		BL	ONES		// get number of 1s in the word
		CMP	R5, R0		// compare r5-r0 to check for max
		MOVLT	R5, R0		// if r0 larger than r5 (neg result), store it
		B	MAIN		// repeat
END:		B	END

ONES:		MOV     R0, #0          // R0 will hold the result
LOOP:   	CMP     R1, #0        	// loop until the data contains no more 1's
       		BEQ     END_ONES	//             
        	LSR     R2, R1, #1    	// perform SHIFT, followed by AND
        	AND     R1, R1, R2    	// removes 1 consective 1  
        	ADD     R0, #1        	// count the string length so far
        	B       LOOP		
END_ONES:       MOV	PC, LR		// return to main            

TEST_NUM:	.word   0x103fe00f 	//9
		.word	0x0000000f	//4
		.word	0x000000ff	//8
		.word	0x00000fff	//12
		.word	0x0000ffff	//16
		.word	0x000fffff	//20
		.word	0x00ffffff	//24
		.word	0x0fffffff	//28
		.word	0xffffffff	//32
		.word	0x0000ff0f	//8
		.word	0x000fff0f	//12
		.word	0x000ffff0 	//16
		.word	0x00000000 	//0
		
		.end                            