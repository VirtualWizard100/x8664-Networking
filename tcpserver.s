%include "socket.s"

section .text

global _start

_start:

	socket AF_INET, SOCK_STREAM, 0

	mov [s], eax
	mov byte [struct_sockaddr_local+ 4], 127
	mov byte [struct_sockaddr_local+ 5], 0
	mov byte [struct_sockaddr_local+ 6], 0
	mov byte [struct_sockaddr_local+ 7], 1
	mov word [struct_sockaddr_local], AF_INET
	mov word [struct_sockaddr_local+ 2], 0x901F
	bind [s], struct_sockaddr_local, sockaddr_len
	listen [s], 10
	accept [s], struct_sockaddr_accept, sockaddr_accept_len
	mov [s], eax
	jmp connection


connection:
	xor eax, eax		;read
	mov rdi, [s]
	mov rsi, buffer
	mov rdx, buffer_len
	syscall
	mov eax, 0x1		;write
	mov edi, 0x1
	mov rsi, buffer
	mov rdx, buffer_len
	syscall
	xor eax, eax		;read
	xor edi, edi
	mov rsi, my_buffer
	mov rdx, my_buffer_len
	syscall
	mov eax, 0x1		;write
	xor rdi, rdi
	mov rdi, [s]
	mov rsi, my_buffer
	mov edx, my_buffer_len
	syscall
	mov eax, 0x3		;close
	mov rdi, [s]
	syscall
	jmp exit

exit:
	mov eax, 0x3c		;exit
	xor edi, edi
	syscall



section .data
s:
	dd 0

s_accept:
	dd 0

port:
	dw 8080

struct_sockaddr_local:
	dw 0
	db (14) dup (0)

sockaddr_len equ $-struct_sockaddr_local

struct_sockaddr_accept:
	sa_family dw 0
	sa_data db (14) dup (0)

len equ $-struct_sockaddr_accept

sockaddr_accept_len:
	dd len


section .bss

buffer:
	resb 2048
buffer_len equ $-buffer

my_buffer:
	resb 100
my_buffer_len equ $-my_buffer

