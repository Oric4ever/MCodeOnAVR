#include <stdbool.h>
#include <stdio.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "keyboard.h"
#include "keys.h"
#include "input.h"

const char unshifted[] PROGMEM = {
    /* table for the main part of the keyboard: keys #1 to #61 */
    -1, // no key #0
    '`','1','2','3','4','5','6','7','8','9','0','-','=',-1,0x7f,   // no key #14
    '\t','q','w','e','r','t','y','u','i','o','p','[',']','\\',
    -1, // CAPS
    'a','s','d','f','g','h','j','k','l',';','\'','\\','\r',
    -1, // left Shift
    '\\','z','x','c','v','b','n','m',',','.','/',-1, // no key #56
    -1, // right shift
    -1, // left ctrl
    -1, // no key #59
    -1, // left alt
    ' '// space
};

const char shifted[] PROGMEM = {
    /* shifted table for the main part of the keyboard: keys #1 to #61 */
    -1, // no key #0
    '~','!','@','#','$','%','^','&','*','(',')','_','+',-1,0x7f,
    -1,'Q','W','E','R','T','Y','U','I','O','P','{','}','|',
    -1,'A','S','D','F','G','H','J','K','L',':','"','|','\n',
    -1,'|','Z','X','C','V','B','N','M','<','>','?',-1,
    -1, // left shift
    -1, // left ctrl
    -1, // none
    -1, // left alt
    ' '// space
};

const char numpad[] PROGMEM = {
    /* numpad table: keys #91 to #109 */
        '7','4','1',  -1,
    '/','8','5','2','0',
    '*','9','6','3','.',
    '-','+',  -1,'\r', -1
};

#define CSI(c) c
#define SS3(c) c-128
#define NOKEY -1

const char editing[] PROGMEM = {
    /* numpad table when numlock is not active : keys #75 to #110 (ESC) */
    /* Bit 7 codes either CSI (ESC-[) or SS3 (ESC-O) */
    /* If the char is a number, then a final '~' is sent */
    CSI('2'),CSI('3'),  NOKEY ,  NOKEY ,CSI('D'), // Ins,  Del, _ , _ , left
    CSI('1'),CSI('4'),  NOKEY ,CSI('A'),CSI('B'), // Home, End, _ , up, down
    CSI('5'),CSI('6'),  NOKEY ,  NOKEY ,CSI('C'), // PgUp,PgDn, _ , _ ,right
      NOKEY ,CSI('1'),CSI('D'),CSI('4'),  NOKEY , // NumLck, 7, 4 , 1 , _
    SS3('o'),CSI('A'),CSI('E'),CSI('B'),CSI('2'), //   / ,   8, 5 , 2 , 0
    SS3('j'),CSI('5'),CSI('C'),CSI('6'),CSI('3'), //   * ,   9, 6 , 3 , .  
    SS3('m'),SS3('k'),  NOKEY ,SS3('M'),  NOKEY   //   - ,   +, _ ,Ret, _
};

void kbd_translate(unsigned char key) {
    if (KBD_STATE & BREAK) {  // release state keys
        switch (key) {
            case L_SHIFT: // assume both won't be pressed simultaneously... 
            case R_SHIFT: KBD_STATE &= ~SHIFTED; break;
            case L_CTRL: // assume both won't be pressed simultaneously... 
            case R_CTRL:  KBD_STATE &= ~CTRL_PRESSED; break;
            case L_ALT: // assume both won't be pressed simultaneously... 
            case R_ALT:   KBD_STATE &= ~(KBD_STATE & EXTENDED ? ALTGR_PRESSED : ALT_PRESSED); break;
        }
    } else { // make keys
        // assume both won't be pressed simultaneously... 
             if (key==L_SHIFT || key==R_SHIFT) KBD_STATE |= SHIFTED;
        else if (key==L_CTRL  || key==R_CTRL ) KBD_STATE |= CTRL_PRESSED;
        else if (key==L_ALT   || key==R_ALT  ) KBD_STATE |= KBD_STATE & EXTENDED ? ALTGR_PRESSED : ALT_PRESSED;
        else if (key==NUMLCK) KBD_STATE ^= NUM_LOCK;
        else if (key==CAPS)   KBD_STATE ^= CAPS_LOCK;
        else if (key <= 61) { // main table
            char ascii = pgm_read_byte(KBD_STATE & SHIFTED ? &shifted[key] : &unshifted[key]);
            if ((KBD_STATE & CAPS_LOCK) && ascii>='a' && ascii <='z') ascii -= 0x20;
            if (KBD_STATE & CTRL_PRESSED) ascii &= 0x1f;
            input_enqueue(ascii);
        } else if (key == 110) { input_enqueue(0x1b); // ESC
        } else if (key >= 75) {
            char ss3 = false, param=0, command=0;
            if (key >= 112) { // function keys normally encoded as CSI-nn~
                param = key-111; // => param = function number (1 to 12)
                if (param >= 11) param++; // insert a hole between F10 and F11
                if (param >= 6)  param++; // insert a hole between F5 and F6
                if (param <= 4) {       // F1 to F4 encoded as SS3-P .. SS3-S
                    ss3 = true; command = param+'O'; param = 0;
                } else {                // F5 ... encoded as CSI-15~
                    param+=10; command='~';
                }
            } else {
                if (key>=91 && !(KBD_STATE & EXTENDED) && (KBD_STATE & NUM_LOCK))
                    // numpad in numeric mode
                    input_enqueue(pgm_read_byte(numpad[key-91]));
                else { // numpad in editing mode
                    param = pgm_read_byte(&editing[key-75]);
                    ss3 = param & 128;
                    param &= 0x7F;
                    if (param>='0' && param<='9') { param-='0'; command='~'; }
                    else { command = param; param = 0; }
                    if (KBD_STATE & CTRL_PRESSED) {
                        if (key==80) { param=1; command='H'; }
                        if (key==81) { param=1; command='F'; }
                    }
                }
            }
            if (command) {
                input_enqueue(0x1b);
                if (KBD_STATE & CTRL_PRESSED) ss3 = false;
                input_enqueue(ss3 ? 'O' : '[');
                if (param || (KBD_STATE & CTRL_PRESSED)) {
                    if (param==0) param=1; // default param value is 1
                    // send tenths
                    if (param>=20) { input_enqueue('2'); param-=20; }
                    else if (param>=10) { input_enqueue('1'); param-=10; }
                    // send units
                    input_enqueue('0'+param);
                }
                if (KBD_STATE & CTRL_PRESSED) { input_enqueue(';'); input_enqueue('5'); }
                input_enqueue(command);
            }
        }
    }
}

