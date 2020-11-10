#define Zero    r1
// r2 will be used as zero register in multiply routines

#define FreeList    0x0318
#define StackLimit  0x0316

// warning: r2-r17 must be preserved in routines called from C
#define op3     r8
#define op3L    r8
#define op3H    r9
#define op3UL   r10
#define op3UH   r11
#define Local   r12
#define LocalL  r12
#define LocalH  r13
#define Global  r14
#define GlobalL r14
#define GlobalH r15
#define op      r16
#define opL     r16
#define opH     r17

// warning: C routines might clobber r18-r27
// so these have to be saved
#define opU     r18
#define opUL    r18
#define opUH    r19
#define op2     r20
#define op2L    r20
#define op2H    r21
#define op2U    r22
#define op2UL   r22
#define op2UH   r23
// r24 is the first param in C routines, and the result
#define tmp     r24
#define tmpL    r24
#define tmpH    r25
#define IP      X
#define IPL     XL
#define IPH     XH

// warning: Y must be preserved in routines called from C
#define EADDR   Y

// warning: C routines might clobber Z
#define OpCode  ZL
