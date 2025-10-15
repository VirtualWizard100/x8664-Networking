%include "socket.s"
%include "ioctl.s"

section .text

global _start

_start:
	socket AF_INET, SOCK_DGRAM, 0
	mov edi, eax

Ioctl:
	ioctl edi, SIOCGIFHWADDR, STRUCT_IFREQ
	jmp Write

Write:
	mov eax, 0x1
	mov edi, 0x1
	mov rsi, [STRUCT_IFREQ + 16 + 2]
	mov edx, 6
	syscall
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


