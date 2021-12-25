build:
nasm -f elf64 -o hi.o hi.s && ld -s -nostdinc -static -o ./hi{,.o}
