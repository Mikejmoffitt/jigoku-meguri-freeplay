AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame
ROMDIR=/home/moffitt/.mame/roms

ASFLAGS=-i . -n -U -g

.PHONY: game_prg

all: game_prg

game_prg:
	$(AS) $(SRC) $(ASFLAGS) -o prg.o
	$(P2BIN) prg.o prg.bin -r \$$-0x3FFFF
	$(BSPLIT) s prg.bin cpu.even cpu.odd
	split -b 65536 cpu.even
	mv xaa b41-09-1.17
	mv xab b41-10.16
	split -b 65536 cpu.odd
	mv xaa b41-11-1.26
	mv xab b41-12.25
	rm cpu.odd
	rm cpu.even

test: game_prg
	$(MAME) -debug jigkmgri

zip: game_prg
	zip jigkmgri-free.zip b41-09-1.17 b41-10.16 b41-11-1.26 b41-12.25

clean:
	@-rm prg.bin
	@-rm prg.o
