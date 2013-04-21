myhexdump: myhexdump.o
	ld -m elf_i386 -o myhexdump myhexdump.o
myhexdump.o: myhexdump.asm
	nasm -f elf myhexdump.asm
