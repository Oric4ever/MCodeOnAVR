AVRBIN=~/arduino-1.8.9/hardware/tools/avr/bin

GCCOPTS= -Wall -ffunction-sections -fdata-sections -Os
AVROPTS= -mmcu=atmega162 -DF_CPU=18432000
LINKOPTS= -Wl,--gc-sections
OBJCOPYOPTS= --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0

INCS= asmdef.h fp32def.h
SRCS= addsf3.S \
	  addsf3x.S \
	  cmpsf2.S \
	  divsf3.S \
	  divsf3x.S \
	  fixsfsi.S \
	  fixunssfsi.S \
	  floatsisf.S \
	  fp_cmp.S \
	  fp_inf.S \
	  fp_nan.S \
	  fp_pscA.S \
	  fp_pscB.S \
	  fp_round.S \
	  fp_split3.S \
	  fp_zero.S \
	  mulsf3.S \
	  mulsf3x.S

OBJS= addsf3.o \
	  addsf3x.o \
	  cmpsf2.o \
	  divsf3.o \
	  divsf3x.o \
	  fixsfsi.o \
	  fixunssfsi.o \
	  floatsisf.o \
	  fp_cmp.o \
	  fp_inf.o \
	  fp_nan.o \
	  fp_pscA.o \
	  fp_pscB.o \
	  fp_round.o \
	  fp_split3.o \
	  fp_zero.o \
	  mulsf3.o \
	  mulsf3x.o

fplib.a: $(SRCS) $(INCS) 
	$(AVRBIN)/avr-gcc -c $(GCCOPTS) $(AVROPTS) $(SRCS)
	$(AVRBIN)/avr-gcc-ar r fplib.a $(OBJS)

clean:
	rm fplib.a *.o
