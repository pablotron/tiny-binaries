bits 64

str:
  db "hi!", 10

main:
   lea rdi, [rel str]
   inc al
   mov edi, eax
   push 0x44556677
   push 0x00112233
