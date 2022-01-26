main: main.o
	ld -o $@ $^

main.o: main.s
	nasm -f elf64 -o $@ $^

clean:
	rm -f main main.o

.PHONY: clean
