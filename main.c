#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "newbios.h"
#include "keyboard.h"


// avoids to write in page 0, so skip the first sector of image
#define RAM_BASE            ((unsigned char *)0x0200)

extern void uart0_init();
extern void mcode_run();
extern char mmc_init();

void load_system(void)
{
    // read the system from within reserved sectors starting at 9
    // (sector 8 would have to go at address 0)
    struct diskparams params;
    params.dma    = RAM_BASE;
    params.offset = 0;
    params.count  = 512;
    for (int sect = 9; sect<64; sect++) {
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

    // Change the stack location, so that loading the system doesn't overwrite it
    SPL = 0xff;
    SPH = 0xfe;   // keep page FF free for some virtual machine variables

    load_system();
    mcode_run();
}
