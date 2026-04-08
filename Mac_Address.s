%macro mac_address 2
%%start:
	lea r8, BYTE [%1 + r9]
	mov eax, 0x1
	mov edi, 0x1
	mov rsi, r8
	mov rdx, 2
	syscall
	add r9, 0x2 	; Add 2 to r9 to account for the 2 bytes that are in each MAC Address ASCII byte (1 for each ASCII nibble)
	cmp r9, 0xC	; Compare it to 12 (1 byte for each ASCII nibble, 2 bytes for each ASCII MAC Address byte, MAC Address byte length = 6, 6 * 2 nibbles = 12)
	je %%end	; If it is equal to the ascii_address_buffer length, jump to Newline
	mov eax, 0x1	; Write colon in between ASCII bytes
	mov edi, 0x1
	mov esi, %2
	mov edx, 0x1
	syscall
	jmp %%start
%%end:
%endmacro


