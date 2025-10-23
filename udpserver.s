%include "socket.s"

section .text

global _start

_start:

	socket AF_INET, SOCK_DGRAM, 0
	mov [s], eax
	mov word [struct_sockaddr_local], AF_INET
	mov word [struct_sockaddr_local + 2], 0x901f
	mov byte [struct_sockaddr_local + 4], 127
	mov byte [struct_sockaddr_local + 5], 0
	mov byte [struct_sockaddr_local + 6], 0
	mov byte [struct_sockaddr_local + 7], 1
	bind [s], struct_sockaddr_local, sockaddr_local_len
	jmp connection

connection:
	recvfrom [s], buffer, buffer_len, 0, struct_sockaddr, socklen_t_sockaddr_len
	cmp eax, 0x1
	jle closedconnection
	mov eax, 0x1
	mov edi, 0x1
	mov rsi, buffer
	mov edx, buffer_len
	syscall
	xor eax, eax		;read
	xor edi, edi
	mov rsi, my_buffer
	mov edx, my_buffer_len
	syscall
	cmp eax, 0x1
	jle exit
	sendto [s], my_buffer, my_buffer_len, 0, struct_sockaddr, [socklen_t_sockaddr_len]
	jmp connection

closedconnection:
	mov eax, 0x1
	mov edi, 0x1
	mov rsi, closedmessage
	mov edx, closedmessage_len
	syscall
	jmp exit

exit:
	mov eax, 0x3c
	xor edi, edi
	syscall

section .data

closedmessage:
	db "Connection closed by peer", 0xa

closedmessage_len equ $-closedmessage

s:
	dd 0

struct_sockaddr_local:
	dw 0
	db (14) dup (0)

sockaddr_local_len equ $-struct_sockaddr_local

struct_sockaddr:
	dw 0
	db (14) dup (0)

sockaddr_len equ $-struct_sockaddr

socklen_t_sockaddr_len:
	dd sockaddr_len

buffer:
	db (100) dup (0)

buffer_len equ $-buffer

my_buffer:
	db (100) dup (0)

my_buffer_len equ $-my_buffer
