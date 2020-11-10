#include <avr/sleep.h>
#include "input.h"

void input_enqueue(char c)
{
    char next_put = (BUFFER_PUT+1) & (BUFFER_SIZE-1);
    if (next_put == BUFFER_GET) return; // buffer is full
    BUFFER[(unsigned int)BUFFER_PUT] = c;
    BUFFER_PUT = next_put;
}

char input_status(void)
{
    return BUFFER_PUT != BUFFER_GET;
}

char input_dequeue(void)
{
    while (BUFFER_PUT == BUFFER_GET)
        sleep_mode(); // wait for an interrupt
    char c = BUFFER[(unsigned int)BUFFER_GET];
    BUFFER_GET = (BUFFER_GET+1) & (BUFFER_SIZE-1);
    return c;
}
