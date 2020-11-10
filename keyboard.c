#include <stdio.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "keyboard.h"
#include "keys.h"
#include "input.h"

/* Set-2 make code to ibm key translation table */
const char ibm_key[] PROGMEM = {
/* 00-07 */   0,F9,0,F5,            F3,F1,F2,F12,
/* 08-0F */   0,F10,F8,F6,          F4,TAB,BACKTICK,0,
/* 10-17 */   0,L_ALT,L_SHIFT,0,    L_CTRL,KEY_Q,KEY_1,0,
/* 18-1F */   0,60,KEY_Z,KEY_S,     KEY_A,KEY_W,KEY_2,0,
/* 20-27 */   0,KEY_C,KEY_X,KEY_D,  KEY_E,KEY_4,KEY_3,0,
/* 28-2F */   0,SPACE,KEY_V,KEY_F,  KEY_T,KEY_R,KEY_5,0,
/* 30-37 */   0,KEY_N,KEY_B,KEY_H,  KEY_G,KEY_Y,KEY_6,0,
/* 38-3F */   0,0,KEY_M,KEY_J,      KEY_U,KEY_7,KEY_8,0,
/* 40-47 */   0,COMMA,KEY_K,KEY_I,  KEY_O,KEY_0,KEY_9,0,
/* 48-4F */   0,DOT,SLASH,KEY_L,    SEMICOL,KEY_P,MINUS,0,
/* 50-57 */   0,0,QUOTE,0,          L_BRACKET,EQUAL,0,0,
/* 58-5F */CAPS,R_SHIFT,ENTER,R_BRACKET,  0,BACKSLASH,0,0,
/* 60-67 */   0,KBD102,0,0,         0,0,BACKSP,0,
/* 68-6F */   0,KP_1,0,KP_4,        KP_7,0,0,0,
/* 70-77 */KP_0,KP_DOT,KP_2,KP_5,   KP_6,KP_8,ESCAPE,NUMLCK,
/* 78-7F */ F11,KP_PLUS,KP_3,KP_MINUS, KP_MUL,KP_9,SCRLLCK,0,
/* 80-83 */   0,  0,  0,F7
};

/**
 * Bitbang a 0xFF code (reset command) to the keyboard
 */
void kbd_reset(void)
{
    UCSR1A = 0;
    UCSR1B = 0; // disable receiver
    UCSR1C = _BV(URSEL1); // and disable usart

    PORTD &= ~_BV(PORTD2); // clock line low
    DDRD |= _BV(DDD2); // output clock low

    _delay_us(100);

    PORTB &= ~_BV(PORTB2);  // DATA line low
    DDRB |= _BV(DDB2); // output DATA low

    PORTD |= _BV(PORTD2); // clock line high
    DDRD &= ~_BV(DDD2);  // release clock line (=> input)
    PORTD &= ~_BV(PORTD2); // clock is tri-stated

    loop_until_bit_is_clear(PIND,PIND2); // wait for clock line low

    PORTB |= _BV(PORTB2); // emits '1' bits

    for (int bits=0; bits<9; bits++) {
        loop_until_bit_is_set(PIND,PIND2); // wait for clock high
        loop_until_bit_is_clear(PIND,PIND2); // wait for clock low
    }

    DDRB &= ~_BV(DDB2); // release data line (=> input)
    PORTB &= ~_BV(PORTB2); // DATA line is tri-stated

    loop_until_bit_is_clear(PIND,PIND2); // wait for clock low
    loop_until_bit_is_set(PIND,PIND2); // wait for clock high
}

void kbd_init(void)
{
    KBD_STATE = 0;
//    kbd_reset(); // needed for some keyboard, eg. Peritex
    UCSR1A = 0;
    UCSR1B = _BV(RXEN1) | _BV(RXCIE1);
    UCSR1C = _BV(URSEL1)|_BV(UMSEL1)|_BV(UPM11)|_BV(UPM10)|_BV(UCSZ11)|_BV(UCSZ10);
    UCSR1A; // read status
    UDR1;   // read data
    sei();
}

ISR(USART1_RXC_vect)
{
    unsigned char status = UCSR1A;
    unsigned char code = UDR1;
    if (status & (UPE1 | FE1)) {
        extern void hexbyte(char);
        hexbyte(code);
        return;
    }
    if (code==0xAA) return; // Keyboard's initial test ok
    if (code==0xE0) { KBD_STATE |= EXTENDED; return; }
    if (code==0xF0) { KBD_STATE |= BREAK;    return; }
    char key = pgm_read_byte(&ibm_key[(int)code]);
    if (key) kbd_translate(key);
    KBD_STATE &= ~(EXTENDED | BREAK);
}

