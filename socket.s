;Protocol Family
AF_INET equ 2
AF_INET6 equ 10
AF_PACKET equ 17

;Socket Type
SOCK_STREAM equ 1 ;Mainly for TCP
SOCK_DGRAM equ 2  ;Mainly for UDP, or raw sockets with protocols layer 3 and higher
SOCK_RAW equ 3	  ;Mainly for Raw Sockets from layer 2, and up, AKA, the entire Packet

;;Protocol

;ethernet
ETH_P_ALL equ 0x0003 ;needs htons
ETH_P_IP equ 0x0800
ETH_P_IPV6 equ 0x86DD

;;setsockopt options

;raw sockets
IP_HDRINCL equ 0x3

;ipv6
IPV6_V6ONLY equ 0x1a

;sockets
SO_REUSEADDR equ 2

;setsockopt levels
SOL_SOCKET equ 0x1
IPPROTO_RAW equ 0xff
IPPROTO_IPV6 equ 0x29

%macro socket 3
	mov eax, 0x29
	mov edi, %1 ;Family
	mov esi, %2 ;Socket Type
	mov edx, %3 ;Protocol
	syscall
%endmacro

%macro bind 3
	mov eax, 0x31
	mov edi, %1
	mov rsi, %2
	mov rdx, %3
	syscall
%endmacro

%macro sendmsg 4
	mov eax, 0x2e
	mov edi, %1
	lea esi, [%2]
	mov edx, %3
	mov r10d, %4
	syscall
%endmacro

%macro sendto 6
	mov eax, 0x2c
	mov rdi, %1
	mov rsi, %2
	mov rdx, %3
	mov r10, %4
	mov r8, %5
	mov r9, %6
	syscall
%endmacro

%macro recvmsg 3
	mov eax, 0x2f
	mov edi, %1
	mov rsi, %2
	mov edx, %3
	syscall
%endmacro

%macro recvfrom 6
	mov eax, 0x2d
	mov edi, %1
	mov esi, %2
	mov edx, %3
	mov r10d, %4
	mov r8d, %5
	mov r9d, %6
	syscall
%endmacro

%macro listen 2
	mov eax, 0x32
	mov edi, %1
	mov esi, %2
	syscall
%endmacro

%macro accept 3
	mov eax, 0x2b
	mov edi, %1
	lea rsi, [%2]
	lea rdx, [%3]
	syscall
%endmacro

%macro connect 3
	mov eax, 0x2a
	mov edi, %1
	mov rsi, %2
	mov rdx, %3
	syscall
%endmacro

%macro setsockopt 5
	mov eax, 0x36
	mov edi, %1
	mov esi, %2
	mov edx, %3
	mov r10, %4
	mov r8, %5
	syscall
%endmacro
