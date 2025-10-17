%include "socket.s"

section .text

global _start

_start:
	mov eax, 0x1	;write
	mov edi, 0x1
	mov esi, prompt
	mov edx, prompt_len
	syscall

	mov eax, 0	;read
	mov edi, 0
	mov esi, Message
	mov edx, len
	syscall


	socket AF_INET, SOCK_DGRAM, 0
	mov [s], eax

	mov word [struct_sockaddr], AF_INET
	mov word [struct_sockaddr + 2], 0x5000
	mov byte [struct_sockaddr + 4], 127
	mov byte [struct_sockaddr + 5], 0
	mov byte [struct_sockaddr + 6], 0
	mov byte [struct_sockaddr + 7], 1
	sendto [s], Message, len, 0, struct_sockaddr, sockaddr_len
	mov eax, 0x3	;close /* Make sure to close the socket file descriptor after using it to free up allocated memory */
	mov edi, [s]
	syscall
	jmp exit

exit:
	mov rax, 0x3c	;exit
	xor rdi, rdi
	syscall

section .data
prompt:
	db "Enter message here:", 0

prompt_len equ $-prompt

;Message:
;	db "Oi lads", 0xa

;len equ $-Message

ip_address:
	db 4, 4, 4, 4

port:
	dw 80

struct_in_addr:
	db (4) dup (0)

struct_sockaddr:
	dw 0
	db (14) dup (0)

sockaddr_len equ $-struct_sockaddr

section .bss

s:
	resd 1

Message:
	resb 32
len equ $-Message



;struct sockaddr_in {
;  __kernel_sa_family_t  sin_family;     /* Address family               */
;  __be16                sin_port;       /* Port number                  */
;  struct in_addr        sin_addr;       /* Internet address             */

;  /* Pad to size of `struct sockaddr'. */
;  unsigned char         __pad[__SOCK_SIZE__ - sizeof(short int) -
;                        sizeof(unsigned short int) - sizeof(struct in_addr)];
;};

;struct in_addr {
;        __be32  s_addr;
;};


