; ---------------------------------------------------------------------------

; sweep_batch_table

; ---------------------------------------------------------------------------

; SWEEP 1
;
; Synthpopalooza's 1+3 filter, 1 and 3 @1.79MHz
; Interval of $0101 and reverse 16-bit

    ; Pokey settings (copy manually from UI)

    ; Pokey $d200-$d207 (AUDF/AUDC pairs)
    dta $00, $af, $00, $a0, $00, $a0, $00, $a0
    ; Pokey AUDCTL ($d208)
    dta $64
    ; Pokey SKCTL ($d20f)
    dta $83

    ; Sweep settings

    ; Resolution, (0,1,2) = (8-bit, 16-bit, Reverse 16-bit)
    dta $02

    ; Channels, (0,1,2,3) = (1+2, 3+4, 1+3, 2+4) or (1, 2, 3, 4) in 8-bit mode
    dta $02

    ; Start value, 16-bit, MSB is ignored in 8-bit mode
    dta a($0001)

    ; End value, 16-bit, MSB is ignored in 8-bit mode
    dta a($ffff)

    ; Interval, 16-bit, MSB is ignored in 8-bit mode
    dta a($0101)

    ; Play time, (0,1,2,3) = (0.1s, 1s, 2s, 4s)
    dta $00

    ; Gap time, (0,1,2,3) = (0s, 0.1s, 0.5s, 1s)
    dta $00

    ; Poly reset, (0,1,2) = (off, once, each)
    dta $00

; ---------------------------------------------------------------------------

; SWEEP 2

; Plain $Ax sweep

    dta $00, $af, $00, $a0, $00, $a0, $00, $a0
    dta $00
    dta $83

    dta $00 ; 8-bit
    dta $00 ; channel 1
    dta a($0000)
    dta a($ffff)
    dta a($0001)
    dta $00 ; 0.1s
    dta $00 ; 0s
    dta $00 ; off

; ---------------------------------------------------------------------------

; SWEEP 3

; $8x, poly counter 9-bit, channel 1 clock 1.79MHz, 8-bit sweep
; $03 + n*7

    dta $03, $8f, $00, $a0, $00, $a0, $00, $a0
    dta $c0
    dta $83

    dta $00 ; 8-bit
    dta $00 ; channel 1
    dta a($0003)
    dta a($ffff)
    dta a($0007)
    dta $01 ; 1s            slower than previous sweeps
    dta $01 ; 0.1s          and with a gap!
    dta $00 ; off

; ---------------------------------------------------------------------------

