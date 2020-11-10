#include <avr/io.h>
#include <avr/interrupt.h>

extern void interrupt_handler(int vector_num);

ISR(TIMER2_COMP_vect)   { interrupt_handler(11); }
ISR(TIMER2_OVF_vect)    { interrupt_handler(12); }
ISR(TIMER1_CAPT_vect)   { interrupt_handler(13); }
ISR(TIMER1_COMPA_vect)  { interrupt_handler(14); }
ISR(TIMER1_COMPB_vect)  { interrupt_handler(15); }
ISR(TIMER1_OVF_vect)    { interrupt_handler(16); }
ISR(TIMER0_COMP_vect)   { interrupt_handler(17); }
ISR(TIMER0_OVF_vect)    { interrupt_handler(18); }
ISR(SPI_STC_vect)       { interrupt_handler(19); }

/* USART0_RXC and USART1_RXC already defined */

ISR(USART0_UDRE_vect)   { interrupt_handler(22); }
ISR(USART1_UDRE_vect)   { interrupt_handler(23); }
ISR(USART0_TXC_vect)    { interrupt_handler(24); }
ISR(USART1_TXC_vect)    { interrupt_handler(25); }

