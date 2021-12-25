;
; hi.s: Print "hi!\n" to standard output, then call exit(0).
;
; Notes:
; * Generates a 114 byte x86-64 Linux ELF executable.
; * Makes straight Linux system calls.
; * ELF header, program header, and code are overlapped.
; * Code interleaved in unverified bytes of ELF header and
;   program header.
; * Actual code 22 bytes, broken into the following two 12-byte chunks:
;   - code_0: a 10 byte chunk followed by a 2 byte jmp
;   - code_1: the remaining 12 bytes of code
; * The code (but not the binary) could be shrunk by one byte by
;   switching from push/mov (8 bytes) to lea (7 bytes), but the size of
;   the binary would still be 114 bytes and we would need to use 4 bytes
;   of padding to store the string.
;
; Build:
;   nasm -f bin -o hi hi.s && chmod a+x ./hi
;
; Result:
;   $ ./hi
;   hi!
;   $ wc -c ./hi
;   114 ./hi
;
; Reference:
;   https://nathanotterness.com/2021/10/tiny_elf_modernized.html
;
bits 64

; base load address
base_addr: equ 4096 * 40

; "hi!\n" (encoded as 32-bit, little endiant int)
str: equ 0x0a216968

; elf magic number
db 0x7f, 'E', 'L', 'F'

; entry point
code_0:
  push dword str  ; push string onto stack (68 68 69 21 0a)
  inc al          ; write() (fe c0)
  mov rsi, rsp    ; str (48 89 e6)
  jmp code_1      ; jump to next chunk (eb 18)

dw 2
dw 0x3e
dd 1
dq base_addr + code_0
dq ph_start

; second code chunk
code_1:
  mov edi, eax    ; fd (89 c7)
  mov dl, 4       ; len (b2 04)
  syscall         ; call write() (0f 05)

  mov al, 60      ; exit() (b0 3c)
  xor edi, edi    ; 0 exit code (31 ff)
  syscall         ; call exit() (0f 05)

dw 64
dw 0x38
dw 1

ph_start:
dd 1
dd 5
dq 0
dq base_addr
dq 0 ; pad
dq eof, eof

; zero-pad to EOF (won't exec w/o this)
dq 0

eof:
