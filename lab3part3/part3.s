/* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           
            STR     R0, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters:  R0 has the number of elements in the list
 *              R1 has the address of the start of the list
		R2 has a copy of R0, loops remaining
		R3 holds current list item value
 * Returns: R0 returns the largest item in the list
 */
LARGE:		MOV	 R2, R0		// copy num elements into r2
		LDR	 R0, [R1]	// largest number thus far (1st in list)
		MOV	 R15, #LARGE_LOOP

LARGE_LOOP:    	SUBS     R2, #1         // decrement the loop counter
         	MOVEQ    R15, R14       // if result is equal to 0, change pc to r14
         	LDR      R3, [R1, #4]!  // get the next number
         	CMP      R0, R3         // check if larger number found
         	BGE      LARGE_LOOP     // go to next element if r3 <= r0
         	MOV      R0, R3         // update the largest number r0 = r3
        	B        LARGE_LOOP

RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            

