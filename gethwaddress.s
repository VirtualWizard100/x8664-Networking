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
	mov eax, 0x1						; Write the MAC Address out
	mov edi, 0x1
	lea esi, [ascii_address_buffer + r9]
	mov edx, 2
	syscall
	add r9, 0x2						; Add 2 to r9 to account for the 2 bytes that are in each MAC Address ASCII byte (1 for each ASCII nibble)
	cmp r9, 0xC						; Compare it to 12 (1 byte for each ASCII nibble, 2 bytes for each ASCII MAC Address byte, MAC Address byte length = 6, 6 * 2 nibbles = 12)
	je Newline						; If it is equal to the ascii_address_buffer length, jump to Newline
	mov eax, 0x1						; Write colon in between ASCII bytes
	mov edi, 0x1
	mov esi, colon
	mov edx, 0x1
	syscall
	jmp MAC_Address_write

Newline:
	mov eax, 0x1						; Write Newline
	mov edi, 0x1
	mov esi, nl
	mov edx, 0x1
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
