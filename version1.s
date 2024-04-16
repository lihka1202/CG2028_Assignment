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

@ Write Student 1’s Name here: 
@ Write Student 2’s Name here: 

@ Look-up table of registers:

/*
  R0 addr of signal array
  R1 addr of kernel array
  R2 value of M size of signal
  R3 value of N size of kernel

  R4 M+N-1
  R5 i
  R6 j
  R7 x_start
  R8 x_end
  R9 h_start

  R2, R10, R11, R12 hold the values for the MLA in inner loop
*/

@ write your program from here:
convolve:
	PUSH {R14}
	PUSH {R4-R11}

	@ M + N - 1
	ADD R4, R2, R3
	SUB R4, #1

	@ allocate output array (w extra)
	.lcomm OUTPUT 400

	@ set i, j = 0
	MOV R5, #0
	MOV R6, #0

	@ call main subroutine
	BL outer_caller

	@ housekeeping- return back to c func
	LDR R0, =OUTPUT
	POP {R4-R11}
	POP {R14}
	BX LR  // means return to the address in the link register

outer_caller:
	@ do outer loop until i's end value
	PUSH {R14}
	CMP R5, R4
	BCC outer_loop

outer_exit:
	POP {R14}
	BX LR

outer_loop:
	CMP R5, R4
	BCS outer_exit
	@ R7, ie x_start_idx, gets max(0, i - lenH + 1)
	MOV R10, #0
	SUBS R12, R5, R2
	ADD R12, #1
	CMP R10, R12
	ITE GT       // if then else, R10 > R12 (signed)
	MOVGT R7, R10
	MOVLE R7, R12


	@ R8, ie x_end_idx, gets min(i + 1, lenX)
	MOV R10, R5
	ADD R10, #1
	CMP R10, R3
	ITE LT       // if then else, R10 < R3 (signed)
	MOVLT R8, R10
	MOVGE R8, R3

	@ R9, ie h_start_idx, gets min(i,lenH - 1)
	MOV R10, R5
	MOV R11, R3
	SUB R11, #1
	CMP R10, R11
	ITE LT       // if then else, R10 < R11 (signed)
	MOVLT R9, R10
	MOVGE R9, R11

	@ set j to x_start do inner loop till j reaches x_end
	MOV R6, R7
	CMP R6, R8
	BCC inner_caller

	@ housekeeping- increment variables, call itself
	ADD R5, R5, #1

	B outer_loop


inner_caller:
	@ do inner loop till j reaches x_end, then ++i
	CMP R6, R8
	BCC inner_loop
	ADD R5, R5, #1
	B outer_loop


inner_loop:
	@ -- get current out[i] val --
	@ calc offset amount for output array
	MOV R10, #4
	MUL R10, R10, R5
	@ point to correct index of output arr
	PUSH {R3}
	LDR R3, =OUTPUT
	ADD R3, R10
	@ put value into R2
	PUSH {R2}
	LDR R2, [R3]
	// no need to init to 0 for the first as lcomm inits to 0

	@ -- get h[curr_h_start] val --
	@ calc offset amount for signal
	MOV R10, #4
	MUL R10, R10, R9
	@ point to correct index of signal arr
	ADD R12, R0, R10
	@ replace R12 with value
	LDR R12, [R12]

	@ -- get x[curr_j] val --
	@ calc offset amount for kernel
	MOV R10, #4
	MUL R10, R10, R6
	@ point to correct index of kernel arr
	ADD R11, R1, R10
	@ replace R11 with value
	LDR R11, [R11]

	@ do the multiplication + addition
	MLA R10, R12, R11, R2

	@ store
	STR R10, [R3]

	@ stack housekeeping
	POP {R2}
	POP {R3}

	@ values housekeeping
	ADD R6, R6, #1
	SUB R9, R9, #1

	B inner_caller

