CFLAGS=-Os -W -Wall -Werror -Wextra -pedantic
LDFLAGS=-static -Wl,-s
APP=hi
OBJS=hi.o

.PHONY=all clean

all: $(APP)

$(APP): $(OBJS)
	$(CC) $(LDFLAGS) -o $(APP) $(OBJS)

%.o: %.c
	$(CC) -c $(CFLAGS) $<

clean:
	$(RM) -f $(OBJS) $(APP)
