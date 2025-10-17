%include "socket.s"

section .text

global _start

_start:

	socket AF_INET, SOCK_DGRAM, 0
	mov [s], eax

	mov word [struct_sockaddr], AF_INET
	mov word [struct_sockaddr + 2], 0x5000
	mov byte [struct_sockaddr + 4], 127
	mov byte [struct_sockaddr + 5], 0
	mov byte [struct_sockaddr + 6], 0
	mov byte [struct_sockaddr + 7], 1
	sendto [s], Message, len, 0, struct_sockaddr, sockaddr_len
	jmp exit

exit:
	mov rax, 0x3c
	xor rdi, rdi
	syscall

section .data
Message:
	db "Oi lads", 0xa

len equ $-Message

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


