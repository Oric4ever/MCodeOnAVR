#include <avr/interrupt.h>

ISR(PCINT0_vect)
{
    int a=2;
    int b= a+ 3;
    a = b + 1;
}
