#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

#define TAB 0x09
#define WRITE(char) ldi tmp,char $ rcall uart0_send 
#define NEWLINE WRITE(0x0d) $ WRITE(0x0a)

.global trace, dump, Error, hexbyte, hexword, print_line_number, assert_fails
.text

trace:
    push  tmpH
    push  tmpL
    push  YH
    push  YL

    NEWLINE
    WRITE(TAB)

    WRITE('L')
    WRITE('O')
    WRITE('C')
    WRITE('A')
    WRITE('L')
    WRITE('=')
    movw  tmp,Local
    rcall hexword
    rcall space

    WRITE('G')
    WRITE('L')
    WRITE('O')
    WRITE('B')
    WRITE('A')
    WRITE('L')
    WRITE('=')
    movw  tmp,Global
    rcall hexword
    rcall space

/*
    WRITE('F')
    WRITE('R')
    WRITE('E')
    WRITE('E')
    WRITE('=')
    lds   tmpL,FreeList+0
    lds   tmpH,FreeList+1
    rcall hexword
    rcall space

*/
    WRITE('H')
    WRITE('E')
    WRITE('A')
    WRITE('P')
    WRITE('=')
    mov   tmpL,StackLimitL
    mov   tmpH,StackLimitH
    sbiw  tmp,60
    rcall hexword
    rcall space

    WRITE('L')
    WRITE('I')
    WRITE('M')
    WRITE('I')
    WRITE('T')
    WRITE('=')
    mov   tmpL,StackLimitL
    mov   tmpH,StackLimitH
    rcall hexword
    rcall space

    WRITE('S')
    WRITE('T')
    WRITE('A')
    WRITE('C')
    WRITE('K')
    WRITE('=')
    GETSP(tmp)
    adiw  tmp,7 // pre-incrementation + return addr + 4 saved regs 
    movw  Y,tmp
    rcall hexword
    rcall space

    WRITE('T')
    WRITE('O')
    WRITE('P')
    WRITE('=')
    ld    tmpL,Y+
    ld    tmpH,Y+
    rcall hexword
    rcall space
    
/*
    WRITE('[')
    WRITE('F')
    WRITE('9')
    WRITE('1')
    WRITE('0')
    WRITE(']')
    WRITE('=')
    lds   tmp,0xf910
    rcall hexbyte
    rcall space
*/

    NEWLINE
//    rcall tempo_1s
    NEWLINE

    WRITE('I')
    WRITE('P')
    WRITE('=')
    movw  tmp,IP
    rcall hexword
    rcall space
    
    WRITE('O')
    WRITE('P')
    WRITE('=')
    movw  Y,IP
    ld    tmp,Y+
    rcall hexbyte
    rcall space
    ld    tmp,Y+
    rcall hexbyte
    rcall space
    ld    tmp,Y+
    rcall hexbyte
    rcall space
    rcall newline

    pop   YL
    pop   YH
    pop   tmpL
    pop   tmpH
    ld    ZL,X+   // do the Fetch here, so that rcall trace replaces
    ret           // this ld ZL,X+ instruction

    
tempo_1s: /* 3 cycles per iteration => ~ 1 second at 18.432 MHz */
    ldi   tmp,94
    ldi   r23,192
1:  dec   r22
    brne  1b
    dec   r23
    brne  1b
    dec   tmp
    brne  1b
    ret

Error:
    push  tmp
    rcall newline
    WRITE('E')
    WRITE('R')
    WRITE('R')
    WRITE('O')
    WRITE('R')
    rcall space
    pop   tmp
    rcall print_num
    rjmp  stack_trace

module_write:
    rcall newline
    WRITE('M')
    WRITE('o')
    WRITE('d')
    WRITE('u')
    WRITE('l')
    WRITE('e')
    rcall space
    GLOBAL                  // module addr in Y
    sbiw  Y,14
    ldi   ZL,8
name_write:
    ld    tmp,Y+
    tst   tmp
    brne  non_nul
    ldi   tmp,' '
non_nul:
    rcall uart0_send
    dec   ZL
    brne  name_write
    rjmp space

search_proc:
    ldi   op,0              // proc num in op
    GLOBAL
    PROCS                   // proc table addr in Y and tmp
test_proc:
    ld    ZL,Y
    ldd   ZH,Y+1            // relative addr of proc #0 in Z
    sec
    adc   ZL,YL
    adc   ZH,YH             // absolute addr of proc #0 in Z
    cp    XL,ZL
    cpc   XH,ZH
    brsh  found_proc
search_loop:
    inc   op                // proc number += 1
    ld    ZH,-Y
    ld    ZL,-Y             // relative addr of proc #n in Z
    sec
    adc   ZL,YL
    adc   ZH,YH             // absolute addr of proc #n in Z
    cp    XL,ZL
    cpc   XH,ZH
    brsh  search_loop
    dec   op
    adiw  Y,2
    rjmp test_proc
found_proc:                 // proc num in op, proc addr in Z
    WRITE('p')
    WRITE('r')
    WRITE('o')
    WRITE('c')
    rcall space
    WRITE('#')
    mov   tmpL,op
    mov   tmpH,Zero
    rcall print_num
    rcall space
    rcall space
    WRITE('+')
    movw  tmp,X
    sub   tmpL,ZL
    sbc   tmpH,ZH
    rjmp  print_num
    
restore_global:
    movw  Global,op
stack_trace:
    sbiw  X,1           // IP was incremented in advance
    rcall module_write
    rcall search_proc
    movw  Y,Local       // Local ptr in Y
    ld    opL,Y+        // load outer frame in op
    ld    opH,Y+
    ld    LocalL,Y+     // load upper frame in Local
    ld    LocalH,Y+
    ld    XL,Y+         // load IP in X
    ld    XH,Y+
    tst   opH
    brne  restore_global
    tst   opL
    breq  stack_trace
    jmp   halt

dump:
    ldi   YH,3
    ldi   YL,0
1:  mov   tmp,YL
    andi  tmp,0x0F
    brne  2f
    rcall newline
2:  ld    tmp,Y
    rcall hexbyte
    rcall space
    inc   YL
    brne  1b
    inc   YH
    cpi   YH,4
    brne  1b
    ret

assert_fails:
    rcall newline
    WRITE('A')
    WRITE('s')
    WRITE('s')
    WRITE('e')
    WRITE('r')
    WRITE('t')
    rcall space
    WRITE('f')
    WRITE('a')
    WRITE('i')
    WRITE('l')
    WRITE('s')
    rcall space
    WRITE('l')
    WRITE('i')
    WRITE('n')
    WRITE('e')
    rcall space
    ld    tmpL,X+   // fetch line number
    ld    tmpH,X+
print_num:
    ldi  opL,10     // prepare to divide by 10
    ldi  opH,0
    cp   tmpL,opL
    cpc  tmpH,opH
    brlo last_digit
    call div16u     // quotient in tmp, remainder in op2
    push op2        // save remainder
    call print_num  // recurse on quotient
    pop  tmp        // restore remainder
last_digit:
    subi tmp,0xd0   // ie add 0x30
    rjmp uart0_send
    
newline:
    ldi   tmp,0x0d
    rcall uart0_send
    ldi   tmp,0x0a
    rjmp  uart0_send

space:
    ldi   tmp,' '
    rjmp  uart0_send

hexword: /* param: tmp, no result */
    push  tmp
    mov   tmp,tmpH
    rcall hexbyte
    pop   tmp
hexbyte: /* param: tmp, no result */
    push  tmp
    swap  tmp
    rcall hexdigit
    pop   tmp
hexdigit:
    andi  tmp,0x0f
    cpi   tmp,10
    brlo  1f
    subi  tmp,-7
1:  subi  tmp,-48
    rjmp  uart0_send


