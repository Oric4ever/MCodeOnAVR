#include <avr/pgmspace.h>

// bits in the KBD_STATE variable
#define EXTENDED 0x80
#define BREAK 0x40
#define SHIFTED 0x20
#define CTRL_PRESSED 0x10
#define ALT_PRESSED 0x08
#define ALTGR_PRESSED 0x04
#define CAPS_LOCK 0x02
#define NUM_LOCK 0x01

extern const char ibm_key[] PROGMEM;
extern void kbd_enqueue(unsigned char code);
extern void kbd_translate(unsigned char scancode);
extern void kbd_reset(void);
extern void kbd_init(void);
