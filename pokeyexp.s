; ---------------------------------------------------------------------------

; POKEY EXPLORER
; by Ivo van Poorten (C)2020
; BSD0 license

; ---------------------------------------------------------------------------

    icl 'cio.s'

; ---------------------------------------------------------------------------

    org $2000

; ---------------------------------------------------------------------------

; SHADOW POKEY

shadow_audf1    dta $00         ; $d200
shadow_audc1    dta $a0         ; $d201
shadow_audf2    dta $00         ; $d202
shadow_audc2    dta $a0         ; $d203
shadow_audf3    dta $00         ; $d204
shadow_audc3    dta $a0         ; $d205
shadow_audf4    dta $00         ; $d206
shadow_audc4    dta $a0         ; $d207
shadow_audctl   dta $00         ; $d208
shadow_skctl    dta $03         ; $d20f

; ---------------------------------------------------------------------------

; MAIN

    org $2080
main
    open 1, 4, 0, "K"

    mva #>font $02f4
    mwa #dl $0230   ; display list
    mva #$ff $02db  ; NOCLIK, disable key click

loop
    jsr display_shadow_pokey
    jsr play_shadow_pokey

    mva #$00 $02be  ; SHFLOK, set lower case, always lower case

    bget 1, 1, keybuf
    jsr handle_keypress

    jmp loop

keybuf
    dta 0

; ---------------------------------------------------------------------------

; PRINT macros

print_shadow_hex    .macro register, location
    lda :register
    tay
    lsr
    lsr
    lsr
    lsr
    tax
    mva hextab,x :location
    tya
    and #$0f
    tax
    mva hextab,x :location+1
    .mend

print_shadow_bit    .macro register, mask, off_line, on_line, location
    lda :register
    and #:mask
    bne bit_on

    mwa #:off_line :location
    jmp bit_done

bit_on
    mwa #:on_line :location

bit_done
    .mend

; ---------------------------------------------------------------------------

display_shadow_pokey
    print_shadow_hex shadow_audf1  loc_audf1
    print_shadow_hex shadow_audc1  loc_audc1
    print_shadow_hex shadow_audf2  loc_audf2
    print_shadow_hex shadow_audc2  loc_audc2
    print_shadow_hex shadow_audf3  loc_audf3
    print_shadow_hex shadow_audc3  loc_audc3
    print_shadow_hex shadow_audf4  loc_audf4
    print_shadow_hex shadow_audc4  loc_audc4
    print_shadow_hex shadow_audctl loc_audctl
    print_shadow_hex shadow_skctl  loc_skctl

    print_shadow_bit shadow_audctl, $80, poly17_line, poly9_line, loc_poly_line
    print_shadow_bit shadow_audctl, $40, clock_channel1_base_line, clock_channel1_179_line, loc_clock_channel1_line
    print_shadow_bit shadow_audctl, $20, clock_channel3_base_line, clock_channel3_179_line, loc_clock_channel3_line

    ; join channels

    lda shadow_audctl
    and #$18                ; both
    cmp #$18
    beq display_join_both

    cmp #$10
    beq display_join12

    cmp #$08
    beq display_join34

    mwa #join00_line loc_join1234_line
    jmp cont_display_shadow_pokey

display_join12
    mwa #join12_line loc_join1234_line
    jmp cont_display_shadow_pokey

display_join34
    mwa #join34_line loc_join1234_line
    jmp cont_display_shadow_pokey

display_join_both
    mwa #join1234_line loc_join1234_line

cont_display_shadow_pokey

    ; filter bits

    print_shadow_bit shadow_audctl, $04, filter13_off_line, filter13_on_line, loc_filter13_line
    print_shadow_bit shadow_audctl, $02, filter24_off_line, filter24_on_line, loc_filter24_line

    ; base clock

    print_shadow_bit shadow_audctl, $01, base_clock64_line, base_clock15_line, loc_base_clock_line

    ; SKCTL two-tone bit

    print_shadow_bit shadow_skctl, $08, two_tone_off_line, two_tone_on_line, loc_two_tone_line

    rts

; ---------------------------------------------------------------------------

hextab
    dta d'0123456789ABCDEF'

; ---------------------------------------------------------------------------

play_shadow_pokey
    mva shadow_audf1  $d200
    mva shadow_audc1  $d201
    mva shadow_audf2  $d202
    mva shadow_audc2  $d203
    mva shadow_audf3  $d204
    mva shadow_audc3  $d205
    mva shadow_audf4  $d206
    mva shadow_audc4  $d207
    mva shadow_audctl $d208
    mva shadow_skctl  $d20f
    rts

; ---------------------------------------------------------------------------

; case macros for keypress handler

case_inc1_key .macro key, register
    cmp #:key
    bne nope
    inc :register
    rts
nope
    .mend
 
case_dec1_key .macro key, register
    cmp #:key
    bne nope
    dec :register
    rts
nope
    .mend
 
case_inc16_key .macro key, register
    cmp #:key
    bne nope
    lda :register
    clc
    adc #$10
    sta :register
    rts
nope
    .mend
 
case_dec16_key .macro key, register
    cmp #:key
    bne nope
    lda :register
    sec
    sbc #$10
    sta :register
    rts
nope
    .mend
 
case_audctl_toggle_key .macro key, mask
    cmp #:key
    bne nope
    lda shadow_audctl
    eor #:mask
    sta shadow_audctl
    rts
nope
    .mend

case_skctl_toggle_key .macro key, mask
    cmp #:key
    bne nope
    lda shadow_skctl
    eor #:mask
    sta shadow_skctl
    rts
nope
    .mend

; ---------------------------------------------------------------------------

handle_keypress
    lda keybuf

    case_inc1_key '1', shadow_audf1
    case_inc1_key '2', shadow_audc1
    case_inc1_key '3', shadow_audf2
    case_inc1_key '4', shadow_audc2
    case_inc1_key '5', shadow_audf3
    case_inc1_key '6', shadow_audc3
    case_inc1_key '7', shadow_audf4
    case_inc1_key '8', shadow_audc4

    case_dec1_key 'q', shadow_audf1
    case_dec1_key 'w', shadow_audc1
    case_dec1_key 'e', shadow_audf2
    case_dec1_key 'r', shadow_audc2
    case_dec1_key 't', shadow_audf3
    case_dec1_key 'y', shadow_audc3
    case_dec1_key 'u', shadow_audf4
    case_dec1_key 'i', shadow_audc4

    case_inc16_key '!', shadow_audf1
    case_inc16_key '@', shadow_audc1    ; PC Keyboard
    case_inc16_key '"', shadow_audc1    ; real ATARI
    case_inc16_key '#', shadow_audf2
    case_inc16_key '$', shadow_audc2
    case_inc16_key '%', shadow_audf3
    case_inc16_key '^', shadow_audc3
    case_inc16_key '&', shadow_audf4
    case_inc16_key '*', shadow_audc4

    case_dec16_key 'Q', shadow_audf1
    case_dec16_key 'W', shadow_audc1
    case_dec16_key 'E', shadow_audf2
    case_dec16_key 'R', shadow_audc2
    case_dec16_key 'T', shadow_audf3
    case_dec16_key 'Y', shadow_audc3
    case_dec16_key 'U', shadow_audf4
    case_dec16_key 'I', shadow_audc4

    case_audctl_toggle_key 'c', $01
    case_audctl_toggle_key 'C', $01
    case_audctl_toggle_key 'g', $02
    case_audctl_toggle_key 'G', $02
    case_audctl_toggle_key 'f', $04
    case_audctl_toggle_key 'F', $04
    case_audctl_toggle_key 'k', $08
    case_audctl_toggle_key 'K', $08
    case_audctl_toggle_key 'j', $10
    case_audctl_toggle_key 'J', $10
    case_audctl_toggle_key 'd', $20
    case_audctl_toggle_key 'D', $20
    case_audctl_toggle_key 'a', $40
    case_audctl_toggle_key 'A', $40
    case_audctl_toggle_key 'p', $80
    case_audctl_toggle_key 'P', $80

    case_skctl_toggle_key 'm', $08
    case_skctl_toggle_key 'M', $08

    rts

; ---------------------------------------------------------------------------

; DISPLAY LIST

    .align $0400

dl
    dta $70
    dta $42, a(title)
    dta $42, a(author)
    dta $70
loc_filter13_line = *+1
    dta $42, a(filter13_on_line), $02
    dta $10
loc_filter24_line = *+1
    dta $42, a(filter24_on_line), $02
    dta $10
loc_join1234_line = *+1
    dta $42, a(join1234_line), $02

    dta $30
    dta $42, a(pokey_values_decoration_top)
    dta $42, a(pokey_values_line)
    dta $42, a(pokey_values_decoration_bottom)
    dta $30

    dta $42, a(up_keys_line)
    dta $42, a(down_keys_line)
    dta $30

loc_poly_line = *+1
    dta $42, a(poly9_line)
    dta $00
loc_base_clock_line = *+1
    dta $42, a(base_clock64_line)
    dta $00
loc_clock_channel1_line = *+1
    dta $42, a(clock_channel1_base_line)
    dta $00
loc_clock_channel3_line = *+1
    dta $42, a(clock_channel3_179_line)
    dta $00
loc_two_tone_line = *+1
    dta $42, a(two_tone_off_line)
    dta $30
.if 0
    dta $42, a(sweep_line)
.fi

    dta $41, a(dl)

; ---------------------------------------------------------------------------

; SCREEN DATA

; ---------------------------------------------------------------------------

title
    dta d'             POKEY EXPLORER             '*

author
    dta d'    by Ivo van Poorten   (C)2020 TGK    '
empty_line
    dta d'                                        '

; ---------------------------------------------------------------------------

filter13_off_line
    dta d' ', d'F'*, d'                                      '
    dta d'                                        '

filter13_on_line
    dta d' ', d'F'*, d'   ', c'QRRR', d'Filter', c'RRRRE'
    dta d'                    '
    dta d'     1             3                    '

filter24_off_line
    dta d' ', d'G'*, d'                                      '
    dta d'                                        '

filter24_on_line
    dta d' ', d'G'*, d'          ', c'QRRR', d'Filter', c'RRRRE'
    dta d'             '
    dta d'            2             4             '

; ---------------------------------------------------------------------------

join00_line
    dta d' ', d'J'*, d'                            ', d'K'*, d'         '
    dta d'                                        '

join12_line
    dta d' ', d'J'*, d'   ', c'QR', d'Join', c'RE', d'                 '
    dta d'K'*, d'         '
    dta d'     1      2                           '

join34_line
    dta d' ', d'J'*, d'                 ', c'QR', d'Join', c'RE', d'   '
    dta d'K'*, d'         '
    dta d'                   3      4             '

join1234_line
    dta d' ', d'J'*, d'   ', c'QR', d'Join', c'RE', d'      ', c'QR', d'Join'
    dta c'RE', d'   ', d'K'*, d'         '
    dta d'     1      2      3      4             '

; ---------------------------------------------------------------------------

poly9_line
    dta d' ', d'P'*, d' Poly counter    : 9-bit              '

poly17_line
    dta d' ', d'P'*, d' Poly counter    : 17-bit             '

base_clock15_line
    dta d' ', d'C'*, d' Clock base      : 15 kHz             '

base_clock64_line
    dta d' ', d'C'*, d' Clock base      : 64 kHz             '

clock_channel1_base_line
    dta d' ', d'A'*, d' channel 1 clock : base               '
 
clock_channel1_179_line
    dta d' ', d'A'*, d' channel 1 clock : 1.79 MHz           '

clock_channel3_base_line
    dta d' ', d'D'*, d' channel 3 clock : base               '

clock_channel3_179_line
    dta d' ', d'D'*, d' channel 3 clock : 1.79 MHz           '

; ---------------------------------------------------------------------------

pokey_values_decoration_top
    dta d'  ', c'QRRRRREQRRRRREQRRRRREQRRRRRE', d'                     '

loc_audf1 = *+3
loc_audc1 = *+6
loc_audf2 = *+10
loc_audc2 = *+13
loc_audf3 = *+17
loc_audc3 = *+20
loc_audf4 = *+24
loc_audc4 = *+27
loc_audctl = *+33
loc_skctl = *+36

pokey_values_line
    dta d'  |00 01||02 03||04 05||06 07|   08 0f  '

pokey_values_decoration_bottom
    dta d'  ', c'ZRRRRRCZRRRRRCZRRRRRCZRRRRRC', d'                     '

; ---------------------------------------------------------------------------

two_tone_off_line
    dta d' ', d'M'*, d' two-tone Mode   : off                ' 

two_tone_on_line
    dta d' ', d'M'*, d' two-tone Mode   : on                 ' 

; ---------------------------------------------------------------------------

up_keys_line
    dta d' + ', d'1'*, d'  ', d'2'*, d'   ', d'3'*, d'  ', d'4'*, d'   '
    dta d'5'*, d'  ', d'6'*, d'   ', d'7'*, d'  ', d'8'*, d'            '

down_keys_line
    dta d' -  ', d'Q'*, d'  ', d'W'*, d'   ', d'E'*, d'  ', d'R'*, d'   '
    dta d'T'*, d'  ', d'Y'*, d'   ', d'U'*, d'  ', d'I'*, d'           '

; ---------------------------------------------------------------------------

sweep_line
    dta d' ', d'S'*, d' Sweep 8-bit     ', d'Z'*, d' Sweep 16-bit       '

; ---------------------------------------------------------------------------

; HTT FONT

   org $3800
font
    ins "font.fnt"

; ---------------------------------------------------------------------------

    RUN main
