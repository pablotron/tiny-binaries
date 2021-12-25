APP=hi

.PHONY=all clean

all: $(APP)

$(APP): hi.s
	nasm -f bin -o $(APP) hi.s 
	chmod a+x $(APP)

clean:
	$(RM) $(APP)
