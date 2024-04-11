/*
 * convolve.s
 *
 *  Created on: 29/01/2023
 *      Author: Hou Linxin
 */
   .syntax unified
	.cpu cortex-m4
	.fpu softvfp
	.thumb

		.global convolve

@ Start of executable code
.section .text

@ CG2028 Assignment 1, Sem 2, AY 2023/24
@ (c) ECE NUS, 2024

@ Write Student 1’s Name here: Willson Han Zhekai - A0252890Y
@ Write Student 2’s Name here:

@ You could create a look-up table of registers here:

@ R0 h[M]: signal
@ R1 x[N]: kernel
@ R2 M
@ R3 N

// R4-11 need to be PUSH, POP else code will break
@ R4 ACCESS_INDEX index
@ R5 ACCESS_INDEX array, returns element

@ R6 x_start
@ R7 x_end
@ R8 h_start = j
@ R9 y[i] sum

@ R10 i
@ R11 Length
@ R12 RESULT

@ return: R0

@ write your program from here:
convolve:
	@ Save original data
	PUSH {R14}		// Return address to main.c
	PUSH {R4-R11}

	@ Length = M + N - 1
	ADD R11, R2, R3
	SUB R11, #1

	@ Pointer to allocated memory at RESULT
	LDR R12, =RESULT

	@ Iterate for total length
	BL ITERATE_LENGTH

	@ Return (in R0) the pointer to the result array
	LDR R0, =RESULT

	@ Return to main.c
	POP {R4-R11}
	POP {R14}
	BX LR


ITERATE_LENGTH:
	PUSH {R14}			// Return address to convolve
	MOV R10, #0
length_loop:
	BL KERNEL
	ADD R10, #1
	CMP R10, R11
	BNE length_loop

	@ Return to convolve
	POP {R14}
	BX LR


KERNEL:
	PUSH {R14}			// Return address to length_loop

	@ x_start
	SUB R4, R10, R2
	ADDS R4, #1
	IT MI				// If smaller than 0, take MAX = 0
	MOVMI R4, #0
	PUSH {R4}

	@ x_end
	ADD R4, R10, #1
	CMP R4, R3
	IT PL				// CMP (R4 - R3): +ve means R3 is smaller
	MOVPL R4, R3
	PUSH {R4}

	@ h_start
	SUB R4, R2, #1
	CMP R4, R10
	IT PL				// CMP (R4 - R10): +ve means R10 smaller
	MOVPL R4, R10
	PUSH {R4}

	@ Iterate through kernel
	BL ITERATE_KERNEL

	@ Return to length_loop
	POP {R14}
	BX LR


ITERATE_KERNEL:
	@ Loop variables
	POP {R8}		// h_start
	POP {R7}		// x_end
	POP {R6}		// x_start = j
	MOV R9, #0
	PUSH {R14}		// Return address to KERNEL
kernel_loop:
	@ h[h_start]
	MOV R4, R8
	MOV R5, R0
	BL ACCESS_INDEX
	PUSH {R5}

	@ x[j]
	MOV R4, R6
	MOV R5, R1
	BL ACCESS_INDEX
	PUSH {R5}

	@ POP elements, multiply, add to sum
	POP {R4-R5}
	MUL R4, R5
	ADD R9, R4

	@ Update loop
	SUBS R8, #1		// Decrement h_start
	ADD R6, #1		// Increment x_start
	CMP R6, R7		// Compare x_start against x_end
	BMI kernel_loop

	@ Store sum in RESULT and increment address
	STR R9, [R12], #4

	@ Return to KERNEL
	POP {R14}
	BX LR

@ R4: index
@ R5: array / returns desired element
ACCESS_INDEX:
	CMP R4, #0			// Check index
	IT NE
	ADDNE R5, #4		// Increment address
	SUBS R4, #1			// Decrement index count
	BGT ACCESS_INDEX

	LDR R5, [R5]		// Return element
	BX LR


@ Allocate memory at RESULT
.lcomm RESULT 400
