; ---------------------------------------------------------------------------

; POKEY EXPLORER
; by Ivo van Poorten (C)2020
; BSD0 license

; ---------------------------------------------------------------------------

    icl 'cio.s'

; ---------------------------------------------------------------------------

    org $2200

; ---------------------------------------------------------------------------

; SHADOW POKEY

shadow_audf1    dta $12         ; $d200
shadow_audc1    dta $34         ; $d201
shadow_audf2    dta $56         ; $d202
shadow_audc2    dta $78         ; $d203
shadow_audf3    dta $9a         ; $d204
shadow_audc3    dta $bc         ; $d205
shadow_audf4    dta $de         ; $d206
shadow_audc4    dta $f0         ; $d207
shadow_audctl   dta $ea         ; $d208
shadow_skctl    dta $56         ; $d20f

; ---------------------------------------------------------------------------

; MAIN

    org $2400
main

    close 0
    open 0, 4, 0, "K"

    mva #>font $02f4
    mva #<dl $0230
    mva #>dl $0231

loop
    jsr display_shadow_pokey

    bget 0, 1, keybuf
    jmp loop

keybuf
    dta 0

; ---------------------------------------------------------------------------

print_shadow_hex    .macro register, location
    lda :register
    tay
    lsr
    lsr
    lsr
    lsr
    tax
    lda hextab,x
    sta :location
    tya
    and #$0f
    tax
    lda hextab,x
    sta :location+1
    .mend

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

    rts

; ---------------------------------------------------------------------------

hextab
    dta d'0123456789ABCDEF'

; ---------------------------------------------------------------------------

; DISPLAY LIST

    .align $0400

dl
    dta $70, $70
    dta $47, a(title)
    dta $70
    dta $42, a(filter13_line), $02
    dta $30
    dta $42, a(filter24_line), $02
    dta $30
    dta $42, a(join1234_line), $02

    dta $70
    dta $42, a(pokey_values_decoration_top)
    dta $42, a(pokey_values_line)
    dta $42, a(pokey_values_decoration_bottom)
    dta $70

    dta $42, a(up_keys_line)
    dta $42, a(down_keys_line)
    dta $70

    dta $42, a(poly9_line)
    dta $00
    dta $42, a(base_clock64_line)
    dta $00
    dta $42, a(clock_channel1_base_line)
    dta $00
    dta $42, a(clock_channel3_179_line)
    dta $00
    dta $42, a(two_tone_off_line)
    dta $70
    dta $42, a(sweep_line)

    dta $41, a(dl)

; ---------------------------------------------------------------------------

; SCREEN DATA

; ---------------------------------------------------------------------------

title
    dta d'   POKEY EXPLORER   '

empty_line
    dta d'                                        '

; ---------------------------------------------------------------------------

filter13_off_line
    dta d' ', d'F'*, d'                                      '
    dta d'                                        '

filter13_line
    dta d' ', d'F'*, d'   ', c'QRRR', d'Filter', c'RRRRE'
    dta d'                    '
    dta d'     1             3                    '

filter24_off_line
    dta d' ', d'G'*, d'                                      '
    dta d'                                        '

filter24_line
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
