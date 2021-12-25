__attribute__ ((noreturn)) void _start(void) {
  __asm(
    // "hi\n", encoded as 32-bit little-endian int
    "push $0x0a216968\n"

    "inc %al\n"         // write()
    "movw %ax, %di\n"   // fd
    "movq %rsp, %rsi\n" // msg
    "movb $4, %dl\n"    // len
    "syscall\n"

    "movb $60, %al\n"   // exit()
    "xor %edi, %edi\n"  // exit code
    "syscall"
  );

  // function won't return, omit "ret"
  __builtin_unreachable();
}
