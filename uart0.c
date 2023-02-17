#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include "input.h"

#define BAUD 115200L

void uart0_init(void)
{
    /* Initialize UART0 to BAUD, 8N1 */
    UBRR0H = 0;
    UBRR0L = 18432000L/16/BAUD-1;
    UCSR0A = 0;
    UCSR0B = _BV(TXEN0) | _BV(RXEN0) | _BV(RXCIE0);
    UCSR0C = _BV(URSEL0) | _BV(UCSZ01) | _BV(UCSZ00); // 8 bit data
    if (UCSR0A & _BV(RXC0))
        UDR0;  // read UDR0
    sei();
}

void uart0_send(char c)
{
    while (!(UCSR0A & _BV(UDRE0)))
        ;
    UDR0 = c;
}

ISR(USART0_RXC_vect)
{
    unsigned char status = UCSR0A;
    unsigned char c = UDR0;
    if (status & (UPE0 | FE0)) return;
    char next_put = (BUFFER_PUT+1) & (BUFFER_SIZE-1);
    if (next_put == BUFFER_GET) {
        return; // buffer is full
    }
    BUFFER[(unsigned int)BUFFER_PUT] = c;
    BUFFER_PUT = next_put;
}

char uart0_status(void)
{
    return BUFFER_PUT != BUFFER_GET;
}

char uart0_receive(void)
{
    while (BUFFER_PUT == BUFFER_GET)
        sleep_mode(); // wait for an interrupt
    char c = BUFFER[(unsigned int)BUFFER_GET];
    BUFFER_GET = (BUFFER_GET+1) & (BUFFER_SIZE-1);
    return c;
}

void uart0_space(void)   { uart0_send(' '); }
void uart0_newline(void) { uart0_send(0x0d); uart0_send(0x0a); }

static void uart0_hexdigit(char d) {
    uart0_send( d < 10 ? '0'+d : 'A'+d-10 );
}
void uart0_hexbyte(char hex) {
    uart0_hexdigit(hex >> 4);
    uart0_hexdigit(hex & 0x0f);
}
void uart0_hexword(unsigned int hex) {
    uart0_hexbyte(hex >> 8);
    uart0_hexbyte(hex & 0xff);
}

