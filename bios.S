#include <avr/io.h>
#include "regdefs.h"
#include "macros.h"

#define NON_BLOCKING 1

#define IORESULT 0x300
#define HLRESULT 0x302
#define LBA_SECT 0xFF00
#define DMA_ADDR 0xFF04

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
.global SectorRead, SectorWrite, SelectTrackNumber, SelectSectorNumber, SetDMA

.text
trace_relay: jmp trace

BIOS_Table:
/* fct  0 */    rjmp WarmBoot
/* fct  1 */    rjmp ConsoleStatus
/* fct  2 */    rjmp ConsoleInput
/* fct  3 */    rjmp ConsoleOutput
/* fct  4 */    rjmp unimplemented
/* fct  5 */    rjmp unimplemented
/* fct  6 */    rjmp unimplemented
/* fct  7 */    rjmp unimplemented
/* fct  8 */    rjmp SelectDiskDrive
/* fct  9 */    rjmp SelectTrackNumber
/* fct 10 */    rjmp SelectSectorNumber
/* fct 11 */    rjmp SetDMA
/* fct 12 */    rjmp SectorRead
/* fct 13 */    rjmp SectorWrite

BIOS:
    cpi  opL,14
    cpc  opH,Zero
    brsh unimplemented
    sts  IORESULT,Zero            // default IORESULT = 0
    sts  HLRESULT,Zero            // default HLRESULT = 0000
    sts  HLRESULT+1,Zero
    ldi  ZH,hi8(pm(BIOS_Table))
    ldi  ZL,lo8(pm(BIOS_Table))
    add  ZL,opL
    adc  ZH,Zero
    ijmp

WarmBoot:
    ldi  YL,0xff
    ldi  YH,0xfe
    SETSP(Y)
    jmp  mcode_run
    
SelectDiskDrive:
unimplemented:
    ret

ConsoleOutput: jmp uart0_send
    
ConsoleStatus:
#if NON_BLOCKING
    call uart0_status
#else
    ser  result
#endif
    sts  IORESULT,result
    ret

ConsoleInput:
    call uart0_receive
    sts  IORESULT,result
    ret

SelectTrackNumber:  // track number is actually interpreted as the MSW of lba
    sts  LBA_SECT+2,param1
    sts  LBA_SECT+3,param1H
    ret

SelectSectorNumber: // sector number is actually interpreted as the LSW of lba
    sts  LBA_SECT+0,param1
    sts  LBA_SECT+1,param1H
    ret

SetDMA:
    sts  DMA_ADDR+0,param1
    sts  DMA_ADDR+1,param1H
    ret

CMD17 = 0x40 + 17
CMD24 = 0x40 + 24

// 512-bytes sector read
// Reads sector LBA_SECT (initialized with BIOS functions 9 and 10)
// into address DMA_ADDR (initialized with BIOS function 11)
// Can be called from C:
//   uses only call-used registers: r30-r31 (Z), r18-r25
SectorRead:
    ldi   param1,CMD17      // read single block command
    rcall sector_rw         // send read command to mmc
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
    inc   result            // a data packet arrived if data was 0xFE
    sec                     // in case of error, return carry
    brne  mmc_read_end
    clr   param2
    ldi   param2H,2         // prepare to loop for 512 bytes
receive_sector:
    rcall spi_read
    st    Z+,result
    dec   param2
    brne  receive_sector
    dec   param2H
    brne  receive_sector
    rcall spi_read          // receive first crc byte
    rcall spi_read          // receive second crc byte
    clc
mmc_read_end:
    rcall mmc_unselect
    ret


// 512-bytes sector write
// Writes sector LBA_SECT (initialized with BIOS functions 9 and 10)
// from address DMA_ADDR (initialized with BIOS function 11)
// Can be called from C:
//   uses only call-used registers: r30-r31 (Z), r18-r25
SectorWrite:
    ldi   param1,CMD24       // write single block command
    rcall sector_rw
    tst   result
    brne  mmc_write_error

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
    ldi   param2H,20           // prepare ~5120 retries
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
    ret

sector_rw:  // load lba address for read or write sector command
    lds   ZL,DMA_ADDR+0         // load DMA address
    lds   ZH,DMA_ADDR+1
    lds   param3 ,LBA_SECT+0
    lds   param3H,LBA_SECT+1
    lds   param2 ,LBA_SECT+2
    lds   param2H,LBA_SECT+3
    ldi   param4,1              // prepare 7-bits dummy crc + stop bit
    rjmp  mmc_send_cmd

