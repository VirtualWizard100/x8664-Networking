%include "Newline.s"

section .text
global _start

_start:
	movzx eax, BYTE [buffer]	; mov byte from input buffer into eax, and pad the remaining bytes with 0 in case of garbage data
	mov rcx, ASCII_Buffer		; mov the Address of the output buffer into rcx
	add rcx, 2			; add 2 to rcx to start at the ones position
	xor rbx, rbx			; Clear bits for rbx
	mov rbx, 10			; add the divisor to rbx
	mov r8b, 0x1			; Start the digit counter at one to account for 0, or a single digit value
loop:
	xor rdx, rdx			; Clear bits in rdx for the remainder value from the following div instruction
	div ebx				; divide the value in rax by 10, store the quotient in rax, and the remainder in rdx
	add dl, 0x30			; add 0x30, or '0' to rdx to make it the ASCII integer form
	mov BYTE [rcx], dl		; mov the ASCII remainder into the current position of the output buffer
	dec rcx				; Decrement rcx to the address of the tens position for the first iteration, and the hundreds position for the second
	inc r8b				; increment the digit counter by 1
	cmp rax, 0x0			; compare rax to 0
	ja loop				; If rax is above 0, jump to loop

Write:
	mov rax, 0x1			; Write the ASCII integer to terminal
	mov rdi, 0x1
	mov rsi, rcx
	mov rdx, r8
	syscall
	newline
	mov rax, 0x3c
	xor rdi, rdi
	syscall

section .data
buffer:
	db 0x5

section .bss
ASCII_Buffer:
	resb 3
