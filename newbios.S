#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

#define NON_BLOCKING 1

#define param4  r18
#define param4H r19
#define param3  r20
#define param3H r21
#define param2  r22
#define param2H r23
#define param1  r24
#define param1H r25
#define result  r24

.global BIOS
.global ConsoleStatus, ConsoleInput, ConsoleOutput
.global NewSectorRead, NewSectorWrite

.text
trace_relay: jmp trace

BIOS_Table:
/* fct  0 */    rjmp WarmBoot
/* fct  1 */    rjmp ConsoleStatus
/* fct  2 */    rjmp ConsoleInput
/* fct  3 */    rjmp ConsoleOutput
/* fct  4 */    rjmp NewSectorRead
/* fct  5 */    rjmp NewSectorWrite

BIOS:
    cpi  opL,6
    cpc  opH,Zero
    brsh unimplemented
    ldi  ZH,hi8(pm(BIOS_Table))
    ldi  ZL,lo8(pm(BIOS_Table))
    add  ZL,opL
    adc  ZH,Zero
    ijmp

WarmBoot:
    jmp  mcode_run
    
unimplemented:
    ser  result
    ret

ConsoleOutput: jmp uart0_send
ConsoleInput:  jmp uart0_receive
ConsoleStatus:
#if NON_BLOCKING
    call uart0_status
#else
    ser  result
#endif
    ret


CMD17 = 0x40 + 17
CMD24 = 0x40 + 24

sector_params:
    ldd   param3 ,Z+0   // LBA sector number
    ldd   param3H,Z+1
    ldd   param2 ,Z+2
    ldd   param2H,Z+3
    ldi   param4 ,1     // prepare 7-bits dummy crc + stop bit
    rjmp  mmc_send_cmd
    
// partial sector read
// Can be called from C:
//   uses only call-used registers: r30-r31 (Z), r18-r25
NewSectorRead:
    movw  Z,param1          // params are now pointed by Z
    ldi   param1,CMD17      // read single block command
    rcall sector_params     // send read command to mmc
    tst   result
    brne  mmc_read_end      // skip if error
    clr   param2            // timeout after 65536 loops
    clr   param2H
wait_mmc_data:
    rcall spi_read
    inc   result
    brne  received_spi_data // exit loop when data is not 0xFF
    dec   param2
    brne  wait_mmc_data     // loop until timeout
    dec   param2H
    brne  wait_mmc_data
received_spi_data:
    inc   result            // a data packet is ready if data was 0xFE
    sec                     // in case of error, return carry
    brne  mmc_read_end
    ldd   param1 ,Z+4       // DMA address
    ldd   param1H,Z+5
    ldd   param3 ,Z+6       // offset in sector
    ldd   param3H,Z+7
    ldd   param4 ,Z+8       // count of bytes
    ldd   param4H,Z+9
    movw  Z,param1          // DMA addr in Z
    clr   param2
    ldi   param2H,2         // prepare the final loop for 512 bytes
    sub   param2 ,param3    // remove the initial skipped bytes
    sbc   param2H,param3H
    sub   param2 ,param4    // and the stored bytes
    sbc   param2H,param4H
skip_leading_bytes:
    mov   param1,param3     // test if there are bytes to skip
    or    param1,param3H
    breq  receive_sector
skip_byte:
    rcall spi_read
    subi  param3,1
    sbci  param3H,0
    brne  skip_byte
receive_sector:             // assume the count of bytes to read will never be 0
    rcall spi_read
    st    Z+,result
    subi  param4,1
    sbci  param4H,0
    brne  receive_sector
    mov   param1,param2     // test if there are bytes to skip at the end
    or    param1,param2H
    breq  receive_crc
skip_end_of_sector:
    rcall spi_read
    subi  param2,1
    sbci  param2H,0
    brne  skip_end_of_sector
receive_crc:
    rcall spi_read          // receive first crc byte
    rcall spi_read          // receive second crc byte
    clc
mmc_read_end:
    rcall mmc_unselect
    clr   result
    ret

// 512-bytes sector write
// Can be called from C:
//   uses only call-used registers: r30-r31 (Z), r18-r25
NewSectorWrite:
    movw  Z,param1          // params are now pointed by Z
    ldi   param1,CMD24      // write single block command
    rcall sector_params
    tst   result
    brne  mmc_write_error

    ldd   param1 ,Z+4       // DMA address
    ldd   param1H,Z+5
    movw  Z,param1          // DMA addr in Z

    ldi   param1,0xFF
    rcall spi_write
    ldi   param1,0xFE
    rcall spi_write

    clr   param2
    ldi   param2H,2         // prepare to loop for 512 bytes
write_sector:
    ld    param1,Z+
    rcall spi_write
    dec   param2
    brne  write_sector
    dec   param2H
    brne  write_sector
    clr   param1            // write two bytes of dummy CRC
    rcall spi_write
    clr   param1
    rcall spi_write

    rcall spi_read          // read data response
    andi  result,0x1F
    cpi   result,0x05
    brne  mmc_write_error
    ldi   param2H,20        // prepare ~5120 retries
wait_ready:
    rcall spi_read
    inc   result
    clc                
    breq  mmc_write_end     // mmc ready if it returns 0xFF
    clr   param1
wait_tempo:                 // don't annoy the mmc for ~ 60 microseconds
    nop
    dec   param1
    brne  wait_tempo
    dec   param2
    brne  wait_ready
    dec   param2H
    brne  wait_ready
mmc_write_error:
    sec                     // timeout, no ready response
mmc_write_end:
    rcall mmc_unselect
    clr   result
    ret

