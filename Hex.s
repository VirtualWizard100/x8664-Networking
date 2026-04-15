%ifndef HEX
%define HEX
%macro hex 0
	[section .data]
	%%Hex_Symbol:
		db "0x"
	[section .text]
	push rax
	push rdi
	push rsi
	push rdx
	xor rax, rax
	xor rdi, rdi
	xor rsi, rsi
	xor rdx, rdx
	mov eax, 0x1
	mov edi, 0x1
	mov esi, %%Hex_Symbol
	mov edx, 0x2
	syscall
	pop rdx
	pop rsi
	pop rdi
	pop rax
%endmacro
%endif
