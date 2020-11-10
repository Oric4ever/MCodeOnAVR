/*-----------------------------------------------------------------------/
/  PFF - Generic low level disk control module            (C)ChaN, 2014
/------------------------------------------------------------------------/
/
/  Copyright (C) 2014, ChaN, all right reserved.
/
/ * This software is a free software and there is NO WARRANTY.
/ * No restriction on use. You can use, modify and redistribute it for
/   personal, non-profit or commercial products UNDER YOUR RESPONSIBILITY.
/ * Redistributions of source code must retain the above copyright notice.
/-----------------------------------------------------------------------*/

//#include "pff.h"
//#include "diskio.h"

/* Type definitions */
typedef unsigned char BYTE;
typedef unsigned int  WORD;
typedef unsigned long DWORD;

void spi_init (void);		/* Initialize SPI port (asmfunc.S) */
void spi_init2(void);		/* Initialize maximum SPI frequency */
void mmc_select (void);		/* Select MMC (asmfunc.S) */
void mmc_unselect (void);	/* Deselect MMC (asmfunc.S) */
BYTE mmc_send_cmd(BYTE cmd, DWORD arg, BYTE crc);
void spi_write (BYTE d);	/* Send a byte to the MMC (asmfunc.S) */
BYTE spi_read (void);		/* Send a 0xFF to the MMC and get the received byte (asmfunc.S) */
void delay_100us (void);	/* Delay 100 microseconds (asmfunc.S) */


/* Definitions for MMC/SDC command */
#define CMD0	(0x40+0)	/* GO_IDLE_STATE */
#define CMD1	(0x40+1)	/* SEND_OP_COND (MMC) */
#define	ACMD41	(0xC0+41)	/* SEND_OP_COND (SDC) */
#define CMD8	(0x40+8)	/* SEND_IF_COND */
#define CMD16	(0x40+16)	/* SET_BLOCKLEN */
#define CMD17	(0x40+17)	/* READ_SINGLE_BLOCK */
#define CMD24	(0x40+24)	/* WRITE_BLOCK */
#define CMD55	(0x40+55)	/* APP_CMD */
#define CMD58	(0x40+58)	/* READ_OCR */


/* Card type flags (CardType) */
#define CT_MMC				0x01	/* MMC ver 3 */
#define CT_SD1				0x02	/* SD ver 1 */
#define CT_SD2				0x04	/* SD ver 2 */
#define CT_BLOCK			0x08	/* Block addressing */


/*-----------------------------------------------------------------------*/
/* Send a command packet to MMC                                          */
/*-----------------------------------------------------------------------*/

static
BYTE send_Acmd (
	BYTE cmd,		/* 1st byte (Start + Index) */
	DWORD arg		/* Argument (32 bits) */
)
{
    BYTE res = mmc_send_cmd(CMD55, 0, 1);
	if (res > 1) return res;
    return mmc_send_cmd(cmd & 0x7F, arg, 1);
}

/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/

BYTE mmc_init(void)
{
	BYTE n, cmd, ty, ocr[4];
	WORD tmr;

extern void uart0_send(char);
uart0_send('S');
	spi_init();							/* Initialize ports to control MMC */
	for (n = 100; n; n--) delay_100us();	/* 10ms delay */
	for (n = 10; n; n--) spi_write(0xFF);/* 80 Dummy clocks with CS=H */

	ty = 0;
uart0_send('D');
	if (mmc_send_cmd(CMD0, 0, 0x95) == 1) {			/* Enter Idle state */
uart0_send('v');
		if (mmc_send_cmd(CMD8, 0x1AA, 0x87) == 1) {	/* SDv2 */
			for (n = 0; n < 4; n++) ocr[n] = spi_read();		/* Get trailing return value of R7 resp */
uart0_send('2');
			if (ocr[2] == 0x01 && ocr[3] == 0xAA) {			/* The card can work at vdd range of 2.7-3.6V */
				for (tmr = 10000; tmr && send_Acmd(ACMD41, 1UL << 30); tmr--)
                    delay_100us();	/* Wait for leaving idle state (ACMD41 with HCS bit) */
				if (tmr && mmc_send_cmd(CMD58, 0, 1) == 0) {		/* Check CCS bit in the OCR */
					for (n = 0; n < 4; n++) ocr[n] = spi_read();
					ty = (ocr[0] & 0x40) ? CT_SD2 | CT_BLOCK : CT_SD2;	/* SDv2 (HC or SC) */
				}
			}
		} else {							/* SDv1 or MMCv3 */
			if (send_Acmd(ACMD41, 0) <= 1) 	{
uart0_send('1');
				ty = CT_SD1; cmd = ACMD41;	/* SDv1 */
			} else {
uart0_send('0');
				ty = CT_MMC; cmd = CMD1;	/* MMCv3 */
			}
			for (tmr = 10000; tmr && mmc_send_cmd(cmd, 0, 0x95); tmr--)
                delay_100us();	/* Wait for leaving idle state */
			if (!tmr || mmc_send_cmd(CMD16, 512, 1) != 0)			/* Set R/W block length to 512 */
				ty = 0;
		}
	}
	mmc_unselect();
    spi_init2();    /* raise clock freq to fcpu/2 */

	return ty;
}



