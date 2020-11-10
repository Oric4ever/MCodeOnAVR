#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

.global Transfer, IOtransfer, NewProcess, interrupt_handler
.text
trace_relay: jmp trace
Error5: ERROR(5)

NewProcess:
    POP1(opU)       // process variable addr
    POP1(op2)       // work size
    POP1(Z)         // work addr
    POP1(Y)         // module addr
    POP1(op)        // procedure number
    cpi   op2L,70   // check work size is at least 70 bytes
    cpc   op2H,Zero
    brlo  Error5
    ldi   op2UL,lo8(FREE_MARKER)
    ldi   op2UH,hi8(FREE_MARKER)
    st    Z,op2UL   // store a FREE_MARKER at the beginning
    std   Z+1,op2UH
    GETSP(op2U)     // save stack pointer
    add   op2L,ZL   // set the stack at the end of the work area
    adc   op2H,ZH
    subi  op2L,1    // minus 1, this is where push will go
    sbc   op2H,Zero
    SETSP(op2)
    PUSH0           // this one will be left on stack
    rcall NewProcessCont // push a return addr to next instruction
    // we will arrive here when the newprocess is transfered to
    movw  op,Z      // be sure that the outer frame is 1 because
    FFETCH          // the new process should fetch an ENTER opcode
NewProcessCont:
    movw  op2,Y     // save the module addr in op2, proc num is in op
    PUSH0           // word 15: tmp
    LOADIMMBYTE(128)// word 14: SREG and r0
    LOADIMMBYTE(1)  // word 13: Outer-frame=1 marks top frame (Z80's BC)
    LOADPROCADDR    // word 12: IP  // Caution! LOADPROCADDR uses op and tmp
    PUSH0           // word 11
    PUSH0           // word 10
    PUSH0           // word  9: Local
    PUSH0           // word  8
    PUSH0           // word  7
    PUSH0           // word  6
    PUSH0           // word  5: FreeList cleared
    adiw  Z,60
    PUSH1(Z)        // word  4: StackLimit at the start of work area + 60
    PUSH0           // word  3: "Interrupt Disable" flag cleared
    PUSH1(op2)      // word  2: Global
    PUSH0           // word  1
    PUSH0           // word  0
    
    movw  Y,opU     // process variable addr
    GETSP(tmp)
    adiw  tmp,1     // adjust pointer to have it point to word #0
    STORE

    SETSP(op2U)     // restore stack of creator process
    FFETCH          // and that's it
    

IOtransfer:     // interrupt vector number in tmp
                // Caution: table of coroutine pointers at FF00
                //  => some of them are used by absolute variables
                //  (e.g keyboard driver variables and buffer)

                // current coroutine to save to pointer op
                // (interrupt handler coroutine)
                // save pointer op for interrupt handler
    mov   ZL,tmpL   // tmp contains vector number
    lsl   ZL        // multiply by 4 to point to the two processes
    lsl   ZL
    ldi   ZH,0xFF
    st    Z+,op2L  // save the process to run until interrupt occurs
    st    Z+,op2H
    st    Z+,opL   // save this process, resume it when interrupt occurs
    st    Z+,opH

    cli         // disable interrupts during the transfer
    rcall interrupt_enable // enable the specific interrupt
    // and now do the TRANSFER

Transfer:   // save current coroutine to pointer op
            // then transfer to coroutine pointed by op2
            // Warning: registers r2-r7 are not saved

    PUSH            // word 15: tmp  (r24-25)
    in    tmp,_SFR_IO_ADDR(SREG)
    cli             // disable interrupts during coroutine transfer
    push  r0        // word 14: flags and r0
    push  tmp

    PUSH1(Z)        // word 13: Z    (r30-31) (takes the role of Z80's BC)
    PUSH1(X)        // word 12: IP   (r26-27) (same location as on Z80)
    PUSH1(op2U)     // word 11: op2U (r22-23)
    PUSH1(op2)      // word 10: op2  (r20-21)
    PUSH1(Local)    // word  9: Local(r12-13) (same location as on Z80)
    PUSH1(opU)      // word  8: opU  (r18-19)

    PUSH1(op)       // word  7: op   (r16-17)
Transfer_cont:
    PUSH1(op3U)     // word  6: op3U (r10-11)
    lds   ZL,FreeList 
    lds   ZH,FreeList+1 
    PUSH1(Z)        // word  5: FreeList
    lds   ZL,StackLimit
    lds   ZH,StackLimit+1
    PUSH1(Z)        // word  4: StackLimit 
    lds   tmp,0x0314// word  3: "Interrupt Disable" flag TODO: replace
    PUSHBYTE
    PUSH1(Global)   // word  2: Global (r14-15) (location as on Z80)
    PUSH1(op3)      // word  1: op3  (r8-9)
    PUSH1(Y)        // word  0: Y    (r28-29) (takes role of Z80's HL)

    movw  Y,op      // coroutine variable address
    GETSP(tmp)      // get SP and adjust it to point to word #0
    adiw  tmp,1 
    STORE           // save it in coroutine variable

    movw  Y,op2     // coroutine variable address
    LOAD1(Z)
    sbiw  Z,1       // ajust coroutine pointer to cope with AVR's SP
    SETSP(Z)        // warning, SETSP uses tmpH

    POP1(Z)         // word  0: Y, but keep it in Z for now
    POP1(op3)       // word  1: op3
    POP1(Global)    // word  2: Global
    POP             // word  3: "Interrupt Disable" flag TODO: replace
    sts   0x0314,tmp

    POP1(Y)         // word  4: StackLimit
    sts   StackLimit+0,YL
    sts   StackLimit+1,YH

    // verify start of heap is free
    sbiw  Y,60
    ld    opL,Y+
    ld    opH,Y+
    subi  opL,lo8(FREE_MARKER)
    sbci  opH,hi8(FREE_MARKER)
    brne  Error17   // corrupted memory

    
    POP1(Y)         // word  5: FreeList
    sts   FreeList+0,YL
    sts   FreeList+1,YH
    POP1(op3U)      // word  6: op3U
    POP1(op)        // word  7: op
    POP1(opU)       // word  8: opU
    POP1(Local)     // word  9: Local
    POP1(op2)       // word 10: op2
    POP1(op2U)      // word 11: op2U
    POP1(X)         // word 12: IP

    GLOBAL
    ld    tmpH,Y    // test bit 0 of GLOBAL[0]:
    sbrc  tmpH,0    // skip following call if bit 0 is clear
    call  LoadOverlay

    movw  Y,Z       // restore Y
    POP1(Z)         // word 13: Z
    pop   tmp       // word 14: flags and r0
    pop   r0
//    ori   tmp,0x80  // ADDED to force interrupts to be enabled
    out   _SFR_IO_ADDR(SREG),tmp // restore flags
    POP             // word 15: tmp
    ret

Error17: ERROR(17)

interrupt_handler:  // C registers already saved, e.g tmp and Z
    rcall interrupt_disable // tmp contains vector number
    mov   ZL,tmpL   // tmp still contains vector number
    lsl   ZL        // multiply by 4 to point to the two processes
    lsl   ZL
    ldi   ZH,0xFF
    push  opH       // Caution, op register is not saved yet
    push  opL
    ld    opL,Z+    // get pointer for main process
    ld    opH,Z+
    ld    op2L,Z+   // get pointer for interrupt handler process
    ld    op2H,Z+
    rcall Transfer
    pop   opL
    pop   opH
    ret

interrupt_enable: // tmp: vector number
    ldi   ZL,lo8(pm(int_enable_table))
    ldi   ZH,hi8(pm(int_enable_table))
    add   ZL,tmpL
    adc   ZH,tmpH
    ijmp

interrupt_disable: // tmp: vector number
    ldi   ZL,lo8(pm(int_disable_table))
    ldi   ZH,hi8(pm(int_disable_table))
    add   ZL,tmpL
    adc   ZH,tmpH
    ijmp


int_enable_table:
    rjmp  enable_nothing            // 0
    rjmp  enable_nothing            // 1 : RESET
    rjmp  enable_int0               // 2
    rjmp  enable_int1               // 3
    rjmp  enable_int2               // 4
    rjmp  enable_pcint0             // 5
    rjmp  enable_pcint1             // 6
    rjmp  enable_timer3_capt        // 7
    rjmp  enable_timer3_compA       // 8
    rjmp  enable_timer3_compB       // 9
    rjmp  enable_timer3_ovf         // 10
    rjmp  enable_timer2_comp        // 11
    rjmp  enable_timer2_ovf         // 12
    rjmp  enable_timer1_capt        // 13
    rjmp  enable_timer1_compA       // 14
    rjmp  enable_timer1_compB       // 15
    rjmp  enable_timer1_ovf         // 16
    rjmp  enable_timer0_comp
    rjmp  enable_timer0_ovf
    rjmp  enable_spi
    rjmp  enable_usart0_rxc
    rjmp  enable_usart1_rxc
    rjmp  enable_usart0_udre
    rjmp  enable_usart1_udre
    rjmp  enable_usart0_txc
    rjmp  enable_usart1_txc
    rjmp  enable_eeprom

int_disable_table:
    rjmp  disable_nothing
    rjmp  disable_nothing
    rjmp  disable_int0
    rjmp  disable_int1
    rjmp  disable_int2
    rjmp  disable_pcint0
    rjmp  disable_pcint1
    rjmp  disable_timer3_capt
    rjmp  disable_timer3_compA
    rjmp  disable_timer3_compB
    rjmp  disable_timer3_ovf
    rjmp  disable_timer2_comp
    rjmp  disable_timer2_ovf
    rjmp  disable_timer1_capt
    rjmp  disable_timer1_compA
    rjmp  disable_timer1_compB
    rjmp  disable_timer1_ovf
    rjmp  disable_timer0_comp
    rjmp  disable_timer0_ovf
    rjmp  disable_spi
    rjmp  disable_usart0_rxc
    rjmp  disable_usart1_rxc
    rjmp  disable_usart0_udre
    rjmp  disable_usart1_udre
    rjmp  disable_usart0_txc
    rjmp  disable_usart1_txc
    rjmp  disable_eeprom

#define SETIOBIT(io,bit) in ZL,_SFR_IO_ADDR(io) $ sbr ZL,_BV(bit) $ out _SFR_IO_ADDR(io),ZL
#define CLRIOBIT(io,bit) in ZL,_SFR_IO_ADDR(io) $ cbr ZL,_BV(bit) $ out _SFR_IO_ADDR(io),ZL
#define SETMMBIT(a,bit) lds ZL,_SFR_MEM_ADDR(a) $ sbr ZL,_BV(bit) $ sts _SFR_MEM_ADDR(a),ZL
#define CLRMMBIT(a,bit) lds ZL,_SFR_MEM_ADDR(a) $ cbr ZL,_BV(bit) $ sts _SFR_MEM_ADDR(a),ZL

enable_nothing:                                $ ret
enable_int0:            SETIOBIT(GICR,INT0)    $ ret
enable_int1:            SETIOBIT(GICR,INT1)    $ ret
enable_int2:            SETIOBIT(GICR,INT2)    $ ret
enable_pcint0:          SETIOBIT(GICR,PCIE0)   $ ret
enable_pcint1:          SETIOBIT(GICR,PCIE1)   $ ret
enable_timer3_capt:     SETMMBIT(ETIMSK,TICIE3)$ ret
enable_timer3_compA:    SETMMBIT(ETIMSK,OCIE3A)$ ret
enable_timer3_compB:    SETMMBIT(ETIMSK,OCIE3B)$ ret
enable_timer3_ovf:      SETMMBIT(ETIMSK,TOIE3) $ ret
enable_timer2_comp:     SETIOBIT(TIMSK,OCIE2)  $ ret
enable_timer2_ovf:      SETIOBIT(TIMSK,TOIE2)  $ ret
enable_timer1_capt:     SETIOBIT(TIMSK,TICIE1) $ ret
enable_timer1_compA:    SETIOBIT(TIMSK,OCIE1A) $ ret
enable_timer1_compB:    SETIOBIT(TIMSK,OCIE1B) $ ret
enable_timer1_ovf:      SETIOBIT(TIMSK,TOIE1)  $ ret
enable_timer0_comp:     SETIOBIT(TIMSK,TOIE0)  $ ret
enable_timer0_ovf:      SETIOBIT(TIMSK,OCIE0)  $ ret
enable_spi:             SETIOBIT(SPCR ,SPIE)   $ ret
enable_usart0_rxc:      SETIOBIT(UCSR0B,RXCIE0)$ ret
enable_usart1_rxc:      SETIOBIT(UCSR1B,RXCIE1)$ ret
enable_usart0_udre:     SETIOBIT(UCSR0B,UDRIE0)$ ret
enable_usart1_udre:     SETIOBIT(UCSR1B,UDRIE1)$ ret
enable_usart0_txc:      SETIOBIT(UCSR0B,TXCIE0)$ ret
enable_usart1_txc:      SETIOBIT(UCSR1B,TXCIE1)$ ret
enable_eeprom:          SETIOBIT(EECR,EERIE)   $ ret

disable_nothing:                               $ ret
disable_int0:           CLRIOBIT(GICR,INT0)    $ ret
disable_int1:           CLRIOBIT(GICR,INT1)    $ ret
disable_int2:           CLRIOBIT(GICR,INT2)    $ ret
disable_pcint0:         CLRIOBIT(GICR,PCIE0)   $ ret
disable_pcint1:         CLRIOBIT(GICR,PCIE1)   $ ret
disable_timer3_capt:    CLRMMBIT(ETIMSK,TICIE3)$ ret
disable_timer3_compA:   CLRMMBIT(ETIMSK,OCIE3A)$ ret
disable_timer3_compB:   CLRMMBIT(ETIMSK,OCIE3B)$ ret
disable_timer3_ovf:     CLRMMBIT(ETIMSK,TOIE3) $ ret
disable_timer2_comp:    CLRIOBIT(TIMSK,OCIE2)  $ ret
disable_timer2_ovf:     CLRIOBIT(TIMSK,TOIE2)  $ ret
disable_timer1_capt:    CLRIOBIT(TIMSK,TICIE1) $ ret
disable_timer1_compA:   CLRIOBIT(TIMSK,OCIE1A) $ ret
disable_timer1_compB:   CLRIOBIT(TIMSK,OCIE1B) $ ret
disable_timer1_ovf:     CLRIOBIT(TIMSK,TOIE1)  $ ret
disable_timer0_comp:    CLRIOBIT(TIMSK,TOIE0)  $ ret
disable_timer0_ovf:     CLRIOBIT(TIMSK,OCIE0)  $ ret
disable_spi:            CLRIOBIT(SPCR ,SPIE)   $ ret
disable_usart0_rxc:     CLRIOBIT(UCSR0B,RXCIE0)$ ret
disable_usart1_rxc:     CLRIOBIT(UCSR1B,RXCIE1)$ ret
disable_usart0_udre:    CLRIOBIT(UCSR0B,UDRIE0)$ ret
disable_usart1_udre:    CLRIOBIT(UCSR1B,UDRIE1)$ ret
disable_usart0_txc:     CLRIOBIT(UCSR0B,TXCIE0)$ ret
disable_usart1_txc:     CLRIOBIT(UCSR1B,TXCIE1)$ ret
disable_eeprom:         CLRIOBIT(EECR,EERIE)   $ ret

