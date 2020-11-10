#ifdef TRACE
#  define FETCH       rcall trace_relay  $  ijmp
#else
#  define FETCH       ld ZL,X+  $  ijmp
#endif 

#define FFETCH      ldi ZH,hi8(pm(OpcodeTable)) $ FETCH

#define GETSP(reg)  in reg##L,_SFR_IO_ADDR(SPL) $ in reg##H,_SFR_IO_ADDR(SPH) $
// SETSP disable interrupts during intermediate state of SP
#define SETSP(reg) \
    in   tmpH,_SFR_IO_ADDR(SREG)  $\
    cli                           $\
    out  _SFR_IO_ADDR(SPL),reg##L $\
    out  _SFR_IO_ADDR(SPH),reg##H $\
    out  _SFR_IO_ADDR(SREG),tmpH  $

#define IMMB(reg)   ld reg,X+ $
#define IMMZ(reg)   ld reg,X+ $ mov reg##H,Zero $
#define IMMS(r)     ld r,X+ $ mov r##H,Zero $ sbrc r,7 $ dec r##H $
#define IMMW(reg)   ld reg##L,X+ $ ld reg##H,X+ $
#define IMMD(r)     ld r##L,X+ $ ld r##H,X+ $ ld r##UL,X+ $ ld r##UH,X+ $
#define SPLIT       mov op2,tmp $ swap tmp $ andi tmp,15 $ andi op2,15 $
#define IMM_NIBBLES IMMB(tmp) SPLIT lsl tmp $ lsl op2 $

#define SUB_IDX(n)  sbiw Y,2*n $
#define SUB(reg)    sub YL,reg##L $ sbc YH,reg##H $
#define SUBB(reg)   sub YL,reg##L $ sbc YH,Zero $
#define SHL1        lsl tmpL $ rol tmpH $
#define SHL2        SHL1 SHL1
#define SHIFT_LEFT  1: lsl tmp $ rol tmpH $ dec op $ brne 1b $
#define SHIFT_RIGHT 1: lsr tmpH $ ror tmp $ dec op $ brne 1b $
#define ADD(reg)    add YL,reg##L $ adc YH,reg##H $
#define ADDB(reg)   add YL,reg##L $ adc YH,Zero $

#define LOCAL       movw Y,Local $
#define GLOBAL      movw Y,Global $
#define MODULE      GLOBAL SUB_IDX(9) SUBB(tmp) LOAD movw Y,tmp $
#define MODULEm     IMMB(tmp) lsl tmp $ MODULE

#define CHECKNIL    tst YH $ brne 1f $ dec YH $ tst YL $ brne 1f $ rjmp NilPointer $ 1:

#define PUSH1(reg)  push reg##H $ push reg##L $ 
#define PUSH        push tmpH $ push tmpL $
#define PUSHBYTE    push Zero $ push tmpL $
#define DPUSH       push  opUH $ push  opUL $ push  opH $ push  opL $
#define DPUSH3      push op3UH $ push op3UL $ push op3H $ push op3L $
#define FPUSH       push r25 $ push r24 $ push r23 $ push r22 $

#define POP1(reg)   pop reg##L $ pop reg##H $
#define POP         pop tmpL $ pop tmpH $
#define DPOP        pop  opL $ pop  opH $ pop  opUL $ pop  opUH $
#define DPOP2       pop op2L $ pop op2H $ pop op2UL $ pop op2UH $
#define FPOP        pop r22 $ pop r23 $ pop r24 $ pop r25 $
#define FPOP2       pop r18 $ pop r19 $ pop r20 $ pop r21 $
#define PPOP        pop YL $ pop YH $ CHECKNIL

#define LOAD        ld tmpL,Y+ $ ld tmpH,Y $
#define LOAD1(reg)  ld reg##L,Y+ $ ld reg##H,Y+ $
#define LOADBYTE    ld tmp,Y $
#define LOAD_IDX(n) ldd tmpL,Y+(2*n) $ ldd tmpH,Y+(2*n+1) $

#define STORE       st Y+,tmpL $ st Y+,tmpH $
#define STORE1(reg) st Y+,reg##L $ st Y+,reg##H $
#define STOREBYTE   st Y,tmp $
#define STORE_IDX(n) std Y+(2*n),tmpL $ std Y+(2*n+1),tmpH $

#define PUSH0     push Zero $ push Zero $
#define LDIW(val) ldi tmpH,hi8(val) $ ldi tmpL,lo8(val) $
#define CLR(reg)  clr reg##L $ clr reg##H $

#define ERROR(n)  ldi tmp,n $ jmp Error $

#define PROCS    ld tmpH,-Y $ ld tmpL,-Y $ movw Y,tmp $
#define LOADPROCADDR PROCS SUBB(op) SUBB(op) LOAD ADD(tmp) PUSH1(Y)
#define DLOADPUSH     LOAD_IDX(1) PUSH LOAD PUSH
#define DSTORE         STORE1(op) STORE1(opU)
#define DUP     POP PUSH PUSH
#define SWAP    POP POP1(op) PUSH PUSH1(op)
#define INC1(reg)   subi reg##L,-1 $ sbci reg##H,-1 $

#define LOADIMMBYTE(n) ldi tmp,n $ PUSHBYTE

#define FREE_MARKER 0x3ae3

