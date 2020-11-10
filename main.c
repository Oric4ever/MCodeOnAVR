#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "bios.h"
#include "keyboard.h"


/* this is the only one global variable in all modules,
 * so it should be at ram address 0x0100                */
unsigned char sector_buffer[512];

extern void uart0_init();
extern void mcode_run();
extern char mmc_init();

void load_system(void)
{
#define RAM_BASE            ((unsigned char *)0x0100)
/*
#define SectorsPerCluster   sector_buffer[0x0D]
#define ReservedSectors     (*(unsigned int *)(sector_buffer+0x0E))
#define NumberOfFATs        sector_buffer[0x10]
#define FATtype             sector_buffer[0x15]
#define SectorsPerFAT       (*(unsigned int *)(sector_buffer+0x16))
#define RootDirEntries      (*(unsigned int *)(sector_buffer+0x11))

#define firstKernelCluster  (*(unsigned int *)(sector_buffer+0x1A)) 
#define KERNEL_SECTORS 47
#define firstBDOSCluster    (*(unsigned int *)(sector_buffer+0x3A)) 
#define BDOS_SECTORS 4

#define PATCH_AREA          ((unsigned char *)0x069D)
#define BDOS_BASE           (PATCH_AREA+0x0400)
#define MODULE_START        ((unsigned int *)BDOS_BASE)[-7]

    // first read boot sector to extract some info
    SetDMA(sector_buffer);
    SelectTrackNumber(0); SelectSectorNumber(0);
//  uart0_send('R');
    SectorRead();
//  hexbyte(sector_buffer[0x36]);
//  if (sector_buffer[0x36]!='F') for(;;);

    unsigned int rootDirSect = ReservedSectors + NumberOfFATs * SectorsPerFAT;
    unsigned int dataRegion = rootDirSect + RootDirEntries/16;
    int sectorsPerCluster = SectorsPerCluster;

    // then read first sector of root directory
    // and assume the first two entries are M2.SYS and BDOS.MCD
    SelectSectorNumber(rootDirSect);
    SectorRead();
//  uart0_newline();
//  for (int i=0; i<11; i++) uart0_send(sector_buffer[i]);
//  uart0_newline();
//  for (int i=0; i<11; i++) uart0_send(sector_buffer[i+32]);
//  uart0_newline();

    unsigned int kernel_sect = dataRegion + (firstKernelCluster-2)*sectorsPerCluster;
    unsigned int bdos_sect   = dataRegion + (firstBDOSCluster-2)*sectorsPerCluster;

    // read the system (assume contiguous sectors)
    unsigned char *addr = RAM_BASE;
    for (int i = 0; i<KERNEL_SECTORS; i++, addr += 0x200) {
        SelectSectorNumber(kernel_sect+i);
        SetDMA(addr);
        SectorRead();
    }
    // now read BDOS.MCD, take into account the 16 bytes header
    addr = BDOS_BASE-16;
    for (int i = 0; i<BDOS_SECTORS; i++, addr += 0x200) {
        SelectSectorNumber(bdos_sect+i);
        SetDMA(addr);
        SectorRead();
    }
    unsigned int *bdos_module = (unsigned int *)(BDOS_BASE+MODULE_START+80);
    // adjust the procedure table address
    bdos_module[-1] += (unsigned int)BDOS_BASE;
    // set the sector buffer address (first global variable)
    bdos_module[2] = (unsigned int)sector_buffer;
    // set the dependency to Convert and TERMINAL module
    bdos_module[-9] = 0x35FD;
    bdos_module[-10]= 0x5D18;
    // also change the pointer to the kernel process area and change its size
    ((unsigned int *)0x21d2)[18] = (unsigned int)PATCH_AREA;
    *((unsigned int *)0x1ee9)    = 1024; // 512 bytes would be enough
    *((unsigned int *)0x1eff)    = 1024; // ditto
    // finally save bdos module address
    *((unsigned int *)0xff06)    = (unsigned int)bdos_module;

*/
    // read the system from within reserved sectors starting at 8
    struct diskparams params;
    params.dma    = RAM_BASE;
    params.offset = 0;
    params.count  = 512;
    for (int sect = 8; sect<64; sect++) {
        params.lba = sect;
        NewSectorRead(&params);
        params.dma += 512;
    }
}


int main(void)
{

    // Disable JTAG: it conflicts with address bus 
    uint8_t tmp = MCUCSR | _BV(JTD);
    MCUCSR = tmp; // write twice in less than 4 cycles
    MCUCSR = tmp; // to override protection

    // Init external sram 
    MCUCR |= _BV(SRE); // external SRAM enable

    // Put PD4 in a defined state, it is connected to SRAM's A16 */
    PORTD |= _BV(PORTD4);

    uart0_init();
    _delay_ms(1000);
    //kbd_init(); // Caution! KBD_STATE is in 0xFF0A
    (void)mmc_init();

    // Change the stack location
    SPL = 0xff;
    SPH = 0xfe;   // keep page FF free to remap page 0

    load_system();
    mcode_run();
}
