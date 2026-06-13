.include "m328pdef.inc"

; =====================================
; Timing reference (matches sender):
;   SHORT_DELAY = 127.5ms  (dot ON duration)
;   LONG_DELAY  = 382.5ms  (dash ON duration)
;   Symbol gap  = 127.5ms LOW between dots/dashes in same letter
;   Letter gap  = 510ms total LOW after last symbol of a letter
;
; Timer1: prescaler=256 => 1 tick = 16us (62500 ticks/sec)
;
; Dot/Dash threshold = midpoint(127.5ms, 382.5ms) = 255ms = 15937 ticks = 0x3E41
;   Comparison direction (SAME as working code):
;     timer_H < threshold_H           => DOT    (short pulse)
;     timer_H > threshold_H           => DASH   (long pulse)
;     timer_H == threshold_H AND
;       timer_L < threshold_L         => DOT
;       timer_L >= threshold_L        => DASH
;
; Letter gap threshold = 600ms (exaggerated, safely above 510ms) = 37500 ticks = 0x927C
;   Timer is reset on FALLING EDGE so it measures pure silence.
;   When silence >= 600ms => decode buffered letter.
;   Both 0x3E41 and 0x927C fit in two byte registers (max 0xFFFF), no overflow.
;
; Timer read order: TCNT1L first, then TCNT1H  (matches working code)
; Timer write order: TCNT1H first, then TCNT1L (AVR requirement for safe atomic write)
; =====================================

.org 0x0000
rjmp RESET

; =====================================
RESET:
    ; Stack Setup
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; Pin Configuration
    cbi DDRB, PB3      ; PB3 (D11) INPUT  -> RX signal
    sbi DDRB, PB0      ; PB0 (D8)  OUTPUT -> LED
    sbi PORTB, PB0
    sbi DDRD, PD6      ; PD6 (D6)  OUTPUT -> Buzzer
    cbi PORTD, PD6

    ; UART 9600 @16MHz
    ldi r16, 103
    sts UBRR0L, r16
    ldi r16, 0
    sts UBRR0H, r16
    ldi r16, (1<<TXEN0)
    sts UCSR0B, r16
    ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
    sts UCSR0C, r16

    ; Timer1 Normal Mode, Prescaler=256
    ldi r16, 0
    sts TCCR1A, r16
    ldi r16, (1<<CS12)
    sts TCCR1B, r16

    clr r18     ; lastState = LOW
    clr r25     ; morse pattern buffer
    clr r26     ; morse length counter

; =====================================
MAIN:
    ; Read PB3 into r19 (1=signal present, 0=idle)
    in r17, PINB
    sbrc r17, PB3
    ldi r19, 1
    sbrs r17, PB3
    ldi r19, 0

    tst r19
    breq SIGNAL_LOW

SIGNAL_HIGH:
    sbi PORTB, PB0      ; LED on
    sbi PORTD, PD6      ; Buzzer on
    rjmp EDGE_CHECK

SIGNAL_LOW:
    cbi PORTB, PB0      ; LED off
    cbi PORTD, PD6      ; Buzzer off
    rcall CHECK_LETTER  ; check if letter gap has elapsed
    rjmp EDGE_CHECK

; =====================================
EDGE_CHECK:
    ; -------- Rising Edge (0->1): start of pulse, reset timer --------
    cpi r19, 1
    brne CHECK_FALL
    cpi r18, 0
    brne UPDATE_LAST
    ldi r16, 0
    sts TCNT1H, r16     ; write H before L (AVR atomic write requirement)
    sts TCNT1L, r16
    rjmp UPDATE_LAST

; -------- Falling Edge (1->0): end of pulse --------
CHECK_FALL:
    cpi r19, 0
    brne UPDATE_LAST
    cpi r18, 1
    brne UPDATE_LAST

    ; Read timer — L before H, same as working code
    lds r20, TCNT1L
    lds r21, TCNT1H

    ; Reset timer NOW so CHECK_LETTER measures pure silence from this moment
    ldi r16, 0
    sts TCNT1H, r16
    sts TCNT1L, r16

    ; --- Dot/Dash threshold = 0x3E41 (255ms) ---
    ; Same comparison logic as working code:
    ;   timer < threshold => DOT  (short pulse)
    ;   timer >= threshold => DASH (long pulse)
    ldi r22, 0x3E       ; threshold high byte
    ldi r23, 0x41       ; threshold low byte

    cp r21, r22         ; compare timer_H with threshold_H
    brlo PULSE_DOT      ; timer_H < threshold_H => short pulse => DOT
    brne PULSE_DASH     ; timer_H > threshold_H => long pulse  => DASH
    ; high bytes equal, check low byte
    cp r20, r23
    brlo PULSE_DOT      ; timer_L < threshold_L => DOT
    rjmp PULSE_DASH     ; timer_L >= threshold_L => DASH

PULSE_DASH:
    lsl r25             ; shift left, bit0 = 0 (dot)
    inc r26
    rjmp UPDATE_LAST

PULSE_DOT:
    lsl r25
    ori r25, 1          ; shift left, bit0 = 1 (dash)
    inc r26
    rjmp UPDATE_LAST

; =====================================
; CHECK_LETTER
; Timer was reset on falling edge, so it measures pure silence.
; Threshold = 600ms = 37500 ticks = 0x927C (exaggerated, safe above 510ms gap)
; Both high(0x927C)=0x92 and low(0x927C)=0x7C fit in a byte register fine.
; =====================================
CHECK_LETTER:
    cpi r26, 0
    breq CL_DONE        ; nothing buffered yet

    ; Read timer L before H (matching working code style)
    lds r20, TCNT1L
    lds r21, TCNT1H

    ; Letter gap threshold = 0x927C (600ms)
    ldi r22, 0x92       ; threshold high byte
    ldi r23, 0x7C       ; threshold low byte

    cp r21, r22
    brlo CL_DONE        ; timer_H < threshold_H => not long enough yet
    brne CL_DECODE      ; timer_H > threshold_H => silence elapsed, decode
    ; high bytes equal, check low byte
    cp r20, r23
    brlo CL_DONE        ; timer_L < threshold_L => not yet
    ; fall through to decode

CL_DECODE:
    rcall DECODE_LETTER
    ; Reset timer so we don't re-decode the same letter on next loop
    ldi r16, 0
    sts TCNT1H, r16
    sts TCNT1L, r16

CL_DONE:
    ret

; =====================================
UPDATE_LAST:
    mov r18, r19
    rjmp MAIN

; =====================================
; DECODE_LETTER
; Dispatches to a subroutine per length group.
; Each group has its own SEND_Lx/RESET_Lx immediately after its checks
; so every breq is guaranteed within +-63 words (no out-of-range errors).
; =====================================
DECODE_LETTER:
    cpi r26, 1
    breq DECODE_L1
    cpi r26, 2
    breq DECODE_L2
    cpi r26, 3
    breq DECODE_L3
    cpi r26, 4
    breq DECODE_L4
    clr r25
    clr r26
    ret

; =====================================
; Length 1: E(.) T(-)
; Pattern: 1 symbol. dot=0 (lsl only), dash=1 (lsl+ori 1)
; E = .  => r25 = 0x00
; T = -  => r25 = 0x01
; =====================================
DECODE_L1:
    cpi r25, 0x00
    ldi r24, 'E'
    breq SEND_L1
    cpi r25, 0x01
    ldi r24, 'T'
    breq SEND_L1
    rjmp RESET_L1
SEND_L1:
    rcall UART_SEND
RESET_L1:
    clr r25
    clr r26
    ret

; =====================================
; Length 2: I(..) A(.-) N(-.) M(--)
; Pattern: r25 = (s1<<1)|s2
; I = .. => 0x00
; A = .- => 0x01
; N = -. => 0x02
; M = -- => 0x03
; =====================================
DECODE_L2:
    cpi r25, 0x00
    ldi r24, 'I'
    breq SEND_L2
    cpi r25, 0x01
    ldi r24, 'A'
    breq SEND_L2
    cpi r25, 0x02
    ldi r24, 'N'
    breq SEND_L2
    cpi r25, 0x03
    ldi r24, 'M'
    breq SEND_L2
    rjmp RESET_L2
SEND_L2:
    rcall UART_SEND
RESET_L2:
    clr r25
    clr r26
    ret

; =====================================
; Length 3: S(...) U(..-) R(.-.) W(.--) D(-..) K(-.-) G(--.) O(---)
; Pattern: r25 = (s1<<2)|(s2<<1)|s3
; S = ... => 0x00
; U = ..- => 0x01
; R = .-. => 0x02
; W = .-- => 0x03
; D = -.. => 0x04
; K = -.- => 0x05
; G = --. => 0x06
; O = --- => 0x07
; =====================================
DECODE_L3:
    cpi r25, 0x00
    ldi r24, 'S'
    breq SEND_L3
    cpi r25, 0x01
    ldi r24, 'U'
    breq SEND_L3
    cpi r25, 0x02
    ldi r24, 'R'
    breq SEND_L3
    cpi r25, 0x03
    ldi r24, 'W'
    breq SEND_L3
    cpi r25, 0x04
    ldi r24, 'D'
    breq SEND_L3
    cpi r25, 0x05
    ldi r24, 'K'
    breq SEND_L3
    cpi r25, 0x06
    ldi r24, 'G'
    breq SEND_L3
    cpi r25, 0x07
    ldi r24, 'O'
    breq SEND_L3
    rjmp RESET_L3
SEND_L3:
    rcall UART_SEND
RESET_L3:
    clr r25
    clr r26
    ret

; =====================================
; Length 4: H(....)/V(...-)/F(..-.)/L(.-..)
;           P(.--.)/ J(.---)/B(-...)/X(-..-)/
;           C(-.-.)/Y(-.--)/Z(--..)/Q(--.-)
; Pattern: r25 = (s1<<3)|(s2<<2)|(s3<<1)|s4
; H = .... => 0x00
; V = ...- => 0x01
; F = ..-. => 0x02
; L = .-.. => 0x04
; P = .--. => 0x06
; J = .--- => 0x07
; B = -... => 0x08
; X = -..- => 0x09
; C = -.-. => 0x0A
; Y = -.-- => 0x0B
; Z = --.. => 0x0C
; Q = --.- => 0x0D
; =====================================
DECODE_L4:
    cpi r25, 0x00
    ldi r24, 'H'
    breq SEND_L4
    cpi r25, 0x01
    ldi r24, 'V'
    breq SEND_L4
    cpi r25, 0x02
    ldi r24, 'F'
    breq SEND_L4
    cpi r25, 0x04
    ldi r24, 'L'
    breq SEND_L4
    cpi r25, 0x06
    ldi r24, 'P'
    breq SEND_L4
    cpi r25, 0x07
    ldi r24, 'J'
    breq SEND_L4
    cpi r25, 0x08
    ldi r24, 'B'
    breq SEND_L4
    cpi r25, 0x09
    ldi r24, 'X'
    breq SEND_L4
    cpi r25, 0x0A
    ldi r24, 'C'
    breq SEND_L4
    cpi r25, 0x0B
    ldi r24, 'Y'
    breq SEND_L4
    cpi r25, 0x0C
    ldi r24, 'Z'
    breq SEND_L4
    cpi r25, 0x0D
    ldi r24, 'Q'
    breq SEND_L4
    rjmp RESET_L4
SEND_L4:
    rcall UART_SEND
RESET_L4:
    clr r25
    clr r26
    ret

; =====================================
UART_SEND:
WAIT_TX:
    lds r16, UCSR0A
    sbrs r16, UDRE0
    rjmp WAIT_TX
    sts UDR0, r24
    ret