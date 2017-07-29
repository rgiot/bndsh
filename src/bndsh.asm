 ;;
; Basic interpreter for bndsh.
;
; @author Romain Giot
; @date june 2017
; @licence GPL



 
    include "lib/debug.asm"

M4_ROM_NB equ 6 ; TODO remove that for a final version

config_enable_sound equ 1





bndsh_startup
    ld hl, startup_data.text : call display_print_string
    
    call m4_available : jr nz, .no_m4
    ld hl, startup_data.m4 : call display_print_string
.no_m4

    call pdos_available : jr nz, .no_pdos
    ld hl, startup_data.pdos : call display_print_string
.no_pdos
    ret



;;;
bndsh_get_rsx_names

    xor a
    ld de, rsx_names
.loop_over_rom
    push af

        call bndsh_copy_current_rom_rsx_table_in_ram

        ; Get rom name

        


        ld a, (hl) : or a : jp z, .test_next_rom
        ld a, (hl) : cp 'A' : jp c, .test_next_rom

        call .eat_string

        ld bc, 0 ; counter for the animated char
.loop_over_rsx




            ld a, (hl)
            or a : jr z, .end_loop_over_rsx             ; End of table
            bit 7, a : jr nz, .loop_over_rsx_forget     ; Unprintable string
            cp 'A' : jr c, .test_next_rom               ; Memory error ?




                push hl

                    ; XXX this is far too slow here
                    push de 
                        ld de, interpreter.command_name_buffer
                        call  .copy_name_in_buffer
                        ld de, interpreter.command_name_buffer
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
.test_next_rom
    pop af : inc a


    cp 32
   jr nz, .loop_over_rom
.end_loop_over_rom

    
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

.anim
  db '|/-\'


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







startup_data
.text    string  "Benediction Shell v0.1br3    (July 2017)"
.m4      string  "                            M4 detected."
.pdos    string  " (do not still work)   Parados detected."


    include "lib/system.asm"
    include "lib/CRTC_detection.asm" ; XXX Attention may not be ROM friendly

    include "new_line_editor2.asm"
    include "interpreter.asm"
    include "display.asm"
    include "string.asm"
    include "history.asm"
    include "autocomplete.asm"
    include "more.asm"
    include "alias.asm"
    include "cpcget.asm"
    include "error.asm"

    if BNDSH_EXEC
        include "m4.asm"
        include "code_in_ram.asm"
        include "data.asm"
    endif

    if BNDSH_ROM
bndsh_rom_data_start
        rorg BNDSH_DATA_LOCATION
            include "m4.asm"
            include "code_in_ram.asm"
            include "data.asm"
        rend
bndsh_rom_data_stop
    endif
