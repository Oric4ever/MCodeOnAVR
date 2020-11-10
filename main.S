#include <avr/io.h>
#include <avr/interrupt.h>
#include "regdefs.h"
F_CPU = 18432000
BAUD = 38400
UBRR_VALUE = F_CPU/16/BAUD - 1
STACK = 0x04ff

.text
/*******************************************************
// GCC first inserts the interrupt vector table at address 0 :
    jmp $0038  // reset
    jmp $0042  // interrupt vector 2
    ...
    jmp $0042  // interrupt vector 28
// then the following reset routine at address $0038
    clr  r1
    out  SREG,r1
    ser  YL
    ldi  YH,4
    out  SPH,YH
    out  SPL,YL
    call main
    jmp  $146A  // points to a cli $ rjmp -1
// now that's the code for uninitialized interrupt routines
// (at address $0042)
    jmp  $0000
// and finally at address $0044 : my code
*/
    .global main
main:
    call uart0_init
    jmp  mcode_run

