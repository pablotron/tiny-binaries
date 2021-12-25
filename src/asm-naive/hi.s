bits 64

global _start

section .rodata
  hi  db  "hi", 10
  len equ $ - hi

section .text

_start:
  mov rax, 1 ; write
  mov rdi, 1 ; fd
  mov rsi, hi ; msg
  mov rdx, len ; len
  syscall

  mov rax, 60 ; exit
  mov rdi, 0 ; exit code
  syscall
