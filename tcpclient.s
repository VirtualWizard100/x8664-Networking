%include "socket.s"

section .text

global _start

_start:

	mov word [struct_sockaddr_local], AF_INET
	mov word [struct_sockaddr_local + 2], 0x901F
	mov byte [struct_sockaddr_local + 4], 127
	mov byte [struct_sockaddr_local + 5], 0
	mov byte [struct_sockaddr_local + 6], 0
	mov byte [struct_sockaddr_local + 7], 1
	socket AF_INET, SOCK_STREAM, 0
	mov [s], eax
	connect [s], struct_sockaddr_local, sockaddr_len
	mov eax, 0x1		;write
	mov edi, [s]
	mov rsi, Message
	mov edx, Message_len
	syscall
	jmp connection

connection:
        xor eax, eax		;read
	mov edi, [s]
	mov rsi, Buffer
	mov edx,  Buffer_len
	syscall
	cmp eax, 0x1
	jle closedconnection
	mov eax, 0x1		;write
	mov edi, 0x1
	mov rsi, Buffer
	mov edx, Buffer_len
	syscall
	xor eax, eax		;read
	xor edi, edi
	mov rsi, my_buffer
	mov rdx, my_buffer_len
	syscall
	cmp eax, 0x1
	jle exit
	mov eax, 0x1		;write
	mov edi, [s]
	mov rsi, my_buffer
	mov rdx, my_buffer_len
	syscall
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

struct_sockaddr_local:
	dw 0
	db (14) dup (0)

sockaddr_len equ $-struct_sockaddr_local

s:
	dd 0

Message:
	db "Ahoy.", 0xa
Message_len equ $-Message

my_buffer:
	db (32) dup (0)
my_buffer_len equ $-my_buffer

Buffer:
	db (100) dup (0)
Buffer_len equ $-Buffer
