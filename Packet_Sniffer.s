%include "socket.s"
%include "ioctl.s"
%include "hextoasciimacro.s"
%include "Mac_Address.s"
%include "IP_Address.s"
%include "Newline.s"
%include "Zero.s"

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
	mac_address ascii_address_buffer
	xor r9, r9
	newline

MAC_Address_copy:
	mov BYTE r8b, [address_buffer + r9]			; mov current MAC Address byte into r8
	mov BYTE [struct_sockaddr_ll + 12 + r9], r8b		; mov current MAC Address byte in r8 into struct_sockaddr_ll offset to sll_addr offset by current byte
	inc r9
	cmp r9, 0x6
	je ifindex
	jmp MAC_Address_copy

ifindex:
	ioctl [fd], SIOCGIFINDEX, STRUCT_IFREQ_ifr_ifindex	; Get the interface index of wlan0
	lea r8, [STRUCT_IFREQ_ifr_ifindex + 16]			; Load the Effective Address of the interface index offset
	htoa r8, 1, index
	mov eax, 0x1
	mov edi, 0x1
	mov esi, index
	mov edx, 0x3
	syscall
	mov DWORD r8d, [STRUCT_IFREQ_ifr_ifindex + 16]	; mov the interface index into r8
	mov DWORD [struct_sockaddr_ll + 2 + 2], r8d	; store it in sll_ifindex variable offset of struct_sockaddr_ll

Bind:
	bind [fd], struct_sockaddr_ll, sockaddr_ll_len	; Bind the socket to wlan0 based on it's interface index Will complain about not taking 1 parameter because the MAC Address is in struct_sockaddr_ll

Read:
	newline
	mov eax, 0x0					; Read Incoming Packet into Packet_Buffer
	mov edi, [fd]
	mov esi, Packet_Buffer
	mov edx, 65535
	syscall
	mov edx, eax					; mov ssize_t byte length into edx
	rol dx, 0x8					; Swap the bytes of edx since the byte length returned from read comes in Little Endian
	mov WORD [buffer], dx				; mov the byte length value into buffer
	mov DWORD [Packet_Length], eax			; mov the Packet Byte Length into Packet_Length for later use
	mov eax, 0x1
        mov edi, 0x1
        mov esi, Packet_Message
        mov edx, Pkt_Msg_Len
        syscall
	mov eax, 0x1					; Write all packet bytes to terminal
	mov edi, 0x1
	mov rsi, Packet_Buffer
	mov edx, DWORD [Packet_Length]
	syscall
	newline
	newline
	lea r14, [buffer + 2]
	htoa buffer, 2, r14
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Bytes_Recieved_Message
	mov edx, Bts_Rcvd_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, r14d
	mov edx, 8
	syscall
	newline
	newline

ProcessPacket:
	mov eax, 0x1					; Write "Ethernet Header:\n" to terminal
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
	mac_address ascii_address_buffer
	newline

Dest_MAC_Address:
	lea r14, [Packet_Buffer + 6]	; Load Effective Address of the Ethernet Header offset by 6 byte to load the effective address of the Destination Address, Use r14 because registers r8 - r13 are being used in the macro
	htoa r14, 6, ascii_address_buffer
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Dst_Address
	mov edx, dstlen
	syscall
	mac_address ascii_address_buffer
	newline
	mov eax, 0x1				; Write Ethernet Protocol Message to terminal
        mov edi, 0x1
        mov esi, Ethernet_Protocol_Message
        mov edx, Ethrnt_Prtcl_Msg_Len
        syscall
	mov eax, 0x1				; Write "0x" to terminal
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall

Ethernet_Protocol:
	lea r14, [Packet_Buffer + 12]		; Load Effective Address of offset of Ethernet Protocol
	htoa r14, 2, buffer
	mov eax, 0x1
	mov edi, 0x1
	mov esi, buffer
	mov edx, 4
	syscall
	newline
	newline
	mov r8w, WORD [Packet_Buffer + 12]	; mov Ethernet Protocol into r8
	rol r8w, 8				; Since it comes in Little Endian (Network Byte Order), you need to rotate the 2 bytes to put it in Big Endian (Host Byte Order), (ntohs())
	cmp r8w, 0x0800				; Compare r8 to IPv4 Ethernet Protocol
	je IPv4
	cmp r8w, 0x0806
	je ARP
	cmp r8w, 0x86DD
	je IPv6
	jmp Next_Packet

IPv4:
	mov eax, 0x1				; Write "IPv4 Header:\n" to terminal
	mov edi, 0x1
	mov esi, IPv4_Header_Message
	mov edx, IPv4_Hdr_Msg_Len
	syscall
	lea r8, WORD [Packet_Buffer + 14]	; Load Effective Address of the first byte of the IPv4 Header
	htoa r8, 1, buffer			; Turn it into a string
	mov eax, 0x1				; Write Version_Buffer message to terminal
	mov edi, 0x1
	mov esi, Version_Buffer
	mov edx, Vrsn_Bfr_Len
	syscall
	mov eax, 0x1				; Write Version Number to terminal
	mov edi, 0x1
	mov esi, buffer
	mov edx, 0x1
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Header_Length_Message
	mov edx, Hdr_Lngth_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	lea esi, [buffer + 1]
	mov edx, 0x1
	syscall
	newline
	mov r8b, BYTE [Packet_Buffer + 14]	; mov first byte of IPv4 Header into r8
	and r8b, 0xf				; Clear the version number from r8 to only have the Internet Header Length
	mul r8, 4				; Multiply it by 4 to get the Total Header Length in bytes (Since the Header Length is how many DWORDs (4 bytes) there are in the IPv4 Header
	mov BYTE [Header_Length], r8b		; mov it into Header Length
	mov r8b, BYTE [Packet_Buffer + 15]	; mov the Differentiated Services Field into r8
	shr r8b, 0x2				; Shift right by 2 to only have the Differentiated Services Codepoint Value
	mov BYTE [buffer], r8b
	lea r14, [buffer]
	htoa r14, 1, buffer
	mov eax, 0x1
	mov edi, 0x1
	mov esi, DS_Message
	mov edx, DS_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov eax, 0x1				; Write the ASCII form of the Differentiated Services value to terminal
	mov edi, 0x1
	mov esi, buffer
	mov edx, 0x2
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Total_Length_Message
	mov edx, Ttl_Lngth_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov r8w, WORD [Packet_Buffer + 16]	; mov the Total Length into r8
	mov WORD [buffer], r8w			; mov the Total Length value into buffer
	lea r14, [buffer + 2]			; Load the Effective address of the buffer offset by 2 to compensate for the Total Length value into r14
	htoa buffer, 2, r14			; Turn the Total Length value into the ASCII form of the raw bytes, and store that into buffer offset by 2 to compensate for the Total Length value
	mov eax, 0x1				; Write the ASCII byte value of Total Length to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 4
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Identification_Message
	mov edx, Idntfctn_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov r8w, WORD [Packet_Buffer + 18]	; mov value the offset of the Identification into r8
	zero buffer, 100			; zero out the buffer
	mov WORD [buffer], r8w			; mov the value into the buffer
	lea r14, [buffer + 2]			; Load Effective Address of the buffer offset by 2
	htoa buffer, 2, r14			; Turn the Identification value into ASCII
	mov eax, 0x1				; Write the ASCII byte value to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x4
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Dont_Fragment_Message
	mov edx, Dnt_Frgmnt_Msg_Len
	syscall
	zero buffer, 100			; Zero out the buffer
	mov r9w, WORD [Packet_Buffer + 20]	; mov the next 2 bytes form the IPv4 Header into r9, they come in Little Endian and are the Flags, and Fragment Offset fields
	mov r8w, r9w				; mov value of r9 into r8
	shr r8w, 0x6				; Shift r8 right by 6 bits to put the Don't Fragment value in the least signifigant bit
	and r8w, 0x1				; Clear all other bits in r8 but that bit
	mov BYTE [buffer], r8b			; mov it into buffer
	htoa buffer, 1, buffer
	mov eax, 0x1
	mov edi, 0x1
	lea esi, [buffer + 1]
	mov edx, 0x1
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, More_Fragments_Message
	mov edx, Mr_Frgmnts_Msg_Len
	syscall
	mov r8w, r9w
	shr r8w, 0x5				; Shift r8 right by 5 bits to put the More Fragments value in the least signifigant bit
	and r8w, 0x1				; Clear all other bits in r8 but that bit
	mov BYTE [buffer], r8b			; mov it into buffer
	htoa buffer, 1, buffer
	mov eax, 0x1				; Write the More Fragments ASCII bit to teerminal
	mov edi, 0x1
	lea esi, [buffer + 1]
	mov edx, 0x1
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Fragment_Offset_Message
	mov edx, Frgmnt_Ofst_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov r8w, r9w
	and r8w, 0x1f				; Clear all bits in r8w but the Fragment Offset bits
	mov WORD [buffer], r8w			; mov the Fragment Offset value into buffer
	lea r14, [buffer + 2]			; Load the Effective Address of the buffer offset by 2 bytes
	htoa buffer, 2, r14			; Turn the Fragment Offset value into the ASCII form of the raw bytes
	mov eax, 0x1				; Write the ASCII Fragment Offset value to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x4
	syscall
	newline
	xor r8, r8
	zero buffer, 100
	mov r8b, BYTE [Packet_Buffer + 22]	; mov the TTL value into r8
	mov BYTE [buffer], r8b			; mov the TTL value into buffer
	htoa buffer, 1, buffer			; Turn the TTL value into the ASCII form of the raw byte
	mov eax, 0x1
	mov edi, 0x1
	mov esi, TTL_Message
	mov edx, TTL_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov eax, 0x1				; Write the ASCII TTL Value to terminal
	mov edi, 0x1
	mov esi, buffer
	mov edx, 0x2
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Protocol_Message
	mov edx, Prtcl_Msg_Len
	syscall
	xor r8, r8
	mov r8b, BYTE [Packet_Buffer + 23]		; mov the Protocol value into r8
	mov BYTE [Protocol], r8b			; mov the Protocol value from r8 into Protocol
	htoa Protocol, 1, buffer			; Turn the protocol into the ASCII form of the raw byte
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	mov eax, 0x1					; Write the raw ASCII Protocol byte to terminal
	mov edi, 0x1
	mov esi, buffer
	mov edx, 0x2
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Checksum_Message
	mov edx, Chcksm_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hex_Symbol
	mov edx, 0x2
	syscall
	zero buffer, 100
	mov r8w, WORD [Packet_Buffer + 24]		; mov the Checksum value into r8
	mov WORD [buffer], r8w				; mov the Checksum value into buffer
	lea r14, [buffer + 2]				; Load Effective Address of the buffer offset by 2 bytes
	htoa buffer, 2, r14				; Turn the Checksum value int the ASCII form of the raw bytes
	mov eax, 0x1					; Write the ASCII Checksum value to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 4
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Source_Address_Message
	mov edx, Src_Addrss_Msg_Len
	syscall
	IP_Address [Packet_Buffer + 26]            	; Pass the dereferenced Source Address offset in the IPv4 Header to IP_Address
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Destination_Address_Message
	mov edx, Dst_Addrss_Msg_Len
	syscall
	IP_Address [Packet_Buffer + 30]			; Pass the dereferenced Destination Address offset in the IPv4 Header to IP_Address
	newline
	jmp Next_Packet

ARP:
	mov eax, 0x1
	mov edi, 0x1
	mov esi, ARP_Header_Message
	mov edx, ARP_Hdr_Msg_Len
	syscall
	jmp Next_Packet

IPv6:

Next_Packet:
	zero Packet_Buffer, 65535
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Packet_Divider
	mov edx, Pkt_Dvdr_Len
	syscall
	jmp Read
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

Packet_Length:
	dd 0

Packet_Message:
	db "Packet: ", 0xa
Pkt_Msg_Len equ $-Packet_Message

Bytes_Recieved_Message:
	db "Bytes Recieved: "
Bts_Rcvd_Msg_Len equ $-Bytes_Recieved_Message

Packet_Divider:
	db 0xa, "------------------------------------------------------", 0xa
Pkt_Dvdr_Len equ $-Packet_Divider

; Ethernet
Ethernet_Header_Message:
	db "Ethernet Header:", 0xa
Eth_Hdr_Msg_Len equ $-Ethernet_Header_Message

Src_Address:
	db "Source MAC Address: "
srclen equ $-Src_Address

Dst_Address:
	db "Destination MAC Address: "
dstlen equ $-Dst_Address

Ethernet_Protocol_Message:
	db "Ethernet Protocol: "
Ethrnt_Prtcl_Msg_Len equ $-Ethernet_Protocol_Message

Hex_Symbol:
        db "0x"

; IPv4
IPv4_Header_Message:
	db "IPv4 Header:", 0xa
IPv4_Hdr_Msg_Len equ $-IPv4_Header_Message

Version_Buffer:
	db "Version: "
Vrsn_Bfr_Len equ $-Version_Buffer

Header_Length_Message:
	db "Header Length: "
Hdr_Lngth_Msg_Len equ $-Header_Length_Message

DS_Message:
	db "Differentiated Services Codepoint Value: "
DS_Msg_Len equ $-DS_Message

Total_Length_Message:
	db "Total Length: "
Ttl_Lngth_Msg_Len equ $-Total_Length_Message

Identification_Message:
	db "Identification ID: "
Idntfctn_Msg_Len equ $-Identification_Message

Dont_Fragment_Message:
	db "Don't Fragment: "
Dnt_Frgmnt_Msg_Len equ $-Dont_Fragment_Message

More_Fragments_Message:
	db "More Fragments: "
Mr_Frgmnts_Msg_Len equ $-More_Fragments_Message

Fragment_Offset_Message:
	db "Fragment Offset: "
Frgmnt_Ofst_Msg_Len equ $-Fragment_Offset_Message

TTL_Message:
	db "Time To Live: "
TTL_Msg_Len equ $-TTL_Message

Protocol_Message:
	db "Protocol: "
Prtcl_Msg_Len equ $-Protocol_Message

Protocol:
	db 0

Checksum_Message:
	db "Checksum: "
Chcksm_Msg_Len equ $-Checksum_Message

Source_Address_Message:
	db "Source Address: "
Src_Addrss_Msg_Len equ $-Source_Address_Message

Destination_Address_Message:
	db "Destination Address: "
Dst_Addrss_Msg_Len equ $-Destination_Address_Message

; ARP
ARP_Header_Message:
	db "ARP Header:", 0xa
ARP_Hdr_Msg_Len equ $-ARP_Header_Message

Header_Length:
	dd 0

section .bss
Packet_Buffer:
	resb 65535
Pckt_Bfr_Len equ $-Packet_Buffer

buffer:
	resb 100

