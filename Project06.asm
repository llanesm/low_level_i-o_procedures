TITLE Designing low-level I/O procedures     (Project06.asm)

; Author: Matthew Llanes
; Last Modified: 3/15/2020
; OSU email address: llanesm@oregonstate.edu
; Course number/section: CS271-400
; Project Number:        6         Due Date: 3/15/2020
; Description: Contains macros for getting and displaying strings. Macros used in procedures that
;				read string of digits and convert to numeric and then write value from string of digits converted
;				from numeric. Test program that prompts user for 10 integers, displays sum and average.

INCLUDE Irvine32.inc

MAX			EQU		2147483647
MIN			EQU		-2147483648
MAXLENGTH	EQU		11

; Macro to get string from user input
; receives: string to prompt user for input and empty array for input
; returns: user input string in input memory
; preconditions: none
; registers changed: none, ecx and edx pushed to and popped from stack
getString		MACRO	prompt, input, len
	push	ecx
	push	edx

; prompt user for input
	mov		edx, prompt
	call	WriteString

; read user input and save in memory
	mov		edx, input
	mov		ecx, len
	call	ReadString
	pop		edx
	pop		ecx
ENDM

; Macro to print string from memory location
; receives: string to print
; returns: string printed to console
; preconditions: none
; registers changed: none, ecx and edx pushed to and popped from stack
displayString	MACRO	string
	push	edx
	mov		edx, string
	call	WriteString
	pop		edx
ENDM

.data

; strings
prog_title	BYTE	"Designing low-level I/O procedures		", 0
progr_name	BYTE	"by Matthew Llanes", 0
desc_1		BYTE	"Please provide 10 signed decimal integers.", 0
desc_2		BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0
desc_3		BYTE	"After you have finished inputting the raw numbers I will display a list", 0
desc_4		BYTE	"of the integers, their sum, and their average value.", 0
prompt		BYTE	"Please enter a signed number: ", 0
error_msg	BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
re_prompt	BYTE	"Please try again: ", 0
sum_msg		BYTE	"The sum of these numbers is: ", 0
round_msg	BYTE	"The rounded average is: ", 0

; arrays
user_input	BYTE	MAXLENGTH	DUP(?)
num_string	BYTE	MAXLENGTH	DUP(?)
num_list	SDWORD	10			DUP(?)

; values
num			SDWORD	?
sign		SDWORD	?
sum			SDWORD	?

.code
main PROC

; Introduction
push	OFFSET prog_title
push	OFFSET progr_name
push	OFFSET desc_1
push	OFFSET desc_2
push	OFFSET desc_3
call	introduction

; Fill array with 10 prompted user inputs, display sum and average
push	MAX					; 60
push	MIN					; 56
push	OFFSET round_msg	; 52
push	OFFSET sum_msg		; 48
push	OFFSET sum			; 44
push	MAXLENGTH			; 40
push	OFFSET num_list		; 36
push	OFFSET num			; 32
push	OFFSET prompt		; 28
push	OFFSET user_input	; 24
push	OFFSET error_msg	; 20
push	OFFSET re_prompt	; 16
push	OFFSET sign			; 12
push	OFFSET num_string	; 8
call	testProc


	exit	; exit to operating system
main ENDP

; Procedure to introduce the program.
; receives: referenced variables for program title, programmer name,
;			and the three lines to describe the program
; returns: prints introduction to console
; preconditions: prog_title, progr_name, and desc_1(2,3) on stack
; registers changed: edx
introduction	PROC

; Set up stack frame
	push	ebp
	mov		ebp, esp

; Display program title and programmer name
	displayString	[ebp+24]
	displayString	[ebp+20]
	call			Crlf
	call			Crlf

; Display description of what program does
	displayString	[ebp+16]	; 1st line of description
	call			Crlf
	displayString	[ebp+12]	; 2nd line of description
	call			Crlf
	displayString	[ebp+8]		; 3rd line of description
	call			Crlf
	call			Crlf
	pop		ebp

	ret		20
introduction	ENDP

; Procedure to get string from user by invoking getString macro, 
; then converts string to numeric while validating input
; receives: prompt, user_input, error_msg, re_prompt, MAXLENGTH, num
; returns: user input string's numeric value in num variable location
; preconditions: defined getString macro
; registers changed: none
readVal PROC

; Set up stack frame
	push			ebp
	mov				ebp, esp
	push			eax
	push			ebx
	push			ecx
	push			edx
	push			esi
	push			edi

; get string
getInput:
	getString		[ebp+24], [ebp+20], [ebp+16]	; prompt, input, MAXLENGTH

; prep conversion loop
	mov				esi, [ebp+20]	; move array address into esi
	mov				ebx, 0			; where numeric value will accumulate
	mov				ecx, eax		; string length from getString's ReadString
	mov				al, [esi]		; first digit in string
	cld

; check for sign in front of digits
	cmp				eax, 43			; check for '+'
	je				hasSign
	cmp				eax, 45			; check for '-'
	je				hasSign
	lodsb							; first increment to same digit
	jmp				conversion

hasSign:
	mov				edx, eax		; save sign
	lodsb							; first increment same digit
	lodsb							; skip over sign
	dec				ecx				; decrease counter

conversion:
	cmp				eax, 48			; between '0'...
	jl				error
	cmp				eax, 57			; ...and '9'
	jg				error
	imul			ebx, 10			; multiply to get correct decimal place
	sub				eax, 48			; to get actual digit
	add				ebx, eax		; add number to accumulator
	lodsb
	loop			conversion
	cmp				ebx, [ebp+32]		; MIN for 32 bit register
	jl				error
	cmp				ebx, [ebp+36]		; MAX for 32 bit register
	jg				error
	jmp				isNeg

; error block
error:
	displayString	[ebp+12]
	call			Crlf
	displayString	[ebp+8]
	call			Crlf
	jmp				getInput

; check if it's negative
isNeg:
	cmp				edx, 45
	jne				endToNum
	imul			ebx, -1

; save number to memory location
endToNum:
	mov				edi, [ebp+28]
	mov				[edi], ebx
	pop				edi
	pop				esi
	pop				edx
	pop				ecx
	pop				ebx
	pop				eax
	pop				ebp

	ret				32
readVal ENDP

; Procedure to convert integer to string and display it
; receives: num, num_string, and sign
; returns: num value displayed as string
; preconditions: num has a value in memory location, num_string is empty array
; registers changed: none
writeVal PROC
; Set up stack frame
	push			ebp
	mov				ebp, esp
	push			eax
	push			ebx
	push			ecx
	push			edx
	push			esi
	push			edi

; number prep
	mov				eax, [ebp+8]
	cmp				eax, 0
	jl				negnum
	mov				ebx, 43
	mov				[ebp+16], ebx	; 43 == '+'
	jmp				Lprep

negnum:
	imul			eax, -1
	mov				[ebp+8], eax
	mov				ebx, 45
	mov				[ebp+16], ebx	; 45 == '-'

; Loop prep
Lprep:
	mov				edi, [ebp+12]	; empty array
	add				edi, 10			; point to end of the array (one's place)
	mov				ecx, 11			; counter
	mov				ebx, 10			; multiplier
	std

digitL:
	mov				eax, [ebp+8]
	mov				edx, 0
	idiv			ebx
	mov				[ebp+8], eax	; result back into number
	add				edx, 48			; ASCII representation of digit
	mov				eax, edx
	stosb
	cmp				[ebp+16], eax	; if string sign pops up, end loop
	je				stringdone
	loop			digitL


stringdone:
	displayString	[ebp+12]

; Save number in register, divide by 10, add 48 to number, store as string
	pop				edi
	pop				esi
	pop				edx
	pop				ecx
	pop				ebx
	pop				eax
	pop				ebp

	ret				12
writeVal ENDP

; Procedure to test readVal and writeVal procs by getting 10 integers from the user, displaying their sum and average
; receives: num by value, num by reference, prompt, user_input, error_msg, re_prompt, sign, num_string, num_list
;			MAXLENGTH, sum, result_msg, round_msg, 
; returns: list of error checked values, their sum, and average in console
; preconditions: readVal and writeVal procedures
; registers changed: none, all preserved
testProc PROC
; set up stack frame, preserve registers
	push			ebp
	mov				ebp, esp
	push			eax
	push			ebx
	push			ecx
	push			edx
	push			esi
	push			edi

; fill array of terms
	mov				edi, [ebp+36]
	mov				ecx, 10
	mov				eax, 0

fillArray:
	push			[ebp+60]		; MAX
	push			[ebp+56]		; MIN
	push			[ebp+32]		; num (reference)
	push			[ebp+28]		; prompt
	push			[ebp+24]		; user_input
	push			[ebp+40]		; MAXLENGTH
	push			[ebp+20]		; error_msg
	push			[ebp+16]		; re_prompt
	call			readVal
	mov				edi, [ebp+32]
	add				eax, [edi]		; sum accumulator
	add				edi, 4
	loop			fillArray

; display results

; sum
	mov				[ebp+44], eax	; move accumulated sum into sum reference
	displayString	[ebp+48]		; sum_msg
	call			Crlf
	push			[ebp+12]		; sign
	push			[ebp+8]			; num_string
	push			[ebp+44]		; sum
	call			writeVal
	call			Crlf
; average
	mov				edx, 0
	mov				ebx, 10
	idiv			ebx
	mov				[ebp+44], eax

	displayString	[ebp+52]
	call			Crlf
	push			[ebp+12]
	push			[ebp+8]
	push			[ebp+44]
	call			writeVal

; return frame and registers
	pop				edi
	pop				esi
	pop				edx
	pop				ecx
	pop				ebx
	pop				eax
	pop				ebp

	ret				56
testProc ENDP

END main
