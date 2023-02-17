	.file	"uart0.c"
__SP_H__ = 0x3e
__SP_L__ = 0x3d
__SREG__ = 0x3f
__tmp_reg__ = 0
__zero_reg__ = 1
	.section	.text.uart0_init,"ax",@progbits
.global	uart0_init
	.type	uart0_init, @function
uart0_init:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
	out 0x20,__zero_reg__
	ldi r24,lo8(9)
	out 0x9,r24
	out 0xb,__zero_reg__
	ldi r24,lo8(-104)
	out 0xa,r24
	ldi r24,lo8(-122)
	out 0x20,r24
	sbic 0xb,7
	in r24,0xc
.L2:
/* #APP */
 ;  18 "uart0.c" 1
	sei
 ;  0 "" 2
/* #NOAPP */
	ret
	.size	uart0_init, .-uart0_init
	.section	.text.__vector_19,"ax",@progbits
.global	__vector_19
	.type	__vector_19, @function
__vector_19:
	push r1
	push r0
	in r0,__SREG__
	push r0
	clr __zero_reg__
	push r18
	push r24
	push r25
	push r30
	push r31
/* prologue: Signal */
/* frame size = 0 */
/* stack size = 8 */
.L__stack_usage = 8
	in r24,0xb
	in r25,0xc
	andi r24,lo8(6)
	brne .L4
	lds r24,-248
	subi r24,lo8(-(1))
	andi r24,lo8(15)
	lds r18,-247
	cp r24,r18
	breq .L4
	lds r30,-248
	mov __tmp_reg__,r30
	lsl r0
	sbc r31,r31
	subi r30,-16
	sbc r31,__zero_reg__
	st Z,r25
	sts -248,r24
.L4:
/* epilogue start */
	pop r31
	pop r30
	pop r25
	pop r24
	pop r18
	pop r0
	out __SREG__,r0
	pop r0
	pop r1
	reti
	.size	__vector_19, .-__vector_19
	.section	.text.uart0_send,"ax",@progbits
.global	uart0_send
	.type	uart0_send, @function
uart0_send:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
.L7:
	sbis 0xb,5
	rjmp .L7
	out 0xc,r24
	ret
	.size	uart0_send, .-uart0_send
	.section	.text.uart0_status,"ax",@progbits
.global	uart0_status
	.type	uart0_status, @function
uart0_status:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
	lds r18,-248
	lds r25,-247
	ldi r24,lo8(1)
	cpse r18,r25
	rjmp .L11
	ldi r24,0
.L11:
	ret
	.size	uart0_status, .-uart0_status
	.section	.text.uart0_receive,"ax",@progbits
.global	uart0_receive
	.type	uart0_receive, @function
uart0_receive:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
.L13:
	lds r25,-248
	lds r24,-247
	cpse r25,r24
	rjmp .L15
	in r24,0x35
	ori r24,lo8(32)
	out 0x35,r24
/* #APP */
 ;  47 "uart0.c" 1
	sleep
	
 ;  0 "" 2
/* #NOAPP */
	in r24,0x35
	andi r24,lo8(-33)
	out 0x35,r24
	rjmp .L13
.L15:
	lds r30,-247
	mov __tmp_reg__,r30
	lsl r0
	sbc r31,r31
	subi r30,-16
	sbc r31,__zero_reg__
	ld r24,Z
	lds r25,-247
	subi r25,lo8(-(1))
	andi r25,lo8(15)
	sts -247,r25
	ret
	.size	uart0_receive, .-uart0_receive
	.section	.text.uart0_space,"ax",@progbits
.global	uart0_space
	.type	uart0_space, @function
uart0_space:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
	ldi r24,lo8(32)
	jmp uart0_send
	.size	uart0_space, .-uart0_space
	.section	.text.uart0_newline,"ax",@progbits
.global	uart0_newline
	.type	uart0_newline, @function
uart0_newline:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
	ldi r24,lo8(13)
	call uart0_send
	ldi r24,lo8(10)
	jmp uart0_send
	.size	uart0_newline, .-uart0_newline
	.section	.text.uart0_hexbyte,"ax",@progbits
.global	uart0_hexbyte
	.type	uart0_hexbyte, @function
uart0_hexbyte:
	push r28
/* prologue: function */
/* frame size = 0 */
/* stack size = 1 */
.L__stack_usage = 1
	mov r28,r24
	asr r24
	asr r24
	asr r24
	asr r24
	subi r24,lo8(-(48))
	call uart0_send
	mov r24,r28
	andi r24,lo8(15)
	cpi r24,lo8(10)
	brge .L19
	subi r24,lo8(-(48))
	rjmp .L20
.L19:
	subi r24,lo8(-(55))
.L20:
/* epilogue start */
	pop r28
	jmp uart0_send
	.size	uart0_hexbyte, .-uart0_hexbyte
	.section	.text.uart0_hexword,"ax",@progbits
.global	uart0_hexword
	.type	uart0_hexword, @function
uart0_hexword:
	push r28
/* prologue: function */
/* frame size = 0 */
/* stack size = 1 */
.L__stack_usage = 1
	mov r28,r24
	mov r24,r25
	call uart0_hexbyte
	mov r24,r28
/* epilogue start */
	pop r28
	jmp uart0_hexbyte
	.size	uart0_hexword, .-uart0_hexword
	.ident	"GCC: (GNU) 5.4.0"
