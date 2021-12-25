APP=hi

.PHONY=all clean

all: $(APP)

$(APP): hi.o
	ld -s -static -nostdinc -o $(APP) hi.o

%.o: %.s
	nasm -f elf64 -o hi.o hi.s

clean:
	$(RM) $(APP) hi.o
