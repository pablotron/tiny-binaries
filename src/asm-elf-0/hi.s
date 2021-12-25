;
; hi.s: Print "hi!\n" to standard output, then call exit(0).
;
; Notes:
; * Generates a 114 byte x86-64 Linux ELF executable.
; * Makes straight linux system calls.
; * ELF header and program header are interleaved.
; * Assembly is interleaved in unverified bytes of ELF header and
;   program header.
;
; Build:
;   nasm -f bin -o hi hi.s && chmod a+x ./hi
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
; db 2, 1, 1, 0 ; not verified, can be mangled

; entry point
code_0:
  push dword str  ; push string onto stack (68 68 69 21 0a)
  inc al          ; write() (fe c0)
  ; inc di          ; fd (66 ff c7)
  mov edi, eax    ; fd (89 c7)
  jmp code_1      ; jump to next chunk (eb 18)
  db 0            ; pad (00)

dw 2
dw 0x3e
dd 1
dq base_addr + code_0
dq ph_start

; second code chunk
code_1:
  mov rsi, rsp    ; str (48 89 e6)
  mov dl, 4       ; len (b2 04)
  syscall         ; call write() (0f 05)

  mov al, 60      ; exit() (b0 3c)
  jmp code_2      ; jump to next chunk (eb 1f)
  db 0            ; pad (00)

dw 64
dw 0x38
dw 1

ph_start:
; These next two fields also serve as the final six bytes of the ELF header.
dd 1
dd 5
dq 0
dq base_addr

; third code chunk
code_2:
  xor edi, edi    ; 0 exit code (31 ff)
  syscall         ; call exit() (0f 05)
  dd 0            ; pad (00 00 00 00)

dq eof, eof

; zero-pad to EOF
; (linux won't load ELF without this)
dq 0

eof:
