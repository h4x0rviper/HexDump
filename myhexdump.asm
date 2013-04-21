;Let's try to replicate the hexdump program

section .bss
	Buff: resb 16	;16 bits per time
	
section .data
	Printable: db '|................|',10		;The printable sequence
	PrintableLen: equ $-Printable			;Printable length for indexing

	hexdumpline: db ' 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '	;A line of hex code
	hexlen: equ $-hexdumpline	;The length of this line

	digits: db '0123456789ABCDEF'	;Every possible digit

section .text
	global _start	;The entry point

_start:
	nop	;Keep the debugger happy

;Read 16 bytes from stdin and store them into a buffer
Read:	mov eax, 3	;SYS_READ
	mov ebx, 0	;Trom stdin
	mov ecx, Buff	;Store into Buff
	mov edx, 16	;Buffer length
	int 80h		;Fill the buffer

	cmp eax, 0
	je Exit		;If we got 0 as a char, EOF received: exit

	mov ebp, eax	;Store the buffer length
	xor ecx, ecx	;Zero out the ecx gpr
	
;Read a byte and look it up in the char list
Lookup:		xor eax, eax	;Clear the eax register

		;Get the address inside the hexdumpline by multiplying by 3
		mov edx, ecx	;Store the address into ebx
		lea edx, [edx*2+edx]	;Using LEA, multiply by 3
	
		;Lookup the digit into the array
		mov al, byte[Buff+ecx]		;Get the character hex value
		mov ebx, eax			;Store a copy into bl
		and al, 0xf			;Look only at the 1st nybble
		mov al, byte[digits+eax]		;Get the converted char hex value
		mov byte[hexdumpline+edx+2], al	;Move the digit found into the 1st character
		;Look at the 2nd nybble
		shr bl, 4				;Shift it to have it divided by 16
		mov bl, byte[digits+ebx]		;Move into dl the converted char
		mov byte[hexdumpline+edx+1], bl		;Store it into the array as the 2nd character
	
		inc ecx		;Realign buffer
		cmp ecx, ebp	;See if we got at the end of the buffer
		jna Lookup	;If not, continue translating
;Here we need to fill the string with ' 00' whenever a char is left untouched
Filler:		inc edx		;Next char
		cmp edx, hexlen	;See if the index is really at the end of the string
		je Continue	;If so, skip to next part
		mov byte[hexdumpline+edx], 0x30	;Put a space
		inc edx				;Next char
		mov byte[hexdumpline+edx], 0x30	;Then a zero
		inc edx				;Next char
		mov byte[hexdumpline+edx], 0x20	;Then another zero
		jmp Filler			;Repeat

Continue:	xor ecx, ecx	;Clear the counter 

Print:		cmp byte[Buff+ecx], 0x20	;If ASCII code is less than 'space'
		jl NotPrintable			;The char is not printable
		cmp byte[Buff+ecx], 0x7A	;If ASCII code is more than 'z'
		jg NotPrintable			;The char is not printable

		;If it's printable...
		mov al, byte[Buff+ecx]		;Process the character
		mov byte[Printable+ecx+1], al	;Move the processed char into the printMap
		jmp Next			;No need to substitute

		;Otherwise...
NotPrintable:	mov al, 0x2E			;Insert a point
		mov byte[Printable+ecx+1], al	;Store it into the array

Next:		inc ecx				;Add 1 to the char count
		cmp ecx, ebp			;Check if we're done
		jb Print			;If not, continue processing

;We need to fill the rest of the string with dots

		add ecx, 2			;This way we don't count the two | chars as wrong
Complete:	inc ecx				;Next char
		cmp ecx, PrintableLen		;See if the last sequence of chars left any char untouched
		je Write			;If nothing is left, go write
		mov byte[Printable+ecx-2], 0x2E	;Place a dot where needed
		jmp Complete			;Restart the process

		

;Just a plain SYS_WRITE with no surprises
Write:	mov eax, 4
	mov ebx, 1
	mov ecx, hexdumpline	;The string containing the hex values
	mov edx, hexlen
	int 80h

	mov eax, 4
	mov ebx, 1
	mov ecx, Printable	;The string containing the printable chars
	mov edx, PrintableLen
	int 80h

	jmp Read	;Continue reading
	

Exit:	mov eax, 1
	mov ebx, 0
	int 80h
