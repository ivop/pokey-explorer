; Detect 2nd Pokey - by Ivo van Poorten - (C)2020 - 0BSD
; Work with the OS

    org $3000

    RTCLOK = $0012
    SSKCTL = $0232
    SKCTL  = $d20f
    COLOR4 = $02c8
    RANDOM = $d20a

wait_for_vertical_blank .macro
    lda RTCLOK+2
wait
    cmp RTCLOK+2
    beq wait
    .endm

MAIN
    wait_for_vertical_blank

    ; Clear SKCTL. This stops all poly counters

    mva #0 SSKCTL
    mva #0 SKCTL
    mva #0 SKCTL+$10        ; make sure a potential 2nd pokey is cleared

    wait_for_vertical_blank

    ; Restart SKCTL. This starts all the poly counters

    mva #3 SSKCTL
    mva #3 SKCTL

    wait_for_vertical_blank

    ; Except when there's a seconds pokey!! Its counters are not restarted.
    ; Its RANDOM should not change.

    lda RANDOM+$10
    cmp RANDOM+$10
    beq detected_stereo         ; so equal means there's a 2nd pokey

detected_mono
    mva #$74 COLOR4             ; Blueish is MONO
    jmp loop

detected_stereo
    mva #$34 COLOR4             ; Redish is STEREO

loop
    jmp loop

    run MAIN
