#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

.global Multiply32x32, div16u, div16s, div32s
.text

;***************************************************************************
Multiply32x32:          // multiplication 32x32 bits
                        // result in tmp (low word) and Y (high word)
    clr     r2          // will be used as zero register
    mul     opL,op2L    // multiply the LSBs
    movw    tmp,r0      // transfer result to tmp
    mul     opH,op2H    // multiply the second bytes
    movw    Y,r0        // transfer result to Y
    mul     opH,op2L    // partial product of order 1
    add     tmpH,r0
    adc     YL,r1
    adc     YH,r2  
    mul     opUL,op2L   // partial product of order 2
    add     YL,r0
    adc     YH,r1
    mul     opUH,op2L   // partial product of order 3
    add     YH,r0
    mul     opL,op2H    // partial product of order 1
    add     tmpH,r0
    adc     YL,r1
    adc     YH,r2
    mul     opUL,op2H   // partial product of order 3
    add     YH,r0
    mul     opL,op2UL   // partial product of order 2
    add     YL,r0
    adc     YH,r1
    mul     opH,op2UL   // partial product of order 3
    add     YH,r0
    mul     opL,op2UH   // partial product of order 3
    add     YH,r0
    movw    op,tmp
    movw    opU,Y
    clr     Zero        // restore Zero register
    ret

;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division from AVR Application Note #200
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd16uH:dd16uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words  :19
;* Number of cycles :235/251 (Min/Max)
;* Low registers used   :2 (drem16uL,drem16uH)
;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;*              dcnt16u)
;*
;***************************************************************************

;***** Subroutine Register Variables

#define drem16uL op2L
#define drem16uH op2H
#define dres16uL tmpL
#define dres16uH tmpH
#define dd16uL   tmpL
#define dd16uH   tmpH
#define dv16uL   opL
#define dv16uH   opH
#define dcnt16u  ZL

;***** Code

div16u:
    clr     drem16uL            ;clear remainder Low byte
    sub     drem16uH,drem16uH   ;clear remainder High byte and carry
    ldi     dcnt16u,17          ;init loop counter
d16u_1:
    rol     dd16uL              ;shift left dividend
    rol     dd16uH
    dec     dcnt16u             ;decrement counter
    brne    d16u_2              ;if done
    ret                         ;    return
d16u_2: 
    rol     drem16uL            ;shift dividend into remainder
    rol     drem16uH
    sub     drem16uL,dv16uL     ;remainder = remainder - divisor
    sbc     drem16uH,dv16uH     ;
    brcc    d16u_3              ;if result negative
    add     drem16uL,dv16uL     ;    restore remainder
    adc     drem16uH,dv16uH
    clc                         ;    clear carry to be shifted into result
    rjmp    d16u_1              ;else
d16u_3: 
    sec                         ;    set carry to be shifted into result
    rjmp    d16u_1
    
;***************************************************************************
;*
;* "div16s" - 16/16 Bit Signed Division from AVR Application Note #200
;*
;* This subroutine divides the two 16 bit signed numbers 
;* "dd16sH:dd16sL" (dividend) and "dv16sH:dv16sL" (divisor). 
;* The result is placed in "dres16sH:dres16sL" and the remainder in
;* "drem16sH:drem16sL".
;*  
;* Number of words  :39
;* Number of cycles :247/263 (Min/Max)
;* Low registers used   :3 (d16s,drem16sL,drem16sH)
;* High registers used  :7 (dres16sL/dd16sL,dres16sH/dd16sH,dv16sL,dv16sH,
;*              dcnt16sH)
;*
;***************************************************************************

;***** Subroutine Register Variables

#define    d16s     op2U
#define    drem16sL op2L
#define    drem16sH op2H
#define    dres16sL tmpL
#define    dres16sH tmpH
#define    dd16sL   tmpL
#define    dd16sH   tmpH
#define    dv16sL   opL
#define    dv16sH   opH
#define    dcnt16s  ZL

;***** Code

div16s:
    mov     d16s,dd16sH ;move dividend High to sign register
    eor     d16s,dv16sH ;xor divisor High with sign register
    sbrs    dd16sH,7    ;if MSB in dividend set
    rjmp    d16s_1
    com     dd16sH      ;    change sign of dividend
    neg     dd16sL      
    sbci    dd16sH,-1
d16s_1: 
    sbrs    dv16sH,7    ;if MSB in divisor set
    rjmp    d16s_2
    com     dv16sH      ;    change sign of divisor
    neg     dv16sL      
    sbci    dv16sH,-1
d16s_2: 
    clr     drem16sL    ;clear remainder Low byte
    sub     drem16sH,drem16sH;clear remainder High byte and carry
    ldi     dcnt16s,17  ;init loop counter

d16s_3: 
    rol     dd16sL      ;shift left dividend
    rol     dd16sH
    dec     dcnt16s     ;decrement counter
    brne    d16s_5      ;if done
    sbrs    d16s,7      ;    if MSB in sign register set
    rjmp    d16s_4

    com     dres16sH    ;      start changing sign of result by complementing high byte
    tst     drem16sL    ; test if remainder is non nul
    brne    d16s_4b
    tst     drem16sH
    brne    d16s_4b
                        ; remainder is nul, finish changing sign of result
    neg     dres16sL
    sbci    dres16sH,-1
d16s_4: 
    ret         ;    return
d16s_4b:                ; remainder is not nul, finish 1-complement of result
    com     dres16sL
    sub     dv16sL,drem16sL ; and complement modulo
    sbc     dv16sH,drem16sH
    movw    drem16sL,dv16sL
    ret
d16s_5: 
    rol     drem16sL    ;shift dividend into remainder
    rol     drem16sH
    sub     drem16sL,dv16sL ;remainder = remainder - divisor
    sbc     drem16sH,dv16sH ;
    brcc    d16s_6      ;if result negative
    add     drem16sL,dv16sL ;    restore remainder
    adc     drem16sH,dv16sH
    clc         ;    clear carry to be shifted into result
    rjmp    d16s_3      ;else
d16s_6: 
    sec         ;    set carry to be shifted into result
    rjmp    d16s_3

;***************************************************************************
;*
;* 32/32 Bit Signed Division

div32s: // Signed 32 bits division: divide op by op2
        // result in op2, remainder in op3
#define sign tmpH
#define loopcount tmp
    mov     sign,opUH   ;move dividend High to sign register
    eor     sign,op2UH  ;xor with divisor High
    sbrc    opUH,7      ;negate dividend if negative
    rcall   negateDividend
    sbrc    op2UH,7     ;negate divisor if negative
    rcall   negateDivisor
    clr     op3L        ; clear remainder
    clr     op3H
    clr     op3UL
    clr     op3UH
    ldi     loopcount,33  ;init loop counter
div32loop0:             ; enter a 0 in the result
    clc
div32loop:      // 32*22 = 704 cycles max, 32*17 = 544 cycles min
    rol     opL         ; left shift result (and dividend)
    rol     opH
    rol     opUL
    rol     opUH
    dec     loopcount
    breq    div32end
    rol     op3L        ; and overflow into remainder
    rol     op3H
    rol     op3UL
    rol     op3UH
    cp      op3L, op2L     ; compare with divisor
    cpc     op3H, op2H
    cpc     op3UL,op2UL
    cpc     op3UH,op2UH
    brlo    div32loop0
    sub     op3L, op2L     ; substract divisor
    sbc     op3H, op2H
    sbc     op3UL,op2UL
    sbc     op3UH,op2UH
    sec
    rjmp    div32loop   ; enter a 1 in the result
div32end:
    sbrs    sign,7      ; skip return and negate result if negative
    ret
negateDividend:             ; negate dividend (or result)
    com     opUH
    com     opUL
    com     opH
    neg     opL
    sbci    opH,-1
    sbci    opUL,-1
    sbci    opUH,-1
    ret
negateDivisor:            ; change sign of divisor
    com     op2UH
    com     op2UL
    com     op2H
    neg     op2L
    sbci    op2H,-1
    sbci    op2UL,-1
    sbci    op2UH,-1
    ret

;***************************************************************************
; division by 10, 16-bits dividend in op
; Result: quotient in op, remainder in op2
; 37 cycles

div10:
    movw    tmp,op
    movw    op2,op
    asr     tmpH        ; n/2 in tmp
    ror     tmpL
    movw    op,tmp      ; n/2 in op
    asr     tmpH
    ror     tmpL        ; n/4 in tmp
    add     opL,tmpL
    adc     opH,tmpH    ; n * 3/4 in op
    movw    tmp,op
    asr     tmpH
    ror     tmpL        ; n * 3/8 in tmp
    asr     tmpH
    ror     tmpL        ; n * 3/16 in tmp
    asr     tmpH
    ror     tmpL        ; n * 3/32 in tmp
    asr     tmpH
    ror     tmpL        ; n * 3/64 in tmp
    add     opL,tmpL
    adc     opH,tmpH    ; n * 51/64 in op
    add     opL,opH
    adc     opH,Zero    ; n * 13107/16384 in op, let's div by 8 to get 1/10
    movw    tmp,op      ; so that's div10(n) * 8
    asr     opH
    ror     opL
    asr     opH
    ror     opL         ; and that's div10(n) * 2
    add     tmpL,opL
    adc     tmpH,opH    ; and thus, that's div10(n)*10
    sub     op2L,tmpL
    sbc     op2H,tmpH   ; and thus n - (n div 10)*10 in op2
    asr     opH
    ror     opL         ; and n div 10 in op
    ret
