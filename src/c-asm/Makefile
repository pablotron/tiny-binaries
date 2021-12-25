CFLAGS=-Os -W -Wall -Werror -Wextra -pedantic -std=c11
LDFLAGS=-s -static -nostartfiles -nostdlib -Wl,--build-id=none -Wl,--no-eh-frame-hdr -Wl,-nmagic -Wl,-s -Wl,--as-needed
APP=hi
OBJS=hi.o

.PHONY=all clean

all: $(APP)

$(APP): $(OBJS)
	$(CC) -o $(APP) $(LDFLAGS) $(OBJS)
	objcopy -R .note -R .comment -R .eh_frame $(APP)

%.o: %.c
	$(CC) -c $(CFLAGS) $<

clean:
	$(RM) -f $(OBJS) $(APP)
