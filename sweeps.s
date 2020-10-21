; sweep_batch_table

; SWEEP 1

    ; Pokey settings

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

