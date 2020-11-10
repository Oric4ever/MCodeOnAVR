#include <avr/io.h>
#include <avr/interrupt.h>
#include "regdefs.h"

.global uart0_init, uart0_send, uart0_status, uart0_receive
.global uart0_space, uart0_newline, uart0_hexbyte, uart0_hexword

BAUD = 115200
UBRR_VALUE = F_CPU/16/BAUD - 1

.text

uart0_init: /* no param, no result */

    ldi   tmp, hi8(UBRR_VALUE)
    out   _SFR_IO_ADDR(UBRR0H), tmp
    ldi   tmp, lo8(UBRR_VALUE)
    out   _SFR_IO_ADDR(UBRR0L), tmp

    clr   tmp
    out   _SFR_IO_ADDR(UCSR0A), tmp
    ldi   tmp, _BV(TXEN0) | _BV(RXEN0) // | _BV(RXCIE0) for interrupt
    out   _SFR_IO_ADDR(UCSR0B), tmp
    ldi   tmp, _BV(URSEL0) | _BV(UCSZ01) | _BV(UCSZ00) // 8 bit data
    out   _SFR_IO_ADDR(UCSR0C), tmp

    in    tmp, _SFR_IO_ADDR(UCSR0A)
    andi  tmp, _BV(RXC0)
    breq  1f
    in    tmp, _SFR_IO_ADDR(UDR0)
1:  sei
    ret

uart0_newline:
    ldi   tmp,0x0d
    rcall uart0_send
    ldi   tmp,0x0a
    rjmp  uart0_send

uart0_space:
    ldi   tmp,' '
uart0_send: /* param: tmp, no result */
    sbis  _SFR_IO_ADDR(UCSR0A), UDRE0
    rjmp  uart0_send
    out   _SFR_IO_ADDR(UDR0), tmp
    ret
    
uart0_hexword: /* param: tmp, no result */
    push  tmp
    mov   tmp,tmpH
    rcall uart0_hexbyte
    pop   tmp
uart0_hexbyte: /* param: tmp, no result */
    push  tmp
    swap  tmp
    rcall uart0_hexdigit
    pop   tmp
uart0_hexdigit:
    andi  tmp,0x0f
    cpi   tmp,10
    brlo  1f
    subi  tmp,-7
1:  subi  tmp,-48
    rjmp  uart0_send


uart0_status:
    in    tmp,_SFR_IO_ADDR(UCSR0A)  // TODO: handle errors
    lsl   tmp                       // shift RXC in carry
    clr   tmp
    sbc   tmp,Zero                  // return 0xFF if char received
    ret

uart0_receive:
    sbis  _SFR_IO_ADDR(UCSR0A), RXC0
    rjmp  uart0_receive
    in    tmp,_SFR_IO_ADDR(UDR0)
    ret

    
