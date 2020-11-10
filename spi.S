#include <avr/io.h>
#include "regdefs.h"

.text

.global spi_read
.global spi_write
.global delay_100us
.global spi_init
.global spi_init2

.func delay_100us
delay_100us:
	ldi	tmp, lo8(F_CPU / 100000)	/* Loop counter */
1:	/* 10 clocks per loop */
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	dec	 tmp
	brne 1b
	ret
.endfunc

.func spi_init
spi_init:
    sbi _SFR_IO_ADDR(DDRB),DDB4    ; SPI SS: output (to be sure SPI master remains selected)
    sbi _SFR_IO_ADDR(PORTB),PORTB4 ; SPI SS: high

    sbi _SFR_IO_ADDR(DDRB),DDB7    ; SCK : output
    sbi _SFR_IO_ADDR(DDRB),DDB5    ; MOSI : output
    ; Enable SPI, Master
    ; MSB transmitted first
    ; Clock Polarity: SCK low when idle
    ; Clock Phase: sampling on leading edge, setup on trailing edge
    ; Clock rate: fcpu/64 for initialization (250kHz)
    ldi tmp,_BV(SPE)|_BV(MSTR)|_BV(SPR1)
    out _SFR_IO_ADDR(SPCR),tmp
	ret
.endfunc

.func spi_init2
spi_init2:
    ; Clock rate: fcpu/4 for fast transfer
    ldi tmp,_BV(SPE)|_BV(MSTR)
    out _SFR_IO_ADDR(SPCR),tmp
    ; and even fcpu/2 with spi2x    => 8 MHz
    ldi tmp,_BV(SPI2X)
    out _SFR_IO_ADDR(SPSR),tmp
    ret
.endfunc
    
spi_read:
	ldi	tmp, 0xFF	; Send 0xFF when receiving data

// param : r24 byte to write
// result: r24-r25 byte received in exchange
spi_write:
    out  _SFR_IO_ADDR(SPDR),tmp
    clr  tmpH
Wait_Transmit:
    sbis _SFR_IO_ADDR(SPSR),SPIF
    rjmp Wait_Transmit
    in   tmp,_SFR_IO_ADDR(SPDR)
    ret

