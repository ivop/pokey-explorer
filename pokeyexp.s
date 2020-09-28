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

; Sweep Variables

var_sweep_resolution    dta $00
var_sweep_channels      dta $00
var_sweep_start_value   dta $00, $00
var_sweep_end_value     dta $ff, $ff
var_sweep_interval      dta $01
var_sweep_play_time     dta $00
var_sweep_gap_time      dta $01
var_sweep_poly_reset    dta $00

; Sweep Variables default values

var_sweep_default_values
    dta $00, $00, $00, $ff, $01, $00, $01, $00

; ---------------------------------------------------------------------------

; MAIN

    org $2080
main
    open 1, 4, 0, "K"

    mva #>font $02f4
    mwa #display_list $0230
    mva #$ff $02db  ; NOCLIK, disable key click

loop
    jsr display_sweep_variables
    jsr display_shadow_pokey
    jsr play_shadow_pokey

    mva #$00 $02be  ; SHFLOK, set lower case, always lower case

    bget 1, 1, keybuf
    jsr handle_keypress

    jmp loop

keybuf
    dta 0

; ---------------------------------------------------------------------------

; PRINT MACROS

print_byte_to_hex    .macro register, location
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

print_shadow_bit   .macro register, mask, offstring, onstring, location, length
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

; DISPLAY SHADOW POKEY

display_shadow_pokey
    print_byte_to_hex shadow_audf1  loc_audf1
    print_byte_to_hex shadow_audc1  loc_audc1
    print_byte_to_hex shadow_audf2  loc_audf2
    print_byte_to_hex shadow_audc2  loc_audc2
    print_byte_to_hex shadow_audf3  loc_audf3
    print_byte_to_hex shadow_audc3  loc_audc3
    print_byte_to_hex shadow_audf4  loc_audf4
    print_byte_to_hex shadow_audc4  loc_audc4
    print_byte_to_hex shadow_audctl loc_audctl
    print_byte_to_hex shadow_skctl  loc_skctl

    print_shadow_bit shadow_audctl, $80, poly17_string, \
                                         poly9_string,  \
                                         loc_poly_string, \
                                         poly_strlen 

    print_shadow_bit shadow_audctl, $40, channel_clock_base_string, \
                                         channel_clock_179_string,  \
                                         loc_channel1_clock_string, \
                                         channel_clock_strlen 

    print_shadow_bit shadow_audctl, $20, channel_clock_base_string, \
                                         channel_clock_179_string,  \
                                         loc_channel3_clock_string, \
                                         channel_clock_strlen

    ; join channels

    lda shadow_audctl
    and #$10
    bne do_join12_on

    memcpyshort join_off_string, loc_join12_string, join_strlen
    jmp handle_join34

do_join12_on
    memcpyshort join_on_string, loc_join12_string, join_strlen

handle_join34
    lda shadow_audctl
    and #$08
    bne do_join34_on

    memcpyshort join_off_string, loc_join34_string, join_strlen
    jmp cont_display_shadow_pokey

do_join34_on
    memcpyshort join_on_string, loc_join34_string, join_strlen

cont_display_shadow_pokey

    print_shadow_bit shadow_audctl, $04, filter_off_string,   \
                                         filter_on_string,    \
                                         loc_filter13_string, \
                                         filter_strlen

    print_shadow_bit shadow_audctl, $02, filter_off_string,   \
                                         filter_on_string,    \
                                         loc_filter24_string, \
                                         filter_strlen

    print_shadow_bit shadow_audctl, $01, base_clock64_string,   \
                                         base_clock15_string,   \
                                         loc_base_clock_string, \
                                         base_clock_strlen

    print_shadow_bit shadow_skctl, $08, two_tone_off_string, \
                                        two_tone_on_string,  \
                                        loc_two_tone_string, \
                                        two_tone_strlen

    rts

; ---------------------------------------------------------------------------

hextab
    dta d'0123456789ABCDEF'

; ---------------------------------------------------------------------------

; SWEEP DISPLAY MACROS

case_sweep  .macro val, dst, string, len
    cmp #:val
    bne nope
    memcpyshort :string :dst :len
nope
    .mend

; ---------------------------------------------------------------------------

; DISPLAY SWEEP VARIABLES

display_sweep_variables
    lda var_sweep_resolution

    case_sweep 0, loc_sweep_resolution_string,  \
                  sweep_resolution_8bit_string, \
                  sweep_resolution_strlen
    case_sweep 1, loc_sweep_resolution_string,   \
                  sweep_resolution_16bit_string, \
                  sweep_resolution_strlen
    case_sweep 2, loc_sweep_resolution_string,          \
                  sweep_resolution_reverse16bit_string, \
                  sweep_resolution_strlen

    lda var_sweep_resolution
    beq do_8bit_channels

do_16bit_channels
    lda var_sweep_channels
    case_sweep 0, loc_sweep_channels_string,     \
                  sweep_16bit_channels_0_string, \
                  sweep_channels_strlen
    case_sweep 1, loc_sweep_channels_string,     \
                  sweep_16bit_channels_1_string, \
                  sweep_channels_strlen
    case_sweep 2, loc_sweep_channels_string,     \
                  sweep_16bit_channels_2_string, \
                  sweep_channels_strlen
    case_sweep 3, loc_sweep_channels_string,     \
                  sweep_16bit_channels_3_string, \
                  sweep_channels_strlen
    jmp channels_done

do_8bit_channels
    lda var_sweep_channels
    case_sweep 0, loc_sweep_channels_string,    \
                  sweep_8bit_channels_0_string, \
                  sweep_channels_strlen
    case_sweep 1, loc_sweep_channels_string,    \
                  sweep_8bit_channels_1_string, \
                  sweep_channels_strlen
    case_sweep 2, loc_sweep_channels_string,    \
                  sweep_8bit_channels_2_string, \
                  sweep_channels_strlen
    case_sweep 3, loc_sweep_channels_string,    \
                  sweep_8bit_channels_3_string, \
                  sweep_channels_strlen

channels_done

    lda var_sweep_resolution
    beq do_8bit_start_value

do_16bit_start_value
    jmp start_value_done

do_8bit_start_value

start_value_done

    print_byte_to_hex var_sweep_interval, loc_sweep_interval_string

    lda var_sweep_poly_reset

    case_sweep 0, loc_sweep_poly_reset_string, \
                  sweep_poly_reset_off_string, \
                  sweep_poly_reset_strlen
    case_sweep 1, loc_sweep_poly_reset_string,  \
                  sweep_poly_reset_once_string, \
                  sweep_poly_reset_strlen
    case_sweep 2, loc_sweep_poly_reset_string,  \
                  sweep_poly_reset_each_string, \
                  sweep_poly_reset_strlen

    lda var_sweep_play_time

    case_sweep 0, loc_sweep_play_time_string, \
                  sweep_play_time_0_string,   \
                  sweep_play_time_strlen
    case_sweep 1, loc_sweep_play_time_string, \
                  sweep_play_time_1_string,   \
                  sweep_play_time_strlen
    case_sweep 2, loc_sweep_play_time_string, \
                  sweep_play_time_2_string,   \
                  sweep_play_time_strlen
    case_sweep 3, loc_sweep_play_time_string, \
                  sweep_play_time_3_string,   \
                  sweep_play_time_strlen

    lda var_sweep_gap_time

    case_sweep 0, loc_sweep_gap_time_string, \
                  sweep_gap_time_0_string,   \
                  sweep_gap_time_strlen
    case_sweep 1, loc_sweep_gap_time_string, \
                  sweep_gap_time_1_string,   \
                  sweep_gap_time_strlen
    case_sweep 2, loc_sweep_gap_time_string, \
                  sweep_gap_time_2_string,   \
                  sweep_gap_time_strlen
    case_sweep 3, loc_sweep_gap_time_string, \
                  sweep_gap_time_3_string,   \
                  sweep_gap_time_strlen

    rts

; ---------------------------------------------------------------------------

; PLAY SHADOW POKEY

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

case_sweep_var_ctrl_key .macro key, var, max
    cmp #:key-64
    bne nope

    inc :var
    lda :var
    cmp #:max+1
    bne done

    mva #0 :var

done
    rts
nope
    .mend

; ---------------------------------------------------------------------------

; HANDLE KEY PRESS

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

    case_sweep_var_ctrl_key 'R', var_sweep_resolution, 2
    case_sweep_var_ctrl_key 'C', var_sweep_channels, 3
    case_sweep_var_ctrl_key 'X', var_sweep_poly_reset, 2
    case_sweep_var_ctrl_key 'P', var_sweep_play_time, 3
    case_sweep_var_ctrl_key 'G', var_sweep_gap_time, 3

    ; KEY-64 equals CTRL-KEY
    case_inc1_key 'I'-64, var_sweep_interval
    case_dec1_key 'O'-64, var_sweep_interval

    rts

; ---------------------------------------------------------------------------

; DISPLAY LIST

    org $3000

display_list
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
    dta $30
    dta $42, a(sweep_line)
    dta $10
    dta $02, $02, $02, $02, $02, $02, $02, $02

    dta $41, a(display_list)

; ---------------------------------------------------------------------------

; SCREEN DATA

; ---------------------------------------------------------------------------

title
    dta d'             POKEY EXPLORER   v0.2beta3 '*

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
    dta c'QRRR', d'Filter', c'RRRRE'
filter_strlen = *-filter_on_string

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
    dta c'QR', d'Join', c'RE'
join_strlen = *-join_on_string

; ---------------------------------------------------------------------------

poly_line
    dta d' ', d'P'*, d' Poly counter    : '
loc_poly_string
    dta d'17-bit    ', d'-['*, d' Reset '

poly9_string
    dta d'9-bit '
poly17_string
    dta d'17-bit'
poly_strlen = *-poly17_string

base_clock_line
    dta d' ', d'C'*, d' Clock base      : '
loc_base_clock_string
    dta d'15 kHz             '

base_clock15_string
    dta d'15 kHz'
base_clock64_string
    dta d'64 kHz'
base_clock_strlen = *-base_clock64_string

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
channel_clock_strlen = *-channel_clock_179_string

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
two_tone_strlen = *-two_tone_on_string

; ---------------------------------------------------------------------------

up_keys_line
    dta d' + ', d'1'*, d'  ', d'2'*, d'   ', d'3'*, d'  ', d'4'*, d'   '
    dta d'5'*, d'  ', d'6'*, d'   ', d'7'*, d'  ', d'8'*, d'   SHIFT+$10'

down_keys_line
    dta d' -  ', d'Q'*, d'  ', d'W'*, d'   ', d'E'*, d'  ', d'R'*, d'   '
    dta d'T'*, d'  ', d'Y'*, d'   ', d'U'*, d'  ', d'I'*, d'  SHIFT-$10'

; ---------------------------------------------------------------------------

sweep_line
;    dta d'         Press ', d' START '*, d' to sweep         '
    dta d'            Sweep Parameters            '

    dta d' CTRL-', d'R'*, d' Resolution   : '
loc_sweep_resolution_string
    dta d'                 '

    dta d' CTRL-', d'C'*, d' Channel(s)   : '
loc_sweep_channels_string
    dta d'                 '

    dta d' CTRL-', d'S'*, d' Start value  : '
loc_sweep_start_value_string
    dta d'XXXX      CTRL-D '
    dta d' CTRL-', d'W'*, d' End value    : '
loc_sweep_end_value_string
    dta d'XXXX      CTRL-E '

    dta d' CTRL-', d'I'*, d' Interval     : '
loc_sweep_interval_string
    dta d'          CTRL-', d'O'*, d' '

    dta d' CTRL-', d'P'*, d' Play time    : '
loc_sweep_play_time_string
    dta d'                 '

    dta d' CTRL-', d'G'*, d' Gap time     : '
loc_sweep_gap_time_string
    dta d'                 '

    dta d' CTRL-', d'X'*, d' Poly Reset   : '
loc_sweep_poly_reset_string
    dta d'                 '

sweep_resolution_8bit_string
    dta d'8-bit         '
sweep_resolution_16bit_string
    dta d'16-bit        '
sweep_resolution_reverse16bit_string
    dta d'Reverse 16-bit'
sweep_resolution_strlen = *-sweep_resolution_reverse16bit_string

sweep_8bit_channels_0_string
    dta d'1  '
sweep_8bit_channels_1_string
    dta d'2  '
sweep_8bit_channels_2_string
    dta d'3  '
sweep_8bit_channels_3_string
    dta d'4  '

sweep_16bit_channels_0_string
    dta d'1+2'
sweep_16bit_channels_1_string
    dta d'3+4'
sweep_16bit_channels_2_string
    dta d'1+3'
sweep_16bit_channels_3_string
    dta d'2+4'
sweep_channels_strlen = *-sweep_16bit_channels_3_string

sweep_poly_reset_off_string
    dta d'off '
sweep_poly_reset_once_string
    dta d'once'
sweep_poly_reset_each_string
    dta d'each'
sweep_poly_reset_strlen = *-sweep_poly_reset_each_string

sweep_play_time_0_string
    dta d'1s  '
sweep_play_time_1_string
    dta d'2s  '
sweep_play_time_2_string
    dta d'3s  '
sweep_play_time_3_string
    dta d'4s  '
sweep_play_time_strlen = *-sweep_play_time_3_string

sweep_gap_time_0_string
    dta d'0s  '
sweep_gap_time_1_string
    dta d'0.1s'
sweep_gap_time_2_string
    dta d'0.5s'
sweep_gap_time_3_string
    dta d'1s  '
sweep_gap_time_strlen = *-sweep_gap_time_3_string

; ---------------------------------------------------------------------------

; HTT FONT

   org $3800
font
    ins "font.fnt"

; ---------------------------------------------------------------------------

    RUN main
