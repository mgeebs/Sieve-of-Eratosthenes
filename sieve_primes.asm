TITLE sieve_primes.asm
; Author: Michael Hedrick 
; Creation Date: 4/20/2017
; Last Edit: 4/27/2017	;;everything works

INCLUDE Irvine32.inc

;;Declare function prototypes
FindPrimes PROTO, ptrBools:PTR BYTE		      ;takes the boolArray
DisplayPrimes PROTO, ptrBoolsD:PTR BYTE		      ;takes the array, user will decide length to print
Euclid PROTO, ptrBoolsE:PTR BYTE	              ;takes array for checking for prime gcd 
MainMenu PROTO, mChoice:PTR BYTE		      ;just takes the menuchoice by reference
getGCD PROTO, numberA:PTR DWORD, numberB:PTR DWORD    ;function will be called recursively to find a GCD

;;Declare symbolics for clearing registers
clearEAX TEXTEQU <mov eax, 0>
clearEBX TEXTEQU <mov ebx, 0>
clearECX TEXTEQU <mov ecx, 0>
clearEDX TEXTEQU <mov edx, 0>
clearESI TEXTEQU <mov esi, 0>
clearEDI TEXTEQU <mov edi, 0>

.data
	boolArray BYTE 0,0, 999 dup(1) ;an array of booleans indicating prime or not prime for the
				       ;index value.
	
	invalidPrompt BYTE "Invalid selection. Try again",0ah,0dh,0
	menuChoice BYTE ?	       ;menu option returned from mainMenu function

.code
main PROC  ;begin the main procedure
	
INVOKE FindPrimes, OFFSET boolArray + 1	;determine all the primes right from the beginning 

startHere:			        ;start of the program driver
call clrscr
;;clear out all the registers wo we know we're starting clean
	clearEAX
	clearEBX
	clearECX
	clearEDX
	clearESI
	clearEDI

	INVOKE MainMenu, ADDR menuChoice	;invoke the mainMenu function passing the choice by reference
	
	cmp menuChoice, 1			;make a menu comparison
	jne option2				;if not 1 check for 2
	
	INVOKE displayPrimes, OFFSET boolArray
	jmp startHere

	option2:
	cmp menuChoice, 2			;make another menu comparison
	jne option3				;if not 1-3 check 4

	call clrscr
	INVOKE Euclid, OFFSET boolArray
	jmp startHere

	option3:
	cmp menuChoice, 3			;make another menu comparison
	jne nopeLabel				;they must have entered something invalid
	exit

	nopeLabel:
	mov edx, OFFSET invalidPrompt		;get ready to display the invalid selection text
	call WriteString			;display it
	call crlf
	jmp startHere				;go back to the start 
	

	main ENDP


;-------------------------------------------------------------
MainMenu PROC, mChoice:PTR BYTE	
;Desc: Displays the main menu and gets the user's choice
;Requires: menuChoice passed by reference
;Returns:  changes menuChoice to the user's choice
;-------------------------------------------------------------
.data
	menuPrompt1 BYTE "Select an option below:",0ah,0dh,
					 "-------------------------------------------------------------",0ah,0dh,
					 "1: Display a specified range of prime numbers between 1 and n",0ah,0dh,
					 "2: Find the GCD of two numbers via Euclid's algorithm",0ah,0dh,
					 "3: Quit",0ah,0dh,0
.code
	mov edx, OFFSET menuPrompt1		;prepare to display the menu
	call WriteString			;display the menu
	call readDec				;read in a digit from the user

	mov esi, mChoice			;move the address into the esi register
	mov [esi], al				;move the value at eax into the memory address, changing the variable						

ret
MainMenu ENDP

;-------------------------------------------------------------
FindPrimes PROC, ptrBools:PTR BYTE
;Desc: Uses the Sieve of Eratosthenes to find all primes between 2 and 1000
;Requires: the boolArray passed by reference
;Returns:  changes menuChoice to the user's choice
;-------------------------------------------------------------	
.data
	finishedPrompt BYTE "All primes between 2 and 1000 have been calculated and stored",0ah,0dh,0

.code

mov ebx, 1				;ebx will represent the number we're checking for prime
mov esi, ptrBools			;esi now holds the offset of index 1 of the booleanArray

PRIMELOOP1:
	inc esi				;move esi to the next index, so we will begin at 2 and move on
	inc ebx				;move ebx to the next number indicating the actual number being checked
	cmp ebx, 31d			;31 is the highest number we need to check,square root of 1000
	ja endPrimes			;if the number is above 31, stop sieving primes

	mov edx, 1			;prepare to check for 1					
	cmp BYTE PTR [esi], dl	;see if the number at the index is flagged as prime
	jne PRIMELOOP1			;if it isnt flagged prime don't worry about removing multiples

	clearEAX

	mov eax, ebx			;move the index value into eax for manipulations
	mul eax				;square of the value should be in ax, this is the first value to unflag
	mov edi, esi			;move the offset into edi to manipulate in the next loop
	add edi, eax
	sub edi, ebx			;trying pretty hard here lol

	PRIMELOOP2:
		cmp eax, 1000d		;check if we're over the range we're worried about
		ja PRIMELOOP1		;if we reached over the end, go to the next index
		
		mov edx, 0
		mov BYTE PTR [edi], dl	;set the value to zero at the index
		add edi, ebx		;increment by multiples of edx
		add eax, ebx
		jmp PRIMELOOP2
	
		endPrimes:

		mov edx, OFFSET finishedPrompt	;inform that the primes are all determined
		call WriteString
		call waitmsg
		call crlf
	ret
FindPrimes ENDP

;-------------------------------------------------------------
DisplayPrimes PROC, ptrBoolsD:PTR BYTE
;Desc: User enters a number N and primes 2-N are displayed
;		in the specified format
;Requires: the boolArray passed by reference
;Returns:  nothing
;function is working and finished
;-------------------------------------------------------------	
.data
	N DWORD ?			;user will choose this value, display all primes between 2 and N

	;;create an elaborate scheme of strings for telling how many primes occured
	primesPrompt1 BYTE "There are ",0
	primesPrompt2 BYTE " primes between 2 and n (n = ",0
	primesPrompt3 BYTE ")",0ah,0dh,0
	primesPrompt4 BYTE "-------------------------------------------------------",0ah,0dh,0	
	invalidPromptD BYTE "Invalid entry, try again",0ah,0dh,0
	inputPromptD BYTE "Enter a value n between 2 and 1000: ",0
	numPrimes BYTE 0  ;hold the number of primes after it's calculated in a register
	goToRow BYTE 2		;use for passing values to GoToXY
	gotoCol BYTE 0		;use for passing values to GoToXY
	colCount BYTE 0		;use for keeping track of how many columns have been printed

.code
	clearEAX
	clearEBX
	clearECX
	clearEDX
	clearESI
	clearEDI

	startHereD:
	mov numPrimes, 0				;needed to clear this every time...expected it to lose scope but stays full
	mov esi, ptrBoolsD				;move the offset into a register for easy manipulation
	mov edx, OFFSET inputPromptD	;get ready to prompt for N
	call WriteString
	call readDec				;read in a value N
	call clrscr
	cmp eax, 1000d				;need to make sure it's 1000 or less
	ja nopeLabelD				;if it isn't, tell them they have to pick again

	mov N, eax				;store the value
	mov ecx, N				;enter the count into the register for a loop
	inc ecx					;need to count one beyond n to catch every prime 
						;(for example if they enter 3 we want to find 2 and 3, stepping
					        ;through 0,1,2,3 -> thus we need to check n+1 digits
COUNTINGLOOP:
		clearEAX			;clear eax on every loop pass just to be safe
		mov al, [esi]			;move the value into the al register to see if it's 0 or 1
		cmp al, 1			;if it IS a 1 then the number is prime and we need to track it 
		jne notPrime			;if it's not 1 then it's not prime

		inc numPrimes			;if it's prime increment the variable

		notPrime:
		inc esi				;move to the next byte to see if it's prime
		loop COUNTINGLOOP		;back to the loop

		jmp finishedCounting

	nopeLabelD:
		mov edx, OFFSET invalidPromptD	;get ready to deliver the bad news
		call WriteString
		call waitmsg
		call crlf
		jmp startHereD			;another try at entering a number < 1001
	
	finishedCounting:	                ;now we need to display output formatted as specified in pa7 documents
		mov edx, OFFSET primesPrompt1	;get ready to write the first part of the message
		call WriteString
		mov al, numPrimes	        ;get ready to display the number of primes in the range				
		call WriteDec
		mov edx, OFFSET primesPrompt2	;get ready to write the second part of the message
		call WriteString
		mov eax, N			;get ready to display N
		call WriteDec
		mov edx, OFFSET primesPrompt3	;get ready to write the third part of the message
		call WriteString
		mov edx, OFFSET primesPrompt4	;get ready to display a diving line of dashes
		call WriteString

		;;at this point, we can start the loop that will display prime numbers in columns of 5
		;the header works and has displayed
		mov ebx, 0			;use for tracking actual digits
		mov esi, ptrBoolsD	        ;get esi back to the offset of the boolArray
	startDisplaying:
		mov al, [esi]		        ;move the element at the index into the al register
		cmp al, 0
 		je doNotDisplay		        ;if it's not prime, don't display it

		mov dh, goTorow			;prepare parameters for gotoXY
		mov dl, goTOcol

		call GoToXY

		mov eax, ebx			;prepare to display the actual digit
		call WriteDec
		inc colCount		        ;add a printed column
		inc ebx				;move to the next digit
		cmp colCount, 5		        ;if colCount = 5 then we need to begin a new row
		je startNewRow

		add goTocol, 5
		inc esi

		jmp lastLabel	

	startNewRow:
		sub goTocol, 25			;have to subtract all the Y coordinates we added
		inc goTorow			;prepare the next row
		mov colCount, 0		        ;empty out the column counter
		mov dh, goTorow			;get ready for another GoToXY call
		mov dl, goTocol
		call GoToXY
		add goTocol, 5
		inc esi				;move to the next index

		jmp lastLabel

	doNotDisplay:
		inc ebx				;increment our two references
		inc esi

	lastLabel:
		
		cmp ebx, N			;check to see if ebx has reached the top of the range
		jbe startDisplaying		

		pop ebx
		mov colCount, 0
		mov numPrimes, 0
		mov goToCol, 0			;set everything back to zero to prepare for running the function again
		mov goToRow, 2			;thought these would all lose scope but they get trash left behind

		call crlf
		call waitmsg

ret
DisplayPrimes ENDP

;-------------------------------------------------------------
Euclid PROC, ptrBoolsE:PTR BYTE
;Desc: User enters two numbers, proc finds the GCD and tells whether it's prime
;Requires: the boolArray passed by reference
;Returns:  nothing
;-------------------------------------------------------------	
.data
	enterNumPrompt1 BYTE "Enter Number #1: ",0
	enterNumPrompt2 BYTE "Enter Number #2: ",0
	outputScreen1 BYTE "Number #1		Number #2		GCD		GCD Prime?",0ah,0dh,
					   "--------------------------------------------------",0ah,0dh,0

	yesPrompt BYTE "yes",0
	noPrompt BYTE "no",0

	findAnotherPrompt BYTE "Find another GCD? (Y(es) or any other key for main menu): ",0
	numOne DWORD ?
	numTwo DWORD ?
	
.code
	call clrscr
	
	startEuclidAsk:
	call crlf
	mov numOne, 0
	mov numTwo, 0				;dealing with so much garbage left overs
	mov edx, OFFSET enterNumPrompt1		;get ready to ask for number 1
	call WriteString
	call readDec				;take unsigned input since sign wont matter here
	call crlf

	mov ebx, eax				;move number 1 into the ebx register
	mov numOne, ebx

	mov edx, OFFSET enterNumPrompt2		;get ready to ask for number 2
	call WriteString
	call readDec
	call crlf
							
	mov numTwo, eax
	;;for the algorithm number "a" is in ebx and "b" is in ebx
	push numOne		             ;save these because I think I'm going to mess them up
	push numTwo
	INVOKE getGCD, OFFSET numOne, OFFSET numTwo
	pop numTwo		            ;get them back from a couple lines ago
	pop numOne
	mov edx, OFFSET outputScreen1	    ;print the header for the results
	call WriteString
		
	clearEAX			

	mov eax, numOne
	call WriteDec

	mov al, 09h			    ;get ready to print a tab
	call writeChar                 
	call writeChar
	call writeChar			    ;sloppy but it works
	mov eax, numTwo
	call WriteDec

	mov al, 09h
	call writeChar
	call writeChar    		    ;print a tab
	call writeChar

	mov eax, ecx		            ;put the gcd in to display

	call WriteDec

	mov al, 09h			    ;print a tab
	call writeChar
	call writeChar         
	call writeChar

	mov esi, ptrBoolsE		    ;esi now holds the offset for finding primes
	add esi, ecx		            ;move the index of the array offset in esi to the prime number
	cmp BYTE PTR [esi], 1
	je gcdPrime

	;;gcd is not prime if we're executing here
	mov edx, OFFSET noPrompt
	call WriteString
	call crlf
	jmp askRepeat		            ;go to asking if they want to repeat

	gcdPrime:
	mov edx, OFFSET yesPrompt	    ;tell the user the gcd is prime
	call WriteString
	call crlf


	askRepeat:
	clearEAX
	mov edx, OFFSET findAnotherPrompt	;about to ask if they want to get another gcd
	call WriteString
	call readChar
	and al, 11011111b			;capitalize the input
	cmp al, 'Y'				;compare against Y, anything else exits
	je startEuclidAsk			;if they want to go again, do it
ret
Euclid ENDP

;-------------------------------------------------------------
getGCD PROC, numberA:PTR DWORD, numberB:PTR DWORD
;Desc: Makes recursive calls to itself to perform Euclid's algorithm
;Requires: two numbers passed, a and b
;Returns:  greatest common divisor in ECX
;-------------------------------------------------------------	
beginEuclid:
	clearEAX
	clearEDX
	mov esi, numberA
	mov edi, numberB
	mov edx, [edi]
	cmp [esi],edx
	jb swapVals				;if number 1 < number 2, swap them to begin the algorithm
	clearEDX
	mov eax, [esi]				;mov number 1 in for dividing
	mov ecx, [edi]
	div ecx					;divide it by number 2 (b)

	cmp edx, 0				;if the remainder is 0 this is over
	je foundGCD				;we know the value in (ecx) in the last division is the GCD if edx is 0

	mov ebx, [edi]
	mov [esi], ebx			        ;swap a and b
					        ;put the remainder into ecx (b)
	mov [edi], edx

	INVOKE getGCD, esi, edi

	jmp foundGCD

	swapVals:				;swap values a and b so a (1) is greater
	mov edx, [edi]
	mov ebx, [esi]
	mov [edi], ebx
	mov [esi], edx
	jmp beginEuclid

	foundGCD:
		ret		               ;return with ecx containing the gcd
		getGCD ENDP
end main
