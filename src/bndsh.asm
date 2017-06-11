    org 0x8000
    include "lib/debug.asm"


config_enable_sound equ 1

        ; sauvegarde lecteur/face courante
        ld hl,(&BE7D)
        ld a,(hl)
        push hl
        push af
        ; initialise la ROM7
        ld hl,&ABFF
        ld de,&0040
        ld c,&06 ; XXX found the rom position automatically
        call &BCCE
        ; on reprend sur le même lecteur/face
        pop af
        pop hl
        ld (hl),a



    call bndsh_get_rsx_names
    call line_editor_init

    jp line_editor_main_loop




bndsh_get_rsx_names

    ; Save current state of the ROM
    xor a
    call FIRMWARE.KL_ROM_SELECT
    push bc

    xor a
    ld de, rsx_names
.loop_over_rom
    push af

        ; Select the ROM of interest
        ld c, a
        push de
            call FIRMWARE.KL_ROM_SELECT
            ld a, 1 : call FIRMWARE.TXT_SET_COLUMN
        pop de

        ; Get rom name
        ld	hl,(0xC004)
        ld a, (hl) : or a
        jp z, .end_loop_over_rom

        call .eat_string

.loop_over_rsx
            ld a, (hl)
            or a : jr z, .end_loop_over_rsx


            bit 7, a : jr nz, .loop_over_rsx_forget

                push hl
                    BREAKPOINT_WINAPE
                    call  .copy_name_in_buffer
                pop hl

.loop_over_rsx_forget

            call .eat_string
            jr .loop_over_rsx
.end_loop_over_rsx
    pop af : inc a


    cp 32
   jr nz, .loop_over_rom
.end_loop_over_rom

    
    ; Restore the previous state of the ROM
    pop bc : push de : call FIRMWARE.KL_ROM_SELECT : pop de
    xor a
    ld (de), a
    inc de
    ld (de), a

    ret

.eat_string
    ld a, (hl)
    inc hl
    bit 7, a
    ret nz
    jr .eat_string
    

.copy_name_in_buffer
    ld a, (hl) : res 7, a : ld (de), a  ; Copy char without bit 7
    ld a, (hl) : inc hl : inc de        ; Read again char
    bit 7, a : jr nz, .end_of_copy                    ; Leave when the word is written
    jr .copy_name_in_buffer
.end_of_copy
    xor a
    ld (de), a
    inc de
    ret

startup_data
.text    string  "Benediction Shell v0.1 (june 2017)"


    include "lib/system.asm"
    include "lib/CRTC_detection.asm" ; XXX Attention may not be ROM friendly

    include "line_editor.asm"
    include "interpreter.asm"
    include "display.asm"
    include "string.asm"
    include "history.asm"
    include "autocomplete.asm"


    include "data.asm"
