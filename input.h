#define BUFFER_SIZE 0x10
#define BUFFER_PUT (*(volatile char *)0xff08)
#define BUFFER_GET (*(volatile char *)0xff09)
#define KBD_STATE  (*(unsigned char *)0xff0a)
#define BUFFER      ((char *)0xff20)

void input_enqueue(char c);
