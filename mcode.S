#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

.global mcode_run, full_fetch, Error, OpcodeTable, LoadOverlay
.text

#define LOADPROCADDR PROCS SUBB(op) SUBB(op) LOAD ADD(tmp) PUSH1(Y)
Op_02: IMMB(op) GLOBAL LOADPROCADDR FETCH

#define GETPARAM(n)     LOCAL LOAD_IDX(n) PUSH
#define SETPARAM(n)     POP LOCAL STORE_IDX(n)
Op_03: GETPARAM(3) FETCH
Op_04: GETPARAM(4) FETCH
Op_05: GETPARAM(5) FETCH
Op_06: GETPARAM(6) FETCH
Op_07: GETPARAM(7) FETCH

#define DLOADLOCAL    LOCAL   IMMS(tmp) SHL1 ADD(tmp) DLOADPUSH
#define DLOADGLOBAL   GLOBAL  IMMZ(tmp) SHL1 ADD(tmp) DLOADPUSH
#define DLOADSTACKIDX PPOP    IMMZ(tmp) SHL1 ADD(tmp) DLOADPUSH
#define DLOADEXTERN   MODULEm IMMZ(tmp) SHL1 ADD(tmp) DLOADPUSH
Op_08: DLOADLOCAL    FETCH
Op_09: DLOADGLOBAL   FETCH
Op_0a: DLOADSTACKIDX FETCH
Op_0b: DLOADEXTERN   FETCH

#define GETXTERNWORD1 IMM_NIBBLES MODULE ADDB(op2) LOAD PUSH
Op_0c: GETXTERNWORD1 FETCH


#define LOADSTACKIDXBYTE  POP PPOP ADD(tmp) LOADBYTE PUSHBYTE
#define LOADSTACKIDXWORD  POP PPOP SHL1 ADD(tmp) LOAD PUSH
#define LOADSTACKIDXDWORD POP PPOP SHL2 ADD(tmp) DLOADPUSH
Op_0d: LOADSTACKIDXBYTE  FETCH
Op_0e: LOADSTACKIDXWORD  FETCH
Op_0f: LOADSTACKIDXDWORD FETCH


#define LOADOUTERFRAME  LOCAL LOAD PUSH 
#define LOADOUTERFRAMEn IMMB(op) LOCAL 1: LOAD movw Y,tmp $ dec op $ brne 1b $ PUSH
Op_10: LOADOUTERFRAME  FETCH
Op_11: LOADOUTERFRAMEn FETCH

Op_12: rjmp Unimplemented   // LONGREAL opcodes

Op_13: SETPARAM(3) FETCH
Op_14: SETPARAM(4) FETCH
Op_15: SETPARAM(5) FETCH
Op_16: SETPARAM(6) FETCH
Op_17: SETPARAM(7) FETCH

#define DSTORELOCAL    DPOP LOCAL   IMMS(tmp) SHL1 ADD(tmp) DSTORE
#define DSTOREGLOBAL   DPOP GLOBAL  IMMZ(tmp) SHL1 ADD(tmp) DSTORE
#define DSTORESTACKIDX DPOP PPOP    IMMZ(tmp) SHL1 ADD(tmp) DSTORE
#define DSTOREXTERN    DPOP MODULEm IMMZ(tmp) SHL1 ADD(tmp) DSTORE
Op_18: DSTORELOCAL     FETCH
Op_19: DSTOREGLOBAL    FETCH
Op_1a: DSTORESTACKIDX  FETCH
Op_1b: DSTOREXTERN     FETCH

#define SETXTERNWORD1 IMM_NIBBLES MODULE ADDB(op2) POP STORE
Op_1c: SETXTERNWORD1   FETCH

#define STORESTACKIDXBYTE POP1(op) POP PPOP      ADD(tmp) st Y,op $
#define STORESTACKIDXWORD POP1(op) POP PPOP SHL1 ADD(tmp) STORE1(op)
#define STORESTACKIDXDWORD    DPOP POP PPOP SHL2 ADD(tmp) DSTORE
Op_1d: STORESTACKIDXBYTE  FETCH
Op_1e: STORESTACKIDXWORD  FETCH
Op_1f: STORESTACKIDXDWORD FETCH

Op_20: DUP  FETCH
Op_21: SWAP FETCH

#define GETLOCALVAR(n) LOCAL SUB_IDX(n) LOAD PUSH
#define SETLOCALVAR(n) LOCAL SUB_IDX(n) POP STORE

Op_22: GETLOCALVAR(2)  FETCH
Op_23: GETLOCALVAR(3)  FETCH
Op_24: GETLOCALVAR(4)  FETCH
Op_25: GETLOCALVAR(5)  FETCH
Op_26: GETLOCALVAR(6)  FETCH
Op_27: GETLOCALVAR(7)  FETCH
Op_28: GETLOCALVAR(8)  FETCH
Op_29: GETLOCALVAR(9)  FETCH
Op_2a: GETLOCALVAR(10) FETCH
Op_2b: GETLOCALVAR(11) FETCH

#define GETLOCALWORD    LOCAL   IMMS(tmp) SHL1 ADD(tmp) LOAD PUSH
#define GETGLOBALWORD   GLOBAL  IMMZ(tmp) SHL1 ADD(tmp) LOAD PUSH
#define GETSTACKIDXWORD PPOP    IMMZ(tmp) SHL1 ADD(tmp) LOAD PUSH
#define GETXTERNWORD2   MODULEm IMMZ(tmp) SHL1 ADD(tmp) LOAD PUSH
Op_2c: GETLOCALWORD    FETCH
Op_2d: GETGLOBALWORD   FETCH
Op_2e: GETSTACKIDXWORD FETCH
Op_2f: GETXTERNWORD2   FETCH

Error7: ERROR(7)
Error15: ERROR(15)

Op_31:  // copy string
    POP         // tmp = src size
    POP1(op2)   // op2 = dst size
    POP1(Y)     // source
    POP1(Z)     // dest
    tst  YH
    brne 1f
    tst  YL     // error 7 if NIL pointer
    breq Error7
    dec  YH     // remap page 0 to $ff00
1:  tst  ZH
    brne 2f
    tst  ZL     // error 7 if NIL pointer
    breq Error7
    dec  ZH     // remap page 0 to $ff00
    rjmp 2f
5:  ld   op,Y+
    tst  op
    breq 4f
    subi op2L,1
    sbc  op2H,Zero
    brcs Error15
    st   Z+,op
2:  subi tmpL,1
    sbc  tmpH,Zero
    brcc 5b
    rjmp 4f
3:  st   Z+,Zero
4:  subi op2L,1
    sbc  op2H,Zero
    brcc 3b
    FFETCH

Op_32: SETLOCALVAR(2)  FETCH
Op_33: SETLOCALVAR(3)  FETCH
Op_34: SETLOCALVAR(4)  FETCH
Op_35: SETLOCALVAR(5)  FETCH
Op_36: SETLOCALVAR(6)  FETCH
Op_37: SETLOCALVAR(7)  FETCH
Op_38: SETLOCALVAR(8)  FETCH
Op_39: SETLOCALVAR(9)  FETCH
Op_3a: SETLOCALVAR(10) FETCH
Op_3b: SETLOCALVAR(11) FETCH

#define SETLOCALWORD           LOCAL  IMMS(tmp) SHL1 ADD(tmp) POP STORE
#define SETGLOBALWORD          GLOBAL IMMZ(tmp) SHL1 ADD(tmp) POP STORE
#define SETSTACKIDXWORD POP1(op) PPOP IMMZ(tmp) SHL1 ADD(tmp) STORE1(op)
#define SETXTERNWORD          MODULEm IMMZ(tmp) SHL1 ADD(tmp) POP STORE
Op_3c: SETLOCALWORD    FETCH
Op_3d: SETGLOBALWORD   FETCH
Op_3e: SETSTACKIDXWORD FETCH
Op_3f: SETXTERNWORD    FETCH

Op_40: // Extended opcodes
    ldi  ZH,hi8(pm(ExtOpcodeTable))
    ld   ZL,X+
    ijmp

#define DLOADSTACKIND PPOP DLOADPUSH
Op_41: DLOADSTACKIND FETCH

#define GETGLOBALVAR(n) GLOBAL LOAD_IDX(n) PUSH
#define SETGLOBALVAR(n) GLOBAL POP STORE_IDX(n)

Op_42: GETGLOBALVAR(2)  FETCH
Op_43: GETGLOBALVAR(3)  FETCH
Op_44: GETGLOBALVAR(4)  FETCH
Op_45: GETGLOBALVAR(5)  FETCH
Op_46: GETGLOBALVAR(6)  FETCH
Op_47: GETGLOBALVAR(7)  FETCH
Op_48: GETGLOBALVAR(8)  FETCH
Op_49: GETGLOBALVAR(9)  FETCH
Op_4a: GETGLOBALVAR(10) FETCH
Op_4b: GETGLOBALVAR(11) FETCH
Op_4c: GETGLOBALVAR(12) FETCH
Op_4d: GETGLOBALVAR(13) FETCH
Op_4e: GETGLOBALVAR(14) FETCH
Op_4f: GETGLOBALVAR(15) FETCH

Op_50: // End program, return to Shell
    ldi  opH, hi8(0x030A)
    ldi  opL, lo8(0x030A)
    ldi  op2H,hi8(0x0308)
    ldi  op2L,lo8(0x0308)
    call Transfer
    // hopefully, the halted coroutine will never be resumed to

Ext_01: // Enter monitor
    in tmp,_SFR_IO_ADDR(SREG)
    PUSHBYTE
    cli
    FFETCH
// old version:
// push "interrupts-disabled-flag", then disable interrupts
//    lds  tmp,0x0314
//    PUSHBYTE
//    ldi  tmp,1
//    rjmp restore_flag
Ext_02: // Exit monitor
    POP
    out _SFR_IO_ADDR(SREG),tmp
    FFETCH
// old version:
// pop "interrupts-disabled-flag": 0=Enable 1=Disable
//    POP
//restore_flag:
//    sts  0x0314,tmp
//    FFETCH

#define DSTORESTACKIND DPOP PPOP DSTORE
Op_51: DSTORESTACKIND FETCH

Op_52: SETGLOBALVAR(2)  FETCH
Op_53: SETGLOBALVAR(3)  FETCH
Op_54: SETGLOBALVAR(4)  FETCH
Op_55: SETGLOBALVAR(5)  FETCH
Op_56: SETGLOBALVAR(6)  FETCH
Op_57: SETGLOBALVAR(7)  FETCH
Op_58: SETGLOBALVAR(8)  FETCH
Op_59: SETGLOBALVAR(9)  FETCH
Op_5a: SETGLOBALVAR(10) FETCH
Op_5b: SETGLOBALVAR(11) FETCH
Op_5c: SETGLOBALVAR(12) FETCH
Op_5d: SETGLOBALVAR(13) FETCH
Op_5e: SETGLOBALVAR(14) FETCH
Op_5f: SETGLOBALVAR(15) FETCH

#define LOADSTACKIND        PPOP LOAD PUSH 
#define LOADSTACKINDEXED(n) PPOP LOAD_IDX(n) PUSH
#define STORESTACKIND        POP PPOP STORE
#define STORESTACKINDEXED(n) POP PPOP STORE_IDX(n)

Op_60: LOADSTACKIND         FETCH
Op_61: LOADSTACKINDEXED(1)  FETCH
Op_62: LOADSTACKINDEXED(2)  FETCH
Op_63: LOADSTACKINDEXED(3)  FETCH
Op_64: LOADSTACKINDEXED(4)  FETCH
Op_65: LOADSTACKINDEXED(5)  FETCH
Op_66: LOADSTACKINDEXED(6)  FETCH
Op_67: LOADSTACKINDEXED(7)  FETCH
Op_68: LOADSTACKINDEXED(8)  FETCH
Op_69: LOADSTACKINDEXED(9)  FETCH
Op_6a: LOADSTACKINDEXED(10) FETCH
Op_6b: LOADSTACKINDEXED(11) FETCH
Op_6c: LOADSTACKINDEXED(12) FETCH
Op_6d: LOADSTACKINDEXED(13) FETCH
Op_6e: LOADSTACKINDEXED(14) FETCH
Op_6f: LOADSTACKINDEXED(15) FETCH

Op_70: STORESTACKIND         FETCH
Op_71: STORESTACKINDEXED(1)  FETCH
Op_72: STORESTACKINDEXED(2)  FETCH
Op_73: STORESTACKINDEXED(3)  FETCH
Op_74: STORESTACKINDEXED(4)  FETCH
Op_75: STORESTACKINDEXED(5)  FETCH
Op_76: STORESTACKINDEXED(6)  FETCH
Op_77: STORESTACKINDEXED(7)  FETCH
Op_78: STORESTACKINDEXED(8)  FETCH
Op_79: STORESTACKINDEXED(9)  FETCH
Op_7a: STORESTACKINDEXED(10) FETCH
Op_7b: STORESTACKINDEXED(11) FETCH
Op_7c: STORESTACKINDEXED(12) FETCH
Op_7d: STORESTACKINDEXED(13) FETCH
Op_7e: STORESTACKINDEXED(14) FETCH
Op_7f: STORESTACKINDEXED(15) FETCH

// OpcodeTable in the middle to benefit from rjmp range
.align 9
OpcodeTable:
#define _ rjmp stop $
#define M(code) rjmp Op_##code $
#define FLOAT _
#define DOUBL _

M(00) M(01) M(02) M(03) M(04) M(05) M(06) M(07) M(08) M(09) M(0a) M(0b) M(0c) M(0d) M(0e) M(0f)
M(10) M(11) DOUBL M(13) M(14) M(15) M(16) M(17) M(18) M(19) M(1a) M(1b) M(1c) M(1d) M(1e) M(1f)
M(20) M(21) M(22) M(23) M(24) M(25) M(26) M(27) M(28) M(29) M(2a) M(2b) M(2c) M(2d) M(2e) M(2f)
M(30) M(31) M(32) M(33) M(34) M(35) M(36) M(37) M(38) M(39) M(3a) M(3b) M(3c) M(3d) M(3e) M(3f)
M(40) M(41) M(42) M(43) M(44) M(45) M(46) M(47) M(48) M(49) M(4a) M(4b) M(4c) M(4d) M(4e) M(4f)
M(50) M(51) M(52) M(53) M(54) M(55) M(56) M(57) M(58) M(59) M(5a) M(5b) M(5c) M(5d) M(5e) M(5f)
M(60) M(61) M(62) M(63) M(64) M(65) M(66) M(67) M(68) M(69) M(6a) M(6b) M(6c) M(6d) M(6e) M(6f)
M(70) M(71) M(72) M(73) M(74) M(75) M(76) M(77) M(78) M(79) M(7a) M(7b) M(7c) M(7d) M(7e) M(7f)
M(80) M(81) M(82) M(83) M(84) M(85) M(86) M(87) M(88) M(89) M(8a) M(8b) M(8c) M(8d) M(8e) M(8f)
M(90) M(91) M(92) M(93) M(94) M(95) M(96) M(97) M(98) M(99) M(9a) M(9b) M(9c) M(9d) M(9e) M(9f)
M(a0) M(a1) M(a2) M(a3) M(a4) M(a5) M(a6) M(a7) M(a8) M(a9) M(aa) M(ab) M(ac) M(ad) M(ae) M(af)
M(b0) M(b1) M(b2) M(b3) M(b4) M(b5) M(b6) M(b7) M(b8) M(b9) M(ba) M(bb) M(bc) M(bd) M(be) M(bf)
M(c0) M(c1) M(c2) M(c3) M(c4) M(c5) M(c6) M(c7) M(c8) M(c9) M(ca) M(cb) M(cc) M(cd) M(ce) M(cf)
M(d0) M(d1) M(d2) M(d3) M(d4) M(d5) M(d6) M(d7) M(d8) M(d9) M(da) M(db) M(dc) M(dd) M(de) M(df)
M(e0) M(e1) M(e2) M(e3) M(e4) M(e5) M(e6) M(e7) M(e8) M(e9) M(ea) M(eb) M(ec) M(ed) M(ee) M(ef)
M(f0) M(f1) M(f2) M(f3) M(f4) M(f5) M(f6) M(f7) M(f8) M(f9) M(fa) M(fb) M(fc) M(fd) M(fe) M(ff)

ExtOpcodeTable:
    rjmp Ext_00
    rjmp Ext_01
    rjmp Ext_02
    rjmp Ext_03
    rjmp Ext_04
    rjmp Ext_05
    rjmp Ext_06
    rjmp Ext_07
    rjmp Ext_08
    rjmp Ext_09
    rjmp Ext_0a
    rjmp Ext_0b
    rjmp Ext_0c
    rjmp Ext_0d
    rjmp Ext_0e
    rjmp Ext_0f
    rjmp Ext_10
    rjmp Ext_11
    rjmp Ext_12

Op_87: // Z80 machine code
Op_00: // IllegalInstruction
    ldi  tmp,16
    rjmp Error

Error:
    PUSHBYTE // push error code
    PUSH0 
    PUSH0
Op_01:  // RAISE
    ldi   opL, lo8(0x0306)
    ldi   opH, hi8(0x0306)
    ldi   op2L,lo8(0x0304)
    ldi   op2H,hi8(0x0304)
    call  Transfer
    POP
    POP
    POP
    ret

NilPointer: ERROR(7)

trace_relay: jmp trace
Unimplemented:
stop:
    call trace
    call dump
1:  sleep
    rjmp 1b
    

#define ADDRLOCALWORD    LOCAL   IMMS(tmp) SHL1 ADD(tmp) PUSH1(Y)
#define ADDRGLOBALWORD   GLOBAL  IMMZ(tmp) SHL1 ADD(tmp) PUSH1(Y)
#define ADDRSTACKIDXWORD PPOP    IMMZ(tmp) SHL1 ADD(tmp) PUSH1(Y)
#define ADDRXTERNWORD    MODULEm IMMZ(tmp) SHL1 ADD(tmp) PUSH1(Y)
Op_80: ADDRLOCALWORD    FETCH
Op_81: ADDRGLOBALWORD   FETCH
Op_82: ADDRSTACKIDXWORD FETCH
Op_83: ADDRXTERNWORD    FETCH

#define LEAVE        \
    bst  tmp,7      $\
    LOCAL            \
    LOAD1(op2)       \
    LOAD1(Local)     \
    ld    XL,Y+      $\
    ld    XH,Y       $\
    lsl   tmp        $\
    add   YL,tmp     $\
    adc   YH,Zero    $\
    SETSP(Y)

Op_84: IMMB(tmp)           LEAVE           rjmp ReloadCallerModule
Op_85: IMMB(tmp)  POP1(op) LEAVE PUSH1(op) rjmp ReloadCallerModule
Op_86: IMMB(tmp)  DPOP     LEAVE DPUSH     rjmp ReloadCallerModule

Op_88:  // LEAVE TopLevel proc, remove 0 param 
Op_89:  // LEAVE TopLevel proc, remove 1 param
Op_8a:  // LEAVE TopLevel proc, remove 2 params
Op_8b:  // LEAVE TopLevel proc, remove 3 params
    mov  tmp,ZL
    andi tmp,0x83
    LEAVE
ReloadCallerModule:
    brtc  1f
    tst   op2H
    brne  2f
    tst   op2L
    breq  1f
    ERROR(10)       // tried to return from the main module
2:  movw  Global,op2
    GLOBAL
    ld    tmp,Y
    sbrc  tmp,0
    rcall LoadOverlay
1:  FETCH

#define CALL_FORWARD IMMB(tmp) PUSH1(X) add XL,tmp $ adc XH,Zero $
Op_8c:       CALL_FORWARD  FETCH
Op_8d: IMMB(tmp) PUSHBYTE  FETCH
Op_8e: IMMW(tmp) PUSH      FETCH
Op_8f: IMMD(op)  DPUSH     FETCH

#define LOADIMMBYTE(n) ldi tmp,n $ PUSHBYTE

Op_92: LOADIMMBYTE(2)  FETCH
Op_93: LOADIMMBYTE(3)  FETCH
Op_94: LOADIMMBYTE(4)  FETCH
Op_95: LOADIMMBYTE(5)  FETCH
Op_96: LOADIMMBYTE(6)  FETCH
Op_97: LOADIMMBYTE(7)  FETCH
Op_98: LOADIMMBYTE(8)  FETCH
Op_99: LOADIMMBYTE(9)  FETCH
Op_9a: LOADIMMBYTE(10) FETCH
Op_9b: LOADIMMBYTE(11) FETCH
Op_9c: LOADIMMBYTE(12) FETCH
Op_9d: LOADIMMBYTE(13) FETCH
Op_9e: LOADIMMBYTE(14) FETCH
Op_9f: LOADIMMBYTE(15) FETCH



#define IN_BITSET cpi op,16 $ cpc opH,Zero $ brsh False $ tst op $ breq 2f $ SHIFT_RIGHT 2: andi tmp,1 $
Op_e7: POP      POP1(op) IN_BITSET PUSHBYTE FETCH

False:
Op_90: PUSH0 FETCH


#define COMPARE         cp tmpL,opL $ cpc tmpH,opH $ 
#define COMPARE_INV     cp opL,tmpL $ cpc opH,tmpH $ 
#define EQUAL           COMPARE breq True $ rjmp False
#define NOT_EQUAL       COMPARE brne True $ rjmp False
#define LESS_THAN       COMPARE brlo True $ rjmp False
#define GREATER_OR_EQ   COMPARE brsh True $ rjmp False
#define GREATER_THAN    COMPARE_INV brlo True $ rjmp False
#define LESS_OR_EQ      COMPARE_INV brsh True $ rjmp False

#define ILESS_THAN      COMPARE brlt True $ rjmp False
#define IGREATER_OR_EQ  COMPARE brge True $ rjmp False
#define IGREATER_THAN   COMPARE_INV brlt True $ rjmp False
#define ILESS_OR_EQ     COMPARE_INV brge True $ rjmp False

#define EQUAL0      or tmpL,tmpH $ breq True $ rjmp False
#define NOT_ZERO    or tmpL,tmpH $ brne True $ rjmp False
#define NOT         com tmp $ andi tmp,1 $
#define COMPLEMENT  com tmpL $ com tmpH $
#define INC         adiw tmp,1 $
#define DEC         sbiw tmp,1 $
#define ADDITION    add tmpL,opL $ adc tmpH,opH $
#define SUBTRACT    sub tmpL,opL $ sbc tmpH,opH $
#define ADDITIONB   add tmpL,opL $ adc tmpH,Zero $
#define SUBTRACTB   sub tmpL,opL $ sbc tmpH,Zero $
#define MULTIPLY    mul op2L,opL $ movw tmp,r0 $ mul op2H,opL $ add tmpH,r0 $ mul opH,op2L $ add tmpH,r0 $ clr Zero $
#define DIVIDE      call div16u $
#define REMAINDER   call Remainder_U16 $
#define PUSH_TRUE   LOADIMMBYTE(1)
#define PUSH_FALSE  PUSH0

Op_a0: POP1(op) POP EQUAL
Op_a1: POP1(op) POP NOT_EQUAL
Op_a2: POP1(op) POP LESS_THAN
Op_a3: POP1(op) POP GREATER_THAN
Op_a4: POP1(op) POP LESS_OR_EQ
Op_a5: POP1(op) POP GREATER_OR_EQ
Op_ab:          POP EQUAL0
Op_cb:          POP NOT_ZERO
True:
Op_91:              LOADIMMBYTE(1) FETCH
Op_b2: POP1(op) POP ILESS_THAN
Op_b3: POP1(op) POP IGREATER_THAN
Op_b4: POP1(op) POP ILESS_OR_EQ
Op_b5: POP1(op) POP IGREATER_OR_EQ

Op_a6: POP1(op)  POP      ADDITION   PUSH       FETCH
Op_a7: POP1(op)  POP      SUBTRACT   PUSH       FETCH
Op_a8: POP1(op2) POP1(op) MULTIPLY   PUSH       FETCH
Op_a9: POP1(op)  POP      DIVIDE     PUSH       FETCH
Op_aa: POP1(op)  POP      DIVIDE     PUSH1(op2) FETCH
Op_ac:           POP      INC        PUSH       FETCH
Op_ad:           POP      DEC        PUSH       FETCH
Op_ae: IMMB(op)  POP      ADDITIONB  PUSH       FETCH
Op_af: IMMB(op)  POP      SUBTRACTB  PUSH       FETCH

#define ABS     tst tmpH $ brpl 1f $ com tmpL $ com tmpH $ INC $ 1: 
#define INTTOLONG  mov opUL,Zero $ sbrc opH,7 $ dec opUL $ mov opUH,opUL$
#define UMUL16_32       /* unsigned multiply 16x16=32 bits      */ $\
    clr     r2          /* new zero register                    */ $\
    mul     opH,op2H    /* multiply the MSBs                    */ $\
    movw    opU,r0      /* transfer the result to opU           */ $\
    mul     opL,op2L    /* multiply the LSBs                    */ $\
    movw    tmp,r0      /* transfer the result to tmp           */ $\
    mul     opH,op2L    /* multiply MSB1 with LSB2              */ $\
    add     tmpH,r0     /* add this product to final result     */ $\
    adc     opUL,r1                                                $\
    adc     opUH,r2                                                $\
    mul     op2H,opL    /* multiply MSB2 with LSB1              */ $\
    add     tmpH,r0     /* add this product to final result too */ $\
    adc     opUL,r1                                                $\
    adc     opUH,r2                                                $\
    clr     Zero                                                   $


#define IMUL16_32       /* signed multiplication 16x16=32 bits  */ $\
    clr     r2          /* new zero register                    */ $\
    muls    opH,op2H    /* multiply the MSBs                    */ $\
    movw    opU,r0      /* transfer the result to opU           */ $\
    mul     opL,op2L    /* multiply the LSBs                    */ $\
    movw    tmp,r0      /* transfer the result to tmp           */ $\
    mulsu   opH,op2L    /* multiply MSB1 with LSB2              */ $\
    sbc     opUH,r2                                                $\
    add     tmpH,r0     /* add this product to final result     */ $\
    adc     opUL,r1                                                $\
    adc     opUH,r2                                                $\
    mulsu   op2H,opL    /* multiply MSB2 with LSB1              */ $\
    sbc     opUH,r2                                                $\
    add     tmpH,r0     /* add this product to final result too */ $\
    adc     opUL,r1                                                $\
    adc     opUH,r2                                                $\
    clr     Zero                                                   $

#define IDIVIDE         call div16s $

Op_b0: IMMB(op)  POP      SHIFT_LEFT  PUSH  FETCH
Op_b1: IMMB(op)  POP      SHIFT_RIGHT PUSH  FETCH
Op_b6:           POP      NOT         PUSH  FETCH
Op_b7:           POP      COMPLEMENT  PUSH  FETCH
Op_b9: POP1(op)  POP      IDIVIDE     PUSH  FETCH
Op_bc:           POP      ABS         PUSH  FETCH
Op_bd:           POP1(op) INTTOLONG   DPUSH FETCH
Op_be: // LONG to REAL
    FPOP
    movw Y,X // save IP
    call floatsisf 
    movw X,Y // restore IP
    FPUSH 
    FFETCH // ZH modified by float routines
Op_bf: // REAL to LONG
    FPOP
    movw Y,X // save IP
    call fixsfsi // TODO: raise errors ?
    movw X,Y
    FPUSH 
    FFETCH // ZH modified by float routines

#define CHECKED_UADD add tmpL,opL $ adc tmpH,opH $ brcs Overflow $
#define CHECKED_USUB sub tmpL,opL $ sbc tmpH,opH $ brcs Overflow $
#define CHECKED_IADD add tmpL,opL $ adc tmpH,opH $ brvs Overflow $
#define CHECKED_ISUB sub tmpL,opL $ sbc tmpH,opH $ brvs Overflow $
#define CHECK_CARD or opUL,opUH $ brne Overflow $ 
#define CHECK_INT  mov tmp,opH  $ lsl tmp $ adc opUL,Zero $ adc opUH,Zero $ or opUL,opUH $ brne Overflow $ 
#define CHECK_INT2 mov opH,tmpH $ lsl opH $ adc opUL,Zero $ adc opUH,Zero $ or opUL,opUH $ brne Overflow $ 
Op_c0: POP1(op) POP CHECKED_UADD    PUSH FETCH
Op_c1: POP1(op) POP CHECKED_USUB    PUSH FETCH

Op_d0: POP1(op) POP CHECKED_IADD    PUSH FETCH
Op_d1: POP1(op) POP CHECKED_ISUB    PUSH FETCH

Op_ba:         DPOP CHECK_CARD PUSH1(op) FETCH
Op_bb:         DPOP CHECK_INT  PUSH1(op) FETCH

Overflow: ERROR(12)

Op_b8: POP1(op2) POP1(op) IMUL16_32 CHECK_INT2 PUSH FETCH
Op_c2: POP1(op2) POP1(op) UMUL16_32 CHECK_CARD PUSH FETCH

Op_c4: // string compare, mimic original behavior
    POP1(op2)       // str2 size
    POP1(op)        // str1 size
    POP1(Z)         // str2 address
    POP1(Y)         // str1 address
1:  clr  opU        // default to NUL char
    cp   opL,Zero   // if str1 size is 0
    cpc  opH,Zero
    breq 2f
    ld   opU,Y+     // otherwise get string char
2:  clr  op2U       // default to NUL char
    cp   op2L,Zero  // if str2 size is 0
    cpc  op2H,Zero
    breq 3f
    ld   op2U,Z+    // otherwise get string char
3:  cp   opU,op2U
    breq 4f
    brsh LongGreater
LongLess:   PUSH_FALSE PUSH_TRUE  FFETCH
4:  tst  opU
    breq LongEqual
    subi opL,1
    sbc  opH,Zero
    subi op2L,1
    sbc  op2H,Zero
    rjmp 1b

LongEqual:  PUSH_FALSE PUSH_FALSE FFETCH  // reload ZH for Op_c4
    
#define DCOMPLEMENT     com opL $ com opH $ com opUL $ com opUH $
#define DINC INC1(op) $ adc opUL,Zero $ adc opUH,Zero $
#define DADD add opL,op2L $ adc opH,op2H $ adc opUL,op2UL $ adc opUH,op2UH $
#define DSUB sub opL,op2L $ sbc opH,op2H $ sbc opUL,op2UL $ sbc opUH,op2UH $
#define DMUL rcall Multiply32x32 $
#define DDIV rcall div32s $
#define DMOD rcall div32s $

Op_c5: // LONGINT compare,  push op>op2 and then op<op2
    DPOP2 // => op2 
    DPOP  // => op
    DSUB  // => op - op2
    breq LongEqual
    brlt LongLess
LongGreater: PUSH_TRUE PUSH_FALSE FFETCH    // reload ZH for Op_c4

Op_d5: // REAL compare, push op>op2 and then op<op2
    FPOP2 // => op2
    FPOP  // => op
    movw  Y,X  // save IP
    call  cmpsf2
    movw  X,Y  // restore IP
    tst   r24
    breq  LongEqual
    brpl  LongGreater
    rjmp  LongLess

Op_c6: DPOP2 DPOP DADD DPUSH FETCH
Op_c7: DPOP2 DPOP DSUB DPUSH FETCH

#define DABS tst opUH $ brmi NegateLong $ 
#define DNEG com opUH $ com opUL $ com opH $ neg opL $ sbci opH,-1 $ sbci opUL,-1 $ sbci opUH,-1 $
Op_c8: DPOP2 DPOP DMUL DPUSH  FETCH
Op_c9: DPOP2 DPOP DDIV DPUSH  FETCH
Op_ca: DPOP2 DPOP DMOD DPUSH3 FETCH
Op_cc:       DPOP DABS DPUSH  FETCH
Ext_03:      DPOP
NegateLong:       DNEG DPUSH FFETCH

Op_cd: // table_jump
    IMMW(op)        // low bound
    IMMW(op2)       // high bound - low bound
    POP             // value
    subi tmpH,0x80  // for unsigned comparison
    sub  tmpL,opL   // substract low bound
    sbc  tmpH,opH
    brlo skip_case
    cp   op2L,tmpL  // compare with high bound too
    cpc  op2H,tmpH
    brlo skip_case
    IMMW(opU)       // relative addr of return
    add  opUL,XL    // calculate corresponding absolute addr
    adc  opUH,XH
    subi opUL,1
    sbc  opUH,Zero
    lsl  tmpL       // now calculate jump addr location
    rol  tmpH
    add  XL,tmpL
    adc  XH,tmpH
    ld   tmpL,X+    // load relative addr
    ld   tmpH,X
    add  XL,tmpL    // and jump !
    adc  XH,tmpH
    tst  tmpH       // push return addr if relative addr < 0
    brpl 1f
    PUSH1(opU)
1:  FETCH
skip_case:
    lsl  op2L       // skip the full jump table
    rol  op2H
    add  XL,op2L
    adc  XH,op2H
    adiw X,4
    FETCH

Op_ce: POP1(X) FETCH
Op_cf: IMMW(tmp) add tmpL,XL $ adc tmpH,XH $ sbiw tmp,1 $ PUSH FETCH

#define CHECK_STACK          \
    GETSP(Y)                 \
    SUB(tmp)                 \
    lds  op,StackLimit+1    $\
    cp   op,YH              $\
    brlo 1f                 $\
    brne StackOverflow      $\
    lds  op,StackLimit+0    $\
    cp   op,YL              $\
    brsh StackOverflow      $\
1:
    
//#define CHECK_STACK GETSP(Y) SUB(tmp) cp YL,StackLimitL $ cpc YH,StackLimitH $ brlo StackOverflow

Op_d2: // reserve bytes on stack, initialized to 0
    POP                 // number of bytes to reserve
    adiw tmp,1          // round number of bytes to even
    andi tmpL,0xFE
    CHECK_STACK
    lsr  tmpH           // convert to number of words to reserve
    ror  tmpL
reserve_loop:
    PUSH0
    DEC
    brne reserve_loop
    adiw Y,1            // adjust stack pointer due to AVR SP behavior
    PUSH1(Y)            // push address of reserved area
    FETCH

Ext_12:
Op_d3: // make a local copy of an array on stack
    POP1(Z)             // get addr of parameter
    tst ZH              // if in page 0, it's a fake parameter, feel free to move it
    brne 1f
    inc ZH
1:  POP                 // get number of bytes to reserve
    adiw tmp,1          // round number of bytes to even
    andi tmpL,0xFE
    add  ZL,tmpL        // prepare to copy the array backwards
    adc  ZH,tmpH
    CHECK_STACK
    lsr  tmpH           // convert to number of words to reserve
    ror  tmpL
copy_loop:
    ld   opH,-Z
    ld   opL,-Z
    PUSH1(op)
    DEC
    brne copy_loop
    adiw Y,1            // adjust stack pointer due to AVR SP behavior
    PUSH1(Y)            // push address of reserved area
    FFETCH              // restore ZH
    

StackOverflow: ERROR(6)

Op_d4:  // ENTER proc
        IMMB(tmpL)     // complemented nb of bytes to reserve for local vars
        PUSH1(Local)   // LOCAL[1]: previous Local
        push opH       // LOCAL[0]: outer frame or caller's global
        GETSP(Local)   // AVR's SP points to next byte to push
        push opL
        PUSH1(IP)      // LOCAL[-1]: addr of start of routine
        com  tmpL      // calculate the nb of bytes to reserve for local vars
        brne Reserve
                       // faster if no reservation to do, but still we
                       // check stack growth in case of infinite recursion
        lds  tmp,StackLimit+1
        cp   tmp,LocalH     // comparison of MSBs will be enough almost always
        brsh 1f
        FETCH
1:      brne StackOverflow
        lds  tmp,StackLimit // MSBs are equal, now compare LSBs
        cp   tmp,LocalL
        brsh StackOverflow
        FETCH
Reserve:
        movw Y,Local
        sub  YL,tmpL
        sbc  YH,Zero
        lds  tmp,StackLimit+1   // check if StackLimit is reached
        cp   tmp,YH      // comparing MSBs will be enough almost always
        brlo 1f
        brne StackOverflow
        lds  tmp,StackLimit
        cp   tmp,YL     // compare LSBs in case of tie
        brsh StackOverflow
1:                      // ok we can update stack pointer now 
//                      // Normal version :
//        sbiw Y,3      // take into account LOCAL[-1] and AVR's
//        SETSP(Y)      // stack pointer (points to next byte to push)
//        FETCH
//                      // Alternative version just to have deterministic TOP=0000
        sbiw Y,1        // LOCAL[-1] not taken into account
        SETSP(Y)        // set stack pointer
        PUSH0           // push the missing word with a defined 0 value
        FETCH

#define FADD  movw Y,X $ call addsf3 $ movw X,Y $
#define FSUB  movw Y,X $ call subsf3 $ movw X,Y $
#define FMUL  movw Y,X $ call mulsf3 $ movw X,Y $
#define FDIV  movw Y,X $ call divsf3 $ movw X,Y $

Op_d6:  FPOP2 FPOP FADD FPUSH FFETCH // ZH modified
Op_d7:  FPOP2 FPOP FSUB FPUSH FFETCH // ZH modified
Op_d8:  FPOP2 FPOP FMUL FPUSH FFETCH // ZH modified
Op_d9:  FPOP2 FPOP FDIV FPUSH FFETCH // ZH modified

#define COMPARE_HIGH add op2L,opL $ adc op2H,opH $ cp op2L,tmpL $ cpc op2H,tmpH $
#define CHECK_BOUNDS  COMPARE brlo Error2 $ COMPARE_HIGH brlo Error2 $
#define CHECK_BOUNDSI COMPARE brlt Error3 $ COMPARE_HIGH brlt Error3 $
#define CHECK_HIGH    COMPARE_INV brlt Error2b $ 
#define CHECK_POSITIVE tst tmpH $ brmi Error4 $
Op_da: POP1(op) POP1(op2) POP PUSH CHECK_BOUNDS   FETCH
Op_db: POP1(op) POP1(op2) POP PUSH CHECK_BOUNDSI  FETCH
Op_dc:          POP1(op)  POP PUSH CHECK_HIGH     FETCH
Op_dd:                    POP PUSH CHECK_POSITIVE FETCH

Error2:
    movw Z,op
    movw Y,op2
    ERROR(2)
Error2b:
    clr  ZL
    clr  ZH
    movw Y,op
    ERROR(2)
Error3:
    movw Z,op
    movw Y,op2
    ERROR(3)
Error4: ERROR(4)

#define BRANCH_IF_FALSE(label)  POP1(op) andi op,1 $ breq label $
#define ANDBRANCH               POP1(op) andi op,1 $ breq ShortCut $
#define ORBRANCH                POP1(op) andi op,1 $ brne ShortCut $
Op_de: IMMB(tmpL) ANDBRANCH FETCH
Op_df: IMMB(tmpL) ORBRANCH  FETCH
ShortCut: PUSH1(op) rjmp BranchForward

#define BRANCH_REL         add XL,tmpL $ adc XH,tmpH $
#define BRANCH_FORWARD     add XL,tmpL $ adc XH,Zero $
#define BRANCH_BACKWARD    sub XL,tmpL $ sbc XH,Zero $
Op_e0: IMMB(tmpL) ld tmpH,X // don't increment IP yet
Branch:  BRANCH_REL FETCH

Op_e1:    IMMW(tmp)  BRANCH_IF_FALSE(Branch_1) FETCH
Branch_1: sbiw X,1 $ BRANCH_REL FETCH

Op_e2: // branch forward unconditional
    IMMB(tmpL)
BranchForward: BRANCH_FORWARD FETCH

Op_e3: IMMB(tmpL) BRANCH_IF_FALSE(BranchForward) FETCH

Op_e4: // branch backwards unconditional
    IMMB(tmpL)
BranchBackward: BRANCH_BACKWARD FETCH

Op_e5: IMMB(tmpL) BRANCH_IF_FALSE(BranchBackward) FETCH

#define POWER2 LDIW(1) tst op $ breq 2f $ SHIFT_LEFT 2:
Op_e6: POP1(op) POP or tmpL,opL $ or tmpH,opH $ PUSH FETCH
Op_e8: POP1(op) POP and tmpL,opL $ and tmpH,opH $ PUSH FETCH
Op_e9: POP1(op) POP eor tmpL,opL $ eor tmpH,opH $ PUSH FETCH
Op_ea: POP1(op) POWER2 PUSH FETCH

#define JUMPPROC    ld XL,Y+ $ ld XH,Y $ add XL,YL $ adc XH,YH $
#define CALLTOP(n)                    PUSH1(IP) GLOBAL   PROCS SUB_IDX(n)          JUMPPROC CLR(op)
#define CALLTOPn             IMMB(op) PUSH1(IP) GLOBAL   PROCS SUBB(op)  SUBB(op)  JUMPPROC CLR(op)
#define CALLINNERn           IMMB(op) PUSH1(IP) GLOBAL   PROCS SUBB(op)  SUBB(op)  JUMPPROC movw op,Local $
#define CALLOUTERn POP1(op2) IMMB(op) PUSH1(IP) GLOBAL   PROCS SUBB(op)  SUBB(op)  JUMPPROC movw op,op2 $

Op_ec: CALLINNERn  FETCH
Op_ed: CALLTOPn    FETCH
Op_ee: CALLOUTERn  FETCH

Op_c3: // BDOS system call, module base and proc # must have been stored previously
    lds   YL,0xff10     // BDOS module
    lds   YH,0xff11
    lds   op2L,0xff12   // procedure number of BDOS
    lds   op2H,0xff13
    lsl   op2
    rjmp  OverlayTest
Op_eb: // call external procedure, module base and proc # on stack
    PPOP
    POP1(op2)
    lsl   op2
    rjmp  OverlayTest
Op_ef: // call external procedure, immediate module num and proc #
    MODULEm
    IMMB(op2)
    lsl   op2
    rjmp  OverlayTest
Op_f0: // call external procedure, compacted module num and proc #
    IMM_NIBBLES
    MODULE
OverlayTest:    // Y is module to call, op2 is procedure number
    PUSH1(IP)
    movw  op,Global     // op (caller module) will be saved in Op_d4 (ENTER)
    movw  Global,Y      // switch to called module
    ld    tmp,Y         // load module flags
    sbrc  tmp,0         // skip next rjmp if module is present 
    rjmp  ModuleIsSwapped
CallExtProc:
    PROCS
    SUBB(op2)
    JUMPPROC
    FETCH
    
ModuleIsSwapped:
    PUSH1(op2)          // save proc num x2
    movw  tmp,op        // save op (caller module)
    rcall LoadOverlay
    movw  op,tmp        // restore op
    POP1(op2)
    rjmp CallExtProc
    
LoadOverlay:    // Y is module to load
    PUSH        // save tmp
    ldi  tmp,1
    rcall Error
    POP         // restore tmp
    ret
    

Op_f1: CALLTOP(1)  FETCH
Op_f2: CALLTOP(2)  FETCH
Op_f3: CALLTOP(3)  FETCH
Op_f4: CALLTOP(4)  FETCH
Op_f5: CALLTOP(5)  FETCH
Op_f6: CALLTOP(6)  FETCH
Op_f7: CALLTOP(7)  FETCH
Op_f8: CALLTOP(8)  FETCH
Op_f9: CALLTOP(9)  FETCH
Op_fa: CALLTOP(10) FETCH
Op_fb: CALLTOP(11) FETCH
Op_fc: CALLTOP(12) FETCH
Op_fd: CALLTOP(13) FETCH
Op_fe: CALLTOP(14) FETCH
Op_ff: CALLTOP(15) FETCH

#define DROP POP
Ext_00: DROP FFETCH

Ext_04: // build field mask
    POP1(op) POWER2
    movw op2,tmp
    POP1(op) POWER2
    sub tmpL,op2L
    sbc tmpH,op2H
    PUSH
    FETCH
    
Ext_05: rjmp Allocate
Ext_06: rjmp Deallocate
Ext_07: rjmp Mark
Ext_08: rjmp Release
Ext_09: // FREEMEM()
    GETSP(tmp)
    lds opL,StackLimit+0
    lds opH,StackLimit+1
    sub tmpL,opL
    sbc tmpH,opH
    PUSH
    FFETCH

Ext_0a: POP1(op2) POP1(op) rcall Transfer $ FFETCH
Ext_0b: POP1(tmp) POP1(op2) POP1(op) rcall IOtransfer $ FFETCH
Ext_0c: rjmp NewProcess
Ext_0d: POP1(tmp) POP1(op) rcall BIOS $ FFETCH

Ext_0e: // SYSTEM.MOVE
    POP1(tmp)   // size
    POP1(Z)     // dest
    POP1(Y)     // src
    cp    tmpL,Zero
    cpc   tmpH,Zero
    breq  move_end
    tst   ZH
    brne  1f
    dec   ZH    // map page 0 to page FF
1:  tst   YH
    brne  2f
    dec   YH    // map page 0 to page FF
2:  cp    YL,ZL
    cpc   YH,ZH
    brsh  move_forward
                // copy bytes starting from the end
    add   YL,tmpL
    adc   YH,tmpH
    add   ZL,tmpL
    adc   ZH,tmpH
move_backward:
    ld    op,-Y
    st    -Z,op
    DEC
    brne  move_backward
    rjmp  move_end

Op_30:  // copy block 
    POP         // size 
    POP1(Y)     // source 
    POP1(Z)     // dest 
    cp   tmpL,Zero
    cpc  tmpH,Zero
    breq move_end
    tst  YH
    brne 1f
    dec  YH     // remap page 0 to $ff00
1:  tst  ZH
    brne move_forward
    dec  ZH     // remap page 0 to $ff00
move_forward:
    ld    op,Y+
    st    Z+,op
    DEC
    brne  move_forward
move_end:
    FFETCH


Ext_0f: // SYSTEM.FILL
    POP1(op)    // fill value
    POP1(tmp)   // size
    POP1(Z)     // start addr
    cp    tmpL,Zero
    cpc   tmpH,Zero
    breq  fill_end
    tst   ZH
    brne  fill_loop
    dec   ZH
fill_loop:
    st    Z+,opL
    DEC
    brne  fill_loop
fill_end:
    FFETCH

Ext_10: // SYSTEM.INP 
    POP1(Y)     // I/O addr
    adiw Y,0x20
    ld   tmpL,Y
    PUSHBYTE
    FFETCH

Ext_11: // SYSTEM.OUT
    POP1(tmp)   // value
    POP1(Y)     // I/O addr
    adiw Y,0x20
    st   Y,tmpL
    FFETCH

TestCode:
// fake module 0 at 0320:
//.word 0x0009 // proc1 relative addr
//.word 0xfffe // proc0 relative addr points to 0 byte
//.word 0x0322 // GLOBAL[-1] : absolute address of proc table
//.word 0      // GLOBAL[0] at 0326 : priority 1
//.word 0x1234 // GLOBAL[1]
                //// proc1:
//.byte 0xd4,0xff // enter
//.byte 0x88,0x00 // leave
//.byte 0x40,0x0A // leave inner function

// fake module 1 at 0330:

//.word 0x0326    // GLOBAL[-10]: module dependency 1 points to module 0 too
//.word 0x0326    // GLOBAL[-9] : module dependency 0
//.word 0         // GLOBAL[-8] : ?
//.ascii "MOD_NAME"// GLOBAL[-7..-4]
//.word 0         // GLOBAL[-3] : ?
//.word 0         // GLOBAL[-2] : ?
//.word 0x0320    // GLOBAL[-1] : address of proc table
//.word 0         // GLOBAL[0] at 0344
//.word 0         // GLOBAL[1] at 0346
//.word 0         // GLOBAL[2] at 0348
//.word 0         // GLOBAL[3] at 034A
//.word 0         // GLOBAL[4] at 034C
//.word 0         // GLOBAL[5] at 034E

// bytecode at 0350:
//.byte 0x40,0x05
//.byte 0x40,0x05
//.byte 0x40,0x05
//.byte 0x40,0x05
//.byte 0x40,0x06
//.byte 0x40,0x06
//.byte 0x40,0x06
//.byte 0x40,0x06
//.byte 0

.align 1    // enforces following code to be word-aligned !!

mcode_run:

/* some commented tests

#define PUSHIMM(val) ldi tmpH,hi8(val) $ push tmpH $ ldi tmpL,lo8(val) $ push tmpL $
//PUSHIMM(0x01)   // proc number
//PUSHIMM(0x0326) // module addr
//PUSHIMM(0x0370) // work addr
//PUSHIMM(0x0070) // work size
//PUSHIMM(0x0348) // process var addr
PUSHIMM(0x34E)
PUSHIMM(8)
PUSHIMM(0x34A)
PUSHIMM(8)
PUSHIMM(0x348)
PUSHIMM(8)
PUSHIMM(0x34C)
PUSHIMM(8)
PUSHIMM(0x34E)
PUSHIMM(8)
PUSHIMM(0x34C)
PUSHIMM(8)
PUSHIMM(0x34A)
PUSHIMM(8)
PUSHIMM(0x348)
PUSHIMM(8)
    ldi   YL,lo8(0x0320)
    ldi   YH,hi8(0x0320)
    ldi   ZL,lo8(TestCode)
    ldi   ZH,hi8(TestCode)
    ldi   tmpH,0x50
1:  lpm   tmp,Z+
    st    Y+,tmp
    dec   tmpH
    brne  1b

    ldi   IPL,lo8(0x0350)
    ldi   IPH,hi8(0x0350)
    ldi   tmpH, hi8(0x0370+60)
    ldi   tmpL, lo8(0x0370+60)
    sts   StackLimit+0,tmpL
    sts   StackLimit+1,tmpH
    ldi   tmpH, hi8(FREE_MARKER)
    ldi   tmpL, lo8(FREE_MARKER)
    sts   0x0370,tmpL
    sts   0x0371,tmpH
    sts   FreeList+0,Zero
    sts   FreeList+1,Zero
    FFETCH

*/

    lds   GlobalL,0x0312
    lds   GlobalH,0x0313

    clr   LocalL
    clr   LocalH
    inc   LocalL

    GLOBAL                              // jump to KERNEL's INIT
    PROCS
    JUMPPROC
    PUSH1(IP)       // so that KERNEL's INIT would be entered again in case it ends
    clr   opH
    ldi   opL,1     // saved Global will be 1
    rcall init_fetch_pointer    // push a return to full_fetch
full_fetch:
    FFETCH

init_fetch_pointer: // INCREDIBLE: the address on stack for (r)call/ret is in reverse order!!!
    POP                 // store the address of full_fetch so
    sts   0xff0c,tmpL   // that the kernel can return to it.
    sts   0xff0d,tmpH
    rjmp  full_fetch

