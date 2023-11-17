;
; morse-code-transmitter.asm
;
; Created: 2023-11-17 12:19:00
; Author : Alexander Engström
;

START:
	rjmp	INIT_STACK 

MESSAGE:
	.db		"MESSAGE TO BE TRANSMITTED", $00

INIT_STACK:
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

INIT_IO:
	ldi		r16, $01
	out		DDRA, r16
	out		DDRB, r16

INIT_VAR:
	.equ	N = 50
	.equ	T = 200

MAIN:
	push	ZH
	push	ZL
	push	r16
	push	r17

	rcall	MORSE

	pop		r17
	pop		r16
	pop		ZL
	pop		ZH
	rjmp	MAIN

MORSE:
	ldi		ZL, LOW(MESSAGE * 2)
	ldi		ZH, HIGH(MESSAGE * 2)
READ_WORD:
	lpm		r17, Z+
	cpi		r17, $00
	breq	READING_COMPLETE

	cpi		r17, $20
	breq	SPECIAL_CHAR

	cpi		r17, $5B
	brsh	SPECIAL_CHAR

	rcall	LOOKUP
	rcall	SEND
	rjmp	READ_WORD

SPECIAL_CHAR:
	ldi		r16, 6
	rcall	NOBEEP
	rjmp	READ_WORD

READING_COMPLETE:
	ldi		r16, 7
	rcall	NOBEEP
	ret

LOOKUP:	
	push	ZH
	push	ZL
	ldi		ZL, LOW(BTAB * 2)
	ldi		ZH, HIGH(BTAB * 2)

	subi	r17, $41
	brmi	LOOKUP_COMPLETE
	add		ZL, r17
	brcc	NO_CARRY
	inc		ZH
NO_CARRY:
	lpm		r17, Z

	pop		ZL
	pop		ZH
LOOKUP_COMPLETE:
	ret

SEND:
	cpi		r17, $80
	breq	SEND_DONE
	lsl		r17
	brcc	CARRY_CLEAR
	ldi		r16, 3
	rcall	BEEP
	rjmp	SEND
CARRY_CLEAR:
	ldi		r16, 1
	rcall	BEEP
	rjmp	SEND
SEND_DONE:
	ldi		r16, 2
	rcall	NOBEEP
	ret

BEEP:
	sbi		PORTA, 0
	rcall	SIGNAL
	cbi		PORTA, 0
	ldi		r16, 1
	rcall	SIGNAL
	ret

NOBEEP:
	cbi		PORTA, 0
	rcall	SIGNAL
	ldi		r16, 1
	rcall	SIGNAL
	ret

SIGNAL:
	push	r17
SIGNAL_OUTER_LOOP:
	ldi		r17, N
SIGNAL_INNER_LOOP:
	rcall	TONE
	dec		r17
	brne	SIGNAL_INNER_LOOP
	dec		r16
	brne	SIGNAL_OUTER_LOOP
	pop		r17
	ret

TONE:
	sbic	PINA, 0
	sbi		PORTB, 0
	rcall	FREQUENCY_CYCLE
	cbi		PORTB, 0
	rcall	FREQUENCY_CYCLE
	ret

FREQUENCY_CYCLE:
	push	r16
	ldi		r16, T
FREQUENCY_LOOP:
	dec		r16
	brne	FREQUENCY_LOOP
	pop		r16
	ret

BTAB:
	.db		$60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8, $00, $00

