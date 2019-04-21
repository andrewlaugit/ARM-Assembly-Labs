/* Program that converts a binary number to decimal */
           .text               // executable code follows
           .global _start

_start:     MOV	   R1, #10	// divide by value
            MOV    R4, #N	// r4 holds location for binary number
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds binary number
            MOV    R0, R4       // parameter for DIVIDE goes in R0, r0 holds copy of binary number
            BL     DIVIDE
            STRB   R0, [R5]     // Ones digit is in R0, remainder
	    MOV    R0, R2       // parameter for DIVIDE goes in R0, r0 holds copy of quotient
            BL     DIVIDE
	    STRB   R0, [R5, #1] // Tens digit is now in R0, remainder
	    MOV    R0, R2       // parameter for DIVIDE goes in R0, r0 holds copy of quotient
            BL     DIVIDE
	    STRB   R0, [R5, #2] // hundreds digit is now in R0, remainder
	    STRB   R2, [R5, #3] // Thousands digit is now in R1, quotient
END:        B      END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     MOV    R3, #0	 // r2 is quotient
CONT:       CMP    R0, R1	 // R0 - R1, raise flags accordingly
            BLT    DIV_END	 // if result -ve, done with division
            SUB    R0, R1	 // if not -ve, subtract r1 from r0
            ADD    R3, #1	 // add 1 to quotient
            B      CONT		 // repeat sequence

DIV_END:    MOV    R2, R3     	 // quotient in R1 (remainder in R0)
            MOV    PC, LR	 // return to _start portion

N:          .word  9876         // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
