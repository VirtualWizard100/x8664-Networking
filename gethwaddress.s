%include "socket.s"
%include "ioctl.s"
%include "hextoasciimacro.s"

section .text

global _start

_start:
        socket AF_INET, SOCK_DGRAM, 0
        mov DWORD [fd], eax

Ioctl:
        ioctl [fd], SIOCGIFHWADDR, STRUCT_IFREQ
loop:
	mov r8b, BYTE [STRUCT_IFREQ + 16 + 2 + r9]
	mov BYTE [address_buffer + r9], r8b
	inc r9
	cmp r9, 0x6
	je Htoa
	jmp loop
Htoa:
	htoa address_buffer, buflen, ascii_address_buffer
        jmp exit

exit:
        mov eax, 0x3c
        mov edi, 0
        syscall

section .data

struct_sockaddr_ifr_hwaddr:
        sa_family dw 0
        sa_data db (14) dup (0)

STRUCT_IFREQ:
        ifr_name db "wlan0", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ifr_hwaddr dq struct_sockaddr_ifr_hwaddr
        ifr_ifindex dd 0
fd:
	dd 0

address_buffer:
	db (6) dup (0)
buflen equ $-address_buffer

ascii_address_buffer:
	times buflen*2 db 0
newlen equ $-ascii_address_buffer
