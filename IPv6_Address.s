%ifndef IPV6_ADDRESS
%define IPV6_ADDRESS
%macro IPv6_Address 1
	[section .data]
	%%colon:
		db ":"
	[section .text]
	push r8
	push r9
	xor r8, r8
	xor r9, r9
%%loop:
	lea r8, [%1 + r9]
	mov eax, 0x1
	mov edi, 0x1
	mov rsi, r8
	mov rdx, 4
	syscall
	add r9, 0x4 	; Add 4 to r9 to account for the 2 bytes that are in each IPv6 Address ASCII byte (1 for each ASCII nibble)
	cmp r9, 0x20	; Compare it to 32 (1 byte for each ASCII nibble, 2 bytes for each ASCII IPv6 Address byte, IPv6 Address byte length = 16, 16 * 2 nibbles = 32)
	je %%end	; If it is equal to the ascii_address_buffer length, jump to Newline
	mov eax, 0x1	; Write colon in between ASCII bytes
	mov edi, 0x1
	mov esi, %%colon
	mov edx, 0x1
	syscall
	jmp %%loop
%%end:
	pop r9
	pop r8
%endmacro
%endif

