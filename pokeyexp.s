; ---------------------------------------------------------------------------
;
; POKEY EXPLORER
;
; by Ivo van Poorten (C)2020
;
; License: Zero clause BSD
;
; Permission to use, copy, modify, and/or distribute this software for any
; purpose with or without fee is hereby granted.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
; REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
; AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
; INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
; LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
; OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
; PERFORMANCE OF THIS SOFTWARE.

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

; SHADOW POKEY default values

shadow_default_values
    dta $00, $a0, $00, $a0, $00, $a0, $00, $a0, $00, $03

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

memcpyshort  .macro src, dst, len
    ldx #0
copyloop
    lda :src,x
    sta :dst,x
    inx
    cpx #:len
    bne copyloop
    .mend

print_shadow_bit2   .macro register, mask, offstring, onstring, location, length
    lda :register
    and #:mask
    bne bit_on

    memcpyshort :offstring :location :length

    jmp bit_done

bit_on
    memcpyshort :onstring :location :length

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

    print_shadow_bit2 shadow_audctl, $80, poly17_string, poly9_string, loc_poly_string, 6

    print_shadow_bit2 shadow_audctl, $40, channel_clock_base_string, channel_clock_179_string, loc_channel1_clock_string, 8
    print_shadow_bit2 shadow_audctl, $20, channel_clock_base_string, channel_clock_179_string, loc_channel3_clock_string, 8

    ; join channels

    lda shadow_audctl
    and #$10
    bne do_join12_on

    memcpyshort join_off_string, loc_join12_string, 8
    jmp handle_join34

do_join12_on
    memcpyshort join_on_string, loc_join12_string, 8

handle_join34
    lda shadow_audctl
    and #$08
    bne do_join34_on

    memcpyshort join_off_string, loc_join34_string, 8
    jmp cont_display_shadow_pokey

do_join34_on
    memcpyshort join_on_string, loc_join34_string, 8

cont_display_shadow_pokey

    ; filter bits

    print_shadow_bit2 shadow_audctl, $04, filter_off_string, filter_on_string, loc_filter13_string, 15
    print_shadow_bit2 shadow_audctl, $02, filter_off_string, filter_on_string, loc_filter24_string, 15

    ; base clock

    print_shadow_bit2 shadow_audctl, $01, base_clock64_string, base_clock15_string, loc_base_clock_string, 6

    ; SKCTL two-tone bit

    print_shadow_bit2 shadow_skctl, $08, two_tone_off_string, two_tone_on_string, loc_two_tone_string, 3

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

    cmp #'['
    beq polyreset
    cmp #'-'
    bne no_polyreset

polyreset
    lda #$ff
    sta $d209           ; STIMER
    rts
no_polyreset

    rts

; ---------------------------------------------------------------------------

; DISPLAY LIST

    .align $0400

dl
    dta $70
    dta $42, a(title)
    dta $42, a(author)
    dta $30
    dta $42, a(filter13_line)
    dta $00
    dta $42, a(filter24_line)
    dta $00
    dta $42, a(join_line)

    dta $00
    dta $42, a(pokey_values_decoration_top)
    dta $42, a(pokey_values_line)
    dta $42, a(pokey_values_decoration_bottom)
    dta $00
    dta $42, a(up_keys_line)
    dta $42, a(down_keys_line)

    dta $30
    dta $42, a(poly_line)
    dta $00
    dta $42, a(base_clock_line)
    dta $00
    dta $42, a(channel1_clock_line)
    dta $00
    dta $42, a(channel3_clock_line)
    dta $00
    dta $42, a(two_tone_line)
.if 0
    dta $30
    dta $42, a(sweep_line)
    dta $10
    dta $02, $02, $02, $02, $02, $02, $02, $02
.fi

    dta $41, a(dl)

; ---------------------------------------------------------------------------

; SCREEN DATA

; ---------------------------------------------------------------------------

title
    dta d'             POKEY EXPLORER     v0.2wip '*

author
    dta d'    by Ivo van Poorten   (C)2020 TGK    '
empty_line
    dta d'                                        '

; ---------------------------------------------------------------------------

filter13_line
    dta d' ', d'F'*, d'   '
loc_filter13_string
    dta d'                                   '

filter_off_string
    dta d'               '
filter_on_string
    dta c'QRRR', d'Filter', c'RRRRE'    ; 15

filter24_line
    dta d' ', d'G'*, d'          '
loc_filter24_string
    dta d'                            '

; ---------------------------------------------------------------------------

join_line
    dta d' ', d'J'*, d'   '
loc_join12_string
    dta d'              '
loc_join34_string
    dta d'           ', d'K'*, d'         '

join_off_string
    dta d'        '
join_on_string
    dta c'QR', d'Join', c'RE'       ; 8

; ---------------------------------------------------------------------------

poly_line
    dta d' ', d'P'*, d' Poly counter    : '
loc_poly_string
    dta d'17-bit    ', d'-['*, d' Reset '

poly9_string
    dta d'9-bit '
poly17_string
    dta d'17-bit'

base_clock_line
    dta d' ', d'C'*, d' Clock base      : '
loc_base_clock_string
    dta d'15 kHz             '

base_clock15_string
    dta d'15 kHz'
base_clock64_string
    dta d'64 kHz'

channel1_clock_line
    dta d' ', d'A'*, d' channel 1 clock : '
loc_channel1_clock_string
    dta d'1.79 MHz           '

channel3_clock_line
    dta d' ', d'D'*, d' channel 3 clock : '
loc_channel3_clock_string
    dta d'base               '
 
channel_clock_base_string
    dta d'base    '
channel_clock_179_string
    dta d'1.79 MHz'

; ---------------------------------------------------------------------------

pokey_values_decoration_top
    dta d'  ', c'QRR', d'1', c'RREQRR', d'2', c'RREQRR'
    dta d'3', c'RREQRR', d'4', c'RRE', d'          '

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
    dta d'  ', c'ZRRRRRCZRRRRRCZRRRRRCZRRRRRC', d'          '

; ---------------------------------------------------------------------------

two_tone_line
    dta d' ', d'M'*, d' two-tone Mode   : '
loc_two_tone_string
    dta d'off                ' 

two_tone_off_string
    dta d'off' 
two_tone_on_string
    dta d'on ' 

; ---------------------------------------------------------------------------

up_keys_line
    dta d' + ', d'1'*, d'  ', d'2'*, d'   ', d'3'*, d'  ', d'4'*, d'   '
    dta d'5'*, d'  ', d'6'*, d'   ', d'7'*, d'  ', d'8'*, d'   SHIFT+$10'

down_keys_line
    dta d' -  ', d'Q'*, d'  ', d'W'*, d'   ', d'E'*, d'  ', d'R'*, d'   '
    dta d'T'*, d'  ', d'Y'*, d'   ', d'U'*, d'  ', d'I'*, d'  SHIFT-$10'

; ---------------------------------------------------------------------------

.if 0
sweep_line
    dta d'         Press ', d' START '*, d' to sweep         '
    dta d' CTRL-', d'R'*, d' Resolution   : 16 bit           '
    dta d' CTRL-', d'C'*, d' Channel(s)   : 1+2              '
    dta d' CTRL-', d'S'*, d' Start value  : 0000             '
    dta d' CTRL-', d'E'*, d' End value    : FFFF             '
    dta d' CTRL-', d'I'*, d' Interval     : 01               '
    dta d' CTRL-', d'P'*, d' Play time    : 1s               '
    dta d' CTRL-', d'G'*, d' Gap time     : 0.1s             '
    dta d' CTRL-', d'X'*, d' Poly Reset   : once             '
.fi

; ---------------------------------------------------------------------------

; HTT FONT

   org $3800
font
    ins "font.fnt"

; ---------------------------------------------------------------------------

    RUN main
