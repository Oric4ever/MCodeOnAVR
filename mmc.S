#include <avr/io.h>

.global mmc_select, mmc_unselect, mmc_send_cmd
.text

/****************************************************
 MultiMediaCard interface : 
  implemented on SPI bus, with /CardSelect on PB4
  minimal set of routines designed to be called both from assembly and C
*****************************************************/
#define param4  r18
#define param4H r19
#define param3  r20
#define param3H r21
#define param2  r22
#define param2H r23
#define param1  r24
#define param1H r25
#define result  r24
#define resultH r25

// send MMC command in param1 register, followed by 32-bits argument in param2-3,
// and crc + stop bit in param4
// Can be called from C:
//   uses only call-used registers: r30-r31 (Z), r18-r25
mmc_send_cmd:
    mov   param4H,param1   // save command
    rcall mmc_select
    mov   param1,param4H
    rcall spi_write        // send MMC command
    mov   param1,param2H   // send MSB of argument
    rcall spi_write
    mov   param1,param2    // send 2nd byte of argument
    rcall spi_write
    mov   param1,param3H   // send 3rd byte
    rcall spi_write
    mov   param1,param3    // send LSB of argument
    rcall spi_write
    mov   param1,param4    // send CRC + stop bit
    rcall spi_write

    ldi   param2,10           // timeout of 10 tries
wait_response:
    rcall spi_read
    tst   result
    brpl  mmc_cmd_end
    dec   param2
    brne  wait_response
mmc_cmd_end:
    ret                    // return with response value

mmc_select:
	rcall mmc_unselect
    cbi   _SFR_IO_ADDR(PORTB),PORTB4 ; CARD_CS: low (activated)
	rjmp  spi_read

mmc_unselect:
    sbi   _SFR_IO_ADDR(PORTB),PORTB4 ; CARD_CS: high (disabled)
    ret



CMD0 = 0x40 + 0
CMD8 = 0x40 + 8

mmc_init:       // TODO: FIXME, this init does not work
    rcall spi_init      // initialize SPI and unselect card

    clr   param1
    call  hexbyte

    ldi   param2,100        // 10 ms tempo to let the card start after a power up
delay10ms:
    rcall delay_100us
    dec   param2
    brne  delay10ms
// send 80 clocks with card unselected to have it enter native SD mode
    ldi   param2,10      
dummy80clocks:
    ldi   param1,0xFF
    rcall spi_write
    dec   param2
    brne  dummy80clocks

    clr   param1
    call  hexbyte

    ldi   param1,CMD0      // soft reset (GO_IDLE_STATE): the card will enter SPI mode
    clr   param2
    clr   param2H
    clr   param3
    clr   param3H
    ldi   param4,0x95       // crc and stop bit for CMD0(0)
    rcall mmc_send_cmd
    call  hexbyte
    dec   result           // check response is 1
    brne  init_end      // failed to initialize

/*
    ldi   param1,CMD8      // SEND_IF_COND command
    ldi   param3L,0xAA
    ldi   param3H,1
    ldi   param4,0x87       // crc and stop bit for CMD8(0x1AA)
    rcall mmc_send_cmd
    call  hexbyte
    dec   result           // check response is 1
    brne  init_end      // failed to initialize
    rcall spi_read      // should be 0
    rcall spi_read      // should be 0
    rcall spi_read      // should be 1
    rcall spi_read      // should be 0xAA
 call  hexbyte
*/

    rcall spi_init2     // raise clock freq to the max: fcpu/2
init_end:
    rcall mmc_unselect
    ret





