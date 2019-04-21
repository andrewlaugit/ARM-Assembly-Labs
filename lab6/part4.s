		.section .vectors, "ax"  
                B        _start              // reset vector
                B        SERVICE_UND         // undefined instruction vector
                B        SERVICE_SVC         // software interrupt vector
                B        SERVICE_ABT_INST    // aborted prefetch vector
                B        SERVICE_ABT_DATA    // aborted data vector
                .word    0                   // unused vector
                B        SERVICE_IRQ         // IRQ interrupt vector
                B        SERVICE_FIQ         // FIQ interrupt vector

                  .text                                       
                  .global  _start                          
_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */
                  LDR	R0, =0b10011	// svc mode bits
		  MSR	CPSR, R0	
		  LDR	SP, =0x20000	// set stack pointer

		  LDR	R0, =0b10010	// irq mode bits
		  MSR	CPSR, R0	
		  LDR	SP, =0x3FFFFFFC	// set stack pointer

                    BL      CONFIG_GIC          // configure the ARM generic
                                                // interrupt controller
                    BL      CONFIG_PRIV_TIMER   // configure the private timer
                    BL      CONFIG_TIMER        // configure the Interval Timer
                    BL      CONFIG_KEYS         // configure the pushbutton
                                                // KEYs port
/* Enable IRQ interrupts in the ARM processor */
                  MOV     r0, #0b01010011
                  MSR     CPSR_c, r0 // enable interrupts in svc mode
                    LDR     R5, =0xFF200000     // LEDR base address
                    LDR     R6, =0xFF200020     // HEX3-0 base address
LOOP:                                           
                    LDR     R4, COUNT           // global variable
                    STR     R4, [R5]            // light up the red lights
                    LDR     R4, HEX_code        // global variable
                    STR     R4, [R6]            // show the time in format
                                                // SS:DD
                    B       LOOP                

/* Configure the MPCore private timer to create interrupts every 1/100 seconds */
CONFIG_PRIV_TIMER:  LDR	R0, =0xFFFEC600		// a9 private timer address

		LDR	R1, =2000000		// 2 million
		STR	R1, [R0]		// count st
		LDR	R1, =0b111		// set interrupt, auto-reload,and start
		STR	R1, [R0, #8]

                BX       LR
                               
/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:   LDR	R0, =0xFF202000		// interval timer address

		LDR	R1, =0x7840		// 25 mil = 17D7840, store the lower 16 bits
		STR	R1, [R0, #8]		// count start lower bits
		LDR	R1, =0x17D		// store the upper 16 bits
		STR	R1, [R0, #0xC]

		LDR	R1, =0b111		// set start, continue, and interrupt
		STR	R1, [R0, #4]

                BX       LR
                      
/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:    LDR	R0, =0xff200050	 // KEY ADDRESS
		LDR	R1, =0b1111	 // enable interrrupts in all keys
		STR	R1, [R0, #8]	 // STORE INTO MASK
                BX       LR                

/* Global variables */
                    .global COUNT                               
COUNT:              .word   0x0       // used by timer
                    .global RUN       // used by pushbutton KEYs
RUN:                .word   0x1       // initial value to increment COUNT
                    .global RUN_TIME
RUN_TIME:           .word   0x1       // initial value to increment TIME
                    .global TIME                                
TIME:               .word   0x0       // used for real-time clock
                    .global HEX_code                            
HEX_code:           .word   0x0       // used for 7-segment displays


/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

KEYS_HANDLER:                       
                CMP      R5, #73         // check the interrupt ID
		BEQ	 KEY_ISR	 // if id corresponds to keys

		CMP	 R5, #72	 // compare against id for interval timer
		BEQ	 TIMER_ISR

		CMP	 R5, #29	// compare against id for private timer
		BEQ	 PRIVATE_TIMER_ISR 

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here 

EXIT_IRQ:       STR      R5, [R4, #0x10] 	// write to the End of Interrupt
                                         	// Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      	// return from exception

KEY_ISR:	LDR		R0, =0xff200050	 	// load key adress
		LDR		R1, [R0, #0xC]		// READ THE EDGE CAPTURE BITS
                STR		R1, [R0, #0xC]		// RESET THE EDGE CAPTURE
                
KEY0_ISR:	ANDS		R2, R1, #0b0001		// see if key0 was pressed
		BEQ		KEY1_ISR		// if not pressed, check other keys		
		LDR		R3, =RUN		// load run
                LDR		R2, [R3]			
                EOR		R2, #1			// flip run value
                STR		R2, [R3]		// save new pattern

KEY1_ISR:	ANDS		R2, R1, #0b0010		// see if key1 was pressed
		BEQ		KEY2_ISR		// if not pressed, check other keys
		LDR		R0, =0XFF202000		// load interval time address
		LDR		R2, =0b1011		// stop timer
		STR		R2, [R0, #4]		// write to control reg
		LDR		R2, [R0, #8]		// read the low 16 bits of current timer
		LDR		R3, [R0, #0xC]		// read the high 16 bits of current timer
		ORR		R2, R2, R3, LSL #16	// combine 2 half words into one word
		LSR		R2, #1			// multiply current speed by 2, so divide count by 2
		LDR		R3, =0xFFFF		// get the lowest 16 bits
		AND		R3, R3, R2
		STR		R3, [R0, #8]		// store the low 16 bits of new timer
		LSR		R2, #16
		LDR		R3, =0xFFFF		// get the highest 16 bits
		AND		R3, R3, R2
		STR		R3, [R0, #0xC]		// store the high 16 bits of new timer
		LDR		R2, =0b0111		// turn timer back on
		STR		R2, [R0, #4]		// write to control reg     

KEY2_ISR:	ANDS		R2, R1, #0b0100		// see if key2 was pressed
		BEQ		KEY3_ISR		// if not pressed, done
		LDR		R0, =0XFF202000		// load interval time address
		LDR		R2, =0b1011		// stop timer
		STR		R2, [R0, #4]		// write to control reg
		LDR		R2, [R0, #8]		// read the low 16 bits of current timer
		LDR		R3, [R0, #0xC]		// read the high 16 bits of current timer
		ORR		R2, R2, R3, LSL #16	// combine 2 half words into one word
		LSL		R2, #1			// divide current speed by 2, so multiply count by 2
		LDR		R3, =0xFFFF		// get the lowest 16 bits
		AND		R3, R3, R2
		STR		R3, [R0, #8]		// store the low 16 bits of new timer
		LSR		R2, #16
		LDR		R3, =0xFFFF		// get the highest 16 bits
		AND		R3, R3, R2
		STR		R3, [R0, #0xC]		// store the high 16 bits of new timer
		LDR		R2, =0b0111		// turn timer back on
		STR		R2, [R0, #4]		// write to control reg 

KEY3_ISR:	ANDS		R2, R1, #0b1000		// see if key2 was pressed
		BEQ		KEY_ISR_END		// if not pressed, done
		
		LDR		R3, =RUN_TIME		// load run for timer
                LDR		R2, [R3]			
                EOR		R2, #1			// flip run timer value
                STR		R2, [R3]		// save new pattern    
                
KEY_ISR_END:	B 		EXIT_IRQ		// exit interrupt routine

TIMER_ISR:	LDR		R0, =0xFF202000		// load adddress for interval timer
		LDR		R1, =1			// clear the interrupt request
		STR		R1, [R0]		
		
		LDR		R0, =RUN		// get run value
		LDR		R0, [R0]		

		LDR		R2, =COUNT		// get count value
		LDR		R1, [R2]
		ADD		R1, R1, R0		// increment count by run
		STR		R1, [R2]		// store new count value

		B 		EXIT_IRQ

PRIVATE_TIMER_ISR:
		LDR		R0, =0xFFFEC600		// load address of private timer
		LDR		R1, =1			// reset counter
		STR		R1, [R0, #0xC]

		LDR		R0, =RUN_TIME		// check if time should be incremented
		LDR		R0, [R0]	

		LDR		R3, =TIME		// get time value
		LDR		R1, [R3]
		ADD		R1, R0			// increment time by run_time
		LDR		R2, =6000
		CMP		R1, R2			// see if the time needs to be reset
		LDREQ		R1, =0			// reset if equal to 6000
		STR		R1, [R3]		// update time
		LDR		R2, =0			// r2 will hold the seg codes

		MOV		R0, R1			// get the ones digit
		BL		DIVIDE
		BL		SEG7_CODE
		ORR		R2, R2, R0		// save the seg7 for ones into r2

		MOV		R0, R1			// move the remainder for divide
		BL		DIVIDE			// get the tens digit
		BL		SEG7_CODE
		ORR		R2, R2, R0, LSL #8	// save the seg7 for tens into r2

		MOV		R0, R1			// move the remainder for divide
		BL		DIVIDE			// get the hundreds digit
		BL		SEG7_CODE
		ORR		R2, R2, R0, LSL #16	// save the seg7 for hundreds into r2

		MOV		R0, R1
		BL		SEG7_CODE
		ORR		R2, R2, R0, LSL #24	// save the seg7 for thousands into r2
		
		LDR		R3, =HEX_code
		STR		R2, [R3]
		
		B		EXIT_IRQ		

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     	MOV    R1, #0	 // r3 is quotient
		
CONT:    	CMP    R0, #10	 // 10 - R0, raise flags accordingly
            	BLT    DIV_END	 // if result -ve, done with division
            	SUB    R0, #10	 // if not -ve, subtract r9 from r0
            	ADD    R1, #1	 // add 1 to quotient
            	B      CONT	 // repeat sequence

DIV_END:    	MOV    PC, LR	 // return to caller

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 * 	Parameters: R0 = the decimal value of the digit to be displayed
 * 	Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  	LDR     R3, =BIT_CODES
            	LDRB    R0, [R3, R0]    
            	MOV     PC, LR     
	
/* Define the exception service routines */
/* Undefined instructions */
SERVICE_UND:                                
                    B   SERVICE_UND         
/* Software interrupts */
SERVICE_SVC:                                
                    B   SERVICE_SVC         
/* Aborted data reads */
SERVICE_ABT_DATA:                           
                    B   SERVICE_ABT_DATA    
/* Aborted instruction fetch */
SERVICE_ABT_INST:                           
                    B   SERVICE_ABT_INST    
SERVICE_FIQ:                                
                    B   SERVICE_FIQ                                             

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
CONFIG_GIC:
				PUSH		{LR}
    			/* Configure the A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer
				/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    			MOV		R0, #MPCORE_PRIV_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			MOV		R0, #INTERVAL_TIMER_IRQ
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT
    			
                MOV		R0, #KEYS_IRQ // 73
    			MOV		R1, #CPU0
    			BL			CONFIG_INTERRUPT

				/* configure the GIC CPU interface */
    			LDR		R0, =0xFFFEC100		// base address of CPU interface
    			/* Set Interrupt Priority Mask Register (ICCPMR) */
    			LDR		R1, =0xFFFF 			// enable interrupts of all priorities levels
    			STR		R1, [R0, #0x04]
    			/* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
				 * allows interrupts to be forwarded to the CPU(s) */
    			MOV		R1, #1
    			STR		R1, [R0]
    
    			/* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
				 * allows the distributor to forward interrupts to the CPU interface(s) */
    			LDR		R0, =0xFFFED000
    			STR		R1, [R0]    
    
    			POP     	{PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
    			PUSH		{R4-R5, LR}
    
    			/* Configure Interrupt Set-Enable Registers (ICDISERn). 
				 * reg_offset = (integer_div(N / 32) * 4
				 * value = 1 << (N mod 32) */
    			LSR		R4, R0, #3							// calculate reg_offset
    			BIC		R4, R4, #3							// R4 = reg_offset
				LDR		R2, =0xFFFED100
				ADD		R4, R2, R4							// R4 = address of ICDISER
    
    			AND		R2, R0, #0x1F   					// N mod 32
				MOV		R5, #1								// enable
    			LSL		R2, R5, R2							// R2 = value

				/* now that we have the register address (R4) and value (R2), we need to set the
				 * correct bit in the GIC register */
    			LDR		R3, [R4]								// read current register value
    			ORR		R3, R3, R2							// set the enable bit
    			STR		R3, [R4]								// store the new register value

    			/* Configure Interrupt Processor Targets Register (ICDIPTRn)
     			 * reg_offset = integer_div(N / 4) * 4
     			 * index = N mod 4 */
    			BIC		R4, R0, #3							// R4 = reg_offset
				LDR		R2, =0xFFFED800
				ADD		R4, R2, R4							// R4 = word address of ICDIPTR
    			AND		R2, R0, #0x3						// N mod 4
				ADD		R4, R2, R4							// R4 = byte address in ICDIPTR

				/* now that we have the register address (R4) and value (R2), write to (only)
				 * the appropriate byte */
				STRB		R1, [R4]
    
    			POP		{R4-R5, PC}

				
                 
         .equ EDGE_TRIGGERED,         0x1
			.equ		LEVEL_SENSITIVE,        0x0
			.equ		CPU0,         				0x01	// bit-mask; bit 0 represents cpu0
			.equ		ENABLE, 						0x1

			.equ		KEY0, 						0b0001
			.equ		KEY1, 						0b0010
			.equ		KEY2,							0b0100
			.equ		KEY3,							0b1000

			.equ		RIGHT,						1
			.equ		LEFT,							2

			.equ		USER_MODE,					0b10000
			.equ		FIQ_MODE,					0b10001
			.equ		IRQ_MODE,					0b10010
			.equ		SVC_MODE,					0b10011
			.equ		ABORT_MODE,					0b10111
			.equ		UNDEF_MODE,					0b11011
			.equ		SYS_MODE,					0b11111

			.equ		INT_ENABLE,					0b01000000
			.equ		INT_DISABLE,				0b11000000

/* This files provides address values that exist in the system */

/* Memory */
        .equ  DDR_BASE,	            0x00000000
        .equ  DDR_END,              0x3FFFFFFF
        .equ  A9_ONCHIP_BASE,	      0xFFFF0000
        .equ  A9_ONCHIP_END,        0xFFFFFFFF
        .equ  SDRAM_BASE,    	      0xC0000000
        .equ  SDRAM_END,            0xC3FFFFFF
        .equ  FPGA_ONCHIP_BASE,	   0xC8000000
        .equ  FPGA_ONCHIP_END,      0xC803FFFF
        .equ  FPGA_CHAR_BASE,   	   0xC9000000
        .equ  FPGA_CHAR_END,        0xC9001FFF

/* Cyclone V FPGA devices */
        .equ  LEDR_BASE,             0xFF200000
        .equ  HEX3_HEX0_BASE,        0xFF200020
        .equ  HEX5_HEX4_BASE,        0xFF200030
        .equ  SW_BASE,               0xFF200040
        .equ  KEY_BASE,              0xFF200050
        .equ  JP1_BASE,              0xFF200060
        .equ  JP2_BASE,              0xFF200070
        .equ  PS2_BASE,              0xFF200100
        .equ  PS2_DUAL_BASE,         0xFF200108
        .equ  JTAG_UART_BASE,        0xFF201000
        .equ  JTAG_UART_2_BASE,      0xFF201008
        .equ  IrDA_BASE,             0xFF201020
        .equ  TIMER_BASE,            0xFF202000
        .equ  AV_CONFIG_BASE,        0xFF203000
        .equ  PIXEL_BUF_CTRL_BASE,   0xFF203020
        .equ  CHAR_BUF_CTRL_BASE,    0xFF203030
        .equ  AUDIO_BASE,            0xFF203040
        .equ  VIDEO_IN_BASE,         0xFF203060
        .equ  ADC_BASE,              0xFF204000

/* Cyclone V HPS devices */
        .equ   HPS_GPIO1_BASE,       0xFF709000
        .equ   HPS_TIMER0_BASE,      0xFFC08000
        .equ   HPS_TIMER1_BASE,      0xFFC09000
        .equ   HPS_TIMER2_BASE,      0xFFD00000
        .equ   HPS_TIMER3_BASE,      0xFFD01000
        .equ   FPGA_BRIDGE,          0xFFD0501C

/* ARM A9 MPCORE devices */
        .equ   PERIPH_BASE,          0xFFFEC000   /* base address of peripheral devices */
        .equ   MPCORE_PRIV_TIMER,    0xFFFEC600   /* PERIPH_BASE + 0x0600 */

        /* Interrupt controller (GIC) CPU interface(s) */
        .equ   MPCORE_GIC_CPUIF,     0xFFFEC100   /* PERIPH_BASE + 0x100 */
        .equ   ICCICR,               0x00         /* CPU interface control register */
        .equ   ICCPMR,               0x04         /* interrupt priority mask register */
        .equ   ICCIAR,               0x0C         /* interrupt acknowledge register */
        .equ   ICCEOIR,              0x10         /* end of interrupt register */
        /* Interrupt controller (GIC) distributor interface(s) */
        .equ   MPCORE_GIC_DIST,      0xFFFED000   /* PERIPH_BASE + 0x1000 */
        .equ   ICDDCR,               0x00         /* distributor control register */
        .equ   ICDISER,              0x100        /* interrupt set-enable registers */
        .equ   ICDICER,              0x180        /* interrupt clear-enable registers */
        .equ   ICDIPTR,              0x800        /* interrupt processor targets registers */
        .equ   ICDICFR,              0xC00        /* interrupt configuration registers */

/* This files provides interrupt IDs */

/* FPGA interrupts (there are 64 in total; only a few are defined below) */
			.equ	INTERVAL_TIMER_IRQ, 			72
			.equ	KEYS_IRQ, 						73
			.equ	FPGA_IRQ2, 						74
			.equ	FPGA_IRQ3, 						75
			.equ	FPGA_IRQ4, 						76
			.equ	FPGA_IRQ5, 						77
			.equ	AUDIO_IRQ, 						78
			.equ	PS2_IRQ, 						79
			.equ	JTAG_IRQ, 						80
			.equ	IrDA_IRQ, 						81
			.equ	FPGA_IRQ10,						82
			.equ	JP1_IRQ,							83
			.equ	JP2_IRQ,							84
			.equ	FPGA_IRQ13,						85
			.equ	FPGA_IRQ14,						86
			.equ	FPGA_IRQ15,						87
			.equ	FPGA_IRQ16,						88
			.equ	PS2_DUAL_IRQ,					89
			.equ	FPGA_IRQ18,						90
			.equ	FPGA_IRQ19,						91

/* ARM A9 MPCORE devices (there are many; only a few are defined below) */
			.equ	MPCORE_GLOBAL_TIMER_IRQ,	27
			.equ	MPCORE_PRIV_TIMER_IRQ,		29
			.equ	MPCORE_WATCHDOG_IRQ,			30

/* HPS devices (there are many; only a few are defined below) */
			.equ	HPS_UART0_IRQ,   				194
			.equ	HPS_UART1_IRQ,   				195
			.equ	HPS_GPIO0_IRQ,          	196
			.equ	HPS_GPIO1_IRQ,          	197
			.equ	HPS_GPIO2_IRQ,          	198
			.equ	HPS_TIMER0_IRQ,         	199
			.equ	HPS_TIMER1_IRQ,         	200
			.equ	HPS_TIMER2_IRQ,         	201
			.equ	HPS_TIMER3_IRQ,         	202
			.equ	HPS_WATCHDOG0_IRQ,     		203
			.equ	HPS_WATCHDOG1_IRQ,     		204

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
			.byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
.end