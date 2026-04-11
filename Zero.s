%ifndef ZERO
%define ZERO
%macro zero 2
	xor eax, eax	; Clear bits in eax to make eax equal to 0 which is going to be the value stored in the buffer
	mov edi, %1	; mov the address of the buffer into edi
	mov ecx, %2	; mov the value of the amount of bytes to clear into ecx for rep
	rep stosb	; Repeatedly store a 0 byte in the amount of bytes specified in ecx of the buffer
%endmacro
%endif
