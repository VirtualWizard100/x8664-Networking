%include "socket.s"
%include "ioctl.s"
%include "hextoasciimacro.s"
%include "Mac_Address.s"
%include "IP_Address.s"
%include "IPv6_Address.s"
%include "Newline.s"
%include "Zero.s"
%include "Htoib.s"
%include "Hex.s"

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
        ioctl [fd], SIOCGIFHWADDR, STRUCT_IFREQ			; Get the MAC Address of wlan0, and store it in STRUCT_IFREQ
	ioctl [fd], SIOCGIFFLAGS, STRUCT_IFREQ_ifr_ifflags	; Get the interface flags on wlan0
	xor r8, r8
	mov r8w, WORD [STRUCT_IFREQ_ifr_ifflags + 16]
	test r8, 0x100						; Test if the IFF_PROMISC flag is set
	jnz copy_address_bytes					; If the AND result in test reults in a non-zero value (0x100), then the IFF_PROMISC flags is set, and jump to copy_address_bytes
	add r8, 0x100						; Else, add the IFF_PROMISC flag to the interface flags
	mov WORD [buffer], r8w
	lea r8, [buffer + 2]
	htoa buffer, 2, r8
	lea r8, [buffer + 2]
	hex
	mov eax, 0x1
	mov edi, 0x1
	mov esi, r8d
	mov edx, 4
	syscall
	newline
	movzx r8, WORD [buffer]
	mov WORD [STRUCT_IFREQ_ifr_ifflags + 16], r8w		; Add the IFF_PROMISC flag value to the value in ifr_ifflags to set the interface to promiscuous mode
	xor r8, r8
	ioctl [fd], SIOCSIFFLAGS, STRUCT_IFREQ_ifr_ifflags	; Write the flags to the wlan0 interface to set the interface to promiscuous mode

copy_address_bytes:
	movzx r8, BYTE [STRUCT_IFREQ + 16 + 2 + r9] 		; mov the STRUCT_IFREQ + ifrname + ifr_hwaddr.sa_family + current MAC Address byte offset byte into r8
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
	hex
	mov eax, 0x1
	mov edi, 0x1
	mov esi, r14d
	mov edx, 8
	syscall
	newline
	newline

ProcessPacket:
	zero Arp, 1
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
	hex

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
	hex
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
	hex
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
	hex
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
	hex
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
	lea r14, [Packet_Buffer + 22]		; Load the Effective Address of the TTL offset into r14
	mov eax, 0x1
	mov edi, 0x1
	mov esi, TTL_Message
	mov edx, TTL_Msg_Len
	syscall
	zero buffer, 100
	htoib r14, buffer
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Protocol_Message
	mov edx, Prtcl_Msg_Len
	syscall
	lea r14, [Packet_Buffer + 23]			; Load the Effective Address of Protocol offset in the IPv4 Header
	zero Protocol, 1
	movzx r15, BYTE [r14]
	mov BYTE [Protocol], r15b
	zero buffer, 100
	htoib r14, buffer
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Checksum_Message
	mov edx, Chcksm_Msg_Len
	syscall
	hex
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
	lea r15, [Packet_Buffer + 14]			; Load the Effective Address of the potential offset of the Layer 4 Header
	movzx r8, BYTE [Packet_Buffer + 14]
	and r8, 0xf					; Clear the Version bits to only have the Internet Header Length bits
	shl r8, 0x2					; Shift r8 left by 2 to times it by 4 to get the amount of bytes in the Internet Header
	add r15, r8					; Add the amount of bytes in the Internet Header including Options to r15, Should be the exact offset of the TCP/UDP Header including options
	mov QWORD [Layer_4_Base_Pointer], r15
	call IPv4_Options
	newline
	movzx r8, BYTE [Protocol]
	cmp r8, 0x6
	je TCP
	cmp r8, 0x11
	je UDP
	jmp Next_Packet

IPv4_Options:
	movzx r14, BYTE [Header_Length]
        sub r14, 0x5					; Subtract minimum amount of DWORDs in the IPv4 Header
        cmp r14, 0x1					; Compare r14 to 1
	jge continue					; If it is greater than, or equal to 1, jump to continue
	ret

continue:
	mov eax, 0x1					; Write Options Message to terminal
	mov edi, 0x1
	mov esi, Options_Message
	mov edx, Optns_Msg_Len
	syscall
	shl r14, 0x2					; Shift the value in r14 left by to to multiply the value by 4 to get the amount of bytes in the Options field
	add r15, r14					; add the affset in bytes of the Options field to the Layer 4 Header offset
	zero Header_Length, 4
	mov DWORD [Header_Length], r14d                 ; Move the potential options length value into Header_Length for later use
	lea r15, [Packet_Buffer + 34]			; Load the Effective Address of the Options field offset into r15
	hex
	zero buffer, 100
	htoa r15, r14, buffer				; Turn the Options bytes into the ASCII form of the raw bytes
	mov eax, 0x1					; Write the ASCII Options bytes to terminal
	mov edi, 0x1
	mov esi, buffer
	shl r14, 0x1					; Shift the value r14 left by 1 to multiply it by 2 to account for double the amount of ASCII bytes
	mov edx, r14d
	syscall
	newline
	ret
ARP:
	mov BYTE [Arp], 0x1
	mov eax, 0x1
	mov edi, 0x1
	mov esi, ARP_Header_Message
	mov edx, ARP_Hdr_Msg_Len
	syscall
	jmp IPv4

IPv6:
	mov eax, 0x1
	mov edi, 0x1
	mov esi, IPv6_Header_Message
	mov edx, IPv6_Hdr_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Version_Buffer
	mov edx, Vrsn_Bfr_Len
	syscall
	movzx r14, BYTE [Packet_Buffer + 14]		; mov the Version byte in the IPv6 Header into r14
	shr r14, 4					; Shift r14 right by 4 bits to only have the Version nibble
	mov BYTE [buffer], r14b				; mov the Version value into buffer
	htoa buffer, 1, buffer				; Turn the Version value into the ASCII form of the raw bytes
	mov eax, 0x1					; Write the Version to terminal
	mov edi, 0x1
	lea esi, [buffer + 1]				; Load the Effective Address of the buffer offset by 1 to account for the '0' byte into esi
	mov edx, 0x1
	syscall
	newline
	zero buffer, 2
	movzx r14, WORD	[buffer + 14]			; mov the first word of the IPv6 Header into r14 to get the whole Traffic Class field
	and r14w, 0xff0					; Clear all bits in r14 but the Traffic Class bits
	shr r14w, 0x4					; Shift the bits in r14w left by 4 to put the Traffic Class bits at the least signifigant bit
	mov BYTE [buffer], r14b				; store the Traffic Class byte into buffer
	mov eax, 0x1					; Write Traffic Class message to terminal
	mov edi, 0x1
	mov esi, Traffic_Class_Message
	mov edx, Trfc_Cls_Msg_Len
	syscall
	hex
	htoa buffer, 1, buffer				; Turn the Traffic Class into the ASCII form of the raw byte
	mov eax, 0x1					; Write the Traffic Class ASCII byte to terminal
	mov edi, 0x1
	mov esi, buffer
	mov edx, 0x2
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Flow_Label_Message
	mov edx, Flw_Lbl_Msg_Len
	syscall
	hex
	movzx r14, DWORD [Packet_Buffer + 14]		; mov the first DWORD of the IPv6 Header into r14 to get the Flow Label bits
	and r14, 0x0fffff				; Clear all bits in r14 but the Flow Label bits
	mov DWORD [buffer], r14d			; Store the Flow Label DWORD into buffer
	lea r14, [buffer + 4]				; Load the Effective Address of the buffer offset by 4 to compensate for the Flow Label DWORD
	htoa buffer, 4, r14				; Turn the Flow Label DWORD into the ASCII form of the raw bytes
	mov eax, 0x1
	mov edi, 0x1
	lea esi, [buffer + 7]				; Load the Effective Address of the buffer offset by 7 to compensate for the Flow Label DWORD, and the first 3 zero nibbles of the Flow Label ASCII nibbles
	mov edx, 5
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Payload_Length_Message
	mov edx, Pyld_Lngth_Msg_Len
	syscall
	movzx r14, WORD [Packet_Buffer + 18]		; mov the Payload Length value into r14
	mov WORD [buffer], r14w				; mov the Payload Length value into buffer
	lea r14, [buffer + 2]				; Load the Effective Address of the buffer offset by 2 to compensate for the Payload Length WORD value
	htoa buffer, 2, r14				; Turn the Payload Length value into the ASCII form of the raw bytes
	hex
	mov eax, 0x1					; Write the ASCII Payload Length value to terminal
	mov edi, 0x1
	lea esi, [buffer + 2]
	mov edx, 0x4
	syscall
	newline
	zero buffer, 6
	lea r14, BYTE [Packet_Buffer + 20]		; Load the Effective Address of the Next Header value into r14
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Next_Header_Message
	mov edx, Nxt_Hdr_Msg_Len
	syscall
	htoib r14, buffer				; Write the ASCII integer form of the raw byte to terminal
	newline
	lea r14, [Packet_Buffer + 21]			; Load the Effective Address of the Hop Limit value into r14
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Hop_Limit_Message
	mov edx, Hp_Lmt_Msg_Len
	syscall
	zero buffer, 2
	htoib r14, buffer				; Write the ASCII integer form of the raw byte to terminal
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Source_Address_Message
	mov edx, Src_Addrss_Msg_Len
	syscall
	mov r14, QWORD [Packet_Buffer + 22]		; mov the first QWORD of the Source Address into r14
	mov QWORD [buffer], r14				; mov the first QWORD of the Source Address into the buffer
	mov r14, QWORD [Packet_Buffer + 30]		; mov the second QWORD of the Source Address into r14
	mov QWORD [buffer + 8], r14			; mov the second QWORD of the Source Address into the buffer offset by 8 to compensate for the first QWORD of the Source Address
	lea r14, [buffer + 16]				; Load the Effective Address of the buffer offset by 16 to compensate for the Source Address
	htoa buffer, 16, r14				; Turn the Source Address into the ASCII form of the raw bytes
	IPv6_Address r14				; Write the Source Address to terminal
	newline
	zero buffer, 100
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Destination_Address_Message
	mov edx, Dst_Addrss_Msg_Len
	syscall
	mov r14, QWORD [Packet_Buffer + 38]		; mov the first QWORD of the Destination Address into r14
	mov QWORD [buffer], r14				; mov the first QWORD of the Destination Address into the buffer
	mov r14, QWORD [Packet_Buffer + 46]		; mov the second QWORD of the Destination Address into r14
	mov QWORD [buffer + 8], r14			; mov the second QWORD of the Destination Address into the buffer offset by 8 to compensate for the first QWORD of the Destination Address
	lea r14, [buffer + 16]				; Load the Effective Address of the buffer offset by 16 to compensate for the Destination Address
	htoa buffer, 16, r14				; Turn the Destination Address into the ASCII form of the raw bytes
	IPv6_Address r14				; Write the Destination Address to terminal
	newline
	newline
	zero buffer, 100
	lea r15, [Packet_Buffer + 54]			; Load the Effective Address of the Layer 4 Header offset
	movzx r8, BYTE [Packet_Buffer + 20]
	cmp r8, 0x6
	je TCP
	cmp r8, 0x11
	je UDP
	jmp Next_Packet

TCP:
	mov eax, 0x1
	mov edi, 0x1
	mov esi, TCP_Header_Message
	mov edx, TCP_Hdr_Msg_Len
	syscall
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Source_Port_Message
	mov edx, Src_Prt_Msg_Len
	syscall
	hex
	movzx r9, WORD [r15]				; mov the Source Port from the base Layer 4 address into r9
	rol r9w, 0x8					; Rotate the bits left by 8 in the 16 bit form of r9 to do ntohs since the Source Port comes in Little Endian
	zero buffer, 100
	mov WORD [buffer], r9w				; mov the Source Port WORD into the buffer
	lea r14, [buffer + 2]				; Load the Effective Address of the buffer offset by 4 to compensate for the Source Port WORD
	htoa buffer, 2, r14				; Turn the Source Port value into the ASCII form of the raw bytes
	mov eax, 0x1					; Write the Source Port ASCII value to terminal
	mov edi, 0x1
	mov rsi, r14
	mov edx, 0x4
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Destination_Port_Message
	mov edx, Dstntn_Prt_Msg_Len
	syscall
	movzx r14, WORD [r15 + 2]			; mov the Destination Port into r14
	zero buffer, 3
	mov WORD [buffer], r14w				; mov the Destination Port value into buffer
	lea r14, [buffer + 2]				; Load the Effective Address of the buffer offset by 2 bytes to compensate for the Destination Port value
	htoa buffer, 2, r14				; Turn the Destination Port into the ASCII form of the raw bytes
	hex
	mov eax, 0x1					; Write the Destination Port ASCII value to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x4
	syscall
	newline
	movzx r14, DWORD [r15 + 4]			; mov the DWORD Sequence Number value into r14
	zero buffer, 100
	mov DWORD [buffer], r14d			; mov the DWORD Sequence Port value into the buffer
	lea r14, [buffer + 4]				; Load the Effective Address of the buffer offset by 4 bytes to compensate for the Sequence Number DWORD value
	htoa buffer, 4, r14				; Turn the Sequence Number into the ASCII form of the raw bytes
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Sequence_Number_Message
	mov edx, Sqnce_Nmbr_Msg_Len
	syscall
	hex
	mov eax, 0x1					; Write the Sequence Number ASCII value to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x8
	syscall
	newline
	movzx r14, DWORD [r15 + 8]			; mov the Acknowledgment Number DWORD value into r14
	zero buffer, 100
	mov DWORD [buffer], r14d			; mov the Acknowledgment Number into the buffer
	lea r14, [buffer + 4]				; Load the Effective ADdress of the buffer offset by 4 bytes to compensate for the Acknowledgment Number DWORD value
	htoa buffer, 4, r14				; Turn the Acknowledgment Number into the ASCII form of the raw bytes
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Acknowledgment_Number_Message
	mov edx, Acknldgmnt_Nmbr_Msg_Len
	syscall
	hex
	mov eax, 0x1					; Write the Acknowledgment Number ASCII value to terminal
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x8
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Data_Offset_Message
	mov edx, Dta_Offst_Msg_Len
	syscall
	movzx r8, BYTE [r15 + 12]
	shr r8, 0x4
	zero buffer, 100
	mov BYTE [buffer], r8b
	htoib buffer, (buffer + 1)
	newline
	movzx r14, BYTE [r15 + 13]
	mov r13, r14
	and r13, 0x80
	shr r13, 0x7
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Congestion_Window_Reduced_Message
	mov edx, Cngstn_Wndw_Rdcd_Msg_Len
	syscall
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	zero buffer, 3
	newline
	xor r13, r13
	mov r13, r14
	and r13, 0x40
	shr r13, 0x6
	mov eax, 0x1
	mov edi, 0x1
	mov esi, ECN_Echo_Message
	mov edx, ECN_Ech_Msg_Len
	syscall
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	zero buffer, 3
	newline
	xor r13, r13
	mov r13, r14
	and r13, 0x20
	shr r13, 0x5
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Urgent_Pointer_Flag_Message
	mov edx, Urgnt_Pntr_Flg_Msg_Len
	syscall
	htoib buffer, (buffer + 1)
	zero buffer, 3
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Acknowledgment_Flag_Message
	mov edx, Acknldgmnt_Flg_Msg_Len
	syscall
	mov r13, r14
	and r13, 0x10
	shr r13, 0x4
	zero buffer, 3
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	newline
	zero buffer, 3
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Push_Flag_Message
	mov edx, Psh_Flg_Msg_Len
	syscall
	mov r13, r14
	and r13, 0x8
	shr r13, 0x3
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Reset_Flag_Message
	mov edx, Rst_Flg_Msg_Len
	syscall
	zero buffer, 3
	mov r13, r14
	and r13, 0x4
	shr r13, 0x2
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Synchronize_Flag_Message
	mov edx, Syncrnz_Flg_Msg_Len
	syscall
	mov r13, r14
	and r13, 0x2
	shr r13, 0x1
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	newline
	zero buffer, 3
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Finish_Flag_Message
	mov edx, Fnsh_Flg_Msg_Len
	syscall
	mov r13, r14
	and r13, 0x1
	mov BYTE [buffer], r13b
	htoib buffer, (buffer + 1)
	newline
	xor r13, r13
	mov r14w, WORD [r15 + 14]
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Window_Message
	mov edx, Wndw_Msg_Len
	syscall
	mov WORD [buffer], r14w
	lea r14, [buffer + 2]
	htoa buffer, 2, r14
	hex
	mov eax, 0x1
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x4
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, TCP_Checksum_Message
	mov edx, TCP_Chcksm_Msg_Len
	syscall
	hex
	zero buffer, 100
	xor r14, r14
	movzx r14, WORD [r15 + 16]
	mov WORD [buffer], r14w
	lea r14, [buffer + 2]
	htoa buffer, 2, r14
	mov eax, 0x1
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x4
	syscall
	newline
	movzx r14, WORD [r15 + 18]
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Urgent_Pointer_Message
	mov edx, Urgnt_Pntr_Msg_Len
	syscall
	hex
	zero buffer, 100
	mov WORD [buffer], r14w
	lea r14, [buffer + 2]
	htoa buffer, 2, r14
	mov eax, 0x1
	mov edi, 0x1
	mov esi, r14d
	mov edx, 0x4
	syscall
	newline
	movzx r14, BYTE [r15 + 12]
	and r14, 0xf0
	shr r14, 0x4
	sub r14, 0x5
	cmp r14, 0x0
	jle Next_Packet
	call TCP_Options
	jmp Next_Packet

TCP_Options:
	shl r14, 0x2
	mov BYTE [TCP_Header_Length], r14b
	lea r8, [r15 + 20]
	zero buffer, 100
	htoa r8, r14, buffer
	mov eax, 0x1
	mov edi, 0x1
	mov esi, TCP_Options_Message
	mov edx, TCP_Optns_Msg_Len
	syscall
	hex
	shl r14, 0x1
	mov eax, 0x1
	mov edi, 0x1
	mov esi, buffer
	mov edx, r14d
	syscall
	newline
	ret

UDP:
	mov eax, 0x1
	mov edi, 0x1
	mov esi, UDP_Header_Message
	mov edx, UDP_Hdr_Msg_Len
	syscall
	movzx r8, WORD [r15]
	zero buffer, 6
	mov WORD [buffer], r8w
	mov eax, 0x1
	mov edi, 0x1
	mov esi, UDP_Source_Port_Message
	mov edx, UDP_Src_Prt_Msg_Len
	syscall
	hex
	htoa buffer, 2, (buffer + 2)
	mov eax, 0x1
	mov edi, 0x1
	lea esi, [buffer + 2]
	mov edx, 0x4
	syscall
	newline
	movzx r8, WORD [r15 + 2]
	zero buffer, 6
	mov WORD [buffer], r8w
	htoa buffer, 2, (buffer + 2)
	mov eax, 0x1
	mov edi, 0x1
	mov esi, UDP_Destination_Port_Message
	mov edx, UDP_Dst_Prt_Msg_Len
	syscall
	hex
	mov eax, 0x1
	mov edi, 0x1
	mov esi, (buffer + 2)
	mov edx, 0x4
	syscall
	newline
	mov eax, 0x1
	mov edi, 0x1
	mov esi, Length_Message
	mov edx, Lngth_Msg_Len
	syscall
	hex
	movzx r8, WORD [r15 + 4]
	mov WORD [buffer], r8w
	htoa buffer, 2, (buffer + 2)
	mov eax, 0x1
	mov edi, 0x1
	mov esi, (buffer + 2)
	mov edx, 0x4
	syscall
	newline
	movzx r8, WORD [r15 + 6]
	zero buffer, 6
	mov WORD [buffer], r8w
	htoa buffer, 2, (buffer + 2)
	mov eax, 0x1
	mov edi, 0x1
	mov esi, UDP_Checksum_Message
	mov edx, UDP_Chksm_Msg_Len
	syscall
	hex
	mov eax, 0x1
	mov edi, 0x1
	mov esi, (buffer + 2)
	mov edx, 0x4
	syscall
	jmp Next_Packet

Next_Packet:
	zero Protocol, 1
	zero Packet_Buffer, [Packet_Length]
	zero Packet_Length, 4
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
        ifr_name db "wlan0", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ifr_hwaddr dq struct_sockaddr_ifr_hwaddr

STRUCT_IFREQ_ifr_ifindex:
	index_ifr_name db "wlan0", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	index_ifr_ifindex dd 0

STRUCT_IFREQ_ifr_ifflags:
	flags_ifr_name db "wlan0", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	flags_ifr_ifflags dw 0
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

Packet_Length:		; Total byte lenggth of packet
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

Options_Message:
	db "Options: "
Optns_Msg_Len equ $-Options_Message

; ARP
ARP_Header_Message:
	db "ARP:", 0xa
ARP_Hdr_Msg_Len equ $-ARP_Header_Message

Arp:
	db 0

Layer_4_Base_Pointer:
	dq 0

; IPv6
IPv6_Header_Message:
	db "IPv6 Header:", 0xa
IPv6_Hdr_Msg_Len equ $-IPv6_Header_Message

Traffic_Class_Message:
	db "Traffic Class: "
Trfc_Cls_Msg_Len equ $-Traffic_Class_Message

Flow_Label_Message:
	db "Flow Label: "
Flw_Lbl_Msg_Len equ $-Flow_Label_Message

Payload_Length_Message:
	db "Payload Length: "
Pyld_Lngth_Msg_Len equ $-Payload_Length_Message

Next_Header_Message:
	db "Next Header: "
Nxt_Hdr_Msg_Len equ $-Next_Header_Message

Hop_Limit_Message:
	db "Hop Limit: "
Hp_Lmt_Msg_Len equ $-Hop_Limit_Message

; TCP
TCP_Header_Message:
	db "TCP:", 0xa
TCP_Hdr_Msg_Len equ $-TCP_Header_Message

Source_Port_Message:
	db "Source Port: "
Src_Prt_Msg_Len equ $-Source_Port_Message

Destination_Port_Message:
	db "Destination Port: "
Dstntn_Prt_Msg_Len equ $-Destination_Port_Message

Sequence_Number_Message:
	db "Sequence Number: "
Sqnce_Nmbr_Msg_Len equ $-Sequence_Number_Message

Acknowledgment_Number_Message:
	db "Acknowldgement Number: "
Acknldgmnt_Nmbr_Msg_Len equ $-Acknowledgment_Number_Message

Data_Offset_Message:
	db "Data Offset: "
Dta_Offst_Msg_Len equ $-Data_Offset_Message

Congestion_Window_Reduced_Message:
	db "Congestion Window Reduced Flag: "
Cngstn_Wndw_Rdcd_Msg_Len equ $-Congestion_Window_Reduced_Message

ECN_Echo_Message:
	db "ECN Echo Flag: "
ECN_Ech_Msg_Len equ $-ECN_Echo_Message

Urgent_Pointer_Flag_Message:
	db "Urgent Pointer Signifigant Flag: "
Urgnt_Pntr_Flg_Msg_Len equ $-Urgent_Pointer_Flag_Message

Acknowledgment_Flag_Message:
	db "Acknowledgment Flag: "
Acknldgmnt_Flg_Msg_Len equ $-Acknowledgment_Flag_Message

Push_Flag_Message:
	db "Push Flag: "
Psh_Flg_Msg_Len equ $-Push_Flag_Message

Reset_Flag_Message:
	db "Reset Flag: "
Rst_Flg_Msg_Len equ $-Reset_Flag_Message

Synchronize_Flag_Message:
	db "Synchronize Flag: "
Syncrnz_Flg_Msg_Len equ $-Synchronize_Flag_Message

Finish_Flag_Message:
	db "Finish Flag: "
Fnsh_Flg_Msg_Len equ $-Finish_Flag_Message

Window_Message:
	db "Window: "
Wndw_Msg_Len equ $-Window_Message

TCP_Checksum_Message:
	db "TCP Checksum: "
TCP_Chcksm_Msg_Len equ $-TCP_Checksum_Message

Urgent_Pointer_Message:
	db "Urgent Pointer: "
Urgnt_Pntr_Msg_Len equ $-Urgent_Pointer_Message

TCP_Options_Message:
	db "TCP Options: "
TCP_Optns_Msg_Len equ $-TCP_Options_Message

; UDP
UDP_Header_Message:
	db "UDP:", 0xa
UDP_Hdr_Msg_Len equ $-UDP_Header_Message

UDP_Source_Port_Message:
	db "Source Port: "
UDP_Src_Prt_Msg_Len equ $-UDP_Source_Port_Message

UDP_Destination_Port_Message:
	db "Destination Port: "
UDP_Dst_Prt_Msg_Len equ $-UDP_Destination_Port_Message

UDP_Checksum_Message:
	db "Checksum: "
UDP_Chksm_Msg_Len equ $-UDP_Checksum_Message

Length_Message:
	db "Length: "
Lngth_Msg_Len equ $-Length_Message


Header_Length:			; Potential Options byte length
	dd 0

TCP_Header_Length:
	dd 0			; Potential TCP Options byte length

section .bss
Packet_Buffer:
	resb 65535
Pckt_Bfr_Len equ $-Packet_Buffer

buffer:
	resb 100

