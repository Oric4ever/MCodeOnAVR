#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

.global   Allocate_with_tag,   Allocate_without_tag
.global Deallocate_with_tag, Deallocate_without_tag, Mark, Release
.text
trace_relay: jmp trace

#define FreeMarker  opU 
#define FreeMarkerL opUL
#define FreeMarkerH opUH


Allocate_with_tag:
    POP1(Y)             // size
    adiw Y,2            // add two bytes for the tag
    movw op,Y
    rcall Allocate      // address of block in Z
    POP1(Y)             // get the tag
    st   Z+,YL          // write the tag
    st   Z+,YH          // and Z now points to the record
    rjmp store_alloc

Allocate_without_tag:   // allocate op bytes 
    POP1(op)            // op : the wanted block size
    rcall Allocate      // address of block in Z
store_alloc:
    POP1(Y)             // get the address of the variable 
    st   Y+,ZL          // and assign it the addr of the block found
    st   Y+,ZH  
    FFETCH

Allocate:
    INC1(op)           // round to the above even value 
    andi op,0xfe
    cpi  opL,8         // allocate at least 8 bytes 
    cpc  opH,Zero
    brsh 1f
    ldi  opL,8
1:  ldi  YL,lo8(FreeList)     // Y : address of a block ptr
    ldi  YH,hi8(FreeList)
    ldi  FreeMarkerL,lo8(FREE_MARKER)
    ldi  FreeMarkerH,hi8(FREE_MARKER)

SearchFreeList:
    ld   ZL,Y           // Z : block 
    ldd  ZH,Y+1
    cp   ZL,Zero        // end of list ? 
    cpc  ZH,Zero
    breq NoAdequateBlock
                        // here we check the current block of the list 
    ld   tmpL,Z         // first check it has the FREE marker
    ldd  tmpH,Z+1
    cp   tmpL,FreeMarkerL
    cpc  tmpH,FreeMarkerH
    brne Error14
    ldd  op2L,Z+4       // op2 : this block's size 
    ldd  op2H,Z+5
#define BlockSize op2
    movw tmp,BlockSize  // calculate the excess size (if any) 
    sub  tmpL,opL
    sbc  tmpH,opH
#define ExcessSize tmp
    brcs TooSmall       // skip if block too small 
    breq PerfectSize    // go handle a perfect size block 
    cpi  tmpL,8
    cpc  tmpH,Zero
    brlo TooSmall       // jump if splitting the block would leave a too small chunk
                        // here we can split the block in two parts:
                        // leave the left part free (the excess chunk)
                        // and return the right part
    st   Z,  FreeMarkerL// mark the excess part as free 
    std  Z+1,FreeMarkerH
                        // the link at offset 2 is kept untouched
    std  Z+4,tmpL       // store the excess size at offset 4, 
    std  Z+5,tmpH       // both sizes at the same offset in an 8-bytes block 
    add  ZL,tmpL        // calculate the address of the right part
    adc  ZH,tmpH
    movw Y,Z            // use Y to modify the end of the left block 
    st   -Y,FreeMarkerH // mark the end of the left part 
    st   -Y,FreeMarkerL
    st   -Y,tmpH        // size is present at both end of block 
    st   -Y,tmpL
    rjmp EndAllocate    // Z is the address of the block to return

Error14: ERROR(14)

NoAdequateBlock:        // here we reached the end of free-blocks list, so 
                        // we allocate in the remaining Big Block 
    mov  ZL,StackLimitL // the Big Block is 60 bytes before the stack limit
    mov  ZH,StackLimitH
    movw Y,Z            // calculate the new stack limit
    add  YL,opL
    adc  YH,opH
    cp   YL,ReserveL
    cpc  YH,ReserveH
    brsh Error5
    mov  StackLimitL,YL // set the new stack limit
    mov  StackLimitH,YH
    sbiw Z,60           // ok so here is the block
    sbiw Y,60           // and the new remaining big block, mark it free
    st   Y+,FreeMarkerL 
    st   Y+,FreeMarkerH
    rjmp EndAllocate

PerfectSize:
    ldd  tmpL,Z+2       // get next block addr 
    ldd  tmpH,Z+3
    st   Y+,tmpL        // replace previous link with next block addr 
    st   Y+,tmpH
    rjmp EndAllocate

TooSmall:
    movw Y,Z
    adiw Y,2            // Y now points to next block pointer
    rjmp SearchFreeList

EndAllocate:
    movw Y,Z            // copy addr of block allocated
EraseLoop:              // fill the block with zeroes
    st   Y+,Zero
    st   Y+,Zero
    subi opL,2
    sbc  opH,Zero
    brne EraseLoop
    ret
    
    
Error5: ERROR(5)
NilPointer: ERROR(7)

Deallocate_with_tag:
    POP1(Y)              // the block size
    adiw  Y,2            // add two bytes for the tag
    movw  op,Y
    POP1(Y)              // addr of the variable
    ld    ZL,Y           // get the variable value (block address) in Z
    st    Y+,Zero        // and clear the variable
    ld    ZH,Y
    st    Y,Zero
    sbiw  Z,2            // points to the tag
    rjmp  Deallocate

Deallocate_without_tag:
    POP1(op)             // op : the block size
    POP1(Y)              // addr of the variable
    ld    ZL,Y           // get the variable value (block address) in Z
    st    Y+,Zero        // and clear the variable
    ld    ZH,Y
    st    Y,Zero
Deallocate: // DEALLOCATE(var_addr, size)
    INC1(op)             // round to the above even value 
    andi  op,0xfe
    cpi   opL,8          // blocksize is at least 8 bytes 
    cpc   opH,Zero
    brsh  1f
    ldi   opL,8
1:
    cp    ZL,Zero        // test if NIL pointer
    cpc   ZH,Zero
    breq  NilPointer
    ldi   FreeMarkerL,lo8(FREE_MARKER)
    ldi   FreeMarkerH,hi8(FREE_MARKER)

test_block_after:
    movw  Y,Z            // calculate address of the block behind in Y
    add   YL,opL
    adc   YH,opH
    ld    tmpL,Y         // is it a free block ?
    ldd   tmpH,Y+1
    cp    tmpL,FreeMarkerL
    cpc   tmpH,FreeMarkerH
    brne  test_block_before
                        // yes : try to remove it from free list
    rcall remove_from_freelist
    brne  test_block_before  // jump if block was not in freelist
    ldd   tmpL,Y+4      // merge the two blocks : add the sizes
    ldd   tmpH,Y+5
    add   opL,tmpL
    adc   opH,tmpH

test_block_before: 
    movw  Y,Z           // also is there a free block before ?
    ld    tmpH,-Y
    ld    tmpL,-Y
    cp    tmpL,FreeMarkerL
    cpc   tmpH,FreeMarkerH
    brne  test_if_last_block
                        // yes : get its size
    ld    tmpH,-Y
    ld    tmpL,-Y
    movw  Y,Z           // and thus calculate its starting address
    sub   YL,tmpL
    sbc   YH,tmpH
    rcall remove_from_freelist
    brne  test_if_last_block // jump if not found in free list
    add   opL,tmpL      // merge the two blocks : add the sizes
    adc   opH,tmpH
    movw  Z,Y           // and the resulting block starts here

test_if_last_block:
    movw  Y,Z           // test if the freed block is just under heap:
    add   YL,opL        // now Y points just after the freed block
    adc   YH,opH
    mov   tmpL,StackLimitL
    mov   tmpH,StackLimitH
    sbiw  tmp,60        // and here is the remaining memory
    cp    YL,tmpL
    cpc   YH,tmpH
    brne  insert_in_freelist
                        // yes : lower the stack limit
    movw  Y,Z
    adiw  Y,60
    mov   StackLimitL,YL
    mov   StackLimitH,YH
    st    Z+,FreeMarkerL// and put a marker
    st    Z+,FreeMarkerH
    rjmp  deallocate_end// and that's it

                        // otherwise, insert the block in the freelist
insert_in_freelist:
    st    -Y,FreeMarkerH// put a marker at the end
    st    -Y,FreeMarkerL
    st    -Y,opH        // and the size of the block
    st    -Y,opL
    movw  Y,Z           // put also a marker at the beginning
    st    Y+,FreeMarkerL
    st    Y+,FreeMarkerH
    lds   tmpL,FreeList // then previous freelist (addr of 1st block)
    lds   tmpH,FreeList+1
    st    Y+,tmpL
    st    Y+,tmpH
    st    Y+,opL        // and then the size of the block
    st    Y+,opH
    sts   FreeList,ZL   // now this block is first in the freelist
    sts   FreeList+1,ZH
deallocate_end:
    FFETCH              // and that's it !

remove_from_freelist:   // remove block pointed by Y from freelist :
    movw  op2,Y         // block to search now in op2
    movw  op2U,Z        // save Z too
    ldi   YL,lo8(FreeList)     // Y : address of a block ptr
    ldi   YH,hi8(FreeList)
search_loop:
    ld    ZL,Y          // get the block pointed by Y
    ldd   ZH,Y+1
    cp    ZL,Zero       // is it NIL ?
    cpc   ZH,Zero
    breq  not_found
    cp    ZL,op2L       // is it the searched block ?
    cpc   ZH,op2H
    breq  found_it
    movw  Y,Z           // nope, advance to the next block:
    adiw  Y,2           // Y points to the link
    rjmp  search_loop
not_found:
    clz                 // reflect "not found" in flag Z
    rjmp  end_search
found_it:
    ldd   r0,Z+2        // get the link stored in this block
    st    Y+,r0         // and replace the block pointer with it
    ldd   r0,Z+3
    st    Y+,r0
                        // flag Z should still be set
end_search:             // returns flag Z
    movw  Z,op2U        // restore Z pointer
    movw  Y,op2         // and Y
    ret


Mark:
    POP1(Y)             // addr of the variable
    mov   tmpL,StackLimitL
    mov   tmpH,StackLimitH
    sbiw  tmp,60        // now tmp is the start of the big block
    STORE1(tmp)         // assign the variable with the old heap
    movw  Y,tmp
    lds   opL,FreeList  // get the old FreeList
    lds   opH,FreeList+1
    STORE1(op)          // and save it
    LDIW(FREE_MARKER)   // put a marker at the beginning of new heap
    STORE1(tmp)         // now Y is +2 after the new heap
    adiw  Y,60-2        // update the new StackLimit too
    mov   StackLimitL,YL
    mov   StackLimitH,YH
    sts   FreeList,Zero // the new FreeList is empty
    sts   FreeList+1,Zero
    FFETCH

NilPointer2: ERROR(7)

Release:
    POP1(Y)       // addr of the variable
    ld   ZL,Y     // get the saved heap and clear the variable
    st   Y+,Zero
    ld   ZH,Y
    st   Y+,Zero
    cp   ZL,Zero  // check if NIL pointer
    cpc  ZH,Zero
    breq NilPointer2
    LDIW(FREE_MARKER)    // prepare to put a marker 
    ld   opL,Z           // get the saved FreeList
    sts  FreeList,opL 
    st   Z+,tmpL         // and replace by FREE_MARKER
    ld   opH,Z
    sts  FreeList+1,opH
    st   Z+,tmpH
    adiw Z,60-2          // restore StackLimit 
    mov  StackLimitL,ZL
    mov  StackLimitH,ZH
    FFETCH

