all : pong

pong.o: pong.s
	yasm -g dwarf2 -f elf64 pong.s

pong: pong.o
	ld -lraylib -o pong pong.o --dynamic-linker /lib64/ld-linux-x86-64.so.2
