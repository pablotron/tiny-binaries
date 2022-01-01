bits 64

; "hi!\n", encoded as 32-bit little-endian int
str: equ 0x0a216968

section .text
global _start
_start:
  push dword str  ; push str (68 68 69 21 0a)

  inc al          ; write() (fe c0)
  inc edi         ; fd (ff c7)
  mov rsi, rsp    ; msg (48 89 e6)
  mov dl, 4       ; len (b2 04)
  syscall         ; call write() (0f 05)

  mov al, 60      ; exit() (b0 3c)
  xor edi, edi    ; exit code (31 ff)
  syscall         ; call exit() (0f 05)
