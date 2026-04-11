%include "Htoib.s"
%include "Zero.s"

%ifndef IP_ADDRESS
%define IP_ADDRESS
%macro IP_Address 1
	[section .data]
	%%Period:
        	db "."
	[section .bss]
	%%ASCII_Buffer:
		resb 3
	[section .text]
	push rax
        push rdi
        push rsi
        push rdx
        push r9
        push r10
        xor rax, rax
        xor rdi, rdi
        xor rsi, rsi
        xor rdx, rdx
        xor r9, r9
        xor r10, r10
        lea r9, %1

%%loop:
	zero %%ASCII_Buffer, 3
	htoib r9, %%ASCII_Buffer
	inc r10
	inc r9
	cmp r10, 0x4
	je %%end
	mov eax, 0x1
	mov edi, 0x1
	mov rsi, %%Period
	mov edx, 0x1
	syscall
	jmp %%loop

%%end:
	zero %%ASCII_Buffer, 3
	pop r10
	pop r9
	pop rdx
	pop rsi
	pop rdi
	pop rax
%endmacro
%endif
