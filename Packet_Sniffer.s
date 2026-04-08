%include "socket.s"
%include "ioctl.s"
%include "hextoasciimacro.s"
%include "Mac_Address.s"

section .text

global _start

_start:
	mov r8, ETH_P_ALL
	rol r8, 0x8						; htons(ETH_P_ALL)
	mov WORD [struct_sockaddr_ll + 2], r8w			; mov the htons(ETH_P_ALL) into struct_sockaddr_ll for bind later
        socket AF_PACKET, SOCK_RAW, r8d
        mov DWORD [fd], eax
	xor r8, r8

Ioctl:
        ioctl [fd], SIOCGIFHWADDR, STRUCT_IFREQ

copy_address_bytes:
	mov r8b, BYTE [STRUCT_IFREQ + 16 + 2 + r9] 		; mov the STRUCT_IFREQ + ifrname + ifr_hwaddr.sa_family + current MAC Address byte offset byte into r8
	mov BYTE [address_buffer + r9], r8b			; store the current MAC Address byte into the buffer offset by the current MAC Address byte
	inc r9							; Increment r9
	cmp r9, 0x6						; Compare r9 to 6 (The length in bytes of the MAC Address)
	je Htoa							; Jump if equal to Htoa
	jmp copy_address_bytes					; Else jump back to the beginning of copy_address_bytes
Htoa:
	htoa address_buffer, buflen, ascii_address_buffer	; Macro to turn MAC Address bytes into the ASCII Form of the raw bytes
	xor r9, r9

MAC_Address_write:
	mac_address ascii_address_buffer, colon
Newline:
	mov eax, 0x1						; Write Newline
	mov edi, 0x1
	mov esi, nl
	mov edx, 0x1
	syscall
	xor r9, r9

MAC_Address_copy:
	mov BYTE r8b, [address_buffer + r9]			; mov current MAC Address byte into r8
	mov BYTE [struct_sockaddr_ll + 12 + r9], r8b		; mov current MAC Address byte in r8 into struct_sockaddr_ll offset to sll_addr offset by current byte
	inc r9
	cmp r9, 0x6
	je ifindex
	jmp MAC_Address_copy

ifindex:
	ioctl [fd], SIOCGIFINDEX, STRUCT_IFREQ_ifr_ifindex
	lea r8, [STRUCT_IFREQ_ifr_ifindex + 16]
	htoa r8, 1, index
	mov eax, 0x1
	mov edi, 0x1
	mov esi, index
	mov edx, 0x3
	syscall
	mov DWORD r8d, [STRUCT_IFREQ_ifr_ifindex + 16]	; index_ifr_name
	mov DWORD [struct_sockaddr_ll + 2 + 2], r8d

Bind:
	bind [fd], struct_sockaddr_ll, sockaddr_ll_len	; Bind the socket to wlan0 based on it's interface index Will complain about not taking 1 parameter because the MAC Address is in struct_sockaddr_ll

Read:
	mov eax, 0x0					; Read Incoming Packet into Packet_Buffer
	mov edi, [fd]
	mov esi, Packet_Buffer
	mov edx, 65536
	syscall
	mov edx, eax					; mov ssize_t byte length into edx
	mov eax, 0x1					; Write all packet bytes to terminal
	mov edi, 0x1
	mov rsi, Packet_Buffer
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, nl
	mov edx, 0x1
	syscall

ProcessPacket:
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Ethernet_Header_Message
	mov edx, Eth_Hdr_Msg_Len
	syscall
	htoa Packet_Buffer, 6, ascii_address_buffer
	mov eax, 0x1					; Write Source MAC Address to terminal
	mov edi, 0x1
	mov esi, Src_Address
	mov edx, srclen
	syscall
	mac_address ascii_address_buffer, colon
	mov eax, 0x1
	mov edi, 0x1
	mov esi, nl
	mov edx, 0x1
	syscall

Dest_MAC_Address:
	lea r14, [Packet_Buffer + 6]	; Load Effective Address of the Ethernet Header offset by 6 byte to load the effective address of the Destination Address, Use r14 because registers r8 - r13 are being used in the macro
	htoa r14, 6, ascii_address_buffer
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Dst_Address
	mov edx, dstlen
	syscall
	mac_address ascii_address_buffer, colon
	mov eax, 0x1
	mov edi, 0x1
	mov esi, nl
	mov edx, 0x1
	syscall
	mov eax, 0x1			; Write "0x" to terminal
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall

Ethernet_Protocol:
	lea r14, [Packet_Buffer + 12]	; Load Effective Address of offset of Ethernet Protocol
	htoa r14, 2, buffer
	mov eax, 0x1
	mov edi, 0x1
	mov esi, buffer
	mov edx, 4
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, nl
	mov edx, 0x1
	syscall
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

STRUCT_IFREQ_ifr_ifindex:
	index_ifr_name db "wlan0", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	index_ifr_ifindex dd 0
fd:
	dd 0

address_buffer:
	db (6) dup (0)
buflen equ $-address_buffer

ascii_address_buffer:
	times buflen*2 db 0
newlen equ $-ascii_address_buffer

colon:
	db ":"

nl:
	db 0xa

struct_sockaddr_ll:
	dw AF_PACKET
	dw 0
	dd 0
	dw 0
	db 0
	db 0
	db (8) dup (0)
sockaddr_ll_len equ $-struct_sockaddr_ll

index:
	db 0, 0, 0xa

Ethernet_Header_Message:
	db "Ethernet Header:", 0xa
Eth_Hdr_Msg_Len equ $-Ethernet_Header_Message

Src_Address:
	db "Source MAC Address: "
srclen equ $-Src_Address

Dst_Address:
	db "Destination MAC Address: "
dstlen equ $-Dst_Address

Hex_Symbol:
        db "0x"

section .bss
Packet_Buffer:
	resb 65536
buffer:
	resb 100
