%macro newline 0
	mov eax, 0x1
	mov edi, 0x1
	lea esi, nl
	mov edx, 1
	syscall
%endmacro

section .data
nl:
	db 0xa
