# Morse Code Walkie-Talkie System

A wired Morse code communication system built on two **ATmega328P (Arduino Nano)** microcontrollers, programmed entirely in **AVR assembly language**. A character typed in PuTTY on one end is encoded into Morse pulses, transmitted over a single wire, decoded by the receiver, and printed on a second PuTTY terminal — with LED and buzzer feedback throughout.

Built as a COAL (Computer Organization and Assembly Language) course project at **SEECS, NUST — Spring 2026**.

---

## How It Works

```
[PC / PuTTY] --UART--> [Transmitter Nano] --signal wire--> [Receiver Nano] --UART--> [PC / PuTTY]
                         encodes A-Z                          decodes A-Z
                         LED blinks                           LED + buzzer
```

The transmitter reads an uppercase letter over UART, then drives its output pin HIGH/LOW with precisely timed pulses:

- **Dot** — 127.5 ms HIGH
- **Dash** — 382.5 ms HIGH
- **Inter-symbol gap** — 127.5 ms LOW (between dots/dashes in the same letter)
- **Inter-letter gap** — ~510 ms LOW (after the last symbol of each letter)

The receiver polls its input pin and uses **Timer1 (16-bit, prescaler 256)** to measure pulse durations. A pulse shorter than 255 ms is a dot; longer is a dash. After 600 ms of silence, the buffered bit pattern is matched against all 26 letters and the decoded character is sent back over UART.

---

## System Architecture

| Board | AVR Pin | Arduino Pin | Function |
|---|---|---|---|
| Transmitter | PD6 | D6 | Morse signal output |
| Transmitter | PD7 | D7 | LED indicator |
| Receiver | PB3 | D11 | Morse signal input |
| Receiver | PB0 | D8 | LED indicator |
| Receiver | PD6 | D6 | Buzzer output |

**Wiring:** TX D6 → RX D11, shared GND between both Nanos.

---

## Key Design Details

**Timing** — all delays on the transmitter are software countdown loops (nested counters 40 × 255 × 200) hand-calibrated for 16 MHz. `SHORT_DELAY ≈ 127.5 ms`, `LONG_DELAY = 3 × SHORT_DELAY ≈ 382.5 ms`.

**Dot/Dash threshold** — midpoint of dot and dash durations: 255 ms = 15937 Timer1 ticks = `0x3E41`. Multi-byte unsigned comparison in 8-bit assembly (high byte first, then low byte).

**Letter gap threshold** — 600 ms = 37500 ticks = `0x927C`, intentionally above the theoretical 510 ms to absorb timing variation. Timer is reset on every falling edge so it measures pure silence.

**Bit pattern encoding** — each symbol shifts register R25 left; a dot ORs bit 0 with 1, a dash does not. Register R26 counts symbols. Together R25/R26 uniquely identify all 26 letters grouped by length (1–4 symbols).

**UART** — 9600 baud, 8N1, 16 MHz → UBRR = 103. Transmitter enables `RXEN0`; receiver enables `TXEN0`. Polling-based (no interrupts).

---

## Toolchain

| Tool | Purpose |
|---|---|
| Microchip Studio 7 | AVR assembly IDE (avrasm2 assembler) |
| Arduino IDE + AVRDUDE | Flashing `.hex` to CH340-based Nano clones |
| PuTTY | Serial terminal, 9600 baud 8N1, local echo off |
| Proteus Design Suite | Pre-hardware simulation and verification |

---

## File Structure

```
├── transmitter.asm                 # Transmitter: UART RX → Morse pulse generation
├── receiver.asm                    # Receiver: pulse timing → letter decode → UART TX
├── documentation.pdf               # Full project report (COAL Spring 2026)
├── Diagrams/
│   ├── transmitter.drawio          # Transmitter flowchart
│   └── Receiver.drawio             # Receiver flowchart
├── Hex files/
│   ├── transmitter.hex             # Pre-built transmitter binary
│   └── receiver.hex                # Pre-built receiver binary
└── Simulation/
    └── simulation.pdsprj           # Proteus simulation project
```

Both `.asm` files include `m328pdef.inc` (ATmega328P register definitions, provided by Microchip Studio).

> **Diagrams** — open `.drawio` files at [draw.io](https://app.diagrams.net) (File → Open from → Device) or in the draw.io desktop app.

> **Simulation** — open `simulation.pdsprj` in **Proteus Design Suite**. The `.pdsbak` file is an auto-generated Proteus backup and can be ignored.

---

## Building and Flashing

1. Open each `.asm` file in **Microchip Studio 7**, set device to `ATmega328P`, and build (`F7`). This produces a `.hex` file.
2. Flash using Arduino IDE's upload button (which invokes AVRDUDE), or directly:

```bash
avrdude -c arduino -p m328p -P COMx -b 115200 -U flash:w:transmitter.hex:i
avrdude -c arduino -p m328p -P COMy -b 115200 -U flash:w:receiver.hex:i
```

3. Open two PuTTY windows at **9600 baud, 8N1, local echo off** — one on each Nano's COM port.
4. Type any uppercase letter (A–Z) in the transmitter window and watch it appear decoded in the receiver window.

---

## Results

All 26 uppercase letters (A–Z) encode and decode correctly. Timer1 jitter is ≈0.4 µs per loop iteration, negligible against the 16 ms classification window around the 255 ms threshold.

---

## Limitations

- Uppercase A–Z only — digits, punctuation, and word spaces are not implemented.
- Wired only — a 433 MHz ASK RF module was acquired but not integrated (future work).
- Unidirectional — full-duplex would require a second signal wire or time-division multiplexing.
- Timing is calibrated for exactly 16 MHz — any clock change invalidates the delay loops.
- No error detection — no checksum or acknowledgement mechanism.

---

## Team

[@username](https://github.com/username) · [@username](https://github.com/username) · [@username](https://github.com/username) · [@username](https://github.com/username)

SEECS, National University of Sciences & Technology (NUST) — Spring 2026
