SIOCGIFHWADDR equ 0x8927
SIOCGIFADDR equ 0x8915
SIOCGIFINDEX equ 0x8933

SIOCGIFFLAGS equ 0x8913
SIOCSIFFLAGS equ 0x8914


%macro ioctl 3
	mov eax, 0x10
	mov edi, %1
	mov esi, %2
	lea edx, [%3]
	syscall
%endmacro
