.include "m328pdef.inc"

.org 0x0000
rjmp RESET

; =====================================
RESET:
    ; Stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ;; PD7 (LED) output
	sbi DDRD, PD7

	; PD6 (RF DATA) output
	sbi DDRD, PD6

    ; UART 9600 @16MHz
    ldi r16, 103
    sts UBRR0L, r16
    ldi r16, 0
    sts UBRR0H, r16

    ldi r16, (1<<RXEN0)
    sts UCSR0B, r16

    ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, r16

; =====================================
MAIN:
	WAIT_RX:
		lds r17, UCSR0A
		sbrs r17, RXC0
		rjmp WAIT_RX

		lds r18, UDR0

		cpi r18, 'A'
		brne CHECK_B
		rjmp SEND_A

	CHECK_B:
		cpi r18, 'B'
		brne CHECK_C
		rjmp SEND_B

	CHECK_C:
		cpi r18, 'C'
		brne CHECK_D
		rjmp SEND_C

	CHECK_D:
		cpi r18, 'D'
		brne CHECK_E
		rjmp SEND_D

	CHECK_E:
		cpi r18, 'E'
		brne CHECK_F
		rjmp SEND_E

	CHECK_F:
		cpi r18, 'F'
		brne CHECK_G
		rjmp SEND_F

	CHECK_G:
		cpi r18, 'G'
		brne CHECK_H
		rjmp SEND_G

	CHECK_H:
		cpi r18, 'H'
		brne CHECK_I
		rjmp SEND_H

	CHECK_I:
		cpi r18, 'I'
		brne CHECK_J
		rjmp SEND_I

	CHECK_J:
		cpi r18, 'J'
		brne CHECK_K
		rjmp SEND_J

	CHECK_K:
		cpi r18, 'K'
		brne CHECK_L
		rjmp SEND_K

	CHECK_L:
		cpi r18, 'L'
		brne CHECK_M
		rjmp SEND_L

	CHECK_M:
		cpi r18, 'M'
		brne CHECK_N
		rjmp SEND_M

	CHECK_N:
		cpi r18, 'N'
		brne CHECK_O
		rjmp SEND_N

	CHECK_O:
		cpi r18, 'O'
		brne CHECK_P
		rjmp SEND_O

	CHECK_P:
		cpi r18, 'P'
		brne CHECK_Q
		rjmp SEND_P

	CHECK_Q:
		cpi r18, 'Q'
		brne CHECK_R
		rjmp SEND_Q

	CHECK_R:
		cpi r18, 'R'
		brne CHECK_S
		rjmp SEND_R

	CHECK_S:
		cpi r18, 'S'
		brne CHECK_T
		rjmp SEND_S

	CHECK_T:
		cpi r18, 'T'
		brne CHECK_U
		rjmp SEND_T

	CHECK_U:
		cpi r18, 'U'
		brne CHECK_V
		rjmp SEND_U

	CHECK_V:
		cpi r18, 'V'
		brne CHECK_W
		rjmp SEND_V

	CHECK_W:
		cpi r18, 'W'
		brne CHECK_X
		rjmp SEND_W

	CHECK_X:
		cpi r18, 'X'
		brne CHECK_Y
		rjmp SEND_X

	CHECK_Y:
		cpi r18, 'Y'
		brne CHECK_Z
		rjmp SEND_Y

	CHECK_Z:
		cpi r18, 'Z'
		brne NONE_FOUND
		rjmp SEND_Z

	NONE_FOUND:
		rjmp MAIN

; =====================================
; Morse Routines (A–Z)
; DOT / DASH / LETTER_GAP routines stay same

SEND_A: rcall DOT
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_B: rcall DASH
        rcall DOT
        rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_C: rcall DASH
        rcall DOT
        rcall DASH
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_D: rcall DASH
        rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_E: rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_F: rcall DOT
        rcall DOT
        rcall DASH
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_G: rcall DASH
        rcall DASH
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_H: rcall DOT
        rcall DOT
        rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_I: rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_J: rcall DOT
        rcall DASH
        rcall DASH
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_K: rcall DASH
        rcall DOT
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_L: rcall DOT
        rcall DASH
        rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_M: rcall DASH
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_N: rcall DASH
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_O: rcall DASH
        rcall DASH
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_P: rcall DOT
        rcall DASH
        rcall DASH
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_Q: rcall DASH
        rcall DASH
        rcall DOT
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_R: rcall DOT
        rcall DASH
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_S: rcall DOT
        rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

SEND_T: rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_U: rcall DOT
        rcall DOT
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_V: rcall DOT
        rcall DOT
        rcall DOT
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_W: rcall DOT
        rcall DASH
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_X: rcall DASH
        rcall DOT
        rcall DOT
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_Y: rcall DASH
        rcall DOT
        rcall DASH
        rcall DASH
        rcall LETTER_GAP
        rjmp MAIN

SEND_Z: rcall DASH
        rcall DASH
        rcall DOT
        rcall DOT
        rcall LETTER_GAP
        rjmp MAIN

; =====================================
; DOT / DASH / GAPS remain same

DOT:
    sbi PORTD, PD7      ; LED ON
    sbi PORTD, PD6      ; RF ON
    rcall SHORT_DELAY

    cbi PORTD, PD7      ; LED OFF
    cbi PORTD, PD6      ; RF OFF
    rcall SHORT_DELAY
    ret

DASH:
    sbi PORTD, PD7      ; LED ON
    sbi PORTD, PD6      ; RF ON
    rcall LONG_DELAY

    cbi PORTD, PD7      ; LED OFF
    cbi PORTD, PD6      ; RF OFF
    rcall SHORT_DELAY
    ret

LETTER_GAP:
    rcall LONG_DELAY
    ret

; =====================================
; Delay Routines
SHORT_DELAY:
    ldi r20, 40
SD1:
    ldi r21, 255
SD2:
    ldi r22, 200
SD3:
    dec r22
    brne SD3
    dec r21
    brne SD2
    dec r20
    brne SD1
    ret

LONG_DELAY:
    ldi r23, 3
LD1:
    rcall SHORT_DELAY
    dec r23
    brne LD1
    ret