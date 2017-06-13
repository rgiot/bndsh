 ;;
; Basic interpreter for bndsh.
;
; @author Romain Giot
; @date june 2017
; @licence GPL



 
    include "lib/debug.asm"

M4_ROM_NB equ 6 ; TODO remove that for a final version

config_enable_sound equ 1





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
        ld  hl,(0xC004)
        ld a, (hl) : or a
        jp z, .end_loop_over_rom

        call .eat_string

.loop_over_rsx
            ld a, (hl)
            or a : jr z, .end_loop_over_rsx


            bit 7, a : jr nz, .loop_over_rsx_forget

                push hl
                    push de
                        ld de, interpreter.command_name_buffer
                        call  .copy_name_in_buffer
                        call bndsh_rsx_exists
                        call nz, bndsh_command_exists 
                    pop de
                pop hl
                jr z, .loop_over_rsx_forget
                
                push hl
                    ld hl, interpreter.command_name_buffer
                    call string_copy_word : inc de
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


;;
; Input: 
; DE: ROm name
bndsh_get_rom_number
    ; Save current state of the ROM
    xor a
    push de : call FIRMWARE.KL_ROM_SELECT : pop de
    push bc

    xor a
.loop_over_rom
    push af

        ; Select the ROM of interest
        ld c, a
        push de : call FIRMWARE.KL_ROM_SELECT : pop de

        ; Get rom name
        ld  hl,(0xC004)
        push de : call string_is_prefix : pop de
        jr z,.found 
    pop af
    inc a


    cp 32
   jr nz, .loop_over_rom

.not_found
    ld a, 0xff
.continue
    ; Restore the previous state of the ROM
    pop bc
    push af : call FIRMWARE.KL_ROM_SELECT : pop af
    ret

.found
    pop af
    jr .continue


bndsh_rsx_exists

    ld hl, rsx_names
    ld de, interpreter.command_name_buffer
.loop
    ; HL = pointer on the rsx names
    
    ; Stop search if we are reading the latest string
    ld a, (hl) : or a : jr z, .buffer_read

    ; Check if we have a same
    push de: push hl
        ld de, interpreter.command_name_buffer
        call string_compare
    pop hl: pop de

    jr nz, .is_not_same


.is_same
    ; Add the string
    cp a
    ret

.is_not_same
        ; move to the end of string
        ld  a, (hl) : inc hl
        or a
        jr z, .loop
    jr .is_not_same

.buffer_read
    or 1
    ret




;;
; Check if, for this RSX, there is already an internal command with the same name
; INPUT:
; - HL = string to compare to
; OUTPUT:
; - HL is inchanged
; - Z if command present
bndsh_command_exists


    ld de, interpreter.command_name_buffer
    ld hl, interpreter_command_list
.loop_full
        ; Read the ptr name
        ld c, (hl) : inc hl : ld b, (hl)


        ; Quit if this is the end
        ld a, b
        or c
        jr z, .end_of_loop_no_match


;        ; HL: list of commands
;        ; DE: string to compare to
;        ; BC: current string
;
        push hl : push de
            ld h, b : ld l, c
            call string_compare
        pop de : pop hl
        jr z, .end_of_loop_match

        ld de, command - 1
        add hl, de
        ld de, interpreter.command_name_buffer

    jr .loop_full

.end_of_loop_no_match
    or 1
    ret

.end_of_loop_match
    cp a
    ret



bndsh_startup
    ld a, screen.cpc_mode
    call FIRMWARE.SCR_SET_MODE


    ld hl, startup_data.text : call display_print_string
    
    call m4_available : jr nz, .no_m4
    ld hl, startup_data.m4 : call display_print_string
.no_m4

    call pdos_available : jr nz, .no_pdos
    ld hl, startup_data.pdos : call display_print_string
.no_pdos
    ret






startup_data
.text    string  "Benediction Shell v0.1a      (june 2017)"
.m4      string  "                            M4 detected."
.pdos    string  " (do not still work)   Parados detected."


    include "lib/system.asm"
    include "lib/CRTC_detection.asm" ; XXX Attention may not be ROM friendly

    include "line_editor.asm"
    include "interpreter.asm"
    include "display.asm"
    include "string.asm"
    include "history.asm"
    include "autocomplete.asm"
    include "m4.asm"



    if BNDSH_EXEC
        include "data.asm"
    endif

    if BNDSH_ROM
bndsh_rom_data_start
        rorg BNDSH_DUMMY_MEMORY_LIMIT
            include "data.asm"
        rend
bndsh_rom_data_stop
    endif
