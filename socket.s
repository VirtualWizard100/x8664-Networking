;Protocol Family
AF_INET equ 2
AF_INET6 equ 10
AF_PACKET equ 17

;Socket Type
SOCK_STREAM equ 1 ;Mainly for TCP
SOCK_DGRAM equ 2  ;Mainly for UDP, or raw sockets with protocols layer 3 and higher
SOCK_RAW equ 3	  ;Mainly for Raw Sockets from layer 2, and up, AKA, the entire Packet

;Protocol
ETH_P_ALL equ 0x0003 ;needs htons
ETH_P_IP equ 0x0800
ETH_P_IPV6 equ 0x86DD

%macro socket 3
	mov eax, 0x29
	mov edi, %1 ;Family
	mov esi, %2 ;Socket Type
	mov edx, %3 ;Protocol
	syscall
%endmacro

%macro recvfrom 6
	mov eax, 0x2d
	mov edi, %1
	lea esi, %2
	mov edx, %3
	mov r10d, %4
	lea r8d, %5
	lea r9d, %6
%endmacro


