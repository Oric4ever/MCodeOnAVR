AVRBIN=~/arduino-1.8.9/hardware/tools/avr/bin

GCCOPTS= -Wall -ffunction-sections -fdata-sections -Os
#GCCOPTS= -DTRACE=1 -Wall -ffunction-sections -fdata-sections -Os
AVROPTS= -mmcu=atmega162 -DF_CPU=18432000
LINKOPTS= -Wl,--gc-sections
OBJCOPYOPTS= --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0

INCS= regdefs.h macros.h
SRCS= main.c mcode.S heap.S process.S arith.S newbios.S trace.S spi.S mmc.S \
	  uart0.c input.c mmc_init.c interrupts.c keyboard.c english.c
# order of objects matters!
OBJS= mcode.o heap.o arith.o process.o newbios.o main.o trace.o spi.o mmc.o \
	  uart0.o input.o mmc_init.o interrupts.o keyboard.o english.o float/fplib.a

mcode.hex: mcode.elf
	$(AVRBIN)/avr-objcopy -O ihex -j .eeprom $(OBJCOPYOPTS) mcode.elf mcode.eep
	$(AVRBIN)/avr-objcopy -O ihex -R .eeprom mcode.elf mcode.hex
	$(AVRBIN)/avr-size mcode.elf

mcode.elf: $(SRCS) $(INCS)
	$(AVRBIN)/avr-gcc -c $(GCCOPTS) $(AVROPTS) $(SRCS)
	$(AVRBIN)/avr-gcc $(AVROPTS) $(LINKOPTS) -o mcode.elf $(OBJS)
# Save 516 bytes by using avr-ld directly:
#	$(AVRBIN)/avr-ld -e startup -o mcode.elf $(OBJS) --defsym __TEXT_REGION_LENGTH__=0x4000  

uart0.s: uart0.c
	$(AVRBIN)/avr-gcc $(GCCOPTS) $(AVROPTS) -S uart0.c

pcint.o: pcint.c
	$(AVRBIN)/avr-gcc $(GCCOPTS) $(AVROPTS) -c pcint.c

mcode.s: mcode.S
	clear
	$(AVRBIN)/avr-gcc -E $(AVROPTS) mcode.S > fff.s
	$(AVRBIN)/avr-gcc -c $(AVROPTS) -o mcode.elf fff.s

upload: mcode.hex
	$(AVRBIN)/avrdude -C /etc/avrdude.conf -p m162 -c usbasp -b 38400 \
		-u -V -U flash:w:mcode.hex

commit:
	git add *.S *.c *.h Makefile
	git commit

clean:
	rm mcode.elf mcode.hex mcode.eep *.o
