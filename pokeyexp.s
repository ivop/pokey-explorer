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

; Timing has to be different on PAL and NTSC

    PAL    = 0
    NTSC   = 1

; Note that the _exact_ hardware framerate is not 50Hz (PAL) or 60Hz (NTSC),
; but 49.8607Hz (PAL) and 59.9277Hz (NTSC).

; Emulator settings might vary between exact 50Hz/60Hz, hardware framerate
; or broadcast framerate.

; When post-processing audio recordings, keep this in mind and adjust for it.

    .if SYSTEM == PAL
        FRAMES_PER_SECOND = 50
    .else
        FRAMES_PER_SECOND = 60
    .fi

    WAIT_TIME_100ms = FRAMES_PER_SECOND/10
    WAIT_TIME_200ms = FRAMES_PER_SECOND/5
    WAIT_TIME_500ms = FRAMES_PER_SECOND/2
    WAIT_TIME_800ms = (WAIT_TIME_1s)-(WAIT_TIME_200ms)
    WAIT_TIME_1s    = FRAMES_PER_SECOND
    WAIT_TIME_2s    = FRAMES_PER_SECOND*2
    WAIT_TIME_4s    = FRAMES_PER_SECOND*4

; ---------------------------------------------------------------------------

    icl 'cio.s'

; ---------------------------------------------------------------------------

    RTCLOK = $0012
    SDLSTL = $0230
    SSKCTL = $0232
    SHFLOK = $02be
    NOCLIK = $02db
    CHBAS  = $02f4
    CH     = $02fc

    CONSOL = $d01f
    AUDF1  = $d200
    AUDC1  = $d201
    AUDF2  = $d202
    AUDC2  = $d203
    AUDF3  = $d204
    AUDC3  = $d205
    AUDF4  = $d206
    AUDC4  = $d207
    AUDCTL = $d208
    STIMER = $d209
    RANDOM = $d20a
    SKCTL  = $d20f
    WSYNC  = $d40a

; ---------------------------------------------------------------------------

    zp = $fe

; ---------------------------------------------------------------------------

    org $2000

; ---------------------------------------------------------------------------

; SHADOW POKEY

shadow_pokey
shadow_audf1    dta $00         ; $d200
shadow_audc1    dta $a0         ; $d201
shadow_audf2    dta $00         ; $d202
shadow_audc2    dta $a0         ; $d203
shadow_audf3    dta $00         ; $d204
shadow_audc3    dta $a0         ; $d205
shadow_audf4    dta $00         ; $d206
shadow_audc4    dta $a0         ; $d207
shadow_audctl   dta $00         ; $d208
shadow_skctl    dta $83         ; $d20f

; SHADOW POKEY default values

shadow_pokey_default_values
    dta $00, $a0, $00, $a0, $00, $a0, $00, $a0, $00, $83
shadow_pokey_length = * - shadow_pokey_default_values

shadow_pokey_storage
    dta $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; Sweep Variables

sweep_variables
var_sweep_resolution    dta $00
var_sweep_channel
var_sweep_channels      dta $00
var_sweep_start_value   dta $00, $00
var_sweep_end_value     dta $ff, $ff
var_sweep_interval      dta $01, $00
var_sweep_play_time     dta $01
var_sweep_gap_time      dta $01
var_sweep_poly_reset    dta $00

; Sweep UI Variables

var_sweep_ui_updown
    dta $00

; Sweep UI Variables default values

var_sweep_ui_default_values
    dta $00

; Sweep Temporary Values

var_sweep_poly_reset_copy
    dta $00
var_sweep_value
    dta $00, $00, $00   ; 24-bit LE for easily detecting 16-bit overflow

; Tuning Variables

var_tuning_enabled
    dta $00
var_tuning_volume
    dta $07
var_tuning_note
    dta $09             ; A
var_tuning_octave
    dta $04
var_tuning_key_was_pressed
    dta $01             ; display first run

; ---------------------------------------------------------------------------

; MAIN

main .proc
    jsr detect_2nd_pokey
    beq no_2nd_pokey

    mwa #tuning_enabled_line tuning_line_one
    mwa #tuning_volume_line tuning_line_two
    mwa #tuning_note_line tuning_line_three

    jsr clear_second_pokey

    jsr display_tuning_variables

no_2nd_pokey
    mva #>font        CHBAS
    mwa #display_list SDLSTL
    mva #$ff          NOCLIK

    .if BATCH == 0
        jmp main_interactive
    .else
        jmp main_batch
    .fi
    .endp

; ---------------------------------------------------------------------------

; MAIN BATCH

main_batch .proc

    mwa #sweep_batch_table zp   ; init (zp)

loop_batch
    ldy #9

loop_set_sweep_pokey
    mva (zp),y shadow_pokey,y
    dey
    bpl loop_set_sweep_pokey

    jsr display_shadow_pokey

    ldy #20
    ldx #10

loop_set_sweep_variables
    mva (zp),y sweep_variables,x
    dey
    dex
    bpl loop_set_sweep_variables

    jsr display_sweep_variables

    jsr handle_start_key            ; execute sweep

    lda zp
    clc
    adc #21
    sta zp
    lda zp+1
    adc #0
    sta zp+1

    lda zp
    cmp #<sweep_batch_table_end
    bne loop_batch

    lda zp+1
    cmp #>sweep_batch_table_end
    bne loop_batch

endless
    jmp endless
    .endp

; ---------------------------------------------------------------------------

; MAIN INTERACTIVE

main_interactive .proc
    open 1, 4, 0, "K"

loop
    lda stereo_pokey
    beq skip_display_tuning_variables

    lda var_tuning_key_was_pressed          ; always enabled on first run
    beq skip_display_tuning_variables

    jsr play_tuning_note                    ; play when settings are changed
    jsr display_tuning_variables

skip_display_tuning_variables
    jsr display_sweep_variables
    jsr display_shadow_pokey
    jsr play_shadow_pokey

    mwa #sweep_line sweep_line_dl_location

    mva #$00 SHFLOK     ; set lower case, always lower case

    mva #$ff CH

no_key_yet
    lda CONSOL
    cmp #6
    bne no_start_key

    jsr handle_start_key
    jmp loop

no_start_key
    lda CH
    cmp #$ff
    beq no_key_yet

    bget 1, 1, keybuf
    jsr handle_keypress

    jmp loop

    .endp

; ---------------------------------------------------------------------------

; MAIN data

keybuf
    dta 0
stereo_pokey
    dta 0

sweep_batch_table

    .if BATCH == 1
        icl 'sweeps.s'
    .fi

sweep_batch_table_end

; ---------------------------------------------------------------------------

; Detect 2nd Pokey. Result in A and also store to stereo_pokey

detect_2nd_pokey .proc
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
    mva #0 stereo_pokey
    rts

detected_stereo
    mva #1 stereo_pokey
    rts

    .endp

; ---------------------------------------------------------------------------

; CLEAR second Pokey

clear_second_pokey .proc
    ldx #$0f
    lda #0
clear_loop
    sta $d210,x
    dex
    bpl clear_loop
    rts
    .endp

; ---------------------------------------------------------------------------

; PLAY tuning note on second Pokey

play_tuning_note .proc
    lda var_tuning_enabled
    bne play_the_note

play_silence
    mva #0 AUDF1+$10
    mva #0 AUDC1+$10
    mva #0 AUDF2+$10
    mva #0 AUDC2+$10
    mva #0 AUDCTL+$10
    mva #0 SKCTL+$10
    rts

play_the_note
    mva #$50 AUDCTL+$10         ; join 1+2, ch1 clock 1.79MHz
    mva #$83 SKCTL+$10          ; start poly counters

    ldx var_tuning_octave       ; 0-9
    lda mul_by_12_tab,x         ; A = octave*12
    clc
    adc var_tuning_note

    asl                         ; mul by 2
    tax

    mva tuning_table,x   AUDF1+$10
    mva tuning_table+1,x AUDF2+$10

    mva #$a0 AUDC1+$10

    lda var_tuning_volume
    and #$0f                    ; UI treats it as an 8-bit value
    clc
    adc #$a0
    sta AUDC2+$10

    rts
    .endp

mul_by_12_tab
    dta 0, 12, 24, 36, 48, 60, 72, 84, 96, 108

; ---------------------------------------------------------------------------

; SWEEP and BUZZER timing macros

; clobbers A
wait_for_vertical_blank .macro
    lda RTCLOK+2
wait
    cmp RTCLOK+2
    beq wait
    .endm

; clobbers X and A
wait_number_of_frames   .macro expression
    ldx :expression
    beq done
wait
    wait_for_vertical_blank
    dex
    bne wait
done
    .endm

; ---------------------------------------------------------------------------

; GTIA BUZZERS

gtia_buzzer_countdown .proc
    ldy #WAIT_TIME_200ms

buzz
    mva #0 CONSOL
    wait_number_of_frames #1
    dey
    bne buzz

    wait_number_of_frames #WAIT_TIME_800ms

    rts
    .endp

gtia_buzzer_error .proc
    ldy #WAIT_TIME_1s

buzz
    mva #0 CONSOL
    wait_number_of_frames #2         ; 2 seconds to read the error message
    dey
    bne buzz

    rts
    .endp

; ---------------------------------------------------------------------------

; SWEEP helper code

do_poly_reset_if_necessary .proc
    lda var_sweep_poly_reset_copy
    beq sweep_poly_reset_none
    cmp #2
    beq sweep_poly_reset_each

    ; fall through, must be 1 (once), decrement so next loop it will be none
    dec var_sweep_poly_reset_copy
    ; fall though again and do one Polycounter Reset

sweep_poly_reset_each
    mva #$ff STIMER         ; OK for now. Later more stable reset for Timbres

sweep_poly_reset_none
    rts
    .endp

wait_sweep_play_time .proc
    lda var_sweep_play_time
    beq do_sweep_play_time_0
    cmp #1
    beq do_sweep_play_time_1
    cmp #2
    beq do_sweep_play_time_2
    bne do_sweep_play_time_3

do_sweep_play_time_0
    wait_number_of_frames #WAIT_TIME_100ms
    jmp play_time_done

do_sweep_play_time_1
    wait_number_of_frames #WAIT_TIME_1s
    jmp play_time_done

do_sweep_play_time_2
    wait_number_of_frames #WAIT_TIME_2s
    jmp play_time_done

do_sweep_play_time_3
    wait_number_of_frames #WAIT_TIME_4s
    jmp play_time_done

play_time_done
    rts
    .endp

wait_sweep_gap_time .proc
    lda var_sweep_gap_time
    beq do_sweep_gap_time_0
    cmp #1
    beq do_sweep_gap_time_1
    cmp #2
    beq do_sweep_gap_time_2
    bne do_sweep_gap_time_3

do_sweep_gap_time_0
    jmp gap_time_done                           ; 0s

; Mute here, because we don't want to mute for 0s, so don't factorize this!

do_sweep_gap_time_1
    jsr mute_real_pokey
    wait_number_of_frames #WAIT_TIME_100ms
    jmp gap_time_done

do_sweep_gap_time_2
    jsr mute_real_pokey
    wait_number_of_frames #WAIT_TIME_500ms
    jmp gap_time_done

do_sweep_gap_time_3
    jsr mute_real_pokey
    wait_number_of_frames #WAIT_TIME_1s
    jmp gap_time_done

gap_time_done
    rts
    .endp

; ---------------------------------------------------------------------------

; SWEEP code

handle_start_key .proc

    .if BATCH == 0
wait_for_release
    lda CONSOL
    cmp #7
    bne wait_for_release
    .fi

    jsr mute_real_pokey

    mwa #empty_line sweep_line_dl_location

    wait_number_of_frames #WAIT_TIME_1s

    lda var_sweep_resolution
    jne do_16bit_check

; ----- 8-BIT SWEEP -----

do_8bit_check

    ; check start <= end

    lda var_sweep_start_value
    cmp var_sweep_end_value
    bcc do_8bit_sweep
    beq do_8bit_sweep

    mwa #sweep_error sweep_line_dl_location

    jsr gtia_buzzer_error
    rts

do_8bit_sweep
    ; save pre-sweep settings
    memcpyshort shadow_pokey shadow_pokey_storage shadow_pokey_length
    mva var_sweep_poly_reset var_sweep_poly_reset_copy

    mwa #sweep_countdown sweep_line_dl_location
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown

    ; DO 8-BIT SWEEP

    mwa #sweep_busy sweep_line_dl_location

    ; initialize start sweep value
    mva var_sweep_start_value var_sweep_value
    mva #0 var_sweep_value+1

loop_8bit_sweep
    .if BATCH == 0
    lda CONSOL
    cmp #6
    jeq done_8bit_sweep         ; hold START to end sweep prematurely
    .fi

    ; set sweep value to shadow_pokey channel
    lda var_sweep_channel       ; 0,1,2,3
    asl                         ; 0,2,4,6
    tax

    lda var_sweep_value
    sta shadow_pokey,x

    jsr display_shadow_pokey

    jsr play_shadow_pokey

    jsr do_poly_reset_if_necessary

    jsr wait_sweep_play_time

    jsr wait_sweep_gap_time     ; if non-zero, pokey will be muted

    ; increase var_sweep_value by interval
    lda var_sweep_value
    clc
    adc var_sweep_interval
    sta var_sweep_value
    lda var_sweep_value+1
    adc #0
    sta var_sweep_value+1

    ; check overflow or greater than end_value, in that order
    lda var_sweep_value+1           ; superfluous load
    bne done_8bit_sweep

    lda var_sweep_value
    cmp var_sweep_end_value
    jcc loop_8bit_sweep             ; less than end_value
    jeq loop_8bit_sweep             ; equal, but play end_value, too

done_8bit_sweep
    jmp done_whatever_sweep

; ----- 16-BIT SWEEP -----

do_16bit_check

    ; check start <= end

    lda var_sweep_start_value+1
    cmp var_sweep_end_value+1
    bcc do_16bit_sweep                  ; start is less than end
    bne msb_is_not_equal_so_error_out   ; not equal, so definitely higher

msb_is_equal_so_check_lsb
    lda var_sweep_start_value
    cmp var_sweep_end_value
    bcc do_16bit_sweep      ; less than
    beq do_16bit_sweep      ; equal

    ; fall through

msb_is_not_equal_so_error_out
    mwa #sweep_error sweep_line_dl_location

    jsr gtia_buzzer_error
    rts

do_16bit_sweep
    ; save pre-sweep settings
    memcpyshort shadow_pokey shadow_pokey_storage shadow_pokey_length
    mva var_sweep_poly_reset var_sweep_poly_reset_copy

    mwa #sweep_countdown sweep_line_dl_location
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown

    ; DO 16-BIT SWEEP

    mwa #sweep_busy sweep_line_dl_location

    mwa var_sweep_start_value var_sweep_value
    mva #0 var_sweep_value+2

loop_16bit_sweep
    .if BATCH == 0
    lda CONSOL
    cmp #6
    jeq done_16bit_sweep        ; hold START to end sweep prematurely
    .fi

    ; X and Y become AUDF offsets for specific channel combinations
    ; v=(x-1)*2

    lda var_sweep_channel           ; four options
    beq do_sweep_channels_0
    cmp #1
    beq do_sweep_channels_1
    cmp #2
    beq do_sweep_channels_2

do_sweep_channels_3     ; 2+4
    ldx #2
    ldy #6
    bne channels_selection_done

do_sweep_channels_0     ; 1+2
    ldx #0
    ldy #2
    bne channels_selection_done

do_sweep_channels_1     ; 3+4
    ldx #4
    ldy #6
    bne channels_selection_done

do_sweep_channels_2     ; 1+3
    ldx #0
    ldy #4

channels_selection_done

    lda var_sweep_resolution
    cmp #2                          ; reverse 16-bit!
    bne no_reverse_16_bit

    txa             ; swap X and Y
    pha
    tya
    tax
    pla
    tay

no_reverse_16_bit

    mva var_sweep_value   shadow_pokey,x
    mva var_sweep_value+1 shadow_pokey,y

    jsr display_shadow_pokey

    jsr play_shadow_pokey

    jsr do_poly_reset_if_necessary

    jsr wait_sweep_play_time 

    jsr wait_sweep_gap_time     ; if non-zero, pokey will be muted

    ; - do sweep increment
    lda var_sweep_value
    clc
    adc var_sweep_interval
    sta var_sweep_value
    lda var_sweep_value+1
    adc var_sweep_interval+1
    sta var_sweep_value+1
    lda var_sweep_value+2
    adc #0
    sta var_sweep_value+2

    ; - check overflow
    lda var_sweep_value+2           ; superfluous load
    bne done_16bit_sweep

    ; 16-bit unsigned compare between var_sweep_value and var_sweep_end_value
    lda var_sweep_value+1
    cmp var_sweep_end_value+1
    bcc loop_16bit_sweep               ; value is less than end
    bne done_16bit_sweep               ; not equal, so definitely higher

    lda var_sweep_value
    cmp var_sweep_end_value
    jcc loop_16bit_sweep      ; less than
    jeq loop_16bit_sweep      ; equal, but play end_value, too

    ; fall through

done_16bit_sweep
done_whatever_sweep
    mwa #sweep_done sweep_line_dl_location
    jsr mute_real_pokey

    ; restore pre-sweep settings
    memcpyshort shadow_pokey_storage shadow_pokey shadow_pokey_length
    mva var_sweep_poly_reset_copy var_sweep_poly_reset

    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown
    jsr gtia_buzzer_countdown

    rts
    .endp

; ---------------------------------------------------------------------------

mute_real_pokey .proc
    ldx #8
loop
    mva shadow_pokey_default_values,x AUDF1,x
    dex
    bpl loop
; leave SKCTL alone
    rts
    .endp

; ---------------------------------------------------------------------------

; PRINT MACROS

print_byte_to_hex    .macro register, location
    lda :register
    tay
    :+4 lsr
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
    mva :src,x :dst,x
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

display_sweep_variables .proc
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
    print_byte_to_hex var_sweep_start_value, loc_sweep_start_value_string+2
    print_byte_to_hex var_sweep_start_value+1, loc_sweep_start_value_string
    jmp start_value_done

do_8bit_start_value
    print_byte_to_hex var_sweep_start_value, loc_sweep_start_value_string
    memcpyshort two_spaces, loc_sweep_start_value_string+2, 2

start_value_done

    lda var_sweep_resolution
    beq do_8bit_end_value

do_16bit_end_value
    print_byte_to_hex var_sweep_end_value, loc_sweep_end_value_string+2
    print_byte_to_hex var_sweep_end_value+1, loc_sweep_end_value_string
    jmp end_value_done

do_8bit_end_value
    print_byte_to_hex var_sweep_end_value, loc_sweep_end_value_string
    memcpyshort two_spaces, loc_sweep_end_value_string+2, 2

end_value_done

    lda var_sweep_resolution
    beq do_8bit_interval

do_16bit_interval
    print_byte_to_hex var_sweep_interval+1, loc_sweep_interval_string
    print_byte_to_hex var_sweep_interval,   loc_sweep_interval_string+2
    jmp interval_done

do_8bit_interval
    print_byte_to_hex var_sweep_interval, loc_sweep_interval_string
    memcpyshort two_spaces, loc_sweep_interval_string+2, 2

interval_done

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

    lda var_sweep_ui_updown

    case_sweep 0, loc_sweep_ui_updown_string, \
                  sweep_ui_updown_0_string,   \
                  sweep_ui_updown_strlen
    case_sweep 1, loc_sweep_ui_updown_string, \
                  sweep_ui_updown_1_string,   \
                  sweep_ui_updown_strlen
    case_sweep 2, loc_sweep_ui_updown_string, \
                  sweep_ui_updown_2_string,   \
                  sweep_ui_updown_strlen
    case_sweep 3, loc_sweep_ui_updown_string, \
                  sweep_ui_updown_3_string,   \
                  sweep_ui_updown_strlen

    rts
    .endp

; ---------------------------------------------------------------------------

; DISPLAY Tuning Variables

display_tuning_variables .proc
    lda var_tuning_enabled

    case_sweep 0, loc_tuning_string, \
                  tuning_off_string,   \
                  tuning_enabled_strlen
    case_sweep 1, loc_tuning_string, \
                  tuning_on_string,   \
                  tuning_enabled_strlen

    lda var_tuning_volume
    and #$0f                ; because the UI treats it as an 8-bit value
    tax
    lda hextab,x
    sta loc_tuning_volume

    lda var_tuning_note
    asl
    tax

    mva tone_strings,x loc_tuning_note
    mva tone_strings+1,x loc_tuning_note+1

    ldx var_tuning_octave
    mva octave_strings,x loc_tuning_octave

    rts
    .endp

; ---------------------------------------------------------------------------

; PLAY SHADOW POKEY

play_shadow_pokey .proc
    lda shadow_audf1
    ldx shadow_audc1
    sta AUDF1
    stx AUDC1
    lda shadow_audf2
    ldx shadow_audc2
    sta AUDF2
    stx AUDC2
    lda shadow_audf3
    ldx shadow_audc3
    sta AUDF3
    stx AUDC3
    lda shadow_audf4
    ldx shadow_audc4
    sta AUDF4
    stx AUDC4

    mva shadow_audctl AUDCTL
    mva shadow_skctl  SSKCTL
    mva shadow_skctl  SKCTL
    rts
    .endp

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

case_var_ctrl_key .macro key, var, max
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

; 16-bit variables keys

case_inc_16bit_key .macro key, register
    cmp #:key
    bne nope

    lda var_sweep_ui_updown
    beq do_0001
    cmp #1
    beq do_0010
    cmp #2
    beq do_0100

do_1000
    lda :register+1
    clc
    adc #$10
    sta :register+1
    rts

do_0100
    inc :register+1
    rts

do_0010
    lda :register
    clc
    adc #$10
    sta :register
    bcc done
    inc :register+1
    rts

do_0001
    inc :register
    bne done
    inc :register+1
done
    rts
nope
    .mend
 
case_dec_16bit_key .macro key, register
    cmp #:key
    bne nope

    lda var_sweep_ui_updown
    beq do_0001
    cmp #1
    beq do_0010
    cmp #2
    beq do_0100

do_1000
    lda :register+1
    sec
    sbc #$10
    sta :register+1
    rts

do_0100
    dec :register+1
    rts

do_0010
    lda :register
    sec
    sbc #$10
    sta :register
    bcs done
    dec :register+1
done
    rts

do_0001
    lda :register
    bne just_lsb
    dec :register+1
just_lsb
    dec :register
nope
    .mend
 
; ---------------------------------------------------------------------------

; HANDLE KEY PRESS

handle_keypress .proc
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

    cmp #'['            ; PC keyboard
    beq polyreset
    cmp #'-'            ; ATARI Keyboard
    bne no_polyreset

polyreset
    mva #$ff STIMER
    rts
no_polyreset

    case_var_ctrl_key 'R', var_sweep_resolution, 2
    case_var_ctrl_key 'C', var_sweep_channels, 3
    case_var_ctrl_key 'X', var_sweep_poly_reset, 2
    case_var_ctrl_key 'P', var_sweep_play_time, 3
    case_var_ctrl_key 'G', var_sweep_gap_time, 3
    case_var_ctrl_key 'U', var_sweep_ui_updown, 3

    ; KEY-64 equals CTRL-KEY
    case_inc_16bit_key 'I'-64, var_sweep_interval
    case_dec_16bit_key 'O'-64, var_sweep_interval

    case_inc_16bit_key 'S'-64, var_sweep_start_value
    case_dec_16bit_key 'D'-64, var_sweep_start_value

    case_inc_16bit_key 'W'-64, var_sweep_end_value
    case_dec_16bit_key 'E'-64, var_sweep_end_value

    ; Tuning keys
    mva #1 var_tuning_key_was_pressed

    lda stereo_pokey
    beq no_tuning_keys

    lda keybuf
    case_var_ctrl_key 'T', var_tuning_enabled, 1

    ; be sure to AND #$0f before using this variable
    case_inc1_key 'V'-64, var_tuning_volume
    case_dec1_key 'B'-64, var_tuning_volume

    ; reuse macro. +64 voids control press
    case_var_ctrl_key ','+64, var_tuning_note, 11
    case_var_ctrl_key '.'+64, var_tuning_octave, 9

no_tuning_keys
    dec var_tuning_key_was_pressed
    rts
    .endp

; ---------------------------------------------------------------------------

; DISPLAY LIST

    org $3000

display_list
    dta $00
    dta $42, a(title)
    dta $42, a(author)
    dta $10
    dta $42, a(filter13_line)
    dta $42, a(filter24_line)
    dta $42, a(join_line)

    dta $00
    dta $42, a(pokey_values_decoration_top)
    dta $42, a(pokey_values_line)
    dta $42, a(pokey_values_decoration_bottom)
    dta $00
    dta $42, a(up_keys_line)
    dta $42, a(down_keys_line)

    dta $00
    dta $42, a(poly_line)
    dta $42, a(base_clock_line)
    dta $42, a(channel1_clock_line)
    dta $42, a(channel3_clock_line)
    dta $42, a(two_tone_line)
    dta $10
    dta $42
sweep_line_dl_location
    dta a(0)                    ; MUST be set by MAIN
    dta $00
    dta $42, a(sweep_parameters_lines)
    dta $02, $02, $02, $02, $02, $02, $02

    dta $00
    dta $42, a(sweep_ui_updown_line)
    dta $10
tuning_line_one = *+1
    dta $42, a(empty_line)
tuning_line_two = *+1
    dta $42, a(tuning_disabled_line)
tuning_line_three = *+1
    dta $42, a(empty_line)

    dta $41, a(display_list)

; ---------------------------------------------------------------------------

; SCREEN DATA

; ---------------------------------------------------------------------------

title
    dta d' '*
    .if SYSTEM == PAL
        dta d'PAL '*
    .else
        dta d'NTSC'*
    .fi
    .if BATCH == 0
        dta d'        POKEY EXPLORER     '*
    .else
        dta d'     POKEY BATCH EXPLORER  '*
    .fi
    dta d'v1.1rc2 '*

author
    dta d'    by Ivo van Poorten   (C)2020 TGK    '
two_spaces
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
    dta d'          ', d'-['*, d' Reset '

poly9_string
    dta d'9-bit '
poly17_string
    dta d'17-bit'
poly_strlen = *-poly17_string

base_clock_line
    dta d' ', d'C'*, d' Clock base      : '
loc_base_clock_string
    dta d'                   '

base_clock15_string
    dta d'15 kHz'
base_clock64_string
    dta d'64 kHz'
base_clock_strlen = *-base_clock64_string

channel1_clock_line
    dta d' ', d'A'*, d' channel 1 clock : '
loc_channel1_clock_string
    dta d'                   '

channel3_clock_line
    dta d' ', d'D'*, d' channel 3 clock : '
loc_channel3_clock_string
    dta d'                   '
 
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
    dta d'  |     ||     ||     ||     |          '

pokey_values_decoration_bottom
    dta d'  ', c'ZRRRRRCZRRRRRCZRRRRRCZRRRRRC', d'          '

; ---------------------------------------------------------------------------

two_tone_line
    dta d' ', d'M'*, d' two-tone Mode   : '
loc_two_tone_string
    dta d'off                ' 

tuning_off_string
two_tone_off_string
    dta d'off' 
tuning_on_string
two_tone_on_string
    dta d'on ' 
two_tone_strlen = *-two_tone_on_string
tuning_enabled_strlen = two_tone_strlen

; ---------------------------------------------------------------------------

up_keys_line
    dta d' + ', d'1'*, d'  ', d'2'*, d'   ', d'3'*, d'  ', d'4'*, d'   '
    dta d'5'*, d'  ', d'6'*, d'   ', d'7'*, d'  ', d'8'*, d'  SHIFT+$10 '

down_keys_line
    dta d' -  ', d'Q'*, d'  ', d'W'*, d'   ', d'E'*, d'  ', d'R'*, d'   '
    dta d'T'*, d'  ', d'Y'*, d'   ', d'U'*, d'  ', d'I'*, d' SHIFT-$10 '

; ---------------------------------------------------------------------------

sweep_line
    dta d'         Press ', d' START '*, d' to sweep         '
sweep_error
    dta d' Sweep Error: Start is greater than End '*
sweep_countdown
    dta d' Sweep Countdown... 4... 3... 2... 1... '*

    .if BATCH == 0
sweep_busy
    dta d' EXECUTING SWEEP!    Hold START to STOP '*
    .else
sweep_busy
    dta d'            EXECUTING SWEEP!            '*
    .fi

sweep_done
    dta d'             Sweep Finished!            '*

sweep_parameters_lines
    dta d' CTRL-', d'R'*, d' Resolution   : '
loc_sweep_resolution_string
    dta d'                 '

    dta d' CTRL-', d'C'*, d' Channel(s)   : '
loc_sweep_channels_string
    dta d'                 '

    dta d' CTRL-', d'S'*, d' Start value  : '
loc_sweep_start_value_string
    dta d'          CTRL-', d'D'*, d' '
    dta d' CTRL-', d'W'*, d' End value    : '
loc_sweep_end_value_string
    dta d'          CTRL-', d'E'*, d' '

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
    dta d'0.1s'
sweep_play_time_1_string
    dta d'1s  '
sweep_play_time_2_string
    dta d'2s  '
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

sweep_ui_updown_line
    dta d' CTRL-', d'U'*, d' Up/down sweep value step : '
loc_sweep_ui_updown_string
    dta d'xxxx '

sweep_ui_updown_0_string
    dta d'0001'
sweep_ui_updown_1_string
    dta d'0010'
sweep_ui_updown_2_string
    dta d'0100'
sweep_ui_updown_3_string
    dta d'1000'
sweep_ui_updown_strlen = *-sweep_ui_updown_3_string

; ---------------------------------------------------------------------------

tuning_disabled_line
    dta d' No 2nd Pokey detected, tuning disabled '
tuning_enabled_line
    dta d' CTRL-', d'T'*, d' Tuning note  : '
loc_tuning_string
    dta d'off              '
tuning_volume_line
    dta d' CTRL-', d'V'*, d' Tuning volume: '
loc_tuning_volume
    dta d'F         CTRL-', d'B'*, d' '
tuning_note_line
    dta d' Tune to: '
loc_tuning_note
    dta d'xx'
loc_tuning_octave
    dta d'x           ', d','*, d'=note ', d'.'*, d'=octave '

; ---------------------------------------------------------------------------

; Note Strings
; 12 * 2 = 24 bytes

tone_string_strlen = 2

tone_strings
    dta d'C-'
    dta d'C#'
    dta d'D-'
    dta d'D#'
    dta d'E-'
    dta d'F-'
    dta d'F#'
    dta d'G-'
    dta d'G#'
    dta d'A-'
    dta d'A#'
    dta d'B-'

; C0 - B9 which is 10 octaves
octave_strings = hextab
; which should be dta d'0123456789'

; ---------------------------------------------------------------------------

; TUNING Table

tuning_table
    .if SYSTEM == PAL
        icl 'tuning-16bit-pal.s'
    .else
        icl 'tuning-16bit-ntsc.s'
    .fi

; ---------------------------------------------------------------------------

; HTT FONT

   org $3800
font
    ins "font.fnt"

; ---------------------------------------------------------------------------

    RUN main
