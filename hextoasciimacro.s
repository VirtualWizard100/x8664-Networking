%macro htoa 3
	xor r10, r10	; Nibble Counter and store at nibble ascii byte offset counter
	xor r13, r13	; Byte Counter
        xor r12, r12	; Current byte
        xor r9, r9	; Current byte processing register
	mov r11, %2	; Buffer Length
	add r11, r11	; Multiply length by 2 to account for x2 bytes
	jmp %%valueSort

%%valueSort:
	cmp r10, r11
%ifdef OUTPUT
        je %%write
%else
	je %%end
%endif
	mov r12b, BYTE [%1 + r13]
	inc r13

%%sortfirst:		; for the first nibble
	mov r9b, r12b
	shr r9b, 0x4
	cmp r9b, 0xa
	jl %%number_high
	add r9, (0x41 - 0xa) ; add Ascii A - 0xa (10)
	jmp %%store_high

%%number_high:
	add r9, 0x30	; add Ascii 0

%%store_high:
	mov BYTE [%3 + r10], r9b
	inc r10
	jmp %%sortsecond

%%sortsecond:		; for the second nibble
        mov r9b, r12b
        and r9b, 0xf
        cmp r9b, 0xa
        jl %%number_low
        add r9, (0x41 - 0xa) ; add Ascii A - 0xa (10)
        jmp %%store_low

%%number_low:
	add r9b, 0x30

%%store_low:
	mov BYTE [%3 + r10], r9b
	inc r10
	jmp %%valueSort
%ifdef OUTPUT
%%write:
        mov eax, 0x1
        mov rdi, 0x1
        mov rsi, %3
        mov rdx, r11
        syscall
%else
%%end:
%endif
	xor r8, r8
	xor r9, r9
	xor r10, r10
	xor r11, r11
	xor r12, r12
	xor r13, r13
%endmacro

