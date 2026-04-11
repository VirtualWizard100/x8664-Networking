%ifndef NEWLINE
%define NEWLINE
%macro newline 0
	[section .data]
	%%nl:
		db 0xa
	[section .text]
	push rax
	push rdi
	push rsi
	push rdx
	mov rax, 0x1
	mov rdi, 0x1
	mov rsi, %%nl
	mov rdx, 0x1
	syscall
	pop rdx
	pop rsi
	pop rdi
	pop rax
%endmacro
%endif
